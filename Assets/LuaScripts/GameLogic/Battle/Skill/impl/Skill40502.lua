local Vector3 = Vector3
local StatusGiver = StatusGiver
local Formular = Formular
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local Quaternion = Quaternion
local FixNormalize = FixMath.Vector3Normalize
local FixNewVector3 = FixMath.NewFixVector3
local table_remove = table.remove
local table_insert = table.insert
local FixIntMul = FixMath.muli
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local BattleRander = BattleRander
local AtkRoundJudge = Formular.AtkRoundJudge
local IsJudgeEnd = Formular.IsJudgeEnd
local CalcInjure = Formular.CalcInjure
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local BattleEnum = BattleEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill40502 = BaseClass("Skill40502", SkillBase)

function Skill40502:Perform(performer, target, performPos, special_param)    
    if not performer then
        return
    end

    --雀神每次出场时会击飞所有武将{A}米，并造成{x1}（+{E}%法攻)点法术伤害。

    local battleLogic = CtlBattleInst:GetLogic()
    local statusGiverNew = StatusGiver.New
    
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end
           
            -- if not self:InRange(performer, tmpTarget, performPos, performer:GetPosition()) then
            --     return
            -- end
            
            -- local judge = AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            -- if IsJudgeEnd(judge) then
            --     return  
            -- end

            local injure = CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.ROUNDJUDGE_NORMAL, self:X())
            local addInjure = FixMul(injure, FixDiv(self:E(), 100))
            injure = FixAdd(injure, addInjure)
            if injure > 0 then
                local giver = statusGiverNew(performer:GetActorID(), 40502)
                local statusHP = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                BattleEnum.ROUNDJUDGE_NORMAL, special_param.keyFrameTimes)

                self:AddStatus(performer, tmpTarget, statusHP)
                -- print("OnBeatFly ", self:A())
                tmpTarget:OnBeatFly(BattleEnum.ATTACK_WAY_FLY_AWAY, performer:GetPosition(), self:A())
            end
        end
    )

end

return Skill40502