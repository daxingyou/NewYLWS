 
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local StatusGiver = StatusGiver
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local BattleEnum = BattleEnum
local FixMul = FixMath.mul 

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20122 = BaseClass("Skill20122", SkillBase)

function Skill20122:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() or not target or not target:IsLive() then 
        return 
    end

    --蓄力{A}秒，后对当前攻击目标造成{x1}%的物理伤害。
    --蓄力{A}秒，后对当前攻击目标造成{x2}%的物理伤害。蓄力过程中霸体。
    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return
    end
     
    local giver = StatusGiver.New(performer:GetActorID(), 20122)
    local injure = Formular.CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, 
        BattleEnum.HPCHGREASON_BY_SKILL, judge, special_param.keyFrameTimes)
        self:AddStatus(performer, target, status)
    end      
end

function Skill20122:Preperform(performer, target, performPos)
    if self.m_level >= 2 then 
        local time = FixMul(self:A(), 1000)
        local giver = StatusGiver.New(performer:GetActorID(), 20122)
        local immuneBuff = StatusFactoryInst:NewStatusImmune(giver, time)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_STUN)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_CONTROL)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_NEGATIVE)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_INTERRUPT)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_HURTFLY)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_HURTBACK)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_ALL_BUT_DOT)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_PHY_HURT)
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_MAGIC_HURT)

        immuneBuff:SetCanClearByOther(false)
        self:AddStatus(performer, performer, immuneBuff)
    end 
end

return Skill20122