local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20963 = BaseClass("Skill20963", SkillBase)

local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR
local BattleEnum = BattleEnum
local StatusEnum = StatusEnum
local FixIntMul = FixMath.muli
local FixDiv = FixMath.div

function Skill20963:OnFightStart(performer, currWave)
    if not performer or not performer:IsLive() then
        return
    end

-- "提升郭汜生命上限<color=#ffb400>{x1}%</color>。",
-- "提升的生命上限增加至<color=#ffb400>{x2}%</color>",
-- "提升的生命上限增加至<color=#ffb400>{x3}%</color>",
-- "提升的生命上限增加至<color=#ffb400>{x4}%</color>\n新效果1：额外提升物理攻击<color=#ffb400>{y4}%</color>",

    if currWave == 1 then
        local giver = StatusGiver.New(performer:GetActorID(), 20963)
        local buff = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:A(), 1000))
    
        local maxHP = performer:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAXHP)
        local chgMaxHP = FixIntMul(maxHP, FixDiv(self:X(), 100))
        performer:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MAXHP, chgMaxHP)

        local statusHP = StatusFactoryInst:NewStatusHP(giver, chgMaxHP, BattleEnum.HURTTYPE_REAL_HURT, BattleEnum.HPCHGREASON_BY_SKILL, BattleEnum.ROUNDJUDGE_NORMAL, 0)
        self:AddStatus(performer, performer, statusHP)
        
        if self:GetLevel() >= 4 then
            local phyAtk = performer:GetData():GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK)
            local chgPhyAtk = FixIntMul(phyAtk, FixDiv(self:Y(), 100))
            performer:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, chgPhyAtk)
        end

        self:AddStatus(performer, performer, buff)
    end
end

return Skill20963