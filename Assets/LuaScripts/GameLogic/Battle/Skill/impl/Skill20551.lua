local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local FixFloor = FixMath.floor
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local FixIntMul = FixMath.muli
local BattleCameraMgr = BattleCameraMgr
local Formular = Formular
local ACTOR_ATTR = ACTOR_ATTR

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20551 = BaseClass("Skill20551", SkillBase)

function Skill20551:Perform(performer, target, performPos, special_param)
    if not self.m_skillCfg or not performer then 
        return 
    end

    -- 在选定范围内蓄力{A}秒横击，召唤一片雪浪，对目标区域敌人造成{x1}%物理伤害，并降低{B}%的攻速，持续{C}秒。
    -- 新效果：此次伤害额外提升{D}%的暴击几率。

    local battleLogic = CtlBattleInst:GetLogic()
    local factory = StatusFactoryInst
    local StatusGiverNew = StatusGiver.New
    local perforDir = performer:GetForward()

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not self:InRange(performer, tmpTarget, perforDir, performPos) then
                return
            end
           
            local factor = nil
            if self:GetLevel() == 2 then
                factor = Factor.New()
                factor.phyBaojiProbAdd = FixDiv(self:D(), 100)
            end

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true, factor)
            if Formular.IsJudgeEnd(judge) then
                return  
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
            if injure > 0 then
                local giver = StatusGiverNew(performer:GetActorID(), 20551)
                local status = factory:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                    judge, special_param.keyFrameTimes)
                self:AddStatus(performer, tmpTarget, status)
                
                local buff = factory:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:C(), 1000))
                buff:SetMergeRule(StatusEnum.MERGERULE_NEW_LEFT)  --不能一直减攻速
                
                local baseAtkSpeed = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
                local chgAtkSpeed = FixIntMul(baseAtkSpeed, FixDiv(self:B(), 100))

                buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, FixIntMul(chgAtkSpeed, -1))
                self:AddStatus(performer, tmpTarget, buff)

            end
        end
    )
end


return Skill20551