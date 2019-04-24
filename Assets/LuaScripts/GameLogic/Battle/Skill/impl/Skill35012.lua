
local StatusGiver = StatusGiver
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixNewVector3 = FixMath.NewFixVector3
local MediumManagerInst = MediumManagerInst

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill35012 = BaseClass("Skill35012", SkillBase)

function Skill35012:Perform(performer, target, performPos, special_param)
    if not self.m_skillCfg or not performer or not target or not target:IsLive() then
        return
    end

    --青龙仰首吐出一个{A}米半径的光球，缓缓飞向目标地点，过程中目标地点会有预警光圈。光球持续{B}秒,
    --光球内的目标每秒受到{x1}（+{E}%物攻)点物理伤害，并被降低{y1}双暴。

    -- new 
    -- 青龙仰首吐出一个寒冰球，缓缓飞向目标将其冰冻，令其每秒内受到x1%的物理伤害，持续B秒。
    -- 同时令被冰冻角色周围A米半径圆形内的敌人攻速降低C%，持续D秒。

    local pos = performer:GetPosition()
    local forward = performer:GetForward()
    pos = FixNewVector3(pos.x, FixAdd(pos.y, 3.5), FixSub(pos.z, -6.5))
    performPos= FixNewVector3(performPos.x, FixAdd(performPos.y, 0.5), performPos.z)

    local giver = StatusGiver.New(performer:GetActorID(), 35012)
    
    local mediaParam = {
        targetActorID = target:GetActorID(),
        keyFrame = special_param.keyFrameTimes,
        speed = 15,
    }

    MediumManagerInst:CreateMedium(MediumEnum.MEDIUMTYPE_35012, 42, giver, self, pos, forward, mediaParam)
    
end

return Skill35012