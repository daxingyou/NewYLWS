local rawset = rawset
local PBUtil = PBUtil
local table_sort = table.sort
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format

local FriendMgr = BaseClass("FriendMgr")

function FriendMgr:__init()
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_FRIEND_LIST, Bind(self, self.RspFriendList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_RECENT_LIST, Bind(self, self.RspRecentList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_BLACK_LIST, Bind(self, self.RspBlackList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_RECOMMEND_LIST, Bind(self, self.RspRecommendList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_FIGHTING_ASSIST_INFO, Bind(self, self.RspFightingAssistInfo))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_FIGHTING_ASSIST_CHG, Bind(self, self.NtfFightingAssistChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_SEARCH, Bind(self, self.RspSearch))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_MOVE_TO_BLACKLIST, Bind(self, self.RspMoveToBlackList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_DELETE, Bind(self, self.RspDelete))    
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_REMOVE_FROM_BLACKLIST, Bind(self, self.RspMoveFromBlackList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_ADD_FRIEND, Bind(self, self.RspAddFriend))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_FRIEND_CHG, Bind(self, self.NtfFriendChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_DELETE_FRIEND, Bind(self, self.NtfDeleteFriend))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_REPLY, Bind(self, self.RspReply))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_REPLY, Bind(self, self.NtfReply))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_APPLY, Bind(self, self.NtfApply))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_DELETE_APPLY, Bind(self, self.NtfDeleteApply))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_SET_RENTOUT_WUJIANG, Bind(self, self.RspSetSendRentoutWuJiang))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_FRIENDS_RENTOUT_WUJIANG_PANEL, Bind(self, self.RspFriendsRentoutWuJiangPanel))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_TAKE_STAMINA, Bind(self, self.RspTakeStamina))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_SEND_STAMINA, Bind(self, self.RspSendStamina))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_SEND_GIFT, Bind(self, self.RspSendGift))
    -- HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_EXCHANGE, Bind(self, self.RspSendGift))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_TAKE_QINGYI, Bind(self, self.RspTakeQingYi))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_TAKE_BOX, Bind(self, self.RspTakeBox))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_ENTER_QIECUO, Bind(self, self.RspEnterQieCuo))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_INVITE_TO_COMPLETE_TASK, Bind(self, self.RspInviteToCompleteTask))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_NEW_INVITATION, Bind(self, self.NtfNewInvitation))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_DELETE_INVITATION, Bind(self, self.NtfDeleteInvitation))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_REPLY_INVITATION, Bind(self, self.RspReplyInvitation))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_CAN_INVITE_LIST, Bind(self, self.RspCanInviteList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_CLOSE_INVITE, Bind(self, self.NtfCloseInvite))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_TASK_CP, Bind(self, self.NtfTaskCP))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_FINISH_QIECUO, Bind(self, self.RspFinishQieCuo)) 
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_ACCEPT_TASK, Bind(self, self.RspAcceptTask))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_TAKE_TASK_AWARD, Bind(self, self.RspTakeTaskAward))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_TAKE_BOX_AWARD, Bind(self, self.RspTakeBoxAward))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_RSP_PANEL_REDPOINT_INFO, Bind(self, self.RspFriendRedPointInfo))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.FRIEND_NTF_FRIEND_TASK, Bind(self, self.NtfFriendTask))

    self.m_getAssist01Times = 0
    self.m_friendLimit = 0
    self.m_friendList = {}
    self.m_recentList = {}
    self.m_blackList = {}
    self.m_fightingAssistData = nil

    self.m_invitationList = {}
    self.m_invitationOpen = false

    self.m_assistTaskList = {}

    self.m_tmpRivalUID = 0
    self.m_employWujiangList = {}
    self.m_showedFriendTaskInvitation = false

    self.m_hasOpenAssistTaskList = {}
end

function FriendMgr:Dispose()
    self.m_friendLimit = 0
    self.m_friendList = nil
    self.m_recentList = nil
    self.m_blackList = nil
    self.m_fightingAssistData = nil

    self.m_invitationList = nil
    self.m_employWujiangList = nil
end

function FriendMgr:GetFriendLimit()
    return self.m_friendLimit or 0
end

function FriendMgr:GetFriendCount()
    return self.m_friendList and #self.m_friendList or 0
