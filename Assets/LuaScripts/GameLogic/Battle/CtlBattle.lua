
local BattleEnum = BattleEnum
local table_insert = table.insert
local table_remove = table.remove
local FixFloor = FixMath.floor
local FixSub = FixMath.sub
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixHDMul = FixMath.mul_hd
local PLOTPROGRESS = PLOTPROGRESS
local SequenceEventType = SequenceEventType
local FixNewVector3 = FixMath.NewFixVector3

local CtlBattle = BaseClass("CtlBattle", Singleton)

local LogError = Logger.LogError

function CtlBattle:__init()
    self.m_battleLogic = nil
    self.m_pauserID = 0
    self.m_isPause = false
    self.m_battleStatus = BattleEnum.BattleStatus_NULL

    self.m_commandQueue = {}
    self.m_commandRecorder = {}
    self.m_updateFrameCurTime = 0
    self.m_waitUpdateSingleFrame = 0
    self.m_curFrame = 0
    self.m_svrFrameDelta = 33
    self.m_updateFrameLimit = 2

    self.m_pauseListeners = {}
    self.m_pauseReason = 0
    self.m_pauserID = 0
    self.m_pathHandler = nil
    self.m_skillInputMgr = nil
    self.m_skillCameraFX = nil

    self.m_framePaused = false
    self.m_logicHelperDict = {}
end

function CtlBattle:Clear()
    self.m_battleStatus = BattleEnum.BattleStatus_NULL
    
    if self.m_battleLogic then
        self.m_battleLogic:Delete()
        self.m_battleLogic = nil
    end

    self.m_pauserID = 0
    self.m_isPause = false
    self.m_commandQueue = {}
    self.m_logicHelperDict = {}
    self.m_commandRecorder = {}
    self.m_updateFrameCurTime = 0
    self.m_waitUpdateSingleFrame = 0
    self.m_curFrame = 0
    self.m_pauseListeners = {}
    self.m_pauseReason = 0
    self.m_pauserID = 0
    self.m_pathHandler = nil

    if self.m_skillInputMgr then
        self.m_skillInputMgr:Delete()
        self.m_skillInputMgr = nil
    end

    if self.m_skillCameraFX then
        self.m_skillCameraFX:Delete()
        self.m_skillCameraFX = nil
    end

    self.m_framePaused = false
end

function CtlBattle:AddFrameCommand(command)
    table_insert(self.m_commandQueue, command)

    if self.m_battleLogic and self.m_battleLogic:RecordCommand() then
        table_insert(self.m_commandRecorder, command)
    end
end

function CtlBattle:InitCommandQueue(cmdList)
    if not cmdList then
        return
    end
    
    for _,commandProto in Utils.IterPbRepeated(cmdList) do
        if commandProto then
            if commandProto.cmd_type == BattleEnum.FRAME_CMD_TYPE_SUMMON_PERFORM then
                FrameCmdFactory:GetInstance():ProductSummonPerformCmd(commandProto.frame_num, commandProto.cmd_summon_perform.camp)
            elseif commandProto.cmd_type == BattleEnum.FRAME_CMD_TYPE_SKILL_INPUT_END then
                local data = commandProto.cmd_input_end
                local performPos = FixNewVector3(data.perform_pos.x, data.perform_pos.y, data.perform_pos.z)
                FrameCmdFactory:GetInstance():ProductSkillInputEndCmd(commandProto.frame_num, performPos, data.performer_id, data.target_id)
            elseif commandProto.cmd_type == BattleEnum.FRAME_CMD_TYPE_AUTO_FIGHT then
                FrameCmdFactory:GetInstance():ProductAutoFightCmd(commandProto.frame_num)
            elseif commandProto.cmd_type == BattleEnum.FRAME_CMD_TYPE_CREATE_BENCH then
                FrameCmdFactory:GetInstance():ProductCreateBenchWujiangCmd(commandProto.frame_num, commandProto.cmd_create_bench.wujiang_id)
            elseif commandProto.cmd_type == BattleEnum.FRAME_CMD_TYPE_SELECT_SHENBING then
                FrameCmdFactory:GetInstance():ProductSelectShenbingCmd(commandProto.frame_num, commandProto.cmd_select_shenbing.award_index, commandProto.cmd_select_shenbing.award_actor_id)
            elseif commandProto.cmd_type == BattleEnum.FRAME_CMD_TYPE_GUILDBOSS_SYNC_HP then
                FrameCmdFactory:GetInstance():ProductGuildBossSyncHPCmd(commandProto.frame_num, commandProto.cmd_guildboss_sync_hp.harm, commandProto.cmd_guildboss_sync_hp.left_hp, commandProto.cmd_guildboss_sync_hp.is_self)
            end
        end
    end
