local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local Formular = Formular
local AtkRoundJudge = Formular.AtkRoundJudge
local IsJudgeEnd = Formular.IsJudgeEnd
local CalcInjure = Formular.CalcInjure
local FixMul = FixMath.mul
local StatusFactoryInst = StatusFactoryInst
local FixNormalize = FixMath.Vector3Normalize
local FixNewVector3 = FixMath.NewFixVector3

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20971 = BaseClass("Skill20971", SkillBase)

function Skill20971:Perform(performer, target, performPos, special_param)
    if not performer or not target or not target:IsLive() then
        return
    end
    
    -- 选择单体目标，召唤怒雷，造成{x1}<color=#00ff00>（+{E}%法攻)</color>点<color=#ee00ee>法术伤害</color>。
    -- 选择单体目标，召唤怒雷，造成{x2}<color=#00ff00>（+{E}%法攻)</color>点<color=#ee00ee>法术伤害</color>，并附加持续{A}秒的麻痹状态。麻痹状态下角色无法获得怒气。

    local distance = 0
    target:AddEffect(209702)

    local judge = AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if IsJudgeEnd(judge) then
        return  
    end

    local injure = CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self:X())
    if injure > 0 then
        local giver = StatusGiver.New(performer:GetActorID(), 20971)
        local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, special_param.keyFrameTimes)
        self:AddStatus(performer, target, status)

        if self.m_level == 2 then
            local giver = StatusGiver.New(performer:GetActorID(), 20971)
            local statusPalsy = StatusFactoryInst:NewStatusPalsy(giver, FixMul(self:A(), 1000))
            self:AddStatus(performer, target, status)
        end
    end
end

return Skill20971