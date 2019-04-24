local PBUtil = PBUtil
local table_sort = table.sort
local table_insert = table.insert
local table_remove = table.remove
local ConfigUtil = ConfigUtil
local CommonDefine = CommonDefine
local math_ceil = math.ceil
local string_format = string.format
local LieZhuanCountryDataClass = require "DataCenter.LieZhuanData.LieZhuanCountryData"
local LieZhuanTeamBaseDataClass = require "DataCenter.LieZhuanData.LieZhuanTeamBaseData"
local LieZhuanMgr = BaseClass("LieZhuanMgr")

local TeamStateEnum = {
    NotInTeam = 1,
    Solo = 2,
    Team = 3,
    BuZhen = 4,
    PrepareFight = 5,
    Fighting = 6,
    FightingEnd = 7,
}

local TeamMemberAction = {
    Add = 1,
    Leave = 2,
    LostConnection = 3,
    Reconnection = 4,
    NotEnoughStamina = 5,
    KickOut = 6,
    Overtime = 7,
    DataAbort = 8,
}

function LieZhuanMgr:__init()
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_LIZHUAN_PANNEL, Bind(self, self.RspLiezhuanPannel))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_REFRESH_TEAM_LIST, Bind(self, self.RspLiezhuanTeamList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_CREATE_TEAM, Bind(self, self.RspLiezhuanCreateTeam))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_JOIN_TEAM, Bind(self, self.RspLiezhuanJoinTeam))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_EXIT_TEAM, Bind(self, self.RspLiezhuanExitTeam))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_INVITE_PANNEL_INFO, Bind(self, self.RspLiezhuanInvitePannel))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_INVITE_TO_TEAM, Bind(self, self.RspLiezhuanInviteTeam))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_START_BUZHEN, Bind(self, self.RspLiezhuanStartBuZhen))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_SELECT_WUJIANG_TO_BUZHEN, Bind(self, self.RspLieZhuanSelectWuJiang))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_EXCHANGE_BUZHEN_POS, Bind(self, self.RspLieZhuanExchangetWuJiang))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_READY_TO_FIGHT, Bind(self, self.RspLieZhuanReadyFight))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_SET_AUTO_FIGHT, Bind(self, self.RspLieZhuanSetAutoFight))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_WATCH_BATTLE_FINISH, Bind(self, self.RspLieZhuanWatchBattleFinish))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_SET_AUTO_INVITE, Bind(self, self.RspLieZhuanSetAutoInvite))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_RSP_KICK_MEMBER, Bind(self, self.RspLieZhuanKickOutMember))

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_NTF_PLAYER_IN_TEAM, Bind(self, self.NtfTeamInPlayerChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_NTF_TEAM_STAT_TIMEKEEPING, Bind(self, self.NtfTeamStatTimeChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_NTF_TEAM_DISSMISS, Bind(self, self.NtfTeamDissmiss))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_NTF_PLAYER_INVITE_TO_TEAM, Bind(self, self.NtfInvitePlayerChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_NTF_TEAM_BUZHEN_INFO, Bind(self, self.NtfTeamBuZhenInfoChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_NTF_PLAYER_READY_TO_FIGHT, Bind(self, self.NtfReadyToFight))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LIEZHUAN_NTF_TEAM_FIGHT, Bind(self, self.NtfStartFight))
    
    self.m_selectCountry = 0
    self.m_lieZhuanAllCopyCfgList = nil

    self.m_countryPassInfoList = {}
    self.m_cfg_single_fight_need_tili = 0
    self.m_cfg_team_fight_need_tili = 0

    self.m_teamInfo = nil
    self.m_inviteList = {}
    self.m_cacheTeamInfo = nil
    self.m_cacheBuZhenList = nil
    self.m_userMgr = Player:GetInstance():GetUserMgr()

    self.m_inviteCacheList = {}
    self.m_haveInviteCache = false

    self.m_uiData = { copyId = 0, isAutoFight = false, curAutoFightTimes = 0, countryId = 0, isReadyFight = false }
end

function LieZhuanMgr:ConvertToPassCountryData(country_info)
    if country_info then
        local data = LieZhuanCountryDataClass.New()
        data.country = country_info.country
        data.max_pass_copy = country_info.max_pass_copy
        data.curr_team_count = country_info.curr_team_count
        return data
    end
end

function LieZhuanMgr:ConvertToTeamData(team_info)
    if team_info then
        local teamData = {}
        teamData.team_base_info = self:ConvertToTeamBaseData(team_info.team_base_info)
        teamData.curr_stat = team_info.curr_stat
        teamData.left_time = team_info.left_time
        teamData.captain_auto_invite = team_info.captain_auto_invite
        teamData.member_list = {}
        if team_info.member_list then
            for _,v in ipairs(team_info.member_list) do
                local memberInfo = self:ConvertToTeamMemberData(v)
                if memberInfo then
                    table_insert(teamData.member_list, memberInfo)
                end
            end
        end
        return teamData
    end
end

function LieZhuanMgr:ConvertToTeamBaseData(team_base_info)
    if team_base_info then
        local data = LieZhuanTeamBaseDataClass.New()
        data.team_id = team_base_info.team_id or 0
        data.country = team_base_info.country or 0
        data.copy_id = team_base_info.copy_id or 0
        data.captain_uid = team_base_info.captain_uid or 0
        data.permition = team_base_info.permition or 0
        data.min_level = team_base_info.min_level or 0
        data.max_level = team_base_info.max_level or 0
        return data
    end
end

function LieZhuanMgr:ConvertToTeamMemberData(one_member_info)
    if one_member_info then
        local data = {}
        data.index = one_member_info.index
        data.is_auto_fight = one_member_info.is_auto_fight
        data.is_buzhen_ready = one_member_info.is_buzhen_ready
        data.user_brief = PBUtil.ConvertUserBriefProtoToData(one_member_info.user_brief)
        return data
    end
end

function LieZhuanMgr:ConvertToTeamBuZhenData(one_wujiang_in_buzhen_info)
    if one_wujiang_in_buzhen_info then
        local data = {}
        data.pos = one_wujiang_in_buzhen_info.pos
        data.uid = one_wujiang_in_buzhen_info.uid
        data.wujiang_brief = PBUtil.ConvertWujiangBriefProtoToData(one_wujiang_in_buzhen_info.wujiang_brief)
        return data
    end
end

function LieZhuanMgr:SetSelectCountry(countryId)
    self.m_selectCountry = countryId
end

function LieZhuanMgr:GetSelectCountry()
    return self.m_selectCountry
end

function LieZhuanMgr:GetCountryInfoById(countryId)
    return self.m_countryPassInfoList[countryId]
end

function LieZhuanMgr:GetSingleFightNeedTili()
    if self.m_cfg_single_fight_need_tili then
        return self.m_cfg_single_fight_need_tili
    end
end

function LieZhuanMgr:GetTeamFightNeedTili()
    if self.m_cfg_team_fight_need_tili then
        return self.m_cfg_team_fight_need_tili
    end
end

function LieZhuanMgr:GetAutoNeedTaoFaLing()
    return 1
end

function LieZhuanMgr:GetAllCopyCfgList()
    if self.m_lieZhuanAllCopyCfgList then
        return self.m_lieZhuanAllCopyCfgList
    else
        self.m_lieZhuanAllCopyCfgList = ConfigUtil.GetLieZhuanAllCopyCfg()
        if self.m_lieZhuanAllCopyCfgList then
            return self.m_lieZhuanAllCopyCfgList
        end
    end
end

function LieZhuanMgr:GetCountryCopyCount(countryId)
    local copyList = self:GetAllCopyCfgList()
    if copyList then
        local copyCfgList = {}
        for k,v in pairs(self.m_lieZhuanAllCopyCfgList) do
            if v.country == countryId then
                table_insert(copyCfgList, v)
            end
        end

        table_sort(copyCfgList, function(ltb, rtb)
            return ltb.id < rtb.id
        end
        )

        return copyCfgList
    end
end

function LieZhuanMgr:GetMaxCopyIdByCountry(countryId)
    local copyList = self:GetCountryCopyCount(countryId)
    local maxCopyId = 0
    if copyList then
        for _,v in ipairs(copyList) do
            if v.id > maxCopyId then
                maxCopyId = v.id
            end
        end
    end
    return maxCopyId
end

function LieZhuanMgr:GetLeftTime()
    if self.m_teamInfo then
        return self.m_teamInfo.left_time
    end
end

function LieZhuanMgr:GetTeamInfo()
    return self.m_teamInfo
end

function LieZhuanMgr:GetTeamCaptainUid()
    if self.m_teamInfo then
        return self.m_teamInfo.team_base_info.captain_uid
    end
    return 0
end

function LieZhuanMgr:GetSelfAutoNextFight()
    if self.m_teamInfo and self.m_teamInfo.member_list then
        for _,v in ipairs(self.m_teamInfo.member_list) do
            if self.m_userMgr:CheckIsSelf(v.user_brief.uid) then
                return v.is_auto_fight
            end
        end
    end
    return false
end

function LieZhuanMgr:GetSysIdByCountry(countryId)
    if countryId == CommonDefine.COUNTRY_1 then
        return SysIDs.LIEZHUAN_WEI
    elseif countryId == CommonDefine.COUNTRY_2 then
        return SysIDs.LIEZHUAN_SHU
    elseif countryId == CommonDefine.COUNTRY_3 then
        return SysIDs.LIEZHUAN_WU
    elseif countryId == CommonDefine.COUNTRY_4 then
        return SysIDs.LIEZHUAN_QUN
    end
end

function LieZhuanMgr:GetUIData()
    return self.m_uiData
end

function LieZhuanMgr:GetUserNameDistFromTeamByUid(uid)
    if self.m_teamInfo and self.m_teamInfo.member_list then
        for _,v in ipairs(self.m_teamInfo.member_list) do
            if v.user_brief and v.user_brief.uid == uid then
                return v.user_brief.name, v.user_brief.str_dist_id
            end
        end
    end
end

function LieZhuanMgr:CheckCacheTeam()
    if self.m_cacheBuZhenList then
        UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanLineup,BattleEnum.BattleType_LIEZHUAN_TEAM, self.m_cacheBuZhenList)
        self.m_cacheBuZhenList = nil
    elseif self.m_cacheTeamInfo then
        UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanFightTroop, self.m_cacheTeamInfo)
        self.m_cacheTeamInfo = nil
    end
