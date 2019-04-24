local ActorCreateParam = require "GameLogic.Battle.Actors.ActorCreateParam"
local CopyLogic = require "GameLogic.Battle.BattleLogic.impl.CopyLogic"
local BaseBattleLogic = require "GameLogic.Battle.BattleLogic.BaseBattleLogic"
local GraveLogic = BaseClass("GraveLogic", CopyLogic)
local base = CopyLogic

local AddTime = 15000  --总用时是60秒，过一波，用时加15秒
local TimeToEndMS = 60000
local MonsterCount = 20
local ActorMgrInst = ActorManagerInst

local FixVecConst = FixVecConst
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixMod = FixMath.mod
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local table_insert = table.insert
local table_remove = table.remove
local FixRand = BattleRander.Rand
local BattleEnum = BattleEnum
local NewFixVector3 = FixMath.NewFixVector3

local GetMonsterCfgByID = ConfigUtil.GetMonsterCfgByID


local ThiefPercent = 9  --普通盗墓贼权重

function GraveLogic:__init()
    self.m_battleType = BattleEnum.BattleType_GRAVE
    self.m_dropMoney = 0
    self.m_dropItemDict = {}
    self.m_thiefDropBoxCfgList = {}
    self.m_timeToEndMS = TimeToEndMS
    self.m_generateMonsterList = {}

    self.m_thiefPercentList = nil
    self.m_dropMoneyPercentList = nil


    self.m_offSitePosLit = {
        [1] = {
            NewFixVector3(145.79, 8.1289, 119.58),
            NewFixVector3(175.1, 8.1289, 99),
        },
        [2] = {
            NewFixVector3(152.89, 9.101563, 116.47),
            NewFixVector3(92.28, 9.101563, 119.99),
        },
        [3] = {
            NewFixVector3(109.29, 9.101563, 118.47),
        },
    }

    self.m_runPosList = {
        [1] = {
            NewFixVector3(160.76, 8.1289, 117.32),
            NewFixVector3(160.71, 8.1289, 120.15),
            NewFixVector3(167.51, 8.1289, 113.91),
            NewFixVector3(167.4, 8.1289, 122.48),
            NewFixVector3(178.81, 8.1289, 115.59),
            NewFixVector3(178.3, 8.1289, 120.98),
            NewFixVector3(174.71, 8.1289, 121.87),
            NewFixVector3(174.87, 8.1289, 115.04),
            NewFixVector3(170.52, 8.1289, 114.01),
            NewFixVector3(160.93, 8.1289, 114.51),
            NewFixVector3(160.75, 8.1289, 122.17),
            NewFixVector3(163.93, 8.1289, 122.39),
            NewFixVector3(170.2, 8.1289, 122.54),
            NewFixVector3(179, 8.1289, 118.47),
            NewFixVector3(164.29, 8.1289, 113.86),
        },
        [2] = {
            NewFixVector3(102.74, 11.2, 119.72),
            NewFixVector3(102.69, 11.2, 122.55),
            NewFixVector3(109.49, 11.2, 116.31),
            NewFixVector3(109.38, 11.2, 124.88),
            NewFixVector3(120.79, 11.2, 117.99),
            NewFixVector3(120.28, 11.2, 123.38),
            NewFixVector3(116.69, 11.2, 124.27),
            NewFixVector3(116.85, 11.2, 117.44),
            NewFixVector3(112.5, 11.2, 116.41),
            NewFixVector3(106.27, 11.2, 116.26),
            NewFixVector3(102.91, 11.2, 116.91),
            NewFixVector3(102.73, 11.2, 124.57),
            NewFixVector3(105.91, 11.2, 124.79),
            NewFixVector3(112.18, 11.2, 124.94),
            NewFixVector3(120.98, 11.2, 120.87),
        },
        [3] = {
            NewFixVector3(61.86, 11.2, 117.08),
            NewFixVector3(61.81, 11.2, 119.91),
            NewFixVector3(68.61, 11.2, 113.67),
            NewFixVector3(68.5, 11.2, 122.24),
            NewFixVector3(79.91, 11.2, 115.35),
            NewFixVector3(79.4, 11.2, 120.74),
            NewFixVector3(75.81, 11.2, 121.63),
            NewFixVector3(75.97, 11.2, 114.8),
            NewFixVector3(71.62, 11.2, 113.77),
            NewFixVector3(65.39, 11.2, 113.62),
            NewFixVector3(62.03, 11.2, 114.27),
            NewFixVector3(61.85, 11.2, 121.93),
            NewFixVector3(65.03, 11.2, 122.15),
            NewFixVector3(71.3, 11.2, 122.3),
            --NewFixVector3(80.1, 11.2, 188.23),
        } 
    }

    self.m_isFirstIn = false
