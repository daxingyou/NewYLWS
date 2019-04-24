
local AssetBundleUtility = CS.AssetBundles.AssetBundleUtility
local AssetBundleConfig = CS.AssetBundles.AssetBundleConfig
local BuildUtils = CS.BuildUtils
local GameUtility = CS.GameUtility
local UINoticeTip = CS.UINoticeTip
local string_len = string.len
local IsEditor = CS.GameUtility.IsEditor()
local SimpleHttp = CS.SimpleHttp
local DataUtils = CS.DataUtils
local XLuaManager = CS.XLuaManager
local table_remove = table.remove
local table_insert = table.insert
local SplitString = CUtil.SplitString
local ABConfig = ABConfig
local string_contains = string.contains
local AssetBundleHelper = CS.AssetBundles.AssetBundleHelper
local Logger = Logger
local MAX_DOWNLOAD_NUM = 5
local UPDATE_SIZE_LIMIT = 5 * 1024 * 1024
local Language = Language
local string_format = string.format
local APK_FILE_PATH = "/xyl_%s_%s.apk"

local AssetbundleUpdater = BaseClass("AssetbundleUpdater")

function AssetbundleUpdater:__init()
    self.m_noticeUrl = false
    self.m_resVersionPath = false
    self.m_noticeVersionPath = false
    self.m_clientResVersion = false
    self.m_serverResVersion = false
    self.m_streamingAppVersion = false
    self.m_clientNoticeVersion = false
    self.m_serverAppVersion = false

    self.m_needDownloadGame = false
    self.m_needUpdateGame = false
    self.m_needUpdateNotice = false

    self.m_timeStamp = 0
    self.m_isDownloading = false
    self.m_hostManifestLoader = nil
    self.m_hostManifest = nil
    self.m_needDownloadList = {}
    self.m_downloadingRequest = {}

    self.m_downloadSize = 0
    self.m_totalDownloadCount = 0
    self.m_finishedDownloadCount = 0

    self.m_statusText = nil
    self.m_slider = nil
    self.m_transform = nil
    self.m_gameObject = nil
end

