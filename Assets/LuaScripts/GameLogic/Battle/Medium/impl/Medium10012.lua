local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local BattleEnum = BattleEnum
local table_insert = table.insert
local Formular = Formular
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst

local ACTOR_ATTR = ACTOR_ATTR
local FixNormalize = FixMath.Vector3Normalize
local IsInRect = SkillRangeHelper.IsInRect
local V3Impossible = FixVecConst.impossible()
local StatusFactoryInst = StatusFactoryInst

local LinearFlyToPointMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToPointMedium")
local Medium10012 = BaseClass("Medium10012", LinearFlyToPointMedium)


function Medium10012:InitParam(param)
    LinearFlyToPointMedium.InitParam(self, param)

    self.m_goOnMove = false
    self.m_timeSinceStart = 0
    self.m_speedAdd = 0
end

function Medium10012:DoUpdate(deltaMS)
    local owner = self:GetOwner()
    if not owner or not owner:IsLive() then
        self:Over()
        return 
    end

    if self:GetTargetPos() == V3Impossible then
        self:Over()
        return
    end

    if self.m_timeSinceStart >= 1100 then
        self:Over()
        return
    end
    self.m_timeSinceStart = FixAdd(self.m_timeSinceStart, deltaMS)

    if self:MoveToTarget(deltaMS) then
        self:ArriveDest()
        return
    end
end

function Medium10012:MoveToTarget(deltaMS)
    if self.m_param.targetPos == nil then
        -- print("self.m_param.targetPos nil")
        return false
    end

    local performer = self:GetOwner()
    if not performer then
        return false
    end

    -- local deltaS = FixDiv(deltaMS, 1000)
    local deltaS = FixDiv(deltaMS, 800)
    self.m_speedAdd = FixMul(self.m_param.speed, deltaS)
    
    local moveDis = FixMul(deltaS, self.m_param.speed) 

    if self.m_goOnMove then
        self.m_param.speed = FixSub(self.m_param.speed, self.m_speedAdd)
        local deltaV = self:GetForward() * moveDis 
        self:MovePosition(deltaV)
        return false
    end

    self.m_param.speed = FixAdd(self.m_param.speed, self.m_speedAdd)

    local dir = self.m_param.targetPos - self.m_position
    dir.y = 0
    local leftDistance2 = dir:SqrMagnitude()

    if leftDistance2 < FixMul(moveDis, moveDis) then
        self.m_goOnMove = true
        return true
    end

    local deltaV = FixNormalize(dir) 
    deltaV:Mul(moveDis)

    self:SetForward(dir)
    self:MovePosition(deltaV)
    self:OnceMove(performer, moveDis)

    return false
end

function Medium10012:OnceMove(performer, moveDis)
    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    if not battleLogic or not skillCfg or not self.m_skillBase then
        return
    end

    local statusGiverNew = StatusGiver.New
    local factory = StatusFactoryInst
    
    local normalizedDir = self:GetForward()
    local pos = self.m_position + normalizedDir
    local half1 = FixDiv(skillCfg.dis1, 2)
    
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            -- dis1 宽
            -- IsInRect = function(targetPos, targetRadius, widthHalf, heightHalf, rectCenter, normalizedDir)
            if not IsInRect(tmpTarget:GetPosition(), tmpTarget:GetRadius(), half1, 1 , pos, normalizedDir) then
                return
            end

            tmpTarget:OnBeatBack(performer, moveDis)

            if self.m_skillBase:GetLevel() >= 2 then 
                local performerCurHP = performer:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
                local targetCurHP = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
                if targetCurHP < performerCurHP then
                    local giver = statusGiverNew(performer:GetActorID(), 10012)
                    local stunBuff = factory:NewStatusStun(giver, FixMul(self.m_skillBase:A(), 1000))
                    self:AddStatus(performer, tmpTarget, stunBuff)
                end
            end

        end
    )
end

function Medium10012:ArriveDest()
    local performer = self:GetOwner()
    if not performer then
        self:Over()
        return
    end

    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    if not battleLogic or not skillCfg or not self.m_skillBase then
        return
    end

    local normalizedDir = self:GetForward()

    local pos = self.m_position + normalizedDir
    local half1 = FixDiv(skillCfg.dis1, 2)

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            -- dis1 宽  
            -- IsInRect = function(targetPos, targetRadius, widthHalf, heightHalf, rectCenter, normalizedDir)
            if not IsInRect(tmpTarget:GetPosition(), tmpTarget:GetRadius(), half1, 1 , pos, normalizedDir) then
                return
            end

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return
            end

            -- 2米测试
            local skillItem = performer:GetSkillContainer():GetActiveByID(10012)
            local backDistance = 0
            if skillItem  then
                local skillLevel = skillItem:GetLevel()
                local skillCfg = ConfigUtil.GetSkillCfgByID(10012)
                if skillCfg then
                    backDistance = SkillUtil.D(skillCfg, skillLevel)
                end
            end
            
            tmpTarget:OnBeatBack(performer, backDistance)

            local phyInjure = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:X())
            if phyInjure > 0 then
                local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(phyInjure, -1), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                        judge, self.m_param.keyFrame)
                self:AddStatus(performer, tmpTarget, status)
            end
        end
    )

end



return Medium10012