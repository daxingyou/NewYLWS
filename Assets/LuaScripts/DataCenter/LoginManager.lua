local SystemInfo = CS.UnityEngine.SystemInfo
local string_gsub = string.gsub

local LoginManager = BaseClass("LoginManager")


function LoginManager:__init()
	self.m_serverID = 0
	self.m_platAccount = nil
	self.m_serverPort = 0
	self.m_serverIP = nil

	HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOGIN_RSP_GET_UID, Bind(self, self.OnRspGetUid))
	HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOGIN_RSP_LOGIN, Bind(self, self.OnRspLogin))
	HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOGIN_NTF_LOGOUT, Bind(self, self.OnNtfLogout))
end

function LoginManager:Dispose()

end

function LoginManager:SetServerInfo(id, account, port, serverIP)
	self.m_serverID = id
	self.m_platAccount = account
	self.m_serverPort = port
	self.m_serverIP = serverIP
end

function LoginManager:OnConnect(sender, result, msg)
	if result < 0 then
		Logger.LogError("Connect err : "..msg)
		return
	end
	
	local PlatformMgrInst = PlatformMgr:GetInstance()
	local msg_id = MsgIDDefine.LOGIN_REQ_GET_UID
	local msg = (MsgIDMap[msg_id])()
	msg.plat_account = self.m_platAccount
	msg.from_svrid = tonumber(self.m_serverID)
	msg.device_id = PlatformMgrInst:GetDeviceID() or "" -- TODO IOS设备ID去oc取
	local dvModel = SystemInfo.deviceModel .. ' + ' .. SystemInfo.graphicsDeviceName .. ' + ' .. SystemInfo.operatingSystem
	msg.device_model = string_gsub(dvModel, ' ', '')
	msg.mobile_type = PlatformMgrInst:GetMobileType() or ''
	msg.plat_token = PlatformMgrInst:GetGameSign() or ""
	msg.app_ver = PlatformMgrInst:GetTotalVersion() or ''
	msg.package_id = PlatformMgrInst:GetPackageName() or ''
	msg.res_ver = ""
	msg.int_package_id = PlatformMgrInst:GetChannelID() or 0

	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LoginManager:ReqLogin()
	local msg_id = MsgIDDefine.LOGIN_REQ_LOGIN
	local msg = (MsgIDMap[msg_id])()
	if Player:GetInstance():IsGameInit() then
		msg.flag = 1
	else
		msg.flag = 0
	end
	msg.dist_id = 1

	local PlatformMgrInst = PlatformMgr:GetInstance()
	msg.dist_name = PlatformMgrInst:GetServerName() or ''
	msg.str_dist_id = tostring(PlatformMgrInst:GetShowServerID()) or "0"
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LoginManager:OnRspLogin(msg_obj)
	local result = msg_obj.result
	if result ~= 0 then
		Logger.LogError('OnRspLogin failed: '.. result)
		return
	end

	Player:GetInstance():SetServerTime(msg_obj.game_time)
	HallConnector:GetInstance():InitRequireSeq(msg_obj.game_time)
	
	Player:GetInstance():GetUserMgr():ReqAllData()
end

function LoginManager:OnRspGetUid(msg_obj)
	if msg_obj.result ~= 0 then
		Logger.LogError('OnRspGetUid failed: '.. result)
		return
	end

	self:ReqLogin()
end

function LoginManager:OnNtfLogout(msg_obj)
	Player:GetInstance():SetGameInit(false)
	HallConnector:GetInstance():Disconnect()

	local titleMsg = Language.GetString(9)
	local btn1Msg = Language.GetString(10)
	local contentMsg = Language.GetString(203)
	UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, titleMsg, contentMsg, btn1Msg, function()
		CS.UnityEngine.Application.Quit()
	end, nil, nil, false)
end

function LoginManager:OnClose(sender, result, msg)
	print("Close result : " .. result .. " msg:" ..msg)
end

function LoginManager:ConnectServer()
	HallConnector:GetInstance():Connect(self.m_serverIP, self.m_serverPort, Bind(self, self.OnConnect), Bind(self, self.OnClose))
end

function LoginManager:StartLogin(serverid, name, serverPort, serverIP)
	self:SetServerInfo(serverid, name, serverPort, serverIP)

	self:ConnectServer()
end

return LoginManager