function AssetbundleUpdater:Init()
    self.m_gameObject = CS.UnityEngine.GameObject.Find("UIRoot/LuanchLayer/UILoading")
    self.m_transform = self.m_gameObject.transform
    self.m_statusText = self.m_transform:Find("ContentRoot/LoadingDesc"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.m_slider = self.m_transform:Find("ContentRoot/SliderBar"):GetComponent(typeof(CS.UnityEngine.UI.Slider))
    -- self.m_slider.gameObject:SetActive(false)

    self.m_resVersionPath = AssetBundleUtility.GetPersistentDataPath(ABConfig.ResVersionFileName)
    self.m_noticeVersionPath = AssetBundleUtility.GetPersistentDataPath(ABConfig.NoticeVersionFileName)
    self.m_timeStamp = os.time()
    self.m_statusText.text = Language.GetString(815)
end

function AssetbundleUpdater:Start()
    coroutine.yieldstart(self.InitPackageName, nil, self)
    coroutine.yieldstart(self.InitAppVersion, nil, self)
	coroutine.yieldstart(AssetBundleMgrInst.Initialize, nil, AssetBundleMgrInst)
    coroutine.yieldstart(self.CheckUpdateOrDownloadGame, nil, self)
end

function AssetbundleUpdater:InitAppVersion()
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return coroutine.yieldbreak()
    end
    local appVersionRequest = AssetBundleMgrInst:RequestStreamingAssetFileAsync(ABConfig.AppVersionFileName)
    coroutine.waituntil(appVersionRequest.IsDone, appVersionRequest)
    self.m_streamingAppVersion = appVersionRequest:GetText()
    PlatformMgr:GetInstance():SetAppVersion(self.m_streamingAppVersion)
    appVersionRequest:Dispose()

    local appVersionPath = AssetBundleUtility.GetPersistentDataPath(ABConfig.AppVersionFileName)
    local persistentAppVersion = GameUtility.SafeReadAllText(appVersionPath)
    Logger.Log(string_format("streamingAppVersion = %s, persistentAppVersion = %s", self.m_streamingAppVersion, persistentAppVersion))

    local backupStartupUrlPath = AssetBundleUtility.GetPersistentDataPath(ABConfig.StartUpFileName)
    Setting.SetBackupStartupUrl(GameUtility.SafeReadAllText(backupStartupUrlPath))

    -- 如果persistent目录版本比streamingAssets目录app版本低，说明是大版本覆盖安装，清理过时的缓存
    if persistentAppVersion and persistentAppVersion ~= '' and BuildUtils.CheckIsNewVersion(persistentAppVersion, self.m_streamingAppVersion) then
        GameUtility.SafeDeleteDir(AssetBundleUtility.GetPersistentDataPath())
        AssetBundleHelper.ClearCache()
    end
    GameUtility.SafeWriteAllText(appVersionPath, self.m_streamingAppVersion)
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:InitPackageName()
    if IsEditor and AssetBundleConfig.IsEditorMode then
        return coroutine.yieldbreak()
    end
    local packageNameRequest = AssetBundleMgrInst:RequestStreamingAssetFileAsync(ABConfig.PackageNameFileName)
    coroutine.waituntil(packageNameRequest.IsDone, packageNameRequest)
    local packageName = packageNameRequest:GetText()
    AssetBundleMgrInst:SetManifestABName(packageName)
    PlatformMgr:GetInstance():Init(packageName)
    packageNameRequest:Dispose()
    Logger.Log("packageName = " .. packageName)
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:CheckUpdateOrDownloadGame()
    -- EditorMode总是跳过资源更新
    if IsEditor and AssetBundleConfig.IsEditorMode then
        coroutine.yieldstart(self.StartGame, nil, self)
        return coroutine.yieldbreak()
    end

    coroutine.waitforframes(1)
    local start = os.clock()
    coroutine.yieldstart(self.InitLocalVersion, nil, self)
    Logger.Log("InitLocalVersion use "..self:GetExecuteTime(start).."ms")

    start = os.clock()
    coroutine.yieldstart(self.InitSDK, nil, self)
    Logger.Log("InitSDK use "..self:GetExecuteTime(start).."ms")

    self.m_serverResVersion = self.m_clientResVersion
    if PlatformMgr:GetInstance():IsInternalVersion() then
        -- 内部版本不做大版本更新，不做公告，每次都检测资源更新
        coroutine.yieldstart(self.InternalGetUrlList, nil, self)
        coroutine.yieldstart(self.GetUpdatableABListAtStartFile, nil, self)
        local isUpdate = coroutine.yieldstart(self.CheckGameUpdate, nil, self, true)
        if isUpdate then
            -- 重启lua虚拟机
            XLuaManager.Instance:Restart()
        else
            coroutine.yieldstart(self.StartGame, nil, self)
        end
    else
        -- 外部版本一律使用外网服务器更新
        coroutine.yieldstart(self.GetUrlList, nil, self)
        coroutine.yieldstart(self.WriteNoticeFile, nil, self)
        if self.m_needDownloadGame then
            UIManagerInst:OpenOneButtonTip(Language.GetString(800), Language.GetString(801), Language.GetString(802))
            coroutine.waituntil(function ()
                return UINoticeTip.LastClickIndex ~= -1
            end)
            coroutine.yieldstart(self.DownloadGame, nil, self)
        elseif self.m_needUpdateGame then
            coroutine.yieldbreak(self.UpdateAssetMapFile, nil, self)
            coroutine.yieldstart(self.GetUpdatableABListAtStartFile, nil, self)
            local isUpdate = coroutine.yieldstart(self.CheckGameUpdate, nil, self, false)
            if isUpdate then
                -- 重启lua虚拟机
                XLuaManager.Instance:Restart()
            else
                coroutine.yieldstart(self.StartGame, nil, self)
            end
        else
            coroutine.yieldstart(self.GetUpdatableABListAtStartFile, nil, self)
            coroutine.yieldstart(self.StartGame, nil, self)
        end
    end
    return coroutine.yieldbreak()
end
    
function AssetbundleUpdater:InitLocalVersion()
    local resVersionLoader = AssetBundleMgrInst:RequestStreamingAssetFileAsync(ABConfig.ResVersionFileName)
    coroutine.waituntil(resVersionLoader.IsDone, resVersionLoader)
    local streamingResVersion = resVersionLoader:GetText()
    resVersionLoader:Dispose()
    local persistentResVersion = GameUtility.SafeReadAllText(self.m_resVersionPath)

    if persistentResVersion and persistentResVersion ~= '' then
        self.m_clientResVersion = BuildUtils.CheckIsNewVersion(streamingResVersion, persistentResVersion) and persistentResVersion or streamingResVersion
    else
        self.m_clientResVersion = streamingResVersion
    end
    
    GameUtility.SafeWriteAllText(self.m_resVersionPath, self.m_clientResVersion)

    local persistentNoticeVersion = GameUtility.SafeReadAllText(self.m_noticeVersionPath);
    if not persistentNoticeVersion or persistentNoticeVersion == '' then
        persistentNoticeVersion = "1.0.0"
    end
    PlatformMgr:GetInstance():SetNoticeVersion(persistentNoticeVersion)
    self.m_clientNoticeVersion = persistentNoticeVersion

    Logger.Log("streamingResVersion = " ..streamingResVersion.. ", persistentResVersion = "..(persistentResVersion or "nil")..", persistentNoticeVersion = " .. persistentNoticeVersion)
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:InitSDK()
    local SDKInitComplete = false
    PlatformMgr:GetInstance():InitSDK(function()
        SDKInitComplete = true
    end)

    coroutine.waituntil(function ()
        return SDKInitComplete
    end)
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:GetUrlList()
    local PlatformMgrInst = PlatformMgr:GetInstance()
    local platform = "package=".. PlatformMgrInst:GetPackageName() .. "&app_version=" ..PlatformMgrInst:GetAppVersion() .. "&res_version=" ..self.m_clientResVersion.. "&notice_version=".. PlatformMgrInst:GetNoticeVersion()
    local GetUrlListComplete = false
    local isFail = false
    local urlList = nil

    local startupUri = Setting.GetStartUpURL()
    print("Start Uri : " .. startupUri)
    SimpleHttp.HttpPost(startupUri, nil, DataUtils.StringToBytes(platform), function(wwwInfo)
        if not wwwInfo or (wwwInfo.error and wwwInfo.error ~= '') then
            isFail = true
        else
            local wwwBytes = wwwInfo.bytes
            if not wwwBytes or string_len(wwwBytes) == 0 then
                isFail = true
            else
                urlList = Json.decode(DataUtils.BytesToString(wwwBytes))
            end
        end

        if isFail then
            local errorMsg = nil
            if not wwwInfo then
                errorMsg = "www null"
            elseif wwwInfo.error == '' then
                errorMsg = "bytes length 0"
            else
                errorMsg = wwwInfo.error
            end
            Logger.LogError("Get url list for platform "..platform.." with err : ".. errorMsg)
        end

        GetUrlListComplete = true
    end)

    coroutine.waituntil(function()
        return GetUrlListComplete
    end)

    if isFail then
        coroutine.yieldstart(self.GetUrlList, nil, self)
    else
        Logger.Log("Get url list success1")
        if urlList["serverlist"] and urlList["serverlist"] ~= '' then
            Setting.SetServerListURL(urlList["serverlist"])
        end
        if urlList["verifying"] and urlList["verifying"] ~= '' then
            Setting.SetLoginURL(urlList["verifying"])
        end
        if urlList["logserver"] and urlList["logserver"] ~= '' then
            Logger.SetReportUri(urlList["logserver"])
        end
        if urlList["order_url"] and urlList["order_url"] ~= '' then
            Setting.SetOrderURL(urlList["order_url"])
        end
        if urlList["aborder_url"] and urlList["aborder_url"] ~= '' then
            Setting.SetABOrderURL(urlList["aborder_url"])
        end
        if urlList["charge_url"] and urlList["charge_url"] ~= '' then
            Setting.SetNotifyURL(urlList["charge_url"])
        end
        if urlList["charge_url1"] and urlList["charge_url1"] ~= '' then
            Setting.SetNotifyURL1(urlList["charge_url1"])
        end
        if urlList["pay_way"] and urlList["pay_way"] ~= '' then
            Setting.SetAppPayWay(urlList["pay_way"])
        end
        if urlList["res_version"] and urlList["res_version"] ~= '' then
            self.m_serverResVersion = urlList["res_version"]
        end
        if urlList["updaterole"] and urlList["updaterole"] ~= '' then
            Setting.SetLoginReportURL(urlList["updaterole"])
        end
        if urlList["frame_data_report_uri"] and urlList["frame_data_report_uri"] ~= '' then
            Setting.SetFrameDataReportUri(urlList["frame_data_report_uri"])
        end
        if urlList["startup_backup"] and urlList["startup_backup"] ~= '' then
            Setting.SetBackupStartupUrl(urlList["startup_backup"])
            local backupStartupUrlPath = AssetBundleUtility.GetPersistentDataPath(ABConfig.StartUpFileName)
            GameUtility.SafeWriteAllText(backupStartupUrlPath, urlList["startup_backup"])
        end
        
        if urlList["notice_version"] and urlList["notice_version"] ~= '' then
            local serverNoticeVersion = urlList["notice_version"]
            if BuildUtils.CheckIsNewVersion(self.m_clientNoticeVersion, serverNoticeVersion) then
                GameUtility.SafeWriteAllText(self.m_noticeVersionPath, serverNoticeVersion)
                PlatformMgr:GetInstance():SetNoticeVersion(serverNoticeVersion)
                self.m_needUpdateNotice = true
            end
        end
        if urlList["notice_url"] and urlList["notice_url"] ~= '' then
            self.m_noticeUrl = urlList["notice_url"]
        end
        if urlList["auto_login"] and urlList["auto_login"] ~= '' then
            Setting.SetAutoLogin(urlList["auto_login"])
        end
        if urlList["res"] and urlList["res"] ~= '' then
            Setting.SetServerResAddr(urlList["res"] .. "/")
        end
        if urlList["app"] and urlList["app"] ~= '' then
            Setting.SetAppAddr(urlList["app"])
            self.m_needDownloadGame = true
        elseif urlList["need_hot"] and urlList["need_hot"] == 1 then
            self.m_needUpdateGame = true
        end
    end
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:GetUpdatableABListAtStartFile()
    local abInstance = AssetBundleMgrInst
    local serverFileLoader = abInstance:DownloadAssetBundleAsync(ABConfig.ABUpdateMapFileName)
    coroutine.waituntil(serverFileLoader.IsDone, serverFileLoader)
    local error = serverFileLoader:GetError()
    if error then
        UIManagerInst:OpenOneButtonTip(Language.GetString(810), Language.GetString(811), Language.GetString(809))
        coroutine.waituntil(function ()
            return UINoticeTip.LastClickIndex ~= -1
        end)
        Logger.LogError("Download ABUpdateFile :  " .. serverFileLoader:GetABName() .. "\n from url : " .. serverFileLoader:GetURL() + "\n err : " .. error)
        serverFileLoader:Dispose()
        coroutine.yieldstart(self.GetUpdatableABListAtStartFile, nil, self)
        return coroutine.yieldbreak()
    end
    
    local streamFileLoader = abInstance:RequestStreamingAssetFileAsync(ABConfig.ABUpdateMapFileName)
    coroutine.waituntil(streamFileLoader.IsDone, streamFileLoader)
    AssetBundleHelper.CompareAndSaveABUpdateFile(serverFileLoader:GetWWW(), streamFileLoader:GetWWW())

    streamFileLoader:Dispose()
    serverFileLoader:Dispose()

    return coroutine.yieldbreak()
end

function AssetbundleUpdater:UpdateAssetMapFile()
    AssetBundleHelper.ClearAllCachedVersions(ABConfig.AssetsMapFileName)
    local fileLoader = AssetBundleMgrInst:DownloadAssetBundleAsync(ABConfig.AssetsMapFileName)
    coroutine.waituntil(fileLoader.IsDone, fileLoader)
    local error = fileLoader:GetError()
    if error then
        UIManagerInst:OpenOneButtonTip(Language.GetString(810), Language.GetString(811), Language.GetString(809))
        coroutine.waituntil(function ()
            return UINoticeTip.LastClickIndex ~= -1
        end)
        Logger.LogError("Download AssetMapFile :  " .. fileLoader:GetABName() .. "\n from url : " .. fileLoader:GetURL() + "\n err : " .. error)
        fileLoader:Dispose()
        coroutine.yieldstart(self.UpdateAssetMapFile, nil, self)
        return coroutine.yieldbreak()
    end
    fileLoader:Dispose()

    return coroutine.yieldbreak()
end

function AssetbundleUpdater:DownloadGame()
    local mobileType = PlatformMgr:GetInstance():GetMobileType()
    if mobileType == "Android" then
        if CS.UnityEngine.Application.internetReachability ~= CS.UnityEngine.NetworkReachability.ReachableViaLocalAreaNetwork then
            UIManagerInst:OpenOneButtonTip(Language.GetString(800), Language.GetString(803), Language.GetString(802))
            coroutine.waituntil(function ()
                return UINoticeTip.LastClickIndex ~= -1
            end)
        end
        local appVersionLoader = AssetBundleMgrInst:DownloadAssetFileAsync(ABConfig.AppVersionFileName)
        coroutine.waituntil(appVersionLoader.IsDone, appVersionLoader)
        self.m_serverAppVersion = appVersionLoader:GetText()

        self:DownloadGameForAndroid()
    elseif mobileType == "IOS" then
        PlatformMgr:GetInstance():StartDownLoadGame(Setting.GetAppAddr())
    end
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:DownloadGameForAndroid()
    self.m_slider.normalizedValue = 0
    self.m_slider.gameObject:SetActive(true)
    PlatformMgr:GetInstance():StartDownLoadGame(Setting.GetAppAddr(), Bind(self, self.DownloadGameSuccess), Bind(self, self.DownloadGameFail), function(progress)
        self.m_slider.normalizedValue = progress / 100
    end, string_format(APK_FILE_PATH, PlatformMgr:GetInstance():GetPackageName(), self.m_serverAppVersion))
end

function AssetbundleUpdater:DownloadGameSuccess()
    UIManagerInst:OpenOneButtonTip(Language.GetString(804), Language.GetString(805), Language.GetString(806), function()
        PlatformMgr:GetInstance():InstallGame(Bind(self, self.DownloadGameSuccess), Bind(self, self.DownloadGameFail))
    end)
end

function AssetbundleUpdater:DownloadGameFail()
    UIManagerInst:OpenOneButtonTip(Language.GetString(807), Language.GetString(808), Language.GetString(809), function()
        self:DownloadGameForAndroid()
    end)
end

function AssetbundleUpdater:ShowUpdatePrompt(downloadSize)
    -- //if (UPDATE_SIZE_LIMIT <= 0 && Application.internetReachability == NetworkReachability.ReachableViaLocalAreaNetwork)
    -- //{
    -- //    // wifi不提示更新了
    -- //    return false;
    -- //}

    -- //if (downloadSize < UPDATE_SIZE_LIMIT)
    -- //{
    -- //    return false;
    -- //}

    return true
end

function AssetbundleUpdater:GetDownloadAssetBundlesSize()
    local request = AssetBundleMgrInst:DownloadAssetBundleAsync(ABConfig.AssetBundlesSizeFileName)
    coroutine.waituntil(request.IsDone, request)
    local error = request:GetError()
    if error then
        UIManagerInst:OpenOneButtonTip(Language.GetString(810), Language.GetString(811), Language.GetString(809))
        coroutine.waituntil(function ()
            return UINoticeTip.LastClickIndex ~= -1
        end)
        Logger.LogError("Download host manifest :  " .. request:GetABName() .. "\n from url : " .. request:GetURL() .. "\n err : " .. error)
        request:Dispose()
        coroutine.yieldstart(self.GetDownloadAssetBundlesSize, nil, self)
        return coroutine.yieldbreak()
    end
    local content = string.gsub(request:GetText(), '\r', '')
    request:Dispose()

    self.m_downloadSize = 0
    local lines = SplitString(content, '\n')
    local lookupDict = {}
    for _, line in pairs(lines) do
            if line and line ~= '' then
            local slices = SplitString(line, ABConfig.CommonMapPattren) 
            if #slices >= 2 then
                local size = tonumber(slices[2])
                if size then
                    lookupDict[slices[1]] = size
                else
                    Logger.LogError("size TryParse err : " .. line .. ",  1: " .. slices[1] .. ",  2: " .. slices[2])
                end
            else
                Logger.LogError("line split err : " .. line)
            end
        end
    end

    for _, assetbundle in pairs(self.m_needDownloadList) do
        local size = lookupDict[assetbundle]
        if size then
            self.m_downloadSize = self.m_downloadSize + size
        else
            Logger.LogError("no assetbundle size info : " .. assetbundle)
        end
    end
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:CheckGameUpdate(isInternal)
    -- 检测资源更新
    Logger.Log("Resource download url : " .. Setting.GetServerResAddr())
    local start = os.clock()
    coroutine.yieldstart(self.CheckIfNeededUpdate, nil, self, isInternal)
    Logger.Log("CheckIfNeededUpdate use " .. self:GetExecuteTime(start) .. "ms")

    if #self.m_needDownloadList <= 0 then
        Logger.Log("No resources to update...")
        coroutine.yieldstart(self.UpdateFinish, nil, self, false)
        return coroutine.yieldbreak(false)
    end
    
    start = os.clock()
    coroutine.yieldstart(self.GetDownloadAssetBundlesSize, nil, self)
    Logger.Log("GetDownloadAssetBundlesSize : "..self:KBSizeToString(self.m_downloadSize)..", use "..self:GetExecuteTime(start).."ms")
    if self:ShowUpdatePrompt(self.m_downloadSize) or isInternal then
        local str1 = Language.GetString(813)
        local str2 = Language.GetString(814)
        UIManagerInst:OpenOneButtonTip(Language.GetString(812), str1..self:KBSizeToString(self.m_downloadSize)..str2, Language.GetString(802))
        coroutine.waituntil(function ()
            return UINoticeTip.LastClickIndex ~= -1
        end)
    end

    self.m_statusText.text = Language.GetString(816)
    self.m_slider.normalizedValue = 0
    self.m_slider.gameObject:SetActive(true)
    self.m_totalDownloadCount = #self.m_needDownloadList
    self.m_finishedDownloadCount = 0
    Logger.Log(self.m_totalDownloadCount .. " resources to update...")

    start = os.clock()
    coroutine.yieldstart(self.StartUpdate, nil, self)
    Logger.Log("Update use "..self:GetExecuteTime(start).."ms")
    
    self.m_slider.normalizedValue = 1
    start = os.clock()
    coroutine.yieldstart(self.UpdateFinish, nil, self, true)
    Logger.Log("UpdateFinish use "..self:GetExecuteTime(start).."ms")

    return coroutine.yieldbreak(true)
end

function AssetbundleUpdater:WriteNoticeFile()
    if self.m_needUpdateNotice and self.m_noticeUrl and self.m_noticeUrl ~= '' then
        local request = AssetBundleMgrInst:DownloadWebResourceAsync(self.m_noticeUrl)
        coroutine.waituntil(request.IsDone, request)
        if not request:GetError() then
            local path = AssetBundleUtility.GetPersistentDataPath(ABConfig.UpdateNoticeFileName)
            GameUtility.SafeWriteWWWText(path, request:GetWWW())
        end
        request:Dispose()
    end
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:InternalGetUrlList()
    local resUrlLoader = AssetBundleMgrInst:RequestStreamingAssetFileAsync(ABConfig.AssetBundleServerUrlFileName)
    coroutine.waituntil(resUrlLoader.IsDone, resUrlLoader)
    Setting.SetServerResAddr(resUrlLoader:GetText())
    resUrlLoader:Dispose()

    local resVersionLoader = AssetBundleMgrInst:DownloadAssetFileAsync(ABConfig.ResVersionFileName)
    coroutine.waituntil(resVersionLoader.IsDone, resVersionLoader)
    self.m_serverResVersion = resVersionLoader:GetText()
    resVersionLoader:Dispose()
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:GetHostManifest(downloadManifestUrl, isInternal)
    local request = AssetBundleMgrInst:DownloadAssetBundleAsync(downloadManifestUrl)
    coroutine.waituntil(request.IsDone, request)
    if request.error and request.error ~= '' then
        UIManagerInst:OpenOneButtonTip(Language.GetString(810), Language.GetString(811), Language.GetString(809))
        coroutine.waituntil(function ()
            return UINoticeTip.LastClickIndex ~= -1
        end)
        Logger.LogError("Download host manifest :  "..request.assetbundleName.."\n from url : "..request.url.."\n err : "..request.error)
        request:Dispose()
        if isInternal then
            -- 内部版本本地服务器有问题直接跳过，不要卡住游戏
        else
            coroutine.yieldstart(self.GetHostManifest, nil, self, downloadManifestUrl, isInternal)
        end
    else
        local assetbundle = request:GetAssetbundle()
        self.m_hostManifest:LoadFromAssetbundle(assetbundle)
        self.m_hostManifestLoader = request
        -- ab延时10帧销毁，在iOS和mac editor下加载assetbundle会报错
        coroutine.waitforframes(10)
        assetbundle:Unload(false)
    end
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:CheckIfNeededUpdate(isInternal)
    local localManifest = AssetBundleMgrInst:GetCurManifest()
    local manifestClass = require("Framework.AssetBundle.Config.Manifest")
    self.m_hostManifest = manifestClass.New()

    local downloadManifestUrl = self.m_hostManifest:GetABName();
    if not isInternal then
        downloadManifestUrl = downloadManifestUrl .. "?v" .. self.m_timeStamp
    end

    coroutine.yieldstart(self.GetHostManifest, nil, self, downloadManifestUrl, isInternal)

    self.m_needDownloadList = localManifest:CompareTo(self.m_hostManifest)
    if #self.m_needDownloadList > 0 then
        local persistentUpdateFilePath = AssetBundleUtility.GetPersistentDataPath(ABConfig.ABUpdateMapFileName);
        local dontUpdatableABArray = GameUtility.SafeReadAllLines(persistentUpdateFilePath)
        for i = #self.m_needDownloadList, 1, -1 do
            for j = 0, dontUpdatableABArray.Length-1 do
                if self.m_needDownloadList[i] == dontUpdatableABArray[j] then
                    table_remove(self.m_needDownloadList, i)
                end
            end
            local abPathList = SplitString(self.m_needDownloadList[i], '/')
            if abPathList and #abPathList > 0 then
                AssetBundleHelper.ClearAllCachedVersions(abPathList[#abPathList])
            end
        end
    end

    return coroutine.yieldbreak()
end

function AssetbundleUpdater:StartUpdate()
    self.m_downloadingRequest = {}
    self.m_isDownloading = true
    coroutine.waituntil(function()
        return self.m_isDownloading == false
    end)
    if #self.m_needDownloadList > 0 then
        UIManagerInst:OpenOneButtonTip(Language.GetString(810), Language.GetString(811), Language.GetString(809))
        coroutine.waituntil(function ()
            return UINoticeTip.LastClickIndex ~= -1
        end)
        coroutine.yieldstart(self.StartUpdate, nil, self)
    end
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:UpdateFinish(isUpdated)
    self.m_statusText.text = Language.GetString(817)

    -- 保存服务器资源版本号与Manifest
    GameUtility.SafeWriteAllText(self.m_resVersionPath, self.m_serverResVersion)
    self.m_clientResVersion = self.m_serverResVersion
    self.m_hostManifest:SaveToDiskCahce(self.m_hostManifestLoader:GetWWW())
    self.m_hostManifestLoader:Dispose()
    self.m_hostManifestLoader = nil
    
    if isUpdated then
        -- 清理资源管理器
        local abInstance = AssetBundleMgrInst
        coroutine.yieldstart(abInstance.Cleanup, nil, abInstance)
    end

    return coroutine.yieldbreak()
end

function AssetbundleUpdater:StartGame()
    self.m_statusText.text = Language.GetString(817)

    Logger.Init(self.m_clientResVersion)
    PlatformMgr:GetInstance():SetResVersion(self.m_clientResVersion)

    GameMain:Start()
    return coroutine.yieldbreak()
end

function AssetbundleUpdater:Update() 
    if not self.m_isDownloading then
        return
    end

    for i = #self.m_downloadingRequest, 1, -1 do
        local request = self.m_downloadingRequest[i]
        if request:IsDone() then
            table_remove(self.m_downloadingRequest, i)
            if request:GetError() then
                Logger.LogError("Error when downloading file : " .. request:GetABName() .. "\n from url : " .. request:GetURL() .. "\n err : " .. request:GetError())
                table_insert(self.m_needDownloadList, request:GetABName())
            else
                Logger.Log("Finish downloading file : " .. request:GetABName() .. "\n from url : " .. request:GetURL())
                self.m_finishedDownloadCount = self.m_finishedDownloadCount + 1
                if string_contains(request:GetURL(), ABConfig.LuaABFileName) then
                    local filePath = AssetBundleUtility.GetPersistentDataPath(request:GetABName())
                    GameUtility.SafeWriteWWWBytes(filePath, request:GetWWW())
                end
            end
            request:Dispose()
        end
    end

    while #self.m_downloadingRequest < MAX_DOWNLOAD_NUM and #self.m_needDownloadList > 0 do
        local fileName = table_remove(self.m_needDownloadList)
        local request = AssetBundleMgrInst:DownloadAssetBundleAsync(fileName)
        table_insert(self.m_downloadingRequest, request)
    end

    if #self.m_downloadingRequest == 0 then
        self.m_isDownloading = false
    end

    local progressSlice = 1 / self.m_totalDownloadCount
    local progressValue = self.m_finishedDownloadCount * progressSlice
    for i = 1, #self.m_downloadingRequest do
        progressValue = progressValue + (progressSlice * self.m_downloadingRequest[i]:Progress())
    end
    self.m_slider.normalizedValue = progressValue
end

function AssetbundleUpdater:KBSizeToString(kbSize)
    local sizeStr = nil
    if kbSize >= 1024 then
        sizeStr = string_format("%.2f", kbSize / 1024) .. "M"
    else
        sizeStr = kbSize .. "K"
    end

    return sizeStr
end

function AssetbundleUpdater:GetExecuteTime(start)
    return string_format("%.0f", (os.clock() - start) * 1000)
end

return AssetbundleUpdater