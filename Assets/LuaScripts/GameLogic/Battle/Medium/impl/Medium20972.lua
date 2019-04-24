local FixMul = FixMath.mul
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixSin = FixMath.sin
local FixCos = FixMath.cos
local ActorManagerInst = ActorManagerInst
local BattleEnum = BattleEnum
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local FixNormalize = FixMath.Vector3Normalize

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium20972 = BaseClass("Medium20972", LinearFlyToTargetMedium)

local MAX_RADIUS_FACTOR = 2
local RADIUS_FACTOR = 0.9
local RADIUS_FACTOR_REDUCE_CONST = -1.1

local TWEEN_RADIUS_TIME2 = 1.1

local MediumState= {
    SurroundOwner = 1,
    FlyAway = 2,
}

function Medium20972:InitParam(param, index)
    LinearFlyToTargetMedium.InitParam(self, param)

    self.m_passTime = 0 
    self.m_speedFactor = 4
    self.m_tweenRadiusTime1 = -1
    self.m_tweenRadiusTime2 = -1
    self.m_radiusFactor = RADIUS_FACTOR
    self.m_tmpVector3 = Vector3.zero
    self.m_index = param.index

    self.m_currentTargetID = 0

    self.m_canFlyAway = false
    self.m_mediumState = MediumState.SurroundOwner
end

function Medium20972:DoUpdate(deltaMS)
    local owner = self:GetOwner()
    if not owner or not owner:IsLive() then
        self:Over()
        return 
    end

    if self.m_mediumState == MediumState.SurroundOwner then
        self:SurroundOwner(owner, deltaMS)
        if owner:CanFlyAway() then
            self.m_mediumState = MediumState.FlyAway
        end
        return
    elseif self.m_mediumState == MediumState.FlyAway then
        if not self:IsAtOwnerForward(owner) then 
            self:SurroundOwner(owner, deltaMS)
            return
        end

        if self.m_currentTargetID <= 0 then
            self.m_currentTargetID = owner:GetCurrentTargetID()
        end

        local target = ActorManagerInst:GetActor(self.m_currentTargetID)
        if not target or not target:IsLive() then
            self:SurroundOwner(owner, deltaMS)
            -- self:Over()
            return
        end

        local deltaS = FixDiv(deltaMS, 1000)
        self.m_param.speed = FixAdd(self.m_param.speed, FixMul(deltaS, self.m_param.varSpeed))

        local moveDis = FixMul(deltaS, self.m_param.speed) 
        local dir = target:GetPosition() - self.m_position
        -- dir.y = 0

        local targetRadius = target:GetRadius()
        local disSqr = dir:SqrMagnitude()

        if disSqr > FixMul(targetRadius, targetRadius) then
            local deltaV = FixNormalize(dir)
            self:SetNormalizedForward_OnlyLogic(deltaV)

            deltaV:Mul(moveDis) 
            self:MovePosition_OnlyLogic(deltaV)
            self:OnMove(dir)

            local middlePoint = target:GetMiddlePoint()
            if middlePoint then
                self:LookatTransformOnlyShow(middlePoint)
            end
            self:MoveOnlyShow(moveDis)
        else
            self:ArriveDest()
            self:Over()
            return
        end
    end
end

function Medium20972:ArriveDest()
    self:Hurt()
end

function Medium20972:SurroundOwner(owner, deltaMS)
    local speed = 1.5

    if self.m_tweenRadiusTime1 > 0  then
        self.m_tweenRadiusTime1 = FixSub(self.m_tweenRadiusTime1, speed)
        if self.m_tweenRadiusTime1 <= 0 then
            self.m_tweenRadiusTime1 = -1
            self.m_radiusFactor = MAX_RADIUS_FACTOR
            self.m_tweenRadiusTime2 = TWEEN_RADIUS_TIME2
            self.m_speedFactor = 6
        else
            self.m_speedFactor = FixAdd(4, FixMul(2,FixSub(1, self.m_tweenRadiusTime1)))
            local prob = FixMul(RADIUS_FACTOR_REDUCE_CONST, self.m_tweenRadiusTime1)
            self.m_radiusFactor = FixAdd(prob, MAX_RADIUS_FACTOR)
        end
    elseif self.m_tweenRadiusTime2 > 0 then
        self.m_tweenRadiusTime2 = FixSub(self.m_tweenRadiusTime2, speed)
        if self.m_tweenRadiusTime2 <= 0 then
            self.m_tweenRadiusTime2 = -1
            self.m_radiusFactor = 0
        else
            self.m_speedFactor = FixAdd(6, FixMul(8, FixSub(1, FixDiv(self.m_tweenRadiusTime2, TWEEN_RADIUS_TIME2))))
            self.m_radiusFactor = FixDiv(FixMul(MAX_RADIUS_FACTOR, self.m_tweenRadiusTime2), TWEEN_RADIUS_TIME2)
        end
    end

    self.m_passTime = FixAdd(self.m_passTime, FixMul(speed, self.m_speedFactor))

    local newPos = owner:GetPosition():Clone()
    local sin = FixSin(self.m_passTime)
    local fsin = FixMul(sin, -1)
    local cos = FixCos(self.m_passTime)
    local fcos = FixMul(cos, -1)
    local tmpMul = FixMul(fsin, self.m_radiusFactor)
    -- cos(x) = cos(-x)   cos(pi + x) = -cos(x)  cos(pi - x) = -cos(x)  
    -- sin(x) = -sin(-x)  sin(pi + x) = -sin(x)  sin(pi - x) = sin(x)
    if self.m_index == 1 then
        newPos.x = FixAdd(newPos.x, FixMul(sin, self.m_radiusFactor))
        newPos.z = FixAdd(newPos.z, FixMul(cos, self.m_radiusFactor))
        newPos.y = FixAdd(tmpMul, self.m_position.y)
    elseif self.m_index == 2 then
        newPos.x = FixAdd(newPos.x, tmpMul)
        newPos.z = FixAdd(newPos.z, FixMul(fcos, self.m_radiusFactor))
        newPos.y = FixAdd(tmpMul, self.m_position.y)
    elseif self.m_index >= 3 then
        local tmpCosMul = FixMul(cos, self.m_radiusFactor)
        newPos.x = FixAdd(newPos.x, tmpMul)
        newPos.z = FixAdd(newPos.z, tmpCosMul)
        newPos.y = FixAdd(tmpCosMul, self.m_position.y)
    end

    if self.m_component then
        self.m_component:SetPosition(newPos)
    end
end

function Medium20972:IsAtOwnerForward(owner)
    if self.m_position.y >= owner:GetPosition().y then  -- 防止可能会飞过目标头顶
        -- self:SetForward(owner:GetForward())
        return true
    end

    return false
end

function Medium20972:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    performer:DecBallCount()
    
    local target = ActorManagerInst:GetActor(self.m_currentTargetID)
    if not target or not target:IsLive() then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return
    end
    
    local injure = Formular.CalcInjure(performer, target, self:GetSkillCfg(), BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:X())
    
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)
    end
end

return Medium20972