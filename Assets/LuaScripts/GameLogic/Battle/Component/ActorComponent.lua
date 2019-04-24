local table_insert = table.insert
local Vector3 = Vector3
local ActorUtil = ActorUtil
local BattleEnum = BattleEnum
local EffectEnum = EffectEnum
local UIMessageNames = UIMessageNames
local ACTOR_ATTR = ACTOR_ATTR
local ActorComponent = BaseClass("ActorComponent")
local Type_ActorColor = typeof(CS.Battle_Actor.ActorColor) 
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local GameObject = CS.UnityEngine.GameObject
local Layers = Layers
local SkillUtil = SkillUtil
local GameUtility = CS.GameUtility
local Shader = CS.UnityEngine.Shader
local HorseShowClass = require "UI.UIWuJiang.HorseShow" 
local CommonDefine = CommonDefine
local UIManagerInst = UIManagerInst
local Animator = CS.UnityEngine.Animator

local Type_Animator = typeof(CS.UnityEngine.Animator)
local Type_Renderer = typeof(CS.UnityEngine.Renderer)

function ActorComponent:__init()
    self.m_gameObject = nil
    self.m_transform = nil
    self.m_actor = false
    self.m_effectPointTransDict = {}
    self.m_isInitBodyEffectRotation = false
    self.m_animator = false
    self.m_bodyEffectRotation = false
    self.m_position = Vector3.New(1, 0, 0)
    self.m_forward = Vector3.New(1, 0, 0)
    self.m_pauseSpeed = 0
    self.m_actorColor = false
    self.m_selectedGo = false
    self.m_bossquanGo = false
    self.m_isSelected = false
    self.m_layerState = BattleEnum.LAYER_STATE_NORMAL
    self.m_renderList = false
    self.m_bloodBar = false
    self.m_shadowMatList = {}
    self.m_lastForward = false
    self.m_forwardTime = 0
    self.m_horseShow = nil
    self.m_isOnHorse = false
    self.IdleAnimHash = Animator.StringToHash("Base Layer.idle")
end

function ActorComponent:__delete()
    self:RecycleActorObj()
    self.m_actor = nil
    self.m_gameObject = nil
    self.m_transform = nil
    self.m_renderList = nil
    self.m_shadowMatList = nil
    self.m_effectPointTransDict = nil
    self.m_isInitBodyEffectRotation = false
    self.m_animator = nil
    self.m_bodyEffectRotation = nil
    self.m_position = nil
    self.m_forward = nil
    self.m_bloodBar = false
    self.m_lastForward = false
    self.m_forwardTime = 0
    self.m_ShaderShadowHeightID = 0
    self.m_dummyTr = nil
    self.m_isOnHorse = false

    if self.m_actorColor then
        self.m_actorColor:Clear()
        self.m_actorColor = nil
    end

    if not IsNull(self.m_selectedGo) then
        GameObject.DestroyImmediate(self.m_selectedGo)
        self.m_selectedGo = nil
    end    

    if not IsNull(self.m_bossquanGo) then
        GameObject.DestroyImmediate(self.m_bossquanGo)
        self.m_bossquanGo = nil
    end
end

function ActorComponent:RecycleActorObj()
    if self.m_actor and not IsNull(self.m_gameObject) then
        local resID = self.m_actor:GetWujiangID()
        local wuqiLevel = self.m_actor:GetWuqiLevel()
        local res_path = PreloadHelper.GetWujiangPath(resID, wuqiLevel)
        GameObjectPoolInst:RecycleGameObject(res_path, self.m_gameObject)
        self.m_gameObject = nil
    end

    if self.m_horseShow then
        self.m_horseShow:MountOff(self.m_transform, self.m_dummyTr)
        self.m_horseShow:Delete()
        self.m_horseShow = nil
    end
end

function ActorComponent:CreateActorColor()
    if not IsNull(self.m_gameObject) then
        self.m_actorColor = UIUtil.FindComponent(self.m_transform, Type_ActorColor)
        if IsNull(self.m_actorColor) then
            self.m_actorColor = self.m_gameObject:AddComponent(Type_ActorColor)
        end
    end
end

