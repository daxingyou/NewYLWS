local UserBrief = require("DataCenter.UserData.UserBrief")



local GuildWarMgr = BaseClass("GuildWarMgr")

local PBUtil = PBUtil
local CommonDefine = CommonDefine
local copyNumList = table.copyNumList
local Utils = Utils
local string_format = string.format
local table_insert = table.insert

function GuildWarMgr:__init()

    --rsp
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_GUILDWARCRAFT_PANNEL, Bind(self, self.RspPanelInfo))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_GUILD_START_OFFENCE, Bind(self, self.RspGuildStartOffence))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_START_ATK, Bind(self, self.RspStartAtk))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_WARCRAFT_USER_DETAIL, Bind(self, self.RspAchievement))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_CITY_INFO, Bind(self, self.RspCityInfo))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_SET_DEF_BUZHEN, Bind(self, self.RspSetDefBuZhen))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_DEF_BUZHEN_INFO, Bind(self, self.RspDefBuZhenList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_WARCRAFT_GUILD_DETAIL, Bind(self, self.RspGuildDetail))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_USER_DEF_BUZHEN_INFO, Bind(self, self.RspUserDefBuZhenInfo))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_SEND_DEF_BUZHEN_TO_CITY, Bind(self, self.RspSendDefBuZhenToCity))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_BUY_BUFF, Bind(self, self.RspBuyBuff))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_WARCRAFT_RANK_LIST, Bind(self, self.RspRankList))

    --ntf
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_ENTRY_DAY_STAT, Bind(self, self.NtfWarStatus))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_OFFENCE_CITY_RESULT, Bind(self, self.NtfOffenceCityResult))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_OFFENCE_CITY_BATTLE_END, Bind(self, self.NtfOffenceCityBattleEnd))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_GUILD_START_OFFENCE, Bind(self, self.NtfGuildStartOffence))

    --护送任务
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_HUSONG_PANNEL, Bind(self, self.RspHuSongPanel))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_ACCEPT_HUSONG_MISSION, Bind(self, self.RspAcceptHuSongMission))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_INVITE_MEMBER_LIST, Bind(self, self.RspInviteHuFaMembers))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_INVITE_HUFA, Bind(self, self.RspHuFuInvite))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_BE_INVITED_HUFA, Bind(self, self.NtfBeInvitedHuFu))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_ACCEPT_INVITE_HUFA, Bind(self, self.RspAcceptHuFaInvite))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_ACCEPT_INVITE_HUFA, Bind(self, self.NtfAcceptInviteHuFa))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_SEARCH_HUSONG_MISSION, Bind(self, self.RspSearchHuSongMissions))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_ROB_HUSONG_INFO, Bind(self, self.NtfRobHuSongInfo))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_PLAYER_HUSONG_COMPLETE, Bind(self, self.NtfPlayerHuSongComplete))   
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_RSP_TAKE_HUSONG_AWARD, Bind(self, self.RspTakeHuSongAward)) 
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILDWARCRAFT_NTF_PLAYER_CURR_HUSONG, Bind(self, self.NtfPlayerCurHuSong))   
    
    self.m_warBriefData = {
        currWarStatus = 0,
        today_atk_count = 0,
        atk_count_limit = 0,

        isBattleEnd = false, 
        battlle_start_time = 0,   --开启攻城的时间
        attackCityID = 0,         --攻击的城市ID
        war_season = 0,
        war_week = 0,
        roomID = 0, 

        warServerTime = 0,
        warFightInterval = 0,

        --护送
        today_rob_count = 0,
        today_rob_count_limit = 0,
    }

    self.m_myGuildUserBriefData = {
        jungong = 0,
        user_title = 0
    }

    self.m_cityDataList = {}
    --self.m_defBuzhenList = {}
    self.m_buzhen_num_limit = 0
    self.m_reqCityID = 0
    self.m_buffList = {}   --已购买的buff

    self.m_searchMissionInfo = false -- 拦截目标
    self.m_rob_stage = 0

    self.m_hasOpenFailView = true
    self.m_hasReceiveAward = true
    self.m_hufaList = {}

    self.m_currHuSongMissioon = false
end

function GuildWarMgr:Dispose()
    self.m_cityDataList = {}
end

--[[ GUILDWARCRAFT_NTF_GUILDWARCRAFT_BASE_INFO = 21320, 
	GUILDWARCRAFT_REQ_PLAYER_CURR_FIGHTING_INFO = 21327, 
	GUILDWARCRAFT_RSP_PLAYER_CURR_FIGHTING_INFO = 21328, 
  ]]


 --Proto Parse Data
