-- /// <summary>
-- /// added by wsh @ 2017-12-21
-- /// 功能：assetbundle管理类，为外部提供统一的资源加载界面、协调Assetbundle各个子系统的运行
-- /// 注意：
-- /// 1、抛弃Resources目录的使用，官方建议：https://unity3d.com/cn/learn/tutorials/temas/best-practices/resources-folder?playlist=30089
-- /// 2、提供Editor和Simulate模式，前者不适用Assetbundle，直接加载资源，快速开发；后者使用Assetbundle，用本地服务器模拟资源更新
-- /// 3、场景不进行打包，场景资源打包为预设
-- /// 4、只提供异步接口，所有加载按异步进行
-- /// 5、采用LZMA压缩方式，性能瓶颈在Assetbundle加载上，ab加载异步，asset加载同步，ab加载后导出全部asset并卸载ab
-- /// 6、所有公共ab包（被多个ab包依赖）常驻内存，非公共包加载asset以后立刻卸载，被依赖的公共ab包会随着资源预加载自动加载并常驻内存
-- /// 7、随意卸载公共ab包可能导致内存资源重复，最好在切换场景时再手动清理不需要的公共ab包
-- /// 8、常驻包（公共ab包）引用计数不为0时手动清理无效，正在等待加载的所有ab包不能强行终止---一旦发起创建就一定要等操作结束，异步过程进行中清理无效
-- /// 9、切换场景时最好预加载所有可能使用到的资源，所有加载器用完以后记得Dispose回收，清理GC时注意先释放所有Asset缓存
-- /// 10、逻辑层所有Asset路径带文件类型后缀，且是AssetBundleConfig.ResourcesFolderName下的相对路径，注意：路径区分大小写
-- /// TODO：
-- /// 1、区分场景常驻包和全局公共包，切换场景时自动卸载场景公共包
-- /// 使用说明：
-- /// 1、由Asset路径获取AssetName、AssetBundleName：ParseAssetPathToNames
-- /// 2、设置常驻(公共)ab包：SetAssetBundleResident(assetbundleName, true)---公共ab包已经自动设置常驻
-- /// 2、(预)加载资源：var loader = LoadAssetBundleAsync(assetbundleName)，协程等待加载完毕后Dispose：loader.Dispose()
-- /// 3、加载Asset资源：var loader = LoadAssetAsync(assetPath, TextAsset)，协程等待加载完毕后Dispose：loader.Dispose()
-- /// 4、离开场景清理所有Asset缓存：ClearAssetsCache()，UnloadUnusedAssetBundles(), Resources.UnloadUnusedAssets()
-- /// 5、离开场景清理必要的(公共)ab包：TryUnloadAssetBundle()，注意：这里只是尝试卸载，所有引用计数不为0的包（还正在加载）不会被清理
-- /// </summary>

--  最大同时进行的ab创建数量
local MAX_ASSETBUNDLE_CREATE_NUM = 5
local GameUtility = CS.GameUtility
local IsEditor = CS.GameUtility.IsEditor()
local table_keyof = table.keyof
local table_insert = table.insert
local table_remove = table.remove
local IsNull = IsNull
local AssetBundleConfig = CS.AssetBundles.AssetBundleConfig
local AssetBundleHelper = CS.AssetBundles.AssetBundleHelper
local AssetBundleUtility = CS.AssetBundles.AssetBundleUtility
local Shader = CS.UnityEngine.Shader
local AssetDatabase = CS.UnityEditor.AssetDatabase
local ABConfig = ABConfig
local SplitString = CUtil.SplitString
local string_contains = string.contains
local AssetBundleMgr = BaseClass("AssetBundleMgr", Singleton)

function AssetBundleMgr:__init()
        -- manifest：提供依赖关系查找以及hash值比对
        self.m_manifest = nil
        self.m_manifestABName = nil
        -- 资源路径相关的映射表
        self.m_assetsPathMapping = nil
        -- 不需要更新的ab列表
        self.m_dontUpdatableABArray = nil
        -- 常驻ab包：需要手动添加公共ab包进来，常驻包不会自动卸载（即使引用计数为0），引用计数为0时可以手动卸载
        self.m_assetbundleResident = {}
        -- 常驻的asset列表, 切换场景不清理，一直常驻内存
        self.m_residentAssetList = {}
        -- ab缓存包：所有目前已经加载的ab包，包括临时ab包与公共ab包
        self.m_assetbundlesCaching = {}
        -- ab缓存包引用计数：卸载ab包时只有引用计数为0时才会真正执行卸载
        self.m_assetbundleRefCount = {}
        -- asset缓存：给非公共ab包的asset提供逻辑层的复用
        self.m_assetsCaching = {}
        -- 加载数据请求：正在prosessing或者等待prosessing的资源请求
        self.m_webRequesting = {}
        -- 等待处理的资源请求
        self.m_webRequesterQueue = {}
        -- 正在处理的资源请求
        self.m_prosessingWebRequester = {}
        -- 逻辑层正在等待的ab加载异步句柄
        self.m_prosessingAssetBundleAsyncLoader = {}
        -- 逻辑层正在等待的asset加载异步句柄
        self.m_prosessingAssetAsyncLoader = {}
        -- 正在下载的ab数量
        self.m_downloadList = {}
        self.m_lastDownloadCount = 0
        self.m_abSizeDict = {}
        -- 同步加载列表，用于unload ab
        self.m_syncList = {}
        self.m_abPathListForCacheAsset = nil
        self.m_abListForResidentAsset = nil
