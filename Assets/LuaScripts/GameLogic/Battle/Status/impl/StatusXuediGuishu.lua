local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusEnum = StatusEnum
local FixSub = FixMath.sub

local StatusXuediGuishu = BaseClass("StatusXuediGuishu", StatusBase)

function StatusXuediGuishu:__init()
    self.m_effectKey = -1
    self.m_chgNuqi = 0
    self.m_magicPercent = 0
    self.m_maxMagicPercent = 0
    self.m_skillCfg = nil
end

function StatusXuediGuishu:Init(giver, leftMS, chgNuqi, magicPercent, maxPercent, skillCfg, effect)
    self.m_giver = giver
    self.m_effectMask = effect
    self.m_mergeRule = StatusEnum.MERGERULE_NEW_LEFT
    self:SetLeftMS(leftMS)
    self.m_effectKey = -1
    self.m_chgNuqi = chgNuqi
    self.m_magicPercent = magicPercent
    self.m_maxMagicPercent = maxPercent
    self.m_skillCfg = skillCfg
end

function StatusXuediGuishu:GetMagicPercent()
    return self.m_magicPercent
end

function StatusXuediGuishu:GetChgNuqi()
    return self.m_chgNuqi
end

function StatusXuediGuishu:GetSkillCfg()
    return self.m_skillCfg
end

function StatusXuediGuishu:GetStatusType()
    return StatusEnum.STATUSTYPE_GUISHU
end

function StatusXuediGuishu:GetMaxMagicPercent()
    return self.m_maxMagicPercent
end

function StatusXuediGuishu:Effect(actor)
    if actor then 
        if self.m_effectMask and #self.m_effectMask > 0 then
            self.m_effectKey = self:ShowEffect(actor, self.m_effectMask[1])
        end
    end

    return false
end

function StatusXuediGuishu:ClearEffect(actor)
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
        self.m_effectKey = -1
    end

    self.m_chgNuqi = 0
    self.m_magicPercent = 0
    self.m_maxMagicPercent = 0
    self.m_skillCfg = nil
end

function StatusXuediGuishu:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    if self.m_leftMS > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE
    end
    
    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END
end


function StatusXuediGuishu:IsPositive()
    return false
end

return StatusXuediGuishu