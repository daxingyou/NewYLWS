local BattleEnum = BattleEnum
local ConfigUtil = ConfigUtil
local SKILL_PERFORM_MODE = SKILL_PERFORM_MODE
local SKILL_PHASE = SKILL_PHASE
local SkillUtil = SkillUtil
local SKILL_RANGE_TYPE = SKILL_RANGE_TYPE
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixMul = FixMath.mul
local FixDiv = FixMath.div

local FixNewVector3 = FixMath.NewFixVector3
local FixNormalize = FixMath.Vector3Normalize
local CtlBattleInst = CtlBattleInst

local StateInterface = require "GameLogic.Battle.ActorState.StateInterface"
local HurtState = BaseClass("HurtState", StateInterface)

local Speed_in_sky = 5.7
local Speed_on_ground = 0.5

local Anim_none = 0
local Anim_normal = 1
local Anim_flyup = 2
local Anim_insky = 3
local Anim_flyaway = 4

local Move_none = 0
local Move_flydown = 1
local Move_flyaway = 2

function HurtState:__init(selfActor)
    self.m_anim = Anim_none
    self.m_atkerPos = false
    self.m_hurtFlyDis = 0
    self.m_isPause = false
    self.m_phase = BattleEnum.HURTSTATE_PHASE_NORMAL
    self.m_phaseMS = 0
    self.m_phaseLength = 0
    self.m_hurtParam1 = nil
    self.m_actionCfg = nil
end

function HurtState:GetStateID()
    return BattleEnum.ActorState_HURT
end

function HurtState:SetParam(whatParam, ...)
    if whatParam == BattleEnum.StateParam_HURT_ACTION then
        self:CalcAnim(...)
        self:ChangeAction()
    end
end

function HurtState:Start(...)
    self.m_execState = BattleEnum.EventHandle_CONTINUE
    self.m_isPause = false
    self.m_actionCfg = ConfigUtil.GetActionCfgByID(self.m_selfActor:GetWujiangID())
    self.m_anim = Anim_none

    self:CalcAnim(...)
    self:ChangeAction()

    return true
end

function HurtState:CalcAnim(...)
    local atkWay, atkerPos, hurtFlyDis, hurtParam1 = ...

    --self.m_anim = Anim_none
    self.m_atkerPos = atkerPos
    self.m_hurtFlyDis = hurtFlyDis
    self.m_hurtParam1 = hurtParam1
        
    if self.m_anim == Anim_none or self.m_anim == Anim_normal then
        if atkWay == BattleEnum.ATTACK_WAY_IN_SKY then
            self.m_anim = Anim_flyup
        elseif atkWay == BattleEnum.ATTACK_WAY_FLY_AWAY then
            self.m_anim = Anim_flyaway
        else
            self.m_anim = Anim_normal
        end 
    elseif self.m_anim == Anim_flyup or self.m_anim == Anim_insky then
        if atkWay == BattleEnum.ATTACK_WAY_IN_SKY then
            self.m_anim = Anim_insky
        elseif atkWay == BattleEnum.ATTACK_WAY_FLY_AWAY then
            self.m_anim = Anim_flyaway
        end
    elseif self.m_anim == Anim_flyaway then
        if atkWay == BattleEnum.ATTACK_WAY_IN_SKY then
            self.m_anim = Anim_insky 
        elseif atkWay == BattleEnum.ATTACK_WAY_FLY_AWAY then
            self.m_anim = Anim_flyaway
        end
    end
end

function HurtState:ChangeAction()   
    if not self.m_actionCfg then
        return
    end

    if self.m_anim == Anim_normal then
        local animCfg = ConfigUtil.GetAnimationCfgByName(self.m_actionCfg['hurt'])
        if not animCfg then
            return
        end

        self.m_phaseMS = 0
        self.m_phase = BattleEnum.HURTSTATE_PHASE_NORMAL
        self.m_phaseLength = animCfg.length
        self.m_selfActor:PlayAnim(BattleEnum.ANIM_HURT_NORMAL)

    elseif self.m_anim == Anim_insky then
        -- local animCfg = ConfigUtil.GetAnimationCfgByName(self.m_actionCfg['hurt_in_sky'])
        -- if not animCfg then
        --     return
        -- end

        self.m_phaseMS = 0
        self.m_phase = BattleEnum.HURTSTATE_PHASE_INSKY
        self.m_phaseLength = self.m_hurtParam1 or 133       -- animCfg.length
        self.m_selfActor:PlayAnim(BattleEnum.ANIM_HURT_IN_SKY)
        
    elseif self.m_anim == Anim_flyup then
        -- local animCfg = ConfigUtil.GetAnimationCfgByName(self.m_actionCfg['hurt_up'])
        -- if not animCfg then
        --     return
        -- end

        self.m_phaseMS = 0
        self.m_phase = BattleEnum.HURTSTATE_PHASE_INSKY
        self.m_phaseLength = self.m_hurtParam1 or 200       -- animCfg.length
        self.m_selfActor:PlayAnim(BattleEnum.ANIM_HURT_UP)

    elseif self.m_anim == Anim_flyaway then
        -- local animCfg = ConfigUtil.GetAnimationCfgByName(self.m_actionCfg['hurt_up'])
        -- if not animCfg then
        --     return
        -- end

        self.m_phaseMS = 0
        self.m_phase = BattleEnum.HURTSTATE_PHASE_INSKY
        self.m_phaseLength = self.m_hurtParam1 or 200       -- animCfg.length
        self.m_selfActor:PlayAnim(BattleEnum.ANIM_HURT_UP)

        self:StartFlyAway()
    end
