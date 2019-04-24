local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local FixFloor = FixMath.floor
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local FixIntMul = FixMath.muli
local BattleCameraMgr = BattleCameraMgr
local IsInRect = SkillRangeHelper.IsInRect
local IsInCircle = SkillRangeHelper.IsInCircle
local FixRand = BattleRander.Rand
local Formular = Formular

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill12011 = BaseClass("Skill12011", SkillBase)

function Skill12011:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end

    -- 胆烈狂刀 1-2
    -- 乐进挥舞长刀对技能范围内所有敌人造成{x1}（+{E}%物攻)点物理伤害。其中，远端的目标有{A}%概率被恐惧{B}秒。
    -- 3-4
    -- 乐进挥舞长刀对技能范围内所有敌人造成{x3}（+{E}%物攻)点物理伤害。其中，远端的目标有{A}%概率被恐惧{B}秒。
    -- 若远端目标已被虚弱，则必然被恐惧。若其未被恐惧，则被虚弱{B}秒。
    -- 5-6
    -- 乐进挥舞长刀对技能范围内所有敌人造成{x5}（+{E}%物攻)点物理伤害。其中，远端的目标有{A}%概率被恐惧{B}秒。
    -- 若远端目标已被虚弱，则必然被恐惧。若其未被恐惧，则被虚弱{B}秒。本技能造成的恐惧或虚弱状态额外延长{C}秒。

    local battleLogic = CtlBattleInst:GetLogic()
    local factory = StatusFactoryInst
    local StatusGiverNew = StatusGiver.New
    local selfPos = performer:GetPosition()
    local perforDir = performPos - selfPos
    local radius = self.m_skillCfg.dis3

    local time = FixIntMul(self:B(), 1000)
    if self.m_level >= 5 then
        time = FixAdd(FixIntMul(self:C(), 1000), time)
    end

    local function AddWeakStatus(target)
        local giver = StatusGiverNew(performer:GetActorID(), 12011)
        local statusWeakNew = factory:NewStatusWeak(giver, time)
        self:AddStatus(performer, target, statusWeakNew)
    end

    local function AddFearStatus(target)
        local giver = StatusGiverNew(performer:GetActorID(), 12011)
        local statusFear = factory:NewStatusFear(giver, time)
        self:AddStatus(performer, target, statusFear)
    end

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not self:InRange(performer, tmpTarget, perforDir, performPos) then
                return
            end

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            local statusWeak = tmpTarget:GetStatusContainer():GetStatusWeak()
            local isFear = tmpTarget:GetStatusContainer():IsFear()
            if (statusWeak or isFear) and performer:RoundJudgeMustBaoji() then
                judge = BattleEnum.ROUNDJUDGE_BAOJI
            end

            if Formular.IsJudgeEnd(judge) then
                return  
            end

            if IsInCircle(performPos, radius, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                if statusWeak and self.m_level >= 3 then
                    AddFearStatus(tmpTarget)
                else
                    local randVal = FixMod(FixRand(), 100)
                    if randVal <= self:A() then
                        AddFearStatus(tmpTarget)
                    else
                        AddWeakStatus(tmpTarget)
                    end
                end
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
            if injure > 0 then
                local giver = StatusGiverNew(performer:GetActorID(), 12011)
                local status = factory:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                    judge, special_param.keyFrameTimes)
                self:AddStatus(performer, tmpTarget, status)
            end
        end
    )

    
end

return Skill12011