local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()
local GuildWarUserBriefItem = require("UI.GuildWar.GuildWarUserBriefItem")
local GuildWarFightRecordItem = require("UI.GuildWar.GuildWarFightRecordItem")
local GuildWarUserTitleBriefItem = require("UI.GuildWar.GuildWarUserTitleBriefItem")
local table_insert = table.insert
local table_sort = table.sort
local string_format = string.format
local CommonDefine = CommonDefine
local GameObject = CS.UnityEngine.GameObject
local Vector3 = Vector3
local UIUtil = UIUtil
local ConfigUtil = ConfigUtil

local PosList = {
    Vector3.New(-75, 117),
    Vector3.New(-75, -116),
    Vector3.New(262, -116)
}

local GuildWarGuildDetailView = BaseClass("GuildWarGuildDetailView", UIBaseView)
local base = UIBaseView

function GuildWarGuildDetailView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()

    self:InitVariable()

    self:HandleClick()
end

function GuildWarGuildDetailView:OnEnable(...)
    base.OnEnable(self, ...)
    
    _, guildID = ...

    if not guildID then
        guildID = Player:GetInstance():GetUserMgr():GetUserData().guild_id
    end

    GuildWarMgr:ReqGuildDetail(guildID)
end

function GuildWarGuildDetailView:OnDisable()
    for i, v in ipairs(self.m_leaderItemList) do
        v:Delete()
    end
    self.m_leaderItemList = {}

    base.OnDisable(self)
end

function GuildWarGuildDetailView:OnDestroy()	
    for i, v in ipairs(self.m_userTitleItemList) do
        v:Delete()
    end
    self.m_userTitleItemList = nil

    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_detailBtn.gameObject)

	base.OnDestroy(self)
end

function GuildWarGuildDetailView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_GUILDWAR_GUILD_DETAIL, self.UpdateView)
end

function GuildWarGuildDetailView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:RemoveUIListener(UIMessageNames.MN_GUILDWAR_GUILD_DETAIL, self.UpdateView)
end

function GuildWarGuildDetailView:OnClick(go, x, y)
    if go.name == "CloseBtn" then
        self:CloseSelf()
    elseif go.name == "DetailBtn" then
        if self.m_guildDetailData then
            local user_info_list = self.m_guildDetailData.user_info_list
            if user_info_list then
                UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarMemberList, user_info_list)
            end
        end
    end
end

function GuildWarGuildDetailView:InitView()
    self.m_guildNameText,
    self.m_rankNumText, self.m_detailBtnText,
    self.m_reportTitleText,
    self.m_produceText, self.m_produceDescText,
    self.m_occCityText, self.m_occCityDescText
    = UIUtil.GetChildTexts(self.transform, {
        "Container/Top/GuildNameText",
        "Container/Top/RankImage/RankNumText",
        "Container/Top/DetailBtn/DetailBtnText",
        "Container/Middle/ReportContainer/ReportBG/ReportTitleText",
        "Container/Bottom/ProduceText","Container/Bottom/ProduceDescText",
        "Container/Bottom/OccCityText", "Container/Bottom/OccCityDescText"
    })
   
    self.m_detailBtnText.text = Language.GetString(2334)
    self.m_produceDescText.text = Language.GetString(2293)
    self.m_occCityDescText.text = Language.GetString(2313) 
    self.m_reportTitleText.text = Language.GetString(2335) 

    self.m_userContainerTran, self.m_guildUserBriefItemPrefab,
    self.m_recordItemPrefab, self.m_recordItemContent,
    self.m_userTitleItemPrefab, self.m_topTran,
    self.m_closeBtn, self.m_detailBtn = UIUtil.GetChildTransforms(self.transform, {
        "Container/Middle/UserContainer", "GuildUserBriefItemPrefab",
        "RecordItemPrefab", "Container/Middle/ReportContainer/ItemScrollView/Viewport/ItemContent",
        "UserTitleItemPrefab", "Container/Top",
        "CloseBtn", "Container/Top/DetailBtn"
    }) 

    self.m_guildUserBriefItemPrefab = self.m_guildUserBriefItemPrefab.gameObject
    self.m_recordItemPrefab = self.m_recordItemPrefab.gameObject
    self.m_userTitleItemPrefab = self.m_userTitleItemPrefab.gameObject
  
    self.m_guildIconImage = self:AddComponent(UIImage, "Container/Top/GuildIconItem/GuildIconImage", AtlasConfig.DynamicLoad2)
    self.m_cityIconImage = self:AddComponent(UIImage, "Container/Bottom/CityIconImage", AtlasConfig.DynamicLoad2)
    self.m_atkReportScrollView = self:AddComponent(LoopScrowView, "Container/Middle/ReportContainer/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateReportItem))
end

function GuildWarGuildDetailView:InitVariable()
    self.m_guildDetailData = false

    self.m_leaderItemList = {}
    self.m_recordItemList = {}
    self.m_userTitleItemList = {}
end

function GuildWarGuildDetailView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_detailBtn.gameObject, onClick)
end

