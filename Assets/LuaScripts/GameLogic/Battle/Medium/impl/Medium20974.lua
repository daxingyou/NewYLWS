local FixMul = FixMath.mul
local ActorManagerInst = ActorManagerInst
local BattleEnum = BattleEnum
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local Factor = Factor

local NormalFly = require("GameLogic.Battle.Medium.impl.NormalFly")
local Medium20974 = BaseClass("Medium20974", NormalFly)

function Medium20974:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local skillCfg = self:GetSkillCfg()
    local factor = nil
    if performer:IsCalled() then
        factor = Factor.New()
        factor.chgMagicDef = performer:GetCallIgnoreMagicDef()
    end
    
    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end
    
    if self.m_param.reason == BattleEnum.HPCHGREASON_NONE then
        return
    end
    target:AddEffect(20003)
    
    local judge = Formular.AtkRoundJudge(performer, target, self.m_param.hurtType, true, factor)
    if Formular.IsJudgeEnd(judge) then
        return
    end
    
    local injure = Formular.CalcInjure(performer, target, skillCfg, self.m_param.hurtType, judge, self.m_skillBase:X())
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), self.m_param.hurtType, BattleEnum.HPCHGREASON_BY_SKILL, judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)
    end
end


return Medium20974