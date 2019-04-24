local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local Formular = Formular
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR
local IsInCircle = SkillRangeHelper.IsInCircle

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium35012 = BaseClass("Medium35012", LinearFlyToTargetMedium)


function Medium35012:ArriveDest()
    self:Hurt()
end


function Medium35012:Hurt()

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

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return
    end

    local injure = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:X())
    if injure > 0 then
        local intervalStatus = StatusFactoryInst:NewStatusIntervalHP(self.m_giver, FixMul(injure, -1), 1000, self.m_skillBase:B(), nil, nil, BattleEnum.HURTTYPE_PHY_HURT)
        self:AddStatus(performer, target, intervalStatus)
    end
          

    local frozenStatus = StatusFactoryInst:NewStatusFrozen(self.m_giver, FixIntMul(self.m_skillBase:B(), 1000))
    local suc = self:AddStatus(performer, target, frozenStatus)

    if suc then
        local battleLogic = CtlBattleInst:GetLogic()
        local factory = StatusFactoryInst
        local targetPos = target:GetPosition()
        local targetID = target:GetActorID()
        local radius = self.m_skillBase:A()
        local time = FixIntMul(self.m_skillBase:D(), 1000)
        local percent = FixDiv(self.m_skillBase:C(), 100)
        ActorManagerInst:Walk(
            function(tmpTarget)           
                if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                    return
                end

                if tmpTarget:GetActorID() == targetID then
                    return
                end

                if not IsInCircle(targetPos, radius, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                    return
                end           

                local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
                if Formular.IsJudgeEnd(judge) then
                    return
                end

                local buff = StatusFactoryInst:NewStatusBuff(self.m_giver, BattleEnum.AttrReason_SKILL, time)
                local chgAtkSpeed = tmpTarget:CalcAttrChgValue(ACTOR_ATTR.BASE_ATKSPEED, percent)
                buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, FixMul(chgAtkSpeed, -1))
                self:AddStatus(performer, tmpTarget, buff)
            end
        )
    end
end

return Medium35012