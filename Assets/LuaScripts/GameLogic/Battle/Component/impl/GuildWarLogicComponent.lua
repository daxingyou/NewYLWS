local BaseBattleLogicComponent = require "GameLogic.Battle.Component.BaseBattleLogicComponent"
local GuildWarLogicComponent = BaseClass("GuildWarLogicComponent", BaseBattleLogicComponent)

function GuildWarLogicComponent:__init(logic)
    self.m_logic = logic

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_FINISH_FIGHT, Bind(self, self.RspBattleFinish))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_CITY_FIGHTING_NEWS, Bind(self, self.HandleCityFightNews))
end

function GuildWarLogicComponent:__delete()

    HallConnector:GetInstance():ClearHandler(MsgIDDefine.GUILDWARCRAFT_RSP_FINISH_FIGHT)
    HallConnector:GetInstance():ClearHandler(MsgIDDefine.GUILDWARCRAFT_NTF_CITY_FIGHTING_NEWS)
end

function GuildWarLogicComponent:ShowBattleUI()

   
    UIManagerInst:OpenWindow(UIWindowNames.UIBattleGuildWarMain)
    BaseBattleLogicComponent.ShowBloodUI(self)
end

function GuildWarLogicComponent:HandleCityFightNews(ntf_city_fighting_news)
    local rivalinfo = self.m_logic:GetRivalInfo()
    if rivalinfo.rivalUserBriefData and rivalinfo.rivalUserBriefData.uid == ntf_city_fighting_news.def_uid then
        if ntf_city_fighting_news.winner_uid == ntf_city_fighting_news.offence_uid then
            --对手被击败
            self.m_logic:SetRivalDead()
        end

        --更新剩余人数
        rivalinfo.rival_guild_left_member_num = ntf_city_fighting_news.def_guild_left_member_num
    end
        
    UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_GUILDWAR_FIGHT_NEWS, ntf_city_fighting_news)
end

function GuildWarLogicComponent:ReqBattleFinish(copyID)
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_FINISH_FIGHT
    local msg = (MsgIDMap[msg_id])()

    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
    self:GenerateResultInfoProto(msg.battle_result)

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end
    
function GuildWarLogicComponent:RspBattleFinish(msg_obj)
	local result = msg_obj.result
	if result ~= 0 then
		Logger.LogError('GuildWarLogicComponent failed: '.. result)
		return
    end

    local isEqual = self:CompareBattleResult(msg_obj.battle_result)
    if not isEqual then
        Logger.LogError("Do not sync, report frame data to server")
        self:ReqReportFrameData()
    end

    UIManagerInst:CloseWindow(UIWindowNames.UIBattleGuildWarMain)
    UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarSettlement, msg_obj)
end


return GuildWarLogicComponent