end

function AssetBundleMgr:GetManifestABName()
    return self.m_manifestABName
end

function AssetBundleMgr:SetManifestABName(manifestName)
    self.m_manifestABName = manifestName
end

function AssetBundleMgr:Initialize()
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return coroutine.yieldbreak()
    end

    local manifestClass = require("Framework.AssetBundle.Config.Manifest")
    self.m_manifest = manifestClass.New()
    
    local AssetsPathMappingClass = require("Framework.AssetBundle.Config.AssetsPathMapping")
    self.m_assetsPathMapping = AssetsPathMappingClass.New()

    --  说明：同时请求资源可以提高加载速度
    local manifestLoader = self:RequestAssetBundleAsync(self.m_manifest:GetABName())
    local pathMapLoader = self:RequestAssetBundleAsync(self.m_assetsPathMapping:GetABName())
    local abSizeLoader = self:RequestStreamingAssetFileAsync(ABConfig.AssetBundlesSizeFileName)

    coroutine.waituntil(manifestLoader.IsDone, manifestLoader)
    local assetbundle = manifestLoader:GetAssetbundle()
    self.m_manifest:LoadFromAssetbundle(assetbundle)
    -- ab延时10帧销毁，在iOS和mac editor下加载assetbundle会报错
    coroutine.waitforframes(10)
    assetbundle:Unload(false)
    manifestLoader:Dispose()

    coroutine.waituntil(pathMapLoader.IsDone, pathMapLoader)
    assetbundle = pathMapLoader:GetAssetbundle()
    local mapContent = AssetBundleHelper.LoadTextFromAssetbundle(assetbundle, self.m_assetsPathMapping:GetAssetName())
    if mapContent then
        self.m_assetsPathMapping:Initialize(mapContent.text)
    end

    -- ab延时10帧销毁，在iOS和mac editor下加载assetbundle会报错
    coroutine.waitforframes(10)
    assetbundle:Unload(true)
    pathMapLoader:Dispose()

    coroutine.waituntil(abSizeLoader.IsDone, abSizeLoader)
    self:InitABSizeData(abSizeLoader:GetText())
    abSizeLoader:Dispose()

    local residentABList = self:GetResidentABList()
    for _, abName in ipairs(residentABList) do
        self:SetAssetBundleResident(abName, true)
    end

    return coroutine.yieldbreak()
end

function AssetBundleMgr:Cleanup()
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return coroutine.yieldbreak()
    end

    -- 等待所有请求完成
    -- 要是不等待Unity很多版本都有各种Bug
    coroutine.waituntil(function()
        return #self.m_prosessingWebRequester == 0
    end)

    coroutine.waituntil(function()
        return #self.m_prosessingAssetBundleAsyncLoader == 0
    end)

    coroutine.waituntil(function()
        return #self.m_prosessingAssetAsyncLoader == 0
    end)

    self:ClearAssetsCache()

    for assetbundleName, ab in pairs(self.m_assetbundlesCaching) do
        if ab then
            ab:Unload(false)
        end
    end
    
    self.m_assetbundlesCaching = {}
    self.m_assetbundleRefCount = {}
    self.m_assetbundleResident = {}
    self.m_syncList = {}
    
    ABLoaderFactory:GetInstance():CleanUp()
    AssetLoaderFactory:GetInstance():CleanUp()
    ResourceAsyncLoaderFactory:GetInstance():CleanUp()

    return coroutine.yieldbreak()
end

function AssetBundleMgr:GetCurManifest()
    return self.m_manifest
end

function AssetBundleMgr:GetDownloadUrl()
    return Setting.GetServerResAddr()
end

-- ab常驻
function AssetBundleMgr:SetAssetBundleResident(assetbundleName, resident)
    if resident then
        self.m_assetbundleResident[assetbundleName] = true
    else
        self.m_assetbundleResident[assetbundleName] = false
    end
end

-- 资产常驻
function AssetBundleMgr:SetAssetResident(assetName)
    self.m_residentAssetList[assetName] = true
end

function AssetBundleMgr:ClearAssetResident(assetName)
    self.m_residentAssetList[assetName] = false
end

function AssetBundleMgr:IsAssetBundleResident(assetbundleName)
    if self.m_assetbundleResident[assetbundleName] then
        return true
    else
        return false
    end
end

function AssetBundleMgr:IsAssetBundleLoaded(assetbundleName)
    return self.m_assetbundlesCaching[assetbundleName] ~= nil
end

function AssetBundleMgr:GetAssetBundleCache(assetbundleName)
    return self.m_assetbundlesCaching[assetbundleName]
end

function AssetBundleMgr:RemoveAssetBundleCache(assetbundleName)
    self.m_assetbundlesCaching[assetbundleName] = nil
end

function AssetBundleMgr:AddAssetBundleCache(assetbundleName, assetbundle)
    self.m_assetbundlesCaching[assetbundleName] = assetbundle
end

function AssetBundleMgr:IsAssetLoaded(assetName)
    return self.m_assetsCaching[assetName] ~= nil
end

function AssetBundleMgr:GetAssetCache(assetName)
    return self.m_assetsCaching[assetName]
end

