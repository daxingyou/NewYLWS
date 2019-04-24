local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local CtlBattleInst = CtlBattleInst
local FixIntMul = FixMath.muli
local Formular = Formular

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill35013 = BaseClass("Skill35013", SkillBase)

function Skill35013:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end

    --青龙长啸一声，为自己回复{x1}（+{E}%法攻)点生命。并在{A}秒内，青龙每受到一次攻击就恢复{y1}（+{E}%法攻)点血量。

    local battleLogic = CtlBattleInst:GetLogic()
    local factory = StatusFactoryInst
    local statusGiverNew = StatusGiver.New

    local giver = statusGiverNew(performer:GetActorID(), 35013)
    local recoverHP = Formular.CalcRecover(BattleEnum.HURTTYPE_REAL_HURT, performer, performer, self.m_skillCfg, self:X())
    local judge = BattleEnum.ROUNDJUDGE_NORMAL
    if isBaoji then
        judge = BattleEnum.ROUNDJUDGE_BAOJI
    end
    
    local status = factory:NewStatusHP(giver, recoverHP, BattleEnum.HURTTYPE_REAL_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, special_param.keyFrameTimes)
    self:AddStatus(performer, performer, status)
    
    performer:PerformSkill35013(FixIntMul(self:A(), 1000))
    
end

return Skill35013