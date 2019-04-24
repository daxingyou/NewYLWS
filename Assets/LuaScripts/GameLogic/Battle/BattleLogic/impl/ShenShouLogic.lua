local BattleEnum = BattleEnum
local FixVecConst = FixVecConst
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixMul = FixMath.mul
local FixCeil = FixMath.ceil
local NewFixVector3 = FixMath.NewFixVector3
local table_insert = table.insert
local table_remove = table.remove
local ConfigUtil = ConfigUtil
local SequenceEventType = SequenceEventType
local PreloadHelper = PreloadHelper
local SkillUtil = SkillUtil
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local FixSqrt = FixMath.sqrt

local ActorCreateParam = require "GameLogic.Battle.Actors.ActorCreateParam"
local BaseBattleLogic = require "GameLogic.Battle.BattleLogic.BaseBattleLogic"
local ShenShouLogic = BaseClass("ShenShouLogic", BaseBattleLogic)

local base = BaseBattleLogic

function ShenShouLogic:__init()
    self.m_standPosList = {
        NewFixVector3(0, 0, 0),
        NewFixVector3(-1.5, 0, -2),
        NewFixVector3(-1.5, 0, 2),
        NewFixVector3(-3.5, 0, -1),
        NewFixVector3(-3.5, 0, 1),
        NewFixVector3(2, 0, 0),
        NewFixVector3(0.5, 0, -2),
        NewFixVector3(0.5, 0, 2),
    }

    self.m_rightPosList = {}
    self.m_shenshouCopyCfg = nil
    self.m_bossID = 0
    self.m_timeToEndMS = 180000
    self.m_battleType = BattleEnum.BattleType_SHENSHOU
end 

function ShenShouLogic:OnActorCreated(actor)
    base.OnActorCreated(self, actor) 

    if actor:GetCamp() == BattleEnum.ActorCamp_RIGHT then 
        if self.m_bossID == 0 then
            self.m_bossID = actor:GetActorID() 
        end
    end
end

function ShenShouLogic:InnerGetPreloadList()
    local helper = CtlBattleInst:GetLogicHelper(self.m_battleType)
    return helper:GetPreloadList(self.m_battleParam.copyID)
end

function ShenShouLogic:OnBattleInit()
    base.OnBattleInit(self)
    self.m_currWave = 1

    if self.m_battleParam.autoFight then
        self.m_autoFight = true
    end
    
    local actormgr = ActorManagerInst

    local leftWujiangList = self.m_battleParam.leftCamp.wujiangList
    for _, oneWujiang in ipairs(leftWujiangList) do
        local createParam = ActorCreateParam.New()
        createParam:MakeSource(BattleEnum.ActorSource_ORIGIN, 0)
        createParam:MakeAttr(BattleEnum.ActorCamp_LEFT, oneWujiang)
        createParam:MakeLocation(self:GetBornWorldLocation(BattleEnum.ActorCamp_LEFT, 0, createParam.lineUpPos))
        createParam:MakeAI(BattleEnum.AITYPE_MANUAL) 
        createParam:MakeRelationType(BattleEnum.RelationType_NORMAL)
        createParam:SetImmediateCreateObj(true)

        actormgr:CreateActor(createParam)
    end

    self:FlushBoss()
end

function ShenShouLogic:FlushBoss()
    local battleRound = self.m_shenshouCopyCfg["battleRound"..FixCeil(self.m_battleParam.challengeCount + 1)]
    local roundId = battleRound[1][1]
    local battleRoundCfg = ConfigUtil.GetBattleRoundCfgByID(roundId)
    self:FlushBattleRound(battleRoundCfg, true)
end

function ShenShouLogic:FlushBattleRound(battleRoundCfg, immediately)
    local GetMonsterCfgByID = ConfigUtil.GetMonsterCfgByID

    local actormgr = ActorManagerInst

    for i, monster in ipairs(battleRoundCfg.monsterlist) do
        local monsterID, aiType = monster[1], monster[2]
        local monsterSkillLevel = monster[3]

        local monsterCfg = GetMonsterCfgByID(monsterID)
        if monsterCfg then
            local createParam = ActorCreateParam.New()
            createParam:MakeAI(aiType)

            local oneWujiang = self:CreateBattleMonster(i, monsterCfg, battleRoundCfg, monsterSkillLevel, tonumber(self.m_battleParam.bossLevel))

            createParam:MakeMonster(monsterID, oneWujiang.bossType)
            createParam:MakeAttr(BattleEnum.ActorCamp_RIGHT, oneWujiang)
            createParam:MakeLocation(self:GetBornWorldLocation(BattleEnum.ActorCamp_RIGHT, self.m_currWave, i)) 
            createParam:SetImmediateCreateObj(immediately)

            actormgr:CreateActor(createParam)
        end
    end
end

function ShenShouLogic:GetFollowDirectMS()
    if self.m_sinceStartMS <= 3000 then
        return 500     --ms
    else
        return base.GetFollowDirectMS(self)
    end
end

function ShenShouLogic:IsPathHandlerHitTest()
    return self.m_inFightMS >= 1500
end

function ShenShouLogic:CreatePlot()
    self.m_plotContext = SequenceMgr:GetInstance():PlayPlot('PlotShenShou')
end

