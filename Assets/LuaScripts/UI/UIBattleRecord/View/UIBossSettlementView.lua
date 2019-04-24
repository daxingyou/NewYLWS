local base = require "UI.UIBattleRecord.View.BattleSettlementView"
local UIBossSettlementView = BaseClass("UIBossSettlementView", base)

local BossMgr = Player:GetInstance():GetBossMgr()
local CtlBattleInst = CtlBattleInst
function UIBossSettlementView:OnEnable(...)
    base.OnEnable(self, ...)
    local order, msgObj, bossinfo = ...

    if not msgObj or not bossinfo then
        -- print(' = UIBossSettlementView == no boss finish battle msg  or not bossinfo == ')
        return
    end
    
    self.m_bossInfo = bossinfo
    
    local finish_result = msgObj.battle_result.worldboss_result.is_kill
    self.m_msg_bj = msgObj

    if finish_result == 1 then
        self:HandleWinOrLoseEffect(0)
    else
        self:HandleWinOrLoseEffect(1)
    end

    self.starListTrans.gameObject:SetActive(false)
    self.m_bottomContentTr.gameObject:SetActive(false)

    self:UpdateTimeout()
end

function UIBossSettlementView:GetBattleResult()
    local logic = CtlBattleInst:GetLogic()
    if logic then
        return logic:GetBattleResult()
    end
end

function UIBossSettlementView:GetOpenAudio()
    if self:GetBattleResult() == 0 then
	    return 120
    else
        return 121
    end
end

function UIBossSettlementView:UpdateTimeout()
    if self:GetBattleResult() == 2 then
        self.m_timeoutText.transform.localPosition = Vector3.New(0, 110, 0)
    else
        self.m_timeoutText.transform.localPosition = Vector3.New(0, 100, 0)
    end
end


function UIBossSettlementView:OnClick(go, x, y)
    if go.name == "finish_BTN" then
        if self.m_finish then
            BossMgr:SetBossFinishFight(self.m_msg_bj)
        end
    end    

    base.OnClick(self, go, x, y)
end


return UIBossSettlementView