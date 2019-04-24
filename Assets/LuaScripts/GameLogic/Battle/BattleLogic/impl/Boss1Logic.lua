local BattleEnum = BattleEnum
local FixVecConst = FixVecConst
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local FixAbs = FixMath.abs
local FixMod = FixMath.mod
local FixSub = FixMath.sub
local FixSqrt = FixMath.sqrt
local FixDiv = FixMath.div
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
local Boss1Logic = BaseClass("Boss1Logic", BaseBattleLogic)

local base = BaseBattleLogic

local BOSS_PERIODS = 120000

function Boss1Logic:__init()
    self.m_standPosList = {
        NewFixVector3(0, 0, 0),
        NewFixVector3(-1.5, 0, -6),
        NewFixVector3(-1.5, 0, 6),
        NewFixVector3(-3.5, 0, -3),
        NewFixVector3(-3.5, 0, 3),

        NewFixVector3(-10, 0, -4),
        NewFixVector3(11, 0, -4),
        NewFixVector3(8, 0, 6),
        NewFixVector3(22, -2.2, 3),
        NewFixVector3(23, -3.2, 8.5),
    }

    self.m_bossID = 0
    self.m_leftHandHP = 0
    self.m_rightHandHP = 0
    self.m_bossMaxHP = 0

    self.m_finishTime = 0

    self.m_battleType = BattleEnum.BattleType_BOSS1
    self.m_rightPosList = {}

    self.m_timeToEndMS = BOSS_PERIODS
end

function Boss1Logic:Update(deltaMS, battlestatus)
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
        -- Logger.Log(' Boss1 Fight finish with time out ')
        return
    end
end

function Boss1Logic:GetLeftMS()
    local leftMS = FixSub(self.m_timeToEndMS, self.m_sinceStartMS)
    if leftMS < 0 then
        leftMS = 0
    end

    return leftMS
end

function Boss1Logic:CreatePlot()
    self.m_plotContext = SequenceMgr:GetInstance():PlayPlot('PlotBoss1')
end

function Boss1Logic:OnBattleStart()
    self.m_inFightMS = 0
    local count = 0
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() then
                tmpTarget:ResetSkillFirstCD(4000, 4000)                
                tmpTarget:OnFightStart(self.m_currWave)
            end
        end
    )

    if self.m_dragonLogic then
        self.m_dragonLogic:Init()
    end
end

function Boss1Logic:OnBattleInit()
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
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DOLLY_GROUP, "Boss20")
end

function Boss1Logic:FlushBoss()
    -- local battleRound = self.m_copyCfg.battleRound[1]
    -- local roundID = battleRound[1]
    local roundID = 100010
    local battleRoundCfg = ConfigUtil.GetBattleRoundCfgByID(roundID)
    self:FlushBattleRound(battleRoundCfg, true)
end

function Boss1Logic:FlushBattleRound(battleRoundCfg, immediately)
    local GetMonsterCfgByID = ConfigUtil.GetMonsterCfgByID

    local actormgr = ActorManagerInst

    for i, monster in ipairs(battleRoundCfg.monsterlist) do
        local monsterID, aiType = monster[1], monster[2]
        local monsterCfg = GetMonsterCfgByID(monsterID)
        if monsterCfg then
            local createParam = ActorCreateParam.New()
            createParam:MakeAI(BattleEnum.AITYPE_HUNDUN)

            local oneWujiang = self:CreateBattleMonster(i, monsterCfg, battleRoundCfg, nil, self.m_battleParam.bossLevel)
            createParam:MakeMonster(monsterID, BattleEnum.BOSSTYPE_BIG)
            createParam:MakeAttr(BattleEnum.ActorCamp_RIGHT, oneWujiang)
            createParam:MakeLocation(self:GetBornWorldLocation(BattleEnum.ActorCamp_RIGHT, 1, 6)) 
            createParam:SetImmediateCreateObj(true)
            actormgr:CreateActor(createParam)
        end
    end
end

function Boss1Logic:GetLeftPos(wave)
    return self.m_standPosList
end

