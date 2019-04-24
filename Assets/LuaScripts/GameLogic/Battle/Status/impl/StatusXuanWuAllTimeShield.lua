
local StatusAllTimeShield = require("GameLogic.Battle.Status.impl.StatusAllTimeShield")
local table_insert = table.insert
local StatusEnum = StatusEnum
local BattleEnum = BattleEnum
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local StatusGiver = StatusGiver

local StatusXuanWuAllTimeShield = BaseClass("StatusXuanWuAllTimeShield", StatusAllTimeShield)

function StatusXuanWuAllTimeShield:__init()
    self.m_frozenActorIDList = {}
    self.m_frozenTime = 0
end

function StatusXuanWuAllTimeShield:Init(giver, hpStore, leftMS, frozenActorIDList, frozenTime, effect)
    StatusAllTimeShield.Init(self, giver, hpStore, leftMS, effect)
    self.m_frozenActorIDList = frozenActorIDList
    self.m_frozenTime = frozenTime
    self:SetLeftMS(leftMS)
end

function StatusXuanWuAllTimeShield:Effect(actor)
    StatusAllTimeShield.Effect(self, actor)
    for actorID, _ in pairs(self.m_frozenActorIDList) do
        local tmpTarget = ActorManagerInst:GetActor(actorID)
        if tmpTarget and tmpTarget:IsLive() then
            local giver = StatusGiver.New(actor:GetActorID(), 35061)
            local status = StatusFactoryInst:NewStatusFrozen(giver, self.m_frozenTime)
            tmpTarget:GetStatusContainer():Add(status, actor)
        end
    end
end

function StatusXuanWuAllTimeShield:BeforeClearFrozen()
    for actorID, _ in pairs(self.m_frozenActorIDList) do
        local tmpTarget = ActorManagerInst:GetActor(actorID)
        if tmpTarget and tmpTarget:IsLive() then
            local frozenBuff = tmpTarget:GetStatusContainer():GetFrozenBuff()
            if frozenBuff then
                frozenBuff:SetLeftMS(0)
            end
        end
    end
end

function StatusXuanWuAllTimeShield:GetStatusType()
    return StatusEnum.STATUSTYPE_XUANWUALLTIMESHIELD
end

function StatusXuanWuAllTimeShield:Update(deltaMS, actor)
    self.m_leftMS = FixSub(self.m_leftMS, deltaMS)
    
    if self.m_hpStore <= 0 then
        self:ClearEffect(actor)
        self:BeforeClearFrozen()
        actor:Idle()
        return StatusEnum.STATUSCONDITION_END
    end

    if self.m_leftMS <= 0 then
        self:ClearEffect(actor)
        actor:Idle()
        return StatusEnum.STATUSCONDITION_END
    end

    return StatusEnum.STATUSCONDITION_CONTINUE
end

function StatusXuanWuAllTimeShield:ClearEffect(actor)
    StatusAllTimeShield.ClearEffect(self, actor)
    if self.m_hpStore > 0 then
        local giver = StatusGiver.New(actor:GetActorID(), 35061)
        local status = StatusFactoryInst:NewStatusDelayHurt(giver, self.m_hpStore, BattleEnum.HURTTYPE_REAL_HURT, 0, BattleEnum.HPCHGREASON_BY_SKILL, 0, BattleEnum.ROUNDJUDGE_NORMAL)
        actor:GetStatusContainer():Add(status, actor)
    end
end

return StatusXuanWuAllTimeShield