end

function FriendMgr:GetFriendList()
    return self.m_friendList
end

function FriendMgr:CheckIsFriend(uid)
    if self.m_friendList then
        for i = 1, #self.m_friendList do
            if self.m_friendList[i] then
            local friend_brief = self.m_friendList[i].friend_brief
                if friend_brief and friend_brief.uid == uid then
                    return true
                end
            end
        end
    end
    return false
end

function FriendMgr:CheckIsInBlackList(uid)
    if self.m_blackList then
        for i = 1, #self.m_blackList do
            if self.m_blackList[i] then
            local friend_brief = self.m_blackList[i].friend_brief
                if friend_brief and friend_brief.uid == uid then
                    return true
                end
            end
        end
    end
    return false
end

function FriendMgr:ReqFriendList()
    local msg_id = MsgIDDefine.FRIEND_REQ_FRIEND_LIST
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspFriendList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    self.m_friendLimit = msg_obj.friend_limit
    self.m_friendList = msg_obj.friendlist
    
    if self.m_friendList then
        table_sort(self.m_friendList, self.FriendDataSortFunc)
    end
    
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_LIST)
end

function FriendMgr:ReqRecentList()
    local msg_id = MsgIDDefine.FRIEND_REQ_RECENT_LIST
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspRecentList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    self.m_recentList = msg_obj.recentlist
    if self.m_recentList then
        table_sort(self.m_recentList, self.FriendDataSortFunc)
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_RECENT_LIST, self.m_recentList)
end

function FriendMgr:ReqBlackList()
    local msg_id = MsgIDDefine.FRIEND_REQ_BLACK_LIST
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspBlackList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local blackList = msg_obj.blacklist
    if blackList then
        table_sort(blackList, self.FriendDataSortFunc)
    end
    self.m_blackList = blackList
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_BLACK_LIST, blackList)
end

function FriendMgr:ReqRecommendList()
    local msg_id = MsgIDDefine.FRIEND_REQ_RECOMMEND_LIST
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspRecommendList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local recommendList = msg_obj.recommend_list
    local applyList = msg_obj.applylist
    
    if recommendList then
        table_sort(recommendList, self.FriendDataSortFunc)
    end
    if applyList then
        table_sort(applyList, self.FriendApplyDataSortFunc)
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_RECOMMEND_LIST, recommendList, applyList)
end

function FriendMgr:ReqFightingAssistInfo()
    local msg_id = MsgIDDefine.FRIEND_REQ_FIGHTING_ASSIST_INFO
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspFightingAssistInfo(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    self.m_fightingAssistData = self:ConvertToFightAssistData(msg_obj.fighting_assist)
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_BATTLE_HELP_DATA, self.m_fightingAssistData)
end

function FriendMgr:NtfFightingAssistChg(msg_obj)
    if not msg_obj then
        return
    end
    self.m_fightingAssistData = self:ConvertToFightAssistData(msg_obj.fighting_assist)
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_BATTLE_HELP_DATA, self.m_fightingAssistData)
end

function FriendMgr:ConvertToFightAssistData(fighting_assist)
    if not fighting_assist then
        return
    end
    local fightingAssistData = {
        rentout_wujiang_brief = PBUtil.ConvertWujiangBriefProtoToData(fighting_assist.rentout_wujiang_brief),
        be_hired_times = fighting_assist.be_hired_times or 0,
        qingyi_count = fighting_assist.qingyi_count or 0,
        box_flag = fighting_assist.box_flag or 0,
        rent_record_list = self:ConvertRentRecordList(fighting_assist.rent_record_list),
        box_need_be_hired_times = fighting_assist.box_need_be_hired_times or 0,
        box_item_list = self:ConvertAwardList(fighting_assist.box_item_list),
    }
    return fightingAssistData
end

function FriendMgr:ConvertRentRecordList(rent_record_list)
    if not rent_record_list then
        return nil
    end
    local recordDataList = {}
    for i = 1, #rent_record_list do
        local data = rent_record_list[i]
        local toData = {
            renter_uid = data.renter_uid,
            battle_type = data.battle_type,
            rent_time = data.rent_time,
            qingyi_count = data.qingyi_count,
            rent_wujiang_id = data.rent_wujiang_id,
            renter_name = data.renter_name
        }
        table_insert(recordDataList, toData)
    end
    return recordDataList