function AssetBundleMgr:AddAssetCache(assetName, asset)
    self.m_assetsCaching[assetName] = asset
end

function AssetBundleMgr:AddAssetbundleAssetsCache(assetbundleName)
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return
    end

    if not self:IsAssetBundleLoaded(assetbundleName) then
        Logger.LogError("Try to add assets cache from unloaded assetbundle : " .. assetbundleName)
        return
    end

    local curAssetbundle = self:GetAssetBundleCache(assetbundleName)
    if not curAssetbundle or curAssetbundle.isStreamedSceneAssetBundle then
        return
    end
    local isAssetResident = self:IsAssetsResident(assetbundleName)
    local allAssetNames = self.m_assetsPathMapping:GetAllAssetNames(assetbundleName)

    for assetName, _ in pairs(allAssetNames) do
        if not self:IsAssetLoaded(assetName) then
            local assetPath = ABConfig.PackagePathToAssetsPath(assetName)
            local asset = curAssetbundle and curAssetbundle:LoadAsset(assetPath) or nil
            if isAssetResident then
                self:SetAssetResident(assetName)
            end
            self:AddAssetCache(assetName, asset)
            if string.find(assetName, "ShaderVariants") then
                AssetBundleHelper.ShaderCollectionWarmUp(asset)
                return
            end

            if IsEditor then
                -- 说明：在Editor模拟时，Shader要重新指定
                local renderers = AssetBundleHelper.GetRenderersInChildren(asset)
                if renderers and renderers.Length > 0 then
                    for i = 0, renderers.Length-1 do
                        local mat = renderers[i].sharedMaterial
                        if not IsNull(mat) then
                            local shader = mat.shader
                            if not IsNull(shader) then
                                mat.shader = Shader.Find(shader.name)
                            end
                        end
                    end
                end
            end
        end
    end
end

function AssetBundleMgr:ClearAssetsCache()
    local remainAssetsList = {}
    for assetName, _ in pairs(self.m_residentAssetList) do
        local status,assetbundleName = self:MapAssetPath(assetName)
        if status then
            remainAssetsList[assetName] = self.m_assetsCaching[assetName]
        else
            Logger.LogError("No assetbundle at asset path :" .. assetName)
        end
    end
    self.m_assetsCaching = remainAssetsList
end
        
function AssetBundleMgr:GetAssetBundleAsyncCreater(assetbundleName)
    return self.m_webRequesting[assetbundleName]
end

function AssetBundleMgr:GetReferenceCount(assetbundleName)
     local count = self.m_assetbundleRefCount[assetbundleName]
     return count or 0
end

function AssetBundleMgr:IncreaseReferenceCount(assetbundleName)
    local count = self:GetReferenceCount(assetbundleName)
    self.m_assetbundleRefCount[assetbundleName] = count + 1
    return count
end

function AssetBundleMgr:DecreaseReferenceCount(assetbundleName)
    local count = self:GetReferenceCount(assetbundleName)
    count = count -1
    count = count < 0 and 0 or count
    self.m_assetbundleRefCount[assetbundleName] = count
    return count
end

function AssetBundleMgr:ClearReferenceCount(assetbundleName)
    self.m_assetbundleRefCount[assetbundleName] = 0
end

function AssetBundleMgr:IsABNeedDownload(assetbundleName, downloadList)
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return false
    end
    
    if self:IsAssetBundleLoaded(assetbundleName) or self.m_webRequesting[assetbundleName] ~= nil then
        return false
    end

    local finalRet = false
    if self.m_manifest then
        local dependancies = self.m_manifest:GetAllDependencies(assetbundleName)
        for i = 0, dependancies.Length-1 do
            local dependance = dependancies[i]
            if dependance and dependance ~= '' and dependance ~= assetbundleName then
                local bRet = self:IsABNeedDownload(dependance, downloadList)
                if bRet then
                    finalRet = true
                end
            end
        end
    end
    
    local bRet, size = self:CheckNeedDownloadFromServer(assetbundleName)
    if bRet then
        finalRet = true
        downloadList[assetbundleName] = size
    end
    
    return finalRet
end

function AssetBundleMgr:IsAssetNeedDownload(assetPath, downloadList)
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return false
    end

    local status,assetbundleName,assetName = self:MapAssetPath(assetPath)
    if not status then
        Logger.LogError("No assetbundle at asset path :" .. assetPath)
        return false
    end

    if self:IsAssetLoaded(assetName) then
        return false
    else
        return self:IsABNeedDownload(assetbundleName, downloadList)
    end
end

function AssetBundleMgr:CreateAssetBundleAsync(assetbundleName)
    if self:IsAssetBundleLoaded(assetbundleName) or self.m_webRequesting[assetbundleName] ~= nil then
        return false
    end

    local loader = ResourceAsyncLoaderFactory:GetInstance():GetLoader()
    local url,needDownload = self:SafeGetABFileUrl(assetbundleName)
    loader:InitWithABName(url, assetbundleName, needDownload)
    if needDownload then
        table_insert(self.m_downloadList, loader)
    end
    self.m_webRequesting[assetbundleName] = loader
    table_insert(self.m_webRequesterQueue, loader)

    -- 创建器持有的引用：创建器对每个ab来说是全局唯一的
    self:IncreaseReferenceCount(assetbundleName)
    return true
end

