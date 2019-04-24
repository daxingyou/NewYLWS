local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusEnum = StatusEnum
local FixSub = FixMath.sub
local Color = Color

local StatusDingShen = BaseClass("StatusDingShen", StatusBase)

function StatusDingShen:__init()
    self.m_effectKey = -1
    self.m_colorKey = -1
end

function StatusDingShen:Init(giver, leftMS, effect)
    self.m_giver = giver
    self.m_effectMask = effect
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT
    self:SetLeftMS(leftMS)
    self.m_effectKey = -1
    self.m_colorKey = -1
end

function StatusDingShen:GetStatusType()
    return StatusEnum.STATUSTYPE_DINGSHEN
end

function StatusDingShen:Effect(actor)
    if actor then 
        actor:Freeze()

        if self.m_effectMask and #self.m_effectMask > 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end

        self.m_colorKey = self:ShowColor(actor)
    end

    return false
end

function StatusDingShen:ShowColor(actor, effect)
    if not actor:GetActorColor() then
        return -1
    end

    local color = Color.New(0, 0.67, 1, 0.56) -- r g b a
    return actor:GetActorColor():AddColorFactor(color, 2, 99999)
end

function StatusDingShen:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end

    if not actor then
        return
    end
    actor:FreezeDone()

    if actor:GetActorColor() and self.m_colorKey > 0 then
        actor:GetActorColor():RemoveColorFactorByKey(self.m_colorKey)
        self.m_colorKey = -1
    end
end

function StatusDingShen:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE
    end
    
    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END
end

function StatusDingShen:Merge(newStatus, actor) -- 合并規則是 刷新时间 如果其他效果，需要继承重写
    if not newStatus or newStatus:GetStatusType() ~= self:GetStatusType() then
        return
    end

    if not self:LogicEqual(newStatus) then
        return
    end

    self.m_leftMS = self.m_totalMS
end

function StatusDingShen:IsPositive()
    return false
end



return StatusDingShen