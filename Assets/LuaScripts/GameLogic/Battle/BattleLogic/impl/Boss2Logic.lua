local BattleEnum = BattleEnum
local FixVecConst = FixVecConst
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local FixAbs = FixMath.abs
local FixMod = FixMath.mod
local FixDiv = FixMath.div
local FixSub = FixMath.sub
local FixFloor = FixMath.floor
local NewFixVector3 = FixMath.NewFixVector3
local FixVetor3RotateAroundY = FixMath.Vector3RotateAroundY
local FixNormalize = FixMath.Vector3Normalize
local table_insert = table.insert
local table_sort = table.sort
local ConfigUtil = ConfigUtil
local SequenceEventType = SequenceEventType
local PreloadHelper = PreloadHelper
local FixRand = BattleRander.Rand
local SkillUtil = SkillUtil
local ActorManagerInst = ActorManagerInst


local ActorCreateParam = require "GameLogic.Battle.Actors.ActorCreateParam"
local BaseBattleLogic = require "GameLogic.Battle.BattleLogic.BaseBattleLogic"
local Boss2Logic = BaseClass("Boss2Logic", BaseBattleLogic)

local base = BaseBattleLogic

local BOSS_PERIODS = 120000

local Boss2CameraMode = {
    First = 1,
    Other = 2,
}

function Boss2Logic:__init()
    self.m_standPosList = {
        NewFixVector3(0, 0, 0),
        NewFixVector3(-1.5, 0, -6),
        NewFixVector3(-1.5, 0, 6),
        NewFixVector3(-3.5, 0, -3),
        NewFixVector3(-3.5, 0, 3),

        NewFixVector3(-12, 0, 6),
        NewFixVector3(6, 0, -0.5),
        NewFixVector3(9, 0, 5),
        NewFixVector3(22, -2.2, 3),
        NewFixVector3(23, -3.2, 8.5),
    }

    self.m_bossID = 0

    self.m_finishTime = 0

    self.m_battleType = BattleEnum.BattleType_BOSS2
    self.m_rightPosList = {}

    self.m_timeToEndMS = BOSS_PERIODS

    self.m_bossMaxHP = 0

    self.m_currCameraMode = Boss2CameraMode.First
    self.m_canSwitchCameraMode = true
end

function Boss2Logic:Update(deltaMS, battlestatus)
    if self.m_finish and self.m_resultParam.playerWin then
        if self.m_finishTime < 1500 and FixAdd(self.m_finishTime, deltaMS) >= 1500 then -- 老御龙
            self:DoFinish()
        end

        self.m_finishTime = FixAdd(self.m_finishTime, deltaMS)
    end

    if self.m_finish then
        return
    end

    base.Update(self, deltaMS, battlestatus)

    if self.m_inFightMS >= self.m_timeToEndMS then
        self:OnFinish(false, BattleEnum.BATTLE_LOSE_REASON_TIMEOUT)
        -- print(' Boss2 Fight finish with time out ')
        return
    end
end

function Boss2Logic:GetLeftMS()
    local leftMS = FixSub(self.m_timeToEndMS, self.m_sinceStartMS)
    if leftMS < 0 then
        leftMS = 0
    end

    return leftMS
end

function Boss2Logic:CreatePlot()
    self.m_plotContext = SequenceMgr:GetInstance():PlayPlot('PlotBoss2')
end

function Boss2Logic:OnBattleStart()
    self.m_inFightMS = 0
    local count = 0
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() then
                local extraAtkCD = 0

                tmpTarget:ResetSkillFirstCD(3500, 3500)
                
                tmpTarget:OnFightStart(self.m_currWave)
            end
        end
    )

    if self.m_dragonLogic then
        self.m_dragonLogic:Init()
    end
end

function Boss2Logic:OnBattleInit()
    base.OnBattleInit(self)

    self.m_timeToEndMS = BOSS_PERIODS

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
        local actor = actormgr:CreateActor(createParam)
        actor:SetForward(actor:GetRight())
    end

    self:FlushBoss()

    self.m_autoFight = false
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_NORMAL, "Boss220", TimelineType.PATH_BATTLE_SCENE)
end

function Boss2Logic:FlushBoss()
    -- local battleRound = self.m_copyCfg.battleRound[1]
    local roundID = 100012
    local battleRoundCfg = ConfigUtil.GetBattleRoundCfgByID(roundID)
    self:FlushBattleRound(battleRoundCfg, true)
end

function Boss2Logic:FlushBattleRound(battleRoundCfg, immediately)
    local GetMonsterCfgByID = ConfigUtil.GetMonsterCfgByID

    local actormgr = ActorManagerInst

    for i, monster in ipairs(battleRoundCfg.monsterlist) do
        local monsterID, aiType = monster[1], monster[2]
        local monsterCfg = GetMonsterCfgByID(monsterID)
        if monsterCfg then
            local createParam = ActorCreateParam.New()
            createParam:MakeAI(BattleEnum.AITYPE_LEIDI)

            local oneWujiang = self:CreateBattleMonster(i, monsterCfg, battleRoundCfg, nil, self.m_battleParam.bossLevel)
            createParam:MakeMonster(monsterID, BattleEnum.BOSSTYPE_BIG)
            createParam:MakeAttr(BattleEnum.ActorCamp_RIGHT, oneWujiang)
            createParam:MakeLocation(self:GetBornWorldLocation(BattleEnum.ActorCamp_RIGHT, 1, 1)) 
            createParam:SetImmediateCreateObj(true)
            actormgr:CreateActor(createParam)
        end
    end
