local BattleEnum = BattleEnum
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local random = math.random
local table_insert = table.insert
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local FixIntMul = FixMath.muli
local FixFloor = FixMath.floor
local FixMod = FixMath.mod
local FixRand = BattleRander.Rand

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill35061 = BaseClass("Skill35061", SkillBase)

function Skill35061:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end

    --玄武停止攻击，冰冻场上一半的敌人{A}秒（向下取整，包括召唤物），同时获得{x1}（+{E}%法攻)点护盾，{B}秒后护盾值将被转化为生命值（不超过最大生命值）。
    --如果护盾被提前击破，玄武和被冰冻的敌人都会恢复正常攻击状态。

    local factory = StatusFactoryInst
    local statusGiverNew = StatusGiver.New
    local battleLogic = CtlBattleInst:GetLogic()
    local giver = statusGiverNew(performer:GetActorID(), 35061)

    local enemyCount = 0
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end
            enemyCount = FixAdd(enemyCount, 1)
        end
    )
    local frozenList = {}
    
    for i = 1, FixFloor(FixDiv(enemyCount, 2)) do
        self:SelectRandActor(performer, frozenList)
    end

    local shieldValue = Formular.CalcRecover(BattleEnum.HURTTYPE_MAGIC_HURT, performer, performer, self.m_skillCfg, self:X())
    local buff = factory:NewStatusXuanWuAllTimeShield(giver, shieldValue, FixIntMul(self:B(), 1000), frozenList, FixIntMul(self:A(), 1000), {350603})
    self:AddStatus(performer, performer, buff)

end

function Skill35061:SelectRandActor(actor, list)
    local copyActorList = {}

    local battleLogic = CtlBattleInst:GetLogic()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(actor, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end
            local targetID = tmpTarget:GetActorID()
            if list[targetID] then
                return
            end

            table_insert(copyActorList, tmpTarget:GetActorID())
        end
    )
    
    local count = #copyActorList
    local tmpActorID = false
    if count > 0 then
        local index = FixMod(FixRand(), count)
        index = FixAdd(index, 1)
        tmpActorID = copyActorList[index]
        if tmpActorID then
            list[tmpActorID] = true
            return tmpActorID
        end
    end

    return false
end

return Skill35061