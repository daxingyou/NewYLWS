local Vector3 = Vector3
local Vector2 = Vector2
local Quaternion = CS.UnityEngine.Quaternion
local BattleEnum = BattleEnum
local Time = Time
local sin = math.sin
local FixSub = FixMath.sub
local Input = CS.UnityEngine.Input
local TouchPhase = CS.UnityEngine.TouchPhase
local ScreenPos2TerrainPos = CS.GameUtility.ScreenPos2TerrainPos
local GameUtility = CS.GameUtility
local FixNewVector3 = FixMath.NewFixVector3
local ActorManagerInst = ActorManagerInst

local BaseSkillInputMgr = require "GameLogic.Battle.Input.BaseSkillInputMgr"
local ClientSkillInputMgr = BaseClass("SkillInputMgr", BaseSkillInputMgr)
local base = BaseSkillInputMgr

function ClientSkillInputMgr:__init()
    self.UPDATE_INTERVAL = 0.2
    self.m_lastUpdateTime = 0
    self.m_lastPos = Vector3.zero
    self.m_candidateTargets = {}
    self.m_targets = {}
    self.m_originPerformerForward = false       -- fixv3
    self.m_isActive = false
    self.m_isInputing = false
    self.m_autoMove = false
    self.m_autoPosStart = Vector3.zero
    self.m_autoPosEnd = Vector3.zero
    self.m_skillSelector = false
end

function ClientSkillInputMgr:__delete()
    if self.m_skillSelector then
        self.m_skillSelector:Delete()
        self.m_skillSelector = nil
    end

    self.m_candidateTargets = nil
    self.m_targets = nil
end

function ClientSkillInputMgr:Active(performer, skillBase)

    base.Active(self, performer, skillBase)

    -- showui UI_BATTLE_SELECTOR_TARGET  todo
   
    self:DoActive(performer, skillBase)

    self:CreateSkillSelector()

    if self.m_performer then
        -- self.m_autoMove = true
        local x, y, z = self.m_performer:GetPosition():GetXYZ()
        local fx, fy, fz = self.m_performer:GetForward():GetXYZ()
        local tmpPos = Vector3.New(x, y, z)
        local tmpPos2 = Vector3.New(fx, fy, fz)
        self.m_autoPosStart = tmpPos + GameUtility.RotateAroundY(tmpPos2 , -25) * 5
        self.m_autoPosEnd = tmpPos + GameUtility.RotateAroundY(tmpPos2 , 25) * 5

        -- showui UI_PLOT_DRAG_POINTER  todo
    else
        self.m_autoMove = false
    end

    self.m_lastUpdateTime = Time.realtimeSinceStartup

    if self.m_performer then
        self.m_originPerformerForward = self.m_performer:GetForward():Clone()
    end

    local cameraFX = CtlBattleInst:GetSkillCameraFX()
    if cameraFX then
        cameraFX:PlayWaitForInputFX(self.m_skillSelector, self.m_performer, self.m_candidateTargets)
    end

    self.m_isActive = true
    SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.SKILL_INPUT_ACTIVE)
end

function ClientSkillInputMgr:CreateSkillSelector()
    if not self.m_skillSelector then
        local selectorClass = require("GameLogic.Battle.Input.SkillSelector")
        self.m_skillSelector = selectorClass.New(self)
    end
end

function ClientSkillInputMgr:DoActive(performer, skillBase)
end

function ClientSkillInputMgr:Deactive(deactiveReason)

    if deactiveReason == BattleEnum.SKILL_INPUT_DEACTIVE_CANCEL then
        if not self:Cancelable() then
            -- todo show UI
            return
        end
    end

    base.Deactive(self, deactiveReason)

    -- to do 各种表现  UI_BATTLE_SELECTOR_TARGET

    
    ActorManagerInst:Walk(
        function(tmpTarget)
            tmpTarget:HideSelected()
        end
    )

    if self.m_skillSelector then
        self.m_skillSelector:Reset()
    end    

    local cameraFX = CtlBattleInst:GetSkillCameraFX()
    local sourceActorID = -1
    if self.m_performer then
        sourceActorID = self.m_performer:GetActorID()
    end

    if deactiveReason == BattleEnum.SKILL_INPUT_DEACTIVE_RELEASE then
        if self:HasPerformCameraFX() then
            if cameraFX then
                cameraFX:PlayPerformPrepareFX(self.m_performer)
            end
        else
            if cameraFX then
                cameraFX:Stop(sourceActorID)
            end
        end
    else
        if self.m_performer and self.m_originPerformerForward then
            self.m_performer:SetForwardOnlyShow(Vector3.New(self.m_originPerformerForward.x, self.m_originPerformerForward.y, self.m_originPerformerForward.z))
        end
            
        if cameraFX then
            cameraFX:Stop(sourceActorID)
        end
    end
   
    self:Reset()
    SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.SKILL_INPUT_DEACTIVE)
