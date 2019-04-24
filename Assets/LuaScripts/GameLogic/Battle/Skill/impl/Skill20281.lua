local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local FixIntMul = FixMath.muli
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular
local StatusEnum = StatusEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20281 = BaseClass("Skill20281", SkillBase)

function Skill20281:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end

    --1，对目标区域造成{x1}点群体物理伤害。
    --2，对目标区域造成{x2}点群体物理伤害。范围内的所有敌人移动速度降低{y2}%，持续{A}秒。

    local factory = StatusFactoryInst
    local statusGiverNew = StatusGiver.New
    local battleLogic = CtlBattleInst:GetLogic()
    
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end
            
            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return
            end

            if not self:InRange(performer, tmpTarget, nil, performPos) then
                return
            end

            local giver = statusGiverNew(performer:GetActorID(), 20281)
            local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
            if injure > 0 then
                local status = factory:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, special_param.keyFrameTimes)
                self:AddStatus(performer, tmpTarget, status)
            end

            if self.m_level == 2 then
                local movePercent = FixDiv(self:Y(), 100)
                local attrBuff = factory:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:A(), 1000))
                attrBuff:SetMergeRule(StatusEnum.MERGERULE_MERGE)

                local curMoveSpeed = performer:GetData():GetAttrValue(ACTOR_ATTR.BASE_MOVESPEED)
                local chgMoveSpeed = FixIntMul(curMoveSpeed, movePercent)
                attrBuff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, chgMoveSpeed)

                self:AddStatus(performer, tmpTarget, attrBuff)
            end
        end
    )

end


return Skill20281