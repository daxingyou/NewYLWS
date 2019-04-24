local ConfigUtil = ConfigUtil
local SkillCheckResult = SkillCheckResult
local SkillUtil = SkillUtil
local SkillPoolInst = SkillPoolInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local BattleEnum = BattleEnum

local AIManual = require "GameLogic.Battle.AI.AIManual"
local AIHundun = BaseClass("AIHundun", AIManual)


function AIHundun:AI(deltaMS)
    if not self:CheckSpecialState(deltaMS) then
        return
    end

    if not self:CanAI() then
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

            local p = target:GetPosition()
            local selectSkill, chkRet = self:SelectSkill(target, self:AutoSelectDazhao())

            if selectSkill and selectSkill:GetID() == 20312 and self.m_selfActor:IsRightHandDead() then
                return
            end
            
            if selectSkill and selectSkill:GetID() == 20313 and self.m_selfActor:IsLeftHandDead() then
                return
            end
            
            if selectSkill and chkRet then
                if chkRet.newTarget then
                    self:SetTarget(chkRet.newTarget:GetActorID())
                    target = chkRet.newTarget
                end
                -- p = chkRet.pos

                p = self.m_selfActor:GetPosition()
                self:PerformSkill(target, selectSkill, p, SKILL_PERFORM_MODE.AI)
            end
        end
    end
end


function AIHundun:SelectSkill(target, includeDazhao)
    if not target then return nil end
    if includeDazhao == nil then includeDazhao = true end

    if not self.m_selfActor:GetStatusContainer():CanAnySkill() then
        return nil
    end

    local skillContainer = self.m_selfActor:GetSkillContainer()
    local GetSkillCfgByID = ConfigUtil.GetSkillCfgByID

    local selectSkill = skillContainer:GetNextSkill()
    if selectSkill then
        return selectSkill, SkillCheckResult.New(target, target:GetPosition())
    end

    local IsDazhao = SkillUtil.IsDazhao
    local skillPool = SkillPoolInst
    local skillCount = skillContainer:GetActiveCount()
    for i = 1, skillCount do
        local skillItem = skillContainer:GetActiveByIdx(i)
        if skillItem then
            local skillcfg = GetSkillCfgByID(skillItem:GetID())
            if skillcfg then
                if IsDazhao(skillcfg) and self:IsCDOK(skillItem) then
                    if self.m_selfActor:CanDaZhao(false) then
                        if self.m_inFightMS >= CtlBattleInst:GetLogic():GetDazhaoFirstCD() then
                            local skillbase = skillPool:GetSkill(skillcfg, skillItem:GetLevel())
                            if skillbase then
                                local tmpRet = skillbase:BaseCheck(self.m_selfActor, false)
                                if tmpRet == SKILL_CHK_RESULT.OK then
                                    local ret, skChkRet = self:CheckDazhao(skillbase, skillcfg, target)
                                    if ret then
                                        return skillItem, skChkRet
                                    end
                                end
                            end
                        end
                    end

                elseif (skillcfg.id == 20312 and not self.m_selfActor:IsRightHandDead()) or (skillcfg.id == 20313 and not self.m_selfActor:IsLeftHandDead()) then
                    if self:InnerCheck(skillItem, skillcfg, includeDazhao, target) then
                        local skillbase = skillPool:GetSkill(skillcfg, skillItem:GetLevel())
                        if skillbase then 
                            local tmpRet, newTarget = skillbase:CheckPerform(self.m_selfActor, target)
                            if tmpRet == SKILL_CHK_RESULT.OK then
                                return skillItem, SkillCheckResult.New(target, target:GetPosition())
                            elseif tmpRet == SKILL_CHK_RESULT.RESELECT then
                                return skillItem, SkillCheckResult.New(newTarget, newTarget:GetPosition())
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

return AIHundun