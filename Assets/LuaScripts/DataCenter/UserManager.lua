local SimpleHttp = CS.SimpleHttp
local DataUtils = CS.DataUtils

local GameSettingData = require("DataCenter.UserData.GameSettingData")
local OneUserIconData = require("DataCenter.UserData.OneUserIconData")
local UserData = require("DataCenter.UserData.UserData")
local UserManager = BaseClass("UserManager")

local table_insert = table.insert
local table_sort = table.sort

function UserManager:__init()
	HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_HEARTBEAT, Bind(self, self.OperateHeartBeat))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_STAR_PANEL, Bind(self, self.RspStarPanel))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_ACTIVE_STAR, Bind(self, self.RspActiveStar))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_NTF_STAR_CHG, Bind(self, self.NtfStarChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.SETTING_NTF_ACTIVITY_SETTING, Bind(self, self.NtfActivitySetting))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_CHANGE_NAME, Bind(self, self.RspChangeName))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_USE_HEAD_ICON, Bind(self, self.RspUseHeadIcon))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_NTF_USER_INFO_CHG,Bind(self, self.NtfUserInfoChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_BUY_STAMINA, Bind(self, self.RspBuyStamina))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_RANDOM_NAME, Bind(self, self.RspRandomName))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_CREATE_USER, Bind(self, self.RspCreateRole))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_TAKE_ACTIVE_STAR_AWARD, Bind(self, self.RspTakeActiveStarAward))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.UI_NTF_SHOW_MESSAGE, Bind(self, self.NtfShowMessage))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_ZHENGZHAN_PANEL, Bind(self, self.RspFightWarData))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_NTF_MONEY_CHG, Bind(self, self.NtfMoneyChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_QUERY_USER_BRIEF, Bind(self, self.RspUserDetail))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_SET_PERSONAL_SIGNATURE, Bind(self, self.RspSetSignature))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.VIP_RSP_TAKE_VIPLEVELGIFT_AWARD, Bind(self, self.RspTakeVipLevelGift))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_NTF_USER_VIP_LEVEL_CHG, Bind(self, self.NtfVipLevelChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_ALL_USER_DATA, Bind(self, self.OnRspAllData))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_SET_GUIDED, Bind(self, self.RspSetGuided))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_NTF_GUIDE_FLAGS_CHG, Bind(self, self.NtfGuideFlagChg))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_NTF_REDPOINT_LIST, Bind(self, self.NtfRedPointList))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_TAKE_DOWNLOAD_AWARD, Bind(self, self.RspTakeDownloadAward))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_RSP_REPORT_GUIDE_DETAIL, Bind(self, self.RspReportGuideDetail))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.USER_NTF_SERVER_NOTICE, Bind(self, self.NtfServerNotice))


    self.m_isCrossDay = false
    self.m_gameSettingData = nil
    self.m_userIconData = nil
    self.m_copyStarCount = 0
    self.m_starMakeIDList = {}
    self.m_guideFlag = 0
    self.m_redPointIdList = {}
    self.m_isShowDownloadRedPoint = true
    self.m_serverNoticeList = {}
    self.m_typeServerNoticelist = {}

    self.m_userData = UserData.New()
end

function UserManager:Dispose()
    self.m_copyStarCount = 0
    self.m_starMakeIDList = nil
    self.m_userIconData = nil

    base.Dispose(self)
end

function UserManager:IsCrossDay()
    return self.m_isCrossDay
end

function UserManager:SetCrossDay(isCross)
    self.m_isCrossDay = isCross
end

function UserManager:ReqHeartBeat()
	local msg_id = MsgIDDefine.USER_REQ_HEARTBEAT
	local msg = (MsgIDMap[msg_id])()
	msg.last_mail_time = 0
	msg.last_heart_time = 0
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:OperateHeartBeat(msg_obj)
	-- Logger.Log('OperateHeartBeat msg_obj: ' .. tostring(msg_obj))
	local result = msg_obj.result
	if result ~= 0 then
		Logger.LogError('OnRspLogin failed: '.. result)
		return
	end

    self.m_isCrossDay = msg_obj.is_crossday == 1 and true or false

    Player:GetInstance():SetServerTime(msg_obj.game_time)
    UIManagerInst:Broadcast(UIMessageNames.MN_RSP_HEARTBEAT, msg_obj)
    -- TODO
    -- if(CrossDay)
    -- {
    --     Player.instance.KingdomwarMgr.ResetData();
    -- }
    -- if (GameModel.instance.gameSetting.module_switch != obj.module_switch)
    -- {
    --     GameModel.instance.gameSetting.module_switch = obj.module_switch;
    --     Messenger.Broadcast(MessageName.MN_MODULE_OPEN_CHG);
    -- }
