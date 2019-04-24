local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local BattleEnum = BattleEnum
local BattleRecordEnum = BattleRecordEnum
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst

local BattleDragon = BaseClass("BattleDragon")

function BattleDragon:__init(camp)
    self.m_camp = camp
    self.m_dragonData = nil
    self.m_dragonSkill = nil
    self.m_isExecuted = false
    self.m_isExecuting = false
    self.m_effectIndex = 0
    self.m_hpCondition = 0
    self.m_leftHP = 0
    self.m_fakeActorID = 0
end

function BattleDragon:__delete()
    self.m_camp = 0
    self.m_dragonData = nil
    self.m_dragonSkill = nil
    self.m_isExecuted = false
    self.m_isExecuting = false
    self.m_effectIndex = 0
    self.m_hpCondition = 0
    self.m_leftHP = 0
    self.m_fakeActorID = 0
end

function BattleDragon:MakeDragonActorID(wujiangID)
    self.m_fakeActorID = self.m_camp * 100000000 + (wujiangID + BattleEnum.DRAGON_ACTOR_ID_OFFSET) * 10000 + self.m_dragonData.dragonLevel

    local damageRecorder = CtlBattleInst:GetLogic():GetDamageRecorder()
    if damageRecorder then
        damageRecorder:AddSummonActor(self.m_fakeActorID, self.m_camp, wujiangID)
    end
end

function BattleDragon:InitData(dragonData)
    self.m_dragonData = dragonData
    
    local dragonCfg = ConfigUtil.GetGodBeastCfgByID(self.m_dragonData.dragonID)
    if not dragonCfg then
        return
    end

    self:InitSkill(dragonCfg.role_id)
end

function BattleDragon:Init()
    local dragonCfg = ConfigUtil.GetGodBeastCfgByID(self.m_dragonData.dragonID)
    if not dragonCfg then
        return
    end

    self:InitPerformCondition()

    self:MakeDragonActorID(dragonCfg.role_id)
end

function BattleDragon:InitSkill(wujiangID)
    local skillClass = require("GameLogic.Battle.BattleLogic.Dragon.impl.DragonSkill"..wujiangID)
    self.m_dragonSkill = skillClass.New(self.m_dragonData, self)
end

function BattleDragon:InitPerformCondition()
    self.m_hpCondition = 0
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() and tmpTarget:GetCamp() == self.m_camp and not tmpTarget:IsCalled() then
                self.m_hpCondition = FixAdd(self.m_hpCondition, tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP))
            end
        end
    )

    local hpPercent = FixDiv(self.m_dragonSkill:GetHPConditionPercent(), 100)
    if hpPercent < 0 then
        hpPercent = 0
    elseif hpPercent > 1 then
        hpPercent = 1
    end
    self.m_hpCondition = FixMul(self.m_hpCondition, hpPercent)
    self.m_leftHP = self.m_hpCondition
end

function BattleDragon:UpdateHP(receiver, hpChange)
    if receiver and not receiver:IsCalled() and not receiver:IsPartner() then
        if hpChange < 0 then
            self.m_leftHP = FixAdd(self.m_leftHP, hpChange)
        end
    end
end

function BattleDragon:GetConditionPercent()
    if self.m_isExecuted then
        return 0
    end
    if self.m_hpCondition <= 0 then
        return 0
    elseif self.m_leftHP > self.m_hpCondition then
        return 0
    elseif self.m_leftHP > 0 then
        local leftPercent = FixDiv(self.m_leftHP, self.m_hpCondition)
        return FixSub(1, leftPercent)
    else
        return 1
    end
end

function BattleDragon:PerformDragonSkill()
    if not self:CanSummon() then
        return false
    end
    self.m_isExecuting = true
    self.m_isExecuted = true

    self:DoPerformSummon()
    return true
end

function BattleDragon:DoPerformSummon()
    local summonCfg = self.m_dragonSkill:GetDragonCfg()
    if summonCfg then
        if not CtlBattleInst:GetLogic():IsPlayDragonSkillShow() then
            CtlBattleInst:GetLogic():OnDragonSkillPerform(self.m_camp)
            FrameDebuggerInst:FrameRecord(BattleRecordEnum.EVENT_TYPE_SUMMON, self.m_camp, summonCfg.role_id, self.m_dragonData.dragonLevel, BattleRecordEnum.SUMMON_REASON_BEGIN)
            self:PerformDragonSkillImmediate()
        else
            DragonTimelineMgr:Play(summonCfg.role_id, summonCfg.timelineName, function(isServer)
                if isServer then
                    FrameDebuggerInst:FrameRecord(BattleRecordEnum.EVENT_TYPE_SUMMON, self.m_camp, summonCfg.role_id, self.m_dragonData.dragonLevel, BattleRecordEnum.SUMMON_REASON_BEGIN)
                    self:PerformDragonSkillImmediate()
                else
                    FrameCmdFactory:GetInstance():ProductCommand(BattleEnum.FRAME_CMD_TYPE_SUMMON_PERFORM, self.m_camp)
                end
            end)
        end
    end
end

function BattleDragon:PerformDragonSkillImmediate()
    if self.m_dragonSkill then
        -- TODO 播放音效
        -- AudioMgr.instance.AddAudio(m_dragonSkill.GetDragonCfg().performAudio)
        local summonCfg = self.m_dragonSkill:GetDragonCfg()

        while self.m_dragonSkill:PerfromDragonSkill(self) do
            if summonCfg then
                FrameDebuggerInst:FrameRecord(BattleRecordEnum.EVENT_TYPE_SUMMON, self.m_camp, summonCfg.role_id, self.m_dragonData.dragonLevel, BattleRecordEnum.SUMMON_REASON_EFFECT_END)
            end

            self.m_effectIndex = self.m_effectIndex + 1
        end

        if summonCfg then
            FrameDebuggerInst:FrameRecord(BattleRecordEnum.EVENT_TYPE_SUMMON, self.m_camp, summonCfg.role_id, self.m_dragonData.dragonLevel, BattleRecordEnum.SUMMON_REASON_END)
        end
    end
 
    self.m_isExecuting = false
end

function BattleDragon:CanSummon()
    if self.m_isExecuted then
        -- Logger.Log("Summon has already executed")
        return false
    end
    if self.m_leftHP > 0 then
        -- Logger.Log("Did not reach HP condition")
        return false
    end
    if ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_LEFT) then
        -- Logger.Log("My Camp has all die")
        return false
    end
    if ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_RIGHT) then
        -- Logger.Log("Enemy Camp has all die")
        return false
    end

    return true
end

function BattleDragon:IsExecuting()
    return self.m_isExecuting
end

function BattleDragon:GetCamp()
    return self.m_camp
end

function BattleDragon:IsExecuted()
    return self.m_isExecuted
end

function BattleDragon:GetEffectIndex()
    return self.m_effectIndex
end

function BattleDragon:GetFakeActorID()
    return self.m_fakeActorID
end

function BattleDragon:GetDragonSkill()
    return self.m_dragonSkill
end

function BattleDragon:GetDragonLevel()
    return self.m_dragonData.dragonLevel
end

return BattleDragon