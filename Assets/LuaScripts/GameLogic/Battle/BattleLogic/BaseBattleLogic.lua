local BattleEnum = BattleEnum
local table_insert = table.insert
local table_remove = table.remove
local ConfigUtil = ConfigUtil
local FixAdd = FixMath.add
local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixMod = FixMath.mod
local FixSin = FixMath.sin
local FixCos = FixMath.cos
local FixFloor = FixMath.floor
local Utils = Utils
local FixVecConst = FixVecConst
local FixNormalize = FixMath.Vector3Normalize
local FixNewVector3 = FixMath.NewFixVector3
local MathfSin = Mathf.Sin
local MathfCos = Mathf.Cos
local MediumManagerInst = MediumManagerInst
local ActorManagerInst = ActorManagerInst
local SkillUtil = SkillUtil
local CommonDefine = CommonDefine

local LogError = Logger.LogError

local ActorCreateParam = require "GameLogic.Battle.Actors.ActorCreateParam"
local BattleDamageRecorder = require "GameLogic.Battle.BattleLogic.BattleDamageRecorder"

local BaseBattleLogic = BaseClass("BaseBattleLogic")

BaseBattleLogic.MonsterJoinRule_INVALID = 0
BaseBattleLogic.MonsterJoinRule_DIE_COUNT = 1
BaseBattleLogic.MonsterJoinRule_BOSS_HP_LEFT_PERCENT = 2
BaseBattleLogic.MonsterJoinRule_ROLE_ENTER_ZONE = 3

function BaseBattleLogic:__init(battleID)
    self.m_battleID = battleID
    self.m_battleType = 0
    self.m_inFightMS = 0
    self.m_sinceStartMS = 0
    self.m_currWave = 0
    self.m_autoFight = false
    self.m_battleParam = false
    self.m_component = false

    -- 物种               可选为目标(影响结束条件) 可否范围伤害(包括选区) 可否单体伤害 可否回血(选区)
    -- NORMAL
    -- ENV_INTERACTIVE
    -- MECHANICAL
    -- SON_NONINTERACTIVE
    -- PARTNER
    self.RELATION_MATRIX = {
        { true, true, true, true },
        { false, true, false, false },
        { true, true, true, false },
        { false, false, false, false },
        { true, true, true, true }
    }

    self.m_plotContext = false
    self.m_mapCfg = false
    self.m_battleDamage = BattleDamageRecorder.New()

    self.m_finish = false
    self.m_resultParam = {}
    self.m_dragonLogic = false
	self.m_cameraAngleMode = BattleEnum.CAMERA_ANGLE_30

    self.m_timeToEndMS = 0

    self.m_atkProfDic = {}
    self.m_forwardCache = { [BattleEnum.ActorCamp_LEFT] = {}, [BattleEnum.ActorCamp_RIGHT] = {} }
    
    self.m_bossBackTime = 0
end

function BaseBattleLogic:__delete()
    if self.m_component then
        self.m_component:WriteCameraAngleModeFile(self.m_cameraAngleMode)
        self.m_component:Delete()
        self.m_component = nil
    end
    self.m_battleParam = nil
    self.m_mapCfg = nil

    if self.m_plotContext then
        self.m_plotContext:Delete()
        self.m_plotContext = nil
    end
    
    self.m_battleDamage = nil
    self.m_resultParam = nil
    if self.m_dragonLogic then
        self.m_dragonLogic:Delete()
        self.m_dragonLogic = nil
    end
    self.m_battleID = 0
    self.m_atkProfDic = nil
    self.m_forwardCache = nil
end

function BaseBattleLogic:RegisterComponent(comp)
    self.m_component = comp
end

function BaseBattleLogic:UpdateComponent()
    if self.m_component then
        self.m_component:Update(Time.deltaTime)
    end
end

-- function BaseBattleLogic:GetInFightMS()
--     return self.m_inFightMS
-- end

function BaseBattleLogic:GetSinceStartMS()
    return self.m_sinceStartMS
end

function BaseBattleLogic:GetDazhaoFirstCD()
    return 2000
end

function BaseBattleLogic:GetSkillFirstCD()
    return 0
end

function BaseBattleLogic:GetSkillCommonCD()
    return 0
end

function BaseBattleLogic:GetFollowDirectMS()
    return 2000     --ms
end

function BaseBattleLogic:GetFollowDirectDis()
    return 8
end

function BaseBattleLogic:GetSkillDistance(dis)
    return dis
end

function BaseBattleLogic:GetSkillDistanceSqr(disSqr)
    return disSqr
end

function BaseBattleLogic:GetSkillAngle(angle)
    return angle
end

function BaseBattleLogic:ChangeKillNuqi(killer, dier, killNuqi)
    return killNuqi
end

function BaseBattleLogic:ChangeNuqiValue(actor, chgVal, reason)
    if chgVal > 0 and self.m_dragonLogic then
        local talentSkillData = self.m_dragonLogic:GetTalentSkillData(actor:GetCamp(), BattleEnum.DRAGON_TALENT_SKILL_PIAOYU)
        if talentSkillData then
            chgVal = FixAdd(chgVal, FixMul(FixDiv(talentSkillData.x, 100), chgVal))
        end
    end
    return chgVal