function GuildWarMgr:ToCityBriefData(one_city_brief, data)
    if one_city_brief then
        data = data or {}
        data.city_id = one_city_brief.city_id	           
        data.own_guild_id = one_city_brief.own_guild_id
        data.atker_guild_id = one_city_brief.atker_guild_id
        data.own_guild_brief = self:ToGuildBriefData(one_city_brief.own_guild_brief, data.own_guild_brief)
        data.atker_guild_brief = self:ToGuildBriefData(one_city_brief.atker_guild_brief, data.atker_guild_brief)
        return data
    end
end

function GuildWarMgr:ToGuildBriefData(one_guild_brief, data)
    if one_guild_brief then
        data = data or {}
        data.gid = one_guild_brief.gid	--军团ID
        data.name = one_guild_brief.name
        data.icon = one_guild_brief.icon --旗帜
        data.level = one_guild_brief.level
        data.doyen_name = one_guild_brief.doyen_name --军团长姓名
        data.doyen = one_guild_brief.doyen  --军团长uid
        data.str_dist_id = one_guild_brief.str_dist_id  --服ID
        data.warcraftscore = one_guild_brief.warcraftscore  --分数
        return data
    end
end

function GuildWarMgr:ToGuildRivalData(one_rival_info, data)
    if one_rival_info then
        data = data or {}
        data.uid = one_rival_info.uid	
        data.user_name = one_rival_info.user_name
        data.level = one_rival_info.level
        data.dist_id = one_rival_info.dist_id
        data.guild_name = one_rival_info.guild_name 
        data.user_title = one_rival_info.user_title == 0 and 1 or one_rival_info.user_title-- 称号
        
        --todo one_wujiang_status
        return data
    end
end

function GuildWarMgr:ToGuildUserBriefData(one_user_info, data)
    if one_user_info then
        data = data or {}
        --玩家数据
        data.uid = one_user_info.uid
        data.use_icon_data = {}
        data.use_icon_data.icon = one_user_info.use_icon.icon
        data.use_icon_data.icon_box = one_user_info.use_icon.icon_box
        data.user_name = one_user_info.user_name 
        data.level = one_user_info.level
       
        --军团数据
        data.guild_name = one_user_info.guild_name
        data.user_title = one_user_info.user_title == 0 and 1 or one_user_info.user_title --称号
        data.post = one_user_info.post 
        data.post_name = one_user_info.post_name
        data.win_rate = one_user_info.win_rate
        data.jungong = one_user_info.jungong
        data.guild_icon = one_user_info.guild_icon

        data.str_dist_id = one_user_info.str_dist_id --区服
        data.dist_name = one_user_info.dist_name

        return data
    end
end

--玩家守城记录数据
function GuildWarMgr:ToUserDefendCityRecordData(one_def_fight)
    if one_def_fight then
        local data = {
            is_win = one_def_fight.is_win,
            battle_id = one_def_fight.battle_id,
            rival_brief = PBUtil.ConvertUserBriefProtoToData(one_def_fight.rival_brief)
        }
        return data
    end
end

--玩家攻城记录数据
function GuildWarMgr:ToUserOffenceCityRecordData(one_user_offence_city_record)
    if one_user_offence_city_record then
        local data = {
            city_id = one_user_offence_city_record.city_id,
            rival_guild_brief = self:ToGuildBriefData(one_user_offence_city_record.rival_guild_brief),
            break_info_list = PBUtil.ToParseList(one_user_offence_city_record.break_info_list, Bind(self, self.ToCityBreakInfo))
        }
        return data
    end
end

function GuildWarMgr:ToCityBreakInfo(one_break_info)
    if one_break_info then
        local data = {
            user_title = one_break_info.user_title, -- 击破对方的称号
            break_count = one_break_info.break_count -- 击破该称号玩家的次数
        }
        return data
    end
end

--军团战斗记录
function GuildWarMgr:ToCityBattleRecordData(one_guild_city_battle_record)
    if one_guild_city_battle_record then
        local data = {
            city_id = one_guild_city_battle_record.city_id,  
            is_offence = one_guild_city_battle_record.is_offence, --true 攻城
            is_win = one_guild_city_battle_record.is_win,
            time = one_guild_city_battle_record.time,
            rival_guild_brief = self:ToGuildBriefData(one_guild_city_battle_record.rival_guild_brief)
        }
        return data
    end
end

--排行数据
function GuildWarMgr:ToGuildRankData(one_guild_rank_info)
    if one_guild_rank_info then
        local data = {
            guild_brief = self:ToGuildBriefData(one_guild_rank_info.guild_brief),
            occ_city_num = one_guild_rank_info.occ_city_num,
            rank = one_guild_rank_info.rank,
        }
        return data
    end
