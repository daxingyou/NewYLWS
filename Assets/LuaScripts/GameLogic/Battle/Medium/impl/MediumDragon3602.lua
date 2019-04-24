local BaseMedium = require("GameLogic.Battle.Medium.BaseMedium")
local BattleEnum = BattleEnum
local FixMath = FixMath
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local EffectMgr = EffectMgr
local Formular = Formular
local StatusFactoryInst = StatusFactoryInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local Quaternion = Quaternion

local MediumDragon3602 = BaseClass("MediumDragon3602", BaseMedium)
function MediumDragon3602:__init()
    self.m_param = false
    self.m_effectTime = 0
    self.m_totalTime = 0
    self.m_effectKey = 0
end

function MediumDragon3602:__delete()
    if self.m_effectKey > 0 then
        EffectMgr:RemoveByKey(self.m_effectKey)
    end
end

function MediumDragon3602:InitParam(param)
    self.m_param = {}
    if param then
        self.m_param.effectPos = param.effectPos
        self.m_param.camp = param.camp
        self.m_param.magicHurt = param.magicHurt
        self.m_param.magicHurtPercent = param.magicHurtPercent
        self.m_totalTime = 2500
    end
end

function MediumDragon3602:OnComponentBorn()
    self:LookatPosOnlyShow(self.m_param.effectPos.x, self.m_param.effectPos.y, self.m_param.effectPos.z)
end

function MediumDragon3602:DoUpdate(deltaMS)
    if self.m_effectTime < 500 then
        self.m_effectTime = FixAdd(self.m_effectTime, deltaMS)
        if self.m_effectTime >= 500 then
            self:Effect()
        end
    else
        self.m_effectTime = FixAdd(self.m_effectTime, deltaMS)
        if self.m_effectTime >= self.m_totalTime then
            self:Over()
            return
        end
    end
end

--对所有敌人造成{x}(+{y}%我方法攻总和)的法术伤害。
function MediumDragon3602:Effect()
    local totalMagicAtk = 0
    local factory = StatusFactoryInst
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsCalled() or not CtlBattleInst:GetLogic():IsDragonFriend(self.m_param.camp, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end
            totalMagicAtk = FixAdd(totalMagicAtk, tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAGIC_ATK)) 
        end
    )

    ActorManagerInst:Walk(
        function(tmpTarget)
            if not CtlBattleInst:GetLogic():IsDragonEnemy(self.m_param.camp, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end
            
            local hurtType = BattleEnum.HURTTYPE_MAGIC_HURT
            local atk = FixIntMul(totalMagicAtk, self.m_param.magicHurtPercent)
            local skillHurt = self.m_param.magicHurt
            local injure = Formular.CalcDragonInjure(hurtType, atk, skillHurt)
            if injure > 0 then
                local statusHP = factory:NewStatusHP(self.m_giver, FixMul(injure, -1), hurtType, BattleEnum.HPCHGREASON_BY_SKILL, BattleEnum.ROUNDJUDGE_NORMAL, 1)
                tmpTarget:GetStatusContainer():Add(statusHP)
            end
        end
    )

    self.m_effectKey = EffectMgr:AddSceneEffect(360201, self.m_param.effectPos, Quaternion.identity)
end

return MediumDragon3602