function ActorComponent:OnBorn(actor_go, actor)
    self.m_gameObject = actor_go
    self.m_transform = actor_go.transform
    self.m_actor = actor
    self.m_animator = actor_go:GetComponentInChildren(Type_Animator)
    self.m_renderList = actor_go:GetComponentsInChildren(Type_Renderer)
    self.m_bloodBar = self.m_transform:Find("hp_up")
    self.m_bloodMiddlePoint = self.m_transform:Find("hp_middle")
    self.m_middleTrans = self.m_transform:Find("Dummy/Bip001/Bip001 Pelvis")
    self.m_dummyTr = self.m_transform:Find('Dummy')

    local x,y,z = self.m_actor:GetPosition():GetXYZ()
   -- local fx,fy,fz = self.m_actor:GetForward():GetXYZ()

    self.m_position = Vector3.New(x,y,z)
    GameUtility.SetLocalPosition(self.m_transform, x, y, z)
    self:SetForward(self.m_actor:GetForward(), true)

    self.m_gameObject.name = actor:GetActorID()

    self:CreateActorColor()
    
    if CtlBattleInst:GetLogic():CanRideHorse() then
        self:CreateHorse()
    end
    
    self:SetActorShadowHeight() 

    if self.m_actor:GetBossType() == BattleEnum.BOSSTYPE_SMALL then
        self:CreateBossQuan()
    end

    self.m_actor:SetComponent(self)    
  
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_ACTOR_CREATE, self.m_actor:GetActorID())
end

-- 给死亡表现的假actor用的，其他地方不要用了
function ActorComponent:SetActor(actor)
    self.m_actor = actor
end

function ActorComponent:CreateHorse()
    local mountID, mountLevel = self.m_actor:GetMountIDLevel()
    if mountID > 0 and mountLevel > 0 then
        local horsePath = PreloadHelper.GetHorsePath(mountID, mountLevel)
        GameObjectPoolInst:GetGameObjectAsync(horsePath,
            function(go, self)
                if IsNull(go) then
                    return
                end

                self.m_horseShow = HorseShowClass.New(go, mountID, mountLevel, false)
                -- self.m_horseShow:MountOn(self.m_transform, self.m_dummyTr)
                self:Mount()
                self:PlayAnim(BattleEnum.ANIM_IDLE)
            end, self)
    end

end

function ActorComponent:CreateActorSelectGo()
    local path, type = PreloadHelper.GetSingleEffectPath('Actor_Select')
    GameObjectPoolInst:GetGameObjectAsync(path,
        function(go, self)
            if IsNull(go) then
                return
            end

            self.m_selectedGo = go
            self.m_selectedGo.transform.parent = self.m_transform
            GameUtility.SetLocalPosition(self.m_selectedGo.transform, 0, 0.03, 0)
            self.m_selectedGo:SetActive(false)
        end, self)
end

function ActorComponent:CreateBossQuan()
    local path, type = PreloadHelper.GetSingleEffectPath('Boss_quan')
    GameObjectPoolInst:GetGameObjectAsync(path,
        function(go, self)
            if IsNull(go) then
                return
            end

            self.m_bossquanGo = go
            self.m_bossquanGo.transform.parent = self.m_transform
            GameUtility.SetLocalPosition(self.m_bossquanGo.transform, 0, 0.03, 0)
            self.m_bossquanGo:SetActive(true)
        end, self)
end

function ActorComponent:Mount()
    if self.m_horseShow and not self.m_isOnHorse then
        self.m_horseShow:MountOn(self.m_transform, self.m_dummyTr)
        self.m_isOnHorse = true
        return true
    end
    return false
end

function ActorComponent:Dismount()
    if self.m_horseShow and self.m_isOnHorse then
        self.m_horseShow:MountOff(self.m_transform, self.m_dummyTr)
        self.m_isOnHorse = false
    end
end

function ActorComponent:RemoveBossQuan()
    if not IsNull(self.m_bossquanGo) then
        GameObject.DestroyImmediate(self.m_bossquanGo)
        self.m_bossquanGo = nil
    end
end

