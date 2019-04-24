local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local Formular = Formular
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular
local StatusGiver = StatusGiver

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium20111 = BaseClass("Medium20111", LinearFlyToTargetMedium)

function Medium20111:ArriveDest()
    self:Hurt()
end

function Medium20111:Hurt() 
    -- 对目标造成{x1}%的物理伤害，并使目标进入流血状态，每秒造成{y1}%的物理伤害，持续{A}秒。
    -- 对目标造成{x2}%的物理伤害，并使目标进入流血状态，每秒造成{y2}%的物理伤害，持续{A}秒。处于流血状态的角色物防下降{z2}%。
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    if not battleLogic or not skillCfg or not self.m_skillBase then
        return
    end

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
    if Formular.IsJudgeEnd(judge) then
       return 
    end

    local injure = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:X())
    if injure > 0 then  
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
         judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)
    end

    local phyDef = 0
    if self.m_skillBase:GetLevel() >= 2 then
        local targetCurPhyDef = target:GetData():GetAttrValue(ACTOR_ATTR.BASE_PHY_DEF)
        phyDef = FixIntMul(targetCurPhyDef, FixDiv(self.m_skillBase:Z(), 100))
    end

    local injure1 = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:Y())
    if injure1 > 0 then 
        local intervalHpStatus = StatusFactoryInst:NewStatusIntervalHP20111(self.m_giver, FixIntMul(injure1, -1), 1000, self.m_skillBase:A(), phyDef)
        self:AddStatus(performer, target, intervalHpStatus)
    end
end

return Medium20111