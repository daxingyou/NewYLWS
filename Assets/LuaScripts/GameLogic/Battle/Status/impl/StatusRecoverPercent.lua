
local table_insert = table.insert
local StatusEnum = StatusEnum
local FixSub = FixMath.sub

local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusRecoverPercent = BaseClass("StatusRecoverPercent", StatusBase)

function StatusRecoverPercent:__init()
    self.m_leftMS = 0
    self.m_reducePercent = 0
    self.m_effectKey = 0
    self.m_effectMask = {}
end

function StatusRecoverPercent:Init(giver, leftMS, reducePercent, effect)
    self.m_giver = giver
    self.m_effectMask = {effect}
    self.m_leftMS = leftMS
    self.m_reducePercent = reducePercent
    self:SetLeftMS(leftMS)
    self.m_effectKey = 0
end

function StatusRecoverPercent:GetPercent()
    return self.m_reducePercent
end

function StatusRecoverPercent:GetStatusType()
    return StatusEnum.STATUSTYPE_RECOVER_PERCENT
end

function StatusRecoverPercent:Effect(actor)
    if actor then
        if self.m_effectMask and #self.m_effectMask > 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end
    end
end

function StatusRecoverPercent:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end
end

function StatusRecoverPercent:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)

    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE, false
    end

    self:ClearEffect(actor)

    return StatusEnum.STATUSCONDITION_END, false
end

function StatusRecoverPercent:IsPositive()
    return false
end

return StatusRecoverPercent 