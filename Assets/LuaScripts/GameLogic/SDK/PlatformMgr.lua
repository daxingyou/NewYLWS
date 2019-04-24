local string_format = string.format
local SimpleHttp = CS.SimpleHttp
local DataUtils = CS.DataUtils
local SplitString = CUtil.SplitString
local Application = CS.UnityEngine.Application
local GameUtility = CS.GameUtility
local string_len = string.len
local string_split = string.split
local NetworkReachability = CS.UnityEngine.NetworkReachability
local SDKHelper = CS.SDKHelper
local PlatformMgr = BaseClass("PlatformMgr", Singleton)

function PlatformMgr:__init()
    self.m_appVersion = nil
    self.m_resVersion = nil
    self.m_noticeVersion = nil
    self.m_packageName = nil
    self.m_platform = nil
    self.m_loginUid = nil
    self.m_serverID = '0'
    self.m_serverName = ''
    self.m_initCallback = nil
    self.m_isLogin = false
    self.m_loginCallback = nil
    self.m_platformUid = nil
    self.m_gameUid = 0
    self.m_gameUserName = nil
    self.m_gameUserLevel = 0
    self.m_productID = 0
    self.m_payMoney = 0
    self.m_payContent = nil
    self.m_payOrder = nil
    self.m_payExt1 = nil
    self.m_payExt2 = nil
    self.m_orderTime = nil
    self.m_downLoadGameSucceed = nil
    self.m_downLoadGameFail = nil
    self.m_downLoadGameProgress = nil
    self.m_itemID = 0
    self.m_appProductID = nil
    self.m_isApplePay = true
    self.m_webPayUrl = nil
    self.m_channelID = nil
    self.m_gameSign = nil
    self.m_showServerID = '0'
    self.m_alreadyRegister = false
end

function PlatformMgr:GetPackageName()
    return self.m_packageName
end

function PlatformMgr:GetNoticeVersion()
    return self.m_noticeVersion
end

function PlatformMgr:SetNoticeVersion(version)
    self.m_noticeVersion = version
end

function PlatformMgr:SetResVersion(version)
    self.m_resVersion = version
end

function PlatformMgr:GetResVersion()
    return self.m_resVersion
end

function PlatformMgr:SetAppVersion(version)
    self.m_appVersion = version
end

function PlatformMgr:GetAppVersion()
    return self.m_appVersion
end

function PlatformMgr:GetChannelID()
    return self.m_channelID
end

function PlatformMgr:IsLogin()
    return self.m_isLogin
end

function PlatformMgr:GetLoginUID()
    return self.m_loginUid
end

function PlatformMgr:SetServerName(name)
    self.m_serverName = name
end

function PlatformMgr:GetServerName()
    return self.m_serverName
end

function PlatformMgr:SetServerID(id)
    self.m_serverID = id
end

function PlatformMgr:GetServerID()
    return self.m_serverID
end

function PlatformMgr:SetShowServerID(id)
    self.m_showServerID = id
end

function PlatformMgr:GetShowServerID()
    return self.m_showServerID
end

function PlatformMgr:GetGameSign()
    return self.m_gameSign
end

function PlatformMgr:Init(packageName)
    self.m_packageName = packageName
    
    local platformClass = nil
    if self.m_packageName == PlatformEnum.TEST then
        platformClass = require("GameLogic.SDK.impl.TestPlatform")
    elseif self.m_packageName == PlatformEnum.TESTIOS then
        platformClass = require("GameLogic.SDK.impl.TestIOSPlatform")
    elseif self.m_packageName == PlatformEnum.ANHX then
        platformClass = require("GameLogic.SDK.impl.ANHXPlatform")
    elseif self.m_packageName == PlatformEnum.IOSHX then
        platformClass = require("GameLogic.SDK.impl.IOSHXPlatform")
    else
        Logger.LogError("No this platform : " .. self.m_packageName)
        return
    end

    self.m_platform = platformClass.New(self.m_packageName)
end

function PlatformMgr:InitSDK(callback)
    self.m_initCallback = callback
    self.m_platform:Init()
end

function HandleSDKCallback(msg)
    Logger.Log("Msg : " .. msg)
    local json = Json.decode(msg)
    if json.methodName == "InitSDKComplete" then
        PlatformMgr:GetInstance():InitSDKComplete(msg)
    elseif json.methodName == "LogoutCallback" then
        PlatformMgr:GetInstance():Relogin()
    elseif json.methodName == "PayCallback" then
        PlatformMgr:GetInstance():SDKPayComplete(json.ret)
    elseif json.methodName == "DownLoadGameProgressCallback" then
        PlatformMgr:GetInstance():DownLoadGameProgress(json.progress)
    elseif json.methodName == "DownLoadGameCallback" then
        PlatformMgr:GetInstance():DownLoadGameEnd(json.ret == 0)
    elseif json.methodName == "LoginCallback" then
        PlatformMgr:GetInstance():VerifyLoginFromSDK(json.platform_id, json.token)
    end
