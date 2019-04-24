local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10021 = BaseClass("Skill10021", SkillBase)
local StatusGiver = StatusGiver
local MediumEnum = MediumEnum
local FixNormalize = FixMath.Vector3Normalize
local MediumManagerInst = MediumManagerInst

function Skill10021:__init()
end

function Skill10021:Perform(performer, target, performPos, special_param)
    if not self.m_skillCfg or not performer then 
        return 
    end
    -- 1
    -- 关羽挥刀依次召唤三道巨浪，每道巨浪对目标范围内的所有敌人造成{x1}（+{E}%物攻)点物理伤害，并附加{y1}（+{E}%法攻)点法术伤害。巨浪可将敌人推后{A}米。
    -- 2-5
    -- 关羽挥刀依次召唤三道巨浪，每道巨浪对目标范围内的所有敌人造成{x2}（+{E}%物攻)点物理伤害，并附加{y2}（+{E}%法攻)点法术伤害。巨浪可将敌人推后{A}米。
    -- 被巨浪连续攻击的敌人将浮空，被三道巨浪连续击中将被击飞{B}米。
    -- 6
    -- 关羽挥刀依次召唤三道巨浪，每道巨浪对目标范围内的所有敌人造成{x6}（+{E}%物攻)点物理伤害，并附加{y6}（+{E}%法攻)点法术伤害。巨浪可将敌人推后{A}米。
    -- 被巨浪连续攻击的敌人将浮空，被三道巨浪连续击中将被击飞{B}米，并恐惧{C}秒。
    local pos = performer:GetPosition()
    local dir = FixNormalize(performPos)
    dir:Mul(self.m_skillCfg.dis2)
    dir:Add(pos)

    local giver = StatusGiver.New(performer:GetActorID(), self.m_skillCfg.id)
    local forward = performer:GetForward()
    local mediaParam = {
        keyFrame = special_param.keyFrameTimes,
        speed = 13,
        targetPos = dir
    }

    MediumManagerInst:CreateMedium(MediumEnum.MEDIUMTYPE_GUANYU_WATER, 30, giver, self, pos, forward, mediaParam)
end

return Skill10021