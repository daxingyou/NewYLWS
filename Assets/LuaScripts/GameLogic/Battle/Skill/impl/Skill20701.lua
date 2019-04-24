local BattleEnum = BattleEnum
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local NewFixVector3 = FixMath.NewFixVector3
local table_insert = table.insert
local FixMod = FixMath.mod 
local FixAdd = FixMath.add
local FixVetor3RotateAroundY = FixMath.Vector3RotateAroundY
local ACTOR_ATTR = ACTOR_ATTR
local ActorManagerInst = ActorManagerInst

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20701 = BaseClass("Skill20701", SkillBase)
local ActorCreateParam = require "GameLogic.Battle.Actors.ActorCreateParam"

function Skill20701:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() then
        return
    end
    -- 水行妖召唤
    -- 吟唱{A}秒，召唤一个水行妖，水行妖继承角色{x1}%的属性。场上最多存在{C}个水行妖
    -- 吟唱{A}秒，召唤一个水行妖，水行妖继承角色{x2}%的属性，水行妖攻击时使目标攻击速度降低{B}%。场上最多存在{C}个水行妖
    -- 吟唱{A}秒，召唤一个水行妖，水行妖继承角色{x3}%的属性，水行妖攻击时使目标攻击速度降低{B}%。场上最多存在{C}个水行妖
    -- 吟唱{A}秒，召唤一个水行妖，水行妖继承角色{x4}%的属性，水行妖攻击时使目标攻击速度降低{B}%。场上最多存在{C}个水行妖

    local shuiyaoCount = performer:GetCurShuiyaoCount()
    local maxShuiyaoCount = self:C()
    if shuiyaoCount >= maxShuiyaoCount then
        return
    end
    
    local standIndex = FixMod(performer:GetCallCount(), 4)
    standIndex = FixAdd(standIndex, 1)
    performer:AddCallCount()
    self:Call(performer, performer:GetPosition(), 2061, FixDiv(self:X(), 100), standIndex)
end


function Skill20701:Call(performer, pos, resID, percent, standIndex)
    if not performer:CanCall() then
        return
    end
    
    local roleCfg = ConfigUtil.GetWujiangCfgByID(resID)
    if not roleCfg then
        -- print(' no zhang jiao hu fa role cfg ========== ')
        return
    end

    local oneWujiang = OneBattleWujiang.New()
    oneWujiang.wujiangID = roleCfg.id
    oneWujiang.level = performer:GetLevel()
    oneWujiang.init_nuqi = roleCfg.initNuqi
    oneWujiang.lineUpPos = 0

    local fightData = performer:GetData()
    oneWujiang.max_hp = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAXHP), percent)
    oneWujiang.phy_atk = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK), percent)
    oneWujiang.phy_def = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_DEF), percent)
    oneWujiang.magic_atk = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK), percent)
    oneWujiang.magic_def = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_DEF), percent)
    oneWujiang.phy_baoji = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_BAOJI), percent)
    oneWujiang.magic_baoji = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_BAOJI), percent)
    oneWujiang.shanbi = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_SHANBI), percent)
    oneWujiang.mingzhong = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MINGZHONG), percent)
    oneWujiang.move_speed = fightData:GetAttrValue(ACTOR_ATTR.BASE_MOVESPEED)
    oneWujiang.atk_speed = fightData:GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)

    table_insert(oneWujiang.skillList, {skill_id = 20611, skill_level = self.m_level})
    table_insert(oneWujiang.skillList, {skill_id = 20612, skill_level = self.m_level})

    local createParam = ActorCreateParam.New()
    createParam:MakeSource(BattleEnum.ActorSource_CALLED, performer:GetActorID())
    createParam:MakeAI(BattleEnum.AITYPE_SHUIXINGYAO)
    createParam:MakeAttr(performer:GetCamp(), oneWujiang)

    local leftDir = nil
    local dir = performer:GetForward()
    if FixMod(standIndex, 2) == 0 then
        leftDir = FixVetor3RotateAroundY(dir, -120.0)
        if standIndex > 2 then
            leftDir:Mul(2)
        end
        leftDir:Add(pos)
    elseif FixMod(standIndex, 2) == 1 then
        leftDir = FixVetor3RotateAroundY(dir, 120.0)
        if standIndex > 2 then
            leftDir:Mul(2)
        end
        leftDir:Add(pos)
    end

    local bornPos = leftDir
    local pathHandler = CtlBattleInst:GetPathHandler()
    if pathHandler then
        local x,y,z = performer:GetPosition():GetXYZ()
        local x2, y2, z2 = bornPos:GetXYZ()
        local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
        if hitPos then
            bornPos:SetXYZ(hitPos.x , performer:GetPosition().y, hitPos.z)
        end
    end

    createParam:MakeLocation(bornPos, performer:GetForward())
    createParam:MakeRelationType(BattleEnum.RelationType_NORMAL)
    createParam:SetImmediateCreateObj(true)
    
    local shuiyaoActor = ActorManagerInst:CreateActor(createParam)
    shuiyaoActor:SetLeftTime(FixIntMul(self:Y(), 1000))
    performer:AddShuiyaoTargetID(shuiyaoActor:GetActorID())
    if self.m_level >= 2 then
        shuiyaoActor:SetAtkEffectPercent(FixDiv(self:B(), 100), FixIntMul(self:D(), 1000))
    end
end


return Skill20701