end

--攻城结果
function GuildWarMgr:ToUserOffenceCityResultData(one_user_offence_result)
    if one_user_offence_result then
        local data = {
            break_info_list = PBUtil.ToParseList(one_user_offence_result.break_info_list, Bind(self, self.ToCityBreakInfo)),
            user_brief = PBUtil.ConvertUserBriefProtoToData(one_user_offence_result.user_brief),
            rank = one_user_offence_result.rank,
            award_jungong = one_user_offence_result.award_jungong
        }
        return data
    end
end

--req rsp ntf
function GuildWarMgr:ReqPanelInfo()
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_GUILDWARCRAFT_PANNEL
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspPanelInfo(msg_obj) 
    local result = msg_obj.result
    if result == 0 then
        self.m_warBriefData.currWarStatus = msg_obj.curr_stat
        self.m_warBriefData.today_atk_count = msg_obj.today_atk_count
        self.m_warBriefData.atk_count_limit = msg_obj.atk_count_limit
        self.m_warBriefData.isBattleEnd = msg_obj.is_battle_end         -- 战斗阶段 战斗是否打完了20分钟
        self.m_warBriefData.battle_start_time = msg_obj.battle_start_time
        self.m_warBriefData.attackCityID = msg_obj.offence_city_id
        self.m_warBriefData.war_week = msg_obj.war_week
        self.m_warBriefData.war_season = msg_obj.war_season
        self.m_warBriefData.warServerTime = msg_obj.curr_time
        self.m_warBriefData.warFightInterval = msg_obj.cfg_offence_duration_time

        self.m_warBriefData.today_rob_count = msg_obj.today_rob_count
        self.m_warBriefData.today_rob_count_limit = msg_obj.today_rob_count_limit

        if msg_obj.curr_searched_husong_misson.husong_id > 0 then
            self.m_warBriefData.curr_searched_husong_misson = self:ConvertOneHuSongMission(msg_obj.curr_searched_husong_misson)
        else 
            self.m_warBriefData.curr_searched_husong_misson = nil
        end
        

        self.m_myGuildUserBriefData.jungong = msg_obj.jungong
        self.m_myGuildUserBriefData.user_title = msg_obj.user_title == 0 and 1 or msg_obj.user_title
        self.m_buzhen_num_limit = msg_obj.buzhen_num_limit
 

        if msg_obj.battle_room_info and msg_obj.battle_room_info.city_list then
            self.m_warBriefData.roomID = msg_obj.battle_room_info.room_id
            self.m_cityDataList = PBUtil.ToParseList(msg_obj.battle_room_info.city_list, Bind(self, self.ToCityBriefData))
        end

        self.m_buffList = copyNumList(msg_obj.buff_list)
        self.m_currHuSongMission = self:ConvertOneHuSongMission(msg_obj.curr_husong_misson)

        if not UIManagerInst:IsWindowOpen(UIWindowNames.UIGuildWarMain) then
            UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarMain, true)
        else
            UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_PANEL_INFO)
        end 

        if self.m_warBriefData.curr_searched_husong_misson then
             UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_RSP_HUSONG_PANEL_CUR_SEARCH_MISSION,
            self.m_warBriefData.curr_searched_husong_misson)
        end 

	end
end

function GuildWarMgr:GetCurSearchedHuSongMission()
    return self.m_warBriefData.curr_searched_husong_misson
end

--开启攻城
function GuildWarMgr:ReqGuildStartOffence()
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_GUILD_START_OFFENCE
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspGuildStartOffence(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        self.m_warBriefData.battle_start_time = msg_obj.battle_start_time
        self.m_warBriefData.attackCityID = msg_obj.offence_city_id

        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_BASE_INFO)
	end
end

--出战
function GuildWarMgr:ReqStartAtk()
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_START_ATK
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspStartAtk(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        self.m_warBriefData.today_atk_count = msg_obj.today_atk_count
        self.m_warBriefData.atk_count_limit = msg_obj.atk_count_limit

        if self.m_warBriefData.attackCityID > 0 then
            UIManagerInst:OpenWindow(UIWindowNames.UILineupMain, BattleEnum.BattleType_GUILD_WARCRAFT, self.m_warBriefData.attackCityID)
        end
	end
end

--军功详情
function GuildWarMgr:ReqAchievement(uid)
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_WARCRAFT_USER_DETAIL
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspAchievement(msg_obj)
    local result = msg_obj.result
    if result == 0 then
      
        local achievementPanelData = {
            curr_break_count = msg_obj.curr_break_count, --本期攻城胜场
            guildUserBriefData = self:ToGuildUserBriefData(msg_obj.user_info),
        }

        local offence_record = msg_obj.offence_record
        if offence_record then
            --攻城战报
            achievementPanelData.offence_city_record_list = PBUtil.ToParseList(offence_record.offence_city_record_list, Bind(self, self.ToUserOffenceCityRecordData))
            --守城战报
            achievementPanelData.def_fight_list = PBUtil.ToParseList(offence_record.def_fight_list, Bind(self, self.ToUserDefendCityRecordData))
        end
        
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_ACHIEVEMENT_INFO, achievementPanelData)
	end