end

function CtlBattle:GetFrameCmdList()
    return self.m_commandRecorder
end

function CtlBattle:IsFramePause()
    return self.m_framePaused
end

function CtlBattle:FramePause()
    if FrameDebuggerInst:IsTraceInfo() then
        FrameDebuggerInst:FrameLog("FramePause")
    end
    self.m_framePaused = true
end

function CtlBattle:FrameResume()
    if FrameDebuggerInst:IsTraceInfo() then
        FrameDebuggerInst:FrameLog("FrameResume")
    end
    self.m_framePaused = false
end

function CtlBattle:Update(deltaTime)
    if not self:IsInitComplete() then
        return
    end

    -- 外部帧暂停是由同步逻辑之外逻辑触发的暂停，比如UI界面点击后暂停
    -- 内部帧暂停时有同步逻辑内的代码触发的暂停，比如一波战斗结束后暂停
    if self.m_framePaused then
        -- 帧暂停后不再更新，保证客户端和服务器逻辑同步
        
        return
    end

    self.m_waitUpdateSingleFrame = FixAdd(self.m_waitUpdateSingleFrame, FixHDMul(deltaTime, 1000))

    -- 帧同步说明：为了保证在Unity帧率低时帧同步也能有良好的表现效果，所以这里需要追帧逻辑，也就是Unity一帧内帧同步会更新多帧
    while self.m_waitUpdateSingleFrame >= self.m_svrFrameDelta do
        if self.m_framePaused then
            -- 这里是为了防止内部帧暂停导致客户端帧号和服务器不一致。
            -- 举例说明：客户端在一波战斗结束后帧暂停，等待玩家点击后前往下一波。但是服务器会在同一帧内前往下一波。
            -- 如果此处不return，在网络卡的时候这里会追帧，导致帧号和服务器不一致。前往下一波战斗的帧号是不一致的。
            return
        end
        self.m_curFrame = FixAdd(self.m_curFrame, 1)

        while #self.m_commandQueue > 0 do
            local command = self.m_commandQueue[1]
            local cmdFrameNum = command:GetFrameNum()
            if cmdFrameNum > self.m_curFrame then
                break
            end

            -- command:SetFrameNum(cmdFrameNum)
            command:Execute()
            table_remove(self.m_commandQueue, 1)
        end

        self:InnerUpdate(self.m_svrFrameDelta)
        if self.m_battleLogic then
            local dragonLogic = self.m_battleLogic:GetDragonLogic()
            if dragonLogic then
                dragonLogic:Update(self.m_svrFrameDelta)
            end
        end

        self.m_waitUpdateSingleFrame = FixSub(self.m_waitUpdateSingleFrame, self.m_svrFrameDelta)
        -- break
        -- self.m_waitUpdateSingleFrame = 0
    end
end

function CtlBattle:LateUpdate(deltaTime)
    if self.m_skillInputMgr then
        self.m_skillInputMgr:Update()
    end

    if self.m_battleLogic then
        self.m_battleLogic:UpdateComponent()
    end
end

function CtlBattle:InnerUpdate(deltaMS)
    if self.m_battleLogic then
        self.m_battleLogic:Update(deltaMS , self.m_battleStatus)
    end

    ActorManagerInst:Update(deltaMS)
    MediumManagerInst:Update(deltaMS)
end

function CtlBattle:GetLogic()
    return self.m_battleLogic
end