end

function GraveLogic:OnEnterParam(enterParam)
    base.OnEnterParam(self, enterParam)

    --第一关才有宝箱奖励
    local graveCopyCfg = ConfigUtil.GetGraveCopyCfgByID(1)
    self.m_thiefPercentList = graveCopyCfg.thiefPercentList
    self.m_dropMoneyPercentList = graveCopyCfg.dropMoneyPercentList
 
    self.m_monsterWuJiangID = graveCopyCfg.monsterActorIDList[1]
    self.m_monsterWuJiangID2 = graveCopyCfg.monsterActorIDList[2]
    self.m_monsterWuJiangID3 = graveCopyCfg.monsterActorIDList[3]
    self.m_thiefWuJiangID = graveCopyCfg.monsterActorIDList[4]
    self.m_thiefWuJiangID2 = graveCopyCfg.monsterActorIDList[5]

    if graveCopyCfg then
        self:PraseThiefDropInfo(self.m_thiefWuJiangID, graveCopyCfg.box1IDList, graveCopyCfg.box1CountList, graveCopyCfg.box1DropPercentList)
        self:PraseThiefDropInfo(self.m_thiefWuJiangID2, graveCopyCfg.box2IDList, graveCopyCfg.box2CountList, graveCopyCfg.box2DropPercentList)
    end

    self.m_graveCopyCfg = ConfigUtil.GetGraveCopyCfgByID(self.m_battleParam.copyID)

    self.m_noTuguanPercentList = self.m_graveCopyCfg.noTuguanPercentList
    self.m_jinGuanziPercent = self.m_graveCopyCfg.jinGuanziPercent

    self.m_isFirstIn = enterParam.param1

    
end

function GraveLogic:Update(deltaMS, battlestatus)
    base.Update(self, deltaMS, battlestatus)

    if self.m_finish then
        return
    end

    if self.m_sinceStartMS >= self.m_timeToEndMS then
        self:OnFinish(false, BattleEnum.BATTLE_LOSE_REASON_TIMEOUT)
        -- print(' Grave Fight finish with time out ')
        return
    end
end

function GraveLogic:UpdateFighting(deltaMS)
    base.UpdateFighting(self, deltaMS)
    
    if self.m_finish then
        return
    end

    if #self.m_generateMonsterList > 0 then
        for i, v in ipairs(self.m_generateMonsterList) do
            local generateData = v
            local monster, ownerID, bornPos, lineupPos = generateData[1], generateData[2], generateData[3], generateData[4]
            if monster then
                local forward = self:GetForward(BattleEnum.ActorCamp_RIGHT, self.m_currWave) 
                local battleRound = self.m_graveCopyCfg.battleRound[1]
                local battleRoundCfg = ConfigUtil.GetBattleRoundCfgByID(battleRound[1])
                self:FlushOneMonster(monster, battleRoundCfg, lineupPos, bornPos, forward, true, true, ownerID)
            end
        end
        self.m_generateMonsterList = {}
    end
end

function GraveLogic:PraseThiefDropInfo(wujiangID, boxIDList, boxCountList, boxDropPercentList)
    if boxIDList then
        local boxDropItemList = {}
        for i, v in ipairs(boxIDList) do
            local dropItemCfg = {
                itemID = v,
                itemCount = boxCountList[i],
                percent = boxDropPercentList[i]
            }
            table_insert(boxDropItemList, dropItemCfg)
        end
        table_insert(self.m_thiefDropBoxCfgList, { wujiangID = wujiangID , boxDropItemList = boxDropItemList })
    end
end

function GraveLogic:OnBattleInit()
    BaseBattleLogic.OnBattleInit(self)

    local leftWujiangList = self.m_battleParam.leftCamp.wujiangList
    for _, oneWujiang in ipairs(leftWujiangList) do
        local createParam = ActorCreateParam.New()
        createParam:MakeSource(BattleEnum.ActorSource_ORIGIN, 0)
        createParam:MakeAttr(BattleEnum.ActorCamp_LEFT, oneWujiang)
        createParam:MakeLocation(self:GetBornWorldLocation(BattleEnum.ActorCamp_LEFT, 0, createParam.lineUpPos))
        createParam:MakeAI(BattleEnum.AITYPE_MANUAL) 
        createParam:MakeRelationType(BattleEnum.RelationType_NORMAL)
        createParam:SetImmediateCreateObj(true)

        ActorMgrInst:CreateActor(createParam)
    end

    self:FlushMonster(true)
