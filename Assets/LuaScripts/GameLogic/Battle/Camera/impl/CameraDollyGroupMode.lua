local CameraModeBase = require("GameLogic.Battle.Camera.CameraModeBase")
local GameObject = CS.UnityEngine.GameObject
local CameraDollyGroupMode = BaseClass("CameraDollyGroupMode", CameraModeBase)
local TimelineType = TimelineType
local table_insert = table.insert
local BattleEnum = BattleEnum

function CameraDollyGroupMode:__init()
    self.dollyVCam = false
    self.m_delaytime = 0
    self.m_timelineID = false
    self.m_isPause = false
    self.m_moveSpeed = 50
    self.m_moveInterval = 0
    self.m_dollyList = {}
    self.m_waitingDollyList = {}
    self.m_timelinePath = nil
end

function CameraDollyGroupMode:Start(timelinePath, dollyImmediate)
    self.m_timelinePath = timelinePath
    self.m_timelineID = TimelineMgr:GetInstance():Play(TimelineType.BATTLE_CAMERA, timelinePath, TimelineType.PATH_BATTLE_SCENE, function (timelineGO)
        if not IsNull(timelineGO) then
            local dollyGroupCameraTrans = timelineGO.transform:Find("DollyGroupCamera")
            if not IsNull(dollyGroupCameraTrans) then
                local mainCamera = BattleCameraMgr:GetMainCamera()
                if not IsNull(mainCamera) then
                    local mainCameraTrans = mainCamera.transform
                    local rotation = Quaternion.Euler(dollyGroupCameraTrans.eulerAngles.x, mainCameraTrans.eulerAngles.y, mainCameraTrans.eulerAngles.z)
                    dollyGroupCameraTrans:SetPositionAndRotation(mainCameraTrans.position, rotation)
                end
                self.dollyVCam = dollyGroupCameraTrans:GetComponent(typeof(CS.Cinemachine.CinemachineVirtualCamera))
            end
            self:AddGroupTarget()
            self:SetCameraLookAtGroup()
        end
    end, dollyImmediate and 6 or 0)
end

function CameraDollyGroupMode:End()
    local targetGroup = BattleCameraMgr:GetTargetGroup()
    if targetGroup then
        targetGroup:RemoveAllTarget()
    end
    self:ClearCameraLookAtGroup()
    TimelineMgr:GetInstance():Release(TimelineType.BATTLE_CAMERA, self.m_timelineID)

    self.m_timelineID = false
    self.dollyVCam = false
    self.m_isPause = false
    self.m_delaytime = 0
    self.m_moveInterval = 0
    self.m_dollyList = {}
    self.m_waitingDollyList = {}
    self.m_timelinePath = nil
end

function CameraDollyGroupMode:AddGroupTarget()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if self:CanDollyActor(tmpTarget) then
                self:AddDollyTarget(tmpTarget)
            end
        end
    )
end

function CameraDollyGroupMode:CanDollyActor(actor)
    if not actor:IsLive() then
        return false
    end
    if actor:IsCalled() then
        return false
    end
    local wujiangID = actor:GetWujiangID()
    if wujiangID == 2048 or wujiangID == 2049 or wujiangID == 2037 then
        return false
    end

    local ai = actor:GetAI()
    if ai and ai:GetAiType() == BattleEnum.AITYPE_STAND_BY_DEAD_COUNT then
        return false
    end
       
    return true
end

function CameraDollyGroupMode:RemoveGroupTarget(actor)
    if not actor then
        return
    end

    local targetGroup = BattleCameraMgr:GetTargetGroup()
    if not targetGroup then
        return
    end

    self.m_dollyList[actor:GetActorID()] = nil
    targetGroup:RemoveTarget(actor:GetTransform(),1,1)
end

function CameraDollyGroupMode:SetCameraLookAtGroup()
    if not self.dollyVCam then
        return
    end
    local targetGroup = BattleCameraMgr:GetTargetGroup()
    if not targetGroup then
        return
    end

    self.dollyVCam.Follow = targetGroup.transform
end

function CameraDollyGroupMode:ClearCameraLookAtGroup()
    if not self.dollyVCam then
        return
    end

    self.dollyVCam.LookAt = nil
end

function CameraDollyGroupMode:OnActorDie(actor)
    self:RemoveGroupTarget(actor)
end

function CameraDollyGroupMode:Pause()
    self.m_isPause = true
    local timeline = TimelineMgr:GetInstance():GetTimeline(TimelineType.BATTLE_CAMERA, self.m_timelineID)
    if timeline then
        timeline:Pause()
    end

    -- if not IsNull(self.dollyVCam) then
    --     self.dollyVCam.gameObject:SetActive(false)
    -- end
end

