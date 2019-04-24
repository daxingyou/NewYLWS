local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local ActorManagerInst = ActorManagerInst
local BattleEnum = BattleEnum
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium2088Atk = BaseClass("Medium2088Atk", LinearFlyToTargetMedium)
 

function Medium2088Atk:ArriveDest()
    self:Hurt()
end
--1-3
--蒋干的普通攻击命中目标时可偷取其{x1}%的物攻与法攻，对每个敌人最多可偷取{A}次
--4
--蒋干的普通攻击命中目标时可偷取其{x4}%的物攻与法攻，对每个敌人最多可偷取{A}次。蒋干该技能命中敌人时，
--若该敌人被蒋干偷取过攻击，则额外对其造成{y4}%的法术伤害

function Medium2088Atk:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local skillcfg = self:GetSkillCfg()
    if not skillcfg then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return
    end

    local injure = Formular.CalcInjure(performer, target, skillcfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:X())
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)
        
        local targetID = target:GetActorID()
        local isStealed = performer:GetStealedTarget(targetID)
        if isStealed then 
            local magic20883Y = performer:Get20883Y()
            if magic20883Y > 0 then
                local statusHp = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(magic20883Y, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                judge, self.m_param.keyFrame)

                self:AddStatus(performer, target, statusHp)
            end
        end

        if performer:Get2088StealAtkCount(targetID) < performer:Get20883A() then 
            local reducePercent = performer:Get20883X()
            local curPhyAtk = target:GetData():GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK)
            local chgPhyAtk = FixIntMul(curPhyAtk, reducePercent)
            local curMagicAtk = target:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK)
            local chgMagicAtk = FixIntMul(curMagicAtk, reducePercent)

            target:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, FixMul(chgPhyAtk, -1))
            target:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, FixMul(chgMagicAtk, -1))
            
            performer:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, chgPhyAtk)
            performer:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, chgMagicAtk, false)
            
            performer:Add2088StealAtkCount(targetID) 
            performer:AddStealedTarget(targetID)
        end 
    end
end


return Medium2088Atk