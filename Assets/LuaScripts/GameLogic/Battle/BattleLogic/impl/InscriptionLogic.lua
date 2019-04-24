local BattleEnum = BattleEnum
local FixVecConst = FixVecConst
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local FixAbs = FixMath.abs
local FixMod = FixMath.mod
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
local table_remove = table.remove
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst

local ActorCreateParam = require "GameLogic.Battle.Actors.ActorCreateParam"
local BaseBattleLogic = require "GameLogic.Battle.BattleLogic.BaseBattleLogic"
local InscriptionLogic = BaseClass("InscriptionLogic", BaseBattleLogic)

local base = BaseBattleLogic

local BOSS_LIFETIME = 30000
local PERIODS = 180000
local BOSS_DROP_COUNT = {1, 2, 3}

local PickInterval = 1000
local FlushMonsterInterval = 2000  --2000

--InscriptionLogic.MAX_INSCRIPTION_TYPE = 10

local BOSS_STATE_NONE = 0
local BOSS_STATE_PREPARE = 1
local BOSS_STATE_LIVING = 2

function InscriptionLogic:__init()
    self.m_leftPosList = {
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
    self.m_copyCfg = false
    self.m_timeToEndMS = PERIODS
    self.m_battleType = BattleEnum.BattleType_INSCRIPTION
    self.m_bossID = 0
    self.m_dropList = {}  -- dropType, count
    self.m_monsterDiePosList = {}
    self.m_updateInterval = 0
    self.m_flushMonsterInterval = 0
    
    self.m_battleRoundCfg = false
    self.m_score = 0
    self.m_bossDropType = 1
    self.m_currBossIndex = 1
    self.m_callTimes = 0
    self.m_bossHP = 0
    self.m_bossState = BOSS_STATE_NONE
    self.m_bossStateMS = 0
    -- drop Type (1 - 10)

    self.m_inscriptionScoreList = nil
    self.m_callScoreList = nil
end

function InscriptionLogic:OnEnterParam(enterParam)
    base.OnEnterParam(self, enterParam)
    
    self.m_copyCfg = ConfigUtil.GetInscriptionCopyCfgByID(self.m_battleParam.copyID)
    local battleRound = self.m_copyCfg.battleRound[1]
    self.m_battleRoundCfg = ConfigUtil.GetBattleRoundCfgByID(battleRound[1])

    local copyCfg = ConfigUtil.GetInscriptionCopyCfgByID(1)
    self.m_inscriptionScoreList = copyCfg.inscriptionScoreList
    self.m_callScoreList = copyCfg.callScoreList
end

function InscriptionLogic:GetLeftMS()
    local leftMS = FixSub(self.m_timeToEnd, self.m_sinceStartMS)
    if leftMS < 0 then
        leftMS = 0
    end

    return leftMS
end

function InscriptionLogic:CreatePlot()
    self.m_plotContext = SequenceMgr:GetInstance():PlayPlot('PlotInscription')
end

function InscriptionLogic:OnBattleInit()
    base.OnBattleInit(self)
    
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

    self:FlushMonster(true)
end

function InscriptionLogic:FlushMonster(immediatelyCreateObj)
    self:FlushBattleRound(self.m_battleRoundCfg, immediatelyCreateObj)
end

function InscriptionLogic:RandFlushMonster(lineUpPos)
    local monsterCount = #self.m_battleRoundCfg.monsterlist
    if monsterCount > 0 then
        local val = FixMod(BattleRander.Rand(), monsterCount) 
        val = FixAdd(val, 1)

        local oneMonster = self.m_battleRoundCfg.monsterlist[val]
        local monsterID, aiType = oneMonster[1], oneMonster[2]
        local monsterSkillLevel = oneMonster[3]

        local monsterCfg = ConfigUtil.GetMonsterCfgByID(monsterID)
        if monsterCfg then
            local createParam = ActorCreateParam.New()
            createParam:MakeAI(aiType)

            local oneWujiang = self:CreateBattleMonster(lineUpPos, monsterCfg, self.m_battleRoundCfg, monsterSkillLevel)
            createParam:MakeMonster(monsterID, oneWujiang.bossType)
            createParam:MakeAttr(BattleEnum.ActorCamp_RIGHT, oneWujiang)
            createParam:MakeLocation(self:GetBornWorldLocation(BattleEnum.ActorCamp_RIGHT, 1, lineUpPos)) 
            createParam:SetImmediateCreateObj(true)

            ActorManagerInst:CreateActor(createParam)
        end
    end
end

function InscriptionLogic:GetLeftPos(wave)
    return self.m_leftPosList
end

function InscriptionLogic:GetRightPos(wave)
    if self.m_rightPosList[1] then
        return self.m_rightPosList[1]
    end

    local dis = self.m_copyCfg.monsterDis
    local standID = self.m_copyCfg.monsterStand

    local standsCfg = ConfigUtil.GetMapStandCfgByID(standID)
    local stands = standsCfg.stands
    local poslist = {}

    local right_zero = FixVecConst.right()
    right_zero:Mul(dis)
    right_zero:Add(self.m_leftPosList[6])
    
    for k, v in ipairs(stands) do
        local pos = right_zero + NewFixVector3(v[1], 0, v[2])
        table_insert(poslist, pos)
    end

    self.m_rightPosList[1] = poslist
    return poslist
end

function InscriptionLogic:OnBattleStart()
    self.m_inFightMS = 0
    local count = 0
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() then
                local extraAtkCD = 0
                tmpTarget:ResetSkillFirstCD(0, extraAtkCD)                
                tmpTarget:OnFightStart(self.m_currWave)
            end
        end
    )

    if self.m_dragonLogic then
        self.m_dragonLogic:Init()
    end
    self:PlayDollyGroupCamera()
    
    if self.m_component then
        self.m_component:OnBattleStart(0)
    end
