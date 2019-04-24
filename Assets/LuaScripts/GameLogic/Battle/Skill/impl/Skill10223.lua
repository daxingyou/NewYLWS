local StatusGiver = StatusGiver
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local FixDiv = FixMath.div
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR
local BattleEnum = BattleEnum
local StatusEnum = StatusEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10223 = BaseClass("Skill10223", SkillBase)

function Skill10223:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() or not target or not target:IsLive()  then 
        return 
    end

    -- 疾风迅雷
    -- 1
    -- 郭嘉对当前目标施放雷法，造成x1%的法术伤害，并在A秒内提升自身攻击速度y1%。
    -- 2-4
    -- 郭嘉对当前目标施放雷法，造成x2%的法术伤害，并在A秒内提升自身攻击速度y2%。
    -- 如果施放疾风迅雷时郭嘉处于风雷翅状态，则令目标眩晕B秒。
    -- 5-6
    -- 郭嘉对当前目标施放雷法，造成x5%的法术伤害，并在A秒内提升自身攻击速度y5%。
    -- 如果施放疾风迅雷时郭嘉处于风雷翅状态，则令目标眩晕B秒。在单场战斗中，郭嘉前C次施放疾风迅雷可造成z5倍伤害。
    target:AddEffect(102212)

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return  
    end

    local injure = Formular.CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self:X())
    if injure > 0 then
        if self.m_level >= 5 then
            local count = performer:GetPerform10223Count()
            if count <= self:C() then
                injure = FixMul(injure, self:Z())
            end
        end

        local giver = StatusGiver.New(performer:GetActorID(), 10223)
        local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
        judge, special_param.keyFrameTimes)
        self:AddStatus(performer, target, status)

        local giver = StatusGiver.New(performer:GetActorID(), 10223)  
        local buff = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:A(), 1000))
        local chgAtkSpeed = performer:CalcAttrChgValue(ACTOR_ATTR.BASE_ATKSPEED, FixDiv(self:Y(), 100))
        buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, chgAtkSpeed)
        buff:SetMergeRule(StatusEnum.MERGERULE_MERGE)
        self:AddStatus(performer, performer, buff)

        if self.m_level >= 2 then
            local fengleichi = performer:GetStatusContainer():GetGuojiaFengleichi()
            if fengleichi then
                local giver = StatusGiver.New(performer:GetActorID(), 10223)
                local stunBuff = StatusFactoryInst:NewStatusStun(giver, FixIntMul(self:B(), 1000))
                self:AddStatus(performer, target, stunBuff)
            end
        end
    end
end

return Skill10223