end

function GraveLogic:FlushMonster(immediatelyCreateObj)
    
    local battleRound = self.m_graveCopyCfg.battleRound[1]
    local battleRoundCfg = ConfigUtil.GetBattleRoundCfgByID(battleRound[1])

--非土罐出现概率：第一层5%*2，第二层10%*3，第三层25%*4
    local randCount = 2
    if self.m_currWave == 2 then
        randCount = 3
    elseif self.m_currWave == 3 then
        randCount = 4
    end

    local standPosList = {}
    for i = 1, MonsterCount do
        table_insert(standPosList, i)
    end

    if self.m_isFirstIn and self.m_currWave == 1 then
        local monsterlist = battleRoundCfg.monsterlist
        for i = 1, MonsterCount do
            local standPos = standPosList[i]
            
            local monster = monsterlist[1]
            if #monsterlist > 2 then
                if i == 1 then
                    monster = monsterlist[3]
                elseif i == 2 then
                    monster = monsterlist[2]
                end
            end

            local pos, forward = self:GetBornWorldLocation(BattleEnum.ActorCamp_RIGHT, self.m_currWave, standPos)
            self:FlushOneMonster(monster, battleRoundCfg, standPos, pos, forward, immediatelyCreateObj)
        end
    else
        for i = 1, MonsterCount do
            local index = FixAdd(1, FixMod(FixRand(), #standPosList))
            local standPos = standPosList[index]
            table_remove(standPosList, index)
            local monster = self:RandMonster(randCount, self.m_graveCopyCfg.floor, self.m_currWave, battleRoundCfg.monsterlist)
            local pos, forward = self:GetBornWorldLocation(BattleEnum.ActorCamp_RIGHT, self.m_currWave, standPos)
            self:FlushOneMonster(monster, battleRoundCfg, standPos, pos, forward, immediatelyCreateObj)
            randCount = FixSub(randCount, 1)
        end
    end
end

function GraveLogic:FlushOneMonster(monster, battleRoundCfg, standPos, pos, forward, immediatelyCreateObj, isCall, ownerID)
    if monster then
        local monsterID, aiType = monster[1], monster[2]
        local monsterSkillLevel = monster[3]
        local monsterCfg = GetMonsterCfgByID(monsterID)
        if monsterCfg then
            local createParam = ActorCreateParam.New()
            createParam:MakeAI(aiType)

            local oneWujiang = self:CreateBattleMonster(standPos, monsterCfg, battleRoundCfg, monsterSkillLevel)
            createParam:MakeMonster(monsterID, oneWujiang.bossType)
            createParam:MakeAttr(BattleEnum.ActorCamp_RIGHT, oneWujiang)
            createParam:MakeLocation(pos, forward)
           --[[  if isCall then
                createParam:MakeSource(BattleEnum.ActorSource_CALLED, ownerID)
            end ]]
            createParam:SetImmediateCreateObj(immediatelyCreateObj)
            ActorMgrInst:CreateActor(createParam)

        end
    end
end

function GraveLogic:GetWaveGoTimelineName()
    if self.m_currWave == 1 then
        return self.m_mapCfg.strGoCameraPath0[self.m_cameraAngleMode]
    elseif self.m_currWave == 2 then
        return self.m_mapCfg.strGoCameraPath1[self.m_cameraAngleMode]
    elseif self.m_currWave == 3 then
        return self.m_mapCfg.strGoCameraPath2[self.m_cameraAngleMode]
    end
end

function GraveLogic:PlayDollyGroupCamera(dollyImmediate)
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DOLLY_GROUP, self.m_mapCfg.DollyGroupCamera[self.m_cameraAngleMode], dollyImmediate)
end

function GraveLogic:GetRightPos(wave)
    if wave <= 0 then
        return nil
    end

    if self.m_rightPosList[wave] then
        return self.m_rightPosList[wave]
    end

    local dis = self.m_graveCopyCfg.monsterDis[wave]
    local standID = self.m_graveCopyCfg.monsterStand

    local standsCfg = ConfigUtil.GetMapStandCfgByID(standID)
    local stands = standsCfg.stands
    local poslist = {}

    local right_zero = FixVecConst.right()
    right_zero:Mul(dis)
    right_zero:Add(self.m_leftPosList[1])

    for k, v in ipairs(stands) do
        local pos = right_zero + NewFixVector3(v[1], 0, v[2])
        table_insert(poslist, pos)
    end

    self.m_rightPosList[wave] = poslist
    return poslist
end

function GraveLogic:GetGoWaveTimelinePath()
    return TimelineType.PATH_BATTLE_SCENE
end

function GraveLogic:RandMonster(randCount, copyFloor, wave, monsterlist)
    if randCount > 0 then
        local randVal = self:GetMonsterRand(copyFloor, wave)
        local rand = FixMod(FixRand(), 100)
        if rand < randVal then
            --陶罐权重4,  金罐权重1
            local jin_guanzi_percent = self.m_jinGuanziPercent
            local rand2 = FixMod(FixRand(), 100)
            local index = FixSub(#monsterlist, 1)
            if #monsterlist > 2 then
                if rand2 < self.m_jinGuanziPercent then
                    index = #monsterlist
                end
            end
            return monsterlist[index]
        end
    end

    return monsterlist[1]
end

--非土罐出现概率：第一层5%*2，第二层10%*3，第三层25%*4
--每提升一个难度等级概率上升5%
function GraveLogic:GetMonsterRand(copyFloor, wave)
    local randVal = self.m_noTuguanPercentList[1]
    if wave == 2 then
        randVal = self.m_noTuguanPercentList[2]
    elseif wave == 3 then
        randVal = self.m_noTuguanPercentList[3]
    end
    --randVal = FixAdd(randVal, FixIntMul(FixSub(copyFloor, 1), 5))

    return randVal
end

function GraveLogic:OnActorDie(actor, killerGiver, hurtReason, deadMode)
    if not actor then
        return
    end
    
    BaseBattleLogic.OnActorDie(self, actor, killerGiver, hurtReason)
    --base.OnActorDie(self, actor, killerGiver, hurtReason)
    
    if actor:GetCamp() == BattleEnum.ActorCamp_RIGHT then
        local wujiangID = actor:GetWujiangID()
        if wujiangID == self.m_monsterWuJiangID or wujiangID == self.m_monsterWuJiangID2 or wujiangID == self.m_monsterWuJiangID3 then
            --铜钱掉落
            local dropMoney = self:CalcDropMoney(actor)
            if self.m_component then
                self.m_component:DropMoney(actor, dropMoney)
            end

            self.m_dropMoney = FixAdd(self.m_dropMoney, dropMoney)

            --概率产生盗墓贼
            local monster = self:ProduceBrief(actor)
            if monster then
                local pos = actor:GetPosition():Clone()
                table_insert(self.m_generateMonsterList, { monster, actor:GetActorID(), pos, actor:GetLineupPos() })
            end

        elseif wujiangID == self.m_thiefWuJiangID or wujiangID == self.m_thiefWuJiangID2 then
            --宝箱掉落
            if killerGiver and killerGiver.actorID ~= actor:GetActorID() then
                self:DropBox(actor)
            end
        end

        if #self.m_generateMonsterList == 0 and ActorManagerInst:IsCampAllDie(BattleEnum.ActorCamp_RIGHT) then
          
            if self.m_currWave == 1 or self.m_currWave == 2 then
                self.m_timeToEndMS = FixAdd(self.m_timeToEndMS, AddTime)
            end

            if self.m_currWave >= BattleEnum.BATTLE_WAVE_COUNT then
                self:OnFinish(true, BattleEnum.BATTLE_LOSE_REASON_DEAD, killerGiver)
            else
                local timelineName = self:GetWavePlotTimelineName(true)
                if timelineName then
                    WavePlotMgr:Start(timelineName, TimelineType.PATH_BATTLE_SCENE, function()
                        self:OnBattleStop()
                        self:DelayWaveEnd()
                    end)
                else
                    self:OnBattleStop()
                    self:DelayWaveEnd()
                end
            end
        end
    end
end

function GraveLogic:CalcDropMoney(actor)
    local wujiangID = actor:GetWujiangID()

    --不同怪，不同掉落金币占比：1% / 2% / 5%
    local dropPercent = self.m_dropMoneyPercentList[1]
    if wujiangID == self.m_monsterWuJiangID2 then
        dropPercent = self.m_dropMoneyPercentList[2]
    elseif wujiangID == self.m_monsterWuJiangID3 then
        dropPercent = self.m_dropMoneyPercentList[3]
    end

    local dropMoney = FixIntMul(FixDiv(self.m_graveCopyCfg.dropMoney, 100), dropPercent)
    return dropMoney
end

function GraveLogic:DropBox(actor)
    local wujiangID = actor:GetWujiangID()
    local dropItemList

    for i, v in ipairs(self.m_thiefDropBoxCfgList) do
        if v.wujiangID == wujiangID then
            dropItemList = v.boxDropItemList
        end
    end

    if not dropItemList then
        dropItemList = self.m_thiefDropBoxCfgList[1].boxDropItemList
    end
   
    local isDrop = false

    --print("----- DropBox" )
    for i, v in ipairs(dropItemList) do
        local rand = FixAdd(1, FixMod(FixRand(), 100))
        if rand < v.percent then
            self.m_dropItemDict[v.itemID] = FixAdd((self.m_dropItemDict[v.itemID] or 0), v.itemCount)
            isDrop = true
            --print("DropBox ", v.itemID, self.m_dropItemDict[v.itemID])
        end
    end
    --print("----- DropBox end" )

    if isDrop then
        if self.m_component then
            self.m_component:DropBox(actor)
        end
    end
end

function GraveLogic:DistributeDrop() -- nothing to do
end

function GraveLogic:GetWavePlotTimelineName(isFightStart)
    return nil
end

--摄像机视角内随机位置
function GraveLogic:GetRandPos()
    if self.m_currWave <= #self.m_runPosList then
        local randPosList = self.m_runPosList[self.m_currWave]
        local index = FixAdd(1, FixMod(FixRand(), #randPosList))
        return randPosList[index]
    end

    return self.m_runPosList[1][1]
end

--场外位置
--[[ function GraveLogic:GetOffSitePos()
    if self.m_currWave <= #self.m_offSitePosLit then
        local randPosList = self.m_offSitePosLit[self.m_currWave]
        local index = FixAdd(1, FixMod(FixRand(), #randPosList))
        return randPosList[index]
    end

    return self.m_offSitePosLit[1][1]
end ]]


--产生盗墓贼
function GraveLogic:ProduceBrief(actor)
    --不同罐子 盗墓贼出现概率不同
    -- 普通盗墓贼权重9， 高级盗墓贼在不同关卡的权重 Lv.4 = 1，Lv.5 = 2，Lv.6 = 3

    local wujiangID = actor:GetWujiangID()
    local percent = 0
    if wujiangID == self.m_monsterWuJiangID then
        percent = self.m_thiefPercentList[1]
    elseif wujiangID == self.m_monsterWuJiangID2 then
        percent = self.m_thiefPercentList[2]
    elseif wujiangID == self.m_monsterWuJiangID3 then
        percent = self.m_thiefPercentList[3]
    end

    if self.m_isFirstIn and self.m_currWave == 1 then
        if wujiangID == self.m_monsterWuJiangID3 then
            return self.m_graveCopyCfg.thiefIDList[1]
        end
    end

    local newMonster = nil
    local rand = FixMod(FixRand(), 100)
    if rand < percent then
        local monster, monster2 = self.m_graveCopyCfg.thiefIDList[1], self.m_graveCopyCfg.thiefIDList[2]
        newMonster = monster

        if self.m_graveCopyCfg.superThiefPercent > 0 then
            local total = ThiefPercent + self.m_graveCopyCfg.superThiefPercent
            local rand2 = FixMod(FixRand(), total)
            if rand2 < self.m_graveCopyCfg.superThiefPercent then
                newMonster = monster2
            end
        end
    end

    return newMonster
end

function GraveLogic:GetRandMoveTime(actor)
    local wujiangID = actor:GetWujiangID()
    if wujiangID == self.m_thiefWuJiangID2 then
        return 10000
    end
    return 6000 --ms
end

function GraveLogic:IsPathHandlerHitTest(actor)
    if actor then
        local ai = actor:GetAI()
        if ai and ai:GetAiType() == BattleEnum.AITYPE_GRAVE_THIEF then
            return false
        end
    end

    return true
end

function GraveLogic:ReqSettle(isWin)
    if self.m_component then
        self.m_component:ReqBattleFinish(self.m_battleParam.copyID)
    end
end

function GraveLogic:GetOffSitePos()
    return self.m_offSitePosLit[1][1]
end

function GraveLogic:GetDropMoney()
    return self.m_dropMoney
end

function GraveLogic:GetDropItemList()
    local dropItemList = {}
    for k, v in pairs(self.m_dropItemDict) do
        local one_item = { item_id = k,  count = v }
        table_insert(dropItemList, one_item)
    end

    --print("dropItemList ", table.dump(dropItemList))
    return dropItemList
end

function GraveLogic:RecordCommand()
    return true
end

function GraveLogic:CanRideHorse()
    return false
end

function GraveLogic:IsFirstIn()
    return self.m_isFirstIn
end

return GraveLogic


