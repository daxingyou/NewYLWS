local PBUtil = PBUtil
local CopyLogicComponent = require "GameLogic.Battle.Component.impl.CopyLogicComponent"
local LieZhuanTeamLogicComponent = BaseClass("LieZhuanTeamLogicComponent", CopyLogicComponent)
local base = CopyLogicComponent

function LieZhuanTeamLogicComponent:__init(logic)
    --HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_FINISH_SINGLE_FIGHT, Bind(self, self.RspBattleFinish))
end

function LieZhuanTeamLogicComponent:__delete()
    --HallConnector:GetInstance():ClearHandler(MsgIDDefine.LIEZHUAN_RSP_FINISH_SINGLE_FIGHT)
end

function LieZhuanTeamLogicComponent:ShowBattleUI()
    UIManagerInst:OpenWindow(UIWindowNames.UIBattleLieZhuanMain)
    base.ShowBloodUI(self)
end  

function LieZhuanTeamLogicComponent:ReqBattleFinish(playerWin)
    local battleResultData = self.m_logic:GetBattleParam().battleResultData
    if battleResultData then
        if battleResultData.finish_result == 1 then
        battleResultData.finish_result = 0
        elseif battleResultData.finish_result == 2 then
        battleResultData.finish_result = 1
        end
    end
    UIManagerInst:CloseWindow(UIWindowNames.UIBattleLieZhuanMain)
    UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanSettlement, battleResultData)
end

function LieZhuanTeamLogicComponent:ReadSpeedUpSetting()
    return 1.5
end

return LieZhuanTeamLogicComponent