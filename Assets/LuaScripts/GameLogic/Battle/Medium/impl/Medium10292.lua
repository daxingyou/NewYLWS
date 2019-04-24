local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local FixIntMul = FixMath.muli
local BattleEnum = BattleEnum
local Formular = Formular
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local StatusFactoryInst = StatusFactoryInst
local IsInRect = SkillRangeHelper.IsInRect
local FixNormalize = FixMath.Vector3Normalize
local ACTOR_ATTR = ACTOR_ATTR

local LinearFlyToPointMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToPointMedium")
local Medium10292 = BaseClass("Medium10292", LinearFlyToPointMedium)

function Medium10292:__init()
    self.m_enemyList = {}
    self.m_enemyCount = 0
end


function Medium10292:OnMove(dir)
    local performer = self:GetOwner()
    if not performer then
        self:Over()
        return
    end

    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    if not battleLogic or not skillCfg or not self.m_skillBase then
        return
    end

    local dir = FixNormalize(self.m_param.targetPos - self.m_position)
    -- local half2 = FixDiv(skillCfg.dis2, 2)
    local factory = StatusFactoryInst
    local statusGiverNew = StatusGiver.New
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInRect(tmpTarget:GetPosition(), tmpTarget:GetRadius(), 1, 1, self.m_position, dir) then
                return
            end

            local targetID = tmpTarget:GetActorID()
            if self.m_enemyList[targetID] then
                return
            end

            self.m_enemyList[targetID] = targetID
            self.m_enemyCount = FixAdd(self.m_enemyCount, 1)

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:X())
            if injure > 0 then
                if self.m_enemyCount <= self.m_skillBase:A() then
                    local mul = FixMul(FixDiv(self.m_skillBase:B(), 100), FixSub(self.m_enemyCount, 1))
                    injure = FixAdd(injure, FixMul(mul, injure))

                    local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                        judge, self.m_param.keyFrame)
                    self:AddStatus(performer, tmpTarget, status)
                end
            end

            if self.m_skillBase:GetLevel() >= 2 then
                local injure = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.ROUNDJUDGE_NORMAL, self.m_skillBase:Y())
                local intervalStatus = StatusFactoryInst:NewStatusIntervalHP(self.m_giver, FixMul(injure, -1), 1000, self.m_skillBase:C(), {20026}, nil, BattleEnum.HURTTYPE_MAGIC_HURT)
                self:AddStatus(performer, tmpTarget, intervalStatus)
            end
        end
    )
end


function Medium10292:Over()
    self.m_enemyList = {}
    self.m_enemyCount = 0

    LinearFlyToPointMedium.Over(self)
end

return Medium10292