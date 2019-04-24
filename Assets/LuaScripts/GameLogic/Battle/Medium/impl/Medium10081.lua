local BattleEnum = BattleEnum
local Formular = Formular
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixIntMul = FixMath.muli
local FixMod = FixMath.mod
local BattleCameraMgr = BattleCameraMgr
local CtlBattleInst = CtlBattleInst
local FixNormalize = FixMath.Vector3Normalize
local FixRand = BattleRander.Rand
local Vector3New = Vector3.New
local Quaternion = Quaternion

local LinearFlyToPointMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToPointMedium")
local Medium10081 = BaseClass("Medium10081", LinearFlyToPointMedium)

function Medium10081:__init()
    self.m_distance = 0
    self.m_lookAtPos = nil
end

function Medium10081:InitParam(param)
    LinearFlyToPointMedium.InitParam(self, param)

    local performer = self:GetOwner()
    if performer and performer:IsLive() then
        local dir = self.m_param.targetPos - self.m_position
        dir.y = 0
        self.m_distance = dir:Magnitude() 
        local radius = performer:GetRadius()
        if self.m_distance < radius then
            self.m_distance = radius
        end
    end

    self.m_lookAtPos = Vector3New(self.m_param.targetPos.x, self.m_param.targetPos.y, self.m_param.targetPos.z)
end


function Medium10081:MoveToTarget(deltaMS)
    if self.m_param.targetPos == nil then
        return
    end

    local deltaS = FixDiv(deltaMS, 1000)
    self.m_param.speed = FixAdd(self.m_param.speed, FixMul(deltaS, self.m_param.varSpeed))
    
    local moveDis = FixMul(deltaS, self.m_param.speed) 
    local dir = self.m_param.targetPos - self.m_position
    local leftDistance = dir:Magnitude()
    local angle = FixMul(FixDiv(leftDistance, self.m_distance), 50)
    self:Rotate(FixMul(angle, -1), 0, 0)

    if dir:IsZero() then
        return true
    else
        local deltaV = FixNormalize(dir) 
        self:SetNormalizedForward_OnlyLogic(deltaV)

        deltaV:Mul(moveDis) 
        self:MovePosition_OnlyLogic(deltaV)
        self:OnMove(dir)
        self:MoveOnlyShow(moveDis)
        self:LookatPosOnlyShow(self.m_lookAtPos.x, self.m_lookAtPos.y, self.m_lookAtPos.z)

        if self.m_position.y <= self.m_param.targetPos.y or leftDistance <= moveDis then
            return true
        end
    end

    return false
end


function Medium10081:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end
    
    local skillCfg = self:GetSkillCfg()
    if not skillCfg then
        return
    end

    BattleCameraMgr:Shake()
    local v3New = Vector3.New(self.m_param.targetPos.x, self.m_param.targetPos.y, self.m_param.targetPos.z)
    if self.m_param.keyFrame <= 2 then
        performer:AddSceneEffect(100803, v3New, Quaternion.identity)
    else
        performer:AddSceneEffect(100804, v3New, Quaternion.identity)
    end

    local skillLevel = self.m_skillBase:GetLevel()
    local time = 0
    if skillLevel >= 3 then
        time = FixIntMul(self.m_skillBase:A(), 1000)
    end

    local logic = CtlBattleInst:GetLogic()
    local dis2 = skillCfg.dis2
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not logic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not self.m_skillBase:InRange(performer, tmpTarget, nil, self.m_position) then
                return
            end

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:X())
            if injure > 0 then
                local mark = tmpTarget:GetStatusContainer():GetPangtongTiesuoMark()
                if mark then
                    local injureMul = performer:GetTieSuoHurtMul()
                    if injureMul > 0 then
                        injure = FixAdd(injure, FixMul(injure, injureMul))
                    end
                end
                
                local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, self.m_param.keyFrame)
                self:AddStatus(performer, tmpTarget, status)

                if skillLevel >= 3 then
                    local silentStatus = StatusFactoryInst:NewStatusSilent(self.m_giver, time)
                    self:AddStatus(performer, tmpTarget, silentStatus)

                    if skillLevel >= 6 then
                        local randVal = FixMod(FixRand(), 100)
                        if randVal <= self.m_skillBase:B() then
                            performer:AddTieSuoMark(tmpTarget)
                        end
                    end
                end
            end
        end
    )
end

function Medium10081:ArriveDest()
    self:Hurt()
end


return Medium10081