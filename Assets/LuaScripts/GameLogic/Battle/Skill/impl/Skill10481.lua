local StatusGiver = StatusGiver
local MediumManagerInst = MediumManagerInst
local FixNewVector3 = FixMath.NewFixVector3
local FixAdd = FixMath.add
local MediumEnum = MediumEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10481 = BaseClass("Skill10481", SkillBase)


function Skill10481:Perform(performer, target, performPos, special_param)
    if not self.m_skillCfg or not performer then
        return
    end
    
    -- name = 莲转流云舞
    -- 貂蝉翩翩起舞，向指定区域发射一枚巨大莲花，对区域内的敌人造成{X1}（+{e}%法攻)点法术伤害。大招对附带莲花印记的敌人造成伤害时，每层印记额外提升{Y1}（+{e}%法攻)点法术伤害，之后清除敌人身上所有印记。印记累计提升的伤害不得超过貂蝉法术攻击的{Z1}%。
    -- 貂蝉翩翩起舞，向指定区域发射一枚巨大莲花，对区域内的敌人造成{X2}（+{e}%法攻)点法术伤害。大招对附带莲花印记的敌人造成伤害时，每层印记额外提升{Y2}（+{e}%法攻)点法术伤害，之后清除敌人身上所有印记。印记累计提升的伤害不得超过貂蝉法术攻击的{Z2}%。
    -- 貂蝉翩翩起舞，向指定区域发射一枚巨大莲花，对区域内的敌人造成{X3}（+{e}%法攻)点法术伤害。大招对附带莲花印记的敌人造成伤害时，每层印记额外提升{Y3}（+{e}%法攻)点法术伤害，之后清除敌人身上所有印记。印记累计提升的伤害不得超过貂蝉法术攻击的{Z3}%。大招无视敌人{a}%的法术防御。
    -- 貂蝉翩翩起舞，向指定区域发射一枚巨大莲花，对区域内的敌人造成{X4}（+{e}%法攻)点法术伤害。大招对附带莲花印记的敌人造成伤害时，每层印记额外提升{Y4}（+{e}%法攻)点法术伤害，之后清除敌人身上所有印记。印记累计提升的伤害不得超过貂蝉法术攻击的{Z4}%。大招无视敌人{a}%的法术防御。
    -- 貂蝉翩翩起舞，向指定区域发射一枚巨大莲花，对区域内的敌人造成{X5}（+{e}%法攻)点法术伤害。大招对附带莲花印记的敌人造成伤害时，每层印记额外提升{Y5}（+{e}%法攻)点法术伤害，之后清除敌人身上所有印记。印记累计提升的伤害不得超过貂蝉法术攻击的{Z5}%。大招无视敌人{a}%的法术防御。附带莲花印记的敌人被大招命中后，仍会保留{b}层印记。
    -- 貂蝉翩翩起舞，向指定区域发射一枚巨大莲花，对区域内的敌人造成{X6}（+{e}%法攻)点法术伤害。大招对附带莲花印记的敌人造成伤害时，每层印记额外提升{Y6}（+{e}%法攻)点法术伤害，之后清除敌人身上所有印记。印记累计提升的伤害不得超过貂蝉法术攻击的{Z6}%。大招无视敌人{a}%的法术防御。附带莲花印记的敌人被大招命中后，仍会保留{b}层印记。

    -- todo pos
    local pos = performer:GetPosition()
    local forward = performer:GetForward()
    pos = FixNewVector3(pos.x, FixAdd(pos.y, 1.3), pos.z)
    pos:Add(performer:GetRight() * -0.01)
    
    performPos = FixNewVector3(performPos.x, performer:GetPosition().y, performPos.z)

    local giver = StatusGiver.New(performer:GetActorID(), 10481)
    
    local mediaParam = {
        keyFrame = special_param.keyFrameTimes,
        speed = 13,
        targetPos = performPos,-- todo
    }
    
    MediumManagerInst:CreateMedium(MediumEnum.MEDIUMTYPE_10481, 13, giver, self, pos, forward, mediaParam)
end

return Skill10481