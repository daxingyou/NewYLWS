local StatusEnum = StatusEnum
local FixSub = FixMath.sub


local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusPangTongTiesuoMark = BaseClass("StatusPangTongTiesuoMark", StatusBase)

function StatusPangTongTiesuoMark:__init()
    self.m_leftMS = 0
    self.m_giver = 0
    self.m_effectKey = 0
end

function StatusPangTongTiesuoMark:Init(giver, leftMS, effect)
    self.m_giver = giver
    self.m_leftMS = leftMS
    self.m_effectKey = 0
    self.m_totalMS = leftMS
    self.m_effectMask = effect
end

function StatusPangTongTiesuoMark:GetStatusType()
    return StatusEnum.STATUSTYPE_PANGTONGTIESUOMARK
end


function StatusPangTongTiesuoMark:Effect(actor)
    if actor and actor:IsLive() then
        if self.m_effectMask and #self.m_effectMask > 0 and self.m_effectKey <= 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end
    end
end


function StatusPangTongTiesuoMark:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end
end

function StatusPangTongTiesuoMark:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE
    end

    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END, false
end

function StatusPangTongTiesuoMark:IsPositive()
    return false
end

function StatusPangTongTiesuoMark:Merge(newStatus, actor) -- 合并規則是 刷新时间 
    if not newStatus or newStatus:GetStatusType() ~= self:GetStatusType() then
        return
    end

    if not self:LogicEqual(newStatus) then
        return
    end

    self.m_leftMS = self.m_totalMS
end

return StatusPangTongTiesuoMark