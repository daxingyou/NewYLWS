local StatusEnum = StatusEnum
local FixSub = FixMath.sub
local FixAdd = FixMath.add

local StatusBase = require("GameLogic.Battle.Status.StatusBase")
local StatusNextNHurtOtherMul = BaseClass("StatusNextNHurtOtherMul", StatusBase)

local StatusUseState = {
    Used = 0,
    Never = 1
}

function StatusNextNHurtOtherMul:__init()
    self.m_giver = false
    self.m_hurtMulList = false
    self.m_key = false
    self.m_isOnce = false
    self.m_statusUseState = StatusUseState.Never
    self.m_mergeRule = StatusEnum.MERGERULE_TOGATHER
end

function StatusNextNHurtOtherMul:Init(giver, skillTypeList, isOnce)
    self.m_giver = giver
    self.m_hurtMulList = false
    self.m_isOnce = isOnce
    self.m_key = false
    self.m_statusUseState = StatusUseState.Never
    self:InitSkillList(skillTypeList)
end

function StatusNextNHurtOtherMul:InitSkillList(skillTypeList)
    if not self.m_hurtMulList then
        self.m_hurtMulList = {}
    end
    if skillTypeList then
        for _,v in pairs(skillTypeList) do
            self.m_hurtMulList[v.skillType] = {m_hurtPercent = v.hurtPercent, m_leftCount = v.leftCount}
        end
    end
end

function StatusNextNHurtOtherMul:GetStatusType()
    return StatusEnum.STAUTSTYPE_NEXT_N_HURTOTHERMUL
end

function StatusNextNHurtOtherMul:GetHurtMul(skillType)
    if not self.m_hurtMulList then
        return 0
    end

    local skillTypeList = self.m_hurtMulList[skillType]
    if skillTypeList then
        if skillTypeList.m_leftCount > 0 then
            if skillTypeList then
                self.m_statusUseState = StatusUseState.Used
                skillTypeList.m_leftCount = FixSub(skillTypeList.m_leftCount, 1)
                return FixAdd(skillTypeList.m_hurtPercent, 1)
            end
        end
    end
    
    return 0
end

function StatusNextNHurtOtherMul:Update(deltaMS, actor)
    if self.m_isOnce then
        if self.m_statusUseState == StatusUseState.Used then
            return StatusEnum.STATUSCONDITION_END
        end
    end

    if self.m_hurtMulList then
        for _,skillTypeList in pairs(self.m_hurtMulList) do
            if skillTypeList then
                if skillTypeList.m_leftCount > 0 then
                    return StatusEnum.STATUSCONDITION_CONTINUE
                end
            end
        end
    end

    return StatusEnum.STATUSCONDITION_END
end

function StatusNextNHurtOtherMul:IsPositive()
    if self.m_hurtMulList then
        for _,skillTypeList in pairs(self.m_hurtMulList) do
            if skillTypeList then
                if skillTypeList.m_hurtPercent > 0 then
                    return true
                end
            end
        end
    end

    return false
end


return StatusNextNHurtOtherMul