-- android上不能用File.Exist来判断StreamingAssets目录下的文件是否存在，因为在android上asset只是一个压缩包，并不是文件夹。PC上可以判断。
function AssetBundleMgr:SafeGetABFileUrl(assetbundleName)
    if self:CheckNeedDownloadFromServer(assetbundleName) then
        Logger.Log("Need download from server, ab : " .. assetbundleName)
        local downloadURL = self:GetDownloadUrl()
        if not downloadURL then
            Logger.LogError("You should set download url first!!!")
            return nil
        end

        return downloadURL .. assetbundleName, true
    else
        return AssetBundleUtility.GetAssetBundleFileUrl(assetbundleName), false
    end
end

function AssetBundleMgr:CheckNeedDownloadFromServer(assetbundleName)
    local dontUpdatableABArray = self:GetDontUpdatableABArray()
    for i = 1, #dontUpdatableABArray do
        if assetbundleName == dontUpdatableABArray[i] then
            return true, self:GetABSize(assetbundleName)
        end
    end
    return false, 0
end

function AssetBundleMgr:GetDontUpdatableABArray()
    if not self.m_dontUpdatableABArray then
        self.m_dontUpdatableABArray = {}
        local persistentUpdateFilePath = AssetBundleUtility.GetPersistentDataPath(ABConfig.ABUpdateMapFileName)
        local dontUpdatableABArray = GameUtility.SafeReadAllLines(persistentUpdateFilePath)
        if not dontUpdatableABArray then --新包安装后没有运行过游戏，直接就进行大版本强更才会为nil，其他情况都不会
            return {}
        end
        for i = 0, dontUpdatableABArray.Length-1 do
            if dontUpdatableABArray[i] and dontUpdatableABArray[i] ~= '' then
                table_insert(self.m_dontUpdatableABArray, dontUpdatableABArray[i])
            end
        end
    end
    return self.m_dontUpdatableABArray
end

function AssetBundleMgr:CopyDontUpdatableABArray()
    local abList = {}
    local dontUpdatableABArray = self:GetDontUpdatableABArray()
    if #dontUpdatableABArray <= 0 then
        return abList
    end
    for i = 1, #dontUpdatableABArray do
        table_insert(abList, dontUpdatableABArray[i])
    end

    return abList
end

function AssetBundleMgr:GetAllNeedDownloadABSize()
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return 0
    end
    
    local totalSize = 0
    local dontUpdatableABArray = self:GetDontUpdatableABArray()
    for i = 1, #dontUpdatableABArray do
        totalSize = totalSize + self:GetABSize(dontUpdatableABArray[i])
    end
    return totalSize
end

function AssetBundleMgr:InitABSizeData(content)
    self.m_abSizeDict = {}

    content = string.gsub(content, '\r', '')
    local lines = SplitString(content , '\n')
    for _, line in pairs(lines) do
            if line and line ~= '' then
            local slices = SplitString(line, ABConfig.CommonMapPattren) 
            if #slices >= 2 then
                local size = tonumber(slices[2])
                if size then
                    self.m_abSizeDict[slices[1]] = size
                end
            end
        end
    end
end

function AssetBundleMgr:GetABSize(assetbundleName)
    local size = self.m_abSizeDict[assetbundleName] 
    return size or 0
end

function AssetBundleMgr:RemoveABFromDontUpdatableArray(abName)
    local dontUpdatableABArray = self:GetDontUpdatableABArray()
    for i = 1, #dontUpdatableABArray do
        if abName == dontUpdatableABArray[i] then
            table_remove(dontUpdatableABArray, i)
            break
        end
    end
end

-- 异步请求Assetbundle资源，AB是否缓存取决于是否设置为常驻包，Assets一律缓存，处理依赖
function AssetBundleMgr:LoadAssetBundleAsync(assetbundleName)
    if IsEditor and AssetBundleConfig.IsEditorMode then
        local loader = ABLoaderFactory:GetInstance():GetEditorLoader()
        loader:Init(assetbundleName)
        return loader
    end
    if not self.m_manifest:IsAssetBundleExist(assetbundleName) then
        -- 这里主要是针对切场景预加载，有的ab包不存在还去加载会导致错误
        Logger.Log("AssetBundle donot exist, " .. assetbundleName)
        local loader = ABLoaderFactory:GetInstance():GetEditorLoader()
        loader:Init(assetbundleName)
        return loader
    end
    
    local loader = ABLoaderFactory:GetInstance():GetLoader()

    table_insert(self.m_prosessingAssetBundleAsyncLoader, loader)
    if self.m_manifest then
        local dependancies = self.m_manifest:GetAllDependencies(assetbundleName)
        for i = 0, dependancies.Length-1 do
            local dependance = dependancies[i]
            if dependance and dependance ~= '' and dependance ~= assetbundleName then
                self:CreateAssetBundleAsync(dependance)
                -- ab缓存对依赖持有的引用
                self:IncreaseReferenceCount(dependance)
            end
        end
        loader:Init(assetbundleName, dependancies)
    else
        loader:Init(assetbundleName)
    end

    self:CreateAssetBundleAsync(assetbundleName)
    -- 加载器持有的引用：同一个ab能同时存在多个加载器，等待ab创建器完成
    self:IncreaseReferenceCount(assetbundleName)
    return loader
end