end

function BaseBattleLogic:OnPerformDazhao(actor)
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() then
                tmpTarget:OnSBPerformDazhao(actor)
            end
        end
    )
end

function BaseBattleLogic:RecordOnceSkill(actor, skillID)
end

function BaseBattleLogic:CanPerformByOnce(actor, skillID)
    return true
end

function BaseBattleLogic:Update(deltaMS, battlestatus)

    if battlestatus == BattleEnum.BattleStatus_WAVE_FIGHTING then
        if self.m_inFightMS >= self.m_timeToEndMS then
            self:OnFinish(false, BattleEnum.BATTLE_LOSE_REASON_TIMEOUT)
            -- Logger.Log(' Fight finish with time out ')
            return
        end

        self:UpdateFighting(deltaMS)    
    elseif battlestatus == BattleEnum.BattleStatus_WAVE_INTERVAL then
        self:UpdateWaveInterval(deltaMS)
    end


    if self.m_battleDamage then
        self.m_battleDamage:Update()
    end
end

function BaseBattleLogic:UpdateFighting(deltaMS)
    self.m_inFightMS = FixAdd(self.m_inFightMS, deltaMS)
    self.m_sinceStartMS = FixAdd(self.m_sinceStartMS, deltaMS)
end

function BaseBattleLogic:UpdateWaveInterval(deltaMS)
    self:CheckNextWaveArrived(deltaMS)
end

function BaseBattleLogic:CheckNextWaveArrived(deltaMS)    
end

function BaseBattleLogic:GoToNextWave()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() and tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
                tmpTarget:Idle()
            end
        end
    )

    self:GoToCurrentWaveStandPoint()
end

function BaseBattleLogic:GoToCurrentWaveStandPoint(ignorePartner)
    local toStands = self:GetLeftPos(self.m_currWave)

    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() and (not ignorePartner or not tmpTarget:IsPartner()) then
                local toLocalPos = toStands[tmpTarget:GetLineupPos()]
    
                if not toLocalPos then
                    Logger.LogError('GoToCurrentWaveStandPoint no pos ' .. tmpTarget:GetWujiangID() .. 
                        ',' .. tmpTarget:GetActorID() .. ',' .. tmpTarget:GetLineupPos())
                end

                local toWorldPos = self:ToWorldPosition(toLocalPos, self.m_currWave)
                tmpTarget:PathingMove(toWorldPos)
            end
        end
    )
end

function BaseBattleLogic:IsEnemy(actor, target, reason, ignoreDie)
    if not CtlBattleInst:IsInFight() then
        return false
    end

    if not actor or not target or not reason then
        return false
    end

    if not ignoreDie and not target:IsLive() then
        return false
    end

    if actor:GetCamp() == target:GetCamp() then
        return false
    end

    -- if (target.GetStatusContainer().IsHiden())
    --         {
    --             return false;
    --         }
    -- bool sure = CheckControl(actor, target);
    --         if (!sure)
    --         {
    --             return false;
    --         }

    local targetType = target:GetRelationType()    
    return self.RELATION_MATRIX[targetType][reason]
end

function BaseBattleLogic:IsDragonFriend(camp, target, reason)
    if not CtlBattleInst:IsInFight() then
        return false
    end

    if not target or not target:IsLive() then
        return false
    end

    if target:GetCamp() ~= camp then
        return false
    end
    
    local targetType = target:GetRelationType()    
    return self.RELATION_MATRIX[targetType][reason]
end

function BaseBattleLogic:IsDragonEnemy(camp, target, reason)
    if not CtlBattleInst:IsInFight() then
        return false
    end

    if not target or not target:IsLive() then
        return false
    end

    -- TODO 
    -- if target:GetStatusContainer():IsHiden() then
    --     return false
    -- end

    -- if !target:ShowableInCamera() then
    --     return false
    -- end

    if target:GetCamp() == camp then
        return false
    end
    
    local targetType = target:GetRelationType()    
    return self.RELATION_MATRIX[targetType][reason]
end

function BaseBattleLogic:IsFriend(actor, target, includeSelf, reason, onlyInFight, ignoreDie)
    -- includeSelf = includeSelf or true
    if includeSelf == nil then
        includeSelf = true
    end

    reason = reason or BattleEnum.RelationReason_RECOVER
    onlyInFight = onlyInFight or true

    if onlyInFight and not CtlBattleInst:IsInFight() then
        return false
    end

    if not actor or not target then
        return false
    end

    if not ignoreDie and not target:IsLive() then
        return false
    end

    if actor:GetCamp() ~= target:GetCamp() then
        return false
    end

    if not includeSelf and actor:GetActorID() == target:GetActorID() then
        return false
    end

    local targetType = target:GetRelationType()    
    return self.RELATION_MATRIX[targetType][reason]
end

function BaseBattleLogic:IsAutoFight() 
    return self.m_autoFight
end

