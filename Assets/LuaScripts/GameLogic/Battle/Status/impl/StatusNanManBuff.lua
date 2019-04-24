local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusEnum = StatusEnum
local FixSub = FixMath.sub
local FixIntMul = FixMath.muli
local FixMul = FixMath.mul

local StatusNanManBuff = BaseClass("StatusNanManBuff", StatusBase)

function StatusNanManBuff:__init()
    self.m_effectKey = -1
    self.m_atkMulPercent = 0
    self.m_atkSpeedPercent = 0
    self.m_chgAtkSpeed = 0
    self.m_skillCfg = nil
end

function StatusNanManBuff:Init(giver, leftMS, atkMulPercent, atkSpeedPercent, skillCfg, effect)
    self.m_giver = giver
    self.m_effectMask = effect
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT
    self:SetLeftMS(leftMS)
    self.m_effectKey = -1
    self.m_atkMulPercent = atkMulPercent
    self.m_atkSpeedPercent = atkSpeedPercent
    self.m_skillCfg = skillCfg
end

function StatusNanManBuff:GetStatusType()
    return StatusEnum.STAUTSTYPE_NANMANBUFF
end

function StatusNanManBuff:GetHurtMulPercent()
    return self.m_atkMulPercent
end

function StatusNanManBuff:GetHurtMulSkillCfg()
    return self.m_skillCfg
end

function StatusNanManBuff:Effect(actor)
    if actor then 
        if self.m_effectMask and #self.m_effectMask > 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end

        if self.m_atkSpeedPercent > 0 then
            local actorData = actor:GetData()
            local baseAtkSpeed = actorData:GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
            local chgAtkSpeed = FixIntMul(baseAtkSpeed, self.m_atkSpeedPercent)
            self.m_chgAtkSpeed = chgAtkSpeed
            actorData:AddFightAttr(ACTOR_ATTR.FIGHT_ATKSPEED, chgAtkSpeed)
        end
    end

    return false
end


function StatusNanManBuff:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end

    if not actor then
        return
    end

    if self.m_chgAtkSpeed > 0 then
        actor:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_ATKSPEED, FixMul(self.m_chgAtkSpeed, -1))
        self.m_chgAtkSpeed = 0
    end
end

function StatusNanManBuff:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE
    end
    
    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END
end

return StatusNanManBuff