-- 重新请求加载所有失败的Assetbundle资源，注意不要调用此方法，使用上面的LoadAssetBundleAsync
-- 注意不要调用此方法 注意不要调用此方法 注意不要调用此方法
function AssetBundleMgr:ReLoadABAsync()
    for i = #self.m_prosessingAssetBundleAsyncLoader, 1, -1 do
        local loader = self.m_prosessingAssetBundleAsyncLoader[i]
        if loader:IsFail() then
            local assetbundleName = loader:GetABName()
            if self.m_manifest then
                local dependancies = self.m_manifest:GetAllDependencies(assetbundleName)
                for i = 0, dependancies.Length-1 do
                    local dependance = dependancies[i]
                    if dependance and dependance ~= '' and dependance ~= assetbundleName then
                        self:CreateAssetBundleAsync(dependance)
                        -- ab缓存对依赖持有的引用
                        self:IncreaseReferenceCount(dependance)
                    end
                end
                loader:Init(assetbundleName, dependancies)
            else
                loader:Init(assetbundleName)
            end
            self:CreateAssetBundleAsync(assetbundleName)
        end
    end
end

-- 异步请求Asset资源，AB是否缓存取决于是否设置为常驻包，Assets一律缓存，处理依赖
function AssetBundleMgr:LoadAssetAsync(assetPath, assetType, callback)
    if IsEditor and AssetBundleConfig.IsEditorMode then
        local path = ABConfig.PackagePathToAssetsPath(assetPath)
        local target = AssetDatabase.LoadAssetAtPath(path, assetType)
        local loader = AssetLoaderFactory:GetInstance():GetEditorLoader()
        loader:InitWithAsset(target, callback)
        return loader
    end

    local status,assetbundleName,assetName = self:MapAssetPath(assetPath)
    if not status then
        Logger.LogError("No assetbundle at asset path :" .. assetPath)
        return nil
    end

    local loader = AssetLoaderFactory:GetInstance():GetAsyncLoader()
    table_insert(self.m_prosessingAssetAsyncLoader, loader)
    if self:IsAssetLoaded(assetName) then
        loader:InitWithAsset(assetName, self:GetAssetCache(assetName), callback)
        return loader
    else
        local assetbundleLoader = self:LoadAssetBundleAsync(assetbundleName)
        loader:InitWithABLoader(assetName, assetbundleLoader, callback)
        return loader
    end
end

-- 同步加载资源
function AssetBundleMgr:LoadAssetSync(assetPath, assetType)
    assert(string.endswith(assetPath, ".prefab", true), "LoadAssetSync only load prefab : " .. assetPath)

    if IsEditor and AssetBundleConfig.IsEditorMode then
        local path = ABConfig.PackagePathToAssetsPath(assetPath)
        local target = AssetDatabase.LoadAssetAtPath(path, assetType)
        return target
    end

    local status,assetbundleName,assetName = self:MapAssetPath(assetPath)
    if not status then
        Logger.LogError("No assetbundle at asset path :" .. assetPath)
        return nil
    end

    if self:IsAssetLoaded(assetName) then
        return self:GetAssetCache(assetName)
    else
        self:LoadAssetBundleSync(assetbundleName)
        return self:GetAssetCache(assetName)
    end
end

-- 同步加载Assetbundle资源，目标AB不缓存，依赖的ab缓存，Assets一律缓存，处理依赖
function AssetBundleMgr:LoadAssetBundleSync(assetbundleName)
    if IsEditor and AssetBundleConfig.IsEditorMode then
        Logger.LogError("Editor mode don't need load assetbundle!")
        return
    end

    if self.m_manifest then
        local dependancies = self.m_manifest:GetAllDependencies(assetbundleName)
        for i = 0, dependancies.Length-1 do
            local dependance = dependancies[i]
            if dependance and dependance ~= '' and dependance ~= assetbundleName then
                while self.m_webRequesting[dependance] ~= nil do end
                if not self:IsAssetBundleLoaded(dependance) then
                    local loader = ABLoaderFactory:GetInstance():GetSyncLoader()
                    local url, removeRecord = self:SafeGetABFileUrl(dependance)
                    local ab, www = loader:SyncLoad(url, dependance)
                    if ab then
                        self:AddAssetBundleCache(dependance, ab)
                        if removeRecord then
                            AssetBundleHelper.RemoveABFromDontUpdatableFile(dependance)
                        end
                    else
                        Logger.LogError("Sync load assetbundle fail, abname: " .. dependance)
                        loader:Dispose()
                        return
                    end
                end
            end
        end
    end

    while self.m_webRequesting[assetbundleName] ~= nil do end
    if self:IsAssetBundleLoaded(assetbundleName) then
        self:AddAssetbundleAssetsCache(assetbundleName)
    else
        local abLoader = ABLoaderFactory:GetInstance():GetSyncLoader()
        local url,removeRecord = self:SafeGetABFileUrl(assetbundleName)
        local ab, www = abLoader:SyncLoad(url, assetbundleName)
        if ab then
            self:AddAssetBundleCache(assetbundleName, ab)
            self:AddAssetbundleAssetsCache(assetbundleName)
            table_insert(self.m_syncList, abLoader)

            if removeRecord then
                -- Logger.Log("Remove donot update record : " .. assetbundleName)
                AssetBundleHelper.RemoveABFromDontUpdatableFile(assetbundleName)
            end
        else
            Logger.LogError("Sync load assetbundle fail, abname: " .. assetbundleName)
            abLoader:Dispose()
        end
    end
