local BattleEnum = BattleEnum
local CommonDefine = CommonDefine
local SimpleMoveState = require "GameLogic.Battle.ActorState.SimpleMoveState"
local AttackState = require "GameLogic.Battle.ActorState.AttackState"
local XiahouyuanFenshenAttackState = require "GameLogic.Battle.ActorState.XiahouyuanFenshenAttackState"
local IdleState = require "GameLogic.Battle.ActorState.IdleState"
local DazhaoState = require "GameLogic.Battle.ActorState.DazhaoState"
local DeadState = require "GameLogic.Battle.ActorState.DeadState"
local HurtState = require "GameLogic.Battle.ActorState.HurtState"
local PathMoveState = require "GameLogic.Battle.ActorState.PathMoveState"
local CtlBattleInst = CtlBattleInst

local StateContainer = BaseClass("StateContainer")

function StateContainer:__init(selfActor)
    self.m_currState = false
    self.m_simpleMoveState = false
    self.m_atkState = false
    self.m_idleState = false
    self.m_deadState = false
    self.m_hurtState = false
    self.m_dazhaoState = false
    self.m_pathMoveState = false
    self.m_selfActor = selfActor
end

function StateContainer:__delete()
    self.m_selfActor = nil
    self.m_currState = nil
    
    if self.m_simpleMoveState then 
        self.m_simpleMoveState:Delete() 
        self.m_simpleMoveState = nil
    end
    if self.m_atkState then 
        self.m_atkState:Delete()
        self.m_atkState = nil
    end
    if self.m_idleState then 
        self.m_idleState:Delete() 
        self.m_idleState = nil
    end
    if self.m_deadState then 
        self.m_deadState:Delete() 
        self.m_deadState = nil
    end
    if self.m_hurtState then 
        self.m_hurtState:Delete() 
        self.m_hurtState = nil
    end
    if self.m_dazhaoState then 
        self.m_dazhaoState:Delete() 
        self.m_dazhaoState = nil
    end
    if self.m_pathMoveState then 
        self.m_pathMoveState:Delete() 
        self.m_pathMoveState = nil
    end
end

function StateContainer:GetState()
    return self.m_currState
end

function StateContainer:ChangeState(toState, exParam, ...)
    if CtlBattleInst:IsInFight() then
        if self.m_currState and self.m_currState:GetStateID() == BattleEnum.ActorState_DEAD then
            return
        end
    end

    local state = self:CreateState(toState, exParam)
    if state then
        local from = BattleEnum.ActorState_MAX
        local fromInfo = nil

        if self.m_currState then
            from = self.m_currState:GetStateID()
            fromInfo = self.m_currState:GetParam(BattleEnum.StateParam_KEY_INFO)
            self.m_currState:End()
        end

        self.m_currState = state
        self.m_currState:Start(...)
        self.m_selfActor:OnStateChange(from, toState, fromInfo, exParam)
    end
end

function StateContainer:Update(deltaMS)
    if self.m_currState then
        self.m_currState:Update(deltaMS)

        if self.m_currState:GetExecState() == BattleEnum.EventHandle_END then
            local from = self.m_currState:GetStateID()
            local fromInfo = self.m_currState:GetParam(BattleEnum.StateParam_KEY_INFO)

            self.m_currState:End()
            self.m_currState = nil

            self.m_selfActor:OnStateChange(from, BattleEnum.ActorState_MAX, fromInfo)
        end
    end
end