function CameraDollyGroupMode:Resume()
    self.m_isPause = false
    local timeline = TimelineMgr:GetInstance():GetTimeline(TimelineType.BATTLE_CAMERA, self.m_timelineID)
    if timeline then
        timeline:Resume()
    end
    -- if not IsNull(self.dollyVCam) then
    --     self.dollyVCam.gameObject:SetActive(true)
    -- end
end

function CameraDollyGroupMode:CanShake()
    return true
end

-- 根据是否在相机笼罩范围，返回相机移动方向，1上移-1下移0不动
function CameraDollyGroupMode:IsInView(worldPos)
    local mainCamera = BattleCameraMgr:GetMainCamera()
    if IsNull(mainCamera) then
        return 0
    end

    local mainCameraTrans = mainCamera.transform

    local viewPos = mainCamera:WorldToViewportPoint(worldPos)
    local dir = (worldPos - mainCameraTrans.position).normalized
    local dot = Vector3.Dot(mainCameraTrans.forward, dir)     --判断物体是否在相机前面

    -- 人在相机后面，相机向上移动 （这种情况不会发生，笼罩相机会自动调整到目标上方）
    if dot <= 0 then 
        return 1
    end

    -- 太靠近中心，相机向前推进
    if viewPos.x >= 0.2 and viewPos.x <= 0.8 and viewPos.y >= 0.2 and viewPos.y <= 0.8 then
        -- print(-1, viewPos.x,viewPos.x,viewPos.y,viewPos.y)
        return -1
    end

    -- 有角色出相机范围了，相机后退
    if viewPos.x <= 0.1 or viewPos.x >= 0.9 or viewPos.y <= 0.1 or viewPos.y >= 0.9 then
        -- print(1, viewPos.x,viewPos.x,viewPos.y,viewPos.y)
        return 1
    end

    -- print(0, viewPos.x,viewPos.x,viewPos.y,viewPos.y)
    -- 正好，不用动
    return 0
end

function CameraDollyGroupMode:GetCameraMoveFactor()
    local isMoveToBack = false
    local dontNeedMove = false

    local actorMgr = ActorManagerInst
    for actorID, _ in pairs(self.m_dollyList) do
        local actor = actorMgr:GetActor(actorID)
        if actor then
            local trans = actor:GetTransform()
            if trans then
                local ret = self:IsInView(trans.position)
                if ret == 1 then -- 有人在外面就需要移动
                    isMoveToBack = true
                    break
                elseif ret == 0 then -- 有人不需要移动
                    dontNeedMove = true
                end
            end
        end
    end

    if isMoveToBack then
        return 1
    end

    if dontNeedMove then
        return 0
    end

    return -1 -- 所有人都靠近相机中心， 相机向前推进
end

function CameraDollyGroupMode:Update(deltaTime)
    if self.m_isPause then
        return
    end

    self.m_moveInterval = self.m_moveInterval + deltaTime
    if self.m_moveInterval < 0.5 then
        return
    end
    self.m_moveInterval = 0

    if IsNull(self.dollyVCam) then
        return
    end

    local timeline = TimelineMgr:GetInstance():GetTimeline(TimelineType.BATTLE_CAMERA, self.m_timelineID)
    if not timeline then
        return
    end

    local factor = self:GetCameraMoveFactor()
    if factor == 0 then
        return
    end

    self.dollyVCam:ModifyCameraDistance(deltaTime * factor * self.m_moveSpeed)
end

function CameraDollyGroupMode:OnStandbyActorFighting(actorID)
    if self.m_dollyList[actorID] then return end

    if not self.m_waitingDollyList[actorID] then
        self.m_waitingDollyList[actorID] = {delayTime = 2}
    end
end

function CameraDollyGroupMode:CheckWaitingDollyActor(deltaTime)
    local deleteList = {}
    for actorID, data in pairs(self.m_waitingDollyList) do
        local actor = ActorManagerInst:GetActor(actorID)
        if actor then
            data.delayTime = data.delayTime - deltaTime
            if data.delayTime <= 0 then
                self:AddDollyTarget(actor)
                table_insert(deleteList, actorID)    
            end
        else
            table_insert(deleteList, actorID)
        end
    end

    for _, actorID in ipairs(deleteList) do
        self.m_waitingDollyList[actorID] = nil
    end
end

function CameraDollyGroupMode:AddDollyTarget(actor)
    local targetGroup = BattleCameraMgr:GetTargetGroup()
    targetGroup:AddTarget(actor:GetTransform(),1,2)
    if not self.m_dollyList[actor:GetActorID()] then
        self.m_dollyList[actor:GetActorID()] = true
    end
    targetGroup:UpdateTransform()
end

function CameraDollyGroupMode:GetMode()
    return BattleEnum.CAMERA_MODE_DOLLY_GROUP
end

function CameraDollyGroupMode:GetRecoverParam()
    return self.m_timelinePath
end

return CameraDollyGroupMode