function BaseBattleLogic:OnAutoFight()
    if not self:CanSwitchAutoFight() then
        return
    end

    if self.m_autoFight then 
        self.m_autoFight = false 
    else
        self.m_autoFight = true
    end
end

function BaseBattleLogic:CanSwitchAutoFight()
    return true
end

function BaseBattleLogic:CreatePlot()
    self.m_plotContext = SequenceMgr:GetInstance():PlayPlot('PlotDummy2')
end

function BaseBattleLogic:OnPreload()
    self:CreatePlot()

    self.m_mapCfg = ConfigUtil.GetMapCfgByID(self:GetMapid())    
end

-- 注意mapid都放到helper里面实现，不要在logic的子类实现
function BaseBattleLogic:GetMapid()
    local helper = CtlBattleInst:GetLogicHelper(self.m_battleType)
    return helper:GetMapID(self.m_battleParam.copyID)
end

function BaseBattleLogic:GetMapCfg()
    return self.m_mapCfg
end

function BaseBattleLogic:GetAudioID()
	return self.m_mapCfg.audio
end


-- function BaseBattleLogic:OnScenePrepareEnter()
--     -- 创建初始对象 ，比如  地图，玩家阵容，第一波怪等
-- end

-- 战斗从此开始
function BaseBattleLogic:OnBattleInit()    
    self.m_currWave = 1
   
    if self.m_component then
        self.m_component:OnBattleInit()
        self.m_cameraAngleMode = self.m_component:ReadCameraAngleModeFile()
    end
    self:InitDragon()
end

function BaseBattleLogic:InitDragon()
    if not self.m_dragonLogic then
        local dragonLogicClass = require "GameLogic.Battle.BattleLogic.Dragon.DragonLogic"
        self.m_dragonLogic = dragonLogicClass.New(self)
    end
    
    local leftDragonData = self.m_battleParam.leftCamp.oneDragon
    if leftDragonData then
        self.m_dragonLogic:InitData(BattleEnum.ActorCamp_LEFT, leftDragonData)
    end
end

function BaseBattleLogic:OnActorCreated(actor)
    if not actor then return end

    if CtlBattleInst:IsInFight() then
        actor:ResetSkillFirstCD()

        actor:OnFightStart(self.m_currWave)
    end

    self.m_battleDamage:OnActorCreated(actor)
end

function BaseBattleLogic:OnBattleStart()
    self.m_inFightMS = 0
    self.m_bossBackTime = 0
    
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

    self:PlayDollyGroupCamera()
    if self.m_dragonLogic then
        self.m_dragonLogic:Init()
    end

    if self.m_component then
        self.m_component:OnBattleStart(self.m_currWave)
    end
end

function BaseBattleLogic:OnBattleStop()
    self.m_inFightMS = 0

    ActorManagerInst:Walk(
        function(tmpTarget)
            -- if tmpTarget:IsLive() and tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
            tmpTarget:OnFightEnd()
            -- end
        end
    )

    -- todo  env recover

    -- timescale  -->  1
    if self.m_component then
        self.m_component:OnBattleStop(self.m_currWave)
    end
end

function BaseBattleLogic:OnWaveEnd()
    
    ActorManagerInst:Walk(
        function(tmpTarget)
            -- if tmpTarget:IsLive() and tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
            tmpTarget:OnWaveEnd()
            -- end
        end
    )

    MediumManagerInst:OnWaveEnd()
end

function BaseBattleLogic:OnBattleGo()
    -- EffectMgr:RemoveAllEffect()
end

function BaseBattleLogic:OnFinishAction()
    self:PlayWinAction()
    self:EveryoneLookAtCamera()
    SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_WIN_ACTION)
end

function BaseBattleLogic:PlayWinAction()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() then
                tmpTarget:Idle(BattleEnum.IdleType_WIN, false, false, BattleEnum.IdleReason_NORMAL)
            end
        end
    )
end

function BaseBattleLogic:EveryoneLookAtCamera()
    if self.m_component then
        self.m_component:EveryoneLookAtCamera()
    end
end

function BaseBattleLogic:GetNearestProfTarget(actor)
    local camp = actor:GetCamp()
    local atkList = self.m_atkProfDic[camp]
    if not atkList then
        return nil
    end

    local minDisSqr = 999999
    local gotTarget = nil
    local REASON_SELECT_TARGET = BattleEnum.RelationReason_SELECT_TARGET
    local selfPos = actor:GetPosition()

    local actorMgr = ActorManagerInst
    local delList = nil

    for actorID, _ in pairs(atkList) do
        local tmpTarget = actorMgr:GetActor(actorID)
        if not tmpTarget or not tmpTarget:IsLive() then
            if not delList then
                delList = {}
            end
            table_insert(delList, actorID)
        else
            if self:IsEnemy(actor, tmpTarget, REASON_SELECT_TARGET) then
                local targetPos = tmpTarget:GetPosition()
                local dir = targetPos - selfPos
                local disSqr = dir:SqrMagnitude()

                if not gotTarget or disSqr < minDisSqr then
                    gotTarget = tmpTarget
                    minDisSqr = disSqr
                end
            end
        end
    end

    if delList then
        for _, actorID in ipairs(delList) do
            atkList[actorID] = nil
        end
    end

    return gotTarget
