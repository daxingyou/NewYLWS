local GameObject = CS.UnityEngine.GameObject
local Vector3 = Vector3
local BattleEnum = BattleEnum
local GameUtility = CS.GameUtility

local MediumComponent = BaseClass("MediumComponent")

function MediumComponent:__init()
    self.m_gameObject = nil
    self.m_transform = nil
    self.m_medium = false
    self.m_position = Vector3.New(1, 0, 0)
    self.m_forward = Vector3.New(1, 0, 0)

    self.m_particleSystemList = nil
    self.m_animatorList = nil

    self.m_audioKey = -1
end

function MediumComponent:__delete()

    self:RecycleObj()
    self:RemoveAudio()

    self.m_gameObject = nil
    self.m_transform = nil
    self.m_medium = false
    self.m_particleSystemList = nil
    self.m_animatorList = nil
end

function MediumComponent:RecycleObj()
    
    if self.m_medium and not IsNull(self.m_gameObject) then
        local mediumID = self.m_medium:GetMediumID()
        local objectCfg = ConfigUtil.GetObjectCfgByID(mediumID)
        if objectCfg then
            local res_path = PreloadHelper.GetObjectPath(objectCfg)
            GameObjectPoolInst:RecycleGameObject(res_path, self.m_gameObject)
        end
    end
end

function MediumComponent:OnBorn(medium_go, medium)
    self.m_gameObject = medium_go
    self.m_transform = medium_go.transform
    self.m_medium = medium

    local x, y, z = medium:GetPosition():GetXYZ()
    local fx, fy, fz = medium:GetForward():GetXYZ()

    GameUtility.SetLocalPosition(self.m_transform, x, y, z)
    GameUtility.SetForward(self.m_transform, fx, fy, fz)

    -- self.m_gameObject.name = medium:GetID()

    self.m_particleSystemList = medium_go:GetComponentsInChildren(typeof(CS.UnityEngine.ParticleSystem))
    self.m_animatorList = medium_go:GetComponentsInChildren(typeof(CS.UnityEngine.Animator))
    
    self:PlayAudio()

    self.m_medium:RegisterComponent(self) 
end

function MediumComponent:PlayAudio()
    --todo 
    if self.m_medium then
        local objectCfg = ConfigUtil.GetObjectCfgByID(self.m_medium:GetMediumID())
        if objectCfg and objectCfg.audio > 0 then
            self.m_audioKey = AudioMgr:PlayAudio(objectCfg.audio, self.m_gameObject);
        end
    end
end

function MediumComponent:RemoveAudio()
    if self.m_audioKey > 0 then
        AudioMgr:RemoveAudio(self.m_audioKey)
        self.m_audioKey = -1
    end
end

function MediumComponent:Pause(reason)
    if self.m_particleSystemList then
        for i = 0, self.m_particleSystemList.Length - 1 do
            local v = self.m_particleSystemList[i]
            if v then
                v:Pause()
            end
        end
    end

    if self.m_animatorList then
        for i = 0, self.m_animatorList.Length - 1 do
            local v = self.m_animatorList[i]
            if v then
                v.speed = 0
            end
        end
    end
end

function MediumComponent:Resume(reason)
    if self.m_particleSystemList then
        for i = 0, self.m_particleSystemList.Length - 1 do
            local v = self.m_particleSystemList[i]
            if v then
                v:Play()
            end
        end
    end

    if self.m_animatorList then
        for i = 0, self.m_animatorList.Length - 1 do
            local v = self.m_animatorList[i]
            if v then
                v.speed = 1
            end
        end
    end

end

function MediumComponent:SetPosition(pos)
    self.m_position = self:ParsePos(pos, self.m_position)
    GameUtility.SetLocalPosition(self.m_transform, self.m_position.x, self.m_position.y, self.m_position.z)
end

function MediumComponent:SetForward(forward)
    self.m_forward = self:ParsePos(forward, self.m_forward)
    GameUtility.SetForward(self.m_transform, self.m_forward.x, self.m_forward.y, self.m_forward.z)
end

function MediumComponent:ParsePos(pos, vector3Pos)
    local x, y, z = pos:GetXYZ()
    vector3Pos.x = x
    vector3Pos.y = y
    vector3Pos.z = z
    return vector3Pos
end

function MediumComponent:LookAtPos(x, y, z)
    GameUtility.LookAt(self.m_transform, x, y, z)
end

function MediumComponent:LookAtTransform(tr)
    self.m_transform:LookAt(tr)
end

function MediumComponent:SetLayerState(layerState)
    if layerState == BattleEnum.LAYER_STATE_HIDE then
        GameUtility.RecursiveSetLayer(self.m_gameObject, Layers.HIDE)
    elseif layerState == BattleEnum.LAYER_STATE_NORMAL then
        GameUtility.RecursiveSetLayer(self.m_gameObject, Layers.MEDIUM)
    end
end

function MediumComponent:MoveOnlyShow(dis)
    
    self.m_transform:Translate(0, 0, dis)
    
end

function MediumComponent:Rotate(x, y, z)
    -- 暂用于黄金弓箭手弓箭旋转
    
    GameUtility.RotateByEuler(self.m_transform, x, y, z)
end

return MediumComponent