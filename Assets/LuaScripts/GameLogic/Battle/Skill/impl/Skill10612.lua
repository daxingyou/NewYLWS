local StatusGiver = StatusGiver
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local FixMul = FixMath.mul
local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR
local BattleEnum = BattleEnum
local StatusEnum = StatusEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10612 = BaseClass("Skill10612", SkillBase)

function Skill10612:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() then 
        return 
    end

    -- 整场战斗包括3关式战斗，过一小关的时候物攻提升不会消失.提升做加法不要千万不要做乘法，因为指数爆炸。
    -- 加攻速buff重复叠加时只刷新持续Cd，攻速不会叠加。
    -- 火力全开  1-2 
    -- 于禁放弃防御，火力全开。在接下来的{A}秒内，失去全部双防，提升{x1}%的攻击速度，并免疫一切控制。
    -- 3-4
    -- 于禁放弃防御，火力全开。在接下来的{A}秒内，失去全部双防，提升{x3}%的攻击速度，并免疫一切控制。
    -- 于禁每释放1次火力全开，物理攻击额外提升{y3}%，，最多提升{B}次，整场战斗生效。
    -- 5-6
    -- 于禁放弃防御，火力全开。在接下来的{A}秒内，失去全部双防，提升{x6}%的攻击速度和{z6}%的物理吸血，并免疫一切控制。
    -- 于禁每释放1次火力全开，物理攻击额外提升{y6}%，，最多提升{B}次，整场战斗生效。
    local time = FixIntMul(self:A(), 1000)
    local StatusGiverNew = StatusGiver.New
    local factory = StatusFactoryInst

    local giver = StatusGiverNew(performer:GetActorID(), 10612)
    local attrBuff = factory:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, time)
    attrBuff:SetMergeRule(StatusEnum.MERGERULE_MERGE)

    local curAtkSpeed = performer:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
    local chgAtkSpeed = FixIntMul(curAtkSpeed, FixDiv(self:X(), 100))
    attrBuff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, chgAtkSpeed)

    local curPhyDef = performer:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_PHY_DEF)
    local chgPhyDef = FixMul(curPhyDef, -1)
    attrBuff:AddAttrPair(ACTOR_ATTR.FIGHT_PHY_DEF, chgPhyDef)

    local curMagicDef = performer:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAGIC_DEF)
    local chgMagicDef = FixMul(curMagicDef, -1)
    attrBuff:AddAttrPair(ACTOR_ATTR.FIGHT_MAGIC_DEF, chgMagicDef)

    if self.m_level >= 5 then
        attrBuff:AddAttrPair(ACTOR_ATTR.FIGHT_PHY_SUCKBLOOD, FixDiv(self:Z(), 100))
    end

    self:AddStatus(performer, performer, attrBuff)

    local giver = StatusGiverNew(performer:GetActorID(), 10612)
    local immuneBuff = factory:NewStatusImmune(giver, time)
    immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_CONTROL)
    self:AddStatus(performer, performer, immuneBuff)

    if self.m_level >= 3 then
        local enhanceAtkCount = performer:GetEnhanceAtkCount()
        if enhanceAtkCount < self:B() then
            local curPhyAtk = performer:GetData():GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK)
            local chgPhyAtk = FixIntMul(curAtkSpeed, FixDiv(self:Y(), 100))
            performer:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, chgPhyAtk)
            performer:AddEnhanceCount()
        end
    end
end

return Skill10612