end

function LieZhuanMgr:IsLockedCopy(countryId, copyId)
    if copyId == 0 then
        return false
    end
    if self.m_countryPassInfoList[countryId] then
        return self.m_countryPassInfoList[countryId].max_pass_copy < copyId
    end
    return true
end

function LieZhuanMgr:ReqLiezhuanPannel()
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_LIZHUAN_PANNEL
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLiezhuanPannel(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    if msg_obj.country_info_list then
        for k,v in ipairs(msg_obj.country_info_list) do
            if v.country then
                self.m_countryPassInfoList[v.country] = self:ConvertToPassCountryData(v)
            end
        end
    end

    self.m_cfg_single_fight_need_tili = msg_obj.cfg_single_fight_need_tili
    self.m_cfg_team_fight_need_tili = msg_obj.cfg_team_fight_need_tili

    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_COUNTRY_INFO)
end

function LieZhuanMgr:ReqLiezhuanTeamList(country, copy_id)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_REFRESH_TEAM_LIST
    local msg = (MsgIDMap[msg_id])()
    msg.country = country
    msg.copy_id = copy_id

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLiezhuanTeamList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local teamDataList = {}
    if msg_obj.team_info_list then
        for _,v in ipairs(msg_obj.team_info_list) do
            local data = self:ConvertToTeamData(v)
            if data then
                table_insert(teamDataList, data)
            end
        end
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_UPDATE_TEAM, teamDataList)
end

