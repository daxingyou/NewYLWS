local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local table_insert = table.insert
local Formular = Formular
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR
local FixNormalize = FixMath.Vector3Normalize
local IsInCircle = SkillRangeHelper.IsInCircle

local LinearFlyToPointMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToPointMedium")
local Medium10352 = BaseClass("Medium10352", LinearFlyToPointMedium)

local MediumState = {
    FlyForward = 1,
    FlyBack = 2,
    Over = 3,
}

function Medium10352:__init()
    self.m_distance = 0
    self.m_farthestTargetID = 0
    self.m_targetOriginalPos = false  -- 存储目标原始位置
    self.m_targetMoveDis = 0  
    self.m_enemyList = {} 
    self.m_mediumState = MediumState.FlyForward
end

function Medium10352:__delete()
    self.m_distance = 0 
    self.m_farthestTargetID = 0    
    self.m_targetOriginalPos = false   
    self.m_enemyList = {} 
end


function Medium10352:OnMove(dir)

    -- 小乔将双环向前方掷出{a}米，对路径上所有的敌方单位造成{X1}（+{e}%物攻)点物理伤害。双环飞回时会选中路径上距离最远的单位向小乔所在方向拉动一小段距离。
    -- 小乔将双环向前方掷出{a}米，对路径上所有的敌方单位造成{X2}（+{e}%物攻)点物理伤害。双环飞回时会选中路径上距离最远的单位向小乔所在方向拉动一小段距离。被飞燕拉动的敌人在{b}秒内物防与法防各下降{Y2}%。
    -- 小乔将双环向前方掷出{a}米，对路径上所有的敌方单位造成{X3}（+{e}%物攻)点物理伤害。双环飞回时会选中路径上距离最远的单位向小乔所在方向拉动一小段距离。被飞燕拉动的敌人在{b}秒内物防与法防各下降{Y3}%。
    -- 小乔将双环向前方掷出{a}米，对路径上所有的敌方单位造成{X4}（+{e}%物攻)点物理伤害。双环飞回时会选中路径上距离最远的单位向小乔所在方向拉动一小段距离。被飞燕拉动的敌人在{b}秒内物防与法防各下降{Y4}%。
    -- 小乔将双环向前方掷出{a}米，对路径上所有的敌方单位造成{X5}（+{e}%物攻)点物理伤害。双环飞回时会选中路径上距离最远的单位向小乔所在方向拉动一小段距离。被飞燕拉动的敌人在{b}秒内物防与法防各下降{Y5}%、攻击速度下降{Z5}%。
    -- 小乔将双环向前方掷出{a}米，对路径上所有的敌方单位造成{X6}（+{e}%物攻)点物理伤害。双环飞回时会选中路径上距离最远的单位向小乔所在方向拉动一小段距离。被飞燕拉动的敌人在{b}秒内物防与法防各下降{Y6}%、攻击速度下降{Z6}%。
    
    local performer = self:GetOwner()
    if not performer then
        self:Over()
        return
    end

    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    if not battleLogic or not skillCfg or not self.m_skillBase then
        return
    end

    ActorManagerInst:Walk(
        function(tmpTarget)
            local targetID = tmpTarget:GetActorID()

            if self.m_enemyList[targetID] then
                return
            end

            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInCircle(self.m_position, 1, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end

            self.m_enemyList[targetID] = targetID

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:X())
            if injure > 0 then
                local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                        judge, self.m_param.keyFrame)
                self:AddStatus(performer, tmpTarget, status)

                tmpTarget:AddEffect(103509)
            end

            local magic10353Y = performer:Get10353Y(tmpTarget:GetActorID())
            if magic10353Y > 0 then
                local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(magic10353Y, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                judge, self.m_param.keyFrame)
                self:AddStatus(performer, tmpTarget, status)
            end

        end
    )
end