function ActorComponent:GetEffectTransform(effectPoint)
    local trans = self.m_effectPointTransDict[effectPoint]
    if trans then
        return trans
    end

    
    if effectPoint == EffectEnum.ATTACH_POINT_HEAD then
        trans = self:GetBloodBarTransform()
        self.m_effectPointTransDict[effectPoint] = trans
        return trans
    end
    
    local path = self:GetBonePath(effectPoint)
   
    trans = self.m_transform:Find(path)

    
    self.m_effectPointTransDict[effectPoint] = trans
    return trans
end

function ActorComponent:GetBonePath(effectPoint)
    return ActorUtil.GetDefaultBonePath(effectPoint, self.m_actor:GetWujiangID())
end

function ActorComponent:Update(deltaTime)
    if not self.m_isInitBodyEffectRotation and self.m_animator then
        local stateInfo = self.m_animator:GetCurrentAnimatorStateInfo(0)
        if stateInfo.fullPathHash == self.IdleAnimHash then
            self.m_isInitBodyEffectRotation = true
            local trans = self:GetTransform(EffectEnum.ATTACH_POINT_BODY)
            if trans then
                local rotation = trans.rotation
                rotation = Quaternion.New(rotation.x, rotation.y, rotation.z , rotation.w)
                self.m_bodyEffectRotation = rotation:Inverse()
            end
        end
    end

    self:UpdateForward(deltaTime)
end

function ActorComponent:UpdateForward(deltaTime)
    self.m_forwardTime = self.m_forwardTime + deltaTime
    if self.m_forwardTime >= 0.15 then
        self.m_forwardTime = 0

        if not self.m_forward then
            return
        end
        
        if not self.m_lastForward or not self.m_forward:Equals(self.m_lastForward) then
            self.m_lastForward = self.m_forward:Clone()
            GameUtility.SetForward(self.m_transform, self.m_lastForward.x, self.m_lastForward.y, self.m_lastForward.z)
        end
    end
end

function ActorComponent:GetBodyEffectRotation()
    return self.m_bodyEffectRotation
end

function ActorComponent:PlayAnim(animName, crossTime)
    crossTime = crossTime or 0.1

    if self.m_animator then

        if self.m_isOnHorse then
            if self.m_horseShow then
                if animName == BattleEnum.ANIM_IDLE then                    
                    animName = PreloadHelper.GetRideIdleAnim(self.m_horseShow:GetHorseID())
                elseif animName == BattleEnum.ANIM_MOVE then
                    animName = PreloadHelper.GetRideWalkAnim(self.m_horseShow:GetHorseID())
                end

                GameUtility.ForceCrossFade(self.m_animator, animName, crossTime) 

                self.m_horseShow:PlayAnim(animName)
            end
        else
            GameUtility.ForceCrossFade(self.m_animator, animName, crossTime) 
        end
    end
end

function ActorComponent:Pause(reason)
    if self.m_animator then
        if self.m_animator.speed ~= 0 then
            self.m_pauseSpeed = self.m_animator.speed
            self.m_animator.speed = 0
        end
    end

    if self.m_actorColor then
        self.m_actorColor:Pause()
    end

    GameUtility.UseWeaponTrail(self.m_gameObject, false)
end

function ActorComponent:Resume(reason)
    if self.m_animator then
        self.m_animator.speed = self.m_pauseSpeed
    end

    if self.m_actorColor then
        self.m_actorColor:Resume()
    end
    
    GameUtility.UseWeaponTrail(self.m_gameObject, true)
end

function ActorComponent:SetPosition(pos)
    self.m_position = self:ParsePos(pos,self.m_position)
    GameUtility.SetLocalPosition(self.m_transform, self.m_position.x, self.m_position.y, self.m_position.z)
    
    local y = pos.y + 0.03
    for _, mat in ipairs(self.m_shadowMatList) do
        mat:SetFloat(self.m_ShaderShadowHeightID, y)
    end

    if self.m_horseShow then
        self.m_horseShow:SetShadowHeight(pos.y)
    end
end