end

function Boss2Logic:GetLeftPos(wave)
    return self.m_standPosList
end

function Boss2Logic:GetRightPos(wave)
    if wave <= 0 then
        return nil
    end

    if self.m_rightPosList[wave] then
        return self.m_rightPosList[wave]
    end

    local dis = 12 -- self.m_copyCfg.monsterDis[wave]
    local standID = 1 -- self.m_copyCfg.monsterStands[wave]

    local standsCfg = ConfigUtil.GetMapStandCfgByID(standID)
    local stands = standsCfg.stands
    local poslist = {}

    local right_zero = FixVecConst.right() 
    right_zero:Mul(dis)
    right_zero:Add(self.m_standPosList[1])

    for k, v in ipairs(stands) do
        local pos = right_zero + NewFixVector3(v[1], 0, v[2])
        table_insert(poslist, pos)
    end

    self.m_rightPosList[wave] = poslist
    return poslist
end

function Boss2Logic:RecordCommand()
    return true
end

function Boss2Logic:OnActorCreated(actor)
    base.OnActorCreated(self, actor)

    if actor:GetCamp() == BattleEnum.ActorCamp_RIGHT and actor:IsBoss() then
        self.m_bossID = actor:GetActorID()
        self.m_bossMaxHP = actor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAXHP)
    end
end

function Boss2Logic:OnActorDie(actor, killerGiver, hurtReason, deadMode)
    if not actor then
        return
    end

    base.OnActorDie(self, actor, killerGiver, hurtReason)

    if actor:GetCamp() == BattleEnum.ActorCamp_LEFT then
        if ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_LEFT) then
            self:OnFinish(false, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
        end
    elseif actor:GetCamp() == BattleEnum.ActorCamp_RIGHT then
        if ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_RIGHT) then
            self:SetKillInfo(true, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
            
            self.m_finish = true
        end
    end
end

function Boss2Logic:IsBeatBackOnHurt(actor, atker, skillCfg)
    return false
end

function Boss2Logic:DoFinish()
    base.DoFinish(self)
    
    if self.m_resultParam.playerWin then
        SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_END)
    else
        self:OnLoseSettle(self.m_resultParam.loseReason)
    end
end

function Boss2Logic:ReqSettle(isWin)
    if self.m_component then
        self.m_component:ReqBattleFinish(isWin)
    end
end

function Boss2Logic:IsHideUIWhenUIStart()
    return false
end

function Boss2Logic:GetFollowDirectMS()
    if self.m_sinceStartMS <= 3000 then
        return 500     --ms
    else
        return base.GetFollowDirectMS(self)
    end
end

function Boss2Logic:IsPathHandlerHitTest()
    return self.m_inFightMS >= 6000
end

function Boss2Logic:GoToNextWave()
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_WAVE_GO, self:GetWaveGoTimelineName(), TimelineType.PATH_BATTLE_SCENE)
end

function Boss2Logic:SwitchCamera()
    return
end

function Boss2Logic:GetWaveGoTimelineName()
    if self.m_currCameraMode == Boss2CameraMode.First then
        self.m_currCameraMode = Boss2CameraMode.Other
        return "Boss240"
    elseif self.m_currCameraMode == Boss2CameraMode.Other then
        self.m_currCameraMode = Boss2CameraMode.First
        return "Boss220"
    end
end

function Boss2Logic:PlayDollyGroupCamera(dollyImmediate)
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_NORMAL, self:GetWaveGoTimelineName(), TimelineType.PATH_BATTLE_SCENE, dollyImmediate)
end

function Boss2Logic:GetSkillDistance(dis)
    return FixAdd(dis, 3.5)
end

function Boss2Logic:GetBossID()
    return self.m_bossID
end

function Boss2Logic:GetBossMaxHP()
    return self.m_bossMaxHP
end

function Boss2Logic:SwitchOnHexinCamMode()
    self.m_canSwitchCameraMode = false
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_NORMAL, "Boss230", TimelineType.PATH_BATTLE_SCENE, false)
end

function Boss2Logic:SwitchOrignalCamMode()
    self.m_canSwitchCameraMode = true
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_NORMAL, self:GetWaveGoTimelineName(), TimelineType.PATH_BATTLE_SCENE, false)
end


function Boss2Logic:GetHarm()
    local damageData = self.m_battleDamage:GetDamageDataByActorID(self.m_bossID)
    if damageData then
        return damageData:GetDropHP(), damageData:GetDropHP() / self.m_bossMaxHP
    end

    Logger.LogError('Boss2Logic:GetHarm no boss damagedata')
    return 99
end

function Boss2Logic:IsKill()
    return self.m_resultParam.killGiver and self.m_resultParam.killGiver.actorID > 0
end

function Boss2Logic:CanRideHorse()
    return false
end

return Boss2Logic
