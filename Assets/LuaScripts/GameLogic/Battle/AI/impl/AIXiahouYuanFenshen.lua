local ActorManagerInst = ActorManagerInst
local FixSub = FixMath.sub
local table_insert = table.insert
local table_remove = table.remove

local AIManual = require "GameLogic.Battle.AI.AIManual"
local AIXiahouYuanFenshen = BaseClass("AIXiahouYuanFenshen", AIManual)


function AIXiahouYuanFenshen:__init(actor)
    self.m_skillList = {}
    self.m_intervalTime = 500
end

function AIXiahouYuanFenshen:__delete()
    self.m_skillList = {}
    self.m_intervalTime = 0
end

function AIXiahouYuanFenshen:AI(deltaMS)
    if not self:CheckSpecialState(deltaMS) then
        return
    end

    if not self:CanAI() then
        return
    end

    if #self.m_skillList > 0 then
        self.m_intervalTime = FixSub(self.m_intervalTime, deltaMS)
        if self.m_intervalTime > 0 then
            return
        end
        self.m_intervalTime = 500

        local skillItem = self.m_skillList[1].skillItem
        local targetID = self.m_skillList[1].curTargetID
        local target = ActorManagerInst:GetActor(targetID)
        if target and target:IsLive() then
            self:SetTarget(targetID)
            self:PerformSkill(target, skillItem, target:GetPosition(), SKILL_PERFORM_MODE.AI)
        end

        table_remove(self.m_skillList, 1)
    end
end


function AIXiahouYuanFenshen:PerformSkillDelay(skillItem, targetID)
    table_insert(self.m_skillList, {curTargetID = targetID, skillItem = skillItem})
end


return AIXiahouYuanFenshen