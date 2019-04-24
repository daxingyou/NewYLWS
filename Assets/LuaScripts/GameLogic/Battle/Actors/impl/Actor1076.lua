local FixDiv = FixMath.div

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1076 = BaseClass("Actor1076", Actor)

function Actor1076:__init()
    self.m_10763SkillCfg = nil
    self.m_10763XPercent = 0
end

function Actor1076:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skillItem = self.m_skillContainer:GetActiveByID(10763)
    if skillItem then
        local skillCfg = ConfigUtil.GetSkillCfgByID(10763)
        self.m_10763SkillCfg = skillCfg
        if skillCfg then
            local level = skillItem:GetLevel()
            self.m_10763XPercent = FixDiv(SkillUtil.X(skillCfg, level), 100)
        end
    end
end

function Actor1076:Get10763X()
    if not self.m_10763SkillCfg then
        return 0
    end

    return self.m_10763XPercent
end

function Actor1076:ActiveChouXueEffect(targetID)
    if self.m_component then
        self.m_component:ActiveChouXueEffect(targetID)
    end
end

function Actor1076:OnAttackEnd(skillCfg)
    Actor.OnAttackEnd(self, skillCfg)

    local movehelper = self:GetMoveHelper()
    if movehelper then
        movehelper:Stop()
    end
end

return Actor1076