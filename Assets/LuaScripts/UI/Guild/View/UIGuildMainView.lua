local math_ceil = math.ceil
local table_insert = table.insert
local string_split = string.split
local string_format = string.format
local table_dump = table.dump
local UILogicUtil = UILogicUtil
local CommonDefine = CommonDefine
local Vector3 = Vector3
local ItemDefine = ItemDefine

local UIGuildMainView = BaseClass("UIGuildMainView", UIBaseView)
local base = UIBaseView

local UIUtil = UIUtil
local ConfigUtil = ConfigUtil
local GameObject = CS.UnityEngine.GameObject
local GuildMgr = Player:GetInstance().GuildMgr
local GuildMemberItem = require "UI.Guild.View.GuildMemberItem"

function UIGuildMainView:OnCreate()
    base.OnCreate(self)

    self.m_currTab = false
    self.m_guildItemList = {}
    self.m_currSelectIndex = 1
    self.m_currSelectItem = false
    self.m_memberItemList = {}

    self:InitView()

    self:HandleClick()
end


function UIGuildMainView:InitView()

    local donationText, levelUpBtnText, declarationText, guildResourceText, guildWarText, scoreText,
    manageBtnText, logBtnText, getAwardBtnText, shopBtnText, skillBtnText, donationBtnText, activityBtnText, rankBtnText

    

    self.m_guildNameText, self.m_guildLevelText, self.m_donationSilderText,
    donationText, levelUpBtnText, declarationText, self.m_declarationContentText,
    guildResourceText, self.m_resouce1CountText, self.m_resouce2CountText, guildWarText,
    scoreText, self.m_scoreValText, manageBtnText, logBtnText, getAwardBtnText,
    self.m_memberCountText,self.m_onlineCountText, self.m_totalDonationBtnText, self.m_weeklyDonationBtnText,
    shopBtnText, skillBtnText, donationBtnText, activityBtnText, rankBtnText, self.m_rankText = UIUtil.GetChildTexts(self.transform, {
        "Container/LeftView/BaseInfo/GuildNameText",
        "Container/LeftView/BaseInfo/GuildLevelText",
        "Container/LeftView/BaseInfo/DonationSilder/DonationSilderText",
        "Container/LeftView/BaseInfo/DonationText",
        "Container/LeftView/BaseInfo/LevelUpBtn/LevelUpBtnText",
        "Container/LeftView/Declaration/DeclarationText",
        "Container/LeftView/Declaration/DeclarationContentText",
        "Container/LeftView/GuildResource/GuildResourceText",
        "Container/LeftView/GuildResource/Resouce1/Resouce1CountText",
        "Container/LeftView/GuildResource/Resouce2/Resouce2CountText",
        "Container/LeftView/GuildWar/GuildWarText",
        "Container/LeftView/GuildWar/Score/ScoreText",
        "Container/LeftView/GuildWar/Score/ScoreValText",
        "Container/LeftView/ManageBtn/ManageBtnText",
        "Container/LeftView/LogBtn/LogBtnText",
        "Container/LeftView/GetAwardBtn/GetAwardBtnText",
        "Container/RightView/TabList/MemberCountText",
        "Container/RightView/TabList/OnlineCountText",
        "Container/RightView/TabList/TotalDonationBtn/Rect/TotalDonationBtnText",
        "Container/RightView/TabList/WeeklyDonationBtn/Rect/WeeklyDonationBtnText",
        "Container/RightView/BtnGrid/ShopBtn/ShopBtnText",
        "Container/RightView/BtnGrid/SkillBtn/SkillBtnText",
        "Container/RightView/BtnGrid/DonationBtn/DonationBtnText",
        "Container/RightView/BtnGrid/ActivityBtn/ActivityBtnText",
        "Container/RightView/BtnGrid/RankBtn/RankBtnText",
        "Container/LeftView/GuildWar/RankNumText",
    })

    donationText.text = Language.GetString(1331)
    levelUpBtnText.text = Language.GetString(1344)
    declarationText.text = Language.GetString(1310)
    guildResourceText.text = Language.GetString(1332)
    guildWarText.text = Language.GetString(1333)
    scoreText.text = Language.GetString(1334)
    manageBtnText.text = Language.GetString(1336)
    logBtnText.text = Language.GetString(1337)
    getAwardBtnText.text = Language.GetString(1338)
    self.m_totalDonationBtnText.text = Language.GetString(1341)
    self.m_weeklyDonationBtnText.text = Language.GetString(1342)
    local btnTexts = string_split(Language.GetString(1343), "|")
    shopBtnText.text = btnTexts[1]
    skillBtnText.text = btnTexts[2]
    donationBtnText.text = btnTexts[3]
    activityBtnText.text = btnTexts[4]
    rankBtnText.text = btnTexts[5]

    self.m_donationSilder = UIUtil.FindSlider(self.transform, "Container/LeftView/BaseInfo/DonationSilder")
    self.m_guildIconImage = self:AddComponent(UIImage, "Container/LeftView/BaseInfo/Icon/GuildIconImage", AtlasConfig.DynamicLoad2)
    self.m_resouce1Image = self:AddComponent(UIImage, "Container/LeftView/GuildResource/Resouce1/Resouce1Image", AtlasConfig.DynamicLoad)
    self.m_resouce2Image = self:AddComponent(UIImage, "Container/LeftView/GuildResource/Resouce2/Resouce2Image", AtlasConfig.DynamicLoad)
    self.m_totalDonationImg = self:AddComponent(UIImage, "Container/RightView/TabList/TotalDonationBtn")
    self.m_weeklyDonationImg = self:AddComponent(UIImage, "Container/RightView/TabList/WeeklyDonationBtn")

    self.m_levelUpBtn, self.m_manageBtn, self.m_logBtn, self.m_getAwardBtn, self.m_manageRedPointGo,
    self.m_totalDonationBtn, self.m_weeklyDonationBtn, self.m_shopBtn, self.m_skillBtn, self.m_donationBtn,
    self.m_activityBtn, self.m_rankBtn, self.m_closeBtn, self.m_memberItemPrefab, self.m_itemContent,
    self.m_totalDonationArrowTr, self.m_weeklyDonationArrowTr, self.m_guildCoinsBtn, self.m_guildGoldBtn = UIUtil.GetChildTransforms(self.transform, {
        "Container/LeftView/BaseInfo/LevelUpBtn",
        "Container/LeftView/ManageBtn",
        "Container/LeftView/LogBtn",
        "Container/LeftView/GetAwardBtn",
        "Container/LeftView/ManageBtn/redPoint",
        "Container/RightView/TabList/TotalDonationBtn",
        "Container/RightView/TabList/WeeklyDonationBtn",
        "Container/RightView/BtnGrid/ShopBtn",
        "Container/RightView/BtnGrid/SkillBtn",
        "Container/RightView/BtnGrid/DonationBtn",
        "Container/RightView/BtnGrid/ActivityBtn",
        "Container/RightView/BtnGrid/RankBtn",
        "Panel/backBtn",
        "MemberItemPrefab", 
        "Container/RightView/ItemScrollView/Viewport/ItemContent",
        "Container/RightView/TabList/TotalDonationBtn/Rect/arrow",
        "Container/RightView/TabList/WeeklyDonationBtn/Rect/arrow",
        "Container/LeftView/GuildResource/Resouce2/Resouce2Image",
        "Container/LeftView/GuildResource/Resouce1/Resouce1Image",
    })

    self.m_manageRedPointGo = self.m_manageRedPointGo.gameObject
    self.m_memberItemPrefab = self.m_memberItemPrefab.gameObject
    self.m_sortType = 0

    self.m_scrollView = self:AddComponent(LoopScrowView, "Container/RightView/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateMemberItem))
end

function UIGuildMainView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
   
    UIUtil.AddClickEvent(self.m_levelUpBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_manageBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_logBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_getAwardBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_totalDonationBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_weeklyDonationBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_shopBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_skillBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_donationBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_activityBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_rankBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_guildCoinsBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_guildGoldBtn.gameObject, onClick)
end

function UIGuildMainView:OnClick(go, x, y)
    if go.name == "backBtn" then
       self:CloseSelf()

    elseif go.name == "DonationBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildDonation)
    elseif go.name == "LevelUpBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildLevelUp)
    elseif go.name == "ManageBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildManage)
    elseif go.name == "LogBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildLog)
    elseif go.name == "GetAwardBtn" then
        GuildMgr:ReqAwardInfo()
    elseif go.name == "ActivityBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildTask)
    elseif go.name == "RankBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildRank)
    elseif go.name == "SkillBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildSkill)
    elseif go.name == "TotalDonationBtn" then
        if not self.m_totalDonationArrowTr.gameObject.activeSelf then
            self.m_totalDonationArrowTr.gameObject:SetActive(true)
        end
        if self.m_sortType == CommonDefine.GUILD_TOTAL_DONATION_DESCENDING_ORDER then
            self.m_sortType = CommonDefine.GUILD_TOTAL_DONATION_ASCENDING_ORDER
            self.m_totalDonationArrowTr.localScale = Vector3.New(1, -1, 1)
        elseif self.m_sortType == CommonDefine.GUILD_TOTAL_DONATION_ASCENDING_ORDER then
            self.m_sortType = CommonDefine.GUILD_TOTAL_DONATION_DESCENDING_ORDER
            self.m_totalDonationArrowTr.localScale = Vector3.New(1, 1, 1)
        else
            self.m_sortType = CommonDefine.GUILD_TOTAL_DONATION_DESCENDING_ORDER
            self.m_totalDonationArrowTr.localScale = Vector3.New(1, 1, 1)
        end
        self.m_weeklyDonationArrowTr.gameObject:SetActive(false)
        self.m_totalDonationBtnText.text = string_format("<color=#FFE94B>%s</color>", Language.GetString(1341))
        self.m_weeklyDonationBtnText.text = string_format("<color=#FFFFFF>%s</color>", Language.GetString(1342))
        self.m_totalDonationImg:SetAtlasSprite("ty75.png", false, AtlasConfig.DynamicLoad)
        self.m_weeklyDonationImg:SetAtlasSprite("ty74.png", false, AtlasConfig.DynamicLoad)
        self:UpdateMemberList()
    elseif go.name == "WeeklyDonationBtn" then
        if not self.m_weeklyDonationArrowTr.gameObject.activeSelf then
            self.m_weeklyDonationArrowTr.gameObject:SetActive(true)
        end
        if self.m_sortType == CommonDefine.GUILD_WEEKLY_DONATION_DESCENDING_ORDER then
            self.m_sortType = CommonDefine.GUILD_WEEKLY_DONATION_ASCENDING_ORDER
            self.m_weeklyDonationArrowTr.localScale = Vector3.New(1, -1, 1)
        elseif self.m_sortType == CommonDefine.GUILD_WEEKLY_DONATION_ASCENDING_ORDER then
            self.m_sortType = CommonDefine.GUILD_WEEKLY_DONATION_DESCENDING_ORDER
            self.m_weeklyDonationArrowTr.localScale = Vector3.New(1, 1, 1)
        else
            self.m_sortType = CommonDefine.GUILD_WEEKLY_DONATION_DESCENDING_ORDER
            self.m_weeklyDonationArrowTr.localScale = Vector3.New(1, 1, 1)
        end
        self.m_totalDonationArrowTr.gameObject:SetActive(false)
        self.m_totalDonationBtnText.text = string_format("<color=#FFFFFF>%s</color>", Language.GetString(1341))
        self.m_weeklyDonationBtnText.text = string_format("<color=#FFE94B>%s</color>", Language.GetString(1342))
        self.m_totalDonationImg:SetAtlasSprite("ty74.png", false, AtlasConfig.DynamicLoad)
        self.m_weeklyDonationImg:SetAtlasSprite("ty75.png", false, AtlasConfig.DynamicLoad)
        self:UpdateMemberList()
    elseif go.name == "ShopBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIShop, CommonDefine.SHOP_GUILD)
    elseif go.name == "Resouce2Image" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildResourceDetail, ItemDefine.GuildTongQian_ID)
    elseif go.name == "Resouce1Image" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildResourceDetail, ItemDefine.GuildYuanBao_ID)
    end