function GuildWarGuildDetailView:UpdateView(guildDetailData)
    self.m_guildDetailData = guildDetailData

    self:UpdateBaseInfo()
    
    self:UpdateGuildLeaderList()

    self:UpdateReportList()
end

function GuildWarGuildDetailView:UpdateBaseInfo()
    self:UpdateUserTitleItemList()

    local guild_brief = self.m_guildDetailData.guild_brief
    if guild_brief then
        self.m_guildNameText.text = guild_brief.name
    end
    self.m_rankNumText.text = self.m_guildDetailData.rank

    local occ_city_list = self.m_guildDetailData.occ_city_list
    local occ_city_count = occ_city_list and #occ_city_list or 0
    self.m_occCityText.text = string_format(Language.GetString(2333), occ_city_count)
    self.m_produceText.text = string_format('%d', self.m_guildDetailData.out_put_coin_num)

    local guildIconCfg = ConfigUtil.GetGuildIconCfgByID(guild_brief.icon)
    if guildIconCfg then
        self.m_guildIconImage:SetAtlasSprite(guildIconCfg.icon..".png")
    end

    local cityIcon = UILogicUtil.GetGuildWarCityIcon(guild_brief)
    if cityIcon then
        self.m_cityIconImage:SetAtlasSprite(cityIcon, true)
    end
end

function GuildWarGuildDetailView:UpdateGuildLeaderList()
    local leaderList = self:GetGuildLeaderList()
    if leaderList then
        local index = 1
        for _, v in ipairs(leaderList) do
            local go = GameObject.Instantiate(self.m_guildUserBriefItemPrefab)
            local guildWarUserBriefItem = GuildWarUserBriefItem.New(go, self.m_userContainerTran)
            table_insert(self.m_leaderItemList, guildWarUserBriefItem)

            guildWarUserBriefItem:UpdateData(v, index)
            guildWarUserBriefItem:SetAnchoredPosition(PosList[index])
            index = index + 1
        end
    end 
end

function GuildWarGuildDetailView:GetGuildLeaderList()
    if self.m_guildDetailData then
        local user_info_list = self.m_guildDetailData.user_info_list
        if user_info_list then
            local leaderList = {}
            for _, v in ipairs(user_info_list) do 
                if v.post == CommonDefine.GUILD_POST_COLONEL or v.post == CommonDefine.GUILD_POST_DEPUTY then
                    table_insert(leaderList, v)
                end
            end

            if #leaderList > 0 then
                table_sort(leaderList, function(l, r)
                    return l.post < r.post
                end)
            end
            return leaderList
        end
    end
end

function GuildWarGuildDetailView:GetUserTitleCountList()
    local countList = { } --id, count

    if self.m_guildDetailData then
        local user_info_list = self.m_guildDetailData.user_info_list
        if user_info_list then
            for _, v in ipairs(user_info_list) do 
                if v.user_title > 0 then
                    local count = countList[v.user_title] or 0
                    countList[v.user_title] = count + 1
                end
            end
        end
    end

    return countList
end

function GuildWarGuildDetailView:UpdateUserTitleItemList()
    local userTitleCountList = self:GetUserTitleCountList()
    if userTitleCountList then

        local cfgList = ConfigUtil.GetGuildWarCraftDefTitleCfgList()
        local count = #cfgList
        local dataIndex = count
        
        for i = 1, count do
            local userTitleBriefItem = self.m_userTitleItemList[i]
            if not userTitleBriefItem then
                local go = GameObject.Instantiate(self.m_userTitleItemPrefab)
                userTitleBriefItem = GuildWarUserTitleBriefItem.New(go, self.m_topTran)
                userTitleBriefItem:SetLocalPosition(Vector3.New(-355.5 + (i - 1) * 136, -29.3, 0))
                table_insert(self.m_userTitleItemList, userTitleBriefItem)
            end
            userTitleBriefItem:UpdateData(dataIndex, userTitleCountList[dataIndex] or 0)
            dataIndex = dataIndex - 1
        end
    end
end

function GuildWarGuildDetailView:UpdateReportList()
    local city_battle_record_list = self.m_guildDetailData.city_battle_record_list
    if city_battle_record_list then
        UIUtil.CreateScrollViewItemList(self.m_recordItemList, 7, self.m_recordItemPrefab, self.m_recordItemContent, GuildWarFightRecordItem)
        self.m_atkReportScrollView:UpdateView(true, self.m_recordItemList, city_battle_record_list)
   end
end

function GuildWarGuildDetailView:UpdateReportItem(item, realIndex)
    local city_battle_record_list = self.m_guildDetailData.city_battle_record_list
    if city_battle_record_list and item and realIndex > 0 and realIndex <= #city_battle_record_list then
        item:UpdateData(city_battle_record_list[realIndex])
    end
end

return GuildWarGuildDetailView