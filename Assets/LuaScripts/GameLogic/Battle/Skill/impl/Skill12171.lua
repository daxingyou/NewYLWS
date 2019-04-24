local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local FixFloor = FixMath.floor
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local FixIntMul = FixMath.muli
local IsInCircle = SkillRangeHelper.IsInCircle
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill12171 = BaseClass("Skill12171", SkillBase)

function Skill12171:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() or not target or not target:IsLive() then
        return
    end

    -- 不动如山 1
    -- 鲁肃选中1位己方武将，令其获得{x1}%的伤害减免，持续{A}秒；被选中的武将会嘲讽他周围{C}米内的敌方单位{B}秒。
    -- 2-3
    -- 鲁肃选中1位己方武将，令其获得{x2}%的伤害减免，鲁肃每有100点法攻额外增加{D}%的伤害减免，持续{A}秒；
    -- 被选中的武将会嘲讽他周围{C}米内的敌方单位{B}秒。
    -- 4-6
    -- 鲁肃选中1位己方武将，令其获得{x4}%的伤害减免，鲁肃每有100点法攻额外增加{D}%的伤害减免，持续{A}秒；
    -- 被选中的武将会嘲讽他周围{C}米内的敌方单位{B}秒，嘲讽每命中1个敌方单位，提升自身{y4}点物理防御和法术防御。

    local factory = StatusFactoryInst
    local StatusGiverNew = StatusGiver.New
    
    local hurtReducePercent = FixDiv(self:X(), 100)
    if self.m_level >= 2 then
        local magicAtk = performer:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAGIC_ATK)
        if magicAtk > 100 then
            local chgOtherMul = FixFloor(FixDiv(magicAtk, 100))
            chgOtherMul = FixMul(self:D(), FixDiv(chgOtherMul, 100))
            hurtReducePercent = FixAdd(hurtReducePercent, chgOtherMul)
        end
    end

    -- 鲁肃大招的减免上限合计最高为70%，由于没有空余参数了，写死即可  合计是指X值的减免加上每有100法攻就增加的减免。 
    if hurtReducePercent > 0.7 then
        hurtReducePercent = 0.7
    end

    local giver = StatusGiverNew(performer:GetActorID(), 12171) 
    local statusNTimeBeHurtChg = factory:NewStatusNTimeBeHurtMul(giver, FixIntMul(self:A(), 1000), FixSub(1, hurtReducePercent), {21016,121703})
    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_PHY_HURT)
    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_MAGIC_HURT)
    statusNTimeBeHurtChg:AddBeHurtMulType(BattleEnum.HURTTYPE_REAL_HURT)
    self:AddStatus(performer, target, statusNTimeBeHurtChg)

    local targetPos = target:GetPosition()
    local targetID = target:GetActorID()
    local radius = self:C()
    local time = FixIntMul(self:B(), 1000)
    local chaoFengCount = 0
    local battleLogic = CtlBattleInst:GetLogic()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(target, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInCircle(targetPos, radius, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end

            local giver = StatusGiverNew(performer:GetActorID(), 12171)
            local statusChaofeng = factory:NewStatusChaoFeng(giver, targetID, time)
            local addSuc = self:AddStatus(performer, tmpTarget, statusChaofeng)
            if addSuc and self.m_level >= 4 then
                chaoFengCount = FixAdd(chaoFengCount, 1)
            end
        end
    )

    if chaoFengCount > 0 and self.m_level >= 4 then
        local attrPercent = FixDiv(self:Y(), 100)
        attrPercent = FixMul(chaoFengCount, attrPercent)
        local chgPhyDef = target:CalcAttrChgValue(ACTOR_ATTR.BASE_PHY_DEF, attrPercent)
        local chgMagicDef = target:CalcAttrChgValue(ACTOR_ATTR.BASE_MAGIC_DEF, attrPercent)
        local giver = StatusGiverNew(performer:GetActorID(), 12171)
        local attrBuff = factory:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:A(), 1000))
        attrBuff:AddAttrPair(ACTOR_ATTR.FIGHT_PHY_DEF, chgPhyDef)
        attrBuff:AddAttrPair(ACTOR_ATTR.FIGHT_MAGIC_DEF, chgMagicDef)
        self:AddStatus(performer, target, attrBuff)
    end
end

function Skill12171:SelectSkillTarget(performer, target)
    if CtlBattleInst:GetLogic():IsAutoFight() then
        local minTarget = nil
        local minHPPercent = 1.1

        local battleLogic = CtlBattleInst:GetLogic()
        ActorManagerInst:Walk(
            function(tmpTarget)
                if not battleLogic:IsFriend(performer, tmpTarget, true) then
                    return
                end

                local targetData = tmpTarget:GetData()
                local tmpHp = targetData:GetAttrValue(ACTOR_ATTR.FIGHT_HP)
                local maxHp = targetData:GetAttrValue(ACTOR_ATTR.BASE_MAXHP)
                local hpPercent = FixDiv(tmpHp, maxHp)
                if hpPercent < minHPPercent then
                    minTarget = tmpTarget
                    minHPPercent = hpPercent
                end
            end
        )

        if minTarget and minTarget:IsLive() then
            return minTarget, minTarget:GetPosition()
        end
    end

    return nil, nil
end

return Skill12171