function Boss1Logic:GetRightPos(wave)
    if wave <= 0 then
        return nil
    end

    if self.m_rightPosList[wave] then
        return self.m_rightPosList[wave]
    end

    local dis = 12  -- self.m_copyCfg.monsterDis[wave]
    local standID = 1   --self.m_copyCfg.monsterStands[wave]

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


function Boss1Logic:CreateHand(handType)
    local boss = ActorManagerInst:GetActor(self.m_bossID)
    if not boss or not boss:IsLive() then
        return
    end

    local roleID = handType == ACTOR_ATTR.BOSS_HANDTYPE_LEFT and 2032 or 2033
    local roleCfg = ConfigUtil.GetWujiangCfgByID(roleID)
    if not roleCfg then
        Logger.LogError(' no boss1 wujiangCfg ==========')
        return
    end

    local oneWujiang = OneBattleWujiang.New()
    oneWujiang.wujiangID = roleCfg.id
    oneWujiang.level = boss:GetLevel()
    oneWujiang.lineUpPos = handType == ACTOR_ATTR.BOSS_HANDTYPE_LEFT and 2 or 3

    local fightData = boss:GetData()
    oneWujiang.max_hp = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAXHP), 0.1)
    oneWujiang.phy_atk = fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK)
    oneWujiang.phy_def = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_DEF), 0.75)
    oneWujiang.magic_atk = fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK)
    oneWujiang.magic_def = FixIntMul(fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_DEF), 0.75)
    oneWujiang.phy_baoji = fightData:GetAttrValue(ACTOR_ATTR.BASE_PHY_BAOJI)
    oneWujiang.magic_baoji = fightData:GetAttrValue(ACTOR_ATTR.BASE_MAGIC_BAOJI)
    oneWujiang.shanbi = fightData:GetAttrValue(ACTOR_ATTR.BASE_SHANBI)
    oneWujiang.mingzhong = fightData:GetAttrValue(ACTOR_ATTR.BASE_MINGZHONG)
    oneWujiang.move_speed = fightData:GetAttrValue(ACTOR_ATTR.BASE_MOVESPEED)
    oneWujiang.atk_speed = fightData:GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)

    local lastHP = handType == ACTOR_ATTR.BOSS_HANDTYPE_LEFT and self.m_leftHandHP or self.m_rightHandHP
    if lastHP > 0 then
        oneWujiang.hp = lastHP
    end

    local createParam = ActorCreateParam.New()
    createParam:MakeSource(BattleEnum.ActorSource_CALLED, self.m_bossID)
    createParam:MakeAI(BattleEnum.AITYPE_STUPID)
    createParam:MakeAttr(boss:GetCamp(), oneWujiang)

    local standPos = self.m_standPosList[FixAdd(oneWujiang.lineUpPos, 5)]
    local position = self:ToWorldPosition(standPos, 1)
    local forward = self:GetForward(ACTOR_ATTR.ActorCamp_RIGHT, 1)
    local rota = FixNormalize(FixVetor3RotateAroundY(forward, handType == ACTOR_ATTR.BOSS_HANDTYPE_LEFT and 10 or -20))
    rota:Add(position)
    rota.y = boss:GetPosition().y

    createParam:MakeLocation(rota, forward)
    createParam:MakeRelationType(BattleEnum.RelationType_NORMAL)
    createParam:SetImmediateCreateObj(true)
    
    local hand = ActorManagerInst:CreateActor(createParam)
    hand:SetHandType(handType)

    boss:SetHandID(hand:GetActorID())    
end

function Boss1Logic:OnActorCreated(actor)
    base.OnActorCreated(self, actor)

    if actor:GetCamp() == BattleEnum.ActorCamp_RIGHT and actor:IsBoss() then
        self.m_bossID = actor:GetActorID()
        self.m_bossMaxHP = actor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAXHP)
    end
end

function Boss1Logic:OnActorDie(actor, killerGiver, hurtReason, deadMode)
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

function Boss1Logic:IsBeatBackOnHurt(actor, atker, skillCfg)
    return false
end

