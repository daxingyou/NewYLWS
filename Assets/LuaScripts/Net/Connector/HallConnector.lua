--[[
-- added by wsh @ 2017-01-09
-- 大厅网络连接器
--]]

local MsgIDDefine = MsgIDDefine
local SceneManagerInst = SceneManagerInst
local HallConnector = BaseClass("HallConnector", Singleton)
local SendMsgDefine = require "Net.Config.SendMsgDefine"
local NetUtil = require "Net.Util.NetUtil"
local NetEnum = NetEnum
local table_insert = table.insert
local table_remove = table.remove
local HjTcpNetwork = CS.Networks.HjTcpNetwork
local isEditor = CS.GameUtility.IsEditor()
local LoginTimeoutInterval = 7
local SendTimeoutInterval = 7
local Config = Config
local table_dump = table.dump
local UILogicUtil = UILogicUtil
local MsgNameMap = require "Net.Config.MsgNameMap"

function HallConnector:__init()
	self.m_loginStatus = NetEnum.LOGIN_STATUS_NONE
	self.m_loginTime = 0
	self.hallSocket = nil
	self.globalSeq = 0
	self.m_requireSeq = 0
	self.msgHandlerDict = {}
	self.m_curSendMsg = {}
	self.m_requestQueue = {}
end

function HallConnector:InitRequireSeq(reqSeq)
	if self.m_requireSeq == 0 then
		self.m_requireSeq = reqSeq
	end
end

function HallConnector:GenerateRequestSeq(msgID)
	if self:NeedResend(msgID) then
		self.m_requireSeq = self.m_requireSeq + 1
		return self.m_requireSeq
	else
		return 0
	end
end

function HallConnector:Connect(host_ip, host_port, on_connect, on_close)
	UIManagerInst:OpenWindow(UIWindowNames.UIDownloadTips)
	if not self.hallSocket then
		self.hallSocket = CS.Networks.HjTcpNetwork(1048576, 4194304)
		self.hallSocket.ReceivePkgHandle = Bind(self, self.OnReceivePackage)
	end
	self.hallSocket.OnConnect = on_connect
	self.hallSocket.OnClosed = on_close
	self.hallSocket:SetHostPort(host_ip, host_port)
	self.hallSocket:Connect()
	self.m_loginTime = LoginTimeoutInterval
	-- Logger.Log("Connect to "..host_ip..", port : "..host_port)
	return self.hallSocket
end

function HallConnector:SendMessage(msg_id, msg_obj, show_mask, need_resend)
	show_mask = show_mask == nil and true or show_mask
	need_resend = need_resend == nil and true or need_resend
	
	self:CheckLoginStatus(msg_id, msg_obj)

	local reqSeq = self:GenerateRequestSeq(msg_id)
	local send_msg = SendMsgDefine.New(msg_id, msg_obj, reqSeq)
	if self.hallSocket:IsConnected() then
		if isEditor then
			if msg_id ~= MsgIDDefine.USER_REQ_HEARTBEAT then
				print(os.date("%m/%d/%Y %H:%M:%S %p", os.time()) .. " reqID: " .. msg_id .. " reqSeq: " .. reqSeq .. "\n" .. 
					MsgNameMap[msg_id] or msg_id, "\n" .. tostring(msg_obj))
			end
		end

		if self:NeedResend(msg_id) then
			if self.m_curSendMsg.state == NetEnum.MSG_SEND_SENDING or 
			   self.m_curSendMsg.state == NetEnum.MSG_SEND_WAIT_RECONNET then
				table_insert(self.m_requestQueue, send_msg)
				return
			end
			self:DoSend(send_msg)
		else
			local msg_bytes = NetUtil.SerializeMessage(send_msg, self.globalSeq)
			self.hallSocket:SendMessage(msg_bytes)
			self.globalSeq = self.globalSeq + 1
		end
	else
		if self:NeedResend(msg_id) then
			table_insert(self.m_requestQueue, send_msg)
		end

		if self.hallSocket:IsConnecting() then
			return
		end

		if SceneManagerInst:IsBattleScene() and msg_id == MsgIDDefine.USER_REQ_HEARTBEAT then
			return
		end

		if self.m_loginStatus == NetEnum.LOGIN_STATUS_DONE then
			self:Reconnect()
		end
	end
end

