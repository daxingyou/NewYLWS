local base = require("GameLogic.Battle.Status.impl.StatusIntervalHP")
local FixAdd = FixMath.add
local FixIntMul = FixMath.muli
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixMod = FixMath.mod
local StatusEnum = StatusEnum
local FixRand = BattleRander.Rand
local table_insert = table.insert

local StatusXunyuIntervalHP = BaseClass("StatusXunyuIntervalHP", base)

function StatusXunyuIntervalHP:__init()
    self.m_frozenTime = 0
    self.m_atkPercent = 0
    self.m_rand = 0
    self.m_atkChg = 0
    self.m_oriChgCount = 0
end

function StatusXunyuIntervalHP:Init(giver, deltaHP, interval, chgCount, effect, maxOverlayCount, frozenTime, atkPercent, rand)
    base.Init(self, giver, deltaHP, interval, chgCount, effect, maxOverlayCount)
    
    self.m_frozenTime = frozenTime
    self.m_atkPercent = atkPercent
    self.m_rand = rand
    self.m_oriChgCount = chgCount
    self.m_atkChg = 0
end

function StatusXunyuIntervalHP:GetStatusType()
    return StatusEnum.STAUTSTYPE_XUNYU_INTERVAL_HP
end

function StatusXunyuIntervalHP:Effect(actor)
    if actor and actor:IsLive() then
        if self.m_atkChg <= 0 and self.m_atkPercent > 0 then
            local actorAtkSpeed = actor:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
            local chgAtkSpeed = FixIntMul(actorAtkSpeed, self.m_atkPercent)
            actor:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_ATKSPEED, FixMul(chgAtkSpeed, -1))
            self.m_atkChg = FixAdd(self.m_atkChg, chgAtkSpeed)
        end
    end
    
    return base.Effect(self, actor)
end

function StatusXunyuIntervalHP:Update(deltaMS, actor) 
    self.m_intervalTime = FixAdd(self.m_intervalTime, deltaMS)
    if self.m_intervalTime < self.m_interval then
        return StatusEnum.STATUSCONDITION_CONTINUE, false
    end

    self.m_intervalTime = 0
    self.m_chgCount = FixSub(self.m_chgCount, 1)
    self:EffectHP(BattleEnum.HURTTYPE_MAGIC_HURT, self.m_deltaHP, actor, BattleEnum.HPCHGREASON_INTERVAL_BUFF, BattleEnum.ROUNDJUDGE_NORMAL, 0)
    local isDie = false
    if not actor:IsLive() then
        isDie = true
    end

    if self.m_chgCount > 0 then
        return StatusEnum.STATUSCONDITION_CONTINUE, isDie
    end
    self:ClearEffect(actor)
    return StatusEnum.STATUSCONDITION_END, isDie
end


function StatusXunyuIntervalHP:ClearEffect(actor)
    base.ClearEffect(self, actor)

    if self.m_atkChg > 0 then
        actor:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_ATKSPEED, self.m_atkChg)
        self.m_atkChg = 0
    end

    local performer = ActorManagerInst:GetActor(self.m_giver.actorID)
    if performer and performer:IsLive() then
        if self.m_frozenTime > 0 then
            local buff = StatusFactoryInst:NewStatusFrozen(self.m_giver, self.m_frozenTime, {102107})
            local suc = actor:GetStatusContainer():Add(buff, performer)
            if suc then
                performer:ChgTianXiangCount(1)
            end
        end

        if self.m_rand > 0 then
            local randVal = FixMod(FixRand(), 100)
            if randVal <= self.m_rand then
                local enemyList = {}
                local battlelogic = CtlBattleInst:GetLogic()
                local actorID = actor:GetActorID()
                ActorManagerInst:Walk(
                    function(tmpTarget)
                        if not battlelogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                            return
                        end

                        if tmpTarget:GetActorID() == actorID then
                            return
                        end

                        table_insert(enemyList, tmpTarget)
                    end
                )

                local randActor = self:RandActor(enemyList)
                if not randActor then
                    randActor = actor
                end

                local xunyuIntervalHP = StatusFactoryInst:NewStatusXunyuIntervalHP(self.m_giver, self.m_deltaHP, 1000, self.m_oriChgCount, {102105}, 
                                                                        nil ,self.m_frozenTime, self.m_atkPercent, self.m_rand)

                randActor:GetStatusContainer():Add(xunyuIntervalHP, performer)
            end
        end
    end
end


function StatusXunyuIntervalHP:RandActor(enemyList)
    local count = #enemyList
    local tmpActor = false
    if count > 0 then
        local index = FixMod(FixRand(), count)
        index = FixAdd(index, 1)
        tmpActor = enemyList[index]
        if tmpActor then
            return tmpActor
        end
    end
    return false
end


return StatusXunyuIntervalHP