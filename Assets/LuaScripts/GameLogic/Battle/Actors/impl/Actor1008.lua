local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local BattleEnum = BattleEnum
local FixIntMul = FixMath.muli
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local FixDiv = FixMath.div
local FixMul = FixMath.mul
local SkillUtil = SkillUtil
local FixRand = BattleRander.Rand
local IsInCircle = SkillRangeHelper.IsInCircle
local ConfigUtil = ConfigUtil
local ActorManagerInst = ActorManagerInst
local Formular = Formular
local CtlBattleInst = CtlBattleInst

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1008 = BaseClass("Actor1008", Actor)

function Actor1008:__init()
    self.m_10083SkillItem = nil
    self.m_10083SkillCfg = nil
    self.m_10083Level = 0
    self.m_10083A = 0
    self.m_10083B = 0
    self.m_10083C = 0
    self.m_10083XPercent = 0
    self.m_10083YPercent = 0
end


function Actor1008:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skillItem = self.m_skillContainer:GetPassiveByID(10083)
    if skillItem  then
        self.m_10083SkillItem = skillItem
        local level = skillItem:GetLevel()
        self.m_10083Level = level
        local skillCfg = ConfigUtil.GetSkillCfgByID(10083)
        if skillCfg then
            self.m_10083SkillCfg = skillCfg
            self.m_10083A = SkillUtil.A(skillCfg, level)
            self.m_10083B = FixIntMul(SkillUtil.B(skillCfg, level), 1000)
            self.m_10083C = SkillUtil.C(skillCfg, level)
            self.m_10083XPercent = FixDiv(SkillUtil.X(skillCfg, level), 100)
            if level >= 4 then
                self.m_10083YPercent = FixDiv(SkillUtil.Y(skillCfg, level), 100)
            end
        end
    end
end

function Actor1008:GetTieSuoHurtMul()
    return self.m_10083YPercent
end

function Actor1008:OnHurtOther(other, skillCfg, keyFrame, chgVal, hurtType, judge)
    Actor.OnHurtOther(self, other, skillCfg, keyFrame, chgVal, hurtType, judge)

    if SkillUtil.IsAtk(skillCfg) and self.m_10083SkillItem and self.m_10083SkillCfg then
        local randVal = FixMod(FixRand(), 100)
        if randVal <= self.m_10083A then
            self:AddTieSuoMark(other)
        end
    end
    
    if skillCfg.id ~= 10083 then
        local otherActorID = other:GetActorID()
        ActorManagerInst:Walk(
            function(tmpTarget)
                if tmpTarget:GetActorID() == otherActorID then
                    return
                end

                local mark = tmpTarget:GetStatusContainer():GetPangtongTiesuoMark()
                if mark then
                    local judge = Formular.AtkRoundJudge(self, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
                    if Formular.IsJudgeEnd(judge) then
                        return  
                    end

                    if self.m_10083YPercent > 0 then
                        chgVal = FixAdd(chgVal, FixMul(chgVal, self.m_10083YPercent))
                    end
                    local giver = StatusGiver.New(self:GetActorID(), 10083)
                    local status = StatusFactoryInst:NewStatusDelayHurt(giver, FixMul(chgVal, self.m_10083XPercent), hurtType, 0, BattleEnum.HPCHGREASON_BY_SKILL, keyFrame, judge)
                    tmpTarget:GetStatusContainer():Add(status, self)
                end
            end
        )
    end
end

function Actor1008:AddTieSuoMark(target)
    local logic = CtlBattleInst:GetLogic()
    local targetPos = target:GetPosition()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not logic:IsEnemy(self, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInCircle(targetPos, self.m_10083C, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end

            local judge = Formular.AtkRoundJudge(self, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end
            local giver = StatusGiver.New(self:GetActorID(), 10083)
            local tiesuoMark = StatusFactoryInst:NewStatusPangtongTieSuoMark(giver, self.m_10083B, {100807})
            tiesuoMark:SetMergeRule(StatusEnum.MERGERULE_MERGE)
            tmpTarget:GetStatusContainer():Add(tiesuoMark, self)
        end
    )
end


return Actor1008