end

function BaseBattleLogic:OnHPChange(actor, giver, deltaHP, hpChgReason, hurtType, judge)
    if deltaHP < 0 then
        local skillCfg = ConfigUtil.GetSkillCfgByID(giver.skillID)
        if actor and skillCfg and SkillUtil.IsAtk(skillCfg) then

            local giverActor = ActorManagerInst:GetActor(giver.actorID)
            if giverActor then
                if actor:GetCamp() ~= giverActor:GetCamp() then
                    if actor:GetProf() == CommonDefine.PROF_4 or actor:GetProf() == CommonDefine.PROF_5 then
                        if giverActor:GetProf() == CommonDefine.PROF_1 or giverActor:GetProf() == CommonDefine.PROF_3 then
                            local tbl = self.m_atkProfDic[actor:GetCamp()]
                            if not tbl then
                                tbl = {}
                                self.m_atkProfDic[actor:GetCamp()] = tbl
                            end
                            tbl[giver.actorID] = 1

                            -- print('add prof atker ', actor:GetCamp(), giver.actorID)
                        end
                    end
                end
            end
        end
    end

    self.m_battleDamage:OnHPChange(actor:GetActorID(), giver, deltaHP, hpChgReason)

    if self.m_dragonLogic then
        self.m_dragonLogic:UpdateHP(actor:GetActorID(), deltaHP)
    end

    if actor and actor:IsBoss() then
        local nowHP = actor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
        local oldHP = FixSub(nowHP, deltaHP)
        local maxHP = actor:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAXHP)

        local nowPercent = FixDiv(nowHP, maxHP)
        local oldPercent = FixDiv(oldHP, maxHP)

        if oldPercent >= 0.3 and nowPercent < 0.3 then
            self:CheckStandBy(BattleEnum.STANDBY_CHECKREASON_BOSS_HP, 30)
        elseif oldPercent >= 0.4 and nowPercent < 0.4 then
            self:CheckStandBy(BattleEnum.STANDBY_CHECKREASON_BOSS_HP, 40)
        elseif oldPercent >= 0.5 and nowPercent < 0.5 then
            self:CheckStandBy(BattleEnum.STANDBY_CHECKREASON_BOSS_HP, 50)
        elseif oldPercent >= 0.6 and nowPercent < 0.6 then
            self:CheckStandBy(BattleEnum.STANDBY_CHECKREASON_BOSS_HP, 60)
        elseif oldPercent >= 0.7 and nowPercent < 0.7 then
            self:CheckStandBy(BattleEnum.STANDBY_CHECKREASON_BOSS_HP, 70)
        elseif oldPercent >= 0.8 and nowPercent < 0.8 then
            self:CheckStandBy(BattleEnum.STANDBY_CHECKREASON_BOSS_HP, 80)
        end
    end


    if judge == BattleEnum.ROUNDJUDGE_BAOJI then
        self:OnSBBaoJi(actor, giver, deltaHP, hpChgReason, hurtType, judge)
    end
end

function BaseBattleLogic:OnSBBaoJi(actor, giver, deltaHP, hpChgReason, hurtType, judge)
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget and tmpTarget:IsLive() then
                tmpTarget:OnSBBaoJi(actor, giver, deltaHP, hpChgReason, hurtType, judge)
            end
        end
    )
end

function BaseBattleLogic:OnWinSettle(show_camera)
    -- show win camera
    -- req settle to server
    -- show result UI
    if show_camera then
        BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_WIN, "BattleWin")
    end
end

function BaseBattleLogic:OnLoseSettle(loseReason)
    CtlBattleInst:OnBattleLose()
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_LOSE, loseReason)
end

function BaseBattleLogic:ReqSettle(isWin)

end

function BaseBattleLogic:ShowDazhaoLastKill()
    -- 大招 最后一击 特写
end

function BaseBattleLogic:OnEnterParam(enterParam)
    self.m_battleParam = enterParam
end

function BaseBattleLogic:GetPreloadList()
    if self.m_component then
        return self:InnerGetPreloadList()
    else
        return {}
    end
end

function BaseBattleLogic:InnerGetPreloadList()
    local helper = CtlBattleInst:GetLogicHelper(self.m_battleType)
    return helper:GetPreloadList(self.m_battleParam.copyID)
end

function BaseBattleLogic:ShowBattleUI()

end

function BaseBattleLogic:GetBattleParam()
    return self.m_battleParam
end

function BaseBattleLogic:OnWaveCamera()

end

function BaseBattleLogic:ToWorldPosition(local_pos_fixv3, wave)
    if not local_pos_fixv3 then
        Logger.LogError('ToWorldPosition no pos ' .. wave)
    end

    local map_name = self.m_mapCfg.scenename
    local matrix = ConfigUtil.GetStandMatrixByMapName(map_name, wave)
    if matrix then
        local pos = Utils.MatrixMulPoint(matrix, local_pos_fixv3)
        local posY = self:GetZoneHeight(pos)
        pos.y = posY
        return pos
    end
    return local_pos_fixv3