end

function UIGuildMainView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_MYGUILD_BASEINFO_CHG, self.UpdateBaseInfo)
    self:AddUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_DETAIL, self.UpdateData)
    self:AddUIListener(UIMessageNames.MN_GUILD_EXIT, self.ExitGuild)
end

function UIGuildMainView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:RemoveUIListener(UIMessageNames.MN_MYGUILD_BASEINFO_CHG, self.UpdateBaseInfo)
    self:RemoveUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_DETAIL, self.UpdateData)
    self:RemoveUIListener(UIMessageNames.MN_GUILD_EXIT, self.ExitGuild)
end

function UIGuildMainView:ExitGuild()
    UIManagerInst:CloseWindow(UIWindowNames.UIGuildManage)
    self:CloseSelf()
end

function UIGuildMainView:OnEnable(...)
   
    base.OnEnable(self, ...)

    -- self:UpdateData()
    GuildMgr:ReqGuildDetail()   --改为每次进入界面请求
end

function UIGuildMainView:OnDisable(...)
   
    self.m_currSelectItem = false

    for i, v in ipairs(self.m_memberItemList) do
        v:Delete()
    end
    self.m_memberItemList = {}
    self.m_sortType = 0

    base.OnDisable(self)
end

function UIGuildMainView:UpdateData()

    self:UpdateBaseInfo()

    self:UpdateMemberList()
