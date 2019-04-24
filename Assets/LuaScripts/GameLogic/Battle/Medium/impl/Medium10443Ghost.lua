local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local Formular = Formular
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium10443Ghost = BaseClass("Medium10443Ghost", LinearFlyToTargetMedium)

function Medium10443Ghost:ArriveDest()
    self:Hurt()
end

function Medium10443Ghost:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
       return 
    end

    local injure = Formular.CalcInjure(performer, target, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:X())
    if injure > 0 then
        if self.m_skillBase:GetLevel() >= 5 then
            local beHurtMulStatus = target:GetStatusContainer():GetNTimeBeHurtMul()
            if beHurtMulStatus then
                local hurtMul = beHurtMulStatus:GetHurtMul()
                if hurtMul < 1 then
                    injure = FixAdd(injure, FixIntMul(injure, FixDiv(self.m_skillBase:Z(), 100)))
                end
            end
        end

        local statusHP = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, statusHP)

        if self.m_skillBase:GetLevel() >= 2 then
            local recoverHP,isBaoji = Formular.CalcRecover(BattleEnum.HURTTYPE_MAGIC_HURT, performer, target, skillCfg,  self.m_skillBase:Y()) 
            local judge = BattleEnum.ROUNDJUDGE_NORMAL
            if isBaoji then
                judge = BattleEnum.ROUNDJUDGE_BAOJI
            end
            local statusHP = StatusFactoryInst:NewStatusHP(self.m_giver, recoverHP, BattleEnum.HURTTYPE_REAL_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, self.m_param.keyFrame)
            self:AddStatus(performer, performer, statusHP)
        end
    end

    
end


return Medium10443Ghost