function CtlBattle:CreateBattleLogic(battleType, battleid)
    if battleType == BattleEnum.BattleType_COPY then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.CopyLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_ARENA then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.ArenaLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_FRIEND_CHALLENGE then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.FriendChallengeLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_TEST then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.TestLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_BOSS1 then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.Boss1Logic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_BOSS2 then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.Boss2Logic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_PLOT then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.PlotLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_CAMPSRUSH then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.CampsRushLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_SHENBING then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.ShenbingLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_YUANMEN then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.YuanmenLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_INSCRIPTION then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.InscriptionLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_GUILD_BOSS then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.GuildBossLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_GRAVE then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.GraveLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_GUILD_WARCRAFT then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.GuildWarLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_ROB_GUILD_HUSONG then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.GuildWarRobLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_SHENSHOU then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.ShenShouLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_LIEZHUAN then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.LieZhuanLogic")
        return BTClass.New(battleid) 
    elseif battleType == BattleEnum.BattleType_QUNXIONGZHULU then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.GroupHerosLogic")
        return BTClass.New(battleid)
    elseif battleType == BattleEnum.BattleType_LIEZHUAN_TEAM then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.LieZhuanTeamLogic")
        return BTClass.New(battleid) 
    elseif battleType == BattleEnum.BattleType_HORSERACE then
        local BTClass = require("GameLogic.Battle.BattleLogic.impl.HorseRaceLogic")
        return BTClass.New(battleid) 
    end

    LogError('CreateBattleLogic no battle type ' .. battleType)
end

function CtlBattle:InitBattle(battleType, randSeedList, battleid)
    Formular.Init()
    BattleRander.AddRandList(randSeedList)

    self.m_pauserID = 0
    self.m_isPause = false
    
    FrameDebuggerInst:SetFrameRecord(true)
    self.m_battleLogic = self:CreateBattleLogic(battleType, battleid)
    ComponentMgr:CreateBattleLogicComponent(battleType, self.m_battleLogic)
end

function CtlBattle:EnterBoss(battletype, copyID, battleid, leftFormation, rightFormation, randSeeds, cmdList, bossLevel)
    if self.m_battleLogic then
        LogError('CtlBattle EnterBoss already Entered')
        return
    end        


    self:InitBattle(battletype, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertBossProto(bossLevel, leftFormation, rightFormation)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, battletype)

end

function CtlBattle:EnterCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterCopy already Entered')
        return
    end        

    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list
	local battleType = msg_obj.battle_info.battle_type

    self:InitBattle(msg_obj.battle_info.battle_type, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertCopyProto(copyID, leftFormation, rightFormation, msg_obj.nonstop_fight)
    self.m_battleLogic:OnEnterParam(enterParam)
    self.m_battleLogic:CacheDropList(msg_obj.drop_list, msg_obj.boss_drop_list)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, battleType)
end

function CtlBattle:EnterGuildBoss(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterGuildBoss already Entered')
        return
    end        

    -- battle_info.param1   boss_index  battle_info.param2   boss level  battle_info.param3   boss curr hp  battle_info.param4   boss max hp
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation_list
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list
	local battleType = msg_obj.battle_info.battle_type
    self:InitBattle(battleType, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertGuildBossProto(tonumber(msg_obj.battle_info.param1), tonumber(msg_obj.battle_info.param2), tonumber(msg_obj.battle_info.param3), 
    tonumber(msg_obj.battle_info.param4), msg_obj.battle_info.copy_id, leftFormation, rightFormation, msg_obj.nonstop_fight)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, battleType)
end

function CtlBattle:EnterPlot(proto)
    if self.m_battleLogic then
        LogError('CtlBattle EnterPlot already Entered')
        return
    end        

    -- todo 后面要用服务器传下来的种子序列
    BattleRander.Generate(500)
    self:InitBattle(BattleEnum.BattleType_PLOT, BattleRander.m_randList)
    local enterParam = BattleProtoConvert.ConvertCopyProtoForTest(proto)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_PLOT)
end

function CtlBattle:EnterArena(battleid, leftFormation, rightFormation, randSeeds, battleResultData, resultInfo)
    if self.m_battleLogic then
        LogError('CtlBattle EnterArena already Entered')
        return
    end        

    self:InitBattle(BattleEnum.BattleType_ARENA, randSeeds, battleid)
    local enterParam = BattleProtoConvert.ConvertArenaProto(leftFormation, rightFormation, battleResultData, resultInfo)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_ARENA)
