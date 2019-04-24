local StatusGiver = StatusGiver

local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixNewVector3 = FixMath.NewFixVector3
local MediumManagerInst = MediumManagerInst

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20972 = BaseClass("Skill20972", SkillBase)

function Skill20972:Perform(performer, target, performPos, special_param)
    if not performer or not target or not target:IsLive() then
        return
    end
    
    -- 召唤一个雷球环绕己身。每当雷球集满{A}个后，就会飞出攻击当前目标。每颗雷球可造成{x1}<color=#00ff00>（+{E}%法攻)</color>点<color=#ee00ee>法术伤害</color>。
    -- 召唤一个雷球环绕己身。每当雷球集满{A}个后，就会飞出攻击当前目标。每颗雷球可造成{x2}<color=#00ff00>（+{E}%法攻)</color>点<color=#ee00ee>法术伤害</color>。控雷师自身每次受到伤害时，自动召唤一个雷球。

    performer:AddBallCount()
    local ballCount = performer:GetBallCount()
    local pos = performer:GetPosition()
    local forward = performer:GetForward()
    pos = FixNewVector3(pos.x, FixAdd(pos.y, 1.3), pos.z)
    pos:Add(forward * 1.13)
    pos:Add(performer:GetRight() * -0.01)
    local giver = StatusGiver.New(performer:GetActorID(), 20972)
    -- local mediaID = self:MediaID()


    local mediaParam = {
        targetActorID = target:GetActorID(),
        keyFrame = special_param.keyFrameTimes,
        speed = 8,
        index = ballCount
    }

    MediumManagerInst:CreateMedium(MediumEnum.MEDIUMTYPE_20972, 19, giver, self, pos, forward, mediaParam)
end

return Skill20972