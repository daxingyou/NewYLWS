local FixMul = FixMath.mul
local FixFloor = FixMath.floor
local FixSub = FixMath.sub
local FixMod = FixMath.mod
local FixAdd = FixMath.add
local table_insert = table.insert
local FixRand = BattleRander.Rand
local SkillUtil = SkillUtil
local GetSkillCfgByID = ConfigUtil.GetSkillCfgByID
local CtlBattleInst = CtlBattleInst

local SkillContainer = BaseClass("SkillContainer")

function SkillContainer:__init()
    self.m_atkList = {}
    self.m_activeList = {}
    self.m_passiveList = {}
    self.m_dazhaoIndex = 1
    self.m_globalCD = SKILL_CD.GLOBAL
    self.m_normalDisSqr = 0
    self.m_nextAtkIdx = -1
    self.m_nextSkillIdx = -1
end

function SkillContainer:__delete()
    self.m_atkList = nil
    self.m_activeList = nil
    self.m_passiveList = nil
end

function SkillContainer:AddActive(skillItem)
    table_insert(self.m_activeList, skillItem)

    local cfg = GetSkillCfgByID(skillItem:GetID())
    if cfg and SkillUtil.IsDazhao(cfg) then        
        self.m_dazhaoIndex = #self.m_activeList
    end
end

function SkillContainer:AddPassive(skillItem)
    table_insert(self.m_passiveList, skillItem)
end

function SkillContainer:AddAtk(skillItem)
    table_insert(self.m_atkList, skillItem)

    if self.m_normalDisSqr <= 0 then
        local skillCfg = GetSkillCfgByID(skillItem:GetID())
        if skillCfg then
            self.m_normalDisSqr = skillCfg.disSqr2
        end
    end
end

function SkillContainer:GetAtkableDisSqr()
    return self.m_normalDisSqr
end

function SkillContainer:GetDazhao()
    return self.m_activeList[self.m_dazhaoIndex]
end

function SkillContainer:GetNextAtk()
    if self.m_nextAtkIdx > 0 and self.m_nextAtkIdx <= #self.m_atkList then
        local tmp = self.m_atkList[self.m_nextAtkIdx]
        self.m_nextAtkIdx = -1
        return tmp
    end

    local randVal = FixMod(FixRand() , 100)
    if randVal < 50 then
        return self.m_atkList[1]
    end

    if self.m_atkList[2] then
        return self.m_atkList[2]
    end

    return self.m_atkList[1]
end

function SkillContainer:SetNextAtkIndex(index)
    self.m_nextAtkIdx = index
end

function SkillContainer:SetNextSkillID(skillID)
    for i, skillItem in ipairs(self.m_activeList) do
        if skillItem:IsEqual(skillID) then
            skillItem:SetLeftCD(0)
            self.m_nextSkillIdx = i
            break
        end
    end
end

function SkillContainer:ResetAllActiveCD()
    for _, skillItem in ipairs(self.m_activeList) do
        skillItem:SetLeftCD(0)
    end
end

function SkillContainer:ResetOneActiveCD(skillID)
    for _, skillItem in ipairs(self.m_activeList) do
        if skillItem:GetID() == skillID then
            skillItem:SetLeftCD(0)
            break
        end
    end
end

function SkillContainer:GetNextSkill()
    if self.m_nextSkillIdx > 0 and self.m_nextSkillIdx <= #self.m_activeList then
        local tmp = self.m_nextSkillIdx
        self.m_nextAtkIdx = -1
        return self.m_activeList[tmp]
    end

    return nil
end

function SkillContainer:GetActiveCount()
    return #self.m_activeList
end

function SkillContainer:GetActiveByIdx(index)
    return self.m_activeList[index]
end

function SkillContainer:GetActiveByID(skillID)
    for _, skillItem in ipairs(self.m_activeList) do
        if skillItem:IsEqual(skillID) then
            return skillItem
        end
    end
    return nil
end

function SkillContainer:GetPassiveCount()
    return #self.m_passiveList
end

function SkillContainer:GetPassiveByIdx(index)
    return self.m_passiveList[index]
end

function SkillContainer:GetPassiveByID(skillID)
    for _, skillItem in ipairs(self.m_passiveList) do
        if skillItem:IsEqual(skillID) then
            return skillItem
        end
    end
    return nil
