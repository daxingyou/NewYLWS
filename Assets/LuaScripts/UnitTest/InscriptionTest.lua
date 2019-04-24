local base = require("UnitTest.SyncTestBase")
local GameUtility = CS.GameUtility
local table_insert = table.insert
local Random = Mathf.Random
local InscriptionTest = BaseClass("InscriptionTest", base)

function InscriptionTest:__init()
    self.m_curCopyIndex = 1
    self.m_inscriptionCopyList = {}
    local cfgList = ConfigUtil.GetInscriptionCopyCfgList()
    for _, v in ipairs(cfgList) do
        table_insert(self.m_inscriptionCopyList, v.id)
    end

    self:RegisterHandler(MsgIDDefine.INSCRIPTIONCOPY_RSP_FINISH_INSCRIPTIONCOPY, Bind(self, self.RspBattleFinish))
    self:RegisterHandler(MsgIDDefine.INSCRIPTIONCOPY_RSP_ENTER_INSCRIPTIONCOPY, Bind(self, self.RspInscriptionCopy), 0)
end

function InscriptionTest:Start()
    base.Start(self)

    print("****************InscriptionTest : " .. self.m_inscriptionCopyList[self.m_curCopyIndex])
    self:ReqEnterInscriptionCopy(self.m_inscriptionCopyList[self.m_curCopyIndex])
end

function InscriptionTest:ReqEnterInscriptionCopy(copyID)
	local msg_id = MsgIDDefine.INSCRIPTIONCOPY_REQ_ENTER_INSCRIPTIONCOPY
    local msg = (MsgIDMap[msg_id])()
    msg.copy_id = copyID
    local buzhenID = Utils.GetBuZhenIDByBattleType(BattleEnum.BattleType_INSCRIPTION)
    PBUtil.ConvertLineupDataToProto(buzhenID, msg.buzhen_info, self:GenerateLineupData(BattleEnum.BattleType_INSCRIPTION))

	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function InscriptionTest:RspInscriptionCopy(msg_obj)
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

    CtlBattleInst:InitBattle(BattleEnum.BattleType_INSCRIPTION, randSeeds, battleid)
    CtlBattleInst:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertCopyProto(copyID, leftFormation)
    CtlBattleInst.m_battleLogic:OnEnterParam(enterParam)
    
    self:SwitchScene(SceneConfig.BattleScene)
    self:StartFight()
    -- coroutine.start(self.StartFight, self)
    self:ReqBattleFinish()
end

function InscriptionTest:ReqBattleFinish()
    local msg_id = MsgIDDefine.INSCRIPTIONCOPY_REQ_FINISH_INSCRIPTIONCOPY
    local msg = (MsgIDMap[msg_id])()
    msg.copy_id = self.m_inscriptionCopyList[self.m_curCopyIndex]
    msg.finish_result = CtlBattleInst.m_battleLogic:GetBattleResult()

    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function InscriptionTest:RspBattleFinish(msg_obj)
	local result = msg_obj.result
	if result ~= 0 then
		return
    end
    
    local isEqual = self:CompareBattleResult(msg_obj.battle_result)
    if isEqual then
        self.m_curCopyIndex = self.m_curCopyIndex + 1
        if self.m_curCopyIndex > #self.m_inscriptionCopyList then
            self.m_curCopyIndex = 1
        end
        self:End()
    else
        Logger.LogError("Do not sync, report frame data to server")
        self:SaveBattleInfo()
        self.m_curCopyIndex = self.m_curCopyIndex + 1
        if self.m_curCopyIndex > #self.m_inscriptionCopyList then
            self.m_curCopyIndex = 1
        end
        self:ReqReportFrameData()
    end
end

function InscriptionTest:SaveBattleInfo()
    GameUtility.SafeWriteAllText("./FrameDebug/Inscription" .. CtlBattleInst.m_battleLogic:GetBattleID() .. ".txt", 
            "CopyID:" .. self.m_inscriptionCopyList[self.m_curCopyIndex] .. ", wujiang:" .. self.m_lineupData.roleSeqList[1] .. 
            "|" .. self.m_lineupData.roleSeqList[2] .. "|" .. self.m_lineupData.roleSeqList[3] .. "|" .. self.m_lineupData.roleSeqList[4] ..
            "|" .. self.m_lineupData.roleSeqList[5] .. " , dragonID: " .. self.m_lineupData.summon)
end

return InscriptionTest