function ActorComponent:FixPosY(posY)
    self.m_position.y = self.m_position.y + (posY - self.m_position.y) * Time.deltaTime * 15
    GameUtility.SetLocalPosition(self.m_transform, self.m_position.x, self.m_position.y, self.m_position.z)
    
    local y = posY + 0.03
    for _, mat in ipairs(self.m_shadowMatList) do
        mat:SetFloat(self.m_ShaderShadowHeightID, y)
    end

    if self.m_horseShow then
        self.m_horseShow:SetShadowHeight(posY)
    end
end

function ActorComponent:SetForward(pos, immediate)
    self.m_forward = self:ParsePos(pos,self.m_forward)

    if immediate then
        GameUtility.SetForward(self.m_transform, self.m_forward.x, self.m_forward.y, self.m_forward.z)
        self.m_lastForward = self.m_forward:Clone()
    end
end

function ActorComponent:SetForwardWithVector3(forward, immediate)
    local dir = Vector3.Normalize(forward)
    self.m_forward = Vector3.New(dir.x, 0, dir.z)

    if immediate then
        GameUtility.SetForward(self.m_transform, self.m_forward.x, self.m_forward.y, self.m_forward.z)
        self.m_lastForward = self.m_forward:Clone()
    end
end

function ActorComponent:SetPositionWithVector3(pos)
    self.m_position = pos
    GameUtility.SetLocalPosition(self.m_transform, self.m_position.x, self.m_position.y, self.m_position.z)
    
    local y = pos.y + 0.03
    for _, mat in ipairs(self.m_shadowMatList) do
        mat:SetFloat(self.m_ShaderShadowHeightID, y)
    end
    
    if self.m_horseShow then
        self.m_horseShow:SetShadowHeight(pos.y)
    end
end

function ActorComponent:GetPosition()
    return self.m_position
end

function ActorComponent:GetForward()
    return self.m_forward
end

function ActorComponent:LookAt(vector3Pos)
    GameUtility.LookAt(self.m_transform, vector3Pos.x, vector3Pos.y, vector3Pos.z)
end

function ActorComponent:ParsePos(pos,vector3Pos)
    local x,y,z = pos:GetXYZ()
    vector3Pos.x = x
    vector3Pos.y = y
    vector3Pos.z = z
    return vector3Pos
end

function ActorComponent:GetTransform()
    return self.m_transform
end

function ActorComponent:GetGameObject()
    return self.m_gameObject
end

function ActorComponent:GetBloodBarTransform()
    return self.m_bloodBar
end

-- function ActorComponent:InnerMove(deltaTime)
--     if not self.m_actor then
--         return
--     end

--     local destPos, speed, leftDistance = self.m_actor:GetMoveHelper():GetParam()

-- end

function ActorComponent:SetAnimatorSpeed(aniSpeed)
    if self.m_animator then
        if aniSpeed ~= self.m_animator.speed then
            self.m_animator.speed = aniSpeed
        end
    end
end

function ActorComponent:GetActorColor()
    return self.m_actorColor
end

function ActorComponent:Shake()
end

function ActorComponent:PunchScale()
    DOTweenShortcut.DOPunchScale(self.m_transform, Vector3.New(0.2, 0.2, 0.2), 0.5)
end

function ActorComponent:HideSelected()
    --todo set layer
    if not IsNull(self.m_selectedGo) then
        self.m_selectedGo:SetActive(false)
    end
    self.m_isSelected = false
end

function ActorComponent:ShowSelected()   
    if IsNull(self.m_selectedGo) then
        self:CreateActorSelectGo()
    end

    if not IsNull(self.m_selectedGo) then
        self.m_selectedGo:SetActive(true)
    end
    self.m_isSelected = true
end

function ActorComponent:HideEffect()
end

function ActorComponent:ShowEffect()
end

function ActorComponent:HideBloodUI(reason)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_SHOW_BLOOD_BAR, self.m_actor:GetActorID(), false)
end

function ActorComponent:ShowBloodUI(reason)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_SHOW_BLOOD_BAR, self.m_actor:GetActorID(), true)
end

function ActorComponent:ChangeBlood(chgVal) --血条
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_HP_CHANGE, self.m_actor:GetActorID(), chgVal)
end

function ActorComponent:StartContinueGuide(guideduring)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_ACTOR_GUIDE, self.m_actor:GetActorID(), guideduring)
end

