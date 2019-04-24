
local PBUtil = PBUtil
local BaseBattleLogicComponent = require "GameLogic.Battle.Component.BaseBattleLogicComponent"
local TestLogicComponent = BaseClass("TestLogicComponent", BaseBattleLogicComponent)

function TestLogicComponent:__init()
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.TESTBATTLE_RSP_TESTBATTLE_FINISH, Bind(self, self.RspBattleFinish))
end

function TestLogicComponent:__delete()
    HallConnector:GetInstance():ClearHandler(MsgIDDefine.TESTBATTLE_RSP_TESTBATTLE_FINISH)
end
  
function TestLogicComponent:ShowBattleUI()
    UIManagerInst:OpenWindow(UIWindowNames.UIBattleMain)
    BaseBattleLogicComponent.ShowBloodUI(self)
end  

function TestLogicComponent:ReqBattleFinish()
    local msg_id = MsgIDDefine.TESTBATTLE_REQ_TESTBATTLE_FINISH
	local msg = (MsgIDMap[msg_id])()
    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
    self:GenerateResultInfoProto(msg.battle_result)
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function TestLogicComponent:RspBattleFinish(msg_obj)
	local result = msg_obj.result
	if result ~= 0 then
		Logger.LogError('TestLogicComponent failed: '.. result)
		return
    end
    
    local isEqual = self:CompareBattleResult(msg_obj.battle_result)
    if not isEqual then
        Logger.LogError("Do not sync, report frame data to server")
        self:ReqReportFrameData()
    end
end

return TestLogicComponent