end

function CtlBattle:EnterGroupHerosWar(battleid, leftFormation, rightFormation, randSeeds, battleResultData, resultInfo)
    if self.m_battleLogic then
        LogError('CtlBattle EnterGroupHerosWar already Entered')
        return
    end
    self:InitBattle(BattleEnum.BattleType_QUNXIONGZHULU, randSeeds, battleid)
    local enterParam = BattleProtoConvert.ConvertGroupHerosWarProto(leftFormation, rightFormation, battleResultData, resultInfo)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_QUNXIONGZHULU)
end

function CtlBattle:EnterFriendChallenge(battleid, leftFormation, rightFormationList, randSeeds)
    if self.m_battleLogic then
        LogError('CtlBattle EnterArena already Entered')
        return
    end        

    self:InitBattle(BattleEnum.BattleType_FRIEND_CHALLENGE, randSeeds, battleid)
    local enterParam = BattleProtoConvert.ConvertFriendChallengeProto(leftFormation, rightFormationList)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_FRIEND_CHALLENGE)
end

function CtlBattle:EnterVideo(battleid, battle_type, leftFormation, rightFormation, randSeeds, battleVersion, parameter1, parameter2)
    if self.m_battleLogic then
        LogError('CtlBattle EnterVideo already Entered')
        return
    end        
    if battleVersion ~= BattleEnum.BATTLE_VERSION then
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(1107),Language.GetString(1122), Language.GetString(10))
        return
    end

    self:InitBattle(battle_type, randSeeds, battleid)

    local enterParam
    if battle_type == BattleEnum.BattleType_HORSERACE then
        enterParam = BattleProtoConvert.ConvertHorseRaceProto(leftFormation, rightFormation, nil, parameter1, parameter2)
    else
        enterParam = BattleProtoConvert.ConvertArenaProto(leftFormation, rightFormation, nil, parameter1)
    end
    
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, battle_type, true)
end

function CtlBattle:EnterInscriptionCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterInscriptionCopy already Entered')
        return
    end        

    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list

    self:InitBattle(BattleEnum.BattleType_INSCRIPTION, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertCopyProto(copyID, leftFormation)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_INSCRIPTION)
end

function CtlBattle:EnterShenbingCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterShenbingCopy already Entered')
        return
    end        

    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list

    self:InitBattle(BattleEnum.BattleType_SHENBING, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertShenbingProto(copyID, leftFormation, msg_obj.random_award_list, msg_obj.battle_info.shenbingcopy_battle.seq_random_list)
    
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_SHENBING)
end

function CtlBattle:EnterShenShouCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterShenbingCopy already Entered')
        return
    end

    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
    local cmdList = msg_obj.battle_info.cmd_list
    local challengeCount = msg_obj.battle_info.param1
    local bossLevel = msg_obj.battle_info.param2

    self:InitBattle(BattleEnum.BattleType_SHENSHOU, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertShenShouProto(copyID, leftFormation, challengeCount, bossLevel)

    self.m_battleLogic:OnEnterParam(enterParam)

    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_SHENSHOU)
end

function CtlBattle:EnterYuanmenCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterYuanmenCopy already Entered')
        return
    end        

    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list

    self:InitBattle(BattleEnum.BattleType_YUANMEN, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertYuanmenProto(copyID, tonumber(msg_obj.battle_info.param1), tonumber(msg_obj.battle_info.param2), 
        leftFormation, msg_obj.battle_info.yuanmen_battle)
    
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_YUANMEN)
end

function CtlBattle:EnterGraveCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterGraveCopy already Entered')
        return
    end        

    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
    local randSeeds = msg_obj.battle_info.battle_random_seeds
    local cmdList = msg_obj.battle_info.cmd_list
   
    self:InitBattle(BattleEnum.BattleType_GRAVE, randSeeds, battleid)
    self:InitCommandQueue(cmdList)

    local isFirstIn = msg_obj.is_guide
    local enterParam = BattleProtoConvert.ConvertGraveProto(copyID, leftFormation, msg_obj.nonstop_fight, isFirstIn)
    
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_GRAVE)
end