end

function PlatformMgr:InitSDKComplete(msg)
    if self.m_packageName == "YIJIE" then
        self.m_packageName = msg
    end
    CS.Logger.platChannel = self.m_packageName
    if self.m_initCallback then
        self.m_initCallback()
        self.m_initCallback = nil
    end
end

function PlatformMgr:Login(callback)
    self.m_loginCallback = callback
    if self.m_platform then
        self.m_platform:Login()
    end
end

function PlatformMgr:Relogin()
    Logger.Log("PlatformMgr Relogin")
    self.m_isLogin = false
    if SceneManagerInst:IsLoginScene() then
        UIManagerInst:Broadcast(UIMessageNames.MN_LOGIN_RELOGIN)
    else
        self:GotoLoginScene()
    end
end
      
function PlatformMgr:OrderCallback(msg)
    local msgTable = Json.decode(msg)
    if msgTable["APPSTORE"] then
        self.m_isApplePay = true
    elseif msgTable["APPSTOREF"] then
        self.m_isApplePay = false
    end
    self:InnerStartPay(self.m_itemID, self.m_payMoney, self.m_payContent, self.m_gameUid, self.m_gameUserName, self.m_gameUserLevel, self.m_appProductID)
end

function PlatformMgr:StartPay(itemID, money, content, uid, userName, userLevel, appStoreProductID)
    local apppayWay = Setting.GetAppPayWay()
    if self.m_m_platform:isOpenDoubelPay() and apppayWay == "ALL" then
        self.m_payMoney = money
        self.m_payContent = content
        self.m_gameUid = uid
        self.m_gameUserName = userName
        self.m_gameUserLevel = userLevel
        self.m_itemID = itemID
        self.m_appProductID = appStoreProductID
        self.m_platform.ChoosePayWay()
    else
        if apppayWay and apppayWay ~= "" then
            self.m_isApplePay = false
        else
            self.m_isApplePay = true
        end
        self:InnerStartPay(itemID, money, content, uid, userName, userLevel, appStoreProductID)
    end
end

function PlatformMgr:InnerStartPay(itemID, money, content, uid, userName, userLevel, appStoreProductID)
    self.m_productID = itemID
    if self.m_platform:IsPaying(self.m_productID) then
        Logger.Log(self.m_productID .. " is paying now")
        return
    end

    local sendMsg = string_format("itemid={0}&price={1}&uid={2}&platform={3}&platform_id={4}&serverid={5}&ordertitle={6}&orderdesc={7}", 
        itemID, money, uid, packageName, self.m_platformUid, self.m_serverID, content, content)
    self:ShowNetWaiting()
    if self.m_isApplePay then
        SimpleHttp.HttpPost (Setting.GetOrderURL(), nil, DataUtils.StringToBytes(sendMsg), Bind(self, self.GetPayOrderComplete))
    else
        SimpleHttp.HttpPost (Setting.GetABOrderURL(), nil, DataUtils.StringToBytes(sendMsg), Bind(self, self.GetPayOrderComplete))
    end
end

function PlatformMgr:Logout()
    self.m_isLogin = false

    if self.m_platform then
        self.m_platform:Logout()
    end
end

function PlatformMgr:GameRegist(roleID, roleName, registerTime, currentTime, balance, vipLevel, partyName)
    if not roleName or roleName == "" then
        roleName = "default"
    end

    if self.m_platform then
        self.m_platform:SubmitUserConfig(roleID, roleName, "1", self.m_serverID, self.m_serverName, registerTime, currentTime, "createRole", balance, vipLevel, partyName);
    end
end

function PlatformMgr:GameLogin(roleID, roleName, level, registerTime, currentTime, balance, vipLevel, partyName)
    self.m_gameUid = roleID
    if not roleName or roleName == '' then
        roleName = "default"
    end

    if self.m_platform then
        self.m_platform.SubmitUserConfig(roleID, roleName, level, self.m_serverID, self.m_serverName, registerTime, currentTime, "loginRole", balance, vipLevel, partyName)
    end
end

function PlatformMgr:GameUpgradeLevel(roleID, roleName, level, registerTime, currentTime, balance, vipLevel, partyName)
    if self.m_platform then
        self.m_platform:SubmitUserConfig(roleID, roleName, level, self.m_serverID, self.m_serverName, registerTime, currentTime, "upgradeRole", balance, vipLevel, partyName)
    end
end
        