end

--请求城的详情数据
function GuildWarMgr:ReqCityInfo(cityID)
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_CITY_INFO
    local msg = (MsgIDMap[msg_id])()
    msg.city_id = cityID
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspCityInfo(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        --todo 是否更新 cityDataList
        local cityDetailData = {
            city_breif = self:ToCityBriefData(msg_obj.city_brief),
            def_user_list = PBUtil.ToParseList(msg_obj.def_user_list, Bind(self, self.ToGuildUserBriefData)),
            --buff_list = copyNumList(msg_obj.buff_list)
        }
       
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_CITY_INFO, cityDetailData)
	end
end

--保存多个阵容
function GuildWarMgr:ReqSetDefBuZhen()
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_SET_DEF_BUZHEN
    local msg = (MsgIDMap[msg_id])()
   
    local lineupMgr = Player:GetInstance():GetLineupMgr()
    local buzhenID = 10001
    for i = 1, 3 do 
        local one_buzhen = msg.buzhen_info_list:add()
        PBUtil.ConvertLineupDataToProto(buzhenID, one_buzhen, lineupMgr:GetLineupDataByID(buzhenID))
        buzhenID = buzhenID + 1 
    end
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspSetDefBuZhen(msg_obj)
    local result = msg_obj.result
    if result == 0 then
       
        local buzhen_info_list = msg_obj.buzhen_info_list
        if buzhen_info_list then
            local LineupMgr = Player:GetInstance():GetLineupMgr()
            for _, one_buzhen in Utils.IterPbRepeated(buzhen_info_list) do
                if one_buzhen then
                    LineupMgr:RefreshOneLineup(one_buzhen)
                end
            end 
        end

        self.m_buzhen_num_limit = msg_obj.buzhen_num_limit

        UILogicUtil.FloatAlert(Language.GetString(2338))
	end
end