end

function ClientSkillInputMgr:HasPerformCameraFX()
    return false
end

function ClientSkillInputMgr:Reset()

    base.Reset(self)

    self.m_lastUpdateTime = 0
    self.m_lastPos = Vector3.zero
    self.m_candidateTargets = {}
    self.m_targets = {}
    self.m_originPerformerForward = false       
    self.m_isActive = false
    self.m_isInputing = false
    self.m_autoMove = false
    self.m_autoPosStart = Vector3.zero
    self.m_autoPosEnd = Vector3.zero
end

function ClientSkillInputMgr:UpdateTargets()
    return false
end

function ClientSkillInputMgr:Update()
    if self.m_isActive then
        -- if self.m_autoMove and not self.m_isInputing then
        if not self.m_isInputing then
            -- self.m_lastPos = self.m_autoPosStart + (self.m_autoPosEnd - self.m_autoPosStart) * (sin(Time.realtimeSinceStartup) + 1) / 2 * 1.5
            self.m_lastPos = self.m_autoPosStart
            -- MN_BATTLE_INPUT_POS todo
            self:UpdatePerformerForward()
    
            if self.m_skillSelector then
                self.m_skillSelector:UpdateSkillSelector(self.m_lastPos)
            end
            
            local cameraFX = CtlBattleInst:GetSkillCameraFX()
            if cameraFX then
                cameraFX:PlaySelectTargetFX(self.m_skillSelector, self.m_performer, self.m_candidateTargets, self.m_targets)
            end
        end

        if Time.realtimeSinceStartup - self.m_lastUpdateTime > self.UPDATE_INTERVAL then
            if self.m_skillSelector then
                ActorManagerInst:Walk(
                    function(tmpTarget)
                        tmpTarget:HideSelected()
                    end
                )

                local tmpList = {}
                for _, tmpTarget in ipairs(self.m_targets) do
                    tmpList[tmpTarget:GetActorID()] = true
                end

                local succ = self:UpdateTargets()

                for _, tmpTarget in ipairs(self.m_targets) do
                    tmpTarget:ShowSelected()
                end

                if succ then
                    self.m_skillSelector:SetPower(2)
                else
                    self.m_skillSelector:SetPower(1)
                end

                for _, tmpTarget in ipairs(self.m_targets) do
                    if not tmpList[tmpTarget:GetActorID()] then
                        tmpTarget:PunchScale()
                    end
                end

                self.m_lastUpdateTime = Time.realtimeSinceStartup
            end
        end

        if self.m_skillSelector then
            -- MN_BATTLE_INPUT_TARGET todo
            end
        
        self:UpdateTouch()
    end
end


function ClientSkillInputMgr:UpdatePerformerForward()
    if self.m_performer then
        local dest = self.m_lastPos:Clone()
        dest.y = self.m_performer:GetPosition().y
        self.m_performer:LookatOnlyShow(dest)
    end
end

function ClientSkillInputMgr:UpdateTouch()
    
    if Input.touchSupported then
        if Input.touchCount == 1 then
            local touch = Input.GetTouch(0)
            local phase = touch.phase            

            local phase_str = tostring(phase)
            if phase_str == 'Began: 0' then                
                self:OnTouchStart(touch.position)

            elseif phase_str == 'Moved: 1' or phase_str == 'Stationary: 2' then
                self:OnSwipe(touch.position)

            elseif phase_str == 'Ended: 3' or phase_str == 'Canceled: 4' then        
                self:OnTouchUp(touch.position)
            end
            
        elseif Input.touchCount > 1 then
            self:On2Fingers()
        end
    else
        if Input.GetMouseButtonDown(0) then
            self:OnTouchStart(Vector2.New(Input.mousePosition.x, Input.mousePosition.y))
        elseif Input.GetMouseButton(0) then
            self:OnSwipe(Vector2.New(Input.mousePosition.x, Input.mousePosition.y))
        elseif Input.GetMouseButtonUp(0) then
            self:OnTouchUp(Vector2.New(Input.mousePosition.x, Input.mousePosition.y))
        end
    end