end

function InscriptionLogic:OnHPChange(actor, giver, deltaHP, hpChgReason)
    base.OnHPChange(self, actor, giver, deltaHP, hpChgReason)

    if deltaHP < 0 then
        if self:IsBoss(actor) then
            local dropCount = BOSS_DROP_COUNT[self.m_currBossIndex] or 1
            self:Drop(actor:GetPosition(), self.m_bossDropType, dropCount)
        end
    end
end

function InscriptionLogic:GetBossLeftMS()
    if self.m_bossState == BOSS_STATE_LIVING then
        return self.m_bossStateMS
    end
    return 0
end

function InscriptionLogic:NextBossNeedScore()
    local calltimes = FixAdd(self.m_callTimes, 1) 
    local needScore = self.m_callScoreList[calltimes]
    return needScore
end

function InscriptionLogic:Update(deltaMS, battlestatus)
    base.Update(self, deltaMS, battlestatus)
    
    if self.m_inFightMS >= self.m_timeToEndMS then
        self:OnFinish(false, BattleEnum.BATTLE_LOSE_REASON_TIMEOUT)
        -- Logger.Log(' InscriptionLogic finish with time out ')
        return
    end
end

function InscriptionLogic:UpdateFighting(deltaMS)
    base.UpdateFighting(self, deltaMS)

    if self.m_canKillRightCamp then
        self.m_canKillRightCamp = false

        ActorManagerInst:Walk(
            function(tmpTarget)
                if tmpTarget:GetCamp() == BattleEnum.ActorCamp_RIGHT and tmpTarget:IsLive() then
                    tmpTarget:KillSelf()
                end
            end
        )
    end

    if self.m_finish then
        return
    end

    self.m_updateInterval = FixAdd(self.m_updateInterval, deltaMS)
    self.m_flushMonsterInterval = FixAdd(self.m_flushMonsterInterval, deltaMS)

    if self.m_updateInterval >= PickInterval then
        self.m_updateInterval = 0
        self:Pick()
    end
    
    if self.m_flushMonsterInterval >= FlushMonsterInterval then
        if #self.m_monsterDiePosList > 0 then
            local n = 10
            while #self.m_monsterDiePosList > 0 and n > 0 do
                local index = #self.m_monsterDiePosList
                local pos = self.m_monsterDiePosList[index]
                table_remove(self.m_monsterDiePosList, index)
                self:RandFlushMonster(pos)
                n = FixSub(n , 1)
            end
        end

        if #self.m_monsterDiePosList == 0 then
            self.m_flushMonsterInterval = 0
        end

        --[[ self.m_flushMonsterInterval = 0
        for _, pos in ipairs(self.m_monsterDiePosList) do
            self:RandFlushMonster(pos)
        end ]]

       
        self.m_monsterDiePosList = {}
    end 

    if self.m_bossState == BOSS_STATE_LIVING then
        self.m_bossStateMS = FixSub(self.m_bossStateMS, deltaMS)
        if self.m_bossStateMS <= 0 then
            local boss = ActorManagerInst:GetActor(self.m_bossID)
            if boss and boss:IsLive() then
                self:OnBossLeave(boss)
                boss:KillSelf(BattleEnum.DEADMODE_DEPARTURE)
                self.m_bossState = BOSS_STATE_NONE
               -- print('66666666666666 boss removed')
            end
        end

    elseif self.m_bossState == BOSS_STATE_PREPARE then
        self.m_bossStateMS = FixSub(self.m_bossStateMS, deltaMS)        
        if self.m_bossStateMS <= 0 then
            self.m_bossState = BOSS_STATE_LIVING
            self.m_bossStateMS = BOSS_LIFETIME
        end

    elseif self.m_bossState == BOSS_STATE_NONE then
        --print("self.m_currBossIndex ", self.m_currBossIndex, #self.m_copyCfg.bossIDList)
        if self.m_currBossIndex <= #self.m_copyCfg.bossIDList then
            local needScore = self:NextBossNeedScore()
            if needScore and self.m_score >= needScore then
               -- print("needScore  ", needScore , self.m_score)
                self.m_bossState = BOSS_STATE_PREPARE
                self.m_bossStateMS = BattleEnum.QUE_SHEN_SHOW_SKILL_TIME --根据出场动画时长

                self:CallBoss(self.m_currBossIndex)

                if self.m_component then
                    self.m_component:PrepareBossOut()
                end
            end
        end
    end
end

function InscriptionLogic:IsBoss(actor)
    local monsterID = actor:GetMonsterID()
    for _, cfg in ipairs(self.m_copyCfg.bossIDList) do  -- monsterID:dropCount
        if cfg[1] == monsterID then
            return true, cfg[2]
        end
    end
    return false
end

function InscriptionLogic:RandDropType()
    local val = FixMod(BattleRander.Rand(), 10)
    return FixAdd(val, 1)
end

function InscriptionLogic:OnActorCreated(actor)
    base.OnActorCreated(self, actor)

    if actor:GetCamp() == BattleEnum.ActorCamp_RIGHT and self:IsBoss(actor) then
        self.m_bossDropType = self:RandDropType()
    end
end

function InscriptionLogic:OnActorDie(actor, killerGiver, hurtReason, deadMode)
    if not actor then
        return
    end

    base.OnActorDie(self, actor, killerGiver, hurtReason)

    if actor:GetCamp() == BattleEnum.ActorCamp_LEFT then
        if ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_LEFT) then
            self:OnFinish(false, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
        end

    elseif actor:GetCamp() == BattleEnum.ActorCamp_RIGHT then
        if hurtReason == BattleEnum.HPCHGREASON_KILLSELF or hurtReason == BattleEnum.DEADMODE_DEPARTURE then
            return
        end

        local isBoss, dropCount = self:IsBoss(actor)
        if isBoss then

            -- print('9999999999999999 boss die ', killerGiver.actorID, hurtReason)
            self.m_bossHP = 0

            self:Drop(actor:GetPosition(), self.m_bossDropType, dropCount)

            if self.m_currBossIndex >= #self.m_copyCfg.bossIDList then
                -- 大招击杀特写
                self.m_canKillRightCamp = true

                if hurtReason == BattleEnum.HPCHGREASON_BY_SKILL or hurtReason == BattleEnum.HPCHGREASON_APPEND then
                    local skillCfg = ConfigUtil.GetSkillCfgByID(killerGiver.skillID)
                    if self.m_component and skillCfg and SkillUtil.IsDazhao(skillCfg) and actor:GetBossType() ~= BattleEnum.BOSSTYPE_BIG then
                        if BattleCameraMgr:GetMode() ~= BattleEnum.CAMERA_MODE_DAZHAO_KILL then
                            -- Logger.Log("Play dazhao kill, skill:" .. killerGiver.skillID)
                            self:SetKillInfo(true, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
                            self:FinishBattle()
                            self:StopRecord()
                            BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DAZHAO_KILL)
                        end
                        return
                    end
                end
               

                self:OnFinish(true, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
            else
                self.m_currBossIndex = FixAdd(self.m_currBossIndex, 1)
                self.m_bossState = BOSS_STATE_NONE
            end
        else
            local pos = actor:GetLineupPos()
            table_insert(self.m_monsterDiePosList, pos)

            local dropType = self:RandDropType()
            self:Drop(actor:GetPosition(), dropType, 1)
        end
        
    end
end

function InscriptionLogic:DoFinish()
    base.DoFinish(self)
    
    -- 无论胜利还是失败，都给留点时间捡东西吧
    --Logger.LogError("DoFinish win "..(self.m_resultParam.playerWin and 1 or 2))
    self:Pick()
    
    if self.m_resultParam.playerWin then
        SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_END)
    else
        self:OnLoseSettle(self.m_resultParam.loseReason)
    end
end

function InscriptionLogic:Drop(aroundPos, dropType, count)
    local dropCount = self.m_dropList[dropType] or 0
    self.m_dropList[dropType] = FixAdd(dropCount, count)

    if self.m_component then
        self.m_component:Drop(aroundPos, dropType, count)
    end
end

function InscriptionLogic:PickOne(count)

    local oldScore = self.m_score
    while count > 1 do
        if count >= 4 then
            self.m_score = FixAdd(self.m_score, self.m_inscriptionScoreList[3])
            count = FixSub(count, 4)

        elseif count >= 3 then
            self.m_score = FixAdd(self.m_score, self.m_inscriptionScoreList[2])
            count = FixSub(count, 3)

        elseif count >= 2 then
            self.m_score = FixAdd(self.m_score, self.m_inscriptionScoreList[1])
            count = FixSub(count, 2)
        end
    end
    
    return count
end

function InscriptionLogic:Pick()
    
    for dropType, count in pairs(self.m_dropList) do
        local left = self:PickOne(count)

        local pickCount = FixSub(count, left)
        if pickCount > 0 and self.m_component then
         
            self.m_component:Pick(dropType, pickCount, self.m_score)
        end

        self.m_dropList[dropType] = left
    end
    
-- print(' ++++++++++++ logic score pick one round ', self.m_score)
end

function InscriptionLogic:CallBoss(bossIndex)
    local bossCfg = self.m_copyCfg.bossIDList[bossIndex]
    if not bossCfg then
        return
    end

    local monsterID = bossCfg[1]
    local monsterCfg = ConfigUtil.GetMonsterCfgByID(monsterID)
    if not monsterCfg then
        return
    end

    local createParam = ActorCreateParam.New()
    createParam:MakeAI(BattleEnum.AITYPE_QUESHEN)

    local oneWujiang = self:CreateBoss(monsterCfg)
    createParam:MakeMonster(monsterID, oneWujiang.bossType) 
    createParam:MakeAttr(BattleEnum.ActorCamp_RIGHT, oneWujiang)
    
    local dir = self:GetForward(BattleEnum.ActorCamp_LEFT, 1)
    local leftCenterPos = self:GetLeftCenter()
    local destPos
    local isHitTest = true
    
    local x, y, z = leftCenterPos:GetXYZ()
    local pathHandler = CtlBattleInst:GetPathHandler()
    if pathHandler then
        for i = 3, 1, -1 do
            destPos = dir * i
            destPos:Add(leftCenterPos)
            
            local x2, y2, z2 = destPos:GetXYZ()
            local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
            if not hitPos then
                isHitTest = false
                break
            end
        end
    end

    --有阻挡
    if isHitTest then
        destPos = leftCenterPos
    end

    -- print("destPos ", leftCenterPos, destPos)
    createParam:MakeLocation(destPos, self:GetForward(BattleEnum.ActorCamp_RIGHT, 1))
    createParam:SetImmediateCreateObj(true)
    createParam:MakeRelationType(BattleEnum.RelationType_SON_NONINTERACTIVE)

    local bossActor = ActorManagerInst:CreateActor(createParam)
    self.m_bossID = bossActor:GetActorID()

    self.m_callTimes = FixAdd(self.m_callTimes, 1)
    -- print('------------------ call boss m_callTimes bossIndex m_bossID ',self.m_callTimes, bossIndex, self.m_bossID, bossActor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP))
