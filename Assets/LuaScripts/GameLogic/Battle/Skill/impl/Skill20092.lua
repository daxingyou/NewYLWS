local table_insert = table.insert
local table_remove = table.remove
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local SKILL_TYPE = SKILL_TYPE
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local StatusEnum = StatusEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20092 = BaseClass("Skill20092", SkillBase)

function Skill20092:Perform(performer, target, performPos, special_param)
    
    if not self.m_skillCfg or not performer then 
        return 
    end

    -- 随机选择3名己方角色施加祝福，令其下一次普攻得到强化，可额外造成X1%的伤害。	
    -- 随机选择3名己方角色施加祝福，令其下一次普攻得到强化，可额外造成X2%的伤害，同时清除他们身上随机1个负面状态。
    local friendsList = {}
    
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not tmpTarget then
                return
            end

            if not CtlBattleInst:GetLogic():IsFriend(performer, tmpTarget, true) then
                return
            end

            table_insert(friendsList, tmpTarget)
        end
    )

    local factory = StatusFactoryInst
    
    local skillTypeList = {
                                    {skillType = SKILL_TYPE.PHY_ATK,   leftCount = 1, hurtPercent = FixDiv(self:X(), 100)},
                                    {skillType = SKILL_TYPE.MAGIC_ATK, leftCount = 1, hurtPercent = FixDiv(self:X(), 100)}
                                  }

    for i = 1, self:A() do        
        local actor = self:RandActor(friendsList)
        if actor then
            
            local giver = StatusGiver.New(performer:GetActorID(), 20092)
            local buff = factory:NewStatusNextNHurtOtherMul(giver, skillTypeList, true)
            self:AddStatus(performer, actor, buff)
            if self.m_level == 2 then
                actor:GetStatusContainer():RandomClearOneBuff(StatusEnum.CLEARREASON_NEGATIVE)
            end
        end
    end
end

function Skill20092:RandActor(friendsList)
    if friendsList then
        local count = #friendsList
        local tmpActor = false
        if count > 0 then
            local index = FixMod(BattleRander.Rand(), count)
            index = FixAdd(index, 1)
            tmpActor = friendsList[index]
            if tmpActor then
                table_remove(friendsList, index)
                return tmpActor
            end
        end
    end
    return false
end

return Skill20092