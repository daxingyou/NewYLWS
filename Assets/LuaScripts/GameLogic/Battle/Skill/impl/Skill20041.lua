local FixIntMul = FixMath.muli
local FixDiv = FixMath.div
local BattleEnum = BattleEnum
local BattleCameraMgr = BattleCameraMgr
local table_insert = table.insert
local ActorManagerInst = ActorManagerInst
local ACTOR_ATTR = ACTOR_ATTR
local FixSub = FixMath.sub

local ActorCreateParam = require "GameLogic.Battle.Actors.ActorCreateParam"

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20041 = BaseClass("Skill20041", SkillBase)


function Skill20041:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end
    local roleCfg = ConfigUtil.GetWujiangCfgByID(2046)
    local attrMul = FixDiv(self:Y(), 100)
    
    local fightData = performer:GetData()
    local oneWujiang = OneBattleWujiang.New()
    oneWujiang.wujiangID    = roleCfg.id
    oneWujiang.level        = self.m_level
    oneWujiang.lineUpPos    = 1
    oneWujiang.max_hp       = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAXHP), attrMul)
    oneWujiang.phy_atk      = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK), attrMul)
    oneWujiang.phy_def      = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_DEF), attrMul)
    oneWujiang.magic_atk    = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK), attrMul)
    oneWujiang.magic_def    = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_DEF), attrMul)
    oneWujiang.phy_baoji    = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_BAOJI), attrMul)
    oneWujiang.magic_baoji  = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_BAOJI), attrMul)
    oneWujiang.shanbi       = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_SHANBI), attrMul)
    oneWujiang.mingzhong    = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MINGZHONG), attrMul)
    oneWujiang.move_speed   = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MOVESPEED), 1)
    oneWujiang.atk_speed    = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED), 1)
    oneWujiang.hp_recover   = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_HP_RECOVER), attrMul)
    oneWujiang.nuqi_recover = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_NUQI_RECOVER), attrMul)
    oneWujiang.baoji_hurt   = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_BAOJI_HURT), attrMul)
    oneWujiang.init_nuqi    = 100

    table_insert(oneWujiang.skillList, {skill_id = 20461, skill_level = 1})
    table_insert(oneWujiang.skillList, {skill_id = 20462, skill_level = 1})

    local createParam = ActorCreateParam.New()
    createParam:MakeSource(BattleEnum.ActorSource_CALLED, performer:GetActorID())
    createParam:MakeAI(BattleEnum.AITYPE_TUKUILEI)
    createParam:MakeAttr(performer:GetCamp(), oneWujiang)

    local performerPos = performer:GetPosition():Clone()
    local dir = performer:GetForward()
    performerPos:Add(dir)
    performerPos.y = FixSub(performerPos.y, 10)
    local pathHandler = CtlBattleInst:GetPathHandler()
    if pathHandler then
        local x,y,z = performer:GetPosition():GetXYZ()
        local x2, y2, z2 = performerPos:GetXYZ()
        local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
        if hitPos then
            performerPos:SetXYZ(hitPos.x , performer:GetPosition().y, hitPos.z)
        end
    end

    createParam:MakeLocation(performerPos, performer:GetForward())
    createParam:MakeRelationType(BattleEnum.RelationType_NORMAL)
    createParam:SetImmediateCreateObj(true)
    
    local puppetActor = ActorManagerInst:CreateActor(createParam)
    puppetActor:SetOrignalY(performer:GetPosition().y)
    puppetActor:SetOrignalPos(performer:GetPosition())
    local puppetAI = puppetActor:GetAI() 
    if puppetAI then
        local newPerformPos = performPos
        newPerformPos.y = 0
        newPerformPos:Mul(self.m_skillCfg.dis2)
        newPerformPos:Add(performerPos)
        puppetAI:Perform20461Skill(newPerformPos, target:GetActorID())
    end
end



return Skill20041