end

function InscriptionLogic:OnBossLeave(actor)
    self.m_bossHP = actor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
end

function InscriptionLogic:GetBossID()
    return self.m_bossID
end

function InscriptionLogic:CreateBoss(monsterCfg)
    local bossLevel = 1

    local maxCfg = ConfigUtil.GetMonsterMaxCfgByLevel(bossLevel)
    if not maxCfg then 
        Logger.LogError('CreateBoss no max cfg or level ' .. bossLevel)
        return
    end
    
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(monsterCfg.role_id)
    if not wujiangCfg then 
        Logger.LogError('CreateBoss no role cfg ' .. monsterCfg.role_id)
        return 
    end

    local oneWujiang = OneBattleWujiang.New()

    oneWujiang.wujiangID = monsterCfg.role_id
    oneWujiang.level = bossLevel
    oneWujiang.lineUpPos = 0
    oneWujiang.bossType = BattleEnum.BOSSTYPE_SMALL

    local valuePercent = FixDiv(self.m_battleRoundCfg.monsterValuePercent, 1000)

    local calc = function(maxval, factor, valuePercent, buff)
        local v = maxval
        v = FixMul(v, factor)
        v = FixMul(v, valuePercent)
        return FixFloor(v)
    end

    local buff = function(b)
        return FixAdd(1, FixDiv(b, 1000))
    end

    local factor = function(f)
        return FixDiv(f, 1000)
    end

    oneWujiang.max_hp = calc(maxCfg.max_hp, factor(monsterCfg.factor_maxhp), valuePercent, 1)
    oneWujiang.phy_atk = calc(maxCfg.phy_atk, factor(monsterCfg.factor_phyatk), valuePercent, 1)
    oneWujiang.phy_def = calc(maxCfg.phy_def, factor(monsterCfg.factor_phydef), valuePercent, 1)
    oneWujiang.magic_atk = calc(maxCfg.magic_atk, factor(monsterCfg.factor_magicatk), valuePercent, 1)
    oneWujiang.magic_def = calc(maxCfg.magic_def, factor(monsterCfg.factor_magicdef), valuePercent, 1)
    oneWujiang.phy_baoji = calc(maxCfg.phy_baoji, factor(monsterCfg.factor_phybaoji), valuePercent, 1)
    oneWujiang.magic_baoji = calc(maxCfg.magic_baoji, factor(monsterCfg.factor_magicbaoji), valuePercent, 1)
    oneWujiang.shanbi = calc(maxCfg.shanbi, factor(monsterCfg.factor_shanbi), valuePercent, 1)
    oneWujiang.mingzhong = calc(maxCfg.mingzhong, factor(monsterCfg.factor_mingzhong), valuePercent, 1)
    oneWujiang.move_speed = wujiangCfg.moveSpeed
    oneWujiang.atk_speed = wujiangCfg.atkSpeed
    oneWujiang.hp_recover = wujiangCfg.hpRecover
    oneWujiang.nuqi_recover = wujiangCfg.nuqiRecover
    oneWujiang.baoji_hurt = wujiangCfg.crtihurt
    oneWujiang.init_nuqi = 0

    if self.m_bossHP > 0 then
        oneWujiang.hp = self.m_bossHP
    end

    -- monsterCfg.skillList 要配置普攻技能
    for _, skill_id in ipairs(monsterCfg.skillList) do
        table_insert(oneWujiang.skillList, {skill_id = skill_id, skill_level = 1})
    end

    return oneWujiang