function CtlBattle:EnterGuildWarCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle GuildWarCopy already Entered')
        return
    end

    local copyID = msg_obj.battle_info.copy_id
    local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation_list
	local randSeeds = msg_obj.battle_info.battle_random_seeds
    local cmdList = msg_obj.battle_info.cmd_list
    
    self:InitBattle(BattleEnum.BattleType_GUILD_WARCRAFT, randSeeds, battleid)
    self:InitCommandQueue(cmdList)

    local enterParam = BattleProtoConvert.ConvertGuildWarProto(leftFormation, rightFormation, msg_obj.rival_guild_brief, msg_obj.rival_info, msg_obj.offence_left_time, msg_obj.rival_guild_left_member_num, copyID)
    self.m_battleLogic:OnEnterParam(enterParam)

    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_GUILD_WARCRAFT, true)
end

function CtlBattle:EnterGuildWarRobCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle GuildWarCopy already Entered')
        return
    end

    local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation_list
	local randSeeds = msg_obj.battle_info.battle_random_seeds
    local cmdList = msg_obj.battle_info.cmd_list

    self:InitBattle(BattleEnum.BattleType_ROB_GUILD_HUSONG, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertGuildWarRobProto(leftFormation, rightFormation)
    self.m_battleLogic:OnEnterParam(enterParam)

    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_ROB_GUILD_HUSONG, true)
end

function CtlBattle:EnterLieZhuanCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterLieZhuanCopy already Entered')
        return
    end        
    
    local copyID = msg_obj.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list
	local battleType = msg_obj.battle_info.battle_type

    self:InitBattle(BattleEnum.BattleType_LIEZHUAN, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertLieZhuanProto(copyID, leftFormation, rightFormation)  
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_LIEZHUAN)
end

function CtlBattle:EnterLieZhuanTeamCopy(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterLieZhuanTeamCopy already Entered')
        return
    end        
    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list
    local battleType = msg_obj.battle_info.battle_type
    
    local battleResultData = {
        finish_result = msg_obj.finish_result,
        copy_id = msg_obj.battle_info.copy_id,
        drop_list = msg_obj.drop_list,
        resultInfo = msg_obj.battle_result_info,
    }

    self:InitBattle(BattleEnum.BattleType_LIEZHUAN_TEAM, randSeeds, battleid)
    self:InitCommandQueue(cmdList)

    local enterParam = BattleProtoConvert.ConvertLieZhuanTeamProto(copyID, leftFormation, battleResultData)  
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_LIEZHUAN_TEAM, true)
end

function CtlBattle:EnterHorseRace(msg_obj)
    if self.m_battleLogic then
        LogError('CtlBattle EnterHorseRace already Entered')
        return
    end
    
    local copyID = msg_obj.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormationList = msg_obj.battle_info.right_formation_list
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list
    local battleType = msg_obj.battle_info.battle_type
    local racingBattleMapList = msg_obj.battle_info.racing_battle.racing_track_list
    local selfUid = msg_obj.uid

    local battleResultData = {
        finish_result = msg_obj.finish_result,
        drop_list = msg_obj.drop_list,
        resultInfo = msg_obj.battle_result_info,
    }

    self:InitBattle(BattleEnum.BattleType_HORSERACE, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertHorseRaceProto(leftFormation, rightFormationList, battleResultData, racingBattleMapList, selfUid)  
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene, BattleEnum.BattleType_HORSERACE, true)
end

-- function CtlBattle:EnterArenaTest(proto, wujiangFormation, wujiangFormation1)
--     if self.m_battleLogic then
--         LogError('EnterArena: CtlBattle EnterArenaTest already Entered')
--         return
--     end        

--     -- todo 后面要用服务器传下来的种子序列
--     BattleRander.Generate(500)
--     self:InitBattle(BattleEnum.BattleType_ARENA, BattleRander.m_randList)
--     local enterParam = BattleProtoConvert.ConvertArenaProto(wujiangFormation,wujiangFormation1)
--     self.m_battleLogic:OnEnterParam(enterParam)
    
--     SceneManagerInst:SwitchScene(SceneConfig.BattleScene)
-- end

