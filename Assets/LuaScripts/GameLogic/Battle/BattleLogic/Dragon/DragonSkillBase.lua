local BattleEnum = BattleEnum
local Vector3 = Vector3
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local table_insert = table.insert
local ACTOR_ATTR = ACTOR_ATTR
local FixNewVector3 = FixMath.NewFixVector3
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local StatusEnum = StatusEnum

local DragonSkillBase = BaseClass("DragonSkillBase")

function DragonSkillBase:__init(dragonData, battleDragon)
    self.m_dragonCfg = ConfigUtil.GetGodBeastCfgByID(dragonData.dragonID)
    self.m_dragonLevel = dragonData.dragonLevel
    self.m_battleDragon = battleDragon
    self.m_talentSkillList = {}
    for _, talentData in ipairs(dragonData.talentList) do
        local talentCfg = ConfigUtil.GetGodBeastTalentCfgByID(talentData.talentID)
        if talentCfg then
            local level = FixSub(talentData.talentLevel, 1)
            self.m_talentSkillList[talentData.talentID] = {
                talentID = talentData.talentID,
                talentLevel = talentData.talentLevel,
                x = FixAdd(talentCfg.x, FixMul(talentCfg.ax, level)),
                y = FixAdd(talentCfg.y, FixMul(talentCfg.ay, level)),
            }
        end
    end
end

function DragonSkillBase:__delete()
    self.m_dragonCfg = false
    self.m_dragonLevel = 0
end

function DragonSkillBase:GetDragonCfg()
    return self.m_dragonCfg
end

function DragonSkillBase:GetHPConditionPercent()
    local hp = self.m_dragonCfg.hp
    local talentSkillData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_QINJIN)
    if talentSkillData then
        return talentSkillData.x
    else
        return hp
    end
end

function DragonSkillBase:GetTalentSkill(skillID)
    return self.m_talentSkillList[skillID]
end

function DragonSkillBase:X()
    local level = FixSub(self.m_dragonLevel, 1)
    local delta = FixMul(self.m_dragonCfg.ax, level)
    return FixAdd(self.m_dragonCfg.x, delta)
end

function DragonSkillBase:Y()
    local level = FixSub(self.m_dragonLevel, 1)
    local yLevel = 0
    for _, limitLevel in ipairs(self.m_dragonCfg.unlocklevel) do
        if level >= limitLevel then
            yLevel = FixAdd(yLevel, 1)
        end
    end
    local delta = FixMul(self.m_dragonCfg.ay, yLevel)
    return FixAdd(self.m_dragonCfg.y, delta)
end

function DragonSkillBase:PerfromDragonSkill(summonEntity)
    return false
end

function DragonSkillBase:GetFriendCampCenterByID(camp)
    local center = Vector3.zero
    local count = 0
    ActorManagerInst:Walk(
        function(tmpTarget)
            if CtlBattleInst:GetLogic():IsDragonFriend(camp, tmpTarget, BattleEnum.RelationReason_RECOVER) then
                center:Add(tmpTarget:GetPosition())
                count = FixAdd(count, 1)
            end
        end
    )
    if count > 1 then
        -- local x,y,z = center:GetXYZ()
        -- center = FixNewVector3(FixDiv(x, count), FixDiv(y, count), FixDiv(z, count))
        center:Div(count)
    end
    return center
end