end

function InscriptionLogic:GetLeftCenter()
    local count = 0
    local center = NewFixVector3(0, 0, 0)
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT and not tmpTarget:IsCalled() then
                center:Add(tmpTarget:GetPosition())
                count = FixAdd(count, 1)
            end
        end
    )

    if count > 0 then
        center:Div(count)
    end
    return center
end

--友方身后位置
function InscriptionLogic:GetRightBackPos()
    local count = 0
    local center = NewFixVector3(0, 0, 0)
    local posX = -9999999
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:GetCamp() == BattleEnum.ActorCamp_RIGHT and tmpTarget:IsLive() and not tmpTarget:IsCalled() then
                local pos = tmpTarget:GetPosition()

                center:Add(pos)
                count = FixAdd(count, 1)
                if pos.x > posX then
                    posX = pos.x
                end
            end
        end
    )

    if count > 0 then
        center:Div(count)
    end

    center.x = posX
    return center
end


function InscriptionLogic:IsHideUIWhenUIStart()
    return false
end

function InscriptionLogic:GoToCurrentWaveStandPoint(ignorePartner)
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_WAVE_GO, self:GetWaveGoTimelineName(), TimelineType.PATH_BATTLE_SCENE)
    WaveGoMgr:GoToCurrentWaveStandPoint(self, ignorePartner)
