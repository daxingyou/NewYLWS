local string_format = string.format
local SimpleHttp = CS.SimpleHttp
local DataUtils = CS.DataUtils
local table_insert = table.insert
local table_sort = table.sort
local AssetBundleUtility = CS.AssetBundles.AssetBundleUtility
local GameUtility = CS.GameUtility
local string_len = string.len
local AssetBundleHelper = CS.AssetBundles.AssetBundleHelper
local ServerDataClass = require("DataCenter.Login.ServerData")
local base = UIBaseView
local UIPlatLogin = BaseClass("UIPlatLogin", base)

function UIPlatLogin:OnCreate()
	base.OnCreate(self)

	self:InitVariable()
	self:InitView()
	self:HandleClick()
end

-- 初始化非UI变量
function UIPlatLogin:InitVariable()
	self.m_serverList = {}
	self.m_lastLoginServerList = {}
	self.m_curServerData = nil
	self.m_checkServerOpen = false
	self.m_showUpdateNotice = true
	self.m_noticeMsg = nil
end

-- 初始化UI变量
function UIPlatLogin:InitView()
	self.m_versionText, self.m_changeText, self.m_loginText, self.m_tipsText, self.m_clearText, 
	self.m_switchText, self.m_noticeText, self.m_serverDesc = UIUtil.GetChildTexts(self.transform, {
		"VersionText",
		"ContentRoot/ServerBg/ChangeBtn/ChangeText",
		"ContentRoot/LoginBtn/LoginText",
		"tipsText",
		"BtnRoot/clearBtn/clearText",
		"BtnRoot/switchBtn/switchText",
		"BtnRoot/noticeBtn/noticeText",
		"ContentRoot/ServerBg/ServerDesc"
    })
	self.m_versionText.text = string_format(Language.GetString(4100), PlatformMgr:GetInstance():GetTotalVersion())
	self.m_changeText.text = Language.GetString(4102)
	self.m_loginText.text = Language.GetString(4103)
	self.m_tipsText.text = Language.GetString(4107)
	self.m_clearText.text = Language.GetString(4104)
	self.m_switchText.text = Language.GetString(4105)
	self.m_noticeText.text = Language.GetString(4106)

    self.m_changeBtn, self.m_loginBtn, self.m_clearBtn, self.m_switchBtn, self.m_noticeBtn  = UIUtil.GetChildRectTrans(self.transform, {
        "ContentRoot/ServerBg/ChangeBtn",
		"ContentRoot/LoginBtn",
		"BtnRoot/clearBtn",
		"BtnRoot/switchBtn",
		"BtnRoot/noticeBtn",
    })
end

function UIPlatLogin:OnAddListener()
	base.OnAddListener(self)
	self:AddUIListener(UIMessageNames.MN_LOGIN_RELOGIN, self.StartSDKLogin)
	self:AddUIListener(UIMessageNames.MN_LOGIN_SELECT_SERVER, self.OnSelectServer)
end

function UIPlatLogin:OnRemoveListener()
	base.OnRemoveListener(self)
	self:RemoveUIListener(UIMessageNames.MN_LOGIN_RELOGIN, self.StartSDKLogin)
	self:RemoveUIListener(UIMessageNames.MN_LOGIN_SELECT_SERVER, self.OnSelectServer)
end

function UIPlatLogin:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_changeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_loginBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_clearBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_switchBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_noticeBtn.gameObject, onClick)
end

function UIPlatLogin:RemoveEvent()
    UIUtil.RemoveClickEvent(self.m_changeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_loginBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_clearBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_switchBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_noticeBtn.gameObject)
end

function UIPlatLogin:OnDisable()

    base.OnDisable(self)
end

