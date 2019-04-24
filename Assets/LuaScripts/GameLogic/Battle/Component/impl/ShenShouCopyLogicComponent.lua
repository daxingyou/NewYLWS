
local PBUtil = PBUtil
local CopyLogicComponent = require "GameLogic.Battle.Component.impl.CopyLogicComponent"
local ShenShouCopyLogicComponent = BaseClass("ShenShouCopyLogicComponent", CopyLogicComponent)
local base = CopyLogicComponent

function ShenShouCopyLogicComponent:__init(logic)
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGONCOPY_RSP_FINISH_COPY, Bind(self, self.RspBattleFinish))
end

function ShenShouCopyLogicComponent:__delete()
    HallConnector:GetInstance():ClearHandler(MsgIDDefine.DRAGONCOPY_RSP_FINISH_COPY)
end
  
function ShenShouCopyLogicComponent:ShowBattleUI()
    UIManagerInst:OpenWindow(UIWindowNames.UIBattleBossMain)
    base.ShowBloodUI(self)
end  

function ShenShouCopyLogicComponent:ReqBattleFinish(playerWin)
    local msg_id = MsgIDDefine.DRAGONCOPY_REQ_FINISH_COPY
    local msg = (MsgIDMap[msg_id])()
    msg.copy_id = self.m_logic.m_battleParam.copyID
    msg.take_time = self.m_logic:GetLeftS()
    msg.finish_result = self.m_logic:GetBattleResult()


    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
    self:GenerateResultInfoProto(msg.battle_result)
    HallConnector:GetInstance():SendMessage(msg_id, msg)
    
    --todo 使用假数据做rsp响应
    -- local battleAwardData = {
    --     finish_result = playerWin and 0 or 1,
    --   }
    
    -- self.m_logic:OnAward(battleAwardData)
end

function ShenShouCopyLogicComponent:RspBattleFinish(msg_obj)

	local result = msg_obj.result
	if result ~= 0 then
		Logger.LogError('ShenShouCopyLogicComponent failed: '.. result)
		return
    end
    
    local isEqual = self:CompareBattleResult(msg_obj.battle_result)
    if not isEqual then
        Logger.LogError("Do not sync, report frame data to server")
        self:ReqReportFrameData()
    end

    UIManagerInst:CloseWindow(UIWindowNames.UIBattleBossMain)
    UIManagerInst:OpenWindow(UIWindowNames.BattleSettlement, msg_obj)
end


return ShenShouCopyLogicComponent