function LieZhuanMgr:ReqLiezhuanCreateTeam(team_base_info)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_CREATE_TEAM
    local msg = (MsgIDMap[msg_id])()
    local teamData = msg.team_base_info
    teamData.team_id = team_base_info.team_id
    teamData.country = team_base_info.country
    teamData.copy_id = team_base_info.copy_id
    teamData.captain_uid = team_base_info.captain_uid
    teamData.permition = team_base_info.permition
    teamData.min_level = team_base_info.min_level
    teamData.max_level = team_base_info.max_level

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLiezhuanCreateTeam(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    if msg_obj.team_info then
        local teamInfo = self:ConvertToTeamData(msg_obj.team_info)
        if teamInfo then
            self.m_teamInfo = teamInfo
            UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanFightTroop,teamInfo)
        end
    end
end

function LieZhuanMgr:ReqLiezhuanJoinTeam(team_id, inviter_uid, is_refuse, copy_id)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_JOIN_TEAM
    local msg = (MsgIDMap[msg_id])()
    msg.team_id = team_id
    msg.inviter_uid = inviter_uid
    msg.is_refuse = is_refuse
    msg.copy_id = copy_id
    
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLiezhuanJoinTeam(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    if msg_obj.team_info then
        local teamInfo = self:ConvertToTeamData(msg_obj.team_info)
        if teamInfo and teamInfo.user_brief_lsit then
            self.m_teamInfo = teamInfo
            UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanFightTroop, teamInfo)
        end
    end