function CtlBattle:EnterTestBattle(battletype, copyID, battleid, leftFormation, rightFormation, randSeeds, cmdList)
    if self.m_battleLogic then
        LogError('EnterTestBattle: CtlBattle EnterTestBattle already Entered')
        return
    end        

    self:InitBattle(battletype, randSeeds, battleid)
    self:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertCopyProto(copyID, leftFormation, rightFormation)
    self.m_battleLogic:OnEnterParam(enterParam)
    
    SceneManagerInst:SwitchScene(SceneConfig.BattleScene)
end

function CtlBattle:OnSceneCreated()
    if self.m_battleLogic then
        self.m_battleLogic:OnPreload()

        self.m_pathHandler = self.m_battleLogic:CreatePathHandler()
    end
end

-- function CtlBattle:OnScenePrepareEnter() 暂时用不上
--     if self.m_battleLogic then
--         self.m_battleLogic:OnScenePrepareEnter()
--     end
-- end

-- 战斗从此开始
function CtlBattle:OnSceneEnter()
    SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_LOGIC_INIT_BEGIN)
end

function CtlBattle:IsInitComplete()
    return self.m_battleStatus >= BattleEnum.BattleStatus_INITED
end


function CtlBattle:OnPlotProgress(progress, args)
    if progress == PLOTPROGRESS.INIT_BEGIN then
        if self.m_battleLogic then
            self.m_battleLogic:OnBattleInit()   --set wave 1
        end            
        SequenceMgr:GetInstance():TriggerEvent(SequenceEventType.BATTLE_LOGIC_INIT_COMPLETE)
   
    elseif progress == PLOTPROGRESS.INIT_END then
        self.m_battleStatus = BattleEnum.BattleStatus_INITED

    elseif progress == PLOTPROGRESS.BEGIN_CAMERA then
        self.m_battleStatus = BattleEnum.BattleStatus_WAVE_INTERVAL
        if self.m_battleLogic then
            self.m_battleLogic:GoToNextWave()   --go from wave 0 to 1
        end

    elseif progress == PLOTPROGRESS.BATTLE_START then
        self.m_battleStatus = BattleEnum.BattleStatus_WAVE_FIGHTING
        self.m_isPause = false

        if self.m_battleLogic then
            self.m_battleLogic:OnBattleStart()
        end

    elseif progress == PLOTPROGRESS.WAVE_END then
        self.m_battleStatus = BattleEnum.BattleStatus_WAVE_INTERVAL
        if self.m_battleLogic then
            self.m_battleLogic:OnWaveEnd()
        end

    elseif progress == PLOTPROGRESS.WAVE_CAMERA then
        self.m_battleStatus = BattleEnum.BattleStatus_WAVE_INTERVAL
        if self.m_battleLogic then
            self.m_battleLogic:GoToNextWave()
        end

    elseif progress == PLOTPROGRESS.FINISH then
        self.m_battleStatus = BattleEnum.BattleStatus_FINISH_SHOW
        if self.m_battleLogic then
            self.m_battleLogic:OnFinishAction()
        end

    elseif progress == PLOTPROGRESS.WIN_COMPLETE then
        self.m_battleStatus = BattleEnum.BattleStatus_REQ_SETTLING
        if self.m_battleLogic then
            self.m_battleLogic:OnWinSettle(true)
        end

    elseif progress == PLOTPROGRESS.WIN_COMPLETE_WITHOUT_CAMERA then
        self.m_battleStatus = BattleEnum.BattleStatus_REQ_SETTLING
        if self.m_battleLogic then
            self.m_battleLogic:OnWinSettle(false)
        end
    end
end

function CtlBattle:IsInFight()
    return self.m_battleStatus == BattleEnum.BattleStatus_WAVE_FIGHTING
end

function CtlBattle:IsBattleFinished()
    return self.m_battleStatus >= BattleEnum.BattleStatus_FINISH_SHOW
end

function CtlBattle:AddPauseListener(listener)
    if listener.Pause and listener.Resume then
        table_insert(self.m_pauseListeners, listener)

        if self.m_isPause then
            listener:Pause(self.m_pauseReason)
        end
    else
        Logger.LogError('listener no func pause ' .. listener)
    end
end

function CtlBattle:RemovePauseListener(listener)
    for i, v in ipairs(self.m_pauseListeners) do
        if v == listener then
            table_remove(self.m_pauseListeners, i)
            break
        end
    end
