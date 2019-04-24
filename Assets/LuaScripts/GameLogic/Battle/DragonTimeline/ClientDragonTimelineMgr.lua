local Input = CS.UnityEngine.Input
local BaseDragonTimelineMgr = require "GameLogic.Battle.DragonTimeline.BaseDragonTimelineMgr"
local ClientDragonTimelineMgr = BaseClass("ClientDragonTimelineMgr", BaseDragonTimelineMgr)

function ClientDragonTimelineMgr:__init()
    self.m_curDragon = false
end

function ClientDragonTimelineMgr:Clear()
    if self.m_curDragon then
        self.m_curDragon:Dispose()
        self.m_curDragon = nil
    end
end

function ClientDragonTimelineMgr:Play(dragonID, timelinePath, onSummonShowEnd)
    if self.m_curDragon then
        self.m_curDragon:Dispose()
        self.m_curDragon = nil
    end

    local dragonClass = self:RequireDragonClass(dragonID)
    if dragonClass then
        self.m_curDragon = dragonClass.New()
        self.m_curDragon:Start(timelinePath, onSummonShowEnd)
    end
end

function ClientDragonTimelineMgr:RequireDragonClass(dragonID)
    if dragonID == 3601 then
        return require("GameLogic.Battle.DragonTimeline.impl.DragonTimeline3601")
    elseif dragonID == 3606 then
        return require("GameLogic.Battle.DragonTimeline.impl.DragonTimeline3606")
    elseif dragonID == 3602 then
        return require("GameLogic.Battle.DragonTimeline.impl.DragonTimeline3602")
    elseif dragonID == 3603 then
        return require("GameLogic.Battle.DragonTimeline.impl.DragonTimeline3603")
    end
end

function ClientDragonTimelineMgr:Update()
    if not self.m_curDragon then
        return
    end
    
    if self.m_curDragon:IsOver() then
        self.m_curDragon:Dispose()
        self.m_curDragon = false
    end

    if Input.anyKeyDown and self.m_curDragon:CanSkip() then
        self.m_curDragon:Dispose()
        self.m_curDragon = false
    end
end

function ClientDragonTimelineMgr:IsCurSummonEnd()
    if not self.m_curDragon then
        return false
    end 
    return self.m_curDragon:IsOver()
end

return ClientDragonTimelineMgr