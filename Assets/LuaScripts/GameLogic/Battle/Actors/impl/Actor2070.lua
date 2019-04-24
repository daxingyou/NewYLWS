local FixAdd = FixMath.add
local ActorManagerInst = ActorManagerInst

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor2070 = BaseClass("Actor2070", Actor)

function Actor2070:__init()
    self.m_shuiyaoIDList = {}
    self.m_shuiyaoCount = 0
    self.m_callCount = 0
    self.m_canCall = true
end


function Actor2070:AddShuiyaoTargetID(targetID)
    if not self.m_shuiyaoIDList[targetID] then
        self.m_shuiyaoIDList[targetID] = true

        self.m_shuiyaoCount = FixAdd(self.m_shuiyaoCount, 1)
    end
end

function Actor2070:LogicOnFightEnd()
    self.m_canCall = false
end

function Actor2070:CanCall()
    return self.m_canCall
end

function Actor2070:LogicOnFightStart(currWave)
    self.m_canCall = true
end


function Actor2070:GetCallCount()
    return self.m_callCount
end


function Actor2070:AddCallCount()
    self.m_callCount = FixAdd(self.m_callCount, 1)
end


function Actor2070:GetCurShuiyaoCount()
    return self.m_shuiyaoCount
end


function Actor2070:ShuiyaoPerformJL(shuiyaoTargetID)
    for targetID,_ in pairs(self.m_shuiyaoIDList) do
        local shuiyaoActor = ActorManagerInst:GetActor(targetID)
        if shuiyaoActor and shuiyaoActor:IsLive() then
            local shuiyaoAI = shuiyaoActor:GetAI()
            if shuiyaoAI then
                shuiyaoAI:PerformJL(shuiyaoTargetID)
            end
        else
            self.m_shuiyaoIDList[targetID] = false
        end
    end
end


return Actor2070