function PlatformMgr:VerifyLoginFromSDK(platform_id, token)
    local msg = "platform_id=" .. platform_id .. "&token=" .. token .. "&platform=" .. self.m_packageName
    self:ShowNetWaiting()
    SimpleHttp.HttpPost(Setting.GetLoginURL(), nil, DataUtils.StringToBytes(msg), Bind(self, self.VerifyComplete))
end

function PlatformMgr:VerifyComplete(www)
    self:HideNetWaiting()
    if www and (not www.error or www.error == '') then
        local wwwBytes = www.bytes
        if wwwBytes and string_len(wwwBytes) > 0 then
            self.m_gameSign = wwwBytes
            local msgTable = Utils.ParseHttpMsg(wwwBytes)
            local ret = -1
            if msgTable["ret"] then
                ret = tonumber(msgTable["ret"])
            end
            if msgTable["account"] then
                self.m_loginUid = msgTable["account"]
                local strList = SplitString(self.m_loginUid, '_')
                if #strList >= 2 then
                    self.m_platformUid = strList[2]
                    Logger.Log("m_platformUid : " .. self.m_platformUid)
                end
            end
            if msgTable["channel_id"] then
                self.m_channelID = tonumber(msgTable["channel_id"])
            end
            if ret ~= 0 then
                Logger.Log("verify login fail!!! msg:" .. wwwBytes)
                self:VerifyLoginFault()
            else
                Logger.Log("verify login succeed, receive msg: " .. wwwBytes)
                self:VerifyLoginSucceed()
            end
        else
            self:VerifyLoginFault()
            Logger.Log("verify http error")
        end
    else
        if Application.internetReachability ~= NetworkReachability.NotReachable then
            self:VerifyLoginFault()
        end

        if www then
            Logger.Log("verify http error: " .. www.error)
        end
    end
end

function PlatformMgr:VerifyLoginSucceed()
    self.m_isLogin = true
    
    if self.m_loginCallback then
        self.m_loginCallback()
        self.m_loginCallback = nil
    end

    if self.m_packageName == "YJYYB" then -- 应用宝每过半个小时会收到登录成功的回调，会导致自动退出。其他渠道保留切换到登录界面功能。针对有些自带切换账号的渠道
        return
    end
    if not SceneManagerInst:IsLoadingScene() and not SceneManagerInst:IsLoginScene() then
        self:GotoLoginScene()
    end
end

function PlatformMgr:GotoLoginScene()
    Player:GetInstance():SetGameInit(false)
    HallConnector:GetInstance():Disconnect()
    HallConnector:GetInstance():ClearAllHandler()
    UIManagerInst:LeaveScene()
    SceneManagerInst:SwitchScene(SceneConfig.LoginScene)
end

function PlatformMgr:VerifyLoginFault()
    UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9),Language.GetString(204), Language.GetString(10))
end

function PlatformMgr:GetPayOrderComplete(www)
    self:HideNetWaiting()

    if www and (not www.error or www.error == '') then
        local wwwBytes = www.bytes
        if wwwBytes and string_len(wwwBytes) > 0 then
            local ret = -1
            local msgtable = Json.decode(DataUtils.BytesToString(www.bytes))
            if msgtable["code"] then
                ret = tonumber(msgtable["code"])
            end
            if msgtable["order_id"] then
                self.m_payOrder = msgtable["order_id"]
            end
            if msgtable["orderExt1"] then
                self.m_payExt1 = msgtable["orderExt1"]
            end
            if msgtable["orderExt2"] then
                self.m_payExt2 = msgtable["orderExt2"]
            end
            if msgtable["order_time"] then
                self.m_orderTime = msgtable["order_time"]
            end
            if msgtable["url"] then
                self.m_webPayUrl = msgtable["url"]
            end

            if ret == 0 then
                self:SDKPay()
            else 
                UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9),Language.GetString(205), Language.GetString(10))
            end
        end
    else
        if www then
            Logger.Log("www error: " .. www.error)
        end
    end
end

function PlatformMgr:SDKPay()
    if self.m_platform then
        local androidServerID = self:IsOfficialPlatform() and self.m_serverID or "0"
        self.m_platform:Pay(self.m_platformUid, --0
                            self.m_payMoney * 100, --1
                            self.m_payContent, --2
                            self.m_productID, --3
                            "1", --4
                            Setting.GetNotifyURL(),--5
                            self.m_gameUserName, --6
                            self.m_gameUid, --7
                            self.m_gameUserLevel, --8
                            self.m_payOrder, --9
                            androidServerID, --10
                            self.m_payExt1, --11
                            self.m_payExt2, --12
                            self.m_orderTime,--13
                            Setting.GetNotifyURL1())--14
    end
end

function PlatformMgr:SDKPayComplete(ret)
    Logger.Log ("sdk pay callback, msg: " .. ret)

    if ret == 0 then
        Player:GetInstance():GetUserMgr():ReqHeartBeat()
    end
