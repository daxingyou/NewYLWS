local StatusGiver = StatusGiver
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local ACTOR_ATTR = ACTOR_ATTR
local BattleEnum = BattleEnum
local Formular = Formular

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill12141 = BaseClass("Skill12141", SkillBase)

function Skill12141:Perform(performer, target, performPos, special_param)
    if not self.m_skillCfg or not performer then
        return
    end
    
    -- name = 光束冲击
    -- 1-4
    -- 于吉向前发射一道光束冲击，对路径上的所有敌人造成{x1}（+{E}%法攻)点法术伤害。
    -- 光束冲击会消耗太平符箓进行强化，每消耗1张太平符箓会额外造成{y1}（+{E}%法攻)点真实伤害。
    -- 5-6
    -- 于吉向前发射一道光束冲击，对路径上的所有敌人造成{x5}（+{E}%法攻)点法术伤害。
    -- 光束冲击会消耗太平符箓进行强化，每消耗1张太平符箓会额外造成{y5}（+{E}%法攻)点真实伤害。光束冲击暴击时，暴击伤害额外提升{z5}%。
    
    local battleLogic = CtlBattleInst:GetLogic()
    local factory = StatusFactoryInst
    local statusGiverNew = StatusGiver.New
    local performDir = performer:GetForward()
    local performerPos = performer:GetPosition()
    local count = performer:Get12143Count()

    BattleCameraMgr:Shake()
    performer:FlyMediumToPoint(performerPos + performDir *self.m_skillCfg.dis2)

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not self:InRange(performer, tmpTarget, performDir, performerPos) then
                return
            end
            
            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end

            local mul = 1
            local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self:X())
            if injure > 0 then
                if self.m_level >= 3 and judge == BattleEnum.ROUNDJUDGE_BAOJI then
                    mul = FixAdd(mul, FixDiv(self:Z(), 100))
                end

                local hurtMul = 0
                if self.m_level >= 3 then
                    local dieWujiangCount = performer:GetWujiangDieCount()
                    if dieWujiangCount > 0 then
                        hurtMul = FixMul(FixDiv(self:Z(), 100), dieWujiangCount)
                        local maxMul = FixDiv(self:A(), 100)
                        if hurtMul > maxMul then
                            hurtMul = maxMul
                        end

                        injure = FixAdd(injure, FixMul(injure, hurtMul))
                    end
                end

                local giver = statusGiverNew(performer:GetActorID(), 12141)
                local status = factory:NewStatusHP(giver, FixMul(-1, FixMul(injure, mul)), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                    judge, special_param.keyFrameTimes)
                self:AddStatus(performer, tmpTarget, status)

                if count > 0 then
                    local giver = statusGiverNew(performer:GetActorID(), 12141)
                    local tmpTargetMaxHP = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAXHP)
                    local hp = FixMul(FixMul(tmpTargetMaxHP, count), FixDiv(self:Y(), 100))
                    local maxInjure = Formular.CalcMaxHPInjure(self:Y(), tmpTarget, BattleEnum.MAXHP_INJURE_PRO_MAXHP)
                    if hp > maxInjure then
                        hp = maxInjure
                    end
                    local delayHurtStatus = factory:NewStatusDelayHurt(giver, FixMul(-1, hp), BattleEnum.HURTTYPE_REAL_HURT, 300, BattleEnum.HPCHGREASON_BY_SKILL, special_param.keyFrameTimes)
                    self:AddStatus(performer, tmpTarget, delayHurtStatus)
                end
            end
        end
    )

    performer:Clear12143Count()
end

return Skill12141