end

function LieZhuanMgr:ReqLieZhuanKickOutMember(uid)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_KICK_MEMBER
    local msg = (MsgIDMap[msg_id])()
    msg.target_uid = uid

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLieZhuanKickOutMember(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function LieZhuanMgr:ReqLiezhuanExitTeam(team_id)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_EXIT_TEAM
    local msg = (MsgIDMap[msg_id])()
    msg.team_id = team_id

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLiezhuanExitTeam(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    self.m_teamInfo = nil
    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_EXIT_TEAM)
end

function LieZhuanMgr:ReqLiezhuanInvitePannel()
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_INVITE_PANNEL_INFO
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLiezhuanInvitePannel(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    local friendBriefList = {}
    if msg_obj.friend_list then
        for _,v in ipairs(msg_obj.friend_list) do
            local user_brief = PBUtil.ConvertUserBriefProtoToData(v)
            if user_brief then
                table_insert(friendBriefList, user_brief)
            end
        end
    end
    local recentlyBriefList = {}
    if msg_obj.recently_list then
        for _,v in ipairs(msg_obj.recently_list) do
            local user_brief = PBUtil.ConvertUserBriefProtoToData(v)
            if user_brief then
                table_insert(recentlyBriefList, user_brief)
            end
        end
    end
    local guildBriefList = {}
    if msg_obj.guild_member_list then
        for _,v in ipairs(msg_obj.guild_member_list) do
            local user_brief = PBUtil.ConvertUserBriefProtoToData(v)
            if user_brief then
                table_insert(guildBriefList, user_brief)
            end
        end
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_INVITE_PANNEL_INFO, friendBriefList, recentlyBriefList, guildBriefList)
end

function LieZhuanMgr:ReqLiezhuanInviteTeam(target_uid_list)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_INVITE_TO_TEAM
    local msg = (MsgIDMap[msg_id])()

    if self.m_teamInfo then
        msg.team_id = self.m_teamInfo.team_base_info.team_id
        for i, v in ipairs(target_uid_list) do
            if v then
                msg.target_uid:append(v)
            end
        end

        HallConnector:GetInstance():SendMessage(msg_id, msg)
    end
end

function LieZhuanMgr:RspLiezhuanInviteTeam(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function LieZhuanMgr:ReqLiezhuanStartBuZhen()
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_START_BUZHEN
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLiezhuanStartBuZhen(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function LieZhuanMgr:ReqLieZhuanSelectWuJiang(wujiang_seq, pos, wujiang_id)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_SELECT_WUJIANG_TO_BUZHEN
    local msg = (MsgIDMap[msg_id])()
    msg.wujiang_seq = wujiang_seq
    msg.pos = pos
    msg.wujiang_id = wujiang_id

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLieZhuanSelectWuJiang(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function LieZhuanMgr:ReqLieZhuanExchangeWuJiang(pos_a, pos_b)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_EXCHANGE_BUZHEN_POS
    local msg = (MsgIDMap[msg_id])()
    msg.pos_a = pos_a
    msg.pos_b = pos_b

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLieZhuanExchangetWuJiang(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function LieZhuanMgr:ReqLieZhuanReadyFight(is_cancel)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_READY_TO_FIGHT
    local msg = (MsgIDMap[msg_id])()

    if self.m_teamInfo then
        msg.team_id = self.m_teamInfo.team_base_info.team_id
        msg.is_cancel = is_cancel
        
        HallConnector:GetInstance():SendMessage(msg_id, msg)
        end
end

function LieZhuanMgr:RspLieZhuanReadyFight(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local selfUid = self.m_userMgr:GetUserData().uid

    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_UPDATE_READY_STATE, msg_obj.is_cancel, selfUid)
end

function LieZhuanMgr:ReqLieZhuanSetAutoFight(is_auto_fight)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_SET_AUTO_FIGHT
    local msg = (MsgIDMap[msg_id])()
    msg.is_auto_fight = is_auto_fight
    
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLieZhuanSetAutoFight(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    if self.m_teamInfo and self.m_teamInfo.member_list then
        for _,v in ipairs(self.m_teamInfo.member_list) do
            if self.m_userMgr:CheckIsSelf(v.user_brief.uid) then
                v.is_auto_fight = msg_obj.is_auto_fight
                break
            end
        end
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_RSP_AUTO_FIGHT, msg_obj.is_auto_fight)
end

function LieZhuanMgr:ReqZhuanWatchBattleFinish()
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_WATCH_BATTLE_FINISH
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLieZhuanWatchBattleFinish(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    if self.m_teamInfo then
        if UIManagerInst:IsWindowOpen(UIWindowNames.UILieZhuanFightTroop) then
            UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_TEAM_MEMBER_CHG, self.m_teamInfo)
        else
            UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanFightTroop, self.m_teamInfo, msg_obj.is_auto_fight)
        end
    else
        UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanChoose, self.m_selectCountry)
        UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanTeam)
    end
end

function LieZhuanMgr:ReqZhuanSetAutoInvite(auto_invite)
    local msg_id = MsgIDDefine.LIEZHUAN_REQ_SET_AUTO_INVITE
    local msg = (MsgIDMap[msg_id])()
    msg.auto_invite = auto_invite
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function LieZhuanMgr:RspLieZhuanSetAutoInvite(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
            if self.m_teamInfo then
                self.m_teamInfo.captain_auto_invite = msg_obj.captain_auto_invite
            end
        return
    end
end

function LieZhuanMgr:NtfTeamInPlayerChg(msg_obj)
    if not msg_obj then
        return
    end
    
    if msg_obj.team_info then
        local teamInfo = self:ConvertToTeamData(msg_obj.team_info)
        local isSelfAction = self.m_userMgr:CheckIsSelf(msg_obj.uid)
        if teamInfo then
            if isSelfAction and msg_obj.action ~= TeamMemberAction.Add and msg_obj.action ~= TeamMemberAction.Reconnection then
                self.m_teamInfo = nil
            else
                self.m_teamInfo = teamInfo
            end

            local strNum = 0
            if msg_obj.action == TeamMemberAction.Add then
                strNum = 3786
            elseif msg_obj.action == TeamMemberAction.Leave then
                strNum = 3787
            elseif msg_obj.action == TeamMemberAction.LostConnection then
                strNum = 3797
            elseif msg_obj.action == TeamMemberAction.NotEnoughStamina then
                if isSelfAction then
                    strNum = 3731
                else
                    strNum = 3787
                end
            elseif msg_obj.action == TeamMemberAction.KickOut then
                strNum = 3749
            elseif msg_obj.action == TeamMemberAction.Overtime then
                strNum = 3729
            elseif msg_obj.action == TeamMemberAction.DataAbort then
                strNum = 3730
            end
            if strNum > 0 then
                UILogicUtil.FloatAlert(string_format(Language.GetString(strNum), msg_obj.name))
            end

            --断线重连，回到对应组队或者布阵界面
            local wujiangBuZhenList = {}
            if msg_obj.curr_wujiang_list_in_buzhen then
                for _,v in ipairs(msg_obj.curr_wujiang_list_in_buzhen) do
                    local buZhenInfo = self:ConvertToTeamBuZhenData(v)
                    if buZhenInfo then                        
                        table_insert(wujiangBuZhenList, buZhenInfo)
                    end
                end
            end

            if UIManagerInst:IsWindowOpen(UIWindowNames.UILieZhuanFightTroop) or UIManagerInst:IsWindowOpen(UIWindowNames.UILieZhuanLineup) then
                UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_TEAM_MEMBER_CHG, self.m_teamInfo, msg_obj.action, msg_obj.uid)
            else
                if msg_obj.action == TeamMemberAction.Reconnection and isSelfAction then --断线重连，服务器要求发送请求
                    self:ReqLiezhuanJoinTeam(teamInfo.team_base_info.team_id,0,false,teamInfo.team_base_info.copy_id)
                end

                if self.m_teamInfo and #wujiangBuZhenList > 0 and self.m_teamInfo.curr_stat == TeamStateEnum.BuZhen then
                    if UIManagerInst:IsWindowOpen(UIWindowNames.UILieZhuanLineup) then
                        UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_UPDATE_BUZHEN_INFO, wujiangBuZhenList)
                    elseif SceneManagerInst:IsHomeScene() then
                        UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanLineup,BattleEnum.BattleType_LIEZHUAN_TEAM, wujiangBuZhenList)
                    end
                    if msg_obj.action == TeamMemberAction.Reconnection then
                        self.m_cacheBuZhenList = wujiangBuZhenList
                    end
                else
                    if SceneManagerInst:IsHomeScene() and not SceneManagerInst:IsLoadingScene() then
                        if msg_obj.action == TeamMemberAction.Add or msg_obj.action == TeamMemberAction.Reconnection then
                            UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanFightTroop, self.m_teamInfo)
                        end
                    end
                    if msg_obj.action == TeamMemberAction.Reconnection then
                        self.m_cacheTeamInfo = teamInfo
                    end
                end
            end
        end
    end