end

function FriendMgr:ConvertAwardList(award_item_list)
    if not award_item_list then
        return nil
    end
    local awardItemList = {}
    for i = 1, #award_item_list do
        local data = award_item_list[i]
        local toData = {
            item_id = data.item_id,
            count = data.count,
        }
        table_insert(awardItemList, toData)
    end
    return awardItemList
end

function FriendMgr:IsRentOutWuJiang(wujiangSeq)
    if self.m_fightingAssistData and self.m_fightingAssistData.rentout_wujiang_brief then
        return self.m_fightingAssistData.rentout_wujiang_brief.index == wujiangSeq
    end
    return false
end

function FriendMgr:ReqSearch(search_string)
    local msg_id = MsgIDDefine.FRIEND_REQ_SEARCH
    local msg = (MsgIDMap[msg_id])()
    msg.search_string = search_string

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspSearch(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local searchList = msg_obj.search_list
    
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_SEARCH_PLAYER, searchList)
end

function FriendMgr:ReqDelete(uid)
    local msg_id = MsgIDDefine.FRIEND_REQ_DELETE
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspDelete(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_DELETE_ONE_FRIEND)
end

function FriendMgr:ReqMoveToBlackList(uid)
    local msg_id = MsgIDDefine.FRIEND_REQ_MOVE_TO_BLACKLIST
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspMoveToBlackList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UILogicUtil.FloatAlert(Language.GetString(3054))
end

function FriendMgr:ReqRemoveFromBlackList(uid)
    local msg_id = MsgIDDefine.FRIEND_REQ_REMOVE_FROM_BLACKLIST
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspMoveFromBlackList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_REMOVE_FROM_BLACKLIST)
end

function FriendMgr:ReqAddFriend(uid, verification_message)
    local msg_id = MsgIDDefine.FRIEND_REQ_ADD_FRIEND
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.verification_message = verification_message

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspAddFriend(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_SEND_REQUEST)
end

function FriendMgr:NtfFriendChg(msg_obj)
    if not msg_obj then
        return
    end

    if not msg_obj or not msg_obj.friend then
        return
    end
    local friendData = msg_obj.friend
    if not friendData then
        return
    end
    local uid = friendData.friend_brief.uid

    --NEW = 1,
    --MOVE_TO_BLACKLIST = 2,
    --REMOVE_FROM_BLACKLIST = 3,
    --SEND_STAMINA = 4,
    --TAKE_STAMINA = 5,
    --RENTOUT_WUJIANG_CHG = 6,
    --SEND_GIFT = 7,
    local reason = msg_obj.reason

    if reason == 1 then
        if friendData and friendData.friend_brief and self.m_friendList then
            rawset(self.m_friendList, #self.m_friendList + 1, friendData)
            local name = friendData.friend_brief.name
            UILogicUtil.FloatAlert(string_format(Language.GetString(3021), name))
        end
    else
        for i = 1, #self.m_friendList do
            local data = self.m_friendList[i]
            if data and data.friend_brief and data.friend_brief.uid == uid then
                self.m_friendList[i] = friendData
                break
            end
        end
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_FRIEND_DATA_CHG, friendData, reason)
end

function FriendMgr:NtfDeleteFriend(msg_obj)
    if not msg_obj then
        return
    end
    local uid = msg_obj.uid
    
    for i = 1, #self.m_friendList do
        local data = self.m_friendList[i]
        if data and data.friend_brief and data.friend_brief.uid == uid then
            table_remove(self.m_friendList, i)
            break
        end
    end
    for i = 1, #self.m_recentList do
        local data = self.m_recentList[i]
        if data and data.friend_brief and data.friend_brief.uid == uid then
            data.param1 = 0
            break
        end
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_NTF_DELETE, uid)
end

--1:通过
function FriendMgr:ReqReply(uid, answer)
    local msg_id = MsgIDDefine.FRIEND_REQ_REPLY
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.answer = answer

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspReply(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function FriendMgr:NtfReply(msg_obj)
    if not msg_obj then
        return
    end

    local reply = msg_obj.reply
end

function FriendMgr:NtfApply(msg_obj)
    if not msg_obj then
        return
    end
    local apply = msg_obj.apply
end

function FriendMgr:NtfDeleteApply(msg_obj)
    if not msg_obj then
        return
    end
    local uid = msg_obj.uid

    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_DELETE_APPLY_LIST, uid)