end

function UserManager:NtfActivitySetting(msg_obj)
    if not self.m_gameSettingData then
        self.m_gameSettingData = GameSettingData.New()
    end
    self.m_gameSettingData.gmt_zone = msg_obj.setting.gmt_zone
    self.m_gameSettingData.player_rename_cost = msg_obj.setting.player_rename_cost
	self.m_gameSettingData.max_user_level = msg_obj.setting.max_user_level
	self.m_gameSettingData.module_switch = msg_obj.setting.module_switch
	self.m_gameSettingData.elite_copy_limit = msg_obj.setting.elite_copy_limit
    self.m_gameSettingData.max_copy_section = msg_obj.setting.max_copy_section
    self.m_gameSettingData.create_guild_need_yuanbao = msg_obj.setting.create_guild_need_yuanbao
    self.m_gameSettingData.rebuild_shenbing_cost_1 = msg_obj.setting.rebuild_shenbing_cost_1
    self.m_gameSettingData.rebuild_shenbing_cost_2 = msg_obj.setting.rebuild_shenbing_cost_2
    self.m_gameSettingData.rebuild_shenbing_cost_3 = msg_obj.setting.rebuild_shenbing_cost_3
    self.m_gameSettingData.arena_lingpai_limit = msg_obj.setting.arena_lingpai_limit
    self.m_gameSettingData.hunt_levelup_reduce_cd_per_yuanbao = msg_obj.setting.hunt_levelup_reduce_cd_per_yuanbao
    self.m_gameSettingData.horse_show_cd = msg_obj.setting.horse_show_cd
    self.m_gameSettingData.dragoncopy_max_challenge_times = msg_obj.setting.dragoncopy_max_challenge_times
    self.m_gameSettingData.dragon_max_level = msg_obj.setting.dragon_max_level
    Player:GetInstance():GetMainlineMgr():InitMaxOpenSection(self.m_gameSettingData.max_copy_section)
end

function UserManager:GetSettingData()
    return self.m_gameSettingData
end

function UserManager:OnUserInfo(user_info)
    if user_info then

         --todo
        local userData = self.m_userData

        userData.uid = user_info.uid
        userData.name = user_info.name
        if userData.exp ~= user_info.exp then
            userData.exp = user_info.exp
            UIManagerInst:Broadcast(UIMessageNames.MN_EXP_CHG)
        end

        if userData.level ~= user_info.level then
            userData.level = user_info.level
            UIManagerInst:Broadcast(UIMessageNames.MN_LEVEL_CHG)
        end

        if userData.yuanbao ~= user_info.yuanbao then
            userData.yuanbao = user_info.yuanbao
            UIManagerInst:Broadcast(UIMessageNames.MN_GOLD_CHG)
        end
        
        if userData.stamina ~= user_info.stamina then
            userData.stamina = user_info.stamina
            UIManagerInst:Broadcast(UIMessageNames.MN_VIGOR_CHG)
        end

        userData.stamina_limit = user_info.stamina_limit
        userData.stamina_recovering_time = user_info.stamina_recovering_time
        userData.stamina_all_recovering_time = user_info.stamina_all_recovering_time
        userData.arena_ling_recovering_time = user_info.arena_ling_recovering_time
        userData.arena_ling_all_recovering_time = user_info.arena_ling_all_recovering_time
        userData.vip_level = user_info.vip_level
        userData.vip_exp = user_info.vip_exp
        userData.create_time = user_info.create_time
        userData.take_download_award_flag = user_info.take_download_award_flag
        userData.guild_id = user_info.guild_id
        userData.guild_level = user_info.guild_level
        userData.guild_job = user_info.guild_job
        userData.today_buy_stamina_count = user_info.today_buy_stamina_count
        userData.next_buy_stamina_cost = user_info.next_buy_stamina_cost
        userData.use_icon_data.icon = user_info.use_icon.icon
        userData.use_icon_data.icon_box = user_info.use_icon.icon_box
        userData.viplevelgift_taken_flag = user_info.viplevelgift_taken_flag  
        if userData.first_recharge_award_status ~= user_info.first_recharge_award_status then
            userData.first_recharge_award_status = user_info.first_recharge_award_status
            UIManagerInst:Broadcast(UIMessageNames.MN_USER_RSP_CHANGENAME)
        end
        userData.str_dist_id = user_info.str_dist_id
        userData.dist_name = user_info.dist_name
        userData.guild_name = user_info.guild_name

        self.m_guideFlag = user_info.guide_flags | (user_info.guide_flags_ex << 32)

    end
