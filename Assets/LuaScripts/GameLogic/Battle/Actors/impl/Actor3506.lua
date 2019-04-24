local FixSub = FixMath.sub
local FixMul = FixMath.mul
local FixAdd = FixMath.add
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local ConfigUtil = ConfigUtil
local SkillUtil = SkillUtil
local StatusGiver = StatusGiver
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local ACTOR_ATTR = ACTOR_ATTR
local BattleEnum = BattleEnum

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor3506 = BaseClass("Actor3506", Actor)

function Actor3506:__init(actorID)
    self.m_loseBlood = 0
    self.m_35064skillCfg = nil
    self.m_35064AHP = 0
    self.m_35064X = 0
    self.m_35064B = 0
end

function Actor3506:OnBorn(create_param)
    Actor.OnBorn(self, create_param)
    self.m_baseHP = self:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAXHP)

    local skillItem = self.m_skillContainer:GetPassiveByID(35064)
    if skillItem then
        local level = skillItem:GetLevel()
        local skillCfg = ConfigUtil.GetSkillCfgByID(35064)
        if skillCfg then
            self.m_35064skillCfg = skillCfg
            self.m_35064AHP = FixIntMul(SkillUtil.A(skillCfg, level), FixDiv(self.m_baseHP, 100))
            self.m_35064B = SkillUtil.B(skillCfg, level)
            self.m_35064X = SkillUtil.X(skillCfg, level)
        end
    end
end

function Actor3506:ChangeHP(giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)
    Actor.ChangeHP(self, giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)
    if self:IsLive() and chgVal < 0 then
        self.m_loseBlood = FixAdd(self.m_loseBlood, FixMul(-1, chgVal))
        local chgHp = self.m_35064AHP
        if self.m_loseBlood >= chgHp then
            self.m_loseBlood = FixSub(self.m_loseBlood, chgHp)
            self:AddEffect(350608)
            local factory = StatusFactoryInst
            local statusGiverNew = StatusGiver.New
            local battleLogic = CtlBattleInst:GetLogic()
            ActorManagerInst:Walk(
                function(tmpTarget)
                    if not battleLogic:IsEnemy(self, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                        return
                    end

                    local judge = Formular.AtkRoundJudge(self, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
                    if Formular.IsJudgeEnd(judge) then
                        return  
                    end

                    local giver = statusGiverNew(self:GetActorID(), 35064)
                    local injure = Formular.CalcInjure(self, tmpTarget, self.m_35064skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_35064X)
                    if injure > 0 then
                        local status = factory:NewStatusDelayHurt(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, 0, BattleEnum.HPCHGREASON_BY_SKILL, 0)
                        tmpTarget:GetStatusContainer():Add(status, self)
                    end

                    if tmpTarget:GetStatusContainer():GetTotalShieldValue() <= 0 then
                        local buff = factory:NewStatusStun(giver, FixIntMul(self.m_35064B, 1000))
                        tmpTarget:GetStatusContainer():DelayAdd(buff)
                    end

                end
            )
        end
    end

end

function Actor3506:OnHurtOther(other, skillCfg, keyFrame, chgVal, hurtType, judge)
    Actor.OnHurtOther(self, other, skillCfg, keyFrame, chgVal, hurtType, judge)
    if skillCfg.id == 35062 or not other:IsLive() then
        return
    end
    if chgVal < 0 then
        local curse = self.m_statusContainer:GetXuanWuCurse()
        if curse then
            local targetID = curse:GetCurseTargetID()
            local otherID = other:GetActorID()

            local battleLogic = CtlBattleInst:GetLogic()
            if targetID == otherID then
                ActorManagerInst:Walk(
                    function(tmpTarget)
                        if not battleLogic:IsEnemy(self, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                            return
                        end

                        local judge = Formular.AtkRoundJudge(self, tmpTarget, hurtType, true)
                        if Formular.IsJudgeEnd(judge) then
                            return  
                        end

                        local giver = StatusGiver.New(self:GetActorID(), 35062)
                        local status = StatusFactoryInst:NewStatusDelayHurt(giver, chgVal, hurtType, 0, BattleEnum.HPCHGREASON_BY_SKILL, keyFrame, judge)
                        tmpTarget:GetStatusContainer():Add(status, self)

                    end
                )
            end
        end
    end
end

function Actor3506:HasHurtAnim()
    return false
end

function Actor3506:NeedBlood()
    return false
end

function Actor3506:CanBeatBack()
    return false
end

return Actor3506