end

function BaseBattleLogic:ToWorldDir(local_dir_fixv3, wave)
    local map_name = self.m_mapCfg.scenename
    local matrix = ConfigUtil.GetStandMatrixByMapName(map_name, wave)
    if matrix then
        return Utils.MatrixMulVector(matrix, local_dir_fixv3)
    end
    return local_dir_fixv3
end

function BaseBattleLogic:GetForward(camp, wave)
    if camp == BattleEnum.ActorCamp_LEFT then
        local tbl = self.m_forwardCache[BattleEnum.ActorCamp_LEFT]
        local f = tbl[wave]
        if not f then
            f = FixNormalize(self:ToWorldDir(FixVecConst.right(), wave))
            tbl[wave] = f
        end
        return f
    else
        local tbl = self.m_forwardCache[BattleEnum.ActorCamp_RIGHT]
        local f = tbl[wave]
        if not f then
            f = FixNormalize(self:ToWorldDir(FixVecConst.left(), wave))
            tbl[wave] = f
        end
        return f
    end
end

function BaseBattleLogic:GetCurrWaveForward(camp)
    return self:GetForward(camp, self.m_currWave)
end

-- return fixv3[]
function BaseBattleLogic:GetLeftPos(wave)
    --              1
    --       3          2
    --           5   4       
    return nil
end

-- return fixv3[]
function BaseBattleLogic:GetRightPos(wave)
    return nil
end

function BaseBattleLogic:GetBornWorldLocation(camp, wave, lineupPos)
    local stands = nil

    if camp == BattleEnum.ActorCamp_LEFT then
        stands = self:GetLeftPos(wave)
    else
        stands = self:GetRightPos(wave)
    end

    if not stands then
        Logger.LogError('Role stand pos is nil, please impl GetLeftPos, GetRightPos')
        return nil, nil
    end

    local localPos = stands[lineupPos]
    return self:ToWorldPosition(localPos, wave), self:GetForward(camp, wave)
end

function BaseBattleLogic:CustomDeadMode(actor, animate)
    return BattleEnum.DEADMODE_DEFAULT
end

function BaseBattleLogic:CreateBattleMonster(pos, monsterCfg, battleRoundCfg, monsterSkillLevel, monsterLevel)
    local level = monsterLevel and monsterLevel or battleRoundCfg.monsterLevel
    
    if not level or level < 0 then
        level = 0 
    end 

    local maxCfg = ConfigUtil.GetMonsterMaxCfgByLevel(level)
    if not maxCfg then 
        Logger.LogError('CreateBattleMonster no max cfg or level ' .. level)
        return
    end

    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(monsterCfg.role_id)
    if not wujiangCfg then 
        Logger.LogError('CreateBattleMonster no role cfg ' .. monsterCfg.role_id)
        return 
    end

    if wujiangCfg.rare == CommonDefine.WuJiangRareType_1 then
        monsterSkillLevel = 2
    elseif wujiangCfg.rare == CommonDefine.WuJiangRareType_2 then
        monsterSkillLevel = 4
    else
        monsterSkillLevel = 6
    end


    -- if not monsterSkillLevel then
    --     monsterSkillLevel = 1
    -- end

    local oneWujiang = OneBattleWujiang.New()

    local hpBuff = 0
    local phyAtkBuff = 0
    local magicAtkBuff = 0
    local phyDefBuff   = 0
    local magicDefBuff = 0
    local backSkillID = 0

    for i = 1, 2 do 
        local bossID = battleRoundCfg['bossID'..i]
        if bossID == monsterCfg.id then
            hpBuff = battleRoundCfg['hpBuff'..i]
            phyAtkBuff = battleRoundCfg['phyAtkBuff'..i]
            magicAtkBuff = battleRoundCfg['magicAtkBuff'..i]
            
            oneWujiang.bossType = battleRoundCfg.bossType
            oneWujiang.backSkillID = 0

            break
        end
    end
    
    oneWujiang.wujiangID = monsterCfg.role_id
    oneWujiang.level = level
    oneWujiang.lineUpPos = pos

    local valuePercent = FixDiv(battleRoundCfg.monsterValuePercent, 1000)

    local calc = function(maxval, factor, valuePercent, buff)
        local v = maxval
        v = FixMul(v, factor)
        v = FixMul(v, valuePercent)
        v = FixMul(v, buff)
        return FixFloor(v)
    end

    local buff = function(b)
        return FixAdd(1, FixDiv(b, 1000))
    end

    local factor = function(f)
        return FixDiv(f, 1000)
    end

    oneWujiang.max_hp = calc(maxCfg.max_hp, factor(monsterCfg.factor_maxhp), valuePercent, buff(hpBuff))
    oneWujiang.phy_atk = calc(maxCfg.phy_atk, factor(monsterCfg.factor_phyatk), valuePercent, buff(phyAtkBuff))
    oneWujiang.phy_def = calc(maxCfg.phy_def, factor(monsterCfg.factor_phydef), valuePercent, 1)
    oneWujiang.magic_atk = calc(maxCfg.magic_atk, factor(monsterCfg.factor_magicatk), valuePercent, buff(magicAtkBuff))
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

    oneWujiang.init_nuqi = battleRoundCfg.initNuqi

    -- monsterCfg.skillList 要配置普攻技能
    for _, skill_id in ipairs(monsterCfg.skillList) do
        table_insert(oneWujiang.skillList, {skill_id = skill_id, skill_level = monsterSkillLevel})
    end

    return oneWujiang
