local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local table_insert = table.insert
local StatusEnum = StatusEnum
local BattleEnum = BattleEnum
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local CtlBattleInst = CtlBattleInst

local StatusNextNBeHurtChg = BaseClass("StatusNextNBeHurtChg", StatusBase)

function StatusNextNBeHurtChg:__init()
    self.m_leftCount = 0
    self.m_hurtType = 0
    self.m_fixedHurt = 0 --负数
    self.m_effectKey = -1
end

function StatusNextNBeHurtChg:Init(giver, effectCount, hurtType, fixedHurt, effect)
    self.m_giver = giver
    self.m_leftCount = effectCount
    self.m_hurtType = hurtType
    self.m_fixedHurt = fixedHurt --负数

    if effect then
        self:SetEffectMask(effect)
    end

    self.m_effectKey = -1
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT --看效果是否叠加
end

function StatusNextNBeHurtChg:GetStatusType()
    return StatusEnum.STAUTSTYPE_NEXT_N_BEHURTCHG
end

function StatusNextNBeHurtChg:Update(deltaMS, actor)
    if self.m_leftCount > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE
    end
    
    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END
end

function StatusNextNBeHurtChg:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end
end

function StatusNextNBeHurtChg:Effect(actor)
    if actor then
        if self.m_effectMask and #self.m_effectMask > 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end
    end
    
    return false
end


function StatusNextNBeHurtChg:ReplaceHurt(hurt, hurtType)
    --伤害类型
    if self.m_hurtType ~= BattleEnum.HURTTYPE_REAL_HURT and hurtType ~= self.m_hurtType then
        return hurt
    end

    --负数比较
    if hurt > self.m_fixedHurt then
        return hurt
    end

    self.m_leftCount = FixSub(self.m_leftCount, 1)
    return self.m_fixedHurt
end


return StatusNextNBeHurtChg