end

-- 从服务器下载网页内容，需提供完整url
function AssetBundleMgr:DownloadWebResourceAsync(url)
    local loader = ResourceAsyncLoaderFactory:GetInstance():GetLoader()
    loader:Init(url, url, true)
    self.m_webRequesting[url] = loader
    table_insert(self.m_webRequesterQueue, loader)
    return loader
end

-- 从资源服务器下载非Assetbundle资源
function AssetBundleMgr:DownloadAssetFileAsync(filePath)
    local downloadURL = self:GetDownloadUrl()
    if not downloadURL then
        Logger.LogError("You should set download url first!!!")
        return nil
    end

    local loader = ResourceAsyncLoaderFactory:GetInstance():GetLoader()
    loader:Init(downloadURL .. filePath, filePath, true)
    self.m_webRequesting[filePath] = loader
    table_insert(self.m_webRequesterQueue, loader)
    return loader
end

-- 从资源服务器下载Assetbundle资源，不缓存，无依赖
function AssetBundleMgr:DownloadAssetBundleAsync(filePath)
    -- 如果ResourceWebRequester升级到使用UnityWebRequester，那么下载AB和下载普通资源需要两个不同的DownLoadHandler
    -- 兼容升级的可能性，这里也做一下区分
    return self:DownloadAssetFileAsync(filePath)
end

-- 本地异步请求非Assetbundle资源
function AssetBundleMgr:RequestStreamingAssetFileAsync(filePath)
    local loader = ResourceAsyncLoaderFactory:GetInstance():GetLoader()
    local url = AssetBundleUtility.GetStreamingAssetsFilePath(filePath)
    loader:Init(url, filePath, true)
    self.m_webRequesting[filePath] = loader
    table_insert(self.m_webRequesterQueue, loader)
    return loader
end

-- 本地异步请求Assetbundle资源，不缓存，无依赖
function AssetBundleMgr:RequestAssetBundleAsync(assetbundleName)
    local loader = ResourceAsyncLoaderFactory:GetInstance():GetLoader()
    local url = AssetBundleUtility.GetAssetBundleFileUrl(assetbundleName)
    loader:Init(url, assetbundleName, true)
    self.m_webRequesting[assetbundleName] = loader
    table_insert(self.m_webRequesterQueue, loader)
    return loader
end

function AssetBundleMgr:UnloadAssetBundleDependencies(assetbundleName)
    if self.m_manifest then
        local dependancies = self.m_manifest:GetAllDependencies(assetbundleName)
        for i = 0, dependancies.Length-1 do
            local dependance = dependancies[i]
            if dependance and dependance ~= '' and dependance ~= assetbundleName then
                self:UnloadAssetBundle(dependance)
            end
        end
    end
end

function AssetBundleMgr:UnloadAssetBundle(assetbundleName, unloadResident, unloadAllLoadedObjects)
    local count = self:GetReferenceCount(assetbundleName)
    if count <= 0 then
        return false
    end

    count = self:DecreaseReferenceCount(assetbundleName)
    if count > 0 then
        return false
    end

    local assetbundle = self:GetAssetBundleCache(assetbundleName)
    if assetbundle then
        local isResident = self:IsAssetBundleResident(assetbundleName)
        if not isResident or unloadResident then
            unloadAllLoadedObjects = unloadAllLoadedObjects or false
            assetbundle:Unload(unloadAllLoadedObjects)
            self:RemoveAssetBundleCache(assetbundleName)
            -- self:UnloadAssetBundleDependencies(assetbundleName)
            return true
        end
    end
    return false
end

function AssetBundleMgr:TryUnloadAssetBundle(assetbundleName, unloadAllLoadedObjects)
    local count = self:GetReferenceCount(assetbundleName)
    if count > 0 then
        return false
    end

    return UnloadAssetBundle(assetbundleName, true, unloadAllLoadedObjects)
end

function AssetBundleMgr:CleanUpWhenSwitchScene()
    self:ClearAssetsCache()
    self:UnloadUnusedAssetBundles()
end

function AssetBundleMgr:GetRemainWhenSwitchScene()
    local remainABList = {}
    for assetName, _ in pairs(self.m_residentAssetList) do
        local status,assetbundleName = self:MapAssetPath(assetName)
        if status then
            self:GetRemainABWhenSwitchScene(assetbundleName, remainABList)
        else
            Logger.LogError("No assetbundle at asset path :" .. assetName)
        end
    end
    return remainABList
end

function AssetBundleMgr:GetRemainABWhenSwitchScene(assetbundleName, remainABList)
    remainABList[assetbundleName] = true
    if self.m_manifest then
        local dependancies = self.m_manifest:GetAllDependencies(assetbundleName)
        for i = 0, dependancies.Length-1 do
            local dependance = dependancies[i]
            if dependance and dependance ~= '' and dependance ~= assetbundleName then
                self:GetRemainABWhenSwitchScene(dependance, remainABList)
            end
        end
    end
end