end

function UIGuildMainView:UpdateBaseInfo()
    local myGuildData = GuildMgr.MyGuildData
    if not myGuildData then
        return
    end

    if #myGuildData.red_point_list > 0 then
        for i, v in ipairs(myGuildData.red_point_list) do
            if v == 1 then
                self.m_manageRedPointGo:SetActive(true)
                break
            end
        end
    else
        self.m_manageRedPointGo:SetActive(false)
    end

    local percent = myGuildData.huoyue / myGuildData.need_huoyue
    if percent > 1 then
        percent = 1
    end

    self.m_guildNameText.text = myGuildData.name
    self.m_guildLevelText.text = string_format(Language.GetString(1345), myGuildData.level)
    if myGuildData.level >= CommonDefine.GUILD_LEVEL_LIMIT then
        self.m_donationSilderText.text = Language.GetString(1457)
        self.m_donationSilder.value = 1
    else
        self.m_donationSilder.value = percent
        self.m_donationSilderText.text = string_format(Language.GetString(1356), myGuildData.huoyue, myGuildData.need_huoyue)
    end
    self.m_declarationContentText.text = myGuildData.declaration
    self.m_scoreValText.text = myGuildData.warcraft_score
    self.m_rankText.text = string_format(Language.GetString(1335), myGuildData.rank) 
    
    local guildIconCfg = ConfigUtil.GetGuildIconCfgByID(myGuildData.icon)
    if guildIconCfg then
        self.m_guildIconImage:SetAtlasSprite(guildIconCfg.icon..".png")
    end
  
    local guildExpCfg = ConfigUtil.GetGuildExpCfgByID(myGuildData.level)
    local yuanbaoText = UILogicUtil.ChangeCountToCountAndText(myGuildData.guild_yuanbao)
    local yuanbaoLimit = UILogicUtil.ChangeCountToCountAndText(guildExpCfg.yuanbao_limit)
    local coinText = UILogicUtil.ChangeCountToCountAndText(myGuildData.guild_coin)
    local coinLimit = UILogicUtil.ChangeCountToCountAndText(guildExpCfg.coin_limit)
    self.m_resouce1CountText.text = string_format("%s/%s", yuanbaoText, yuanbaoLimit)
    self.m_resouce2CountText.text = string_format("%s/%s", coinText, coinLimit)
