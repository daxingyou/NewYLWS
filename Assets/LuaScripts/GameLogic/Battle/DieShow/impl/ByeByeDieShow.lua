local FixNewVector3 = FixMath.NewFixVector3
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local FixVetor3RotateAroundY = FixMath.Vector3RotateAroundY
local FixNormalize = FixMath.Vector3Normalize
local ScreenPointToLocalPointInRectangle = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle
local UIWindowNames = UIWindowNames
local Vector3 = Vector3
local Vector3_Get = Vector3.Get
local Vector2 = Vector2
local ActorManagerInst = ActorManagerInst

local base = require "GameLogic.Battle.DieShow.impl.NormalDieShow"
local ByeByeDieShow = BaseClass("ByeByeDieShow", base)

function ByeByeDieShow:__init()
    self.m_totalS = 0
end

function ByeByeDieShow:__delete()
end

function ByeByeDieShow:Start(...)
    self.m_totalS = 5
    
    local anim, deadmode, actorid = ...
    
    self:InitFakeActor(actorid)

    -- self:SayGoodbye()
end


function ByeByeDieShow:InitFakeActor(actorID)
    base.InitFakeActor(self, actorID)
    
    local actor = ActorManagerInst:GetActor(actorID)
    if actor then
        local DieShowActorClass = require "GameLogic.Battle.Actors.impl.DieShowActor"
        self.m_fakeActor = DieShowActorClass.New()
        self.m_fakeActor:SetActorID(actor:GetActorID())
        self.m_fakeActor:SetWujiangID(actor:GetWujiangID())
        self.m_fakeActor:SetWuqiLevel(actor:GetWuqiLevel())
        self.m_fakeActor:SetPosition(actor:GetPosition())
        self.m_fakeActor:SetSkillContainer(actor:GetSkillContainer())
        self.m_fakeActor:SetFightData(actor:GetData())
        self.m_fakeActor:SetCamp(actor:GetCamp())
        self.m_fakeActor:SetLineupPos(actor:GetLineupPos())
        self.m_fakeActor:SetForward(actor:GetForward())
        local comp = actor:GetComponent()
        if comp then
            self.m_fakeActor:SetComponent(comp)
            comp:SetActor(self.m_fakeActor)
        else
            Logger.Log(' actorID no comp ' .. actorID)
        end
    else
        
    end
end

function ByeByeDieShow:Update(deltaTime)
    if self.m_isPause then
        return
    end

    if self:IsOver() then
        return
    end
    
    self.m_totalS = self.m_totalS - deltaTime

    if self.m_totalS <= 0 then
        self.m_isOver = true
        
        return
    end
end

return ByeByeDieShow