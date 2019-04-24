local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local Formular = Formular
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium20612 = BaseClass("Medium20612", LinearFlyToTargetMedium)

function Medium20612:ArriveDest()
    self:Hurt()
end


function Medium20612:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local skillCfg = self:GetSkillCfg()
    if not skillCfg then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return  
    end

    local injure = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:X())
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                            judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)

        local effectPercent = performer:GetAtkEffectPercent()
        if effectPercent > 0 then
            local buff = StatusFactoryInst:NewStatusBuff(self.m_giver, BattleEnum.AttrReason_SKILL, performer:GetAtkEffectTime())
            local targetData = target:GetData()
            local targetAtkSpeed = targetData:GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
            local chgAtkSpeed = FixIntMul(targetAtkSpeed, effectPercent)
            buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, FixMul(chgAtkSpeed, -1))
            self:AddStatus(performer, target, buff)
        end
    end
end

return Medium20612