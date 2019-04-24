local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local Formular = Formular
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local table_insert = table.insert
local FixNormalize = FixMath.Vector3Normalize
local FixFloor = FixMath.floor

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium10622 = BaseClass("Medium10622", LinearFlyToTargetMedium)

local GONOMOVE_DISTANCE = 2

function Medium10622:__init()
    self.m_goOnMove = false
    self.m_finalPos = nil
end

function Medium10622:DoUpdate(deltaMS)
    local owner = self:GetOwner()
    if not owner or not owner:IsLive() then
        self:Over()
        return 
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        self:Over()
        return
    end

    if self.m_goOnMove and self.m_finalPos then
        self:GoOnMove(deltaMS)
        return
    end

    local deltaS = FixDiv(deltaMS, 1000)
    self.m_param.speed = FixAdd(self.m_param.speed, FixMul(deltaS, self.m_param.varSpeed))
    
    local moveDis = FixMul(deltaS, self.m_param.speed) 
    local dir = target:GetPosition() - self.m_position
    dir.y = 0

    local disSqr = dir:SqrMagnitude()
    local targetRadius = target:GetRadius()

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
        self.m_goOnMove = true

        if not self.m_finalPos then
            self.m_finalPos = self.m_forward * GONOMOVE_DISTANCE
            self.m_finalPos:Add(self.m_position:Clone())
        end
        return
    end
end

function Medium10622:GoOnMove(deltaMS)
    local deltaS = FixDiv(deltaMS, 1000)
    self.m_param.speed = FixAdd(self.m_param.speed, FixMul(deltaS, self.m_param.varSpeed))
    
    local moveDis = FixMul(deltaS, self.m_param.speed) 
    local dir = self.m_finalPos - self.m_position
    dir.y = 0

    local disSqr = (self.m_position - self.m_finalPos):SqrMagnitude()
    if disSqr > 0.4 then
        local deltaV = FixNormalize(dir)
        self:SetNormalizedForward_OnlyLogic(deltaV)

        deltaV:Mul(moveDis) 
        self:MovePosition_OnlyLogic(deltaV)
        self:OnMove(dir)

        self:MoveOnlyShow(moveDis)
    else
        self:Over()
    end
end

function Medium10622:ArriveDest()
    self:Hurt()
end

function Medium10622:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local skillCfg = self:GetSkillCfg()
    if not skillCfg then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        return  
    end

    local injure = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:X())
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                            judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)
    end

    if self.m_skillBase:GetLevel() >= 2 then
        target:ChangeNuqi(FixIntMul(self.m_skillBase:A(), -1), BattleEnum.NuqiReason_STOLEN, skillCfg)
    end

    if self.m_skillBase:GetLevel() >= 5 then
        local logic = CtlBattleInst:GetLogic()
        local friendTargetIDList = {}
        local friendCount = 0
        ActorManagerInst:Walk(
            function(tmpTarget)
                if not logic:IsFriend(performer, tmpTarget, true) then
                    return
                end

                if ActorUtil.IsAnimal(tmpTarget) then
                    return
                end

                friendCount = FixAdd(friendCount, 1)
                table_insert(friendTargetIDList, tmpTarget:GetActorID())
            end
        )

        if friendCount > 0 then
            local nuqi = FixDiv(self.m_skillBase:A(), friendCount)
            nuqi = FixFloor(nuqi)
            for i=1,friendCount do
                local friendID = friendTargetIDList[i]
                local friendActor = ActorManagerInst:GetActor(friendID)
                if friendActor and friendActor:IsLive() then
                    friendActor:ChangeNuqi(nuqi, BattleEnum.NuqiReason_SKILL_RECOVER, skillCfg)
                end
            end
        end
    end
end

return Medium10622