end

function BaseBattleLogic:FlushBattleRound(battleRoundCfg, immediatelyCreateObj)
    local GetMonsterCfgByID = ConfigUtil.GetMonsterCfgByID

    local actormgr = ActorManagerInst

    local monsterInFightRule = battleRoundCfg.monsterInFightRule
    local standbyCount = 0

    for i, monster in ipairs(battleRoundCfg.monsterlist) do
        local monsterID, aiType = monster[1], monster[2]
        local monsterSkillLevel = monster[3]

        local monsterCfg = GetMonsterCfgByID(monsterID)
        if monsterCfg then
            local createParam = ActorCreateParam.New()

            local rule = nil 
            if aiType == BattleEnum.AITYPE_STAND_BY_DEAD_COUNT then
                standbyCount = FixAdd(standbyCount, 1)
                rule = monsterInFightRule[standbyCount]
            end

            createParam:MakeAI(aiType, rule)
            
            local oneWujiang = self:CreateBattleMonster(i, monsterCfg, battleRoundCfg, monsterSkillLevel)
            createParam:MakeMonster(monsterID, oneWujiang.bossType)
            createParam:MakeAttr(BattleEnum.ActorCamp_RIGHT, oneWujiang)
            createParam:MakeLocation(self:GetBornWorldLocation(BattleEnum.ActorCamp_RIGHT, self.m_currWave, i)) 
            createParam:SetImmediateCreateObj(immediatelyCreateObj)

            actormgr:CreateActor(createParam)
        end
    end
end

-- killer StatusGiver
function BaseBattleLogic:OnActorDie(actor, killerGiver, hurtReason, deadMode)
    
    self.m_battleDamage:OnActorDie(actor, killerGiver)
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() then
                tmpTarget:OnSBDie(actor, killerGiver)
            end
        end
    )

    BattleCameraMgr:OnActorDie(actor)

    if self.m_component then
        self.m_component:OnActorDie(actor, killerGiver, hurtReason)
    end
end

function BaseBattleLogic:CustomActorDie(actor, animate)
    return BattleEnum.DEADMODE_DEFAULT
end

function BaseBattleLogic:BodyRemoved(actor)
    return true
end

function BaseBattleLogic:CanAddStatus(performer, target, status, onlyInFight)
    return not onlyInFight or CtlBattleInst:IsInFight()
end

function BaseBattleLogic:IsBeatBackOnHurt(actor, atker, skillCfg)
    return false
end

function BaseBattleLogic:IsDazhaoSimple(actor)
    return false
end

function BaseBattleLogic:CreatePathHandler()

    if self.m_mapCfg then
        local map_name = self.m_mapCfg.scenename
        local matrix = ConfigUtil.GetCellMatrixByMapName(map_name)
        if matrix then
           
            return Pathing:GetPathingHandler(matrix)
        end
    end

    return nil
end

function BaseBattleLogic:GetZoneHeight(pos)
    if pos then
        local pathHandler = CtlBattleInst:GetPathHandler()
        if pathHandler then
            local x, y, z = pos:GetXYZ()
            local y = pathHandler:GetYByXZ(x, z)
            if y then
                return y
            end
        end
    end

    return 0
end

function BaseBattleLogic:GetZoneHeightByXZ(x, z)
    if x and z then
        local pathHandler = CtlBattleInst:GetPathHandler()
        if pathHandler then
            local y = pathHandler:GetYByXZ(x, z)
            if y then
                return y
            end
        end
    end

    return 0
end

function BaseBattleLogic:CreateSkillInputMgr()
    if Config.IsClient then
        local cc = require "GameLogic.Battle.Input.ActorSkillInputMgr"
        return cc.New()
    else
        local cc = require "GameLogic.Battle.Input.BaseSkillInputMgr"
        return cc.New()
    end
end

function BaseBattleLogic:CanDaZhao(camp)
    if CtlBattleInst:IsInFight() and not self.m_autoFight then
        if ActorManagerInst:IsAnyCampAllDie() then
           return false
        end
        return true
    end

    return false
end

function BaseBattleLogic:RecordCommand()
    return false
end

function BaseBattleLogic:OnFinish(playerWin, loseReason, killGiver)
    if self.m_finish then
        return
    end

    self:SetKillInfo(playerWin, loseReason, killGiver)
    self:FinishBattle()
    self:DoFinish()
    self:StopRecord()

    if self.m_resultParam.playerWin then
        self.m_battleDamage:SetWinCamp(BattleEnum.ActorCamp_LEFT)
    else
        if self.m_resultParam.loseReason == BattleEnum.BATTLE_LOSE_REASON_TIMEOUT then
            self.m_battleDamage:SetWinCamp(0)
        else
            self.m_battleDamage:SetWinCamp(BattleEnum.ActorCamp_RIGHT)
        end
    end

    if playerWin then
        self:WinActionOnKiller(killGiver)
    end

    EffectMgr:RemoveAllEffect()
