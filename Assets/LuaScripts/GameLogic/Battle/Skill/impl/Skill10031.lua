local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixMod = FixMath.mod
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local FixFloor = FixMath.floor
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local FixIntMul = FixMath.muli
local BattleCameraMgr = BattleCameraMgr
local ACTOR_ATTR = ACTOR_ATTR
local StatusEnum = StatusEnum

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10031 = BaseClass("Skill10031", SkillBase)

function Skill10031:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end

    -- if special_param.keyFrameTimes == 1 and self.m_level >= 5 then
    --     local giver = StatusGiver.New(performer:GetActorID(), 10031)
    --     local immuneBuff = StatusFactoryInst:NewStatusImmune(giver, 3000) -- 动画 3s
    --     immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_CONTROL)
    --     immuneBuff:SetCanClearByOther(false)
    --     self:AddStatus(performer, performer, immuneBuff)
    -- end

    -- 万夫不当之一喝
    -- 张飞大吼一声，对面前扇形范围的所有敌人快速打击5次，每次打击造成浮空和{X3}（+{e}%物攻)点物理伤害。
    -- 最后一击将所有打击范围内的敌人击飞{a}米然后嘲讽{b}米内的敌人{c}秒。张飞当前的攻速将影响技能的伤害，每10%的攻速加成提升{Y3}%的伤害。

    -- 张飞大吼一声，对面前扇形范围的所有敌人快速打击5次，每次打击造成浮空和{X4}（+{e}%物攻)点物理伤害。
    -- 最后一击将所有打击范围内的敌人击飞{a}米然后嘲讽{b}米内的敌人{c}秒。张飞当前的攻速将影响技能的伤害，每10%的攻速加成提升{Y4}%的伤害。

    -- 张飞大吼一声，对面前扇形范围的所有敌人快速打击5次，每次打击造成浮空和{X3}（+{e}%物攻)点物理伤害。
    -- 最后一击将所有打击范围内的敌人击飞{a}米然后嘲讽{b}米内的敌人{c}秒。张飞当前的攻速将影响技能的伤害，每10%的攻速加成提升{Y3}%的伤害。

    -- 张飞大吼一声，对面前扇形范围的所有敌人快速打击5次，每次打击造成浮空和{X4}（+{e}%物攻)点物理伤害。
    -- 最后一击将所有打击范围内的敌人击飞{a}米然后嘲讽{b}米内的敌人{c}秒。张飞当前的攻速将影响技能的伤害，每10%的攻速加成提升{Y4}%的伤害。

    -- 张飞大吼一声，对面前扇形范围的所有敌人快速打击5次，每次打击造成浮空和{X5}（+{e}%物攻)点物理伤害。
    -- 最后一击将所有打击范围内的敌人击飞{a}米然后嘲讽{b}米内的敌人{c}秒。张飞当前的攻速将影响技能的伤害，每10%的攻速加成提升{Y5}%的伤害。张飞施放万夫不当之一喝时，处于霸体状态不会被控制。

    -- 张飞大吼一声，对面前扇形范围的所有敌人快速打击5次，每次打击造成浮空和{X6}（+{e}%物攻)点物理伤害。
    -- 最后一击将所有打击范围内的敌人击飞{a}米然后嘲讽{b}米内的敌人{c}秒。张飞当前的攻速将影响技能的伤害，每10%的攻速加成提升{Y6}%的伤害。张飞施放万夫不当之一喝时处于霸体状态不会被控制。


    local battleLogic = CtlBattleInst:GetLogic()
    local factory = StatusFactoryInst
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if special_param.keyFrameTimes == 6 then -- 嘲讽 测试显示嘲讽状态时恐惧，需要改进？
                local dir = tmpTarget:GetPosition() - performer:GetPosition()
                dir.y = 0
                local sqrDistance = dir:SqrMagnitude()
                if sqrDistance <= FixMul(self:B(), self:B()) then
                    local giver = StatusGiver.New(performer:GetActorID(), 10031)
                    local statusChaofeng = factory:NewStatusChaoFeng(giver, performer:GetActorID(), FixIntMul(self:C(), 1000))
                    self:AddStatus(performer, tmpTarget, statusChaofeng)
                end
            end

            if not self:InRange(performer, tmpTarget, performPos - performer:GetPosition(), nil) then
                return
            end

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return  
            end

            if special_param.keyFrameTimes <= 5 then
                local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
                if injure > 0 then
                    local giver = StatusGiver.New(performer:GetActorID(), 10031)

                    local performerAtkSpeed = performer:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
                    local curPerformerAtkSpeed = performer:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_ATKSPEED)
                    if curPerformerAtkSpeed > performerAtkSpeed then
                        local subAtkSpeed = FixSub(curPerformerAtkSpeed, performerAtkSpeed)
                        local atkSpeedPercent = FixDiv(subAtkSpeed, performerAtkSpeed)
                        local injureAdd = FixFloor(FixDiv(FixMul(atkSpeedPercent, 100), self:D()))
                        if injureAdd > 0 then
                            local injureChg = FixIntMul(injureAdd, FixMul(FixDiv(self:Y(), 100), injure))
                            injure = FixAdd(injure, injureChg)
                        end
                    end

                    local status = factory:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                        judge, special_param.keyFrameTimes)
                    self:AddStatus(performer, tmpTarget, status)
                end
            end

            if special_param.keyFrameTimes == 5 then
                BattleCameraMgr:Shake(2)
            end
        end
    )

    
end

function Skill10031:Preperform(performer, target, performPos)
    if self.m_level >= 5 then
        local giver = StatusGiver.New(performer:GetActorID(), 10031)
        local immuneBuff = StatusFactoryInst:NewStatusImmune(giver, 3000) -- 动画 3s
        immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_CONTROL)
        immuneBuff:SetCanClearByOther(false)
        self:AddStatus(performer, performer, immuneBuff)
    end
    
    return SkillBase.Preperform(self, performer, target, performPos)
end

return Skill10031