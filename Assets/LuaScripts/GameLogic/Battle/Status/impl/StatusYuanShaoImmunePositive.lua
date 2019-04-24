local StatusEnum = StatusEnum
local BattleEnum = BattleEnum
local FixSub = FixMath.sub
local FixMul = FixMath.mul
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst

local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusYuanShaoImmunePositive = BaseClass("StatusYuanShaoImmunePositive", StatusBase)


function StatusYuanShaoImmunePositive:__init()
    self.m_giver = false

    self.m_hurtHP = 0 -- 大于0 减伤   小于0 增伤
    
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT
end

function StatusYuanShaoImmunePositive:Init(giver, leftMS, hurtHP, effect)
    self.m_giver = giver
    self.m_hurtHP = hurtHP
    self:SetLeftMS(leftMS)
end

function StatusYuanShaoImmunePositive:GetStatusType()
    return StatusEnum.STAUTSTYPE_YUANSHAOIMMUNEPOSITIVE
end

function StatusYuanShaoImmunePositive:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    if self.m_leftMS <= 0 then
        return StatusEnum.STATUSCONDITION_END
    end
    return StatusEnum.STATUSCONDITION_CONTINUE
end

function StatusYuanShaoImmunePositive:HurtToActor(actor)
    if actor and actor:IsLive() then
        local delayHurtStatus = StatusFactoryInst:NewStatusDelayHurt(self.m_giver, FixMul(-1, self.m_hurtHP), BattleEnum.HURTTYPE_MAGIC_HURT, 0, BattleEnum.HPCHGREASON_BY_SKILL, 0)
        local performer = ActorManagerInst:GetActor(self.m_giver.actorID)
        if performer and performer:IsLive() then
            local addSuc = actor:GetStatusContainer():Add(delayHurtStatus, performer)
            if addSuc then
                actor:AddEffect(104309)
            end
		end
    end	
end

function StatusYuanShaoImmunePositive:IsPositive()
    return false
end

return StatusYuanShaoImmunePositive