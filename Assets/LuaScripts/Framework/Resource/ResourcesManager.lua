--[[
-- added by wsh @ 2017-12-01
-- 资源管理系统：提供资源加载管理
-- 注意：
-- 1、只提供异步接口，即使内部使用的是同步操作，对外来说只有异步
-- 2、两套API：使用回调（任何不带"Co"的接口）、使用协程（任何带"Co"的接口）
-- 3、对于串行执行一连串的异步操作，建议使用协程（用同步形式的代码写异步逻辑），回调方式会使代码难读
-- 4、所有lua层脚本别直接使用cs侧的AssetBundleMgr，都来这里获取接口
-- 5、理论上做到逻辑层脚本对AB名字是完全透明的，所有资源只有packagePath的概念，这里对路径进行处理
--]]

local ResourcesManager = BaseClass("ResourcesManager", Singleton)
local AssetBundleUtility = CS.AssetBundles.AssetBundleUtility
local IsEditor = CS.GameUtility.IsEditor()
local AssetBundleConfig = CS.AssetBundles.AssetBundleConfig
local SplitString = CUtil.SplitString

-- 设置常驻包
-- 注意：
-- 1、公共包（被2个或者2个其它AB包所依赖的包）底层会自动设置常驻包
-- 2、任何情况下不想被卸载的非公共包（如Lua脚本）需要手动设置常驻包
local function SetAssetBundleResident(self, path, resident)
	local assetbundleName = AssetBundleUtility.AssetBundlePathToAssetBundleName(path)
	resident = resident and true or false
	AssetBundleMgrInst:SetAssetBundleResident(assetbundleName, resident)
end

