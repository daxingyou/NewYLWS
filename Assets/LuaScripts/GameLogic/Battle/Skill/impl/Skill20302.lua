local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local ACTOR_ATTR = ACTOR_ATTR
local StatusEnum = StatusEnum
local FixMul = FixMath.mul

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20302 = BaseClass("Skill20302", SkillBase)

function Skill20302:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() or not target or not target:IsLive() then
        return
    end

    -- 叫嚣 
    -- 嘲讽当前目标，令其主动攻击自身，持续{x1}秒。被嘲讽的对象在此期间内只能使用普通攻击。
    -- 嘲讽当前目标，令其主动攻击自身，持续{x2}秒。被嘲讽的对象在此期间内只能使用普通攻击。
    -- 嘲讽当前目标，令其主动攻击自身，并提升南蛮将领自身的物理暴击{B}%，持续{x3}秒。被嘲讽的对象在此期间内只能使用普通攻击。
    -- 嘲讽当前目标，令其主动攻击自身，并提升南蛮将领自身的物理暴击{B}%，持续{x4}秒。被嘲讽的对象在此期间内只能使用普通攻击。

    local time = FixIntMul(self:X(), 1000)
    local giver = StatusGiver.New(performer:GetActorID(), 20302)
    local statusChaofeng = StatusFactoryInst:NewStatusChaoFeng(giver, performer:GetActorID(), time)
    self:AddStatus(performer, target, statusChaofeng)

    if self.m_level >= 3 then
        local giver = StatusGiver.New(performer:GetActorID(), 20302)
        local attrBuff = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, time)
        attrBuff:SetMergeRule(StatusEnum.MERGERULE_MERGE)
        attrBuff:AddAttrPair(ACTOR_ATTR.PHY_BAOJI_PROB_CHG, FixDiv(self:B(), 100))
        self:AddStatus(performer, performer, attrBuff)
    end
end

return Skill20302