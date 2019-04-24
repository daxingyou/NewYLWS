local FixDiv = FixMath.div
local FixNormalize = FixMath.Vector3Normalize
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local Angle = FixMath.Vector3Angle  --角度
local IsInRect = SkillRangeHelper.IsInRect
local FixNewVector3 = FixMath.NewFixVector3

local BattleEnum = BattleEnum
local SKILL_CHK_RESULT = SKILL_CHK_RESULT
local SKILL_TARGET_TYPE = SKILL_TARGET_TYPE
local SKILL_RANGE_TYPE = SKILL_RANGE_TYPE
local SKILL_RELATION_TYPE = SKILL_RELATION_TYPE

local CtlBattleInst = CtlBattleInst
local SkillUtil = SkillUtil
-- local ActorManagerInst = ActorManagerInst -- todo

local SkillBase = BaseClass("SkillBase")

function SkillBase:__init(skill_cfg, level)
    self.m_skillCfg = skill_cfg
    self.m_level = level
end

function SkillBase:__delete()
    self.m_skillCfg = nil
end

function SkillBase:GetSkillCfg()
    return self.m_skillCfg
end

function SkillBase:GetLevel()
    return self.m_level
end

function SkillBase:X()
    return SkillUtil.X(self.m_skillCfg, self.m_level)
end

function SkillBase:A()
    return SkillUtil.A(self.m_skillCfg)
end

function SkillBase:B()
    return SkillUtil.B(self.m_skillCfg)
end

function SkillBase:C()
    return SkillUtil.C(self.m_skillCfg)
end

function SkillBase:D()
    return SkillUtil.D(self.m_skillCfg)
end

function SkillBase:E()
    return SkillUtil.E(self.m_skillCfg)
end

function SkillBase:Y()
    return SkillUtil.Y(self.m_skillCfg, self.m_level)
end

function SkillBase:Z()
    return SkillUtil.Z(self.m_skillCfg, self.m_level)
end

function SkillBase:FlyPoint(performer)
    --todo
end

function SkillBase:BaseCheck(performer, ignoreNuqi)
    if (SkillUtil.IsDazhao(self.m_skillCfg) or SkillUtil.IsActiveSkill(self.m_skillCfg)) and (performer:IsSilent() or performer:IsMagicSilent()) then -- 沉默全部主动技能不能释放
        return SKILL_CHK_RESULT.OTHER
    end

    if self.m_skillCfg.type == SKILL_TYPE.PHY_ATK and not performer:CanPhyAtk() then
        return SKILL_CHK_RESULT.OTHER
    end

    if not ignoreNuqi and SkillUtil.IsDazhao(self.m_skillCfg) then
        if not performer:IsNuqiFull() then
            return SKILL_CHK_RESULT.NUQI_LESS
        end
    end

    if not self:IsFightStatusFit(performer) then
        return SKILL_CHK_RESULT.FIGHT_STATUS_ERR
    end
	
    return SKILL_CHK_RESULT.OK
end

-- return : SKILL_CHK_RESULT, new_target
function SkillBase:CheckPerform(performer, target)
    if not self.m_skillCfg then
        return SKILL_CHK_RESULT.ERR
    end

    local ret = self:BaseCheck(performer)
    if ret ~= SKILL_CHK_RESULT.OK then
        return ret
    end

    local chkTarget = false
    if self.m_skillCfg.targettype == SKILL_TARGET_TYPE.CURRENT_TARGET then
        chkTarget = true
    end

    -- perform to curr target
    if chkTarget then
        local dir = target:GetPosition() - performer:GetPosition()
        dir.y = 0

        if not self:InRange(performer, target, dir, target:GetPosition()) then
            return SKILL_CHK_RESULT.TOO_FAR
        end

        if not self:IsRelationshipFit(performer, target, BattleEnum.RelationReason_SKILL_OTHER) then
            return SKILL_CHK_RESULT.TARGET_TYPE_UNFIT
        end
    else
        if self.m_skillCfg.targettype == SKILL_TARGET_TYPE.ANY then
            local tmpTarget = self:Reselect(performer, nil)
            if not tmpTarget then
                return SKILL_CHK_RESULT.OTHER
            end
            
            return SKILL_CHK_RESULT.RESELECT, tmpTarget
        end
    end

    -- if self.m_skillCfg.reselect == 1 then
    --     local newTarget = self:Reselect(performer, target)
    --     if newTarget then
    --         return SKILL_CHK_RESULT.RESELECT, newTarget
    --     end

    --     return SKILL_CHK_RESULT.OTHER
    -- end

    return SKILL_CHK_RESULT.OK