--驻守
function GuildWarMgr:ReqSendDefBuZhenToCity(cityID, buzhenID)
    buzhenID = buzhenID or 10001
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_SEND_DEF_BUZHEN_TO_CITY
    local msg = (MsgIDMap[msg_id])()
    msg.city_id = cityID
    self.m_reqCityID = cityID
    PBUtil.ConvertLineupDataToProto(buzhenID, msg.buzhen_info, Player:GetInstance():GetLineupMgr():GetLineupDataByID(buzhenID))
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspSendDefBuZhenToCity(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        self:ReqCityInfo(self.m_reqCityID)
        UILogicUtil.FloatAlert(Language.GetString(2339))
	end
end

--请求防守阵容(自己的)
function GuildWarMgr:ReqDefBuZhenList()
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_DEF_BUZHEN_INFO
	local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspDefBuZhenList(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        local def_buzhen_list = msg_obj.def_buzhen_list
        if def_buzhen_list then
            Player:GetInstance():GetLineupMgr():AddLineupListFromPB(def_buzhen_list)
            self.m_buzhen_num_limit = msg_obj.buzhen_num_limit
           
            UIManagerInst:Broadcast(UIMessageNames.MN_LINEUP_APPLY_NEW) --更新阵容
        end
    end
end

--查看防守阵容列表
function GuildWarMgr:ReqUserDefBuZhenInfo(uid, city_id)
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_USER_DEF_BUZHEN_INFO
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.city_id = city_id or 0
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspUserDefBuZhenInfo(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        local all_buzhen_wujiang_brief_list = msg_obj.all_buzhen_wujiang_brief_list
        if all_buzhen_wujiang_brief_list then
            local all_buzhen_list = {}

            for _, one_buzhen_wujiang_brief_list in ipairs(all_buzhen_wujiang_brief_list) do
                local wujiang_list = {} 
                for _, one_wujiang_brief in ipairs(one_buzhen_wujiang_brief_list.wujiang_list) do
                    if one_wujiang_brief.id > 0 then
                        local wujiangBrief = PBUtil.ConvertWujiangBriefProtoToData(one_wujiang_brief)
                        table_insert(wujiang_list, wujiangBrief)
                    end
                end

                local buzhenData = {
                    buzhen_id = one_buzhen_wujiang_brief_list.buzhen_id,
                    wujiang_list = wujiang_list
                }

                table_insert(all_buzhen_list, buzhenData)
            end

            UIManagerInst:OpenWindow( UIWindowNames.UIMutiLinpup, all_buzhen_list)
        end
    end
end


--请求军团详情
function GuildWarMgr:ReqGuildDetail(guild_id)
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_WARCRAFT_GUILD_DETAIL
    local msg = (MsgIDMap[msg_id])()
    msg.guild_id = guild_id
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspGuildDetail(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        local guildDetailData = {
            out_put_coin_num = msg_obj.out_put_coin_num,  --产出金币
            rank = msg_obj.rank,
            occ_city_list = copyNumList(msg_obj.occ_city_list),
            guild_brief = self:ToGuildBriefData(msg_obj.guild_brief),
            user_info_list = PBUtil.ToParseList(msg_obj.user_info_list, Bind(self, self.ToGuildUserBriefData)),
            city_battle_record_list = PBUtil.ToParseList(msg_obj.city_battle_record, Bind(self, self.ToCityBattleRecordData))
        }
       
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_GUILD_DETAIL, guildDetailData)
    end
end

--军需商店 购买
function GuildWarMgr:ReqBuyBuff(buff_id)
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_BUY_BUFF
    local msg = (MsgIDMap[msg_id])()
    msg.buff_id = buff_id
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspBuyBuff(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        if msg_obj.buff_list then
            self.m_buffList = copyNumList(msg_obj.buff_list)
            UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_BUY_BUFF)
        end
    end
end

--排行
function GuildWarMgr:ReqRankList()
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_WARCRAFT_RANK_LIST
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspRankList(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        local panelData = {
            curr_week_end_time = msg_obj.curr_week_end_time or 0,
            next_week_start_time = msg_obj.next_week_start_time or 0,
            curr_match_rank_list = PBUtil.ToParseList(msg_obj.curr_room_rank_list, Bind(self, self.ToGuildRankData)),
            self_server_rank_list = PBUtil.ToParseList(msg_obj.self_server_rank_list, Bind(self, self.ToGuildRankData)),
            all_server_rank_list = PBUtil.ToParseList(msg_obj.all_server_rank_list, Bind(self, self.ToGuildRankData)),
        }
        
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarRank, panelData)
    end
end

function GuildWarMgr:NtfWarStatus(ntf_entry_day_stat)
    if ntf_entry_day_stat.new_stat ~= self.m_warBriefData.currWarStatus then
        self.m_warBriefData.currWarStatus = ntf_entry_day_stat.new_stat
        
        local target = UIManagerInst:GetWindow(UIWindowNames.UIGuildWarMain, true, true)
        if target then
            self:ReqPanelInfo()
        end
	end
end

function GuildWarMgr:NtfOffenceCityResult(ntf_offence_city_result)
    local panelData = {
        offence_result = ntf_offence_city_result.offence_result,   -- 0 失败  1 成功
        user_offence_result_list = PBUtil.ToParseList(ntf_offence_city_result.user_offence_result_list, Bind(self, self.ToUserOffenceCityResultData))
    }

    --这个ntf在请求面板数据后才会发，只发一次
    UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarOffenceCityResult, panelData)
end


function GuildWarMgr:NtfOffenceCityBattleEnd(ntf_offence_city_battle_end)
    --攻城战斗结束 通知面板重新请求数据
    --当前房间 所有攻城结束信息
    
    if self.m_warBriefData.roomID == ntf_offence_city_battle_end.room_id then
        if self.m_warBriefData.attackCityID == ntf_offence_city_battle_end.city_id then
            UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_OFFENCE_CITY_BATTLE_END) 
        end
    end

    local newsData = {
        atk_guild_id = ntf_offence_city_battle_end.atk_guild_id,
        def_guild_id = ntf_offence_city_battle_end.def_guild_id,
        winner_guild_id = ntf_offence_city_battle_end.winner_guild_id,
        atk_guild_brief = self:ToGuildBriefData(ntf_offence_city_battle_end.atk_guild_brief),
        def_guild_brief = self:ToGuildBriefData(ntf_offence_city_battle_end.def_guild_brief),
    }
   
    UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_OFFENCE_CITY_BATTLE_NEWS, newsData) 
end

function GuildWarMgr:NtfGuildStartOffence(ntf_guild_start_offence)
    --通知其他玩家 可以出战
    UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_BASE_INFO)
end 