function UIPlatLogin:OnClick(go, x, y)
    local name = go.name
	if name == "ChangeBtn" then
		UIManagerInst:OpenWindow(UIWindowNames.UIServerList, self.m_serverList, self.m_curServerData, self.m_lastLoginServerList)
	elseif name == "LoginBtn" then
		if PlatformMgr:GetInstance():IsLogin() then
			self.m_checkServerOpen = true
		end
		self:StartLogin()
	elseif name == "clearBtn" then
		self:ClearCache()
	elseif name == "switchBtn" then
		PlatformMgr:GetInstance():Logout()
	elseif name == "noticeBtn" then
		coroutine.start(self.LoadUpdateNotice, self)
    end
end

function UIPlatLogin:OnEnable(...)
	base.OnEnable(self, ...)

	self.timer_action = function(self)
		self:StartSDKLogin()
    end
    self.timer = TimerManager:GetInstance():GetTimer(0.5, self.timer_action, self, true)
	self.timer:Start()
end

function UIPlatLogin:StartSDKLogin()
	if PlatformMgr:GetInstance():IsLogin() then
		self:GetServerList()
	else
		PlatformMgr:GetInstance():Login(function()
			self:GetServerList()
		end)
	end
end

function UIPlatLogin:GetServerList()
	UIManagerInst:OpenWindow(UIWindowNames.UIDownloadTips)
	local sendMsg = string_format("platform=%s&uid=%s", PlatformMgr:GetInstance():GetPackageName(), PlatformMgr:GetInstance():GetLoginUID())
	SimpleHttp.HttpPost(Setting.GetServerListURL(), nil, DataUtils.StringToBytes(sendMsg), Bind(self, self.GetServerListComplete))
end

function UIPlatLogin:GetServerListComplete(www)
	UIManagerInst:CloseWindow(UIWindowNames.UIDownloadTips)

	if not www or (www.error and www.error ~= '') then
		self:GetServerList()
		return
	end

	local wwwBytes = www.bytes
	if not wwwBytes or string_len(wwwBytes) == 0 then
		self:GetServerList()
		return
	end

	local ret = self:ParseServerList(wwwBytes)
	if not ret then
		return
	end
	self:UpdateServerInfo()

	if self.m_checkServerOpen then
		self.m_checkServerOpen = false
		self:StartLogin()
	end

	if self.m_showUpdateNotice then
		self.m_showUpdateNotice = false
		coroutine.start(self.LoadUpdateNotice, self)
	end
end

