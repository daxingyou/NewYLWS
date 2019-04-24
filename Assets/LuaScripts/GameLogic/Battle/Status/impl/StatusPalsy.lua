local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusEnum = StatusEnum
local FixSub = FixMath.sub

local StatusPalsy = BaseClass("StatusPalsy", StatusBase)
-- 麻痹状态  效果，不能获得怒气
function StatusPalsy:__init()
    self.m_effectKey = -1
end

function StatusPalsy:Init(giver, leftTime, effect)
    self.m_giver = giver
    self.m_effectMask = effect
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT
    self.m_effectKey = -1
    self:SetLeftMS(leftTime)
end

function StatusPalsy:GetStatusType()
    return StatusEnum.STATUSTYPE_PALSY
end

function StatusPalsy:Effect(actor)
    if actor then
        if self.m_effectMask and #self.m_effectMask > 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end
    end
    return false
end

function StatusPalsy:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end
end

function StatusPalsy:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)

    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE
    end

    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END
end

return StatusPalsy