----------------start 护送任务--------------------
function GuildWarMgr:ReqHuSongPanel()         
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_HUSONG_PANNEL
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspHuSongPanel(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        local tempHSMissionList = {}  
        for i = 1, #msg_obj.husong_misson_list do  
            local temp = self:ConvertOneHuSongMission(msg_obj.husong_misson_list[i]) 
            table.insert(tempHSMissionList, temp)
        end 
        local initMissionData1 = {
            husong_id = 1,
            status = 0,   
            left_time = 0,
            hufa_uid = 0,
            hufa_brief = nil,
        }
        local initMissionData2 = {
            husong_id = 2,
            status = 0,   
            left_time = 0,
            hufa_uid = 0,
            hufa_brief = nil,
        }
        local initMissionData3 = {
            husong_id = 3,
            status = 0,   
            left_time = 0,
            hufa_uid = 0,
            hufa_brief = nil,
        }
        
        if not tempHSMissionList[1] then
            tempHSMissionList[1] = initMissionData1
        end
        if not tempHSMissionList[2] then 
            tempHSMissionList[2] = initMissionData2
        end
        if not tempHSMissionList[3] then 
            tempHSMissionList[3] = initMissionData3
        end

        local tempCurMission = self:ConvertOneHuSongMission(msg_obj.curr_husong_misson)

        local husongPanel = {
            husong_mission_list = tempHSMissionList,
            curr_husong_mission = tempCurMission,
            today_husong_count = msg_obj.today_husong_count or 0,
            today_husong_count_limit = msg_obj.today_husong_count_limit or 0,
            today_rob_count = msg_obj.today_rob_count or 0,
            today_accept_hufa_count = msg_obj.today_accept_hufa_count or 0,
            today_accept_hufa_count_limit = msg_obj.today_accept_hufa_count_limit or 0,
            today_rob_count_limit = msg_obj.today_rob_count_limit or 0,

            guild_husong_progress = msg_obj.guild_husong_progress or 0,
            guild_husong_progress_max = msg_obj.guild_husong_progress_max or 0,
        }  
        self.m_husongPanel= husongPanel
        self.m_currHuSongMission = tempCurMission

        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_RSP_HUSONG_PANEL, husongPanel) 
	end
end

function GuildWarMgr:GetHuSongPanel()
    return self.m_husongPanel
end

function GuildWarMgr:ConvertOneHuSongMission(one_husong_mission)
    if one_husong_mission then
        local tempOneHuSongMission = {
            husong_id = one_husong_mission.husong_id or 0,
            status = one_husong_mission.status or 0,  
            left_time = one_husong_mission.left_time or 0,
            hufa_uid = one_husong_mission.hufa_uid or 0,
            hufa_brief = PBUtil.ConvertUserBriefProtoToData(one_husong_mission.hufa_brief),
            owner_brief = PBUtil.ConvertUserBriefProtoToData(one_husong_mission.owner_brief),
            be_rob_count = one_husong_mission.be_rob_count or 0,
        }

        return tempOneHuSongMission
    end
end 

function GuildWarMgr:ReqAcceptHuSongMission(husong_id)   --接受任务
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_ACCEPT_HUSONG_MISSION
    local msg = (MsgIDMap[msg_id])() 
    msg.husong_id = husong_id 

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspAcceptHuSongMission(msg_obj)
    local result = msg_obj.result 
    if result == 0 then
        self:ReqHuSongPanel()

        self.m_currHuSongMission = self:ConvertOneHuSongMission(msg_obj.misson_info)

        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_HUSONG_MISSION_ACCEPT) 
	end
end

function GuildWarMgr:ReqInviteHuFaMembers()     --请求护法列表
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_INVITE_MEMBER_LIST
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspInviteHuFaMembers(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        local tempUserBriefList = {}
        
        for i = 1, #msg_obj.user_brief_list do
            local oneUser = PBUtil.ConvertUserBriefProtoToData(msg_obj.user_brief_list[i])
            oneUser.user_title = msg_obj.user_title
            table.insert(tempUserBriefList, oneUser)
        end
        
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarInviteCustodian, tempUserBriefList)
	end
end

function GuildWarMgr:AddToHuFaIDList(uid)
    uid = math.ceil(uid)
    if not self.m_hufaIdList then
        self.m_hufaIdList = {}
    end
    local hasID = false
    for i = 1, #self.m_hufaIdList do
        if self.m_hufaIdList[i] == uid then
            hasID = true
        end
    end
    if hasID then
        return
    end
    table.insert(self.m_hufaIdList, uid)
end

function GuildWarMgr:DeleteFromHuFaIDList(uid)
    for i = 1, #self.m_hufaIdList do
        if self.m_hufaIdList[i] == uid then
            table.remove(self.m_hufaIdList, i)
            return true
        end
    end
    return false
