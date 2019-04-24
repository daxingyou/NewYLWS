local StatusGiver = StatusGiver
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local FixDiv = FixMath.div
local IsInCircle = SkillRangeHelper.IsInCircle
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local BattleEnum = BattleEnum
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10222 = BaseClass("Skill10222", SkillBase)

function Skill10222:Perform(performer, target, performPos, special_param)
    if not self.m_skillCfg or not performer or not performer:IsLive() then 
        return 
    end
    -- 风卷残云
    -- 1-2
    -- 郭嘉选择A米内法防最低的B个敌人，在他们身上各召唤一道罡风，造成x1%的法术伤害，并将其推后C米。
    -- 3-5
    -- 郭嘉选择A米内法防最低的B个敌人，在他们身上各召唤一道罡风，造成x3%的法术伤害，并将其推后C米。
    -- 如果施放风卷残云时郭嘉处于风雷翅状态，则技能伤害变为范围伤害。
    -- 6
    -- 郭嘉选择A米内法防最低的B个敌人，在他们身上各召唤一道罡风，造成x6%的法术伤害，并将其推后C米。
    -- 如果施放风卷残云时郭嘉处于风雷翅状态，则技能伤害变为范围伤害。
    -- 在单场战斗中，郭嘉前3次施放风卷残云可令受到伤害的敌人的命中下降y6%，持续D秒。

    local targetIDList = {}
    local battleLogic = CtlBattleInst:GetLogic()
    local radius = self:A()
    local performerPos = performer:GetPosition()
    local enemyCount = self:B()
    for i=1,enemyCount do
        local minMagicDef = 99999999
        local minMagicDefTarget = nil
        ActorManagerInst:Walk(
            function(tmpTarget)
                if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                    return
                end

                if tmpTarget:GetAI() == BattleEnum.AITYPE_STAND_BY_DEAD_COUNT then
                    return
                end

                local tmpTargetID = tmpTarget:GetActorID()
                if targetIDList[tmpTargetID] then
                    return
                end

                local magicDef = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAGIC_DEF)
                if magicDef < minMagicDef then
                    minMagicDef = magicDef
                    minMagicDefTarget = tmpTarget
                end
            end
        )

        if minMagicDefTarget then
            local fengleichi = performer:GetStatusContainer():GetGuojiaFengleichi()
            if fengleichi then
                minMagicDefTarget:AddEffect(102210)
            else
                minMagicDefTarget:AddEffect(102209)
            end
            
            targetIDList[minMagicDefTarget:GetActorID()] = true
            local judge = Formular.AtkRoundJudge(performer, minMagicDefTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end
        
            local injure = Formular.CalcInjure(performer, minMagicDefTarget, self.m_skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self:X())
            if injure > 0 then 
                local giver = StatusGiver.New(performer:GetActorID(), 10222)  
                local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                    judge, special_param.keyFrameTimes)
                self:AddStatus(performer, minMagicDefTarget, status)

                minMagicDefTarget:OnBeatBack(performer, self:C())

                if self.m_level >= 3 then
                    local fengleichi = performer:GetStatusContainer():GetGuojiaFengleichi()
                    if fengleichi then
                        performer:ActiveFengleichiEffect(minMagicDefTarget, fengleichi:GetRadius(), FixMul(injure, fengleichi:GetHurtPercent()))
                    end
                end

                if self.m_level >= 6 and performer:GetPerform10222Count() <= 3 then
                    local giver = StatusGiver.New(performer:GetActorID(), 10222)  
                    local buff = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:D(), 1000))
                    buff:AddAttrPair(ACTOR_ATTR.MINGZHONG_PROB_CHG, FixDiv(self:Y(), -100))
                    buff:SetMergeRule(StatusEnum.MERGERULE_MERGE)
                    self:AddStatus(performer, minMagicDefTarget, buff)
                end
            end
        end
    end

    targetIDList = {}
end

return Skill10222