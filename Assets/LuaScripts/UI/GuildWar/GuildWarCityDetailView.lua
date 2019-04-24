local UIUtil = UIUtil
local Vector3 = Vector3
local table_insert = table.insert
local Language = Language
local ConfigUtil = ConfigUtil
local string_format = string.format
local GameObject = CS.UnityEngine.GameObject
local GuildWarMemberItem = require("UI.GuildWar.GuildWarMemberItem")
local GuildWarBuffIconItem = require("UI.GuildWar.GuildWarBuffIconItem")
local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()
local UserMgr = Player:GetInstance():GetUserMgr()


local GuildWarCityDetailView = BaseClass("GuildWarCityDetailView", UIBaseView)
local base = UIBaseView

function GuildWarCityDetailView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()

    self:InitVariable()

    self:HandleClick()
end

function GuildWarCityDetailView:OnEnable(...)
    base.OnEnable(self, ...)

    self:Reset()

    _, cityID = ...

    self.m_cityID = cityID
    
    GuildWarMgr:ReqCityInfo(cityID)
end

function GuildWarCityDetailView:OnDisable()
    for i, v in ipairs(self.m_defItemList) do
        v:Delete()
    end
    self.m_defItemList = {}

    for i, v in ipairs(self.m_buffItemList) do
        v:SetActive(false)
    end

    base.OnDisable(self)
end

function GuildWarCityDetailView:OnDestroy()
    if self.m_cityIconImage then
        self.m_cityIconImage:Delete()
        self.m_cityIconImage = nil
    end

    if self.m_ownGuildIconImage then
        self.m_ownGuildIconImage:Delete()
        self.m_ownGuildIconImage = nil
    end

    for i, v in ipairs(self.m_buffItemList) do
        v:Delete()
    end
    self.m_buffItemList = nil

    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_buzhenBtn)

    base.OnDestroy(self)
end


function GuildWarCityDetailView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_GUILDWAR_CITY_INFO, self.UpdateView)
end

function GuildWarCityDetailView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:RemoveUIListener(UIMessageNames.MN_GUILDWAR_CITY_INFO, self.UpdateView)
end

function GuildWarCityDetailView:OnClick(go, x, y)
    if go.name == "CloseBtn" then
        self:CloseSelf()
    elseif go.name == "BuzhenBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarCityLineupSelect, self.m_cityID)
    end
end

function GuildWarCityDetailView:InitView()

    local guildText
    self.m_cityNameText, self.m_guildNameText, guildText, 
    self.m_tabText, self.m_tabText2, self.m_tabText3,
    self.m_buffText, 
    self.m_buzhenBtnText, self.m_hadStationedText,
    self.m_severText
    = UIUtil.GetChildTexts(self.transform, {
        "Container/Top/cityRoot/CityNameText",
        "Container/Top/guildRoot/GuildNameText",
        "Container/Top/guildRoot/GuildText",
        "Container/Middle/TabList/TabText",
        "Container/Middle/TabList/TabText2",
        "Container/Middle/TabList/TabText3",
        "Container/Top/BuffList/BuffText",
        "Container/Bottom/BuzhenBtn/BuzhenBtnText",
        "Container/Bottom/HadStationedText",
        "Container/Top/guildRoot/severText",
    })
   
    self.m_tabText.text = Language.GetString(2315)  
    self.m_tabText2.text = Language.GetString(2324)
    self.m_tabText3.text = Language.GetString(2308)
    self.m_buffText.text = Language.GetString(2326)
    self.m_buzhenBtnText.text = Language.GetString(2327)
    self.m_hadStationedText.text = Language.GetString(2329)
    guildText.text = Language.GetString(2398)

    self.m_defItemPrefab, self.m_defItemContent,
    self.m_closeBtn, self.m_buzhenBtn, 
    self.m_hadStationedTextGo, 
    self.m_buffIconItemPrefab, self.m_buffItemParent 
    = UIUtil.GetChildTransforms(self.transform, {
        "DefItemPrefab", 
        "Container/Middle/ItemScrollView/Viewport/ItemContent", 
        "CloseBtn", 
        "Container/Bottom/BuzhenBtn", 
        "Container/Bottom/HadStationedText", 
        "BuffIconItem", 
        "Container/Top/BuffList",
    }) 

    self.m_cityIconImage = UIUtil.AddComponent(UIImage, self, "Container/Top/cityRoot/CityIconImage", AtlasConfig.DynamicLoad2)
    self.m_ownGuildIconImage = UIUtil.AddComponent(UIImage, self, "Container/Top/guildRoot/OwnGuildIconImage", AtlasConfig.DynamicLoad2)

    self.m_buffIconItemPrefab = self.m_buffIconItemPrefab.gameObject

    self.m_buzhenBtn = self.m_buzhenBtn.gameObject
    self.m_hadStationedTextGo =  self.m_hadStationedTextGo.gameObject
    self.m_defItemPrefab = self.m_defItemPrefab.gameObject
    self.m_defItemScrollView = self:AddComponent(LoopScrowView, "Container/Middle/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateDefItem))
end

function GuildWarCityDetailView:InitVariable()
    self.m_cityDetailData = false
    self.m_defItemList = {}
    self.m_buffItemList = {}
end

function GuildWarCityDetailView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_buzhenBtn, onClick)
end

