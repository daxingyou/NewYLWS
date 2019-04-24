local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local Formular = Formular
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local CtlBattleInst = CtlBattleInst
local IsInCircle = SkillRangeHelper.IsInCircle
local table_insert = table.insert
local table_remove = table.remove
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local FixNormalize = FixMath.Vector3Normalize

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium12142 = BaseClass("Medium12142", LinearFlyToTargetMedium)

local MediumState = {
    Normal = 1,
    Hurt = 2
}

function Medium12142:__init()
    self.m_ejectionCount = 0
    self.m_canEjectionCount = 0
    self.m_ejectionInjure = 0
    self.m_ejectionDic = {}
    self.m_ejectionList = {}
    self.m_mediumState = MediumState.Normal
end

function Medium12142:DoUpdate(deltaMS)
    local owner = self:GetOwner()
    if not owner or not owner:IsLive() then
        self:Clear()
        return 
    end
    
    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        self:Clear()
        return
    end

    if self.m_mediumState == MediumState.Normal then
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
            self.m_mediumState = MediumState.Hurt
        end

    elseif self.m_mediumState == MediumState.Hurt then
        self:ArriveDest()
    end
end

function Medium12142:Clear()
    self.m_ejectionCount = 0
    self.m_canEjectionCount = 0
    self.m_ejectionInjure = 0
    self.m_ejectionDic = {}
    self.m_ejectionList = {}
    self:Over()
end


function Medium12142:ArriveDest()
    if self.m_ejectionInjure <= 0 then
        self:Hurt()
    else
        self:HurtEjectionTarget()
    end
end

function Medium12142:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local skillCfg = self:GetSkillCfg()
    if not skillCfg then
        return
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        self:Clear()
        return  
    end

    local injure = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:X())
    self.m_canEjectionCount = performer:Get12143Count()
    if injure > 0 then
        local skillLevel = self.m_skillBase:GetLevel()
        if skillLevel >= 5 then
            local injureMul = performer:Get12143Y()
            injure = FixAdd(injure, FixMul(injure, FixMul(self.m_canEjectionCount, injureMul)))
        end

        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)

        local silentStatus = StatusFactoryInst:NewStatusSilent(self.m_giver, FixIntMul(self.m_skillBase:A(), 1000))
        self:AddStatus(performer, target, silentStatus)
    end

    if self.m_ejectionInjure <= 0 then
        local mul = performer:Get12143X()
        self.m_ejectionInjure = FixMul(injure, mul)
    end

    if self.m_canEjectionCount > 0 then
        self:EjectionOther(target, performer)
    else
        self:Clear()
    end
end

function Medium12142:EjectionOther(target, performer)
    local nextTarget = self:SelectOneActor(target, performer)
    if nextTarget and nextTarget:IsLive() then
        self.m_param.targetActorID = nextTarget:GetActorID()
        self.m_mediumState = MediumState.Normal
    end
end

function Medium12142:SelectOneActor(target, performer)
    local selectTarget = false
    local battleLogic = CtlBattleInst:GetLogic()
    local targetPos = target:GetPosition()
    local radius = performer:Get12143B()
    local minDis = 9999999999
    local suitableList = {}

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if tmpTarget:GetActorID() == self.m_param.targetActorID then
                return
            end

            if not IsInCircle(targetPos, radius, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end

            local disSqr = (targetPos - tmpTarget:GetPosition()):SqrMagnitude()
            if disSqr <= minDis then
                minDis = disSqr
                selectTarget = tmpTarget
            end

            table_insert(suitableList, tmpTarget:GetActorID())
        end
    )

    local hasSuitable = false
    if selectTarget then
        if self.m_ejectionDic[selectTarget:GetActorID()] and #suitableList > 0 then
            for i=1,#suitableList do
                local targetID = suitableList[i]
                if not self.m_ejectionDic[targetID] then
                    hasSuitable = true
                    selectTarget = ActorManagerInst:GetActor(targetID)
                end
            end
        end

        if not hasSuitable and self.m_ejectionDic[selectTarget:GetActorID()] then
            local count = #self.m_ejectionList
            if count > 0  then
                local index = FixMod(self.m_ejectionCount, count)
                index = FixAdd(index, 1)
                local newTargetID = self.m_ejectionList[index]
                selectTarget = ActorManagerInst:GetActor(newTargetID)
            end
        end
    end

    return selectTarget
end

function Medium12142:HurtEjectionTarget()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local skillCfg = self:GetSkillCfg()
    if not skillCfg then
        return
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        if not self.m_ejectionDic[self.m_param.targetActorID] then
            self.m_ejectionDic[self.m_param.targetActorID] = true
            table_insert(self.m_ejectionList, self.m_param.targetActorID)
        end
        
        self.m_ejectionCount = FixAdd(self.m_ejectionCount, 1)
        self.m_canEjectionCount = performer:Get12143Count() -- 随着普攻增加而稍慢增加
        if self.m_ejectionCount < self.m_canEjectionCount  then
            self:EjectionOther(target, performer)
        else
            self:Clear()
        end
        return  
    end

    local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(self.m_ejectionInjure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
            judge, self.m_param.keyFrame)
    self:AddStatus(performer, target, status)

    local skillLevel = self.m_skillBase:GetLevel()
    if skillLevel >= 2 then
        local silentStatus = StatusFactoryInst:NewStatusSilent(self.m_giver, FixIntMul(self.m_skillBase:A(), 1000))
        self:AddStatus(performer, target, silentStatus)
    end

    if not self.m_ejectionDic[self.m_param.targetActorID] then
        self.m_ejectionDic[self.m_param.targetActorID] = true
        table_insert(self.m_ejectionList, self.m_param.targetActorID)
    end

    self.m_ejectionCount = FixAdd(self.m_ejectionCount, 1)
    self.m_canEjectionCount = performer:Get12143Count() -- 随着普攻增加而稍慢增加
    if self.m_ejectionCount < self.m_canEjectionCount  then
        self:EjectionOther(target, performer)
    else
        self:Clear()
    end
end

return Medium12142