end

function CtlBattle:GetPauserID()
    return self.m_pauserID
end

function CtlBattle:SetPauserID(pauserID)
    self.m_pauserID = pauserID
end

function CtlBattle:IsPause()
    return self.m_isPause
end

function CtlBattle:Pause(reason, pauserID)
    if FrameDebuggerInst:IsTraceInfo() then
        FrameDebuggerInst:FrameLog("Pause")
    end
    
    for i, v in ipairs(self.m_pauseListeners) do
        v:Pause(reason)
    end

    self.m_pauseReason = reason
    self.m_pauserID = pauserID
    self.m_isPause = true
end

function CtlBattle:Resume(reason)
    if FrameDebuggerInst:IsTraceInfo() then
        FrameDebuggerInst:FrameLog("Resume")
    end
    
    for i, v in ipairs(self.m_pauseListeners) do
        v:Resume(reason)
    end

    self.m_pauserID = 0
    self.m_isPause = false
end

function CtlBattle:OnSceneLeave()
    self:Clear()
    ComponentMgr:Clear()
    ActorManagerInst:Clear()
    MediumManagerInst:Clear()
    BattleRecorder:GetInstance():Clear()
    StatusFactoryInst:Clear()
    WaveGoMgr:Clear()
    WavePlotMgr:Clear()
    -- todo
end

function CtlBattle:GetPathHandler()
    return self.m_pathHandler
end

function CtlBattle:GetCurFrame()
    return self.m_curFrame
end

function CtlBattle:GetSkillInputMgr()
    if not self.m_skillInputMgr then
        if self.m_battleLogic then
            self.m_skillInputMgr = self.m_battleLogic:CreateSkillInputMgr()
        end
    end

    return self.m_skillInputMgr
end

function CtlBattle:GetSkillCameraFX()
    if not self.m_skillCameraFX then
        if Config.IsClient then
            local cc = require "GameLogic.Battle.Camera.fx.ClientSkillCameraFX"
            self.m_skillCameraFX = cc.New()
        else
            local cc = require "GameLogic.Battle.Camera.fx.BaseSkillCameraFX"
            self.m_skillCameraFX = cc.New()
        end
    end
    
    return self.m_skillCameraFX
end

function CtlBattle:OnBattleLose()
    self.m_battleStatus = BattleEnum.BattleStatus_FINISH_SHOW
end

function CtlBattle:GetLogicHelper(battleType)
    if not self.m_logicHelperDict[battleType] then
        if battleType == BattleEnum.BattleType_COPY then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.CopyLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_ARENA then                
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.ArenaLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_FRIEND_CHALLENGE then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.FriendChallengeLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_TEST then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.TestLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_BOSS1 then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.Boss1LogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_BOSS2 then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.Boss2LogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_PLOT then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.PlotLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_CAMPSRUSH then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.CampsRushLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_SHENBING then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.ShenbingLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_YUANMEN then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.YuanmenLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_INSCRIPTION then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.InscriptionLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_GUILD_BOSS then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.GuildBossLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_GRAVE then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.GraveLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_GUILD_WARCRAFT then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.GuildWarLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_ROB_GUILD_HUSONG then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.GuildWarRobLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_SHENSHOU then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.ShenShouCopyLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_LIEZHUAN then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.LieZhuanLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_QUNXIONGZHULU then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.GroupHerosLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_LIEZHUAN_TEAM then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.LieZhuanTeamLogicHelper")
            return HelperClass.New(battleid)
        elseif battleType == BattleEnum.BattleType_HORSERACE then
            local HelperClass = require("GameLogic.Battle.BattleLogic.helper.HorseRaceLogicHelper")
            return HelperClass.New(battleid)
        end
    end
    return self.m_logicHelperDict[battleType]
end

