local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixMod = FixMath.mod
local FixFloor = FixMath.floor
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local FixIntMul = FixMath.muli
local Quaternion = Quaternion
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular

local IsInCircle = SkillRangeHelper.IsInCircle

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20312 = BaseClass("Skill20312", SkillBase)

function Skill20312:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end

    local bossLogic = CtlBattleInst:GetLogic()
    if not bossLogic then
        return
    end

    if special_param.keyFrameTimes == 1 then
        performer:PlayAnim("skill1Stay")
        bossLogic:ShowRightHand()

        local hand  = ActorManagerInst:GetActor(performer:GetHandID())
        if not hand then
            return
        end
        BattleCameraMgr:Shake(2)
        -- hand:AddEffect(203102)
        hand:AddSceneEffect(203102, Vector3.New(hand:GetPosition().x, hand:GetPosition().y, hand:GetPosition().z), Quaternion.identity)    

        -- 击退所有敌方武将，并令其眩晕{a}秒。并造成{X1}（+{e}%物攻)点物理伤害。

        local battleLogic = CtlBattleInst:GetLogic()
        local factory = StatusFactoryInst
        local statusGiverNew = StatusGiver.New
        ActorManagerInst:Walk(
            function(tmpTarget)
                if not CtlBattleInst:GetLogic():IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                    return
                end

                -- 暂定 8 米
                if not IsInCircle(hand:GetPosition(), 8, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                    return
                end

                local giver = statusGiverNew(performer:GetActorID(), 20312)
                local stunBuff = factory:NewStatusStun(giver, FixIntMul(self:A(), 1000))
                self:AddStatus(performer, tmpTarget, stunBuff)

                tmpTarget:OnBeatBack(performer)

                local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
                if Formular.IsJudgeEnd(judge) then
                    return  
                end

                local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
                if injure > 0 then
                    local giver = StatusGiver.New(performer:GetActorID(), 20312)
                    local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                        judge, special_param.keyFrameTimes)
                    self:AddStatus(performer, tmpTarget, status)
                end
            end
        )
    end


    if special_param.keyFrameTimes == 2 and not performer:IsRightHandDead() then
        performer:PlayAnim("skill1HandUp")
    end
end

function Skill20312:OnActionStart(performer, target, perfromPos)
    if CtlBattleInst:IsInFight() then
        BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_BOSS1_NORMAL, ACTOR_ATTR.BOSS_HANDTYPE_RIGHT)
    end
end

return Skill20312