local BattleEnum = BattleEnum
local FixDiv = FixMath.div
local FixSub = FixMath.sub
local FixIntMul = FixMath.muli
local ActorManagerInst = ActorManagerInst
local ACTOR_ATTR = ACTOR_ATTR

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor2030 = BaseClass("Actor2030", Actor)

function Actor2030:__init()
    self.m_20303SkillItem = nil
    self.m_20303Level = 0
    self.m_20303AHP = 0
    self.m_20303XPercent = 0

    self.m_activePassive = false
    self.m_addHurtMul = false
    self.m_addAttrList = {}

    self.m_intervalTime = 100
    self.m_baseHP = 0
end


function Actor2030:OnBorn(create_param)
    Actor.OnBorn(self, create_param)
    self.m_baseHP = self:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAXHP)

    local skillItem = self.m_skillContainer:GetPassiveByID(20303)
    if skillItem then
        self.m_20303SkillItem = skillItem
        local level = skillItem:GetLevel()
        self.m_20303Level = level
        local skillCfg = ConfigUtil.GetSkillCfgByID(20303)
        if skillCfg then
            self.m_20303AHP = FixIntMul(FixDiv(SkillUtil.A(skillCfg, level), 100), self.m_baseHP)
            self.m_20303XPercent = FixDiv(SkillUtil.X(skillCfg, level), 100)
        end
    end

end



function Actor2030:ChangeHP(giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)
    Actor.ChangeHP(self, giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)

    if self:IsLive() and chgVal < 0 and self.m_20303SkillItem then
        local curHP = self:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
        if curHP < self.m_20303AHP then
            if not self.m_activePassive then
                self.m_activePassive = true
            end
        else
            if self.m_activePassive then
                self.m_activePassive = false
            end
        end
    end
end


function Actor2030:ClearBuff()
    self.m_addHurtMul = false
    for targetID, attrInfo in pairs(self.m_addAttrList) do 
        local target = ActorManagerInst:GetActor(targetID)
        if target and target:IsLive() then
            local targetData = target:GetData()
            targetData:AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, FixIntMul(attrInfo.phyAtk, -1))
            targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, FixIntMul(attrInfo.magicAtk, -1))
        end
    end
    self.m_addAttrList = {}
end


function Actor2030:LogicUpdate(detalMS)
    self.m_intervalTime = FixSub(self.m_intervalTime, detalMS)
    if self.m_intervalTime <= 0 then
        self.m_intervalTime = 100 
        if self.m_activePassive then
                if not self.m_addHurtMul then
                    self:AddFriendHurtMul()
                end
        else
            if self.m_addHurtMul then
                self:ClearBuff()
            end
        end
    end
end

function Actor2030:AddFriendHurtMul()
    self.m_addHurtMul = true

    local battleLogic = CtlBattleInst:GetLogic()
    ActorManagerInst:Walk(
        function(tmpTarget)       
            if not battleLogic:IsFriend(self, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE, nil, nil, true) then
                return
            end

            local targetID = tmpTarget:GetActorID()
            if self.m_addAttrList[targetID] then
                return
            end

            local targetData = tmpTarget:GetData()
            local curPhyAtk = targetData:GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK)
            local chgPhyAtk = FixIntMul(curPhyAtk, self.m_20303XPercent)
            targetData:AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, chgPhyAtk)

            local curMagicAtk = targetData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK)
            local chgMagicAtk = FixIntMul(curMagicAtk, self.m_20303XPercent)
            targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, chgMagicAtk)

            self.m_addAttrList[targetID] = {phyAtk = chgPhyAtk, magicAtk = chgMagicAtk}
        end
    )
end

function Actor2030:OnSBDie(dieActor, killerGiver)
    local dieActorID = dieActor:GetActorID()
    if dieActorID == self.m_actorID and self.m_20303Level < 4 then
        self:ClearBuff()
    end
end

return Actor2030