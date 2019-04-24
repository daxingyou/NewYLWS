local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20101 = BaseClass("Skill20101", SkillBase)

function Skill20101:Perform(performer, target, performPos, special_param)
    if not self.m_skillCfg or not performer then
        return
    end
    
    -- 引导机制。防御姿态状态可以被控制、浮空、击飞打断
    -- 令自身进入防御姿态，停止攻击，受到物理伤害与法术伤害降低{X1}%，持续{a}秒。	
    -- 令自身进入防御姿态，停止攻击，受到物理伤害与法术伤害降低{X2}%，持续{a}秒。防御状态每持续1秒，就为解除防御状态后的下一次普攻提升{Y2}%的伤害，最多提升{b}%。
    if self.m_level == 1 then
        local giver = StatusGiver.New(performer:GetActorID(), 20021) 
        local statusHuangjinDaodunDef = StatusFactoryInst:NewStatusHuangjinDaodunDef(giver, FixMul(self:A(), 1000), FixDiv(self:X(), 100), 0, 0, {21016})
        self:AddStatus(performer, performer, statusHuangjinDaodunDef)
    end

    if self.m_level == 2 then
        local giver = StatusGiver.New(performer:GetActorID(), 20021) 
        local statusHuangjinDaodunDef = StatusFactoryInst:NewStatusHuangjinDaodunDef(giver, FixMul(self:A(), 1000), 
        FixDiv(self:X(), 100), FixDiv(self:B(), 100), FixDiv(self:Y(), 100), {21016})
        self:AddStatus(performer, performer, statusHuangjinDaodunDef)
    end
end

return Skill20101