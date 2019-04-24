local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local CtlBattleInst = CtlBattleInst
local BattleEnum = BattleEnum
local FixIntMul = FixMath.muli
local StatusEnum = StatusEnum
local Formular = Formular
local table_insert = table.insert
local table_remove = table.remove
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local MediumManagerInst = MediumManagerInst

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1034 = BaseClass("Actor1034", Actor)

function Actor1034:__init()
    self.m_10343SkillCfg = 0
    self.m_10343Level = 0
    self.m_10343A = 0
    self.m_10343B = 0
    self.m_10343X = 0
    self.m_10343C = 0

    self.m_interval = 300
    self.m_param = {}
    self.m_checkParam = false
end

function Actor1034:SetPatam(param)
    self.m_checkParam = true
    table_insert(self.m_param, param)
end

function Actor1034:OnBorn(create_param)
    Actor.OnBorn(self, create_param)
    -- 每当有己方武将被施加护盾时，大乔便为护盾内的同伴每秒回复{x6}（+{E}%法攻)点生命，持续{A}秒，并为其随机清除{B}个负面状态。若护盾消失，则立即停止回复。

    local skillItem = self.m_skillContainer:GetPassiveByID(10343)
    if skillItem then
        self.m_10343Level = skillItem:GetLevel()
        local skillCfg = ConfigUtil.GetSkillCfgByID(10343)
        self.m_10343SkillCfg = skillCfg
        if skillCfg then
            self.m_10343A = SkillUtil.A(skillCfg, self.m_10343Level)
            self.m_10343B = SkillUtil.B(skillCfg, self.m_10343Level)
            self.m_10343X = SkillUtil.X(skillCfg, self.m_10343Level)
            self.m_10343C = SkillUtil.C(skillCfg, self.m_10343Level)
        end
    end
end 
 
function Actor1034:OnSBAddShield(actor)
    local battleLogic = CtlBattleInst:GetLogic()
    if self.m_10343SkillCfg and battleLogic:IsFriend(self, actor, true) then 
        local giver = StatusGiver.New(self:GetActorID(), 10343)  
        local recoverHP = Formular.CalcRecover(BattleEnum.HURTTYPE_MAGIC_HURT, self, actor, self.m_10343SkillCfg,  self.m_10343X) 
        local status = StatusFactoryInst:NewStatusDaqiaoIntervalHP(giver, recoverHP, 1000, self.m_10343A)
        actor:GetStatusContainer():Add(status, self)

        if self.m_10343Level >= 4 then
            actor:GetStatusContainer():RandomClearOneBuff(StatusEnum.CLEARREASON_NEGATIVE) 

            self:ChangeNuqi(self.m_10343C, BattleEnum.NuqiReason_SKILL_RECOVER, self.m_10343SkillCfg)
        end  
        
    end 
end

function Actor1034:LogicUpdate(deltaMS)
    if self.m_checkParam then
        local count = #self.m_param
        if count > 0 then
            self.m_interval = FixSub(self.m_interval, deltaMS)
            if self.m_interval <= 0 then
                self.m_interval = FixAdd(self.m_interval, 300)

                local param = self.m_param[1]
                if param then
                    MediumManagerInst:CreateMedium(param.type, param.speed, param.giver, param.skillbase, param.pos, param.forward, param.mediaParam)
                end

                table_remove(self.m_param, 1)
            end
        else
            self.m_checkParam = false
        end
    end
end

return Actor1034