end

function BaseBattleLogic:GetBattleResult()
    --结果，0通关，1失败，2超时
    if self.m_resultParam.playerWin then
        return 0
    else
        if self.m_resultParam.loseReason == BattleEnum.BATTLE_LOSE_REASON_TIMEOUT then
            return 2
        else
            return 1
        end
    end
end

function BaseBattleLogic:SetKillInfo(playerWin, loseReason, killGiver)    
    self.m_resultParam.playerWin = playerWin
    self.m_resultParam.loseReason = loseReason
    self.m_resultParam.killGiver = killGiver
    self.m_resultParam.finishTime = self.m_sinceStartMS

    if self.m_resultParam.playerWin then
        self.m_battleDamage:SetWinCamp(BattleEnum.ActorCamp_LEFT)
    else
        self.m_battleDamage:SetWinCamp(BattleEnum.ActorCamp_RIGHT)
    end

    self:StopRecord()
end

function BaseBattleLogic:FinishBattle()
    if self.m_finish then
        return
    end
    self.m_finish = true
    BattleCameraMgr:StopShake()

    self:OnBattleStop()
end

function BaseBattleLogic:DoFinish()
    
end

function BaseBattleLogic:GetResultParam()
    return self.m_resultParam
end

function BaseBattleLogic:GetCurWave()
    return self.m_currWave
end

function BaseBattleLogic:GetMaxWave()
    return 1
end

function BaseBattleLogic:GetDamageRecorder()
    return self.m_battleDamage
end

function BaseBattleLogic:GetDragonLogic()
    return self.m_dragonLogic
end

function BaseBattleLogic:PerformDragonSkill(camp)
    if self:CanManualPerformDragonSkill() then
        if self.m_dragonLogic then
            self.m_dragonLogic:PerformDragonSkill(camp)
        end
    end
end

function BaseBattleLogic:PlayDollyGroupCamera(dollyImmediate)
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DOLLY_GROUP, "DollyGroup")
end

function BaseBattleLogic:GetBattleID()
    return self.m_battleID
end

function BaseBattleLogic:CanManualPerformDragonSkill()
    return true
end

function BaseBattleLogic:OnCityReturn()
    --todo
    --CtlBattleInst:Resume(BattleEnum.PAUSEREASON_WANT_EXIT)
    SceneManagerInst:SwitchScene(SceneConfig.HomeScene)
end

function BaseBattleLogic:StopRecord()
    if self.m_battleDamage then
        self.m_battleDamage:StopRecord()
    end
    FrameDebuggerInst:SetFrameRecord(false)
end

function BaseBattleLogic:GetBattleType()
    return self.m_battleType
end

-- UI创建都是异步的，外部创建Ui后没有一个合适的节点去隐藏它。现在UI创建后OnEnable里面会取这个值选择是否隐藏。
function BaseBattleLogic:IsHideUIWhenUIStart()
    return true
end

function BaseBattleLogic:WinActionOnKiller(killerGiver)
    local killer = ActorManagerInst:GetActor(killerGiver.actorID)
   
    local uncheckActorList = {}
    local checkActorList =  {}
    if killer then
        table_insert(checkActorList, killer)
    end

    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT and tmpTarget:IsLive() and tmpTarget ~= killer then
                table_insert(uncheckActorList, tmpTarget)
            end
        end
    )

    if #uncheckActorList <= 0 then
        return
    end

    local leftCheckRound = 5

    for i = #uncheckActorList, 1, -1 do
        local actor = uncheckActorList[i]
        local actorPos = actor:GetPosition()
        
        local index = 0
        for j=1,#checkActorList do
            local fixPos = checkActorList[j]:GetPosition()
            local dir = actorPos - fixPos
            if dir:SqrMagnitude() <= 3 then
                local value = FixDiv(BattleRander.Rand(), 100)
                local tmpPos = FixNewVector3(FixSin(value) * 2, 0, FixCos(value) * 2)
                actor:SetPosition(fixPos + tmpPos)
            end

            index = j
        end

        if index >= #checkActorList then
            table_remove(uncheckActorList, i)
            table_insert(checkActorList, actor)
        end

        if i == 1 and #uncheckActorList > 0 and leftCheckRound > 0 then
            leftCheckRound = FixSub(leftCheckRound, 1)
            i = #uncheckActorList
        end
    end
end

function BaseBattleLogic:SwitchCamera()
    self.m_cameraAngleMode = self.m_cameraAngleMode + 1
    self.m_cameraAngleMode = self.m_cameraAngleMode > BattleEnum.CAMERA_ANGLE_40 and BattleEnum.CAMERA_ANGLE_20 or self.m_cameraAngleMode
    -- Logger.Log("SwitchCamera:" .. self.m_cameraAngleMode)
    if CtlBattleInst:IsInFight() then
        self:PlayDollyGroupCamera(true)
    end