function AssetBundleMgr:UnloadUnusedAssetBundles()
    -- 等待所有请求完成
    -- 要是不等待Unity很多版本都有各种Bug
    coroutine.waituntil(function()
        return #self.m_prosessingWebRequester == 0
    end)

    coroutine.waituntil(function()
        return #self.m_prosessingAssetBundleAsyncLoader == 0
    end)

    coroutine.waituntil(function()
        return #self.m_prosessingAssetAsyncLoader == 0
    end)

    local deleteList = {}
    local remainABList = self:GetRemainWhenSwitchScene()

    for abName, ab in pairs(self.m_assetbundlesCaching) do
        if ab then
            local isResident = self:IsAssetBundleResident(abName)
            if not isResident then
                if not remainABList[abName] then
                    self:ClearReferenceCount(abName)
                    ab:Unload(true)
                    table_insert(deleteList, abName)
                end
            end
        end
    end

    for _,abName in pairs(deleteList) do
        if abName then
            self:RemoveAssetBundleCache(abName)
        end
    end
end

function AssetBundleMgr:MapAssetPath(assetPath)
    return self.m_assetsPathMapping:MapAssetPath(assetPath)
end

function AssetBundleMgr:Update()
    self:OnProsessingWebRequester()
    self:OnProsessingAssetBundleAsyncLoader()
    self:OnProsessingAssetAsyncLoader()
    self:OnProcessingAssetSyncLoader()
    self:CheckDownloadState()
end

function AssetBundleMgr:OnProsessingWebRequester()
    for i = #self.m_prosessingWebRequester, 1, -1 do
        local loader = self.m_prosessingWebRequester[i]
        loader:Update()
        if loader:IsDone() then
            table_remove(self.m_prosessingWebRequester, i)
            self.m_webRequesting[loader:GetABName()] = nil
            self:UnloadAssetBundle(loader:GetABName())
            if loader:NeedDownload() then
                if not loader:GetError() then
                    self:RemoveABFromDontUpdatableArray(loader:GetABName())
                end
                for i, downloadLoader in ipairs(self.m_downloadList) do
                    if downloadLoader == loader then
                        table_remove(self.m_downloadList, i)
                        break
                    end
                end
            end
            if loader:IsCache() then
                -- 说明：有错误也缓存下来，只不过资源为空
                -- 1、避免再次错误加载
                -- 2、如果不存下来加载器将无法判断什么时候结束
                self:AddAssetBundleCache(loader:GetABName(), loader:GetAssetbundle())
                loader:Dispose()
            end
        end
    end

    local slotCount = #self.m_prosessingWebRequester
    while slotCount < MAX_ASSETBUNDLE_CREATE_NUM and #self.m_webRequesterQueue > 0 do
        local loader = table_remove(self.m_webRequesterQueue, 1)
        coroutine.start(loader.Start, loader)
        table_insert(self.m_prosessingWebRequester, loader)
        slotCount = slotCount + 1
    end
end

function AssetBundleMgr:OnProsessingAssetBundleAsyncLoader()
    for i = #self.m_prosessingAssetBundleAsyncLoader, 1, -1 do
        local loader = self.m_prosessingAssetBundleAsyncLoader[i]
        loader:Update()
        if loader:CanUnload() then
            self:UnloadAssetBundle(loader:GetABName())
            table_remove(self.m_prosessingAssetBundleAsyncLoader, i)
            loader:Dispose()
        elseif loader:IsFail() then
            ABTipsMgr:GetInstance():ShowABLoadFailTips(Bind(self, self.ReLoadABAsync))
        end
    end
end

function AssetBundleMgr:OnProsessingAssetAsyncLoader()
    for i = #self.m_prosessingAssetAsyncLoader, 1, -1 do
        local loader = self.m_prosessingAssetAsyncLoader[i]
        loader:Update()
        if loader:IsDone() then
            table_remove(self.m_prosessingAssetAsyncLoader, i)
        end
    end
end

function AssetBundleMgr:CheckDownloadState()
    local downloadCount = #self.m_downloadList
    if downloadCount == 0 and self.m_lastDownloadCount == 0 then
        return
    end

    if not SceneManagerInst:IsLoadingScene() then
        if self.m_lastDownloadCount == 0 and downloadCount > 0 then
            UIManagerInst:OpenWindow(UIWindowNames.UIDownloadTips)
        elseif self.m_lastDownloadCount > 0 and downloadCount == 0 then
            UIManagerInst:CloseWindow(UIWindowNames.UIDownloadTips)
        end
    end

    self.m_lastDownloadCount = downloadCount
end

function AssetBundleMgr:GetDownloadingABInfo()
    if #self.m_downloadList == 0 or not SceneManagerInst:IsLoadingScene() then
        return
    end

    local loader = self.m_downloadList[1]
    return loader:GetABName(), loader:Progress()
end

function AssetBundleMgr:OnProcessingAssetSyncLoader()
    for i = #self.m_syncList, 1, -1 do
        local loader = self.m_syncList[i]
        loader:Update()
        if loader:CanUnload() then
            self:UnloadAssetBundle(loader:GetABName())
            loader:Dispose()
            table_remove(self.m_syncList, i)
        end
    end
end

-- 这里的ab包不卸载，常驻的ab不一定要取出里面的资产并且常驻
function AssetBundleMgr:GetResidentABList()
    return {
        "effectcommonmat/materialseffectcommonmat.assetbundle",
        "shaders.assetbundle",
        "ui/atlas/commonatlas.assetbundle",
        "ui/fonts/hei_simple_ttffonts.assetbundle",
        "effectcommonmat/dynamicmaterialseffectcommonmat.assetbundle",
        "ui/atlas/dynamicloadatlas.assetbundle",
        "ui/atlas/dynamicload2atlas.assetbundle",
        "ui/atlas/itemiconatlas.assetbundle",
        "ui/atlas/roleiconatlas.assetbundle",
    }