function Medium10352:DoUpdate(deltaMS)
    local performer = self:GetOwner()
    if not performer or not performer:IsLive() then
        self:Over()
        return 
    end

    local deltaS = FixDiv(deltaMS, 1000)
    self.m_param.speed = FixAdd(self.m_param.speed, deltaS)
    local moveDis = FixMul(deltaS, self.m_param.speed) 

    if self.m_mediumState == MediumState.FlyForward then
        local dir = self.m_param.targetPos - self.m_position
        dir.y = 0
        local deltaV = FixNormalize(dir)
        deltaV:Mul(moveDis) 
        self:SetForward(dir)
        self:MovePosition(deltaV)
        self:OnMove(dir)

        -- local sqrDistance = (self.m_position - self.m_param.targetPos):SqrMagnitude()
        local sqrDistance = (dir):SqrMagnitude()
        if sqrDistance <= 0.05 then
            self.m_mediumState = MediumState.FlyBack
        end

    elseif self.m_mediumState == MediumState.FlyBack then
        if not self.m_targetOriginalPos then -- 返回途中选择最远目标，直到选到为止
            local farthestTarget,distance = self:SelectFarthestTarget()
            if farthestTarget and farthestTarget:IsLive() then
                self.m_targetOriginalPos = farthestTarget:GetPosition():Clone()
                self.m_distance = distance
                self.m_farthestTargetID = farthestTarget:GetActorID()
            end
        else
            if self.m_skillBase:GetLevel() >= 2 and self.m_farthestTargetID > 0 then -- 技能等级达到2级或以上，添加属性debuff
                local farthestTarget = ActorManagerInst:GetActor(self.m_farthestTargetID)
                if farthestTarget and farthestTarget:IsLive() then
                    local dir = self.m_targetOriginalPos - farthestTarget:GetPosition()
                    dir.y = 0
                    local targetMoveDistance = dir:Magnitude()
                    if FixSub(self.m_distance, targetMoveDistance) <= 0.01 then -- 拉人结束之后才会添加debuff
                        -- 需求 位移结束添加debuff
                        local phyDef = farthestTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_PHY_DEF)
                        local chgPhyDef = FixIntMul(phyDef, FixDiv(self.m_skillBase:Y(), 100))

                        local magicDef = farthestTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAGIC_DEF)
                        local chgMagicDef = FixIntMul(magicDef, FixDiv(self.m_skillBase:Y(), 100))

                        local buff = StatusFactoryInst:NewStatusBuff(self.m_giver, BattleEnum.AttrReason_SKILL, FixMul(self.m_skillBase:B(), 1000))
                        buff:AddAttrPair(ACTOR_ATTR.FIGHT_PHY_DEF, FixMul(chgPhyDef, -1))
                        buff:AddAttrPair(ACTOR_ATTR.FIGHT_MAGIC_DEF, FixMul(chgMagicDef, -1))

                        if self.m_skillBase:GetLevel() >= 5 then
                            local atkSpeed = farthestTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
                            local chgAtkSpeed = FixIntMul(atkSpeed, FixDiv(self.m_skillBase:Z(), 100))
                            buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, FixMul(chgAtkSpeed, -1))
                        end
                        self:AddStatus(performer, farthestTarget, buff)

                        self.m_farthestTargetID = 0
                    end
                else
                    self.m_farthestTargetID = 0
                end
            end
        end

        local dir = performer:GetPosition() - self.m_position
        dir.y = 0
        local deltaV = FixNormalize(dir)
        deltaV:Mul(moveDis) 
        self:SetForward(dir)
        self:MovePosition(deltaV)

        if self.m_farthestTargetID > 0 then
            local leftDis = FixSub(self.m_distance, self.m_targetMoveDis)
            local targetMoveDis = moveDis
            if leftDis < moveDis then
                targetMoveDis = leftDis
            end
            local target = ActorManagerInst:GetActor(self.m_farthestTargetID)
            if target and target:IsLive() then
                target:OnBeatBack(performer, FixMul(targetMoveDis, -1))
            else
                self.m_farthestTargetID = 0
            end
            self.m_targetMoveDis = FixAdd(self.m_targetMoveDis, targetMoveDis)
        end
        
        local pos = self.m_position - performer:GetPosition()
        pos.y = 0
        local sqrDistance = pos:SqrMagnitude()
        if sqrDistance <= 0.2 then 
            self:Over()
            return
        end
    elseif self.m_mediumState == MediumState.Over then
        self:Over()
        return
    end
end


function Medium10352:SelectFarthestTarget(performer)
    local performer = self:GetOwner()
    if not performer then
        self:Over()
        return
    end

    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    if not battleLogic or not skillCfg or not self.m_skillBase then
        return
    end

    local target = false
    local maxDis = 0

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not tmpTarget:IsLive() then
                return 
            end

            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInCircle(self.m_position, 1, tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                return
            end

            local dir = tmpTarget:GetPosition() - performer:GetPosition()
            dir.y = 0
            local distance = dir:Magnitude()
            if distance > maxDis then
                target = tmpTarget
                maxDis = distance
            end
        end
    )

   
    return target, FixDiv(maxDis, 6)  
end


return Medium10352