end

function UserManager:GetUserData()
    return self.m_userData
end

function UserManager:CheckIsSelf(uid)
    return self.m_userData and self.m_userData.uid == uid
end

function UserManager:CheckJoinGuild()
    return self.m_userData and self.m_userData.guild_id > 0 or false
end

--错误消息飘字和弹框

function UserManager:NtfShowMessage(msg_obj)
    --0飘字 ，1弹框
    if msg_obj.msg_type == 0 then
        UILogicUtil.FloatAlert(msg_obj.message)
    elseif msg_obj.msg_type == 1 then

    end
end

--主公协议
function UserManager:ReqChangeName(userName)
    local msg_id = MsgIDDefine.USER_REQ_CHANGE_NAME
    local msg = (MsgIDMap[msg_id])()
    msg.name = userName
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end


function UserManager:RspChangeName(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UILogicUtil.FloatAlert(Language.GetString(2732))
    self.m_userData.name = msg_obj.name
    UIManagerInst:Broadcast(UIMessageNames.MN_USER_RSP_CHANGENAME)
end

function UserManager:ReqBuyStamina()
    local msg_id = MsgIDDefine.USER_REQ_BUY_STAMINA
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspBuyStamina(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(Language.GetString(2713))
    end
end

function UserManager:ReqUseHeadIcon(headId)
    local msg_id = MsgIDDefine.USER_REQ_USE_HEAD_ICON
    local msg = (MsgIDMap[msg_id])()
    msg.icon = headId
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspUseHeadIcon(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    UILogicUtil.FloatAlert(Language.GetString(2734))
    local userData = self.m_userData
    userData.use_icon_data.icon = msg_obj.use_icon.icon
    userData.use_icon_data.icon_box = msg_obj.use_icon.icon_box
    UIManagerInst:Broadcast(UIMessageNames.MN_USER_RSP_USE_HEAD_ICON, msg_obj)
end

function UserManager:ReqHeadIconList()
    local msg_id = MsgIDDefine.USER_REQ_HEAD_ICON_LIST
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:NtfUserInfoChg(msg_info)
    local lastLevel = self.m_userData.level

    self:OnUserInfo(msg_info.base_info)
      
    if msg_info.reason == 1 then
        GamePromptMgr:GetInstance():InstallPrompt(CommonDefine.PROMPT_TYPE_LEVEL_UP, {lastLevel, self.m_userData.level, self.m_userData.stamina})
        GamePromptMgr:GetInstance():ShowPrompt()

        UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_ICON_REFRESH) 
        UIManagerInst:Broadcast(UIMessageNames.MN_DIANJIANG_XIEJIA_STATUS) 
    end
end

-------星盘协议
function UserManager:ReqStarPanel()
	local msg_id = MsgIDDefine.USER_REQ_STAR_PANEL
    local msg = (MsgIDMap[msg_id])()
    
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspStarPanel(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    
    self.m_copyStarCount = msg_obj.copy_star

    self.m_starMakeIDList = {}
    if msg_obj.star_makeid_list then
        for i = 1, #msg_obj.star_makeid_list do
            self.m_starMakeIDList[msg_obj.star_makeid_list[i].star_make_id] = msg_obj.star_makeid_list[i]
        end
    end
    self:SetStarPanelRedPointStatus()
    UIManagerInst:Broadcast(UIMessageNames.MN_STAR_PANEL_UPDATE)
end
 
function UserManager:ReqActiveStar(star_make_id)
	local msg_id = MsgIDDefine.USER_REQ_ACTIVE_STAR
    local msg = (MsgIDMap[msg_id])()
    msg.star_makeid = star_make_id
    
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspActiveStar(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    self:SetStarPanelRedPointStatus()
    UIManagerInst:Broadcast(UIMessageNames.MN_STAR_PANEL_ON_ACTIVE_STAR, msg_obj)

    UIManagerInst:Broadcast(UIMessageNames.MN_ASSITS_TASK_STAR_PANEL_ACTIVE)
end

function UserManager:NtfStarChg(msg_obj)
    if not msg_obj then
        return
    end
    self.m_copyStarCount = msg_obj.copy_star
    self.m_starMakeIDList = {}
    if msg_obj.star_makeid_list then
        for i = 1, #msg_obj.star_makeid_list do
            self.m_starMakeIDList[msg_obj.star_makeid_list[i].star_make_id] = msg_obj.star_makeid_list[i]
        end
    end
    self:SetStarPanelRedPointStatus()
    UIManagerInst:Broadcast(UIMessageNames.MN_NTF_STAR_CHG)
end

function UserManager:ReqRandomName()
    local msg_id = MsgIDDefine.USER_REQ_RANDOM_NAME
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspRandomName(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_RANDOM_NAME, msg_obj.name)
end

function UserManager:ReqCreateRole(userName)
    local msg_id = MsgIDDefine.USER_REQ_CREATE_USER
    local msg = (MsgIDMap[msg_id])()
    msg.name = userName
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspCreateRole(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    self.m_userData.name = msg_obj.name
    UIManagerInst:Broadcast(UIMessageNames.MN_USER_CREATE_ROLE)
end

function UserManager:GetCopyStarCount()
    return self.m_copyStarCount or 0
end

function UserManager:CheckStarIsActive(star_make_id)
    return self.m_starMakeIDList[star_make_id] ~= nil
end 

function UserManager:GetStarMakeIDList()
    return self.m_starMakeIDList
end

function UserManager:CheckHaveGetStarBoxAward(starID)
    local star = self.m_starMakeIDList[starID]
    if star then
        return star.taken_award_flag ~= 0
    end
    return false
end

function UserManager:ReqTakeActiveStarAward(star_id)
	local msg_id = MsgIDDefine.USER_REQ_TAKE_ACTIVE_STAR_AWARD
    local msg = (MsgIDMap[msg_id])()
    msg.star_makeid = star_id
    
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspTakeActiveStarAward(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local awardList = PBUtil.ParseAwardList(msg_obj.award_item_list)    
    local uiData = 
    {
        openType = 1,
        awardDataList = awardList,
    }

    self:SetStarPanelRedPointStatus()
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function UserManager:SetStarPanelRedPointStatus()
    local status = false

    for i = 1, 8 do
        local tempData = UILogicUtil.GetStarCfgListByLayer(i)
        if tempData then
            for j = 1, #tempData do
                local starItemCfg = tempData[j]
                local _, count = UILogicUtil.GetStarBoxAwardList(starItemCfg)
                
                if count > 0 then
                    local hadGot = self:CheckHaveGetStarBoxAward(starItemCfg.id)
                    local haveActive = self:CheckStarIsActive(starItemCfg.id)
                    local isCanGet = not hadGot and haveActive   --没有被领取并且是激活状态的
                    if isCanGet then 
                        status = true
                        break
                    else
                        local isActive = self:CheckStarIsActive(starItemCfg.id)
                        --只要有一个未激活且数量足够 
                        local totalStarCount = self:GetCopyStarCount()
                        local costStarCount = starItemCfg.star_count
                        local isEnough = totalStarCount >= costStarCount
                        if not isActive and isEnough then 
                            status = true
                            break
                        end
                    end
                end
            end
        end
    end 

    if not status then 
        self:DeleteRedPointID(SysIDs.STAR_PANEL)   
    else    
        self:AddRedPointId(SysIDs.STAR_PANEL)    
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_ICON_REFRESH_RED_POINT)

    UIManagerInst:Broadcast(UIMessageNames.MN_MAINLINE_XIANYUAN_RED_POINT, status)
end
------------------------------

function UserManager:ReqFightWarData()
	local msg_id = MsgIDDefine.USER_REQ_ZHENGZHAN_PANEL
    local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspFightWarData(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    UIManagerInst:Broadcast(UIMessageNames.MN_FIGHTWAR_INFO, msg_obj.act_copy_list)
end

function UserManager:NtfMoneyChg(msg_obj)
    local userData = self.m_userData
    if userData.yuanbao ~= msg_obj.yuanbao then
        userData.yuanbao = msg_obj.yuanbao
        UIManagerInst:Broadcast(UIMessageNames.MN_GOLD_CHG)
    end
end

function UserManager:ReqUserDetail(uid)
    local msg_id = MsgIDDefine.USER_REQ_QUERY_USER_BRIEF
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspUserDetail(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    local briefClass = require("DataCenter.UserData.UserDetailParam")
    local userDetailParam = briefClass.New()
    userDetailParam.userBrief = PBUtil.ConvertUserBriefProtoToData(msg_obj.user_brief_info)
    userDetailParam.personalSignature = msg_obj.personal_signature

	userDetailParam.arenaRank = msg_obj.arena_rank
	userDetailParam.arenaDan = msg_obj.arena_dan
    userDetailParam.jungong = msg_obj.jungong
    
    for _, v in ipairs(msg_obj.def_wujiang_brief_list) do
        local one_wujiang_info = PBUtil.ConvertWujiangBriefProtoToData(v)
        if one_wujiang_info then
            table_insert(userDetailParam.defWujiangBriefList, one_wujiang_info)
        end
    end

    userDetailParam.defPower = msg_obj.def_power
	userDetailParam.achievement = msg_obj.achievement
	userDetailParam.warcraftUserTitle = msg_obj.warcraft_user_title

    UIManagerInst:Broadcast(UIMessageNames.MN_USER_DETAIL, userDetailParam)
end

function UserManager:ReqSetSignature(sig)
    local msg_id = MsgIDDefine.USER_REQ_SET_PERSONAL_SIGNATURE
    local msg = (MsgIDMap[msg_id])()
    msg.personal_signature = sig
    
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspSetSignature(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(Language.GetString(2733))
    end
end

function UserManager:ReqTakeVipLevelGift(vip_level)
    local msg_id = MsgIDDefine.VIP_REQ_TAKE_VIPLEVELGIFT_AWARD
    local msg = (MsgIDMap[msg_id])()
    msg.vip_level = vip_level
 
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspTakeVipLevelGift(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
    self:SetVipRedPointStatus()
    local awardList = PBUtil.ParseAwardList(msg_obj.award_list) 
    UIManagerInst:Broadcast(UIMessageNames.MN_VIP_GIFT_TAKEN, awardList)
end

function UserManager:NtfVipLevelChg(msg_obj)
    self.m_userData.vip_level = msg_obj.vip_level
    self.m_userData.vip_exp = msg_obj.vip_exp
    
    self:SetVipRedPointStatus()
    UIManagerInst:Broadcast(UIMessageNames.MN_VIP_CHG, self.m_userData.vip_level, self.m_userData.vip_exp)
end

function UserManager:ReqAllData()
	local msg_id = MsgIDDefine.USER_REQ_ALL_USER_DATA
	local msg = (MsgIDMap[msg_id])()
	msg.app_version = '1.1.1'
	msg.res_version = '1.1.1'
	msg.reason = 1
	msg.battle_version = BattleEnum.BATTLE_VERSION
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:OnRspAllData(msg_obj)
	local playerInstance = Player:GetInstance()
	playerInstance:SetGameInit(true)

	self:OnUserInfo(msg_obj.base_info)
	self:NtfActivitySetting(msg_obj)

	local item_list = msg_obj.item_list
	-- Logger.Log('OnRspAllData itemCount: '.. #item_list)
	playerInstance:GetItemMgr():OperateItemList(item_list)

	local shenbing_list = msg_obj.shenbing_list
	-- Logger.Log('OnRspAllData shenbingCount: '.. #shenbing_list)
	playerInstance:GetShenBingMgr():OperateShenBingList(shenbing_list)

	local wujiang_list = msg_obj.wujiang_list
	-- Logger.Log('WUJIANG, ' .. table.dump(wujiang_list))
	playerInstance.WujiangMgr:OperateWuJiangList(wujiang_list)

	local horse_list = msg_obj.horse_list
	-- Logger.Log('OnRspAllData horseCount: '.. #horse_list)
	playerInstance:GetMountMgr():OperateHorseList(horse_list)

	local inscription_case_list = msg_obj.inscription_case_list
	-- Logger.Log('OnRspAllData inscription_case Count: '.. #inscription_case_list)
	playerInstance.InscriptionMgr:OperateInscriptionCaseList(inscription_case_list)

    if not GuideMgr:GetInstance():IsPlayingGuide(GuideEnum.GUIDE_MAINLINE) then
    	playerInstance:GetLineupMgr():RefreshAllLineup(msg_obj.buzhen_list)
    end
	playerInstance:GetGodBeastMgr():InitGodBeastInfo(msg_obj.dragon_list)

	playerInstance:GetGodBeastMgr():InitGodBeastInfo(msg_obj.dragon_list)

	playerInstance:GetFriendMgr():ReqFriendList()
    playerInstance:GetFriendMgr():ReqBlackList()
    playerInstance:GetActMgr():ReqActList() 
    playerInstance:GetTaskMgr():ReqSevenDayInfo() --七天  

	if SceneManagerInst:IsLoginScene() then
		local sceneConfig = SceneConfig.HomeScene

		if not msg_obj.base_info.name or msg_obj.base_info.name == '' then
			sceneConfig = SceneConfig.PlotScene
        end
        
		local downloadList = {}
		local bRet = SceneManagerInst:CheckDownload(sceneConfig, downloadList)
		if bRet then
			ABTipsMgr:GetInstance():ShowABLoadTips(downloadList, function()
				SceneManagerInst:SwitchScene(sceneConfig)
			end)
		else
			SceneManagerInst:SwitchScene(sceneConfig)
		end
	end

	local intimacy_list = playerInstance.WujiangMgr:ConvertIntimacyList(msg_obj.intimacy_list)  
	local finalIntimacyList = playerInstance.WujiangMgr:SortMapIntimacyList(intimacy_list)
    playerInstance.WujiangMgr:SetFinalIntimacyList(finalIntimacyList)
    
    self:ReportLogin()
end

function UserManager:ReportLogin()
    local PlatformMgrInst = PlatformMgr:GetInstance()
    if PlatformMgrInst:IsInternalVersion() or Setting.GetLoginReportURL() == '' then
        return
    end

    local msg = {
        server_id = PlatformMgrInst:GetServerID(),
        uid = self.m_userData.uid,
        account = PlatformMgrInst:GetLoginUID(),
        user_name = self.m_userData.name,
        icon = self.m_userData.use_icon_data.icon,
        level = self.m_userData.level,
        icon_box = self.m_userData.use_icon_data.icon_box,
    }
    SimpleHttp.HttpPost(Setting.GetLoginReportURL(), nil, DataUtils.StringToBytes(Json.encode(msg)), function(www)
        if www and www.error and www.error ~= '' then
            Logger.LogError("ReportUserInfo Error : " .. www.error)
        end
    end)
end

function UserManager:ReqSetGuided(guideID)
	local msg_id = MsgIDDefine.USER_REQ_SET_GUIDED
	local msg = (MsgIDMap[msg_id])()
	msg.guide_id = guideID
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspSetGuided(msg_obj)
    if msg_obj.guide_id == GuideEnum.GUIDE_ARENA1 then
        GuideMgr:GetInstance():ClearWaitList()
    else
        GuideMgr:GetInstance():CheckAndPerformGuide()
    end
end

function UserManager:NtfGuideFlagChg(msg_obj)
    self.m_guideFlag = msg_obj.guide_flags | (msg_obj.guide_flags_ex << 32)
end

function UserManager:ReqReportGuideDetail(int1, int2, int3, str1, str2, str3)
    local msg_id = MsgIDDefine.USER_REQ_REPORT_GUIDE_DETAIL
    local msg = (MsgIDMap[msg_id])()
    
    msg.int1 = int1 or 0
    msg.int2 = int2 or 0
    msg.int3 = int3 or 0
    msg.str1 = str1 or ''
    msg.str2 = str2 or ''
    msg.str3 = str3 or ''
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspReportGuideDetail()
end


function UserManager:IsGuided(guideID)
    return (self.m_guideFlag & (1 << guideID)) ~= 0
end

function UserManager:NtfServerNotice(msg_obj)
    local str = msg_obj.server_notice
    if msg_obj.uid == self.m_userData.uid then 
         if not self.m_typeServerNoticelist[msg_obj.type] then
            self.m_typeServerNoticelist[msg_obj.type] = {}
         end
         table_insert(self.m_typeServerNoticelist[msg_obj.type], str)
    else
        self:AddServerNotice(str) 
        if #self.m_serverNoticeList <= 1 then
            UIManagerInst:Broadcast(UIMessageNames.MN_USER_SERVER_NOTICE)
        end  
    end 
end

function UserManager:InsertServerNoticeByType(type)
    local typeNotice = self.m_typeServerNoticelist[type]
    if typeNotice then
        for i = 1, #typeNotice do
            local str = typeNotice[i]
            self:AddServerNotice(str) 

            if #self.m_serverNoticeList <= 1 then
                UIManagerInst:Broadcast(UIMessageNames.MN_USER_SERVER_NOTICE)
            end
        end
        self.m_typeServerNoticelist[type] = {} 
    end 
end

function UserManager:AddServerNotice(str)
    if str then
        table_insert(self.m_serverNoticeList, str)
    end
end

function UserManager:GetServerNoticList()
    return self.m_serverNoticeList
end

function UserManager:DeleteOneServerNotice()
    if #self.m_serverNoticeList > 0 then
        table.remove(self.m_serverNoticeList, 1)
    end
end

----------------------------------------------------

function UserManager:SetVipRedPointStatus()
    local isAllTaken = self.m_userData:IsAllVipLevelGiftTaken()
    if isAllTaken then
        self:DeleteRedPointID(SysIDs.SHANG_CHENG)   
    else    
        self:AddRedPointId(SysIDs.SHANG_CHENG)   
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_ICON_REFRESH_RED_POINT)
    UIManagerInst:Broadcast(UIMessageNames.MN_SHOP_PRIVILEGE_RED_POINT, isAllTaken) 
end 
------------------------------------------------------------
function UserManager:NtfRedPointList(msg_obj)
    self:AddRedPointIDList(msg_obj.redpoint_list)
    
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_ICON_REFRESH_RED_POINT)  

    local starPanelRedPointStatus = self:GetRedPoint(SysIDs.STAR_PANEL)  
    UIManagerInst:Broadcast(UIMessageNames.MN_MAINLINE_XIANYUAN_RED_POINT, starPanelRedPointStatus)
end

function UserManager:GetRedPointList()
    return self.m_redPointIdList or {}
end

function UserManager:AddRedPointIDList(id_list) 
    if id_list then
        for i = 1, #id_list do
            local tempId = id_list[i]
            self.m_redPointIdList[tempId] = true
        end
    end
end

function UserManager:AddRedPointId(id) 
    local tempData = self.m_redPointIdList[id]
    self.m_redPointIdList[id] = true
end 

function UserManager:DeleteRedPointID(id)
    local tempData = self.m_redPointIdList[id]
    self.m_redPointIdList[id] = false
end 

function UserManager:GetRedPoint(id)
    local isExist = false
    if self.m_redPointIdList[id] then
        isExist = true
    end

    return isExist
end

function UserManager:IsTakeDownloadAward()
    return self.m_userData.take_download_award_flag == 1
end

function UserManager:IsShowDownloadRedPoint()
    return not self:IsTakeDownloadAward() and self.m_isShowDownloadRedPoint
end

function UserManager:HideDownloadRedPoint()
    self.m_isShowDownloadRedPoint = false
end

function UserManager:ReqTakeDownloadAward()
    local msg_id = MsgIDDefine.USER_REQ_TAKE_DOWNLOAD_AWARD
    local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UserManager:RspTakeDownloadAward(msg_obj)
    local uiData = {
        openType = 1,
        awardDataList = PBUtil.ParseAwardList(msg_obj.award_list),
    }

    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function UserManager:IsNeedDownloadAB()
    return AssetBundleMgrInst:GetAllNeedDownloadABSize() > 0
end
------------------------------------------------------

return UserManager