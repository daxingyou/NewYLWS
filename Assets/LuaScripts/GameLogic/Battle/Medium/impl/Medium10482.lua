local BattleEnum = BattleEnum
local Formular = Formular
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local StatusGiver = StatusGiver
local FixAdd = FixMath.add

local LinearFlyToTargetMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToTargetMedium")
local Medium10482 = BaseClass("Medium10482", LinearFlyToTargetMedium)

function Medium10482:Mark()
    local performer = self:GetOwner()
    if not performer then
        return
    end

    local skillCfg = self:GetSkillCfg()
    if not skillCfg or not self.m_skillBase then
        return
    end

    -- name = 凤舞霓裳
    -- 貂蝉舞起霓裳，持续{a}秒，期间每{b}秒向敌方1个随机单位发射1枚莲花印记。每个单位身上最多叠加{c}层莲花印记。
    -- 貂蝉舞起霓裳，持续{a}秒，期间每{b}秒向敌方1个随机单位发射1枚莲花印记。每个单位身上最多叠加{c}层莲花印记。貂蝉凤舞霓裳期间受到的伤害减免{X2}%。
    -- 貂蝉在原地旋转起舞，持续{a}秒。每{b}秒向敌方随机单位发射1枚莲花印记。每个单位身上最多叠加{c}层莲花印记。貂蝉凤舞霓裳期间受到的伤害减免{X3}%。
    -- 貂蝉在原地旋转起舞，持续{a}秒。每{b}秒向敌方随机单位发射1枚莲花印记。每个单位身上最多叠加{c}层莲花印记。貂蝉凤舞霓裳期间受到的伤害减免{X4}%。
    -- 貂蝉在原地旋转起舞，持续{a}秒。每{b}秒向敌方随机单位发射1枚莲花印记。每个单位身上最多叠加{c}层莲花印记。貂蝉凤舞霓裳期间受到的伤害减免{X5}%。
    -- 貂蝉在原地旋转起舞，持续{a}秒。每{b}秒向敌方随机单位发射1枚莲花印记。每个单位身上最多叠加{c}层莲花印记。貂蝉凤舞霓裳期间受到的伤害减免{X6}%，且不受控制技能打断。
    
    local target = ActorManagerInst:GetActor(self.m_param.targetActorID)
    if not target or not target:IsLive() then
        return
    end

    local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_MAGIC_HURT, true)
    if Formular.IsJudgeEnd(judge) then
       return 
    end
    --每发射一个莲花印记，就为自身回复x%法攻的生命
    local recoverHP, _ = Formular.CalcRecover(BattleEnum.HURTTYPE_MAGIC_HURT, performer, performer, skillCfg,  self.m_skillBase:X()) 
    local statusHP = StatusFactoryInst:NewStatusHP(self.m_giver, recoverHP, BattleEnum.HURTTYPE_REAL_HURT, 
                             BattleEnum.HPCHGREASON_BY_SKILL, judge, self.m_param.keyFrame)

    self:AddStatus(performer, performer, statusHP)

    local markCount = 0 
    local diaochanMark = target:GetStatusContainer():GetDiaoChanMark()
    if diaochanMark then
        markCount = diaochanMark:GetMarkCount()
        if markCount < self.m_skillBase:C() then
            diaochanMark:AddMarkCount(1)
            target:ShowSkillMaskMsg(FixAdd(markCount, 1), BattleEnum.SKILL_MASK_DIAOCHAN, TheGameIds.BattleBuffMaskRed)
        end
    else
        local giver = StatusGiver.New(performer:GetActorID(), 10482)
        diaochanMark = StatusFactoryInst:NewStatusDiaoChanMark(giver)
        diaochanMark:AddMarkCount(1)
        local addSuc = self:AddStatus(performer, target, diaochanMark) -- 添加成功飘特效
        if addSuc then
            target:ShowSkillMaskMsg(FixAdd(markCount, 1), BattleEnum.SKILL_MASK_DIAOCHAN, TheGameIds.BattleBuffMaskRed)
        end
    end

    target:AddEffect(104807)
end

function Medium10482:ArriveDest()
    self:Mark()
end

return Medium10482