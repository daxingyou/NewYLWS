local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixRound = FixMath.round
local FixSub = FixMath.sub
local StatusEnum = StatusEnum

local StatusIntervalNuQi = BaseClass("StatusIntervalNuQi", StatusBase)

function StatusIntervalNuQi:__init()
    self.m_deltaNuQi = 0
    self.m_interval = 0
    self.m_chgCount = 0
    self.m_maxOverlayCount = 0
    self.m_intervalTime = 0
    self.m_effectKey = 0
end

function StatusIntervalNuQi:Init(giver, deltaNuQi, interval, chgCount, chgReason, skillCfg, effect, maxOverlayCount)
    self.m_giver = giver
    self.m_deltaNuQi = deltaNuQi
    self.m_interval = interval
    self.m_chgCount = chgCount or 1
    self.m_chgReason = chgReason
    self.m_skillCfg = skillCfg
    self.m_maxOverlayCount = maxOverlayCount or 0
    self.m_intervalTime = 0
    self.m_effectMask = {}
    self:SetEffectMask(effect)

    self.m_effectKey = 0
end

function StatusIntervalNuQi:GetStatusType()
    return StatusEnum.STAUTSTYPE_INTERVAL_NUQI
end

function StatusIntervalNuQi:LogicEqual(newOne)
    if not StatusBase.LogicEqual(self, newOne) then
        return false
    end
    return self:GetMaxCount() == newOne:GetMaxCount()
end

function StatusIntervalNuQi:GetMaxCount()
    return self.m_maxOverlayCount -- ? 
end

function StatusIntervalNuQi:ExtendEffect(value)
    self.m_chgCount = FixRound(FixMul(self.m_chgCount, value))
end

-- return actor isDie
function StatusIntervalNuQi:Effect(actor)
    if actor then
        local _, e = next(self.m_effectMask)
        if e then
            self.m_effectKey = self:ShowEffect(actor, e)
        end
    end
    return false
end

function StatusIntervalNuQi:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1   
    end

    return false
end

function StatusIntervalNuQi:Update(deltaMS, actor) 
    if not self.m_skillCfg then
        return StatusEnum.STATUSCONDITION_END
    end

    self.m_intervalTime = FixAdd(self.m_intervalTime, deltaMS)
    if self.m_intervalTime < self.m_interval then
        return StatusEnum.STATUSCONDITION_CONTINUE, false
    end

    self.m_intervalTime = 0
    self.m_chgCount = FixSub(self.m_chgCount, 1)
    local isDie = false
    if actor:IsLive() then
        actor:ChangeNuqi(self.m_deltaNuQi, self.m_chgReason, self.m_skillCfg)
    else
        isDie = true
    end

    if self.m_chgCount > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE, isDie
    end

    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END, isDie
end

function StatusIntervalNuQi:IsPositive()
    return self.m_deltaNuQi > 0 
end

return StatusIntervalNuQi