function ActorComponent:InterruptContinueGuide()
    -- UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_ACTOR_INTERRUPT_GUIDE, self.m_actor:GetActorID())
    EffectMgr:AddEffect(self.m_actor:GetActorID(), 20027)
end

function ActorComponent:ChangeHP(giver, hurtType, chgVal, judge)
    if chgVal ~= 0 then
        UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_HP, self.m_actor, giver, hurtType, chgVal, judge)
        self:ChangeBlood(chgVal)
    end    
    self:ShowBloodUI()

    if chgVal > 0 then
        EffectMgr:AddEffect(self.m_actor:GetActorID(), 20009)
    end

    local currHP = self.m_actor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
    if currHP <= 0 then
        local wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_actor:GetWujiangID())
        if wujiangCfg and wujiangCfg.dieAudio > 0 then
            AudioMgr:PlayAudio(wujiangCfg.dieAudio)
        end
    end
end

function ActorComponent:DaZhaoBroken(from, to, fromInfo, exParam)
    EffectMgr:AddEffect(self.m_actor:GetActorID(), 20011)
end

function ActorComponent:ChangeNuqi(chgVal, reason, showText)
    if chgVal ~= 0 and showText then
        UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_NUQI, self.m_actor, chgVal, reason)
    end
end

function ActorComponent:ShowJudgeFloatMsg(judge, reason)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_JUDGE, self.m_actor, judge, reason)
end

function ActorComponent:ShowBuffMaskMsg(count, statusType)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_MASK, self.m_actor, count, statusType)
end

function ActorComponent:ShowSkillMaskMsg(count, type, path)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_SKILL_MASK, self.m_actor, count, type, path)
end

function ActorComponent:ShowInscriptionSkill(giver)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_INSCRIPANDHORSESKILL, self.m_actor, giver)
end

function ActorComponent:ShowActiveSkill(skillCfg)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_ACTIVE_SKILL, self.m_actor, skillCfg)
end

function ActorComponent:ShowAttr(attr, oldVal, newVal)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_ATTR, self.m_actor, attr, oldVal, newVal)

    if attr == ACTOR_ATTR.FIGHT_MAXHP and oldVal ~= newVal then
        UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_HP_CHANGE, self.m_actor:GetActorID(), 0)
    end
end

function ActorComponent:ShowFloatHurt(floatType)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLEFLOAT_SHOW_HURT_END, self.m_actor, floatType) 
end

function ActorComponent:SetLayerState(layerState)
    self.m_layerState = layerState
    local layer = ActorUtil.GetLayer(self.m_layerState)

    if self.m_layerState == BattleEnum.LAYER_STATE_HIDE then
        self:HideEffect()
        self:HideBloodUI()
    else
        self:ShowEffect()
        self:ShowBloodUI()
    end

    
    GameUtility.RecursiveSetLayer(self.m_gameObject, layer)
	GameUtility.SetWeaponTrailLayer(self.m_gameObject, layer)

end

function ActorComponent:GetMiddlePoint()
    return self.m_bloodMiddlePoint
end

function ActorComponent:GetMiddleTrans()
    return self.m_middleTrans
end

function ActorComponent:OnControl(controlMSTime)
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_ACTOR_BE_CONTROL, self.m_actor:GetActorID(), controlMSTime)
end

function ActorComponent:GetCurrentAnimatorStateLength(clipNamePart)
  
    if self.m_animator then
        return GameUtility.GetClipLength(self.m_animator, clipNamePart)
    end

    return 0
end

function ActorComponent:SetActorShadowHeight()
    if self.m_renderList then
        self.m_ShaderShadowHeightID = Shader.PropertyToID("_ShadowHeight")
        local y = self.m_actor:GetPosition().y + 0.06
        for i = 0, self.m_renderList.Length - 1 do
            local r = self.m_renderList[i]
            local mat = r.material
            if not IsNull(mat) then
                if r.material:HasProperty('_ShadowHeight') then
                    table_insert(self.m_shadowMatList, mat)
                    mat:SetFloat(self.m_ShaderShadowHeightID, y)
                end
            end
        end
    end
end

return ActorComponent