function StateContainer:CreateState(state, exParam)
    if state == BattleEnum.ActorState_MOVE then
        if exParam == BattleEnum.StateParam_EX_PATH_MOVE then
            if not self.m_pathMoveState then
                self.m_pathMoveState = PathMoveState.New(self.m_selfActor)
            end
            return self.m_pathMoveState
        else
            if not self.m_simpleMoveState then
                self.m_simpleMoveState = SimpleMoveState.New(self.m_selfActor)
            end
            return self.m_simpleMoveState
        end

    elseif state == BattleEnum.ActorState_ATTACK then
        if exParam == BattleEnum.StateParam_EX_DAZHAO then
            if not self.m_dazhaoState then
                if self.m_selfActor:GetWujiangID() == 1004 then
                    local ZhaoyunDazhaoState = require "GameLogic.Battle.ActorState.ZhaoyunDazhaoState"
                    self.m_dazhaoState = ZhaoyunDazhaoState.New(self.m_selfActor)
                elseif CtlBattleInst:GetLogic():IsDazhaoSimple(self.m_selfActor) then
                    local SimpleDazhaoState = require "GameLogic.Battle.ActorState.SimpleDazhaoState"
                    self.m_dazhaoState = SimpleDazhaoState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 2031 then
                    local HunDunDazhaoState = require "GameLogic.Battle.ActorState.HunDunDazhaoState"
                    self.m_dazhaoState = HunDunDazhaoState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 2034 then
                    local LeiDiDazhaoState = require "GameLogic.Battle.ActorState.LeiDiDazhaoState"
                    self.m_dazhaoState = LeiDiDazhaoState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 3506 then
                    local XuanWuDazhaoState = require "GameLogic.Battle.ActorState.XuanWuDazhaoState"
                    self.m_dazhaoState = XuanWuDazhaoState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 1017 then
                    local DianweiDazhaoState = require "GameLogic.Battle.ActorState.DianweiDazhaoState"
                    self.m_dazhaoState = DianweiDazhaoState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 4050 then
                    local QueShenDazhaoState = require "GameLogic.Battle.ActorState.QueShenDazhaoState"
                    self.m_dazhaoState = QueShenDazhaoState.New(self.m_selfActor)
                else
                    self.m_dazhaoState = DazhaoState.New(self.m_selfActor)
                end
            end
            return self.m_dazhaoState
        else
            if not self.m_atkState then
                if self.m_selfActor:GetWujiangID() == 1043 then
                    local YuanShaoAttackState = require "GameLogic.Battle.ActorState.impl.YuanShaoAttackState"
                    self.m_atkState = YuanShaoAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 1048 then
                    local DiaoChanAttackState = require "GameLogic.Battle.ActorState.impl.DiaoChanAttackState"
                    self.m_atkState = DiaoChanAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 4008 then
                    local BearAttackState = require "GameLogic.Battle.ActorState.impl.BearAttackState"
                    self.m_atkState = BearAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 3501 then
                    local QinglongAttackState = require "GameLogic.Battle.ActorState.impl.QingLongAttackState"
                    self.m_atkState = QinglongAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 3503 then
                    local BaiHuAttackState = require "GameLogic.Battle.ActorState.impl.BaiHuAttackState"
                    self.m_atkState = BaiHuAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 1047 then
                    local YuanShuAttackState = require "GameLogic.Battle.ActorState.impl.YuanShuAttackState"
                    self.m_atkState = YuanShuAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 4050 then
                    local QueShenAttackState = require "GameLogic.Battle.ActorState.impl.QueShenAttackState"
                    self.m_atkState = QueShenAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 6015 then
                    local XiahouyuanFenshenAttackState = require "GameLogic.Battle.ActorState.XiahouyuanFenshenAttackState"
                    self.m_atkState = XiahouyuanFenshenAttackState.New(self.m_selfActor)
                elseif self.m_selfActor:GetWujiangID() == 1042 then
                    local LvbuAttackState = require "GameLogic.Battle.ActorState.impl.LvbuAttackState"
                    self.m_atkState = LvbuAttackState.New(self.m_selfActor)
                else
                    self.m_atkState = AttackState.New(self.m_selfActor)
                end
            end
            return self.m_atkState
        end

    elseif state == BattleEnum.ActorState_IDLE then
        if not self.m_idleState then
            self.m_idleState = IdleState.New(self.m_selfActor)
        end
        return self.m_idleState

    elseif state == BattleEnum.ActorState_DEAD then
        if not self.m_deadState then
            self.m_deadState = DeadState.New(self.m_selfActor)
        end
        return self.m_deadState 

    elseif state == BattleEnum.ActorState_HURT then
        if not self.m_hurtState then
            self.m_hurtState = HurtState.New(self.m_selfActor)
        end
        return self.m_hurtState
    end

    return nil
end

function StateContainer:Pause(reason)
    if self.m_currState then
        self.m_currState:Pause(reason)
    end
end

function StateContainer:Resume(reason)
    if self.m_currState then
        self.m_currState:Resume(reason)
    end
end

function StateContainer:OnFightEnd()
    if self.m_currState then
        self.m_currState:OnFightEnd()
    end
end

return StateContainer