local StatusGiver = StatusGiver

local BattleEnum = BattleEnum
local FixIntMul = FixMath.muli
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local table_remove = table.remove
local table_insert = table.insert
local FixNormalize = FixMath.Vector3Normalize
local FixNewVector3 = FixMath.NewFixVector3

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1111 = BaseClass("Actor1111", Actor)

function Actor1111:__init()
    self.m_11113SkillCfg = 0
    self.m_11113Level = 0
    self.m_11113A = 0
    self.m_11113XPercent = 0
end

function Actor1111:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skill11113Item = self.m_skillContainer:GetPassiveByID(11113)
    if skill11113Item then
        local skill11113Cfg = ConfigUtil.GetSkillCfgByID(11113)
        if skill11113Cfg then
            self.m_11113Level = skill11113Item:GetLevel()
            self.m_11113SkillCfg = skill11113Cfg
            self.m_11113A = SkillUtil.A(skill11113Cfg, self.m_11113Level)
            if self.m_11113Level >= 4 then
                self.m_11113XPercent = FixDiv(SkillUtil.X(skill11113Cfg, self.m_11113Level), 100)
            end
        end
    end
end

function Actor1111:Get11113A()
    return self.m_11113A
end

function Actor1111:Get11113X()
    return self.m_11113XPercent
end

function Actor1111:Get11113Level()
    return self.m_11113Level
end

return Actor1111