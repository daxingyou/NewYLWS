Setting = {
    resourceUrl = nil,
    loginUrl = nil,
    serverListUrl = nil,
    orderUrl = nil,
    reportLoginUrl = '',
    appUrl = nil,
    notifyUrl = nil,
    notifyUrl1 = nil,
    ipaUrl = nil,
    payway = nil,
    sandboxId = nil,
    aborderUrl = nil,
    auto_login = nil,
    startupConnectTimes = 0, --启动地址三次切换
    isWhiteList = false,
    backupStartupUrl = nil,
    frameDataReportUri = "http://nylws.haoxingame.com/frame/HX/report",

    GetStartUpURL = function()
        local self = Setting
        if self.startupConnectTimes > 9 then
            self.startupConnectTimes = 0
        elseif self.startupConnectTimes > 6 then
            if self.backupStartupUrl == nil or self.backupStartupUrl == '' then
                self.startupConnectTimes = 0
            end
        end

        self.startupConnectTimes = self.startupConnectTimes + 1
        if self.startupConnectTimes <= 3 then
            return "https://nylws.haoxingame.com/startup"
        elseif self.startupConnectTimes <= 6 then
            return "https://nylws2.haoxingame.com/startup"
        else
            return self.backupStartupUrl
        end
    end,

    GetServerResAddr = function()
        return Setting.resourceUrl
    end,

    SetServerResAddr = function(value)
        Setting.resourceUrl = value
    end,

    GetAppAddr = function()
        return Setting.appUrl
    end,

    SetAppAddr = function(value)
        Setting.appUrl = value
    end,

    GetIPAAddr = function()
        return Setting.ipaUrl
    end,

    SetIPAAddr = function(value)
        Setting.ipaUrl = value
    end,

    GetSandbox = function()
        return Setting.sandboxId
    end,

    SetSandbox = function(value)
        Setting.sandboxId = value
    end,
    
    GetLoginURL = function()
        return Setting.loginUrl
    end,

    SetLoginURL = function(value)
        Setting.loginUrl = value
    end,
    
    GetServerListURL = function()
        return Setting.serverListUrl
    end,

    SetServerListURL = function(value)
        Setting.serverListUrl = value
    end,
    
    GetAppPayWay = function()
        return Setting.payway
    end,

    SetAppPayWay = function(value)
        Setting.payway = value
    end,
    
    GetNotifyURL = function()
        return Setting.notifyUrl
    end,

    SetNotifyURL = function(value)
        Setting.notifyUrl = value
    end,
    
    GetNotifyURL1 = function()
        return Setting.notifyUrl1
    end,

    SetNotifyURL1 = function(value)
        Setting.notifyUrl1 = value
    end,
    
    GetOrderURL = function()
        return Setting.orderUrl
    end,

    SetOrderURL = function(value)
        Setting.orderUrl = value
    end,
    
    GetABOrderURL = function()
        return Setting.aborderUrl
    end,

    SetABOrderURL = function(value)
        Setting.aborderUrl = value
    end,
    
    GetLoginReportURL = function()
        return Setting.reportLoginUrl
    end,

    SetLoginReportURL = function(value)
        Setting.reportLoginUrl = value
    end,

    GetAutoLogin = function()
        return Setting.auto_login
    end,

    SetAutoLogin = function(value)
        Setting.auto_login = value
    end,

    SetBackupStartupUrl = function(value)
        Setting.backupStartupUrl = value
    end,

    SetFrameDataReportUri = function(value)
        Setting.frameDataReportUri = value
    end,

    GetFrameDataReportUri = function()
        return Setting.frameDataReportUri
    end,
}
