local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local GetSkillCfgByID = ConfigUtil.GetSkillCfgByID
local BattleEnum = BattleEnum
local SkillUtil = SkillUtil

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor2002 = BaseClass("Actor2002", Actor)

function Actor2002:__init()
    self.m_20021XPercent = 0
    self.m_20021Level = 0
end

function Actor2002:PreChgHP(giver, chgHP, hurtType, reason)
    -- 20081
    if chgHP >= 0 then
        return chgHP
    end

    local huangjinDefen = self:GetStatusContainer():IsHuangjinDaodunDefensiveState()
    if not huangjinDefen then
        return chgHP
    end

    chgHP = FixMul(-1, chgHP)
    if hurtType == BattleEnum.HURTTYPE_PHY_HURT or hurtType == BattleEnum.HURTTYPE_MAGIC_HURT then
        chgHP = FixSub(chgHP, FixIntMul(chgHP, self.m_20021XPercent))
    end

    return FixMul(-1, chgHP)
end

function Actor2002:Get20021Level()
    return self.m_20021Level
end

function Actor2002:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skillItem = self.m_skillContainer:GetActiveByID(20021)
    if skillItem  then
        local skillLevel = skillItem:GetLevel()
        self.m_20021Level = skillLevel
        local skillCfg = ConfigUtil.GetSkillCfgByID(20021)
        if skillCfg then
            self.m_20021XPercent = FixDiv(SkillUtil.X(skillCfg, skillLevel), 100)
        end
    end

    -- local skill10433Item = self.m_skillContainer:GetPassiveByID(10433)
    -- if skill10433Item  then
    --     local skillLevel = skill10433Item:GetLevel()
    --     self.m_10433Level = skillLevel
    --     self.m_10433Cfg = ConfigUtil.GetSkillCfgByID(10433)
    --     if self.m_10433Cfg then
    --         self.m_10433XPercent = FixDiv(SkillUtil.X(self.m_10433Cfg, skillLevel), 100)
    --         self.m_10433A = SkillUtil.A(self.m_10433Cfg, skillLevel)
    --         self.m_10433B = SkillUtil.B(self.m_10433Cfg, skillLevel)
    --         if skillLevel >= 4 then
    --             self.m_10433CPercent = FixDiv(SkillUtil.C(self.m_10433Cfg, skillLevel), 100)
    --             if skillLevel == 6 then
    --                 self.m_10433DPercent = FixDiv(SkillUtil.D(self.m_10433Cfg, skillLevel), 100)
    --             end
    --         end
    --     end
    -- end
end

function Actor2002:OnAttackEnd(skillCfg)
    Actor.OnAttackEnd(self, skillCfg)

    local movehelper = self:GetMoveHelper()
    if movehelper then
        movehelper:Stop()
    end
end

return Actor2002