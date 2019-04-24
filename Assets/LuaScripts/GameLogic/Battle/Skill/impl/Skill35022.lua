local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local IsInCircle = SkillRangeHelper.IsInCircle
local FixIntMul = FixMath.muli
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill35022 = BaseClass("Skill35022", SkillBase)

function Skill35022:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end

    --朱雀燃烧生命发出炙烤光线，令敌我双方每秒受到当前生命值{A}%的法术伤害，持续{B}秒

    performer:Set35022LeftMs(FixIntMul(self:B(), 1000))
    performer:SetperformPos(performPos)
    -- local factory = StatusFactoryInst
    -- local statusGiverNew = StatusGiver.New
    -- ActorManagerInst:Walk(
    --     function(tmpTarget)
    --         if not CtlBattleInst:GetLogic():IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
    --             return
    --         end

    --         if not self:InRange(performer, tmpTarget, performPos, performer:GetPosition()) then
    --             return
    --         end

    --         local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    --         if Formular.IsJudgeEnd(judge) then
    --             return  
    --         end
            
    --         local chgHp = FixMul(self:A(), performer:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP))
    --         if chgHp > 0 then
    --             local giver = statusGiverNew(performer:GetActorID(), 35032)
    --             local status = factory:StatusIntervalHP(giver, FixMul(-1, chgHp), 1000, self:B())
    --             self:AddStatus(performer, tmpTarget, status)
    --             self:AddStatus(performer, performer, status)
    --         end

    --     end
    -- )
            
end

return Skill35022