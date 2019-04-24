local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local ActorManagerInst = ActorManagerInst
local FixIntMul = FixMath.muli

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20431 = BaseClass("Skill20431", SkillBase)

function Skill20431:Perform(performer, target, performPos, special_param)
    if not performer or not target then
        return
    end
    
    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
    if Formular.IsJudgeEnd(judge) then
      return  
    end
    
    local injure = Formular.CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
    -- if injure > 0 then
    --     local giver = StatusGiver.New(performer:GetActorID(), 20431)
    --     local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, judge, special_param.keyFrameTimes)
    --     self:AddStatus(performer, target, status)
    -- end
    
    -- 老鹰普攻1秒1次	
    -- 指挥老鹰去突击当前攻击目标，造成{X1}（+{e}%攻击力）点物理伤害。老鹰会在接下来的{a}秒内持续攻击目标。老鹰的物理攻击等于驯鹰师的{Y1}%。	
    -- 指挥老鹰去突击当前攻击目标，造成{X2}（+{e}%攻击力）点物理伤害。老鹰会在接下来的{a}秒内持续攻击目标。老鹰的物理攻击等于驯鹰师的{Y2}%。当老鹰返回时，可将其造成伤害的{Y2}%当作血量回复带给驯鹰师。
    local eagle = ActorManagerInst:GetActor(performer:GetMyEagle())
    if eagle then
        if self.m_level == 2 then
            -- 当老鹰返回时，可将其造成伤害的{Y2}%当作血量回复带给驯鹰师。
            if injure > 0 then
                local recoverMul = eagle:SetRecoverMul(FixDiv(self:Y(), 100))
                eagle:AddMakeHurt(injure)
            end
        end
        eagle:SetTujiHurt(injure)
        
        local eagleAI = eagle:GetAI()
        if eagleAI then
            eagleAI:Attack(target:GetActorID(), 40073, FixIntMul(self:A(), 1000))
        end
    end
end

return Skill20431