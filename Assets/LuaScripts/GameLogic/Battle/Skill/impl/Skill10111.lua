local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixIntMul = FixMath.muli
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10111 = BaseClass("Skill10111", SkillBase)

function Skill10111:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() or not target or not target:IsLive() then
        return
    end

    -- 唤雷之法
    -- 法正召唤一道强力的天雷，对目标造成{x1}%的法术伤害。
    -- 法正召唤一道强力的天雷，对目标造成{x2}%的法术伤害，眩晕{A}秒。
    -- 法正召唤一道强力的天雷，对目标造成{x3}%的法术伤害，眩晕{A}秒。
    -- 法正召唤一道强力的天雷，对目标造成{x4}%的法术伤害，眩晕{A}秒,并降低法防{y4}%，持续{B}秒。
    -- 法正召唤一道强力的天雷，对目标造成{x5}%的法术伤害，眩晕{A}秒,并降低法防{y5}%，持续{B}秒。
    -- 法正召唤一道强力的天雷，对目标造成{x6}%的法术伤害，眩晕{A}秒,并降低法防{y6}%，持续5秒。
    target:AddEffect(101104)
    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return  
    end

    local injure = Formular.CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self:X())
    if injure > 0 then 
        local giver = StatusGiver.New(performer:GetActorID(), 10111)
        local delayHurtStatus = StatusFactoryInst:NewStatusDelayHurt(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, 0, BattleEnum.HPCHGREASON_BY_SKILL, special_param.keyFrameTimes, judge)
        self:AddStatus(performer, target, delayHurtStatus)

        if self.m_level >= 2 then
            local giver = StatusGiver.New(performer:GetActorID(), 10111)
            local stunBuff = StatusFactoryInst:NewStatusStun(giver, FixIntMul(self:A(), 1000))
            self:AddStatus(performer, target, stunBuff)

            if self.m_level >= 4 then
                local giver = StatusGiver.New(performer:GetActorID(), 10111)
                local buff = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:B(), 1000))
                local curMagicDef = target:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAGIC_DEF)
                local chgMagicDef = FixIntMul(curMagicDef, FixDiv(self:Y(), 100))
                buff:AddAttrPair(ACTOR_ATTR.FIGHT_MAGIC_DEF, FixMul(chgMagicDef, -1))
                self:AddStatus(performer, target, buff)
            end
        end
    end
end

return Skill10111