end

function HurtState:StartFlyAway()
    local tmpDir = self.m_selfActor:GetPosition() - self.m_atkerPos
    tmpDir.y = 0
    tmpDir = FixNormalize(tmpDir)
    tmpDir:Mul(self.m_hurtFlyDis)

    local myPos = self.m_selfActor:GetPosition()
    tmpDir:Add(myPos)
    
    local destPos = tmpDir

    local x, y, z = myPos:GetXYZ()
    local x2, y2, z2 = destPos:GetXYZ()
    local pathHandler = CtlBattleInst:GetPathHandler()
    if pathHandler then
        local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
        if hitPos then
            destPos:SetXYZ(hitPos.x , myPos.y, hitPos.z)
        end
    end

    local movehelper = self.m_selfActor:GetMoveHelper()
    movehelper:Start({ destPos }, Speed_in_sky, nil, false)
end

function HurtState:Update(deltaMS)
    if self.m_isPause then
        return
    end

    if self.m_execState == BattleEnum.EventHandle_END then
        return
    end

    self.m_phaseMS = FixAdd(self.m_phaseMS, deltaMS)

    if self.m_phaseMS >= self.m_phaseLength then
        if self.m_phase == BattleEnum.HURTSTATE_PHASE_NORMAL then
            self.m_execState = BattleEnum.EventHandle_END
            return
        elseif self.m_phase == BattleEnum.HURTSTATE_PHASE_INSKY then
            self:BeginOnGround()
            return
        elseif self.m_phase == BattleEnum.HURTSTATE_PHASE_ONGROUND then
            self:EndOnGround()
            return
        elseif self.m_phase == BattleEnum.HURTSTATE_PHASE_ONGROUND_STAND then
            self:EndGroundStand()
            return
        end
    end   
end

function HurtState:BeginOnGround()
    if not self.m_actionCfg then
        return
    end

    -- local animCfg = ConfigUtil.GetAnimationCfgByName(self.m_actionCfg['hurt_down'])
    -- if not animCfg then
    --     return
    -- end

    self.m_phaseMS = 0
    self.m_phase = BattleEnum.HURTSTATE_PHASE_ONGROUND
    self.m_phaseLength = 1000       -- animCfg.length
    
    local tmpDir = self.m_selfActor:GetPosition() - self.m_atkerPos 
    tmpDir.y = 0
    tmpDir = FixNormalize(tmpDir)

    local moveDis = 1

    -- local wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_selfActor:GetWujiangID())
    -- if wujiangCfg then
    --     moveDis = wujiangCfg.HurtDownDis
    -- end

    local myPos = self.m_selfActor:GetPosition()

    tmpDir:Mul(moveDis)
    tmpDir:Add(myPos)
    
    local destPos = tmpDir

    local x, y, z = myPos:GetXYZ()
    local x2, y2, z2 = destPos:GetXYZ()
    local pathHandler = CtlBattleInst:GetPathHandler()
    if pathHandler then
        local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
        if hitPos then
            destPos:SetXYZ(hitPos.x , myPos.y, hitPos.z)
        end
    end

    local movehelper = self.m_selfActor:GetMoveHelper()
    movehelper:Start({ destPos }, Speed_in_sky, nil, false)
end

function HurtState:EndOnGround()
    if self.m_selfActor:IsLive() then
        CtlBattleInst:GetLogic():OnHurtFlyAway(self.m_selfActor:GetPosition())

        if not self.m_actionCfg then
            return
        end

        -- local animCfg = ConfigUtil.GetAnimationCfgByName(self.m_actionCfg['hurt_down_end'])
        -- if not animCfg then
        --     return
        -- end

        self.m_phaseMS = 0
        self.m_phase = BattleEnum.HURTSTATE_PHASE_ONGROUND_STAND
        self.m_phaseLength = 400    -- animCfg.length
        self.m_selfActor:PlayAnim(BattleEnum.ANIM_HURT_DOWN_STAND)
    else
        self:End()
    end
end

function HurtState:EndGroundStand()
    self:End()
end

function HurtState:AnimateHurt()
    if self.m_anim == Anim_none or self.m_anim == Anim_normal then
        return true
    else
        return false
    end
end

function HurtState:AnimateDeath()
    if self.m_phase == BattleEnum.HURTSTATE_PHASE_NORMAL or self.m_phase == BattleEnum.HURTSTATE_PHASE_ONGROUND_STAND then
        return true
    else
        return false
    end
end

function HurtState:End()
    self.m_actionCfg = nil
    self.m_isPause = false
    self.m_execState = BattleEnum.EventHandle_END
end

function HurtState:Pause(reason)
    self.m_isPause = true
end

function HurtState:Resume(reason)
    self.m_isPause = false
end

function HurtState:OnFightEnd()
    if not self.m_selfActor:IsLive() then
        self:End()
    end
end

function HurtState:GetStatePhase()
    return self.m_phase
end

return HurtState