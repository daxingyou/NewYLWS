
local PBUtil = PBUtil
local BattleEnum = BattleEnum
local BaseBattleLogicComponent = require "GameLogic.Battle.Component.BaseBattleLogicComponent"
local GuildBossLogicComponent = BaseClass("GuildBossLogicComponent", BaseBattleLogicComponent)
local guildBossMgr = Player:GetInstance():GetGuildBossMgr()

function GuildBossLogicComponent:__init(logic)
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_FINISH_ATK_BOSS, Bind(self, self.RspBattleFinish))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_BOSS_RT_DEDUCT_HP, Bind(self, self.RspBossRTDeductHP))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_NTF_BOSS_RT_DEDUCT_HP, Bind(self, self.NtfBossRTDeductHP))
    self.m_finishBattleMsg = false
end

function GuildBossLogicComponent:__delete()
    HallConnector:GetInstance():ClearHandler(MsgIDDefine.GUILD_RSP_FINISH_ATK_BOSS)
    HallConnector:GetInstance():ClearHandler(MsgIDDefine.GUILD_RSP_BOSS_RT_DEDUCT_HP)
    HallConnector:GetInstance():ClearHandler(MsgIDDefine.GUILD_NTF_BOSS_RT_DEDUCT_HP)
end
  
function GuildBossLogicComponent:ShowBattleUI()
    UIManagerInst:OpenWindow(UIWindowNames.UIBattleBossMain)
    BaseBattleLogicComponent.ShowBloodUI(self)
end  

function GuildBossLogicComponent:ReqBattleFinish(playerWin)
    local msg_id = MsgIDDefine.GUILD_REQ_FINISH_ATK_BOSS
	local msg = (MsgIDMap[msg_id])()
    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    msg.battle_result.guildboss_result.harm_num = self.m_logic:GetHarm()
    
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
    self:GenerateResultInfoProto(msg.battle_result)
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildBossLogicComponent:RspBattleFinish(msg_obj)
    self.m_finishBattleMsg = msg_obj

    local result = msg_obj.result
	if result ~= 0 then
		Logger.LogError('GuildBossLogicComponent failed: '.. result)
		return
    end
    
    local isEqual = self:CompareBattleResult(msg_obj.battle_result)
    if not isEqual then
        Logger.LogError("Do not sync, report frame data to server")
        self:ReqReportFrameData()
    end

    local bossID = self.m_logic:GetBossWujiangID()
    local info = {boss_id = bossID}

    guildBossMgr:SetFinishBattleMsg(msg_obj)
    UIManagerInst:CloseWindow(UIWindowNames.UIBattleBossMain)
    UIManagerInst:OpenWindow(UIWindowNames.UIGuildBossSettlement, msg_obj)
end

function GuildBossLogicComponent:GetGuildBossCfg()
    return guildBossMgr:GetBossCfg()
end

function GuildBossLogicComponent:RspBossRTDeductHP(msgObj)
    local result = msgObj.result
	if result ~= 0 then
        Logger.LogError('RspBossRTDeductHP failed: '.. result)
		return
    end

   -- print('========== fix guild boss hp suc ')
    -- self.m_logic:ClearRecordHarm()
end

function GuildBossLogicComponent:NtfBossRTDeductHP(msgObj)
    -- if Player:GetInstance():GetUserMgr():GetUserData().uid ~= msgObj.atker_uid then
    --     self.m_logic:FixBossHp(msgObj.left_hp, msgObj.harm)
    -- end

  --  print('--------- got ntf cmd ', msgObj.harm)

    FrameCmdFactory:GetInstance():ProductCommand(BattleEnum.FRAME_CMD_TYPE_GUILDBOSS_SYNC_HP, msgObj.harm, msgObj.left_hp, msgObj.is_self)

end

function GuildBossLogicComponent:ReqBossRTDeductHP(seq, harm)
    local msg_id = MsgIDDefine.GUILD_REQ_BOSS_RT_DEDUCT_HP
    local msg = (MsgIDMap[msg_id])()
    msg.seq = seq
    msg.harm = harm

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end


return GuildBossLogicComponent