function DragonSkillBase:GetEnemyCampCenterByID(camp)
    local center = FixNewVector3(0, 0, 0)
    local count = 0
    ActorManagerInst:Walk(
        function(tmpTarget)
            if CtlBattleInst:GetLogic():IsDragonEnemy(camp, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                center:Add(tmpTarget:GetPosition())
                count = FixAdd(count, 1)
            end
        end
    )
    if count > 1 then
        -- local x,y,z = center:GetXYZ()
        -- center = FixNewVector3(FixDiv(x, count), FixDiv(y, count), FixDiv(z, count))
        center:Div(count)
    end
    return center
end

function DragonSkillBase:CheckDragonTalentSkill()
    local camp = self.m_battleDragon:GetCamp()
    local actorID = self.m_battleDragon:GetFakeActorID()
    local level = self.m_battleDragon:GetDragonLevel()
    local battleLogic = CtlBattleInst:GetLogic()
    local statusFactor = StatusFactoryInst

    ActorManagerInst:Walk(
        function(tmpTarget)
            if battleLogic:IsDragonFriend(camp, tmpTarget, BattleEnum.RelationReason_RECOVER) then
                --释放后，我方全体减免{x}%受到的伤害,持续{y}秒
                local yingkeData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_YINGKE)
                if yingkeData then
                    local statusNTimeBeHurtChg = statusFactor:NewStatusNTimeBeHurtMul(StatusGiver.New(actorID, level), FixIntMul(yingkeData.y, 1000), FixSub(1, FixDiv(yingkeData.x, 100)))
                    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_PHY_HURT)
                    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_MAGIC_HURT)
                    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_REAL_HURT)
                    tmpTarget:GetStatusContainer():Add(statusNTimeBeHurtChg, tmpTarget)
                end
                --释放后，我方全体额外获得{x}点怒气
                local baonuData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_BAONU)
                if baonuData then
                    tmpTarget:ChangeNuqi(baonuData.x, BattleEnum.NuqiReason_SKILL_RECOVER)
                end
                --释放后，立刻减少我方全体所有主动技能的冷却时间{x}秒
                local zhenfenData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_ZHENGFEN)
                if zhenfenData then
                    tmpTarget:ReduceSkillCD(zhenfenData.x)
                end
                --释放后，我方全体攻速提升{x}%,持续{y}秒
                local xunjieData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_XUNJIE)
                if xunjieData then
                    local buff = statusFactor:NewStatusBuff(StatusGiver.New(actorID, level), BattleEnum.AttrReason_SKILL, FixIntMul(xunjieData.y, 1000))
                    buff:SetMergeRule(StatusEnum.MERGERULE_TOGATHER)
                    local chgAtkSpeed = FixIntMul(tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED), FixDiv(xunjieData.x, 100))
                    buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, chgAtkSpeed)
                    tmpTarget:GetStatusContainer():Add(buff, tmpTarget)
                end
                --释放后，我方全体获得生命上限{x}%的全效护盾,持续{y}秒
                local jindunData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_JINDUN)
                if jindunData then
                    local hpStore = FixIntMul(tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAXHP), FixDiv(jindunData.x, 100))
                    local shield = statusFactor:NewStatusAllTimeShield(StatusGiver.New(actorID, level), hpStore, FixIntMul(jindunData.y, 1000))
                    shield:SetMergeRule(StatusEnum.MERGERULE_MERGE)
                    tmpTarget:GetStatusContainer():Add(shield, tmpTarget)
                end
                --释放后，我方全体受到伤害的{x}%将反弹给施加者，持续{y}秒
                local fantanData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_FANZHEN)
                if fantanData then
                    local fantanStatus = statusFactor:NewStatusFanTan(StatusGiver.New(actorID, level), FixIntMul(fantanData.y, 1000), FixDiv(fantanData.x, 100))
                    tmpTarget:GetStatusContainer():Add(fantanStatus, tmpTarget)
                end
                --释放神兽技后，己方全体的物理攻击提升{x}%，持续{y}秒
                local yuweiData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_YUWEI)
                if yuweiData then
                    local buff = statusFactor:NewStatusBuff(StatusGiver.New(actorID, level), BattleEnum.AttrReason_SKILL, FixIntMul(yuweiData.y, 1000))
                    buff:SetMergeRule(StatusEnum.MERGERULE_TOGATHER)
                    local chgAtk = FixIntMul(tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_PHY_ATK), FixDiv(yuweiData.x, 100))
                    buff:AddAttrPair(ACTOR_ATTR.FIGHT_PHY_ATK, chgAtk)
                    tmpTarget:GetStatusContainer():Add(buff, tmpTarget)
                end
                --释放神兽技后，己方全体的法术攻击提升{x}%，持续{y}秒
                local yureData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_YURE)
                if yureData then
                    local buff = statusFactor:NewStatusBuff(StatusGiver.New(actorID, level), BattleEnum.AttrReason_SKILL, FixIntMul(yureData.y, 1000))
                    buff:SetMergeRule(StatusEnum.MERGERULE_TOGATHER)
                    local chgAtk = FixIntMul(tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAGIC_ATK), FixDiv(yureData.x, 100))
                    buff:AddAttrPair(ACTOR_ATTR.FIGHT_MAGIC_ATK, chgAtk)
                    tmpTarget:GetStatusContainer():Add(buff, tmpTarget)
                end
            elseif battleLogic:IsDragonEnemy(camp, tmpTarget, BattleEnum.RelationReason_RECOVER) then
                --释放后，我方全体造成的伤害增加{x}%,持续{y}秒
                local zengshangData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_ZENGSHANG)
                if zengshangData then
                    local statusNTimeBeHurtChg = statusFactor:NewStatusNTimeBeHurtMul(StatusGiver.New(actorID, level), FixIntMul(zengshangData.y, 1000), FixAdd(1, FixDiv(zengshangData.x, 100)))
                    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_PHY_HURT)
                    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_MAGIC_HURT)
                    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_REAL_HURT)
                    tmpTarget:GetStatusContainer():Add(statusNTimeBeHurtChg, tmpTarget)
                end
                --释放后，降低对方全体{x}点怒气
                local zhinuData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_ZHINU)
                if zhinuData then
                    tmpTarget:ChangeNuqi(FixIntMul(zhinuData.x, -1), BattleEnum.NuqiReason_SKILL_RECOVER)
                end
                --释放后，额外降低敌方全体{x}%的攻击速度，持续{y}秒
                local chihuanData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_CHIHUAN)
                if chihuanData then
                    local buff = statusFactor:NewStatusBuff(StatusGiver.New(actorID, level), BattleEnum.AttrReason_SKILL, FixIntMul(chihuanData.y, 1000))
                    buff:SetMergeRule(StatusEnum.MERGERULE_TOGATHER)
                    local chgAtkSpeed = FixIntMul(tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED), FixDiv(chihuanData.x, 100))
                    buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, FixIntMul(chgAtkSpeed, -1))
                    tmpTarget:GetStatusContainer():Add(buff, tmpTarget)
                end
                --释放后，降低敌方全体{x}%的闪避，持续{y}秒
                local daizhiData = self:GetTalentSkill(BattleEnum.DRAGON_TALENT_SKILL_DAIZHI)
                if daizhiData then
                    local buff = statusFactor:NewStatusBuff(StatusGiver.New(actorID, level), BattleEnum.AttrReason_SKILL, FixIntMul(daizhiData.y, 1000))
                    buff:SetMergeRule(StatusEnum.MERGERULE_TOGATHER)
                    local chgShanbi = FixIntMul(tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_SHANBI), FixDiv(daizhiData.x, 100))
                    buff:AddAttrPair(ACTOR_ATTR.FIGHT_SHANBI, FixIntMul(chgShanbi, -1))
                    tmpTarget:GetStatusContainer():Add(buff, tmpTarget)
                end
            end
        end
    )
end

return DragonSkillBase