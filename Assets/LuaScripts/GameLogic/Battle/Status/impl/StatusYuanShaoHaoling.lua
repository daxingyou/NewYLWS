local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusEnum = StatusEnum
local FixSub = FixMath.sub

local StatusYuanShaoHaoling = BaseClass("StatusYuanShaoHaoling", StatusBase)

function StatusYuanShaoHaoling:__init()
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT
    self.m_targetID = 0

    self.m_effectMask = {}
    self.m_effectKey = -1
end

function StatusYuanShaoHaoling:Init(giver, targetID, leftMS, effect)
    self.m_giver = giver
    self.m_targetID = targetID
    self:SetLeftMS(leftMS)

    self.m_effectMask = effect
    self.m_effectKey = -1
end

function StatusYuanShaoHaoling:GetStatusType()
    return StatusEnum.STATUSTYPE_YUANSHAOHAOLING
end

-- function StatusYuanShaoHaoling:Effect(actor)
--     if not actor then
--         return false
--     end
--     -- actor:SetTargetID(self.m_targetID)
--     if self.m_effectMask and #self.m_effectMask > 0 then
--         self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
--     end
--     return false
-- end

function StatusYuanShaoHaoling:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end
end

function StatusYuanShaoHaoling:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE,false
    end

    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END, false
end

function StatusYuanShaoHaoling:GetTargetID()
    return self.m_targetID
end

function StatusYuanShaoHaoling:SetTargetEffectKey(effectKey)
    self.m_effectKey = effectKey
end

return StatusYuanShaoHaoling
