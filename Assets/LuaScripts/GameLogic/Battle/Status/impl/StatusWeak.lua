local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusEnum = StatusEnum
local BattleEnum = BattleEnum
local FixSub = FixMath.sub
local StatusFactoryInst = StatusFactoryInst

local StatusWeak = BaseClass("StatusWeak", StatusBase)

function StatusWeak:__init()
    self.m_effectKey = -1
    self.m_colorKey = -1
    self.m_hurtMul = 0
end

function StatusWeak:Init(giver, leftMS, hurtMul, effect)
    self.m_giver = giver
    
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT
    self:SetLeftMS(leftMS)
    self.m_effectKey = -1
    self.m_colorKey = -1
    self.m_hurtMul = hurtMul or 0

    if effect then
        self.m_effectMask = effect
    else
        self.m_effectMask = {21015}
    end
end

function StatusWeak:GetStatusType()
    return StatusEnum.STATUSTYPE_WEAK
end
 
function StatusWeak:Effect(actor)
    if actor and actor:IsLive() then 
        if self.m_hurtMul > 0 then 
            local statusNTimeBeHurtChg = StatusFactoryInst:NewStatusNTimeBeHurtMul(self.m_giver, self.m_leftMS, self.m_hurtMul)
            statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_PHY_HURT)
            statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_MAGIC_HURT)
            statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_REAL_HURT)
            actor:GetStatusContainer():DelayAdd(statusNTimeBeHurtChg)
        end

        if self.m_effectMask and #self.m_effectMask > 0 and self.m_effectKey <= 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end
    end

    return false
end

function StatusWeak:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end

    if actor and actor:IsLive() then   
        local floatType = ACTOR_ATTR.BE_HURT_END_UP
         
        actor:ShowFloatHurt(floatType)
    end
end

function StatusWeak:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE
    end
    
    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END
end

function StatusWeak:IsPositive()
    return false
end
return StatusWeak