end

function LieZhuanMgr:NtfTeamStatTimeChg(msg_obj)
    if not msg_obj then
        return
    end

    if msg_obj.team_id then
        if self.m_teamInfo then
            self.m_teamInfo.curr_stat = msg_obj.curr_stat
            self.m_teamInfo.left_time = msg_obj.left_time
        end
        UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_TEAM_STAT_TIME_CHG, msg_obj.left_time, msg_obj.curr_stat)
    end
end

function LieZhuanMgr:NtfTeamDissmiss(msg_obj)
    if not msg_obj then
        return
    end
    self.m_teamInfo = nil
    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_EXIT_TEAM)
end

function LieZhuanMgr:NtfInvitePlayerChg(msg_obj)
    if not msg_obj then
        return
    end

    if msg_obj.team_info then
        local teamInfo = self:ConvertToTeamData(msg_obj.team_info)
        local inviteData = {
            inviter_uid = msg_obj.inviter_uid,
            team_info = teamInfo,
            team_id = msg_obj.team_id,
            life_time = 30
        }
        local inviteDataList = { inviteData }
        if SceneManagerInst:IsHomeScene() and not SceneManagerInst:IsLoadingScene() then
            if UIManagerInst:IsWindowOpen(UIWindowNames.UIInviteTips) then
                UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_INVITE_TEAM_INFO, inviteDataList)
            else
                UIManagerInst:OpenWindow(UIWindowNames.UIInviteTips, inviteDataList)
            end
        else
            table_insert(self.m_inviteCacheList, inviteData)
            if not self.m_haveInviteCache then
                GamePromptMgr:GetInstance():InstallPrompt(CommonDefine.LIEZHUAN_INVITE_TEAM)
                self.m_haveInviteCache = true
            end
        end
    end
