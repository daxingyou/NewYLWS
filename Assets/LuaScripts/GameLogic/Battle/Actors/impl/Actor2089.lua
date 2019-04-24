local FixAdd = FixMath.add
local ActorManagerInst = ActorManagerInst
local SkillUtil = SkillUtil

local Actor2070 = require "GameLogic.Battle.Actors.impl.Actor2070"
local Actor2089 = BaseClass("Actor2089", Actor2070)

function Actor2089:__init()
    self.m_atkTimes = 0

    self.m_20893B = 0
    self.m_20893X = 0
    self.m_20893Y = 0
    self.m_20893Level = 0

    self.m_nextAtkPercent = 0

    self.m_20893Effect = -1
end


function Actor2089:OnBorn(create_param)
    Actor2070.OnBorn(self, create_param)
    
    local skillItem = self.m_skillContainer:GetPassiveByID(20893)
    if skillItem  then
        local level = skillItem:GetLevel()
        self.m_20893Level = level
        local skillCfg = ConfigUtil.GetSkillCfgByID(20893)
        self.m_20893SkillCfg = skillCfg
        if skillCfg then
            self.m_20893B = SkillUtil.B(skillCfg, level)
            self.m_20893X = SkillUtil.X(skillCfg, level)
            self.m_20893Y = SkillUtil.Y(skillCfg, level)
        end
    end
end

function Actor2089:OnAttackEnd(skillCfg)
    Actor2070.OnAttackEnd(self, skillCfg)

    if SkillUtil.IsAtk(skillCfg) then
        self.m_atkTimes = FixAdd(self.m_atkTimes, 1)

        if self.m_atkTimes >= self.m_20893Y then
            self.m_nextAtkPercent = self.m_20893X
            self.m_atkTimes = -1

            if self.m_20893Effect < 0 then
                self.m_20893Effect = self:AddEffect(207007)
            end
        end
    end
end


function Actor2089:GetNextAtkChgPercent()
    local n = self.m_nextAtkPercent
    return n
end

function Actor2089:ClearNextAtkChgPercent()
    self.m_nextAtkPercent = 0

    if self.m_20893Effect > 0 then
        EffectMgr:RemoveByKey(self.m_20893Effect)
        self.m_20893Effect = -1
    end
end

function Actor2089:GetDingshenS()
    return self.m_20893B
end

return Actor2089