end

function InscriptionLogic:PlayDollyGroupCamera(dollyImmediate)
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DOLLY_GROUP, self.m_mapCfg.DollyGroupCamera[self.m_cameraAngleMode], dollyImmediate)
end

function InscriptionLogic:GetWaveGoTimelineName()
    if self.m_currWave == 1 then
        return self.m_mapCfg.strGoCameraPath0[self.m_cameraAngleMode]
    elseif self.m_currWave == 2 then
        return self.m_mapCfg.strGoCameraPath1[self.m_cameraAngleMode]
    elseif self.m_currWave == 3 then
        return self.m_mapCfg.strGoCameraPath2[self.m_cameraAngleMode]
    end
end


function InscriptionLogic:OnNextWaveArrived()    
    SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_GO_END)
end

function InscriptionLogic:ReqSettle(isWin)
    if self.m_component then
        self.m_component:ReqBattleFinish(self.m_battleParam.copyID)
    end
end

function InscriptionLogic:GetBossData()
    if self.m_copyCfg.bossIDList[self.m_currBossIndex] then
        return self.m_copyCfg.bossIDList[self.m_currBossIndex][1], self.m_currBossIndex
    end
end

function InscriptionLogic:GetScore()
    return self.m_score
end

function InscriptionLogic:ReplaceHurt(actor, deltaHP)
    if deltaHP < 0 then
        if self:IsBoss(actor) then
            return -1
        end
    end
    return deltaHP
end

function InscriptionLogic:RecordCommand()
    return true
end

function InscriptionLogic:CanDaZhao(camp)
    if not base.CanDaZhao(self, camp) then
        return false
    end

    return self.m_bossState ~= BOSS_STATE_PREPARE
end

return InscriptionLogic