end

function UIGuildMainView:UpdateMemberList()
    local myGuildData = GuildMgr.MyGuildData
    if not myGuildData then
        return
    end

    if myGuildData.member_list then
        self:SortMemberList(myGuildData.member_list)
        self.m_memberCountText.text = string_format(Language.GetString(1339), #myGuildData.member_list, myGuildData.member_limit)

        local onlineCount = 0
        for i, v in ipairs(myGuildData.member_list) do 
            if v and v.off_online_time == 0 then
                onlineCount = onlineCount + 1
            end
        end 

        self.m_onlineCountText.text = string_format(Language.GetString(1340), onlineCount)

        if #self.m_memberItemList == 0 then
            for i = 1, 9 do
                local go = GameObject.Instantiate(self.m_memberItemPrefab)
                local memberItem = GuildMemberItem.New(go, self.m_itemContent)
                table_insert(self.m_memberItemList, memberItem)
            end
            self.m_scrollView:UpdateView(true, self.m_memberItemList, myGuildData.member_list)
        else
            self.m_scrollView:UpdateView(true, self.m_memberItemList, myGuildData.member_list)
        end

    end
end


function UIGuildMainView:UpdateMemberItem(item, realIndex)
    local myGuildData = GuildMgr.MyGuildData
    if not myGuildData then
        return
    end
    if myGuildData.member_list then
        if item and realIndex > 0 and realIndex <= #myGuildData.member_list then

            local data = myGuildData.member_list[realIndex]
            local itemOnClick = Bind(self, self.MemberItemOnClick)
            item:UpdateData(data, realIndex, itemOnClick, itemOnClick)
        end
    end
end

function UIGuildMainView:SortMemberList(memberList)
    table.sort(memberList, function(l,r)

        if self.m_sortType == CommonDefine.GUILD_TOTAL_DONATION_DESCENDING_ORDER then
            if l.sum_huoyue ~= r.sum_huoyue then
                return l.sum_huoyue > r.sum_huoyue
            end
        elseif self.m_sortType == CommonDefine.GUILD_TOTAL_DONATION_ASCENDING_ORDER then
            if l.sum_huoyue ~= r.sum_huoyue then
                return l.sum_huoyue < r.sum_huoyue
            end
        elseif self.m_sortType == CommonDefine.GUILD_WEEKLY_DONATION_DESCENDING_ORDER then
            if l.week_huoyue ~= r.week_huoyue then
                return l.week_huoyue > r.week_huoyue
            end
        elseif self.m_sortType == CommonDefine.GUILD_WEEKLY_DONATION_ASCENDING_ORDER then
            if l.week_huoyue ~= r.week_huoyue then
                return l.week_huoyue < r.week_huoyue
            end
        end
        
        if l.off_online_time ~= r.off_online_time then
            return l.off_online_time < r.off_online_time
        end
    
        if l.post ~= r.post then
            return l.post < r.post
        end
        
        if l.level ~= r.level then
            return l.level > r.level
        end
    
    end)

end

function UIGuildMainView:MemberItemOnClick(item)
    if not item then
        return
    end
    
    local myGuildData = GuildMgr.MyGuildData

    if self.m_currSelectItem and self.m_currSelectItem ~= item then
        self.m_currSelectItem:SetOnSelectState(false)
    end

    self.m_currSelectItem = item
    self.m_currSelectItem:SetOnSelectState(true)

    if Player:GetInstance():GetUserMgr():GetUserData().uid ~= self.m_currSelectItem.m_uid then
        local GuildData = GuildMgr.MyGuildData
        local zhanglaoText, futuanzhangText
        for i, v in pairs(GuildData.post_name_map) do
            if v.post_type == CommonDefine.GUILD_POST_DEPUTY then
                futuanzhangText = v.post_name
            elseif v.post_type == CommonDefine.GUILD_POST_MILITARY then
                zhanglaoText = v.post_name
            end
        end

        local pos = self.m_currSelectItem:GetUserIconPosition()
        if pos then
            local screenPoint = UIManagerInst.UICamera:WorldToScreenPoint(pos)
            UIManagerInst:OpenWindow(UIWindowNames.UIGuildMenu, screenPoint,
                self.m_currSelectItem:GetPost(), self.m_currSelectItem:GetUId(), futuanzhangText, zhanglaoText)
        end
    end
end

function UIGuildMainView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_levelUpBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_manageBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_logBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_getAwardBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_totalDonationBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_weeklyDonationBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_shopBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_skillBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_donationBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_activityBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_rankBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_guildCoinsBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_guildGoldBtn.gameObject)

    base.OnDestroy(self)
end

return UIGuildMainView