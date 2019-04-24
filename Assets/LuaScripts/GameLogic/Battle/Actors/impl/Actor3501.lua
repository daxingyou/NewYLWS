local FixSub = FixMath.sub
local ConfigUtil = ConfigUtil
local SkillUtil = SkillUtil
local StatusGiver = StatusGiver
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local BattleEnum = BattleEnum

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor3501 = BaseClass("Actor3501", Actor)

function Actor3501:__init(actorID)
    self.m_35013SkillItem = nil
    self.m_35013SkillCfg = nil
    self.m_beginRecover = false
    self.m_35013Y = 0
    self.m_35013MS = 0
end

function Actor3501:PerformSkill35013(leftMS)
    self.m_35013MS = leftMS
end

function Actor3501:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skillItem = self.m_skillContainer:GetActiveByID(35013)
    if skillItem then
        self.m_35013SkillItem = skillItem
        local level = skillItem:GetLevel()
        local skillCfg = ConfigUtil.GetSkillCfgByID(35013)
        if skillCfg then
            self.m_35013SkillCfg = skillCfg
            self.m_35013Y = SkillUtil.Y(skillCfg, level)
        end
    end

end

function Actor3501:ChangeHP(giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)
    Actor.ChangeHP(self, giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)

    if chgVal < 0 and self.m_35013MS > 0 and self:IsLive() then
        local giver = StatusGiver.New(self:GetActorID(), 35013)
        local recoverHP,isBaoji = Formular.CalcRecover(BattleEnum.HURTTYPE_MAGIC_HURT, self, self, self.m_35013SkillCfg, self.m_35013Y)
        local judge = BattleEnum.ROUNDJUDGE_NORMAL
        if isBaoji then
            judge = BattleEnum.ROUNDJUDGE_BAOJI
        end
        local status = StatusFactoryInst:NewStatusDelayHurt(giver, recoverHP, BattleEnum.HURTTYPE_MAGIC_HURT, 0, BattleEnum.HPCHGREASON_BY_SKILL, keyFrame, judge)
        self:GetStatusContainer():Add(status, self)
    end
end

function Actor3501:PreChgHP(giver, chgHP, hurtType, reason)
    chgHP = Actor.PreChgHP(self, giver, chgHP, hurtType, reason)

    if chgHP < 0 then
        local markStatus = self.m_statusContainer:GetQingLongMark()
        if markStatus then
            local targetID = markStatus:GetMarkTargetID()
            local target = ActorManagerInst:GetActor(targetID)
            if target and target:IsLive() then
                local statusHP = StatusFactoryInst:NewStatusDelayHurt(giver, chgHP, hurtType, 0, reason, 0)
                target:GetStatusContainer():Add(statusHP, self)
                chgHP = 0
            end
        end
    end

    return chgHP
end

function Actor3501:LogicUpdate(deltaMS)
    if self.m_35013MS > 0 then
        self.m_35013MS = FixSub(self.m_35013MS, deltaMS)
    end
end

function Actor3501:Reset35013SkillCD()
    if self.m_35013SkillItem then
        self.m_35013SkillItem:SetLeftCD(0)
    end
end

function Actor3501:HasHurtAnim()
    return false
end


function Actor3501:NeedBlood()
    return false
end

function Actor3501:CanBeatBack()
    return false
end


return Actor3501