end

function SkillContainer:GetAtkCount()
    return #self.m_atkList
end

function SkillContainer:GetAtkByIdx(index)
    return self.m_atkList[index]
end

function SkillContainer:GetByID(skillID)
    for _, skillItem in ipairs(self.m_activeList) do
        if skillItem:IsEqual(skillID) then
            return skillItem
        end
    end

    for _, skillItem in ipairs(self.m_atkList) do
        if skillItem:IsEqual(skillID) then
            return skillItem
        end
    end

    for _, skillItem in ipairs(self.m_passiveList) do
        if skillItem:IsEqual(skillID) then
            return skillItem
        end
    end

    return nil
end

function SkillContainer:PerformBegin(skillCfg)
    if SkillUtil.IsAtk(skillCfg) then
        for _, skillItem in ipairs(self.m_atkList) do
            if skillItem:GetLeftCD() < self.m_globalCD then
                skillItem:SetLeftCD(self.m_globalCD)
            end
        end
    end
end

function SkillContainer:PerformEnd(skillCfg)
    if not SkillUtil.IsAtk(skillCfg) then
        local commonCD = CtlBattleInst:GetLogic():GetSkillCommonCD()

        for _, skillItem in ipairs(self.m_activeList) do
            if skillItem:GetLeftCD() < commonCD then
                skillItem:SetLeftCD(commonCD)
            end
        end
    end
end

function SkillContainer:Update(deltaMS, atkSpeed)
    local realDelta = FixFloor(FixMul(deltaMS, atkSpeed))

    for _, skillItem in ipairs(self.m_atkList) do
        if skillItem:GetLeftCD() > 0 then
            skillItem:SetLeftCD(FixSub(skillItem:GetLeftCD(), realDelta))
        end
    end

    for _, skillItem in ipairs(self.m_activeList) do
        if skillItem:GetLeftCD() > 0 then
            skillItem:SetLeftCD(FixSub(skillItem:GetLeftCD(), deltaMS))
        end
    end
end

function SkillContainer:SetGlobalCD(globalCD)
    self.m_globalCD = globalCD
end

function SkillContainer:ResetAtkCD(index)
    if not index or index == 0 then
        for _, skillItem in ipairs(self.m_atkList) do
            skillItem:SetLeftCD(0)
        end
        return
    end
    local skillItem = self.m_atkList[index]
    if skillItem then
        skillItem:SetLeftCD(0)
    end
end

function SkillContainer:ResetSkillFirstCD(extraActiveSkillCDMS, extraAtkCDMS, reducePercent)
    extraActiveSkillCDMS = extraActiveSkillCDMS or 0
    extraAtkCDMS = extraAtkCDMS or 0
    reducePercent = reducePercent or 0

    local tmpExtraActSkillCDMS = 0
    for _, skillItem in ipairs(self.m_activeList) do
        local skillCfg = GetSkillCfgByID(skillItem:GetID())
        if skillCfg then
            tmpExtraActSkillCDMS = extraActiveSkillCDMS
            local firstcdMS = FixMul(skillCfg.firstcd, 1000)
            local chgTime = FixMul(firstcdMS, reducePercent)
            tmpExtraActSkillCDMS = FixSub(tmpExtraActSkillCDMS, chgTime)
            skillItem:SetDurCD(FixFloor(FixAdd(firstcdMS, tmpExtraActSkillCDMS)))
            skillItem:ResetCD()
        end
    end

    for _, skillItem in ipairs(self.m_atkList) do
        local skillCfg = GetSkillCfgByID(skillItem:GetID())
        if skillCfg then
            skillItem:SetDurCD(FixFloor(FixAdd(FixMul(skillCfg.firstcd, 1000), extraAtkCDMS)))
            skillItem:ResetCD()

        end
    end
end

function SkillContainer:ReduceCD(delta)
    for _, skillItem in ipairs(self.m_activeList) do
        skillItem:ReduceCD(delta)
    end
end

function SkillContainer:IsSkillCDLessThan(cd)
    for idx, skillItem in ipairs(self.m_activeList) do
        if idx ~= self.m_dazhaoIndex then
            if skillItem:GetLeftCD() <= cd then
                return true
            end
        end
    end

    return false
end

return SkillContainer