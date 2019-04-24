local base = require "UI.UIBattleRecord.View.BattleSettlementView"
local UIGuildBossSettlementView = BaseClass("UIGuildBossSettlementView", base)

local CtlBattleInst = CtlBattleInst
local guildBossMgr = Player:GetInstance():GetGuildBossMgr()

function UIGuildBossSettlementView:OnEnable(...)
    base.OnEnable(self, ...)
    local order, msgObj = ...

    if not msgObj then
        -- print(' = UIBossSettlementView == no boss finish battle msg ')
        return
    end

    local finish_result = msgObj.battle_result.guildboss_result.is_kill
    if finish_result == 1 then
        self:HandleWinOrLoseEffect(0)
    else
        self:HandleWinOrLoseEffect(2)
    end

    self.starListTrans.gameObject:SetActive(false)
    self.m_bottomContentTr.gameObject:SetActive(false)
    self:UpdateTimeout()
end

function UIGuildBossSettlementView:OnClick(go, x, y)
    if go.name == "finish_BTN" then
        if self.m_finish then
            local totalHurt = CtlBattleInst:GetLogic():GetHarm()
            GamePromptMgr:GetInstance():InstallPrompt(CommonDefine.GUILD_BOSS_BACK_SETTLE, {totalHurt})
        end
    end    

    base.OnClick(self, go, x, y)
end

function UIGuildBossSettlementView:GetBattleResult()
    local logic = CtlBattleInst:GetLogic()
    if logic then
        return logic:GetBattleResult()
    end
end

function UIGuildBossSettlementView:GetOpenAudio()
    if self:GetBattleResult() == 0 then
	    return 120
    else
        return 121
    end
end


function UIGuildBossSettlementView:UpdateTimeout()
    if self:GetBattleResult() == 2 then
        self.m_timeoutText.transform.localPosition = Vector3.New(0, 110, 0)
    else
        self.m_timeoutText.transform.localPosition = Vector3.New(0, 100, 0)
    end
end

return UIGuildBossSettlementView