end

-- 重要 重要 重要 : 没有依赖的assetbundle才能设置资产不卸载，有依赖的需要慎重考虑
-- 这里的ab包中所有的资产不卸载，和上面的列表有有区别，ab包卸不卸载都不影响资产不卸载，ab包卸载了资产依旧可以使用，但是有一种情况需要注意
-- 比如A包依赖B包，B包没有设置常驻（那么B包作为依赖包会在当前场景保留，切换场景时会卸载），但是A包中的资产常驻了，为了保证A包中的常驻资产
-- 能正常依赖到B包，就会导致B包在切换场景时不卸载，所以这里使用要注意：没有依赖的assetbundle才能设置资产不卸载，有依赖的需要慎重考虑
function AssetBundleMgr:GetABListForResidentAsset()     -- 说明：AB中的资产一直不卸载
    if not self.m_abListForResidentAsset then
        self.m_abListForResidentAsset = {
            ["effectcommonmat/dynamicmaterialseffectcommonmat.assetbundle"] = true,
            ["ui/atlas/dynamicloadatlas.assetbundle"] = true,
            ["ui/atlas/dynamicload2atlas.assetbundle"] = true,
            ["ui/atlas/itemiconatlas.assetbundle"] = true,
            ["ui/atlas/roleiconatlas.assetbundle"] = true,
            ["ui/prefabs/loadingprefabs.assetbundle"] = true,
            ["ui/prefabs/commonprefabs.assetbundle"] = true,
            ["sound/uisound.assetbundle"] = true,
        }
    end
    return self.m_abListForResidentAsset
end

-- 需要缓存资产的ab路径列表。资产不一定常驻，ab也不一定常驻。 如果资产常驻，就要在这里配置上缓存资产，否则资产常驻但是实际并不去缓存，那也没有什么意义
-- 需要取资产的最好都预加载，取资产性能消耗比较大
function AssetBundleMgr:GetABPathListForCacheAsset()        -- 说明：AB中的资产在当前场景缓存
    if not self.m_abPathListForCacheAsset then
        self.m_abPathListForCacheAsset = {
            -- 为了效率考虑，单独处理
            -- "ui/prefabs", --UI里面的prefab基本打开一个界面，里面的东西都会用到，但是不需要常驻，切场景卸载就行了
            ["effect/commoneffect.assetbundle"] = true,
            ["effectcommonmat/dynamicmaterialseffectcommonmat.assetbundle"] = true,
            ["ui/atlas/battledynamicloadatlas.assetbundle"] = true, -- 战斗动态图集的ab包不卸载，如果有其他ab包依赖该图集会造成该图集被重复加载
            ["ui/atlas/dynamicloadatlas.assetbundle"] = true,
            ["ui/atlas/dynamicload2atlas.assetbundle"] = true,
            ["ui/atlas/itemiconatlas.assetbundle"] = true,
            ["ui/atlas/roleiconatlas.assetbundle"] = true,
            ["ui/prefabs/loadingprefabs.assetbundle"] = true,
            ["ui/prefabs/commonprefabs.assetbundle"] = true,
            ["sound/uisound.assetbundle"] = true,
        }
    end
    return self.m_abPathListForCacheAsset
end

function AssetBundleMgr:NeedCacheAsset(abName)
    local abPathList = self:GetABPathListForCacheAsset()
    if abPathList[abName] then
        return true
    else
        if string_contains(abName, "ui/prefabs/") then
            return true
        elseif string_contains(abName, "timeline/(.*).assetbundle", false) then
            return true
        elseif string_contains(abName, "sound/role/") then
            return true            
        elseif string_contains(abName, "sound/atk") then
            return true
        elseif (SceneManagerInst:IsBattleScene() or SceneManagerInst:IsLoadingScene()) and string_contains(abName, "models/(.*).assetbundle", false) then
            return true
        else
            return false
        end
    end
end

function AssetBundleMgr:IsAssetsResident(abName)
    local abList = self:GetABListForResidentAsset()
    return abList[abName]
end

-- 调试接口，用来查看项目中有没有错误依赖
function AssetBundleMgr:CheckAssetbundleDependence()
    local allAssetbundleNames = self.m_manifest:GetAllAssetBundleNames()
    if allAssetbundleNames then
        local length = allAssetbundleNames.Length
        for i = 0, length-1 do
            local abName = allAssetbundleNames[i]
            if abName and abName ~= '' then
                local count = 0
                for j = 0, length-1 do
                    local checkABName = allAssetbundleNames[j]
                    if checkABName and checkABName ~= '' and checkABName ~= abName then
                        local allDependencies = self.m_manifest:GetAllDependencies(checkABName)
                        for k = 0, allDependencies.Length-1 do
                            if allDependencies[k] == abName then
                                count = count + 1
                                -- Logger.Log("AbName:" .. abName .. ", dependencesCount: " .. count .. ", checkABName: " .. checkABName)
                            end
                        end
                    end
                end

                -- if count >= 2 then
                --     Logger.Log("SetResident abName:" .. abName .. ", dependencesCount: " .. count)
                -- end
            end
        end
    end
end

return AssetBundleMgr