end

function GuildWarMgr:GetHuFaIDList()
    return self.m_hufaIdList or {}
end

function GuildWarMgr:ClearHuFaIDList()
    self.m_hufaIdList = {}
end 

function GuildWarMgr:ReqHuFaInvite(uid_list)       --玩家（我）发出主动邀请护法的请求
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_INVITE_HUFA
    local msg = (MsgIDMap[msg_id])()
    for k, v in ipairs(uid_list) do
        if v then
            msg.uid_list:append(v)
        end
    end 

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end 

function GuildWarMgr:RspHuFuInvite(msg_obj)    --主动邀请护法的回应（返回的是已邀请成功的idlist）
    local result = msg_obj.result
    if result == 0 then
        UIManagerInst:CloseWindow(UIWindowNames.UIGuildWarInviteCustodian)
        UILogicUtil.FloatAlert(Language.GetString(2292))
	end
end

function GuildWarMgr:NtfAcceptInviteHuFa(ntf_accept_invite_hufa)   --有玩家接受了我的护法邀请
    local missionInfo = self:ConvertOneHuSongMission(ntf_accept_invite_hufa.misson_info)
    if missionInfo then
        if missionInfo.hufa_brief then
            UILogicUtil.FloatAlert(string_format(Language.GetString(2290), missionInfo.hufa_brief.name))
        end

        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_HUSONG_INVITE) 
    end
end

function GuildWarMgr:NtfBeInvitedHuFu(msg_obj)  --服务器广播的被邀请通知  
    local curHuFaInfo = PBUtil.ConvertUserBriefProtoToData(msg_obj.from_user_brief) 
    table.insert(self.m_hufaList, curHuFaInfo)
    
    UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_HUFA_INVITE)  
end 

function GuildWarMgr:RemoveHuFaInvitation()
    if #self.m_hufaList <= 0 then
        return
    end

    table.remove(self.m_hufaList, 1)

    if #self.m_hufaList <= 0 then
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_HUFA_INVITE)
    end
end

function GuildWarMgr:GetHuFaInvitation()
    return self.m_hufaList
end 

function GuildWarMgr:ReqAcceptHuFaInvite(uid)      
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_ACCEPT_INVITE_HUFA
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid                    
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspAcceptHuFaInvite(msg_obj)  
    local result = msg_obj.result
    if result == 0 then
        local myHuSongMissionInfo = self:ConvertOneHuSongMission(msg_obj.misson_info)
	end
end

function GuildWarMgr:ReqSearchHuSongMissions()         --搜索护送任务列表的请求
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_SEARCH_HUSONG_MISSION
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspSearchHuSongMissions(msg_obj)    
    local result = msg_obj.result
    if result == 0 then
        local searchMissionInfo = self:ConvertOneHuSongMission(msg_obj.misson_info)
        self.m_searchMissionInfo = searchMissionInfo
        --self.m_rob_stage = 1 --默认设置（阶段 1 : 开始阶段， 2：表示已经打败护法现在去打护送者了）
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_HUSONG_INFO)
	end
end 
 
function GuildWarMgr:NtfRobHuSongInfo(msg_obj) 
    local mission_info = self:ConvertOneHuSongMission(msg_obj.misson_info) 
    local roberBrief = PBUtil.ConvertUserBriefProtoToData(msg_obj.rober_brief)
    local robResult = msg_obj.rob_result 
    local isGuildWarMainViewOpen = UIManagerInst:CheckWindowIsOpen(UIWindowNames.UIGuildWarMain)  
    if robResult == 1 then 
        --被拦截成功（任务失败）
        if isGuildWarMainViewOpen then 
            UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarEscortFail, roberBrief) 
        else
            self:SetHuSongFailView(false)
            self.m_missionFailRoberBrief = roberBrief
            UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_MISSION_FAIL)
        end
    end
end 

function GuildWarMgr:SetHuSongFailView(isFailed)
    self.m_hasOpenFailView = isFailed
end

function GuildWarMgr:GetHuSongMissionFail()
    return self.m_hasOpenFailView, self.m_missionFailRoberBrief
end

function GuildWarMgr:NtfPlayerHuSongComplete(msg_obj)    -- 护送任务成功时下发通知
   --[[  local tempHuSongCompleteInfo = {
        uid = msg_obj.uid or 0,
        guild_id = msg_obj.guild_id or 0,
        husong_id = msg_obj.husong_id or 0, 
        guild_husong_progress = msg_obj.guild_husong_progress or 0,
        guild_husong_progress_max = msg_obj.guild_husong_progress_max or 0,
    }  ]]
    
    if UIManagerInst:IsWindowOpen(UIWindowNames.UIGuildWarMain) then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarEscortTask) 
    end
   
    self:SetHasReceiveAward(false)
    UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_MISSION_SUC)