end

function PlatformMgr:StartDownLoadGame(url, succeed, fail, progress, saveName)
    self.m_downLoadGameSucceed = succeed
    self.m_downLoadGameFail = fail
    self.m_downLoadGameProgress = progress
    self.m_platform:DownloadGame(url, saveName)
end

function PlatformMgr:DownLoadGameEnd(succeed)
    if succeed then
        if self.m_downLoadGameSucceed then
            self.m_downLoadGameSucceed()
        end
    else
        if self.m_downLoadGameFail then
            self.m_downLoadGameFail()
        end
    end

    self.m_downLoadGameSucceed = nil
    self.m_downLoadGameFail = nil
    self.m_downLoadGameProgress = nil
end

function PlatformMgr:DownLoadGameProgress(progress)
    if self.m_downLoadGameProgress then
        self.m_downLoadGameProgress(progress)
    end
end

function PlatformMgr:InstallGame(succeed, fail)
    self.m_downLoadGameSucceed = succeed
    self.m_downLoadGameFail = fail
    self.m_platform:InstallApk()
end

function PlatformMgr:IsInternalVersion()
    if self.m_platform then
        return self.m_platform:IsInternalVersion()
    end
    return true
end

function PlatformMgr:IsAppStore()
    if self.m_platform then
        return self.m_platform:IsAppstore()
    end
end

function PlatformMgr:ShowNetWaiting()
    if SceneManagerInst:IsLoadingScene() then
        return
    end
    UIManagerInst:OpenWindow(UIWindowNames.UIDownloadTips)
end

function PlatformMgr:HideNetWaiting()
    UIManagerInst:CloseWindow(UIWindowNames.UIDownloadTips)
end

function PlatformMgr:GetDeviceID()
    if not self.m_platform then
        return ''
    end
    return self.m_platform:GetPhoneIDFA()
end

function PlatformMgr:GetTotalVersion()
    local dynRevision = require "Global.DynamicRevision"
    return string_format("%s.%s.L%s.C%s", self.m_appVersion, self.m_resVersion, dynRevision.luaRevision, dynRevision.excelRevision)
end

function PlatformMgr:GetMobileType()
    if not self.m_platform then
        return ''
    end
    return self.m_platform:GetMobileType()
end

function PlatformMgr:RegisterNotification()
    --注册推送
    local platformName = self:GetMobileType()
    if self.m_alreadyRegister or platformName == "Editor" then
        return
    end

    if platformName == "Android" then
        self:RegisterAndroidNotification()
    elseif platformName == "IOS" then
        self:RegisterIOSNotification()
    end

    self.m_alreadyRegister = true
end


function PlatformMgr:RegisterAndroidNotification()
    SDKHelper.Instance:LuaCallSDK(Json.encode({
        methodName ="InstallNotification",
    }))

    local noticeCfgList = ConfigUtil.GetNoticeCfgList()
    for _, noticeCfg in ipairs(noticeCfgList) do
        if noticeCfg then
            if noticeCfg.type == 1 then
                self:SendNotifyCfgToAndroid(noticeCfg.id, 0, noticeCfg.time[1], noticeCfg.time[2], noticeCfg.title, noticeCfg.content)
            elseif noticeCfg.type == 2 then
                self:SendNotifyCfgToAndroid(noticeCfg.id, noticeCfg.time[1], noticeCfg.time[2], noticeCfg.time[3], noticeCfg.title, noticeCfg.content)
            end
        end
    end
end

function PlatformMgr:SendNotifyCfgToAndroid(id, day, hour, min, title, msg)
    SDKHelper.Instance:LuaCallSDK(Json.encode({
        methodName ="NotificationListAdd",
        id = id,
        day = day,
        hour = hour,
        min = min,
        title = title,
        msg = msg,
    }))  
end

function PlatformMgr:RegisterIOSNotification()
    GameUtility.ClearNotification()

    local noticeCfgList = ConfigUtil.GetNoticeCfgList()
    for _, noticeCfg in ipairs(noticeCfgList) do
        if noticeCfg then
            if noticeCfg.type == 1 then
                local hour = noticeCfg.time[1]
                local minute = noticeCfg.time[2]
                GameUtility.RegisterIOSNotification(0, string.format("%.2d",hour), string.format("%.2d",minute), noticeCfg.title, noticeCfg.content)
            elseif noticeCfg.type == 2 then
                local addDay = noticeCfg.time[1]
                local hour = noticeCfg.time[2]
                local min = noticeCfg.time[3]
                GameUtility.RegisterIOSNotification(addDay, string.format("%.2d",hour), string.format("%.2d",min), noticeCfg.title, noticeCfg.content)
            end
        end
    end
end

return PlatformMgr