end

function BaseBattleLogic:GetLeftS()
    local left = self.m_timeToEndMS - self.m_sinceStartMS
    left = left / 1000
    if left < 0 then
        left = 0
    end

    return left
end

function BaseBattleLogic:IsPathHandlerHitTest()
    return true
end

function BaseBattleLogic:GetSkillReducePercentLimit()
    return 0.7
end

function BaseBattleLogic:OnStandbyGoing()
    if self.m_bossBackTime == 0 then
        self.m_bossBackTime = 500
    end
end

function BaseBattleLogic:CheckBossBack(deltaMS)
    if self.m_bossBackTime > 0 then
        self.m_bossBackTime = FixSub(self.m_bossBackTime, deltaMS)

        if self.m_bossBackTime <= 0 then

            local boss = ActorManagerInst:GetOneActor(
                function(tmpTarget)
                    if tmpTarget:IsLive() and tmpTarget:IsBoss() and tmpTarget:GetBackSkillID() > 0 then
                        return true
                    end
                end
            )

            if boss then

                -- print('Check boss back  got boss' , boss:GetBackSkillID())

                boss:GetAI():BackAndSkill(1500, boss:GetBackSkillID())
            end
        end
    end
end


function BaseBattleLogic:CheckStandBy(checkReason, checkParam)
    -- local matchOne = 
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() and tmpTarget:GetCamp() == BattleEnum.ActorCamp_RIGHT then
                local ai = tmpTarget:GetAI()
                if ai and ai:GetAiType() == BattleEnum.AITYPE_STAND_BY_DEAD_COUNT and not ai:IsFighting() then
                    -- local tmp = self:CheckInFightCondition(ai, checkReason, checkParam)
                    -- if tmp then
                    --     return true
                    -- end

                    -- local tmp = 
                    ai:CheckFightCond(checkReason, checkParam)
                    -- if tmp then
                    --     return true
                    -- end
                end
            end
        end
    )

    -- if matchOne then
    --     self:OnStandbyGoing()
    -- end
end

function BaseBattleLogic:OnHurtFlyAway(pos)
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() and tmpTarget:GetCamp() == BattleEnum.ActorCamp_RIGHT then
                local ai = tmpTarget:GetAI()
                if ai and ai:GetAiType() == BattleEnum.AITYPE_STAND_BY_DEAD_COUNT and not ai:IsFighting() then
                    ai:OnSBHurtFlyAway(pos)
                end
            end
        end
    )
end

function BaseBattleLogic:IsFinished()
    return self.m_finish
end

function BaseBattleLogic:AddShield(actor)
    ActorManagerInst:Walk(
        function(tmpTarget)
            if tmpTarget:IsLive() then
                tmpTarget:OnSBAddShield(actor)
            end
        end
    )
end

function BaseBattleLogic:GetConsumedTime()
    local consumedTime = FixDiv(self:GetSinceStartMS(), 1000)
    return consumedTime
end

function BaseBattleLogic:ReplaceHurt(actor, deltaHP)
    return deltaHP
end

function BaseBattleLogic:WriteAutoFightSetting(isAutoFight)
    if self.m_component then
        self.m_component:WriteAutoFightSetting(isAutoFight)
    end
end

function BaseBattleLogic:ReadSpeedUpSetting()
    if self.m_component then
        return self.m_component:ReadSpeedUpSetting()
    end
end

function BaseBattleLogic:WriteSpeedUpSetting(speed)
    if self.m_component then
        self.m_component:WriteSpeedUpSetting(speed)
    end
end

function BaseBattleLogic:ReadAutoFightSetting()
    if self.m_component then
        return self.m_component:ReadAutoFightSetting()
    end
end

function BaseBattleLogic:NeedBlood(actor)
    return true
end

function BaseBattleLogic:CanPlayDaZhaoTimeline(actorID)
    if self.m_component then
        return self.m_component:CanPlayDaZhaoTimeline(actorID)
    end 
end

function BaseBattleLogic:PlayDaZhaoTimeline(actorID)
    if self:CanPlayDaZhaoTimeline(actorID) then
        CtlBattleInst:GetSkillCameraFX():PlayPrepareScreenEffect(actorID, true)
        BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DAZHAO_PERFORM, actorID)
    else
        CtlBattleInst:GetSkillCameraFX():PlayPrepareScreenEffect(actorID, false)
    end
end

function BaseBattleLogic:AlwaysPlayDazhaoTimeline()
    if self.m_component then
        self.m_component:AlwaysPlayDazhaoTimeline()
    end 
end

function BaseBattleLogic:GetTalentSkillData(camp, talentSkillID)
    if self.m_dragonLogic then
        return self.m_dragonLogic:GetTalentSkillData(camp, talentSkillID)
    end
end

function BaseBattleLogic:IsPlayDragonSkillShow()
    return true
end

function BaseBattleLogic:OnDragonSkillPerform(camp)

end

function BaseBattleLogic:GetComponent()
    return self.m_component
end

function BaseBattleLogic:CanRideHorse()
    return true
end

return BaseBattleLogic