end

function GuildWarMgr:SetHasReceiveAward(hasReceived)
    self.m_hasReceiveAward = hasReceived
end

function GuildWarMgr:GetHasReceiveAward()
    return self.m_hasReceiveAward
end  

function GuildWarMgr:ReqTakeHuSongAward(husong_id)         
    local msg_id = MsgIDDefine.GUILDWARCRAFT_REQ_TAKE_HUSONG_AWARD
    local msg = (MsgIDMap[msg_id])()
    msg.husong_id = husong_id

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildWarMgr:RspTakeHuSongAward(msg_obj)
    local result = msg_obj.result
    if result == 0  then
        self:SetHasReceiveAward(true)
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_MISSION_SUC)

        local husongMission = self:ConvertOneHuSongMission(msg_obj.husong_misson_info)
        local husongID = husongMission.husong_id
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_RSP_TAKE_HUSONG_AWARD, husongID) 

        local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
        local uiData = {
            openType = 1,
            awardDataList = awardList
        }
        UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)

        self:ReqHuSongPanel()
    end
end

function GuildWarMgr:NtfPlayerCurHuSong(msg_obj) 
    local curHuSongMission = self:ConvertOneHuSongMission(msg_obj.curr_husong_misson) 
    if math.ceil(curHuSongMission.status) == 2 then
        self:SetHasReceiveAward(false)
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILDWAR_MISSION_SUC)
    end  
end 
----------------end 护送任务-----------------------


--get data
function GuildWarMgr:GetWarBriefData()
    return self.m_warBriefData
end

function GuildWarMgr:GetMyGuildUserBriefData()
    return self.m_myGuildUserBriefData
end

function GuildWarMgr:GetCityDataList()
    return self.m_cityDataList
end

function GuildWarMgr:BattleIsStart()
    return self.m_warBriefData.battle_start_time > 0 
end

function GuildWarMgr:BattleIsEnd()
    return self.m_warBriefData.isBattleEnd
end

function GuildWarMgr:CheckActCount()
    return self.m_warBriefData.today_atk_count < self.m_warBriefData.atk_count_limit
end

function GuildWarMgr:GetWarStatus()
    return self.m_warBriefData.currWarStatus
end

function GuildWarMgr:IsOwnCity(city_breif)
    if not city_breif then
        Logger.LogError("IsOwnCity city_breif nil")
        return false
    end

    return Player:GetInstance():GetUserMgr():GetUserData().guild_id == city_breif.own_guild_id
end

function GuildWarMgr:GetBuzhenLimit()
    return self.m_buzhen_num_limit
end

function GuildWarMgr:BuffCanBuy(buffID)
    local myGuildData = Player:GetInstance().GuildMgr.MyGuildData
    if myGuildData then
        if myGuildData.self_post ~= CommonDefine.GUILD_POST_COLONEL and myGuildData.self_post ~= CommonDefine.GUILD_POST_DEPUTY then
            return false
        end
    end

    if self.m_buffList then
        for i, v in ipairs(self.m_buffList) do 
            if v == buffID then
                return false
            end
        end
    end

    return true
end


function GuildWarMgr:GetHuSongInfo()
    return self.m_searchMissionInfo
end

function GuildWarMgr:GetRobInfo()
    if self.m_searchMissionInfo then
        local owner_brief = self.m_searchMissionInfo.owner_brief
        if owner_brief then
            return owner_brief.uid, self.m_rob_stage
        end
    end

    return 0, 0
end

--进入下个阶段
function GuildWarMgr:SetRobStage(rob_stage)
    self.m_rob_stage = rob_stage
end

function GuildWarMgr:GetBuffList()
    return self.m_buffList
end

function GuildWarMgr:GetCurHuSongMission()
    return self.m_currHuSongMission
end

function GuildWarMgr:GetWarServerTime()
    return self.m_warBriefData.warServerTime
end

function GuildWarMgr:SetWarServerTime(v)
    self.m_warBriefData.warServerTime = v
end

function GuildWarMgr:GetWarFightInterval()
    return self.m_warBriefData.warFightInterval
end

function GuildWarMgr:CheckHuSongCount()
    return self.m_warBriefData.today_rob_count < self.m_warBriefData.today_rob_count_limit
end

function GuildWarMgr:GetHuSongCount()
    return self.m_warBriefData.today_rob_count_limit - self.m_warBriefData.today_rob_count
end

return GuildWarMgr