function CtlBattle:EnterBattle(msg_obj)
    if msg_obj.battle_info.battle_ver ~= BattleEnum.BATTLE_VERSION then
            UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(1107),Language.GetString(1121), Language.GetString(10))
        return
    end
    if msg_obj.battle_info.battle_type == BattleEnum.BattleType_BOSS1 or msg_obj.battle_info.battle_type == BattleEnum.BattleType_BOSS2 then
        local copyID = msg_obj.battle_info.copy_id
        local battleid = msg_obj.battle_info.battle_id
        local leftFormation = msg_obj.battle_info.left_formation
        local rightFormation = msg_obj.battle_info.right_formation
        local randSeeds = msg_obj.battle_info.battle_random_seeds
        local cmdList = msg_obj.battle_info.cmd_list
        local battleType = msg_obj.battle_info.battle_type
        local bossLevel = tonumber(msg_obj.battle_info.param1)
        self:EnterBoss(battleType, copyID, battleid, leftFormation, rightFormation, randSeeds, cmdList, bossLevel)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_CAMPSRUSH or msg_obj.battle_info.battle_type == BattleEnum.BattleType_COPY then
        self:EnterCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_GUILD_BOSS then
        self:EnterGuildBoss(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_ARENA then
        local arenaBattleResultData = {
            is_winning = msg_obj.is_winning,
            prev_rank = msg_obj.prev_rank,
            curr_rank = msg_obj.curr_rank,
            prev_highest_rank = msg_obj.prev_highest_rank,
            curr_highest_rank = msg_obj.curr_highest_rank,
            wujiang_exp_list = msg_obj.wujiang_exp_list,
            award_money = msg_obj.award_money,
            award_doubi = msg_obj.award_doubi,
            award_yuanbao = msg_obj.award_yuanbao,
            prev_rank_dan = msg_obj.prev_rank_dan,
            curr_rank_dan = msg_obj.curr_rank_dan,
            resultInfo = msg_obj.battle_result_info,
            drop_list = msg_obj.drop_list,
            dan_up_drop_list = msg_obj.dan_up_drop_list
        }
    
        local battle_id = msg_obj.battle_info.battle_id
        local leftFormation = msg_obj.battle_info.left_formation
        local rightFormationList = msg_obj.battle_info.right_formation_list
        local randSeeds = msg_obj.battle_info.battle_random_seeds
        local resultInfo = msg_obj.battle_info.result_info
        self:EnterArena(battle_id, leftFormation, rightFormationList, randSeeds, arenaBattleResultData, resultInfo)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_QUNXIONGZHULU then
        local groupHerosWarBattleResultData = {
            uid = msg_obj.uid,
            battle_result = msg_obj.battle_result,
            src_score = msg_obj.src_score,
            score_chg = msg_obj.score_chg,
            drop_list = msg_obj.drop_list,
            video_id = msg_obj.video_id,
            time = msg_obj.time,
        }

        local battle_id = msg_obj.battle_info.battle_id
        local leftFormation = msg_obj.battle_info.left_formation
        local rightFormationList = msg_obj.battle_info.right_formation_list
        local randSeeds = msg_obj.battle_info.battle_random_seeds
        local resultInfo = msg_obj.battle_info.result_info
        self:EnterGroupHerosWar(battle_id, leftFormation, rightFormationList, randSeeds, groupHerosWarBattleResultData, resultInfo)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_FRIEND_CHALLENGE then
        local battle_id = msg_obj.battle_info.battle_id
        local leftFormation = msg_obj.battle_info.left_formation
        local rightFormationList = msg_obj.battle_info.right_formation_list
        local randSeeds = msg_obj.battle_info.battle_random_seeds
        self:EnterFriendChallenge(battle_id, leftFormation, rightFormationList, randSeeds)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_INSCRIPTION then
        self:EnterInscriptionCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_SHENBING then
        self:EnterShenbingCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_SHENSHOU then
        self:EnterShenShouCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_YUANMEN then
        self:EnterYuanmenCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_GRAVE then
        self:EnterGraveCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_GUILD_WARCRAFT then
        self:EnterGuildWarCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_ROB_GUILD_HUSONG then
        self:EnterGuildWarRobCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_LIEZHUAN then
        self:EnterLieZhuanCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_LIEZHUAN_TEAM then
        self:EnterLieZhuanTeamCopy(msg_obj)
    elseif msg_obj.battle_info.battle_type == BattleEnum.BattleType_HORSERACE then
        self:EnterHorseRace(msg_obj)
    end
end

return CtlBattle