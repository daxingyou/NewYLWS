local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixIntMul = FixMath.muli
local GetSkillCfgByID = ConfigUtil.GetSkillCfgByID
local BattleEnum = BattleEnum
local SkillUtil = SkillUtil
local factory = StatusFactoryInst
local StatusGiver = StatusGiver
local StatusEnum = StatusEnum
local ACTOR_ATTR = ACTOR_ATTR

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1004 = BaseClass("Actor1004", Actor)

function Actor1004:__init()
    self.m_isAlmostDie = false
    self.m_wudiCount = 0
    self.m_skill10041Count = 0
    self.m_1004originalPos = 0
    self.m_1004originalPerformerPos = 0
    
    self.m_speed = 0
    self.m_10041Time = 0
    self.m_isFightEnd = false
    self.m_10043Level = 0
    self.m_10043Y = 0
    self.m_10043SkillCfg = nil

    self.m_clearNBuff = false
end

function Actor1004:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skill10043Item = self.m_skillContainer:GetPassiveByID(10043)
    if skill10043Item then
        local skill10043Cfg = ConfigUtil.GetSkillCfgByID(10043)
        if skill10043Cfg then
            self.m_10043Level = skill10043Item:GetLevel()
            self.m_10043SkillCfg = skill10043Cfg
            self.m_10043Y = SkillUtil.Y(skill10043Cfg, self.m_10043Level)
        end
    end
end

function Actor1004:Get10043SkillCfg()
    return self.m_10043SkillCfg
end

function Actor1004:Get10043Y()
    return self.m_10043Y
end

function Actor1004:Get10043Level()
    if not self.m_10043SkillCfg then
        return 0
    end

    return self.m_10043Level
end

function Actor1004:Set10041Time(time)
    self.m_10041Time = time
end

function Actor1004:Get10041Time()
    return self.m_10041Time
end

function Actor1004:SetSpeed(speed)
    self.m_speed = speed
end

function Actor1004:GetSpeed()
    return self.m_speed
end

function Actor1004:SetOriginalPos(pos)
    self.m_1004originalPos = pos
end

function Actor1004:GetOriginalPos()
    return self.m_1004originalPos
end

function Actor1004:GetOriginalPerformerPos()
    return self.m_1004originalPerformerPos
end

function Actor1004:SetOriginalPerformerPos(pos)
    self.m_1004originalPerformerPos = pos
end

function Actor1004:AddSkill10041Count(count)
    self.m_skill10041Count = FixAdd(self.m_skill10041Count, count)
end

function Actor1004:IsWudi()
    return self.m_isAlmostDie
end

function Actor1004:PreChgHP(giver, chgHP, hurtType, reason)
    chgHP = Actor.PreChgHP(self, giver, chgHP, hurtType, reason)

    if not self.m_isAlmostDie then
        local curHP = self:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
        local reChgHP = FixAdd(curHP, chgHP)
        if reChgHP <= 1 then -- Actor 687
            chgHP = FixSub(1, curHP)
            self.m_isAlmostDie = true
        end
    end
    return chgHP
end

function Actor1004:OnHPChg(giver, deltaHP, hurtType, reason, keyFrame)
    Actor.OnHPChg(self, giver, deltaHP, hurtType, reason, keyFrame)

    if self.m_wudiCount > 0 then
        return
    end

    if not self.m_isAlmostDie then
        return
    end

    local skillItem = self:GetSkillContainer():GetPassiveByID(10043)
    if not skillItem then
        return
    end
    
    -- 攻速算法做加法，例如本来攻速是120%，此时会变成(120+x1)%	
    -- 赵云受到致命伤害时，保留1点生命，进入无敌时间{a}秒，在此期间免疫一切控制效果并提升{X1}%攻速。	无敌
    -- 赵云受到致命伤害时，保留1点生命，进入无敌时间{a}秒，在此期间免疫一切控制效果并提升{X2}%攻速。
    -- 赵云受到致命伤害时，保留1点生命，进入无敌时间{a}秒，在此期间免疫一切控制效果并提升{X3}%攻速。	
    -- 赵云受到致命伤害时，保留1点生命，进入无敌时间{a}秒，在此期间免疫一切控制效果并提升{X4}%攻速。赵云在本场战斗中每发动过1次透阵，此时就额外回复{Y4}点怒气，并令无敌状态的时间延长{b}秒。	
    -- 赵云受到致命伤害时，保留1点生命，进入无敌时间{a}秒，在此期间免疫一切控制效果并提升{X5}%攻速。赵云在本场战斗中每发动过1次透阵，此时就额外回复{Y5}点怒气，并令无敌状态的时间延长{b}秒。	
    -- 赵云受到致命伤害时，保留1点生命，进入无敌时间{a}秒，在此期间免疫一切控制效果并提升{X6}%攻速。赵云在本场战斗中每发动过1次透阵，此时就额外回复{Y6}点怒气，并令无敌状态的时间延长{b}秒。

    local skillCfg = GetSkillCfgByID(10043)
    if not skillCfg then
        return
    end
    
    local wudiTime = FixMul(skillCfg.A, 1000)

    local skillLevel = skillItem:GetLevel()
    if skillLevel > 3 then
        if self.m_skill10041Count > 0 then
            wudiTime = FixAdd(wudiTime, FixMul(self.m_skill10041Count, FixMul(skillCfg.B, 1000)))
        end
    end

    local giver = StatusGiver.New(self:GetActorID(), 10043)

    local wudiBuff = factory:NewStatusZhaoYunWudi(giver, wudiTime, {100407})
    
    wudiBuff:SetCanClearByOther(false)
    local addSuc = self:GetStatusContainer():Add(wudiBuff, self)
    if addSuc then
        self.m_clearNBuff = true
    end

    self.m_wudiCount = FixAdd(self.m_wudiCount, 1) 
    local immuneBuff = factory:NewStatusImmune(giver, wudiTime)
    immuneBuff:SetMergeRule(StatusEnum.MERGERULE_TOGATHER)
    immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_CONTROL)
    immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_STUN)
    immuneBuff:SetCanClearByOther(false) 
    self:GetStatusContainer():DelayAdd(immuneBuff)
    
    local atkSpeedMul = FixDiv(SkillUtil.X(skillCfg, skillItem:GetLevel()), 100)
    local curAtkSpeed = self:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
    local chgAtkSpeed = FixIntMul(atkSpeedMul, curAtkSpeed)
    local atkSpeedBuff = factory:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, wudiTime)
    atkSpeedBuff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, chgAtkSpeed)
    atkSpeedBuff:SetMergeRule(StatusEnum.MERGERULE_MERGE)
    self:GetStatusContainer():DelayAdd(atkSpeedBuff)
end

function Actor1004:OnAttackEnd(skillCfg)
    local movehelper = self:GetMoveHelper()
    if movehelper then
        movehelper:Stop()
    end
    Actor.OnAttackEnd(self, skillCfg)
end

function Actor1004:LogicOnFightEnd()
    self.m_isFightEnd = true
end


function Actor1004:LogicOnFightStart(currWave)
    self.m_isFightEnd = false
end


function Actor1004:IsFightEnd()
      return self.m_isFightEnd
end

function Actor1004:LogicUpdate(deltaMS)
    if self.m_clearNBuff then
        self.m_clearNBuff = false
        self:GetStatusContainer():ClearBuff(StatusEnum.CLEARREASON_NEGATIVE) -- 无敌时，触发无敌效果
    end
end

return Actor1004