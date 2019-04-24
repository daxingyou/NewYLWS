local base = require("UnitTest.SyncTestBase")
local GameUtility = CS.GameUtility
local table_insert = table.insert
local Random = Mathf.Random
local ShenBingTest = BaseClass("ShenBingTest", base)

function ShenBingTest:__init()
    self.m_curCopyIndex = 1
    self.m_shenbingCopyList = {}
    local cfgList = ConfigUtil.GetShenbingCopyCfgList()
    for _, v in ipairs(cfgList) do
        table_insert(self.m_shenbingCopyList, v.id)
    end

    self:RegisterHandler(MsgIDDefine.SHENBINGCOPY_RSP_FINISH_COPY, Bind(self, self.RspBattleFinish))
    self:RegisterHandler(MsgIDDefine.SHENBINGCOPY_RSP_ENTER_COPY, Bind(self, self.RspShenbingCopy), 0)
end

function ShenBingTest:Start()
    base.Start(self)

    print("****************ShenBingCopyTest : " .. self.m_shenbingCopyList[self.m_curCopyIndex])
    self:ReqEnterShenbingCopy(self.m_shenbingCopyList[self.m_curCopyIndex])
end

function ShenBingTest:ReqEnterShenbingCopy(copyID)
	local msg_id = MsgIDDefine.SHENBINGCOPY_REQ_ENTER_COPY
    local msg = (MsgIDMap[msg_id])()
    msg.shenbing_copy_id = copyID
    local buzhenID = Utils.GetBuZhenIDByBattleType(BattleEnum.BattleType_SHENBING)
    PBUtil.ConvertLineupDataToProto(buzhenID, msg.buzhen_info, self:GenerateLineupData(BattleEnum.BattleType_SHENBING))

	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function ShenBingTest:RspShenbingCopy(msg_obj)
    self:ResetState()
    local result = msg_obj.result
    if result ~= 0 then
        self.m_curCopyIndex = 1
        self:End()
		return
    end
    
    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list

    CtlBattleInst:InitBattle(BattleEnum.BattleType_SHENBING, randSeeds, battleid)
    CtlBattleInst:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertShenbingProto(copyID, leftFormation, msg_obj.random_award_list)
    CtlBattleInst.m_battleLogic:OnEnterParam(enterParam)
    
    self:SwitchScene(SceneConfig.BattleScene)
    self:StartFight()
    -- coroutine.start(self.StartFight, self)
    self:ReqBattleFinish()
end

function ShenBingTest:ReqBattleFinish()
    local msg_id = MsgIDDefine.SHENBINGCOPY_REQ_FINISH_COPY
    local msg = (MsgIDMap[msg_id])()
    msg.shenbing_copy_id = self.m_shenbingCopyList[self.m_curCopyIndex]
    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function ShenBingTest:RspBattleFinish(msg_obj)
	local result = msg_obj.result
	if result ~= 0 then
		return
    end
    
    local isEqual = self:CompareBattleResult(msg_obj.battle_result)
    if isEqual then
        self.m_curCopyIndex = self.m_curCopyIndex + 1
        if self.m_curCopyIndex > #self.m_shenbingCopyList then
            self.m_curCopyIndex = 1
        end
        self:End()
    else
        Logger.LogError("Do not sync, report frame data to server")
        self:SaveBattleInfo()
        self.m_curCopyIndex = self.m_curCopyIndex + 1
        if self.m_curCopyIndex > #self.m_shenbingCopyList then
            self.m_curCopyIndex = 1
        end
        self:ReqReportFrameData()
    end
end

function ShenBingTest:SaveBattleInfo()
    GameUtility.SafeWriteAllText("./FrameDebug/ShenBing" .. CtlBattleInst.m_battleLogic:GetBattleID() .. ".txt", 
            "CopyID:" .. self.m_shenbingCopyList[self.m_curCopyIndex] .. ", wujiang:" .. self.m_lineupData.roleSeqList[1] .. 
            "|" .. self.m_lineupData.roleSeqList[2] .. "|" .. self.m_lineupData.roleSeqList[3] .. "|" .. self.m_lineupData.roleSeqList[4] ..
            "|" .. self.m_lineupData.roleSeqList[5] .. " , dragonID: " .. self.m_lineupData.summon)
end

function ShenBingTest:SelectShengBing()
    if CtlBattleInst.m_battleLogic.m_shenbingAwardsList then
        local randNum = Random(1, #CtlBattleInst.m_battleLogic.m_shenbingAwardsList)
        local award = CtlBattleInst.m_battleLogic.m_shenbingAwardsList[randNum]
        FrameCmdFactory:GetInstance():ProductCommand(BattleEnum.FRAME_CMD_TYPE_SELECT_SHENBING, award.award.award_index, award.award_actor_id)
        CtlBattleInst.m_battleLogic.m_shenbingAwardsList = nil
    end
end

function ShenBingTest:OnFightUpdate()
    self:SelectShengBing()
end

return ShenBingTest