-- return fixv3[]
function ShenShouLogic:GetLeftPos(wave)
    return self.m_standPosList
end

-- return fixv3[]
function ShenShouLogic:GetRightPos(wave)
    if wave <= 0 then
        return nil
    end

    if self.m_rightPosList[wave] then
        return self.m_rightPosList[wave]
    end

    local dis = 9  -- self.m_copyCfg.monsterDis[wave]
    local standID = 1   --self.m_copyCfg.monsterStands[wave]

    local standsCfg = ConfigUtil.GetMapStandCfgByID(standID)
    local stands = standsCfg.stands
    local poslist = {}

    local right_zero = FixVecConst.right()
    right_zero:Mul(dis)
    right_zero:Add(self.m_standPosList[6])
    
    for k, v in ipairs(stands) do
        local pos = right_zero + NewFixVector3(v[1], 0, v[2])
        table_insert(poslist, pos)
    end

    self.m_rightPosList[wave] = poslist
    return poslist
end

function ShenShouLogic:GoToCurrentWaveStandPoint(ignorePartner)
    if FrameDebuggerInst:IsTraceInfo() then
        FrameDebuggerInst:FrameLog("GoToCurrentWaveStandPoint")
    end
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_WAVE_GO, self:GetWaveGoTimelineName(), self:GetGoWaveTimelinePath())
    WaveGoMgr:GoToCurrentWaveStandPoint(self, ignorePartner)
end

function ShenShouLogic:GetGoWaveTimelinePath()
    return self.m_mapCfg.timelinePath
end

function ShenShouLogic:PlayDollyGroupCamera(dollyImmediate)
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DOLLY_GROUP, self.m_mapCfg.DollyGroupCamera[self.m_cameraAngleMode], dollyImmediate)
end

function ShenShouLogic:GetWaveGoTimelineName()
    if not self.m_mapCfg then
        return nil
    end

    if self.m_currWave == 1 then
        return self.m_mapCfg.strGoCameraPath0[self.m_cameraAngleMode]
    elseif self.m_currWave == 2 then
        return self.m_mapCfg.strGoCameraPath1[self.m_cameraAngleMode]
    elseif self.m_currWave == 3 then
        return self.m_mapCfg.strGoCameraPath2[self.m_cameraAngleMode]
    end
end

function ShenShouLogic:OnNextWaveArrived()  
    if not self.m_shenshouCopyCfg then
        return
    end 

    SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_GO_END)
end

function ShenShouLogic:GetBossID()
    return self.m_bossID
end

function ShenShouLogic:GetSkillDistance(dis)
    return FixAdd(dis, 3)
end

function ShenShouLogic:GetSkillDistanceSqr(disSqr)
    local disSqrt = FixSqrt(disSqr)
    return FixMul(FixAdd(disSqrt, 3), FixAdd(disSqrt, 4))
end


function ShenShouLogic:OnActorDie(actor, killerGiver, hurtReason)
    if not actor then
        return
    end

    base.OnActorDie(self, actor, killerGiver, hurtReason)

    if actor:IsCalled() then
        return
    end

    if actor:GetCamp() == BattleEnum.ActorCamp_LEFT then
        if ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_LEFT) then
            -- self:ReqBossRTDeductHP()
            
            self:OnFinish(false, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
        end
    elseif actor:GetCamp() == BattleEnum.ActorCamp_RIGHT then
        if ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_RIGHT) then
            -- self:ReqBossRTDeductHP()

            if hurtReason == BattleEnum.HPCHGREASON_BY_SKILL or hurtReason == BattleEnum.HPCHGREASON_APPEND then
                local skillCfg = ConfigUtil.GetSkillCfgByID(killerGiver.skillID)
                if self.m_component and skillCfg and SkillUtil.IsDazhao(skillCfg) and actor:GetBossType() ~= BattleEnum.BOSSTYPE_BIG then
                    if BattleCameraMgr:GetMode() ~= BattleEnum.CAMERA_MODE_DAZHAO_KILL then
                        self:SetKillInfo(true, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
                        self:FinishBattle()
                        self:StopRecord()
                        BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DAZHAO_KILL)
                    end
                    return
                end
            end
            self:OnFinish(true, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
        end
    end
end

function ShenShouLogic:DoFinish()
    base.DoFinish(self)

    if self.m_resultParam.playerWin then
        SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_END)
    else
        self:OnLoseSettle(self.m_resultParam.loseReason)
    end   
end

function ShenShouLogic:GetMapid()
    local helper = CtlBattleInst:GetLogicHelper(self.m_battleType)
    return helper:GetMapID(self.m_battleParam.copyID)
end

function ShenShouLogic:OnEnterParam(enterParam)
    base.OnEnterParam(self, enterParam)
    self.m_shenshouCopyCfg = ConfigUtil.GetShenshouCopyCfgByID(enterParam.copyID)
end

function ShenShouLogic:ReqSettle(isWin)
    if self.m_component then
        self.m_component:ReqBattleFinish(isWin)
    end
end


function ShenShouLogic:RecordCommand()
    return true
end

function ShenShouLogic:NeedBlood(actor)
    if actor:GetBossType() == BattleEnum.BOSSTYPE_BIG then
        return false
    end
    return true
end

function ShenShouLogic:SwitchCamera()
    return
end

return ShenShouLogic
