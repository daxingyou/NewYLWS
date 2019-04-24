local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixMod = FixMath.mod
local FixMul = FixMath.mul
local ActorManagerInst = ActorManagerInst
local BattleEnum = BattleEnum
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local Factor = Factor
local ConfigUtil = ConfigUtil
local FixRand = BattleRander.Rand

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium20903 = BaseClass("Medium20903", LinearFlyToTargetMedium)

function Medium20903:ArriveDest()
    self:Hurt()
end

function Medium20903.CreateParam(targetActorID, keyFrame, speed, hurtType)
    local p = {
        targetActorID = targetActorID,
        keyFrame = keyFrame,
        speed = speed,
        hurtType = hurtType
    }
    return p
end


function Medium20903:Hurt()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local skillCfg = self:GetSkillCfg()
    
    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end
    
    if self.m_param.reason == BattleEnum.HPCHGREASON_NONE then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, self.m_param.hurtType, true)
    if Formular.IsJudgeEnd(judge) then
        return
    end
    
    local injure = Formular.CalcInjure(performer, target, skillCfg, self.m_param.hurtType, judge, self.m_skillBase:X())
    if injure > 0 then
        local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), self.m_param.hurtType, BattleEnum.HPCHGREASON_BY_SKILL, judge, self.m_param.keyFrame)
        self:AddStatus(performer, target, status)
    end

    --"张昭的普通攻击有<color=#1aee00>{A}%</color>的几率使目标进入撕裂状态，受到的治疗效果降低<color=#ffb400>{x1}%</color>，持续<color=#1aee00>{B}</color>秒。",
    --"治疗降低的效果提升至<color=#ffb400>{x2}</color>",
    --"治疗降低的效果提升至<color=#ffb400>{x3}</color>",
    --"治疗降低的效果提升至<color=#ffb400>{x4}</color>\n新效果：另有<color=#1aee00>{C}%</color>的几率使目标进入虚弱状态，
    --受到的伤害增加<color=#ffb400>{y4}%</color>，持续<color=#1aee00>{D}</color>秒",

    
    local skillItem = performer:GetSkillContainer():GetPassiveByID(20903)
    if skillItem  then
        local skillCfg = ConfigUtil.GetSkillCfgByID(20903)
        if not skillCfg then
            return
        end

        local level20903 = skillItem:GetLevel()

        local randVal = FixMod(FixRand(), 100)
        if randVal <= SkillUtil.A(skillCfg, level20903) then
            local b = FixMul(SkillUtil.B(skillCfg, level20903), 1000)
            local recoverMulStatus = StatusFactoryInst:NewStatusRecoverPercent(self.m_giver, b, FixMul(-1, FixDiv(SkillUtil.X(skillCfg, level20903), 100)))
            local addsuc = self:AddStatus(performer, target, recoverMulStatus) 
            if addsuc then
                target:ShowSkillMaskMsg(0, BattleEnum.SKILL_MASK_HUANGXIONG, TheGameIds.BattleBuffMaskBlack)
            end
        end

        if level20903 >= 4 then
            local randVal = FixMod(FixRand(), 100)
            if randVal <= SkillUtil.C(skillCfg, level20903) then
                local d = FixMul(SkillUtil.D(skillCfg, level20903), 1000)
                local mul = FixAdd(1, FixDiv(self.m_skillBase:Y(), 100))
                local statusWeakNew = StatusFactoryInst:NewStatusWeak(self.m_giver, d, mul, {21015})
                self:AddStatus(performer, target, statusWeakNew)
            end
        end
    end
end


return Medium20903