end

-- return : SKILL_CHK_RESULT, target_array[actor]
function SkillBase:GetTargetList(performer, performPos, performTarget, checkValid)
    if not self.m_skillCfg then
        return SKILL_CHK_RESULT.ERR
    end

    if checkValid then
        local ret = self:BaseCheck(performer)
        if ret ~= SKILL_CHK_RESULT.OK then
            return ret
        end
    end

    local targetList = nil

    if self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.RECT or self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.RECT_IN_CIRCLE then
        local performDir = performPos - performer:GetPosition()
        performDir.y = 0
        targetList = self:GetRectTarget(performer, performDir, performPos)

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.LINE or self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.INFINITE_LINE then
        local performDir = performPos - performer:GetPosition()
        targetList = self:GetLineTarget(performer, performDir, performer:GetPosition())

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.SINGLE_TARGET then
        if performTarget and performTarget:IsLive() then
            local performDir = performPos - performer:GetPosition()
            performDir.y = 0
            if self:InRange(performer, performTarget, performDir, performPos) then
                return SKILL_CHK_RESULT.OK, {performTarget}
            end
        end

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.ZHUGELIANG_FLAGS then     --todo 可能没用
        return SKILL_CHK_RESULT.ERR
    else
        if self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.LOLLIPOP2 then
            if not performTarget or not performTarget:IsLive() then
                return SKILL_CHK_RESULT.OTHER
            end
        end

        local performDir = performPos - performer:GetPosition()
        performDir.y = 0

        targetList = ActorManagerInst:GetActorList(
            function(tmpTarget)
                if not self:IsRelationshipFit(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                    return false
                end

                if not self:InRange(performer, tmpTarget, performDir, performPos) then
                    return false
                end

                return true
            end
        )
        
    end
   
    if targetList and #targetList > 0 then
        return SKILL_CHK_RESULT.OK, targetList
    end

    return SKILL_CHK_RESULT.OTHER
end

-- return : targetList
function SkillBase:GetLineTarget(performer, performDir, performPos)
    if self.m_skillCfg == nil then return end

    local widthHalf = FixDiv(self.m_skillCfg.dis1, 2)
    local heightHalf = FixDiv(self.m_skillCfg.dis2, 2)

    performDir.y = 0

    local normalizedDir = FixNormalize(performDir)

    local tmpDir = normalizedDir * heightHalf
    tmpDir:Add(performPos)

    return ActorManagerInst:GetActorList(
        function(tmpTarget)
            if not self:IsRelationshipFit(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return false
            end

            if not IsInRect(tmpTarget:GetPosition(), tmpTarget:GetRadius(), widthHalf, heightHalf, tmpDir, normalizedDir) then
                return false
            end

            return true
        end
    )
end

-- return : targetList
function SkillBase:GetRectTarget(performer, performDir, performPos)
    if self.m_skillCfg == nil then return end

    local widthHalf = FixDiv(self.m_skillCfg.dis1, 2)
    local heightHalf = FixDiv(self.m_skillCfg.dis2, 2)

    performDir.y = 0
    
    local normalizedDir = FixNormalize(performDir)

    return ActorManagerInst:GetActorList(
        function(tmpTarget)
            if not self:IsRelationshipFit(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return false
            end

            if not IsInRect(tmpTarget:GetPosition(), tmpTarget:GetRadius() , widthHalf, heightHalf, performPos, normalizedDir) then
                return false
            end

            return true
        end
    )
end

function SkillBase:CheckAgain(skillID, skillLevel, performer, target)
    return SKILL_CHK_RESULT.OK
end

function SkillBase:InRange(performer, target, performDir, performPos)
    if not self.m_skillCfg then return false end
    if not performer or not target then return false end

    local performerPos = performer:GetPosition()
    local targetPos = target:GetPosition()

    if self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.RING then
        local tmpVec = performerPos - targetPos
        local disSqr = tmpVec:SqrMagnitude()
        local far = CtlBattleInst:GetLogic():GetSkillDistance(self.m_skillCfg.dis2)
        local farSqr = FixMul(far, far)
        return disSqr >= self.m_skillCfg.disSqr1 and disSqr <= farSqr

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.SECTOR then
        local targetDir = targetPos - performerPos
        targetDir.y = 0
        local disSqr = targetDir:SqrMagnitude()
        local battleLogic = CtlBattleInst:GetLogic()
        local far = battleLogic:GetSkillDistance(self.m_skillCfg.dis2)
        local farSqr = FixMul(far, far)

        if disSqr >= self.m_skillCfg.disSqr1 and disSqr <= farSqr then
            local degrees = Angle(targetDir, performDir)
            local maxDegrees = battleLogic:GetSkillAngle(self.m_skillCfg.angle)
            local halfMax = FixDiv(maxDegrees, 2)
            return degrees <= halfMax
        end

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.CIRCLE then
        local targetDir = targetPos - performPos
        targetDir.y = 0
        local disSqr = targetDir:SqrMagnitude()
        local far = CtlBattleInst:GetLogic():GetSkillDistance(self.m_skillCfg.dis2)
        local farSqr = FixMul(far, far)
        return disSqr <= farSqr

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.SINGLE_TARGET then
        local targetDir = targetPos - performPos
        targetDir.y = 0
        local disSqr = targetDir:SqrMagnitude()
        local far = CtlBattleInst:GetLogic():GetSkillDistance(self.m_skillCfg.dis1)
        local farSqr = FixMul(far, far)
        return disSqr <= farSqr

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.LINE then
        local halfDis1 = FixDiv(self.m_skillCfg.dis1, 2)
        local halfDis2 = FixDiv(self.m_skillCfg.dis2, 2)
        local normalizedPerformDir = FixNormalize(performDir)
        local tmpDir = normalizedPerformDir * halfDis2
        tmpDir:Add(performPos)
        return IsInRect(targetPos, target:GetRadius(), halfDis1, halfDis2, tmpDir, normalizedPerformDir)

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.RECT or self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.RECT_IN_CIRCLE then
        local halfDis1 = FixDiv(self.m_skillCfg.dis1, 2)
        local halfDis2 = FixDiv(self.m_skillCfg.dis2, 2)
        local normalizedPerformDir = FixNormalize(performDir)
        return IsInRect(targetPos, target:GetRadius(), halfDis1, halfDis2, performPos, normalizedPerformDir)
        
    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.LOLLIPOP then
        local targetDir = targetPos - performPos
        targetDir.y = 0
        local dis2 = targetDir:SqrMagnitude()
        local far = CtlBattleInst:GetLogic():GetSkillDistance(self.m_skillCfg.dis2)
        local farSqr = FixMul(far, far)
        if dis2 <= farSqr then
            return true
        end

        local dir = performPos - performerPos
        dir.y = 0
        local distance = dir:Magnitude()
        local height = FixSub(distance, self.m_skillCfg.dis2)
        local halfDis1 = FixDiv(self.m_skillCfg.dis3, 2)
        local halfDis2 = FixDiv(height, 2)
        local normalizedPerformDir = FixNormalize(performDir)
        local tmpDir = normalizedPerformDir * halfDis2
        tmpDir:Add(performerPos)        
        return IsInRect(targetPos, target:GetRadius(), halfDis1, halfDis2, tmpDir, normalizedPerformDir)

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.LOLLIPOP2 then
        local targetDir = targetPos - performPos
        targetDir.y = 0
        local dis2 = targetDir:SqrMagnitude()
        local far = CtlBattleInst:GetLogic():GetSkillDistance(self.m_skillCfg.dis1)
        local farSqr = FixMul(far, far)
        if dis2 > farSqr then
            return false
        end
        
        local dir = performPos - performerPos
        dir.y = 0
        local distance = dir:Magnitude()
        local height = distance
        local halfDis1 = FixDiv(self.m_skillCfg.dis2, 2)
        local halfDis2 = FixDiv(height, 2)
        local normalizedPerformDir = FixNormalize(performDir)
        local tmpDir = normalizedPerformDir * halfDis2
        tmpDir:Add(performerPos)        
        return IsInRect(targetPos, target:GetRadius(), halfDis1, halfDis2, tmpDir, normalizedPerformDir)

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.SECTOR_RING then
        local normalizedPerformDir = FixNormalize(performDir)
        performerPos = performerPos - normalizedPerformDir * self.m_skillCfg.dis3
       
        local targetDir = targetPos - performerPos
        targetDir.y = 0
        local disSqr = targetDir:SqrMagnitude()
        local battleLogic = CtlBattleInst:GetLogic()
        local far = battleLogic:GetSkillDistance(self.m_skillCfg.dis2)
        local farSqr = FixMul(far, far)

        if disSqr >= self.m_skillCfg.disSqr3 and disSqr <= farSqr then
            local degrees = Angle(targetDir, performDir)
            local maxDegrees = battleLogic:GetSkillAngle(self.m_skillCfg.angle)
            local halfMax = FixDiv(maxDegrees, 2)
            if degrees <= halfMax then
                return true
            end
        end

    elseif self.m_skillCfg.validrangetype == SKILL_RANGE_TYPE.HALF_CIRCLE then
        local targetDir = targetPos - performerPos
        targetDir.y = 0
        local disSqr = targetDir:SqrMagnitude()
        local battleLogic = CtlBattleInst:GetLogic()
        local far = battleLogic:GetSkillDistance(self.m_skillCfg.dis2)
        far = FixAdd(far, target:GetRadius())
        local farSqr = FixMul(far, far)

        if disSqr <= farSqr then
            local degrees = Angle(targetDir, performDir)
            local maxDegrees = battleLogic:GetSkillAngle(180)
            local halfMax = FixDiv(maxDegrees, 2)
            return degrees <= halfMax
        end
    end

    return false
end

function SkillBase:IsRelationshipFit(performer, target, reason)
    if not self.m_skillCfg then return false end

    if self.m_skillCfg.relationship == SKILL_RELATION_TYPE.NONE then
        return false
    end

    if self.m_skillCfg.relationship == SKILL_RELATION_TYPE.ENEMY then
        return CtlBattleInst:GetLogic():IsEnemy(performer, target, reason)
    end

    if self.m_skillCfg.relationship == SKILL_RELATION_TYPE.FRIEND_WITH_SELF then
        return CtlBattleInst:GetLogic():IsFriend(performer, target, true)
    end

    if self.m_skillCfg.relationship == SKILL_RELATION_TYPE.FRIEND_WITHOUT_SELF then
        return CtlBattleInst:GetLogic():IsFriend(performer, target, false)
    end

    if self.m_skillCfg.relationship == SKILL_RELATION_TYPE.SELF then
        return true
    end

    return false
end

function SkillBase:IsFightStatusFit(performer)
    return CtlBattleInst:IsInFight()
end

function SkillBase:Reselect(performer, exceptTarget)
    return ActorManagerInst:GetOneActor(
        function(tmpTarget)
            if tmpTarget == exceptTarget then
                return false
            end

            if not tmpTarget:IsLive() then
                return false
            end

            if not self:IsRelationshipFit(performer, tmpTarget, BattleEnum.RelationReason_SELECT_TARGET) then
                return false
            end

            local targetPos = tmpTarget:GetPosition()
            local dir = targetPos - performer:GetPosition()
            dir.y = 0
            if not self:InRange(performer, tmpTarget, dir, targetPos) then
                return false
            end

            return true
        end
    )
end

function SkillBase:Perform(performer, target, performPos, special_param)
end

function SkillBase:Preperform(performer, target, performPos)
    return 0
end

function SkillBase:OnActionStart(performer, target, perfromPos)
end

function SkillBase:AddStatus(performer, target, status, prob, onlyInFight)
    if not target or not status then 
        return false 
    end
    
    if onlyInFight == nil then
        onlyInFight = true
    end

    local battleLogic = CtlBattleInst:GetLogic()
    if battleLogic then
        if not battleLogic:CanAddStatus(performer, target, status, onlyInFight) then
            return false
        end
    end
    
    return target:GetStatusContainer():Add(status, performer, prob)
end

-- return : targetActor, pos
function SkillBase:SelectSkillTarget(performer, target)
    return nil, nil
end

function SkillBase:OnFightStart(performer, currWave)
end


function SkillBase:GetCenterInRange(performer, rangeSqr, isEnemy, includeSelf)
    if not performer then return nil end
    if includeSelf == nil then includeSelf = true end

    local tmpV = FixNewVector3(0, 0, 0)
    local actorCount = 0
    local performerPos = performer:GetPosition()
    local battleLogic = CtlBattleInst:GetLogic()

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not tmpTarget:IsLive() then
                return false
            end

            local targetPos = tmpTarget:GetPosition()
            local tmpDir = performerPos - targetPos
            local disSqr = tmpDir:SqrMagnitude()
            if disSqr > rangeSqr then
                return false
            end

            if isEnemy then
                if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                    return false
                end
            else
                if not battleLogic:IsFriend(performer, tmpTarget, includeSelf) then
                    return false
                end
            end

            tmpV:Add(targetPos)
            actorCount = FixAdd(actorCount, 1)
        end
    )

    if actorCount > 0 then
        tmpV:Div(actorCount)
        return tmpV
    end

    return nil
end

function SkillBase:GetMinHPActor(isFriend, performer, includeSelf)
    local minTarget = nil
    local minHPPercent = 10000

    local battleLogic = CtlBattleInst:GetLogic()

    ActorManagerInst:Walk(
        function(tmpTarget)
            if isFriend then
                if not battleLogic:IsFriend(performer, tmpTarget, includeSelf) then
                    return false
                end
            else
                if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_OTHER) then
                    return false
                end
            end

            local targetData = tmpTarget:GetData()

            local tmpPercent = FixDiv(targetData:GetAttrValue(ACTOR_ATTR.FIGHT_HP), targetData:GetAttrValue(ACTOR_ATTR.FIGHT_MAXHP))
            if tmpPercent < minHPPercent then
                minTarget = tmpTarget
                minHPPercent = tmpPercent
            end
        end
    )

    return minTarget
end

function SkillBase:GetMaxHPActor(isFriend, performer, includeSelf)
    local maxTarget = nil
    local maxHPPercent = -1

    local battleLogic = CtlBattleInst:GetLogic()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if isFriend then
                if not battleLogic:IsFriend(performer, tmpTarget, includeSelf) then
                    return false
                end
            else
                if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_OTHER) then
                    return false
                end
            end

            local targetData = tmpTarget:GetData()
            local tmpPercent = FixDiv(targetData:GetAttrValue(ACTOR_ATTR.FIGHT_HP), targetData:GetAttrValue(ACTOR_ATTR.FIGHT_MAXHP))
            if tmpPercent > maxHPPercent then
                maxTarget = tmpTarget
                maxHPPercent = tmpPercent
            end
        end
    )

    return maxTarget
end

return SkillBase