function Boss1Logic:HandDie(actor, killSelf)
    local boss = ActorManagerInst:GetActor(self.m_bossID)
    if not boss or not boss:IsLive() then
        return
    end

    local hp = killSelf and actor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP) or 0
    if actor:GetHandType() == ACTOR_ATTR.BOSS_HANDTYPE_LEFT then
        self.m_leftHandHP = hp

        if not killSelf then
            boss:PlayAnim("skill2HandUp")
            boss:LeftHandDie()
        else
            boss:ShowLeftHand(true)
        end

    elseif actor:GetHandType() == ACTOR_ATTR.BOSS_HANDTYPE_RIGHT then
        self.m_rightHandHP = hp

        if not killSelf then
            boss:PlayAnim("skill1HandUp")
            boss:RightHandDie()
        else
            boss:ShowRightHand(true)
        end
    end

end

function Boss1Logic:GetLeftHandPos()
    return self:ToWorldPosition(self.m_standPosList[9], 1)
end

function Boss1Logic:ShowLeftHand()
    local boss = ActorManagerInst:GetActor(self.m_bossID)
    if not boss or not boss:IsLive() then
        return
    end

    boss:ShowLeftHand(false)

    self:CreateHand(ACTOR_ATTR.BOSS_HANDTYPE_LEFT)
end

function Boss1Logic:GetRightHandPos()
    return self:ToWorldPosition(self.m_standPosList[10], 1)
end

function Boss1Logic:ShowRightHand()
    local boss = ActorManagerInst:GetActor(self.m_bossID)
    if not boss or not boss:IsLive() then
        return
    end

    boss:ShowRightHand(false)

    self:CreateHand(ACTOR_ATTR.BOSS_HANDTYPE_RIGHT)
end

function Boss1Logic:DoFinish()
    base.DoFinish(self)

    if self.m_resultParam.playerWin then
        SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_END)
    else
        self:OnLoseSettle(self.m_resultParam.loseReason)
    end    
end

function Boss1Logic:IsHideUIWhenUIStart()
    return false
end

function Boss1Logic:GetFollowDirectMS()
    if self.m_sinceStartMS <= 3000 then
        return 500     --ms
    else
        return base.GetFollowDirectMS(self)
    end
end

function Boss1Logic:IsPathHandlerHitTest()
    return self.m_inFightMS >= 1500
end

function Boss1Logic:GoToNextWave()
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_WAVE_GO, self:GetWaveGoTimelineName(), TimelineType.PATH_BATTLE_SCENE)
end

function Boss1Logic:GetWaveGoTimelineName()
    if self.m_cameraAngleMode == 1 then
        return "Boss20"
    elseif self.m_cameraAngleMode == 2 then
        return "Boss30"
    elseif self.m_cameraAngleMode == 3 then
        return "Boss40"
    end
end

function Boss1Logic:PlayDollyGroupCamera(dollyImmediate)
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_NORMAL, self:GetWaveGoTimelineName(), TimelineType.PATH_BATTLE_SCENE, dollyImmediate)
end

function Boss1Logic:GetSkillDistance(dis)
    return FixAdd(dis, 4)
end

function Boss1Logic:GetSkillDistanceSqr(disSqr)
    local disSqrt = FixSqrt(disSqr)
    return FixMul(FixAdd(disSqrt, 4), FixAdd(disSqrt, 4))
end

function Boss1Logic:RecordCommand()
    return true
end

function Boss1Logic:GetBossID()
    return self.m_bossID
end

function Boss1Logic:IsKill()
    return self.m_resultParam.killGiver and self.m_resultParam.killGiver.actorID > 0
end

function Boss1Logic:GetBossMaxHP()
    return self.m_bossMaxHP
end

function Boss1Logic:GetHarm()
    local damageData = self.m_battleDamage:GetDamageDataByActorID(self.m_bossID)
    if damageData then
        return damageData:GetDropHP(), FixDiv(damageData:GetDropHP(), self.m_bossMaxHP)
    end

    Logger.LogError('Boss1Logic:GetHarm no boss damagedata')
    return 99
end

function Boss1Logic:ReqSettle(isWin)

    -- local harm, percent = self:GetHarm()
    -- print('Boss1 Settle ', self:IsKill(), harm, percent, self.m_sinceStartMS)

    if self.m_component then
        self.m_component:ReqBattleFinish(isWin)
    end
end


function Boss1Logic:CanRideHorse()
    return false
end


function Boss1Logic:SwitchCamera()
    return
end


return Boss1Logic
