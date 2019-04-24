local FixIntMul = FixMath.muli
local FixAdd = FixMath.add
local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixFloor = FixMath.floor
local SkillUtil = SkillUtil
local ConfigUtil = ConfigUtil
local ACTOR_ATTR = ACTOR_ATTR
local IsInCircle = SkillRangeHelper.IsInCircle
local StatusFactoryInst = StatusFactoryInst
local CtlBattleInst = CtlBattleInst
local StatusGiver = StatusGiver
local ActorManagerInst = ActorManagerInst
local BattleEnum = BattleEnum
local Formular = Formular

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1217 = BaseClass("Actor1217", Actor)

function Actor1217:__init()
    self.m_12173A = 0
    self.m_12173AHP = 0
    self.m_12173B = 0
    self.m_12173X = 0
    self.m_12173YPercent = 0
    self.m_12173Level = 0
    self.m_12173SkillCfg = nil
    self.m_isPerformSkill12173 = false

    self.m_12172SkillItem = nil 
    self.m_12172SkillCfg = nil
    self.m_12172Y = 0
    self.m_12172A = 0
    self.m_12172C = 0
    self.m_12172Level = 0
    self.m_12172TargetID = 0

    self.m_chgHP = 0
    self.m_baseHP = 0
    self.m_chgPhySuck = 0
    self.m_chgMagicSuck = 0
    self.m_baojiJudge = false
    self.m_attrMul = 0

    self.m_isFightEnd = false
end

function Actor1217:OnBorn(create_param)
    Actor.OnBorn(self, create_param)
    
    self.m_baseHP = self:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAXHP)

    self.m_12172SkillItem = self.m_skillContainer:GetActiveByID(12172)
    if self.m_12172SkillItem then
        self.m_12172SkillCfg = ConfigUtil.GetSkillCfgByID(12172)
        self.m_12172Level = self.m_12172SkillItem:GetLevel()
        if self.m_12172SkillCfg then
            if self.m_12172Level >= 3 then
                self.m_12172A = FixIntMul(SkillUtil.A(self.m_12172SkillCfg, self.m_12172Level), 1000)
            end
            self.m_12172Y = SkillUtil.Y(self.m_12172SkillCfg, self.m_12172Level)
            self.m_12172C = SkillUtil.C(self.m_12172SkillCfg, self.m_12172Level)
        end
    end

    local skillItem = self.m_skillContainer:GetPassiveByID(12173)
    if skillItem  then
        self.m_12173Level = skillItem:GetLevel()
        local skillCfg = ConfigUtil.GetSkillCfgByID(12173)
        self.m_12173SkillCfg = skillCfg
        if skillCfg then
            -- self.m_12173A = SkillUtil.A(skillCfg, self.m_12173Level)
            self.m_12173AHP = FixIntMul(FixDiv(SkillUtil.A(skillCfg, self.m_12173Level), 100), self.m_baseHP)
            self.m_12173X = SkillUtil.X(skillCfg, self.m_12173Level)
            self.m_12173B = FixIntMul(SkillUtil.B(self.m_12173SkillCfg, self.m_12173Level), 1000)
            if self.m_12173Level >= 5 then
                self.m_12173YPercent = FixDiv(SkillUtil.Y(skillCfg, self.m_12173Level), 100)
            end
        end
    end

    if self.m_12173Level >= 5 then
        self.m_chgPhySuck = self.m_12173YPercent
        self.m_chgMagicSuck = self.m_12173YPercent
    end
end


function Actor1217:ChangeHP(giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)
    Actor.ChangeHP(self, giver, hurtType, chgVal, reason, judge, keyFrame, showHit, showText)

    if self:IsLive() and self.m_12173SkillCfg and chgVal < 0 then
        local lastChg = self.m_chgHP
        self.m_chgHP = FixAdd(self.m_chgHP, FixIntMul(chgVal, -1))
        if self.m_chgHP > self.m_12173AHP then
            self.m_attrMul = FixFloor(FixDiv(self.m_chgHP, self.m_12173AHP))
            self.m_isPerformSkill12173 = true
            self.m_chgHP = FixSub(self.m_chgHP, FixIntMul(self.m_12173AHP, self.m_attrMul))
        end
    end
end


function Actor1217:LogicUpdate(deltaMS)
    if self.m_isPerformSkill12173 then
        self:PerformSkill12173()
        self.m_isPerformSkill12173 = false
    end

    if self.m_active12172 then
        self:Active12172()
        self.m_active12172 = false
    end
end


function Actor1217:PerformSkill12173()
    if not self:IsLive() then
        return
    end

    local factory = StatusFactoryInst
    local battleLogic = CtlBattleInst:GetLogic()
    local StatusGiverNew = StatusGiver.New
    ActorManagerInst:Walk(
        function(tmpTarget)       
            if not battleLogic:IsFriend(self, tmpTarget, true) then
                return
            end
            
            local shieldValue = Formular.CalcRecover(BattleEnum.HURTTYPE_MAGIC_HURT, self, tmpTarget, self.m_12173SkillCfg, self.m_12173X)
            local giver = StatusGiverNew(self:GetActorID(), 12173)  
            
            local shield = factory:NewStatusLusuAllShieldLeshan(giver, FixMul(shieldValue, self.m_attrMul), self.m_12173B, self.m_chgPhySuck, self.m_chgMagicSuck)
            shield:SetMergeRule(StatusEnum.MERGERULE_MERGE)
            tmpTarget:GetStatusContainer():Add(shield, self)
        end
    )
end

function Actor1217:GetPhySuck()
    return self.m_chgPhySuck
end

function Actor1217:GetMagicSuck()
    return self.m_chgMagicSuck
end

function Actor1217:ShouldActive12172(targetID, isBaoji)
    self.m_active12172 = true
    self.m_12172TargetID = targetID
    self.m_baojiJudge = isBaoji
end

function Actor1217:Active12172()
    if not self.m_12172SkillCfg or not self.m_12172SkillItem then
        return
    end

    local performer = ActorManagerInst:GetActor(self.m_12172TargetID)
    if not performer or not performer:IsLive() then
        return
    end
    local performerPos = performer:GetPosition()
    local battleLogic = CtlBattleInst:GetLogic()
    local factory = StatusFactoryInst
    local StatusGiverNew = StatusGiver.New
    
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInCircle(performerPos, self.m_12172C, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end
            local judge = nil
            if self.m_baojiJudge and self.m_12172Level >= 3 then
                judge = BattleEnum.ROUNDJUDGE_BAOJI
            else
                judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            end

            if Formular.IsJudgeEnd(judge) then
                return
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, self.m_12172SkillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_12172Y)
            if injure > 0 then
                local giver = StatusGiverNew(self:GetActorID(), 12172)
                local status = StatusFactoryInst:NewStatusDelayHurt(giver,  FixMul(injure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, 0, BattleEnum.HPCHGREASON_BY_SKILL, 0, judge)
                tmpTarget:GetStatusContainer():Add(status, self)
                tmpTarget:AddEffect(121706)
            end
        end
    )
end

return Actor1217