local BattleEnum = BattleEnum
local Formular = Formular
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local FixIntMul = FixMath.muli
local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local CtlBattleInst = CtlBattleInst
local ACTOR_ATTR = ACTOR_ATTR

local LinearFlyToPointMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToPointMedium")
local Medium10211 = BaseClass("Medium10211", LinearFlyToPointMedium)

function Medium10211:__init()
    self.m_enemyList = {}
    self.m_beginFrozenTime = 0
    self.m_continueTime = 0
    self._frozenTime = 0
    self.m_frozenList = {}
end


function Medium10211:InitParam(param)
    LinearFlyToPointMedium.InitParam(self, param)

    self.m_beginFrozenTime = FixIntMul(self.m_skillBase:B(), 1000)
    self.m_continueTime = FixIntMul(self.m_skillBase:A(), 1000)
    self._frozenTime = FixIntMul(self.m_skillBase:C(), 1000)
end

function Medium10211:MoveToTarget(deltaMS)
    self.m_beginFrozenTime = FixSub(self.m_beginFrozenTime, deltaMS)
    if self.m_beginFrozenTime <= 0 then
        self:CheckReduceEnemy(true)
    else
        self:CheckReduceEnemy()
    end

    self.m_continueTime = FixSub(self.m_continueTime, deltaMS)
    if self.m_continueTime <= 0 then
        self.m_active10211 = false
        self:ResetEnemyAttr()
        self.m_enemyList = {}
        self.m_frozenList = {}

        self:Over()

        return
    end

    return false
end

function Medium10211:ResetEnemyAttr()
    for targetID, attrParam in pairs(self.m_enemyList) do
        if attrParam then
            local target = ActorManagerInst:GetActor(targetID) 
            if target and target:IsLive() then
                local targetData = target:GetData()
                targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MOVESPEED, attrParam.chgMoveSpeed)
                targetData:AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, attrParam.chgPhyAtk)
                targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, attrParam.chgMagicAtk, false)
            end
        end
    end
end


function Medium10211:CheckReduceEnemy(isFrozen)
    local performer = self:GetOwner()
    if not performer then
        return
    end
    
    local skillCfg = self:GetSkillCfg()
    if not skillCfg then
        return
    end

    local logic = CtlBattleInst:GetLogic()
    local radius = skillCfg.dis2
    local skillLevel = self.m_skillBase:GetLevel()
    local frozenSuc = false
    local DPercent = FixDiv(self.m_skillBase:D(), 100)
    local XPercent = FixDiv(self.m_skillBase:X(), 100)
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not logic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            local targetID = tmpTarget:GetActorID()

            if not self.m_skillBase:InRange(performer, tmpTarget, nil, self.m_position) then
                local attrParam = self.m_enemyList[targetID]
                if attrParam then
                    local targetData = tmpTarget:GetData()
                    targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MOVESPEED, attrParam.chgMoveSpeed)
                    targetData:AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, attrParam.chgPhyAtk)
                    targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, attrParam.chgMagicAtk, false)

                    self.m_enemyList[targetID] = nil
                end

                return
            end

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end

            if isFrozen and not self.m_frozenList[targetID] then
                local buff = StatusFactoryInst:NewStatusFrozen(self.m_giver, self._frozenTime, {102107})
                frozenSuc = self:AddStatus(performer, tmpTarget, buff)
                if frozenSuc and skillLevel >= 2 then
                    local injure = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:Y())
                    if injure > 0 then
                        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, 1)
                        self:AddStatus(performer, tmpTarget, status)
                    end

                    self.m_frozenList[targetID] = true
                end
            end

            if self.m_enemyList[targetID] then
                return
            end
            

            local targetData = tmpTarget:GetData()
            local targetMoveSpeed = targetData:GetAttrValue(ACTOR_ATTR.BASE_MOVESPEED)
            local chgMoveSpeed = FixIntMul(targetMoveSpeed, DPercent)
            targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MOVESPEED, FixMul(chgMoveSpeed, -1))

            local targetPhyAtk = targetData:GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK)
            local chgPhyAtk = FixIntMul(targetPhyAtk, XPercent)
            targetData:AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, FixMul(chgPhyAtk, -1))

            local targetMagicAtk = targetData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK)
            local chgMagicAtk = FixIntMul(targetMagicAtk, XPercent)
            targetData:AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, FixMul(chgMagicAtk, -1), false)

            self.m_enemyList[targetID] = { 
                chgMoveSpeed = chgMoveSpeed,
                chgPhyAtk = chgPhyAtk,
                chgMagicAtk = chgMagicAtk
            }
        end
    )

    if frozenSuc then
        performer:ChgTianXiangCount(1)
    end
end

return Medium10211