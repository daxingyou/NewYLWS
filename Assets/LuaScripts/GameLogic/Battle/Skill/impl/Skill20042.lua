local StatusGiver = StatusGiver
local FixMul = FixMath.mul
local FixMod = FixMath.mod
local Formular = Formular
local FixAdd = FixMath.add
local AtkRoundJudge = Formular.AtkRoundJudge
local BattleEnum = BattleEnum
local CtlBattleInst = CtlBattleInst
local SkillUtil = SkillUtil
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local table_insert = table.insert

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20042 = BaseClass("Skill20042", SkillBase)

function Skill20042:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end
    
    local enemyList = {}

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not tmpTarget:IsLive() then
                return
            end

            if not CtlBattleInst:GetLogic():IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not self:InRange(performer, tmpTarget, nil, performPos) then
                return
            end

            table_insert(enemyList, tmpTarget:GetActorID())
        end
    )

    local actorID = self:RandActorID(enemyList)
    local target = ActorManagerInst:GetActor(actorID)
    if target and target:IsLive() then
        target:AddEffect(200404)

        local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
        if Formular.IsJudgeEnd(judge) then
            return  
        end

        local injure = Formular.CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self:X())
        if injure > 0 then
            local giver = StatusGiver.New(performer:GetActorID(), 20042)
            local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                judge, special_param.keyFrameTimes)
            self:AddStatus(performer, target, status)
        end
    end
end

function Skill20042:RandActorID(enemyList)
    if enemyList then
        local count = #enemyList
        if count > 0 then
            local index = FixMod(BattleRander.Rand(), count)
            index = FixAdd(index, 1)

            local tmpActorID = enemyList[index]
            return tmpActorID
        end
    end
    return 0
end


return Skill20042