end

function ClientSkillInputMgr:OnTouchStart(v2Pos)
    self.m_isInputing = true

    -- closeui UI_PLOT_DRAG_POINTER  todo

    local terrainPos = self:ScreenPosToTerrainPos(v2Pos)
    if terrainPos then
        self.m_lastPos = Vector3.New(terrainPos.x,terrainPos.y,terrainPos.z)
        self:UpdatePerformerForward()
    end

    if self.m_skillSelector then
        self.m_skillSelector:UpdateSkillSelector(self.m_lastPos)
        self:UpdateTargets()
    end

    local cameraFX = CtlBattleInst:GetSkillCameraFX()
    if cameraFX then
        cameraFX:PlaySelectTargetFX(self.m_skillSelector, self.m_performer, self.m_candidateTargets, self.m_targets)
    end
end

function ClientSkillInputMgr:OnSwipe(v2Pos)
    self.m_isInputing = true

    local terrainPos = self:ScreenPosToTerrainPos(v2Pos)
    if terrainPos then
        self.m_lastPos = Vector3.New(terrainPos.x,terrainPos.y,terrainPos.z)
        self:UpdatePerformerForward()
    end

    if self.m_skillSelector then
        self.m_skillSelector:UpdateSkillSelector(self.m_lastPos)
    end
    
    local cameraFX = CtlBattleInst:GetSkillCameraFX()
    if cameraFX then
        cameraFX:PlaySelectTargetFX(self.m_skillSelector, self.m_performer, self.m_candidateTargets, self.m_targets)
    end
end

function ClientSkillInputMgr:OnTouchUp(v2Pos)
    if not self.m_isInputing then
        return
    end

    self.m_isInputing = false
    
    local terrainPos = self:ScreenPosToTerrainPos(v2Pos)
    if terrainPos then
        self.m_lastPos = Vector3.New(terrainPos.x, terrainPos.y, terrainPos.z)
        self:UpdatePerformerForward()
    end

    local cameraFX = CtlBattleInst:GetSkillCameraFX()
    if cameraFX then 
        cameraFX:PlaySelectTargetFX(self.m_skillSelector, self.m_performer, self.m_candidateTargets, self.m_targets)
    end

    local target = nil
    local performPos = nil

    if self.m_skillSelector then
        self.m_skillSelector:UpdateSkillSelector(self.m_lastPos)
        local v3Pos = self.m_skillSelector:GetSkillReallyPos()
        performPos = FixNewVector3(v3Pos.x, v3Pos.y, v3Pos.z)
        target = self.m_skillSelector:SkillReallySingleTarget()

        if self.m_skillSelector and self.m_skillSelector:GetSkillRangeType() == SKILL_RANGE_TYPE.SINGLE_TARGET then
            UIManagerInst:Broadcast(UIMessageNames.MN_BATTLE_SHOW_SELECTOR_TARGET, false)
        end
    end
    
    local ret, tmpList = self.m_skillBase:GetTargetList(self.m_performer, performPos, target) 
    if ret ~= SKILL_CHK_RESULT.OK then  
        self:InputDeactiveCancel()
        return
    end

    local performerID = self.m_performer and self.m_performer:GetActorID() or 0
    local targetID = target and target:GetActorID() or 0
    self:Deactive(BattleEnum.SKILL_INPUT_DEACTIVE_RELEASE)
    
    BattleCameraMgr:SetCinemachineBrainActive(true)
    FrameCmdFactory:GetInstance():ProductCommand(BattleEnum.FRAME_CMD_TYPE_SKILL_INPUT_END, performPos, performerID, targetID)
    CtlBattleInst:FrameResume()
end

function ClientSkillInputMgr:On2Fingers()
    self:InputDeactiveCancel()
end

function ClientSkillInputMgr:InputDeactiveCancel()
    self.m_isInputing = false
    self:Deactive(BattleEnum.SKILL_INPUT_DEACTIVE_CANCEL)
    CtlBattleInst:FrameResume()
end

-- in : vector2,   return : vector3
function ClientSkillInputMgr:ScreenPosToTerrainPos(posV2)
    local v3 = ScreenPos2TerrainPos(posV2, BattleEnum.MASK_MAP_TERRAIN)
    if not v3 or v3.y < -500 then
        return nil
    else
        return v3
    end
end

return ClientSkillInputMgr