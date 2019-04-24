local ConfigUtil = ConfigUtil
local BattleEnum = BattleEnum
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst


local AIManual = require "GameLogic.Battle.AI.AIManual"
local AIShuiyao = BaseClass("AIShuiyao", AIManual)


function AIShuiyao:__init(actor)
    self.m_20611skillItem = self.m_selfActor:GetSkillContainer():GetActiveByID(20611)
    self.m_performed20611 = false
    self.m_20611TargetID = 0
end

function AIShuiyao:__delete()
    self.m_20611skillItem = nil
    self.m_performed20611 = false
    self.m_20611TargetID = 0
end

function AIShuiyao:Attack(targetID)
    self.m_currTargetActorID = targetID
end

function AIShuiyao:AI(deltaMS)
    if not self:CheckSpecialState(deltaMS) then
        return
    end

    if not self:CanAI() then
        return
    end

    if not self.m_performed20611 and self.m_20611skillItem and self.m_20611TargetID > 0 then
        self.m_performed20611 = true
        local target = ActorManagerInst:GetActor(self.m_20611TargetID)
        self.m_20611TargetID = 0
        if target and target:IsLive() then
            self:PerformSkill(target, self.m_20611skillItem, target:GetPosition(), SKILL_PERFORM_MODE.AI)
        end
        return
    end

    local currState = self.m_selfActor:GetCurrStateID()
    if currState == BattleEnum.ActorState_IDLE or currState == BattleEnum.ActorState_MOVE then  
        if self.m_currTargetActorID == 0 then
            local tmpTarget = self:FindTarget()
            if not tmpTarget then
                self:OnNoTarget()
            else
                self:SetTarget(tmpTarget:GetActorID())
            end
        end

        if self.m_currTargetActorID ~= 0 then
            local target = ActorManagerInst:GetActor(self.m_currTargetActorID)
            if not target or not target:IsLive() then
                self:SetTarget(0)
                return
            end

            local selfProf = self.m_selfActor:GetProf()
            if selfProf == CommonDefine.PROF_1 or selfProf == CommonDefine.PROF_3 then
                if target:GetProf() == CommonDefine.PROF_2 then
                    local profTarget = CtlBattleInst:GetLogic():GetNearestProfTarget(self.m_selfActor)
                    if profTarget then
                        self:SetTarget(profTarget:GetActorID())
                        target = profTarget

                    end
                end
            end

            local p = target:GetPosition()
            local selectSkill, chkRet = self:SelectSkill(target, self:AutoSelectDazhao())

            if selectSkill and chkRet then
                if chkRet.newTarget then
                    self:SetTarget(chkRet.newTarget:GetActorID())
                    target = chkRet.newTarget
                end
                p = chkRet.pos
            end
            
            local normalRet = SKILL_CHK_RESULT.ERR
            if not selectSkill then
                normalRet, selectSkill = self:SelectNormalSkill(target)
            end

            if selectSkill then
                self:PerformSkill(target, selectSkill, p, SKILL_PERFORM_MODE.AI)
            else
                if normalRet == SKILL_CHK_RESULT.TARGET_TYPE_UNFIT then
                    self:SetTarget(0)
                end

                if self:ShouldFollowEnemy(normalRet) then
                    
                    self:Follow(target, deltaMS)
                elseif self:ShouldBackAway(target) then
                    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_selfActor:GetWujiangID())
                    self:BackAway(target, wujiangCfg.backaway_dis)                
                else
                    self:TryStop(target:GetPosition())
                end
            end
        end
    end
end


function AIShuiyao:PerformJL(targetID)
    self.m_performed20611 = false
    self.m_20611TargetID = targetID
end



function AIShuiyao:SelectSkill(target, includeDazhao)
    return nil 
end


return AIShuiyao