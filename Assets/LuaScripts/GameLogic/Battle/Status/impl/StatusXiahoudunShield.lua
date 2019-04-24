local StatusEnum = StatusEnum
local FixMul = FixMath.mul
local FixAdd = FixMath.add
local ACTOR_ATTR = ACTOR_ATTR

local StatusAllShield = require("GameLogic.Battle.Status.impl.StatusAllTimeShield")
local StatusXiahoudunShield = BaseClass("StatusXiahoudunShield", StatusAllShield)
 
function StatusXiahoudunShield:__init()
    self.m_baojiProb = 0
    self.m_recoverPercent = 0
    self.m_isImmuneControle = false
    self.m_addBaoji = false
end

function StatusXiahoudunShield:Init(giver, hpStore, leftMS, baoji, recoverPercent, isImmuneControle, effect)
    StatusAllShield.Init(self, giver, hpStore, leftMS, effect)
    self:SetLeftMS(leftMS)
    self.m_baojiProb = baoji
    self.m_recoverPercent = recoverPercent
    self.m_isImmuneControle = isImmuneControle
    self.m_addBaoji = false
end

function StatusXiahoudunShield:GetStatusType()
    return StatusEnum.STATUSTYPE_XIAHOUDUN_SHIELD
end

function StatusXiahoudunShield:AddHPStore(hpStore)
    self.m_hpStore = FixAdd(self.m_hpStore, hpStore)
end

function StatusXiahoudunShield:IsImmuneControle()
    return self.m_isImmuneControle
end

function StatusXiahoudunShield:Effect(actor)
    if actor and actor:IsLive() then
        actor:GetData():AddFightAttr(ACTOR_ATTR.PHY_BAOJI_PROB_CHG, self.m_baojiProb)
        self.m_addBaoji = true

        actor:BeginAddBloodShield(self.m_recoverPercent)
    end

    return StatusAllShield.Effect(self, actor)
end

function StatusXiahoudunShield:ClearEffect(actor)
    StatusAllShield.ClearEffect(self, actor)
    if actor and actor:IsLive() then
        if self.m_addBaoji then
            actor:GetData():AddFightAttr(ACTOR_ATTR.PHY_BAOJI_PROB_CHG, FixMul(self.m_baojiProb, -1))
            self.m_addBaoji = false
        end

        actor:EndAddBloodShield()
    end
end

return StatusXiahoudunShield