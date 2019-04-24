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
local IsInCircle = SkillRangeHelper.IsInCircle
local FixNormalize = FixMath.Vector3Normalize
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10822 = BaseClass("Skill10822", SkillBase)

function Skill10822:Perform(performer, target, performPos, special_param)
    if not performer or not target or not target:IsLive() then
        return
    end

    -- 1
    -- 华雄对距离自身{D}米内当前物防最低的敌人发起一次重击，造成{x1}%的物理伤害，并附加撕裂状态,该状态下的敌人获得的治疗效果削减{A}%，持续{E}秒。

    -- 2 3
    -- 华雄突进到{D}米内血量最低的目标面前进行一次重击，造成{x2}（+{E}%物攻)点物理伤害，并附加撕裂状态，该状态下的敌人获得的治疗效果削减{A}%。
    -- 重击会波及目标周围{C}米内的敌方单位，对其造成{B}倍的物理伤害。{D}秒后华雄会回到原位，若目标死亡则提前返回。

    -- 4 5 6
    -- 华雄突进到{D}米内血量最低的目标面前进行一次重击，造成{x4}（+{E}%物攻)点物理伤害，并附加撕裂状态，该状态下的敌人获得的治疗效果削减{A}%。
    -- 重击会波及目标周围{C}米内的敌方单位，对其造成{B}倍的物理伤害，被波及单位均会获得撕裂状态。{D}秒后华雄会回到原位，若目标死亡则提前返回。

    -- local performerPos = performer:GetPosition()
    -- local targetPos = target:GetPosition()
    -- if special_param.keyFrameTimes == 1 then
    --     performer:SetOrignalPos(performer:GetPosition():Clone())
    --     local distance = 0
    --     local movehelper = performer:GetMoveHelper()
    --     if movehelper then
    --         local moveTargetPos = FixNormalize(performerPos - targetPos)
    --         moveTargetPos:Mul(FixAdd(target:GetRadius(), performer:GetRadius()))
    --         moveTargetPos:Add(target:GetPosition())

    --         local pathHandler = CtlBattleInst:GetPathHandler()
    --         if pathHandler then
    --             local x,y,z = performerPos:GetXYZ()
    --             local x2, y2, z2 = moveTargetPos:GetXYZ()
    --             local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
    --             if hitPos then
    --                 moveTargetPos:SetXYZ(hitPos.x , performerPos.y, hitPos.z)
    --             end
    --         end
            
    --         distance = (moveTargetPos - performerPos):Magnitude()
    --         local speed = FixDiv(distance, 0.6)  -- time 暂定
    --         movehelper:Stop()
    --         movehelper:Start({ moveTargetPos }, speed, nil, false)
    --     end
    -- end

    if special_param.keyFrameTimes == 2 then
        -- performer:Set10822TargetID(target:GetActorID(), FixIntMul(self:D(), 1000))
        BattleCameraMgr:Shake()
        
        local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
        if Formular.IsJudgeEnd(judge) then
            return  
        end

        local injure = Formular.CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
        if injure > 0 then
            local selfPhyAtk = performer:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_PHY_ATK)
            if target:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_PHY_ATK) < selfPhyAtk then
                injure = FixAdd(injure, FixMul(injure, performer:Get10823XPercent()))
            end

            local giver = StatusGiver.New(performer:GetActorID(), 10822)
            local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                judge, special_param.keyFrameTimes)
            self:AddStatus(performer, target, status)
        end

        local giver = StatusGiver.New(performer:GetActorID(), 10822)  
        local statusHuaxiongReduceDebuff = StatusFactoryInst:NewStatusHuaxiongDebuff(giver, FixIntMul(self:E(), 1000), FixDiv(self:A(), 100))
        self:AddStatus(performer, target, statusHuaxiongReduceDebuff)

        if self.m_level >= 2 then
            local battleLogic = CtlBattleInst:GetLogic()
            local factory = StatusFactoryInst
            local statusGiverNew = StatusGiver.New
            local targetPos = target:GetPosition()
            ActorManagerInst:Walk(
                function(tmpTarget)
                    if not battleLogic:IsFriend(target, tmpTarget, false) then
                        return
                    end
        
                    if not IsInCircle(targetPos, self:C(), tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                        return
                    end
        
                    local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
                    if Formular.IsJudgeEnd(judge) then
                        return  
                    end

                    local giver = StatusGiver.New(performer:GetActorID(), 10822)
                    local status = factory:NewStatusHP(giver, FixMul(-1, FixMul(injure, self:B())), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                        judge, special_param.keyFrameTimes)
                    self:AddStatus(performer, tmpTarget, status)
    
                    if self.m_level >= 6 then
                        local giver = StatusGiver.New(performer:GetActorID(), 10822)  
                        local statusHuaxiongReduceDebuff = StatusFactoryInst:NewStatusHuaxiongDebuff(giver, FixIntMul(self:E(), 1000), FixDiv(self:A(), 100))
                        self:AddStatus(performer, tmpTarget, statusHuaxiongReduceDebuff)
                    end
                end
            )
        end
    end
end


function Skill10822:SelectSkillTarget(performer, target)
    if not performer or not performer:IsLive() then
        return
    end

    local performerPos = performer:GetPosition()

    local minDef = 9999999
    local newTarget = false

    local ctlBattle = CtlBattleInst
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not ctlBattle:GetLogic():IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInCircle(performerPos, self:D(), tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end

            local targetDef = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_PHY_DEF)
            if targetDef < minDef then
                minDef = targetDef
                newTarget = tmpTarget
            end
        end
    )

    if newTarget then
        return newTarget, newTarget:GetPosition()
    end
    return nil, nil
end

return Skill10822