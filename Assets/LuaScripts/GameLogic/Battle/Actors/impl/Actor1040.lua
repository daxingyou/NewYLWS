local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixIntMul = FixMath.muli
local GetSkillCfgByID = ConfigUtil.GetSkillCfgByID
local BattleEnum = BattleEnum
local SkillUtil = SkillUtil
local StatusFactoryInst = StatusFactoryInst
local StatusGiver = StatusGiver
local ACTOR_ATTR = ACTOR_ATTR
local StatusEnum = StatusEnum

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1040 = BaseClass("Actor1040", Actor)

function Actor1040:__init()
    self.m_bloodPool = 0
    self.m_skill10402Count = 0
    self.m_skill10402Value = 0
    
    self.m_skill10402Item = nil
    self.m_skill10402Cfg = nil

    self.m_skill10403Cfg = nil
    self.m_10403XPercent = 0
    self.m_10403Level = 0
    self.m_performedPassive = false

    self.m_skill10401EnemyList = {}

    self.m_reducePercent = 0
end

function Actor1040:ClearEnemyList()
    self.m_skill10401EnemyList = {}
end

function Actor1040:HasEnemy(targetID)
    return self.m_skill10401EnemyList[targetID]
end

function Actor1040:AddEnemy(targetID)
    self.m_skill10401EnemyList[targetID] = true
end

function Actor1040:GetEnemyList()
    return self.m_skill10401EnemyList
end

function Actor1040:AddBloodPool(hp)
    self.m_bloodPool = FixAdd(self.m_bloodPool, hp)
end

function Actor1040:AddAtkSpeedAttr(valuePercent, maxCount, reducePercent)
    if self.m_skill10402Count < maxCount then
        self.m_skill10402Count = FixAdd(self.m_skill10402Count, 1)
        local data = self:GetData()
        local curAtkSpeed = data:GetAttrValue(ACTOR_ATTR.FIGHT_ATKSPEED)
        local chgValue = FixIntMul(valuePercent, curAtkSpeed)
        data:AddFightAttr(ACTOR_ATTR.FIGHT_ATKSPEED, chgValue)
        self.m_skill10402Value = FixAdd(self.m_skill10402Value, chgValue)

        if reducePercent > 0 then
            self.m_reducePercent = FixAdd(self.m_reducePercent, reducePercent)
        end
    end
end

function Actor1040:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    self.m_skill10402Item = self.m_skillContainer:GetActiveByID(10402)
    if self.m_skill10402Item then
        self.m_skill10402Cfg = ConfigUtil.GetSkillCfgByID(10402)
    end

    local skillItem = self.m_skillContainer:GetPassiveByID(10403)
    if skillItem  then
        local level = skillItem:GetLevel()
        self.m_10403Level = level
        self.m_skill10403Cfg = ConfigUtil.GetSkillCfgByID(10403)
        if self.m_skill10403Cfg then
            self.m_10403XPercent = FixDiv(SkillUtil.X(self.m_skill10403Cfg, level), 100)
        end
    end
end

function Actor1040:Get10403Level()
    return self.m_10403Level
end


function Actor1040:PreChgHP(giver, chgHP, hurtType, reason)
    chgHP = Actor.PreChgHP(self, giver, chgHP, hurtType, reason)

    if not self.m_performedPassive and self.m_skill10403Cfg and self.m_bloodPool > 0 then
        local data = self:GetData()
        local curHP = data:GetAttrValue(ACTOR_ATTR.FIGHT_HP)
        if FixAdd(curHP, chgHP) <= 0 then
            local realChgHP = FixSub(1, curHP)
            local giver = StatusGiver.New(self:GetActorID(), 10403)  
            local shield = StatusFactoryInst:NewStatusTaishiciShield(giver, self.m_bloodPool, {104008})
            self:GetStatusContainer():Add(shield, self)

            chgHP = realChgHP
            self.m_performedPassive = true
        end
    end

    return chgHP
end


function Actor1040:OnHurtOther(other, skillCfg, keyFrame, chgVal, hurtType, judge)
    Actor.OnHurtOther(self, other, skillCfg, keyFrame, chgVal, hurtType, judge)

    if chgVal < 0 then
        if self.m_skill10403Cfg then
            self.m_bloodPool = FixAdd(self.m_bloodPool, FixIntMul(FixMul(chgVal, -1), self.m_10403XPercent))
        end
    end
end

function Actor1040:LogicOnFightEnd()
    if self.m_skill10402Value > 0 then
        local data = self:GetData()
        data:AddFightAttr(ACTOR_ATTR.FIGHT_ATKSPEED, FixMul(self.m_skill10402Value, -1))
    end

    self.m_skill10402Value = 0
    self.m_skill10402Count = 0
end

function Actor1040:CalcCD(skillItem, skillCfg)
    if skillCfg.id == 10402 and self.m_reducePercent > 0 then
        local cooldown = skillCfg.cooldown
        local reduceCD = self:CheckSkillCD(cooldown, FixMul(cooldown, self.m_reducePercent))
        reduceCD = FixSub(cooldown, reduceCD)
        return reduceCD
    else
        return Actor.CalcCD(self, skillItem, skillCfg)
    end
end

function Actor1040:OnAttackEnd(skillCfg)
    Actor.OnAttackEnd(self, skillCfg)

    if skillCfg.id == 10401 then
        local movehelper = self:GetMoveHelper()
        if movehelper then
            movehelper:Stop()
        end
    end
end

return Actor1040