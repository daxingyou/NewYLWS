
local FixMul = FixMath.mul
local FixAdd = FixMath.add
local AIManual = require "GameLogic.Battle.AI.AIManual"
local base = AIManual

local SKILL_PERFORM_MODE = SKILL_PERFORM_MODE
local SKILL_CHK_RESULT = SKILL_CHK_RESULT
local BattleEnum = BattleEnum
local CommonDefine = CommonDefine

local AIStandByDeadCount = BaseClass("AIStandByDeadCount", AIManual)

local MonsterInFightRule =
{
    INVALID = 0,
    DIE_COUNT = 1,
    BOSS_HP_LEFT_PERCENT = 2,
    ROLE_ENTER_ZONE = 3,
}

function AIStandByDeadCount:__init(actor)    
    self.m_isFighting = false
    self.m_checkInterval = 0
    self.m_showableInCamera = false
end

function AIStandByDeadCount:ShowableInCamera()
    return self.m_showableInCamera
end

function AIStandByDeadCount:AI(deltaMS)
    if not self:CheckSpecialState(deltaMS) then
        return
    end

    if not self:CanAI() then
        return
    end

    if not self:IsFighting() then
        self:CheckCondition(deltaMS)
        return
    end

    if not self:IsFighting() then
        return
    end

    base.AI(self, deltaMS)
end

function AIStandByDeadCount:Fight()	    
    if not self.m_isFighting then
        self.m_selfActor:ResetSkillFirstCD(0, 500)
        self:ResetFightTime()
    end

    self.m_isFighting = true

    BattleCameraMgr:OnStandbyActorFighting(self.m_selfActor:GetActorID())
end

function AIStandByDeadCount:IsFighting()
    return self.m_isFighting
end

function AIStandByDeadCount:PerformSkill(target, skillItem, pos, performMode)
    base.PerformSkill(self, target, skillItem, pos, performMode)
    self.m_showableInCamera = true
end


function AIStandByDeadCount:OnAtked(giver, deltaHP, reason)
    self:Fight()
end

function AIStandByDeadCount:OnSBHurtFlyAway(pos)
    local dir = pos - self.m_selfActor:GetPosition()
    dir.y = 0

    local disSqr = dir:SqrMagnitude()
    if disSqr <= FixMul(self.m_selfActor:GetSkillContainer():GetAtkableDisSqr(), 0.8) then
        self:Fight()
    end
end

function AIStandByDeadCount:CheckFightCond(checkReason, checkParam)
    if not self.m_param then
        return false
    end

    local rule, param = self.m_param[1], self.m_param[2]
    if not rule or not param then
        return false
    end

    if checkReason == BattleEnum.STANDBY_CHECKREASON_MONSTER_DIE and rule == MonsterInFightRule.DIE_COUNT then
        if checkParam >= param then
            self:Fight()
            return true
        end

    elseif checkReason == BattleEnum.STANDBY_CHECKREASON_BOSS_HP and rule == MonsterInFightRule.BOSS_HP_LEFT_PERCENT then
        if checkParam <= param then
            self:Fight()
            return true
        end
        
    elseif checkReason == BattleEnum.STANDBY_CHECKREASON_ENTER_ZONE and rule == MonsterInFightRule.ROLE_ENTER_ZONE then
        if checkParam == param then
            self:Fight()
            return true
        end
    end

    return false
end

function AIStandByDeadCount:CheckCondition(deltaMS)
    if self.m_checkInterval == 0 or self.m_checkInterval >= 500 then
        self.m_checkInterval = 0

        local tmpTarget = self:FindByRange(true)
        if tmpTarget then
            self:Fight()
        end
    end

    self.m_checkInterval = FixAdd(self.m_checkInterval, deltaMS)
end

return AIStandByDeadCount