function HallConnector:DoSend(sendMsg)
	self.m_curSendMsg.msgInfo = sendMsg
	self.m_curSendMsg.state = NetEnum.MSG_SEND_SENDING
	self.m_curSendMsg.duration = 0

	if self.hallSocket:IsConnected() then
		local msg_bytes = NetUtil.SerializeMessage(sendMsg, self.globalSeq)
		self.hallSocket:SendMessage(msg_bytes)
		self.globalSeq = self.globalSeq + 1
		UIManagerInst:OpenWindow(UIWindowNames.UIDownloadTips)
	end
end

function HallConnector:OnReceivePackage(receive_bytes)
	local receive_msg = NetUtil.DeserializeMessage(receive_bytes)

	local packages = receive_msg.Packages
	
	local pkgCount = #packages

	self:CheckWaitMsg(receive_msg.RequestSeq)

	-- Logger.Log("receive_msg: " .. pkgCount .. ',' .. tostring(receive_msg))

	for i = 1, pkgCount do
		local one_package = packages[i]

		local msg_id = one_package.MsgID
		local msg_obj = one_package.MsgProto

		self:CheckLoginStatus(msg_id, msg_obj)
		
		if isEditor then
			if msg_id ~= MsgIDDefine.USER_RSP_HEARTBEAT and msg_id ~= MsgIDDefine.USER_NTF_REDPOINT_LIST then
				print(os.date("%m/%d/%Y %H:%M:%S %p", os.time()) .. " rspID: " .. msg_id .. " RequestSeq: " .. receive_msg.RequestSeq .. "\n" .. 
					MsgNameMap[msg_id] .. "\nresult: " .. (msg_obj.result or 0), "\n" .. tostring(msg_obj))
			end
		end
		
		local msg_handler = self.msgHandlerDict[msg_id]
		if msg_handler then
			local isErrorHandled = false  --处理错误
			local result = msg_obj.result
			
			if result and result ~= 0 then
				local interestResult = msg_handler.interestResult 
				if interestResult and (interestResult < 0 or (interestResult > 0 and interestResult ~= result)) then
					isErrorHandled = true
					UILogicUtil.HandleResult(result)
				end
			end
		   
			if not isErrorHandled then
				if msg_handler.packetHandle then
					msg_handler.packetHandle(msg_obj)
				end
			end
		end
	end
end

function HallConnector:CheckWaitMsg(requestSeq)
	if isEditor then
		if requestSeq > 0 and self.m_curSendMsg.msgInfo == nil then
			print(' -------- CheckWaitMsg nil msgInfo', requestSeq)
		end
	end

	if requestSeq > 0 and self.m_curSendMsg.msgInfo and requestSeq == self.m_curSendMsg.msgInfo.RequestSeq and self.m_loginStatus == NetEnum.LOGIN_STATUS_DONE then
		UIManagerInst:CloseWindow(UIWindowNames.UIDownloadTips)
		self.m_curSendMsg.state = NetEnum.MSG_SEND_RECEIVED
		self.m_curSendMsg.msgInfo = nil
		self.m_curSendMsg.duration = 0

		if #self.m_requestQueue > 0 then
			self:DoSend(table_remove(self.m_requestQueue, 1))
		end
	end
end

function HallConnector:RegisterHandler(msg_id, handle_func, interestResult)
	if self.msgHandlerDict[msg_id] then
		Logger.LogError('RegisterHandler repeat: ' .. msg_id)
		return false
	end

	interestResult = interestResult or -1

	self.msgHandlerDict[msg_id] = { packetHandle = handle_func, interestResult = interestResult }
	return true
end

function HallConnector:ClearHandler(msg_id)
	if not self.msgHandlerDict[msg_id] then
		return false
	end

	self.msgHandlerDict[msg_id] = nil
	return true
end

function HallConnector:ClearAllHandler()
	self.msgHandlerDict = {}
end

function HallConnector:Update(deltatime)
	if self.hallSocket then
		self.hallSocket:UpdateNetwork()
	end
	self:CheckLoginTimeout(deltatime)
	self:CheckSendTimeout(deltatime)
end

function HallConnector:CheckLoginTimeout(deltatime)
	if self.m_loginTime > 0 then
		if self.m_loginStatus == NetEnum.LOGIN_STATUS_FAIL then
			self.m_loginTime = 0
		elseif self.m_loginStatus == NetEnum.LOGIN_STATUS_DONE then
			self.m_loginTime = 0
			UIManagerInst:CloseWindow(UIWindowNames.UIDownloadTips)
			self:ResendMsg()
		else
			self.m_loginTime = self.m_loginTime - deltatime
			if self.m_loginTime <= 0 then
				self.m_loginTime = 0
				self:ShowReconnectTips()
			end
		end
	end