function GuildWarCityDetailView:UpdateView(cityDetailData)
    
    self.m_cityDetailData = cityDetailData

    self:UpdateBaseInfo()
    
    self:UpdateDefList()
end

function GuildWarCityDetailView:UpdateBaseInfo()
    if self.m_cityDetailData then
        local def_user_list = self.m_cityDetailData.def_user_list
        local city_breif = self.m_cityDetailData.city_breif

        if city_breif then
            local cityConfig = ConfigUtil.GetGuildWarCraftCityCfgByID(city_breif.city_id)
            if cityConfig then
                self.m_cityNameText.text = cityConfig.name

                local cityIcon = UILogicUtil.GetGuildWarCityIcon(city_breif.own_guild_brief)
               
                local guildIcon
                local own_guild_brief = city_breif.own_guild_brief
                if own_guild_brief then
                    guildIcon = own_guild_brief.icon
                    self.m_guildNameText.text = own_guild_brief.name
                    self.m_severText.text = string_format(Language.GetString(2399), own_guild_brief.str_dist_id)
                end

                local guildIconCfg = ConfigUtil.GetGuildIconCfgByID(guildIcon)
                if guildIconCfg then
                    self.m_ownGuildIconImage:SetAtlasSprite(guildIconCfg.icon..".png", true)
                    self.m_ownGuildIconImage.transform.localScale = Vector3.one * 0.7
                end

                if cityIcon then
                    self.m_cityIconImage:SetAtlasSprite(cityIcon, true)
                end
            end
        end

        local isOwn = GuildWarMgr:IsOwnCity(city_breif)

        local currWarStatus = GuildWarMgr:GetWarStatus()
        self.m_buzhenBtn:SetActive(isOwn and (currWarStatus == CommonDefine.GUILDWAR_STATUS_PREPARE))
        self.m_buffItemParent.gameObject:SetActive(isOwn)

        if isOwn then
            local def_user_list = self.m_cityDetailData.def_user_list
            if def_user_list then
                --是否已驻守
                local hadStationed
                for i, v in ipairs(def_user_list) do
                    if UserMgr:CheckIsSelf(v.uid) then
                        hadStationed = true
                        break
                    end
                end
    
                self.m_buzhenBtn:SetActive(not hadStationed)
                self.m_hadStationedTextGo:SetActive(hadStationed)
            end

            --守军加成 todo
            local buff_list = GuildWarMgr:GetBuffList()
            if buff_list then
                for i, buffID in ipairs(buff_list) do
                    local buffIconItem = self.m_buffItemList[i]
                    if not buffIconItem then
                        local go = GameObject.Instantiate(self.m_buffIconItemPrefab)
                        buffIconItem = GuildWarBuffIconItem.New(go, self.m_buffItemParent)
                        table_insert(self.m_buffItemList, buffIconItem)
                        buffIconItem:SetLocalPosition(Vector3.New(30 + (i - 1) * 170, 0, 0))
                    else
                        buffIconItem:SetActive(true)
                    end

                    buffIconItem:SetData(buffID)
                end
            end
        end
        self:UpdateDefList()
    end
end

function GuildWarCityDetailView:UpdateDefList()
    if self.m_cityDetailData then
        local def_user_list = self.m_cityDetailData.def_user_list
        if def_user_list then
            if #self.m_defItemList == 0 then
                for i = 1, 7 do
                    local go = GameObject.Instantiate(self.m_defItemPrefab)
                    local defItem = GuildWarMemberItem.New(go, self.m_defItemContent)
                    table_insert(self.m_defItemList, defItem)
                end
            end

            self.m_defItemScrollView:UpdateView(true, self.m_defItemList, def_user_list)
        end
    end
end

function GuildWarCityDetailView:UpdateDefItem(item, realIndex)
    if self.m_cityDetailData then
        local isOwn = GuildWarMgr:IsOwnCity(self.m_cityDetailData.city_breif)

        local def_user_list = self.m_cityDetailData.def_user_list
        if def_user_list and item and realIndex > 0 and realIndex <= #def_user_list then
            item:UpdateData(def_user_list[realIndex], isOwn, self.m_cityID)
        end
    end
end

function GuildWarCityDetailView:Reset(isOwn)
    self.m_buzhenBtn:SetActive(false)
    self.m_hadStationedTextGo:SetActive(false)
end


return GuildWarCityDetailView