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
local IsInCircle = SkillRangeHelper.IsInCircle
local FixRand = BattleRander.Rand
local FixMod = FixMath.mod

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium10152 = BaseClass("Medium10152", LinearFlyToTargetMedium)


function Medium10152:__init()
    self.m_tanCount = 0
    self.m_maxCount = 3
    self.m_extraCount = 0
    self.m_lastTanTargetID = 0
    
    self.m_distance = 0
end


function Medium10152:InitParam(param)
    LinearFlyToTargetMedium.InitParam(self, param)

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    local performer = self:GetOwner()
    if performer and performer:IsLive() and target and target:IsLive() then
        self.m_distance = (target:GetPosition() - self.m_position):Magnitude()
    end
end

function Medium10152:DoUpdate(deltaMS)
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

    local deltaS = FixDiv(deltaMS, 1000)
    self.m_param.speed = FixAdd(self.m_param.speed, FixMul(deltaS, self.m_param.varSpeed))
    
    local moveDis = FixMul(deltaS, self.m_param.speed) 
    local dir = target:GetPosition() - self.m_position

    local disSqr = dir:SqrMagnitude()
    local targetRadius = target:GetRadius()

    local middlePoint = target:GetMiddlePoint()
    if middlePoint then
        self:LookatTransformOnlyShow(middlePoint)
    end

    local curDis = dir:Magnitude()
    local angle = FixMul(FixDiv(curDis, self.m_distance), 50)
    self:Rotate(FixMul(angle, -1), 0, 0)

    if disSqr > FixMul(targetRadius, targetRadius) then
        local deltaV = FixNormalize(dir)
        self:SetNormalizedForward_OnlyLogic(deltaV)

        deltaV:Mul(moveDis) 
        self:MovePosition_OnlyLogic(deltaV)
        self:OnMove(dir)
        self:MoveOnlyShow(moveDis)
    else
        self:ArriveDest()
        return
    end
end

function Medium10152:ArriveDest()
    self:Hurt()
end

function Medium10152:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        self:Over()
        return
    end

    local skillCfg = self:GetSkillCfg()
    if not skillCfg then
        self:Over()
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
    if Formular.IsJudgeEnd(judge) then
        if self.m_tanCount >= self.m_maxCount then
            self:Over()
        end
    
        self:ChooseTarget(target)
        return  
    end

    local injure = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:X())
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                            judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)
    end

    local skillLevel = self.m_skillBase:GetLevel()
    if skillLevel >= 3 then
        local B = self.m_skillBase:B()
        local randValue = FixMod(FixRand(), 100)
        if randValue <= B then
            local stunBuff = StatusFactoryInst:NewStatusStun(self.m_giver, FixIntMul(self.m_skillBase:A(), 1000))
            local addSuc = self:AddStatus(performer, target, stunBuff)
            if addSuc then
                local C = self.m_skillBase:C()
                if skillLevel >= 5 and self.m_extraCount < C then
                    self.m_extraCount = FixAdd(self.m_extraCount, 1)
                    self.m_maxCount = FixAdd(self.m_maxCount, 1)
                end
            end
        end
    end

    if self.m_tanCount >= self.m_maxCount then
        self:Over()
    end

    self:ChooseTarget(target)
end

function Medium10152:ChooseTarget(target)
    local logic = CtlBattleInst:GetLogic()
    local enemyTargetIDList = {}
    local enemyCount = 0
    local targetPos = target:GetPosition()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not logic:IsFriend(target, tmpTarget, false) then
                return
            end

            local tmpTargetID = tmpTarget:GetActorID()
            if tmpTargetID == self.m_lastTanTargetID then
                return
            end

            if not IsInCircle(targetPos, 3, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end

            enemyCount = FixAdd(enemyCount, 1)
            table_insert(enemyTargetIDList, tmpTargetID)
        end
    )

    if enemyCount > 0 then
        local index = FixMod(FixRand(), enemyCount)
        index = FixAdd(index, 1)
        self.m_lastTanTargetID = enemyTargetIDList[index]
        self.m_param.targetActorID = self.m_lastTanTargetID
        self.m_tanCount = FixAdd(self.m_tanCount, 1)
    else
        self:Over()
    end
end

return Medium10152