end

function LieZhuanMgr:CheckCacheInvite()

    GamePromptMgr:GetInstance():ClearCurPrompt()
    GamePromptMgr:GetInstance():ShowPrompt()

    if #self.m_inviteCacheList > 0 then
        if UIManagerInst:IsWindowOpen(UIWindowNames.UIInviteTips) then
            UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_INVITE_TEAM_INFO, self.m_inviteCacheList)
        else
            UIManagerInst:OpenWindow(UIWindowNames.UIInviteTips, self.m_inviteCacheList)
        end
    end
    self.m_inviteCacheList = {}
    self.m_haveInviteCache = false
end

function LieZhuanMgr:NtfTeamBuZhenInfoChg(msg_obj)
    if not msg_obj then
        return
    end

    if msg_obj.wujiang_list_in_buzhen then
        local wujiangBuZhenList = {}
        for _,v in ipairs(msg_obj.wujiang_list_in_buzhen) do
            local buZhenInfo = self:ConvertToTeamBuZhenData(v)
            if buZhenInfo then
                table_insert(wujiangBuZhenList, buZhenInfo)
            end
        end

        if UIManagerInst:IsWindowOpen(UIWindowNames.UILieZhuanLineup) then
            UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_UPDATE_BUZHEN_INFO, wujiangBuZhenList)
        else
            UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanLineup,BattleEnum.BattleType_LIEZHUAN_TEAM, wujiangBuZhenList)
        end
    end
end

function LieZhuanMgr:NtfReadyToFight(msg_obj)
    if not msg_obj then
        return
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_LIEZHUAN_UPDATE_READY_STATE, msg_obj.is_cancel, msg_obj.uid, msg_obj.is_auto_fight)
end

function LieZhuanMgr:NtfStartFight(msg_obj)
    if not msg_obj then
        return
    end
    
    CtlBattleInst:EnterBattle(msg_obj)
end

function LieZhuanMgr:Dispose()
    self.m_selectCountry = 0
    self.m_lieZhuanAllCopyCfgList = nil
    self.m_countryPassInfoList = nil
    self.m_cfg_single_fight_need_tili = 0
    self.m_cfg_team_fight_need_tili = 0
    self.m_teamInfo = nil
end

return LieZhuanMgr