function UIPlatLogin:ParseServerList(wwwBytes)
	self.m_serverList = {}
	local jsonList = Json.decode(DataUtils.BytesToString(wwwBytes))
	if not jsonList or #jsonList == 0 then
		UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9),Language.GetString(4113), Language.GetString(10))
		return false
	end

	local lastLoginTime = 0
	for _,jsonData in ipairs(jsonList) do
		local serverData = ServerDataClass.New()
		serverData.ip = jsonData.ip
		serverData.port = jsonData.port
		serverData.name = jsonData.name
		serverData.status = jsonData.status or 0
		serverData.areaID = jsonData.areaID or 0
		serverData.serverID = jsonData.svrid or '0'
		serverData.openTime = jsonData.open_time or 0
		serverData.serverIndex = jsonData.shown_svrid or 0
		serverData.recommend = jsonData.recommend or 0
		serverData.hasRole = jsonData.has_role or 0
		serverData.loginTime = jsonData.last_time or 0
		serverData.user_name = jsonData.user_name
		serverData.level = jsonData.level or 0
		serverData.icon = jsonData.icon or 0
		serverData.icon_box = jsonData.icon_box or 0
		table_insert(self.m_serverList, serverData)
		self:AddLastLoginServer(serverData)
	end

	if #self.m_serverList <= 0 then
		Logger.Log('GetServerListComplete : serverList.count is 0')
		return false
	end
	
	table_sort(self.m_serverList, function(x, y)
		if x.serverIndex > y.serverIndex then return false
		elseif x.serverIndex < y.serverIndex then return true
		else return x.openTime > y.openTime end
	end)
	self.m_curServerData = self.m_lastLoginServerList[1]
	if not self.m_curServerData then 
		self.m_curServerData = self.m_serverList[#self.m_serverList]
	end
	return true
end

function UIPlatLogin:AddLastLoginServer(serverData)
	if serverData.hasRole <= 0 then
		return
	end

	if #self.m_lastLoginServerList < 3 then
		table_insert(self.m_lastLoginServerList, serverData)
		return
	end

	for i = 1, 3 do
		if self.m_lastLoginServerList[i].loginTime < serverData.loginTime then
			self.m_lastLoginServerList[i] = serverData
			table_sort(self.m_lastLoginServerList, function(x, y)
				return x.loginTime < y.loginTime
			end)
			break
		end
	end
end

function UIPlatLogin:UpdateServerInfo()
	if not self.m_curServerData then
		return
	end
	self.m_serverDesc.text = self.m_curServerData:GetServerIndexAndName()
	local PlatformMgrInst = PlatformMgr:GetInstance()
	PlatformMgrInst:SetServerName(self.m_curServerData.name)
	PlatformMgrInst:SetServerID(self.m_curServerData.serverID)
	PlatformMgrInst:SetShowServerID(self.m_curServerData.serverIndex)
end

function UIPlatLogin:StartLogin()
	local PlatformMgrInst = PlatformMgr:GetInstance()
	if not PlatformMgrInst:IsLogin() then
		self:StartSDKLogin()
		return
	end
	if not self.m_curServerData then
		UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9),Language.GetString(4114), Language.GetString(10))
		return
	end
	if self.m_curServerData.status == CommonDefine.SERVER_WAIT_OPEN then
		if self.m_checkServerOpen then
			self:GetServerList()
			return
		end

		if os.time() < self.m_curServerData.openTime then
			local msg = string_format(Language.GetString(4116), TimeUtil.ToYearMonthDayHourMinSec(self.m_curServerData.openTime,4115))
			UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9), msg, Language.GetString(10))
			return
		end
	elseif self.m_curServerData.status == CommonDefine.SERVER_WEIHU then
		UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9), Language.GetString(4117), Language.GetString(10))
		return
	end

	local serverid = self.m_curServerData.serverID
	local account = PlatformMgrInst:GetLoginUID()
	local port = self.m_curServerData.port
	local ip = self.m_curServerData.ip
	Player:GetInstance():GetLoginMgr():StartLogin(serverid, account, port, ip)
end

function UIPlatLogin:ClearCache()
	UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(1107),Language.GetString(4207), Language.GetString(10), function()
		coroutine.start(function()
			coroutine.yieldstart(AssetBundleMgrInst.Cleanup, nil, AssetBundleMgrInst)
			coroutine.waitforframes(1)
			GameUtility.SafeDeleteDir(AssetBundleUtility.GetPersistentDataPath())
			AssetBundleHelper.ClearCache()
			CS.UnityEngine.Application.Quit()
		end)
	end, Language.GetString(5))
end

function UIPlatLogin:OnDestroy()
    self:RemoveEvent()
	
	base.OnDestroy(self)
end

function UIPlatLogin:LoadUpdateNotice()
	if not self.m_noticeMsg then
		UIManagerInst:OpenWindow(UIWindowNames.UIDownloadTips)
		local noticeLoader = AssetBundleMgrInst:RequestAssetBundleAsync(ABConfig.UpdateNoticeFileName)
		coroutine.waituntil(noticeLoader.IsDone, noticeLoader)
		UIManagerInst:CloseWindow(UIWindowNames.UIDownloadTips)

		local error = noticeLoader:GetError()
		if error then
			noticeLoader:Dispose()
			return
		end
		self.m_noticeMsg = noticeLoader:GetText()
		noticeLoader:Dispose()
	end
	UIManagerInst:OpenWindow(UIWindowNames.UIUpdateNotice, self.m_noticeMsg)
end

function UIPlatLogin:OnSelectServer(serverData)
	self.m_curServerData = serverData
	self:UpdateServerInfo()
end

return UIPlatLogin