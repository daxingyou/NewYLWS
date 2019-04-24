local StatusGiver = StatusGiver
local FixMul = FixMath.mul
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local BattleEnum = BattleEnum
local Formular = Formular
local Quaternion = Quaternion
local FixDiv = FixMath.div

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20681 = BaseClass("Skill20681", SkillBase)

function Skill20681:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() then
        return
    end
    
    -- 箭雨
    -- 对选定区域发射3波箭雨，每波箭雨对范围内的目标造成{x1}%的物理伤害。
    -- 对选定区域发射3波箭雨，每波箭雨对范围内的目标造成{x2}%的物理伤害，本次技能使用期间，物理暴击额外提升{A}%
    
    if special_param.keyFrameTimes == 1 then
        performer:AddSceneEffect(206802, Vector3.New(performPos.x, performer:GetPosition().y, performPos.z), Quaternion.identity)    
    end

    if self.m_level >= 2 and special_param.keyFrameTimes == 1 then
        performer:AddAttr(FixDiv(self:A(), 100))
    end

    local battleLogic = CtlBattleInst:GetLogic()
    local statusGiverNew = StatusGiver.New
    local performDir = performer:GetForward()
    local baoji = 0
    if self.m_level >= 2 then
        baoji = FixDiv(self:A(), 100)
    end

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not self:InRange(performer, tmpTarget, nil, performPos) then
                return
            end
            
            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
            if injure > 0 then
                local giver = statusGiverNew(performer:GetActorID(), 20681)
                local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                    judge, special_param.keyFrameTimes)
                self:AddStatus(performer, tmpTarget, status)
            end
        end
    )

    if self.m_level >= 2 and special_param.keyFrameTimes == 3 then
        performer:ReduceAttr()
    end
end

return Skill20681