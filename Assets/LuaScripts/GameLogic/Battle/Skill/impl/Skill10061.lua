local StatusGiver = StatusGiver
local FixAdd = FixMath.add
local FixNewVector3 = FixMath.NewFixVector3
local MediumManagerInst = MediumManagerInst
local MediumEnum = MediumEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10061 = BaseClass("Skill10061", SkillBase)

function Skill10061:Perform(performer, target, performPos, special_param)
    if not performer or not performer:IsLive() then 
        return 
    end

    -- 太炎箭1
    -- 1
    -- 黄忠向目标区域射出一支燃烧的巨箭，对区域内所有敌人造成{x1}%的物理伤害。
    -- 黄忠向目标区域射出一支燃烧的巨箭，对区域内所有敌人造成{x2}%的物理伤害，同时自身获得{y2}%的命中加成和暴伤加成，本场战斗持续生效，可叠加。
    -- 黄忠向目标区域射出一支燃烧的巨箭，对区域内所有敌人造成{x3}%的物理伤害，同时自身获得{y3}%的命中加成和暴伤加成，本场战斗持续生效，可叠加。
    -- 黄忠向目标区域射出一支燃烧的巨箭，对区域内所有敌人造成{x4}%的物理伤害，同时自身获得{y4}%的命中加成和暴伤加成，本场战斗持续生效，可叠加。若黄忠当前处于百发百中状态，则按百发百中的层数给敌人追加带来每层{z4}%当前生命的真实伤害，最高造成{D}点。
    -- 黄忠向目标区域射出一支燃烧的巨箭，对区域内所有敌人造成{x5}%的物理伤害，同时自身获得{y5}%的命中加成和暴伤加成，本场战斗持续生效，可叠加。若黄忠当前处于百发百中状态，则按百发百中的层数给敌人追加带来每层{z5}%当前生命的真实伤害，最高造成{D}点。
    -- 黄忠向目标区域射出一支燃烧的巨箭，对区域内所有敌人造成{x6}%的物理伤害，同时自身获得{y6}%的命中加成和暴伤加成，本场战斗持续生效，可叠加。在施放太炎箭时，黄忠额外获得{y6}%的命中加成。若黄忠当前处于百发百中状态，则按百发百中的层数给敌人追加带来每层{z6}%当前生命的真实伤害，最高造成{D}点。
    local pos = performPos
    local forward = performer:GetForward()
    pos = FixNewVector3(pos.x, FixAdd(pos.y, 20), pos.z)
    local giver = StatusGiver.New(performer:GetActorID(), 10061)
    local mediaParam = {
        keyFrame = special_param.keyFrameTimes,
        speed = 13,
        targetPos = performPos,
    }
    MediumManagerInst:CreateMedium(MediumEnum.MEDIUMTYPE_10061, 55, giver, self, pos, forward, mediaParam)
end

return Skill10061