end

function HallConnector:CheckSendTimeout(deltatime)
	if not self.m_curSendMsg then
		return
	end

	if self.m_curSendMsg.state ~= NetEnum.MSG_SEND_SENDING then
		return
	end

	if self.m_curSendMsg.duration >= SendTimeoutInterval then
		return
	end

	self.m_curSendMsg.duration = self.m_curSendMsg.duration + deltatime
	if self.m_curSendMsg.duration < SendTimeoutInterval then
		return
	end

	self.m_curSendMsg.state = NetEnum.MSG_SEND_WAIT_RECONNET
	self:ShowReconnectTips()
end

function HallConnector:Disconnect()
	UIManagerInst:CloseWindow(UIWindowNames.UIDownloadTips)
	self.m_loginStatus = NetEnum.LOGIN_STATUS_NONE
	self.m_loginTime = 0

	if self.m_curSendMsg.state == NetEnum.MSG_SEND_SENDING then
		self.m_curSendMsg.state = NetEnum.MSG_SEND_WAIT_RECONNET
		self.m_curSendMsg.duration = 0
	end
	
	if self.hallSocket then
		self.hallSocket:Disconnect()
	end
end

function HallConnector:Dispose()
	if self.hallSocket then
		self.hallSocket:Dispose()
	end
	self.hallSocket = nil
end

function HallConnector:CheckLoginStatus(msgID, msg_obj)
	if msgID == MsgIDDefine.LOGIN_REQ_GET_UID then
		self.m_loginStatus = NetEnum.LOGIN_STATUS_LOGINING
	elseif msgID == MsgIDDefine.LOGIN_RSP_GET_UID then
		if msg_obj.result == 0 then
			self.m_loginStatus = NetEnum.LOGIN_STATUS_LOGINING
		else
			self.m_loginStatus = NetEnum.LOGIN_STATUS_FAIL
		end
	elseif msgID == MsgIDDefine.LOGIN_REQ_LOGIN then
		self.m_loginStatus = NetEnum.LOGIN_STATUS_LOGINING
	elseif msgID == MsgIDDefine.LOGIN_RSP_LOGIN then
		if msg_obj.result == 0 then
			self.m_loginStatus = NetEnum.LOGIN_STATUS_DONE
		else
			self.m_loginStatus = NetEnum.LOGIN_STATUS_FAIL
		end
	end
end

function HallConnector:ShowReconnectTips()
	self:Disconnect()

	local titleMsg = Language.GetString(9)
	local btn1Msg = Language.GetString(201)
	local contentMsg = Language.GetString(200)
	UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, titleMsg, contentMsg, btn1Msg, function()
		self:Reconnect()
	end, nil, nil, false)
end

function HallConnector:Reconnect()
	if not self.hallSocket then
		return
	end

	if self.hallSocket:IsConnecting() then
		return
	end

	if self.hallSocket:IsConnected() then
		self:Disconnect()
	end

	self.m_loginStatus = NetEnum.LOGIN_STATUS_NONE

	self.m_loginTime = LoginTimeoutInterval
	UIManagerInst:OpenWindow(UIWindowNames.UIDownloadTips)

	self.hallSocket:Connect()
end

function HallConnector:NeedResend(msgID)
	if self.m_loginStatus ~= NetEnum.LOGIN_STATUS_DONE then
		return false
	end

	return msgID ~= MsgIDDefine.USER_REQ_HEARTBEAT and msgID ~= MsgIDDefine.LOGIN_REQ_GET_UID and msgID ~= MsgIDDefine.LOGIN_REQ_LOGIN
end

function HallConnector:ResendMsg()
	if self.m_curSendMsg.state == NetEnum.MSG_SEND_WAIT_RECONNET then
		if self.m_curSendMsg.msgInfo then
			self:DoSend(self.m_curSendMsg.msgInfo)
		end
	else
		if #self.m_requestQueue > 0 then
			self:DoSend(table_remove(self.m_requestQueue, 1))
		end
	end
end

function HallConnector:IsSocketConnected()
	if self.hallSocket then
		return self.hallSocket:IsConnected()
	end
end

return HallConnector