end

--wujiang_index(0:移除设置的外租武将)
function FriendMgr:ReqSetSendRentoutWuJiang(wujiang_index)
    local msg_id = MsgIDDefine.FRIEND_REQ_SET_RENTOUT_WUJIANG
    local msg = (MsgIDMap[msg_id])()
    msg.wujiang_index = wujiang_index

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspSetSendRentoutWuJiang(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function FriendMgr:ReqFriendsRentoutWuJiangPanel()
    local msg_id = MsgIDDefine.FRIEND_REQ_FRIENDS_RENTOUT_WUJIANG_PANEL
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspFriendsRentoutWuJiangPanel(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    self.m_employWujiangList = {}
    for k, v in ipairs(msg_obj.friends_wujiang_list) do
        local employBrief = PBUtil.ConvertEmpolyWujiangProtoToData(v)
        self.m_employWujiangList[employBrief.friendBriefData.uid] = employBrief
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_EMPLOY_LIST, msg_obj.left_rent_times)
end

function FriendMgr:NtfLeftRentTimes(msg_obj)
    if not msg_obj then
        return
    end
    local left_rent_times = msg_obj.left_rent_times
end

--uid(0:所有, 其他:指定好友)
function FriendMgr:ReqTakeStamina(uid)
    local msg_id = MsgIDDefine.FRIEND_REQ_TAKE_STAMINA
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspTakeStamina(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UILogicUtil.FloatAlert(Language.GetString(3019))
end

--uid(0:所有, 其他:指定好友)
function FriendMgr:ReqSendStamina(uid)
    local msg_id = MsgIDDefine.FRIEND_REQ_SEND_STAMINA
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspSendStamina(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UILogicUtil.FloatAlert(Language.GetString(3018))
end

function FriendMgr:ReqSendGift(uid, gift_id, gift_count)
    local msg_id = MsgIDDefine.FRIEND_REQ_SEND_GIFT
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.gift_id = gift_id
    msg.gift_count = gift_count

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspSendGift(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UILogicUtil.FloatAlert(Language.GetString(3062))
end

function FriendMgr:ReqExchange(item_id, count)
    local msg_id = MsgIDDefine.FRIEND_REQ_EXCHANGE
    local msg = (MsgIDMap[msg_id])()
    msg.item_id = item_id
    msg.count = count

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspExchange(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function FriendMgr:ReqTakeQingYi()
    local msg_id = MsgIDDefine.FRIEND_REQ_TAKE_QINGYI
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspTakeQingYi(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
    
    local uiData = {
        openType = 1,
        awardDataList = awardList
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function FriendMgr:ReqTakeBox()
    local msg_id = MsgIDDefine.FRIEND_REQ_TAKE_BOX
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspTakeBox(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
    
    local uiData = {
        openType = 1,
        awardDataList = awardList
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function FriendMgr:ReqEnterQieCuo()
    local msg_id = MsgIDDefine.FRIEND_REQ_ENTER_QIECUO
    local msg = (MsgIDMap[msg_id])()
    msg.uid = self.m_tmpRivalUID
    local buzhenID = Utils.GetBuZhenIDByBattleType(BattleEnum.BattleType_FRIEND_CHALLENGE)
    PBUtil.ConvertLineupDataToProto(buzhenID, msg.buzhen_info, Player:GetInstance():GetLineupMgr():GetLineupDataByID(buzhenID))

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspEnterQieCuo(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    CtlBattleInst:EnterBattle(msg_obj)
end

function FriendMgr:ReqFinishQieCuo(playerIsWin)
    local msg_id = MsgIDDefine.FRIEND_REQ_FINISH_QIECUO
    local msg = (MsgIDMap[msg_id])()
    msg.uid = self.m_tmpRivalUID
    self.m_tmpRivalUID = 0
    msg.finish_result = playerIsWin and 0 or 1

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspFinishQieCuo(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function FriendMgr:TryFindUserBriefData(uid)
    local UserMgr = Player:GetInstance():GetUserMgr()
    if UserMgr:CheckIsSelf(uid) then
        local userData = UserMgr:GetUserData()
        local briefData = 
        {
            uid = userData.uid,
            level = userData.level,
            name = userData.name,
            use_icon = 
            {
                icon = userData.use_icon_data.icon,
                icon_box = userData.use_icon_data.icon_box,
            },
            vip_level = userData.vip_level,

            -- guild_name = userData.guild_name,
            -- guild_job = userData.guild_job,
            -- guild_id = userData.guild_id,
            -- dist_id = userData.dist_id,
        }
        return briefData
    end
    for i = 1, #self.m_friendList do
        local friendData = self.m_friendList[i]
        if friendData and friendData.friend_brief and friendData.friend_brief.uid == uid then
            return friendData.friend_brief
        end
    end
    for i = 1, #self.m_recentList do
        local friendData = self.m_recentList[i]
        if friendData.friend_brief and friendData.friend_brief.uid == uid then
            return friendData.friend_brief
        end
    end
    return nil
end

function FriendMgr.FriendDataSortFunc(x, y)
    if x and y then
        if x.last_login_time == 0 or y.last_login_time == 0 then
            return x.last_login_time < y.last_login_time
        elseif x.last_login_time ~= y.last_login_time then
            return x.last_login_time > y.last_login_time
        end
    else
        return true
    end
end

function FriendMgr.FriendApplyDataSortFunc(x, y)
    if x and y then
        if x.apply_time ~= y.apply_time then
            return x.apply_time > y.apply_time
        end
    else
        return true
    end
end

function FriendMgr:ReqInviteToCompleteTask(uidList)
    local msg_id = MsgIDDefine.FRIEND_REQ_INVITE_TO_COMPLETE_TASK
    local msg = (MsgIDMap[msg_id])()
    local list = msg.uid_list
    for i = 1, #uidList do
        rawset(list, i, uidList[i])
    end

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspInviteToCompleteTask(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UILogicUtil.FloatAlert(Language.GetString(3058))
end

function FriendMgr:NtfNewInvitation(msg_obj)
    if not msg_obj then
        return
    end
    local uid = msg_obj.invitation.user_brief.uid
    for i = 1, #self.m_invitationList do
        if self.m_invitationList[i].user_brief.uid == uid then
            return
        end
    end
    table_insert(self.m_invitationList, msg_obj.invitation)
    UIManagerInst:Broadcast(UIMessageNames.MN_FFRIEND_INVITATION_CHG)
end

function FriendMgr:NtfDeleteInvitation(msg_obj)
    if not msg_obj then
        return
    end
    local uid = msg_obj.uid
    if uid == 0 then
        self.m_invitationList = {}
    else
        for i = 1, #self.m_invitationList do
            if self.m_invitationList[i].user_brief.uid == uid then
                table_remove(self.m_invitationList, i)
                break
            end
        end
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_FFRIEND_INVITATION_CHG)
end

--isAccept  1接受，0拒绝
function FriendMgr:ReqReplyInvitation(uid, isAccept)
    local msg_id = MsgIDDefine.FRIEND_REQ_REPLY_INVITATION
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.accept = isAccept

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspReplyInvitation(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end 
end

function FriendMgr:ReqCanInviteList()
    local msg_id = MsgIDDefine.FRIEND_REQ_CAN_INVITE_LIST
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspCanInviteList(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    local friendlist = msg_obj.friendlist
    UIManagerInst:Broadcast(UIMessageNames.MN_FFRIEND_INVITATION_LIST, friendlist)
end

function FriendMgr:NtfCloseInvite(msg_obj)
    if not msg_obj then
        return
    end
    self.m_invitationOpen = msg_obj.close == 0
    UIManagerInst:Broadcast(UIMessageNames.MN_FFRIEND_INVITATION_OPEN)
end

function FriendMgr:NtfTaskCP(msg_obj)
    local isAssitsOpen = UILogicUtil.CheckAssitsTastIsOpen()
    if not isAssitsOpen then
        return
    end

    if not msg_obj then
        return
    end
    if msg_obj.reason == 2 then
        self.m_assistTaskList = {}
    elseif msg_obj.reason == 1 or msg_obj.reason == 3 then
        if msg_obj.user_brief then
            local uid = msg_obj.user_brief.uid
            if not self.m_assistTaskList[uid] then
                self.m_assistTaskList[uid] = {}
                if reason == 1 then 
                    UILogicUtil.FloatAlert(Language.GetString(3078))
                end
            end
            self.m_hasOpenAssistTaskList[uid] = false

            self.m_assistTaskList[uid].user_brief = msg_obj.user_brief
        end
    end  
      
    UIManagerInst:Broadcast(UIMessageNames.MN_FRIEND_ASSIST_TASK_OPEM)
end 

function FriendMgr:SetHasOpenAssistTaskList(uid)
    self.m_hasOpenAssistTaskList[uid] = true
end

function FriendMgr:GetAssistTaskList()
    return self.m_assistTaskList
end

function FriendMgr:GetAssistTaskById(uid)
    return self.m_assistTaskList[uid]
end

function FriendMgr:GetCurAssistTaskIsExist_0_1(uid) 
    local curAssistTaskInfo = self:GetAssistTaskById(uid)

    local task_list = curAssistTaskInfo.task_list
    local box_status = curAssistTaskInfo.box_status

    local isExist0_1 = false
    if box_status == 0 or box_status == 1 then
        isExist0_1 = true
    end

    if not isExist0_1 then
        if task_list then
            for k, v in pairs(task_list) do
                if v.status == 0 or v.status == 1 then
                    isExist0_1 = true
                    break
                end
            end
        end
    end
     
    return isExist0_1
end

function FriendMgr:GetCurAssistTaskIsExist_1(uid)
    local curAssistTaskInfo = self:GetAssistTaskById(uid)

    local task_list = curAssistTaskInfo.task_list
    local box_status = curAssistTaskInfo.box_status

    local isExist_1 = false
    if box_status == 1 then
        isExist_1 = true
    end

    if not isExist_1 then
        if task_list then
            for k, v in pairs(task_list) do
                if v.status == 1 then
                    isExist_1 = true
                    break
                end
            end
        end 
    end

    return isExist_1
end

function FriendMgr:GetAssistTaskCount()
    local count = 0
    for k,v in pairs(self.m_assistTaskList) do 
        if k ~= 0 and v then
            count = count + 1
        end
    end
    return count
end 

function FriendMgr:GetNextTaskUserData()
    local data = self.m_invitationList[1]
    if data then
        return data.user_brief
    end
    return nil 
end

function FriendMgr:GetTaskInvitationCount()
    return #self.m_invitationList
end

function FriendMgr:IsInvitationOpen()
    return self.m_invitationOpen
end

function FriendMgr:SetTmpRivalUID(uid)
    self.m_tmpRivalUID = uid
end

----------------协同任务-------------------------------------------------------------- 
function FriendMgr:NtfFriendTask(msg_obj)
    local tempTaskList = {}
    for k, v in ipairs(msg_obj.task_list) do 
        table_insert(tempTaskList, self:ConvertOneTask(v))
    end    
    self.m_assistTaskList[msg_obj.user_brief.uid] = 
    {
        user_brief = msg_obj.user_brief,
        task_list = tempTaskList,
        box_curr_value = msg_obj.box_curr_value,
        box_status = msg_obj.box_status,
        item_list = msg_obj.item_list,
        close_time = msg_obj.close_time,
        box_cond = msg_obj.box_cond,
        curr_floor = msg_obj.curr_floor or 0,
        max_floor = msg_obj.max_floor or 0,
        cfg_max_floor = msg_obj.cfg_max_floor or 0,
    }
    UIManagerInst:Broadcast(UIMessageNames.MN_RSP_FRIEND_TASK_PANEL_INFO)
    UIManagerInst:Broadcast(UIMessageNames.MN_NTF_FRIEND_TASK_CHG)
    UIManagerInst:Broadcast(UIMessageNames.MN_YUANMEN_NTF_ASSIST_TASK)
end

function FriendMgr:ConvertOneTask(onetask)
    if onetask then
        local data = {}
        data.id = onetask.id or 0
        data.progress = onetask.progress or 0
        data.status = onetask.status or 0
        return data
    end
end

function FriendMgr:ReqAcceptTask(taskID, uid, floor)
    local msg_id = MsgIDDefine.FRIEND_REQ_ACCEPT_TASK
    local msg = (MsgIDMap[msg_id])()
    msg.task_id = taskID
    msg.uid = uid
    msg.floor = floor

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspAcceptTask(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UILogicUtil.FloatAlert(Language.GetString(3067))
end

function FriendMgr:ReqTakeTaskAward(taskID, uid, floor)
    local msg_id = MsgIDDefine.FRIEND_REQ_TAKE_TASK_AWARD
    local msg = (MsgIDMap[msg_id])()
    msg.task_id = taskID
    msg.uid = uid
    msg.floor = floor

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspTakeTaskAward(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
    
    local uiData = {
        openType = 1,
        awardDataList = awardList
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function FriendMgr:ReqTakeBoxAward(uid, floor)
    local msg_id = MsgIDDefine.FRIEND_REQ_TAKE_BOX_AWARD
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.floor = floor

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspTakeBoxAward(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
    local uiData = {
        openType = 1,
        awardDataList = awardList
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function FriendMgr:ReqFriendRedPointInfo()
    local msg_id = MsgIDDefine.FRIEND_REQ_PANEL_REDPOINT_INFO
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function FriendMgr:RspFriendRedPointInfo(msg_obj)
    if msg_obj.result == 0 then
        local info = {
            friend_red_count = msg_obj.friend_red_count,
            recent_red_count = msg_obj.recent_red_count,
            apply_red_count = msg_obj.apply_red_count,
            assist_box_enable = msg_obj.assist_box_enable,
        }

        UIManagerInst:Broadcast(UIMessageNames.MN_RSP_FRIEND_RED_POINT_INFO, info)
    end
end

----------------------------------end---------------------------------------

function FriendMgr:HasShowedFriendTaskInvitation()
    return self.m_showedFriendTaskInvitation
end

function FriendMgr:ShowedFriendTaskInvitation(isShow)
    self.m_showedFriendTaskInvitation = isShow
end

function FriendMgr:GetEmployWujiangBriefData(uid)
    local employBrief = self.m_employWujiangList[uid]
    if employBrief then
        return employBrief.wujiangBriefData
    end
end

-- 根据排序规则获取武将列表
function FriendMgr:GetSortEmployWuJiangList(priority, filter)
    priority = priority or 1
    if priority <= 0 or priority > 4 then
        Logger.LogError("GetSortWuJiangList priority error")
        return
    end

    local wujiangList = {}
    for _, v in pairs(self.m_employWujiangList) do
        local wujiangCfg = ConfigUtil.GetWujiangCfgByID(v.wujiangBriefData.id)
        if filter and wujiangCfg then
            if filter(v, wujiangCfg) then
                v.sortNum = self:GetSortNum(v.wujiangBriefData, priority)
                table_insert(wujiangList, v)
            end
        else
            v.sortNum = self:GetSortNum(v.wujiangBriefData, priority)
            table_insert(wujiangList, v)
        end
    end

    table_sort(wujiangList, function(l, r)
        if l.sortNum ~= r.sortNum then
            return l.sortNum > r.sortNum
        end

        if l.wujiangBriefData.id ~= r.wujiangBriefData.id then
            return l.wujiangBriefData.id < r.wujiangBriefData.id
        end
        
		return l.wujiangBriefData.index < l.wujiangBriefData.index
    end)

    return wujiangList
end

function FriendMgr:GetSortNum(wujiangData, priority)
    --排序规则，按优先级
    --优先级 星级＞等级＞突破次数＞稀有度＞id  
    --priority 1星级2等级3突破次数4稀有度
    --星级1位数 等级3位 突破次数 2位 稀有度1位

    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(wujiangData.id)
    if wujiangCfg then
        if priority == 1 then
            return wujiangData.star * 1000000 + wujiangData.level * 1000 + wujiangData.tupo * 10 + wujiangCfg.rare
        elseif priority == 2 then
            return wujiangData.level * 10000 + wujiangData.star * 1000 + wujiangData.tupo * 10 + wujiangCfg.rare
        elseif priority == 3 then
            return wujiangData.tupo * 100000 + wujiangData.star * 10000 + wujiangData.level * 10 + wujiangCfg.rare
        elseif priority == 4 then
            return wujiangCfg.rare * 1000000 + wujiangData.star * 100000 + wujiangData.level * 100 + wujiangData.tupo 
        end
    end 

    return 0
end

return FriendMgr