-- 异步加载AssetBundle：回调形式
local function LoadAssetBundleAsync(self, path, callback, ...)
	assert(path ~= nil and type(path) == "string" and #path > 0, "path err : "..path)
	assert(callback ~= nil and type(callback) == "function", "Need to provide a function as callback")
	local args = SafePack(...)
	coroutine.start(function()
		local assetbundle = self:CoLoadAssetBundleAsync(path, nil)
		callback(SafeUnpack(args))
	end)
end

-- 异步加载AssetBundle：协程形式
local function CoLoadAssetBundleAsync(self, path, progress_callback)
	assert(path ~= nil and type(path) == "string" and #path > 0, "path err : "..path)
	local assetbundleName = AssetBundleUtility.AssetBundlePathToAssetBundleName(path)
	local loader = AssetBundleMgrInst:LoadAssetBundleAsync(assetbundleName)
	coroutine.waitforasyncloader(loader, progress_callback)
end

local function LoadSync(self, path, res_type)
	assert(path ~= nil and type(path) == "string" and #path > 0, "path err : "..path)	
	local loader = AssetBundleMgrInst:LoadAssetAsync(path, res_type, function()

	end)
	local asset = loader:GetAsset()
    loader:Dispose()
	if IsNull(asset) then
		Logger.LogError("Asset load err : "..path)
	end
	return asset
end

-- 异步加载Asset：回调形式
local function LoadAsync(self, path, res_type, callback, ...)
	assert(path ~= nil and type(path) == "string" and #path > 0, "path err : "..path)
	assert(callback ~= nil and type(callback) == "function", "Need to provide a function as callback")

	local args = SafePack(nil, ...)
	local downloadList = {}
	local bRet = AssetBundleMgrInst:IsAssetNeedDownload(path, downloadList)
	if bRet and not GuideMgr:GetInstance():IsPlayingGuide() then
		ABTipsMgr:GetInstance():ShowABLoadTips(downloadList, function()
			coroutine.start(function()
				local asset = self:CoLoadAsync(path, res_type, nil)
				args[1] = asset
				callback(SafeUnpack(args))
			end)
		end)
	else
		AssetBundleMgrInst:LoadAssetAsync(path, res_type, function(loader, asset)
			if IsNull(asset) then
				Logger.LogError("Asset load err : "..path)
			end
			args[1] = asset
			callback(SafeUnpack(args))

            loader:Dispose()
		end)
	end
end

-- 同步加载Asset，给UI使用，其他场合不要使用
local function LoadPrefabSync(self, path, res_type, callback)
	assert(path ~= nil and type(path) == "string" and #path > 0, "path err : "..path)
	assert(callback ~= nil and type(callback) == "function", "Need to provide a function as callback")

	local downloadList = {}
	local abmgr = AssetBundleMgrInst
	local bRet = abmgr:IsAssetNeedDownload(path, downloadList)
	if bRet and not GuideMgr:GetInstance():IsPlayingGuide() then
		ABTipsMgr:GetInstance():ShowABLoadTips(downloadList, function()
			local asset = abmgr:LoadAssetSync(path, res_type)
			callback(asset)
		end)
	else
		local asset = abmgr:LoadAssetSync(path, res_type)
		callback(asset)
	end
end

-- 异步加载Asset：协程形式
local function CoLoadAsync(self, path, res_type, progress_callback)
	assert(path ~= nil and type(path) == "string" and #path > 0, "path err : "..path)
	local loader = AssetBundleMgrInst:LoadAssetAsync(path, res_type, function()

	end)
	coroutine.waitforasyncloader(loader, progress_callback)
	local asset = loader:GetAsset()
    loader:Dispose()
	if IsNull(asset) then
		Logger.LogError("Asset load err : "..path)
	end
	return asset
end

-- 清理资源：切换场景时调用
local function Cleanup(self)
	AssetBundleMgrInst:CleanUpWhenSwitchScene()
	return coroutine.yieldbreak()
end

function ResourcesManager:CoDownloadAllAssetbundle()
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return coroutine.yieldbreak()
    end
    
    local abList = AssetBundleMgrInst:CopyDontUpdatableABArray()
	if #abList <= 0 then
		return coroutine.yieldbreak()
    end
    
    local curABName = nil
    local totalABSize = AssetBundleMgrInst:GetAllNeedDownloadABSize()
    local alreadyDownloadSize = 0

    for _, abName in ipairs(abList) do
        local nameList = SplitString(abName , '.')
		if #nameList > 1 then
			local fileNameList = SplitString(nameList[1], '/')
			if fileNameList and #fileNameList > 0 then
				curABName = fileNameList[#fileNameList]
			else
				curABName = nameList[1]
			end
            local curABSize = AssetBundleMgrInst:GetABSize(abName)
			self:CoDownloadAssetBundleAsync(nameList[1], function(co, progress)
				assert(progress <= 1.0, "What's the fuck!!!")
				return coroutine.yieldcallback(co, progress, curABName, alreadyDownloadSize + curABSize * progress, totalABSize)
			end)

            alreadyDownloadSize = alreadyDownloadSize + curABSize
            coroutine.yieldreturn(1, curABName, alreadyDownloadSize, totalABSize)
        end
	end
	
	return coroutine.yieldbreak()
end

-- 异步加载AssetBundle：协程形式
local function CoDownloadAssetBundleAsync(self, path, progress_callback)
	assert(path ~= nil and type(path) == "string" and #path > 0, "path err : "..path)
	local assetbundleName = AssetBundleUtility.AssetBundlePathToAssetBundleName(path, false)
	local loader = AssetBundleMgrInst:LoadAssetBundleAsync(assetbundleName)
	coroutine.waitforasyncloader(loader, progress_callback)
end

ResourcesManager.SetAssetBundleResident = SetAssetBundleResident
ResourcesManager.LoadAssetBundleAsync = LoadAssetBundleAsync
ResourcesManager.CoLoadAssetBundleAsync = CoLoadAssetBundleAsync
ResourcesManager.LoadAsync = LoadAsync
ResourcesManager.LoadSync = LoadSync
ResourcesManager.CoLoadAsync = CoLoadAsync
ResourcesManager.Cleanup = Cleanup
ResourcesManager.LoadPrefabSync = LoadPrefabSync
ResourcesManager.CoDownloadAssetBundleAsync = CoDownloadAssetBundleAsync

return ResourcesManager
