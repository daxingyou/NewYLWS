local GuildWarAchievementView = BaseClass("GuildWarAchievementView", UIBaseView)
local base = UIBaseView

local UIUtil = UIUtil
local Language = Language
local ConfigUtil = ConfigUtil
local string_format = string.format
local table_insert = table.insert

local GameObject = CS.UnityEngine.GameObject
local UserItemPrefab = TheGameIds.UserItemPrefab
local UserItemClass = require("UI.UIUser.UserItem")
local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()

local GuildWarDefRecordItem = require("UI.GuildWar.GuildWarDefRecordItem")
local GuildWarAtkRecordItem = require("UI.GuildWar.GuildWarAtkRecordItem")

function GuildWarAchievementView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()

    self:InitVariable()

    self:HandleClick()
end

function GuildWarAchievementView:OnEnable(...)
    base.OnEnable(self, ...)
    
    _, uid = ...

    GuildWarMgr:ReqAchievement(uid)
end

function GuildWarAchievementView:OnDisable()
    
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_userItemSeq)
    self.m_userItemSeq = 0

    if self.m_userItem then
        self.m_userItem:Delete()
        self.m_userItem = nil
    end

    for i, v in ipairs(self.m_defRecordItemList) do
        v:Delete()
    end
    self.m_defRecordItemList = {}

    for i, v in ipairs(self.m_atkRecordItemList) do
        v:Delete()
    end
    self.m_atkRecordItemList = {} 
    
    base.OnDisable(self)
end

function GuildWarAchievementView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_userTitleBtn.gameObject)

    base.OnDestroy(self)
end

function GuildWarAchievementView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_GUILDWAR_ACHIEVEMENT_INFO, self.UpdateView)
end

function GuildWarAchievementView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:RemoveUIListener(UIMessageNames.MN_GUILDWAR_ACHIEVEMENT_INFO, self.UpdateView)
end

function GuildWarAchievementView:OnClick(go, x, y)
    if go.name == "CloseBtn" then
        self:CloseSelf()
    elseif go.name == "UserTitleBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarUserTitle)
    end
end

function GuildWarAchievementView:InitView()

    self.m_titleText, 
    self.m_playerNameText, self.m_guildNameText,
    self.m_achievementText, self.m_achievementDescText,
    self.m_winCountText, self.m_defPercentText,
    self.m_defendTitleText, self.m_attackTitleText,
    self.m_atkTabText,  self.m_atkTabText2, 
    self.m_userTitleBtnText
    = UIUtil.GetChildTexts(self.transform, {
        "Container/Top/titleBg/titleText",
        "Container/Top/BaseInfo/PlayerNameText",
        "Container/Top/BaseInfo/GuildNameText",
        "Container/Top/BaseInfo/AchievementDescText/AchievementText",
        "Container/Top/BaseInfo/AchievementDescText",
        "Container/Top/BaseInfo/winCountText",
        "Container/Top/BaseInfo/DefPercentText",
        "Container/Middle/defendReportList/DefendBG/DefendTitleText",
        "Container/Middle/AtkReportList/AttackBG/AttackTitleText",
        "Container/Middle/AtkReportList/AtkTabText",
        "Container/Middle/AtkReportList/AtkTabText2",
        "Container/Top/UserTitleBtn/UserTitleBtnText"
    })
   
   
    self.m_titleText.text = Language.GetString(2309)
    self.m_achievementDescText.text = Language.GetString(2310)
    self.m_defendTitleText.text = Language.GetString(2313) 
    self.m_attackTitleText.text = Language.GetString(2314) 
    self.m_atkTabText.text = Language.GetString(2315)  
    self.m_atkTabText2.text = Language.GetString(2316)
    self.m_userTitleBtnText.text = Language.GetString(2323)

    self.m_userIconRoot, 
    self.m_defRecordItemPrefab, self.m_atkRecordItemPrefab, self.m_breakItemPrefab,
    self.m_defReportItemContent, self.m_atkReportItemContent, 
    self.m_closeBtn, self.m_userTitleBtn = UIUtil.GetChildTransforms(self.transform, {
        "Container/Top/UserIconRoot",
        "RecordItemPrefab", "AtkRecordItemPrefab", "BreakItemPrefab",
        "Container/Middle/defendReportList/ItemScrollView/Viewport/defendReportItemContent",
        "Container/Middle/AtkReportList/ItemScrollView/Viewport/AtkReportItemContent", 
        "CloseBtn", "Container/Top/UserTitleBtn"
    }) 

    self.m_defRecordItemPrefab = self.m_defRecordItemPrefab.gameObject
    self.m_atkRecordItemPrefab = self.m_atkRecordItemPrefab.gameObject
    self.m_breakItemPrefab = self.m_breakItemPrefab.gameObject

    self.m_userTitleIconImage = self:AddComponent(UIImage, "Container/Top/BaseInfo/UserTitleIconImage", AtlasConfig.DynamicLoad)
    self.m_guildIconImage = UIUtil.AddComponent(UIImage, self, "Container/Top/BaseInfo/GuildIconItem/GuildIconImage", AtlasConfig.DynamicLoad2)
    self.m_defReportScrollView = self:AddComponent(LoopScrowView, "Container/Middle/defendReportList/ItemScrollView/Viewport/defendReportItemContent", Bind(self, self.UpdateDefRecordItem))
    self.m_atkReportScrollView = self:AddComponent(LoopScrowView, "Container/Middle/AtkReportList/ItemScrollView/Viewport/AtkReportItemContent", Bind(self, self.UpdateAtkReportItem))
end

function GuildWarAchievementView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_userTitleBtn.gameObject, onClick)
end


function GuildWarAchievementView:InitVariable()
    self.m_achievementData = false

    self.m_userItem = false
    self.m_userItemSeq = 0

    self.m_defRecordItemList = {}
    self.m_atkRecordItemList = {}
end

function GuildWarAchievementView:UpdateView(achievementData)

    self.m_achievementData = achievementData

    if self.m_achievementData then
        self:UpdateUserIcon()

        self:UpdateBaseInfo()
    
        self:UpdateAtkReportList()
        
        self:UpdateDefReportList()
    end
end

function GuildWarAchievementView:UpdateUserIcon()
    local guildUserBriefData = self.m_achievementData.guildUserBriefData
    if not guildUserBriefData then
        return
    end

    function loadCallBack()
        self.m_userItem:UpdateData(guildUserBriefData.use_icon_data.icon, guildUserBriefData.use_icon_data.icon_box, guildUserBriefData.level)
    end

    --更新玩家头像信息
    if self.m_userItem then
        loadCallBack()
    else
        if self.m_userItemSeq == 0 then
            self.m_userItemSeq = UIGameObjectLoaderInst:PrepareOneSeq()
            UIGameObjectLoaderInst:GetGameObject(self.m_userItemSeq, UserItemPrefab, function(obj)
                self.m_userItemSeq = 0
                if not obj then
                    return
                end
                self.m_userItem = UserItemClass.New(obj, self.m_userIconRoot, UserItemPrefab)
                loadCallBack()
            end)
        end
    end
end

function GuildWarAchievementView:UpdateBaseInfo()
    local guildUserBriefData = self.m_achievementData.guildUserBriefData
    if not guildUserBriefData then
        return
    end

    --称号
    local guildWarCraftDefTitleCfg = ConfigUtil.GetGuildWarCraftDefTitleCfgByID(guildUserBriefData.user_title)
    if guildWarCraftDefTitleCfg then
        self.m_userTitleIconImage:SetAtlasSprite(guildWarCraftDefTitleCfg.icon..".png")
    end

    self.m_playerNameText.text = guildUserBriefData.user_name
    self.m_guildNameText.text = guildUserBriefData.guild_name
    self.m_achievementText.text = string_format('%d', guildUserBriefData.jungong) 
   
    self.m_winCountText.text = string_format(Language.GetString(2311), self.m_achievementData.curr_break_count)
    self.m_defPercentText.text = string_format(Language.GetString(2312), guildUserBriefData.win_rate)

    local guildIconCfg = ConfigUtil.GetGuildIconCfgByID(guildUserBriefData.guild_icon)
    if guildIconCfg then
        self.m_guildIconImage:SetAtlasSprite(guildIconCfg.icon..".png", true)
    end
end

function GuildWarAchievementView:UpdateAtkReportList()
    local offence_city_record_list = self.m_achievementData.offence_city_record_list
    if offence_city_record_list then
        if #self.m_atkRecordItemList == 0 then
            for i = 1, 7 do
                local go = GameObject.Instantiate(self.m_atkRecordItemPrefab)
                local recordItem = GuildWarAtkRecordItem.New(go, self.m_atkReportItemContent)
                table_insert(self.m_atkRecordItemList, recordItem)
            end
        end
        
        self.m_atkReportScrollView:UpdateView(true, self.m_atkRecordItemList, offence_city_record_list)
   end
end

function GuildWarAchievementView:UpdateAtkReportItem(item, realIndex)
    local offence_city_record_list = self.m_achievementData.offence_city_record_list
    if offence_city_record_list and item and realIndex > 0 and realIndex <= #offence_city_record_list then
        item:UpdateData(offence_city_record_list[realIndex], self.m_breakItemPrefab)
    end
end

function GuildWarAchievementView:UpdateDefReportList()
    local def_fight_list = self.m_achievementData.def_fight_list
    if def_fight_list then
        if #self.m_defRecordItemList == 0 then
            for i = 1, 7 do
                local go = GameObject.Instantiate(self.m_defRecordItemPrefab)
                local recordItem = GuildWarDefRecordItem.New(go, self.m_defReportItemContent)
                table_insert(self.m_defRecordItemList, recordItem)
            end
        end
        self.m_defReportScrollView:UpdateView(true, self.m_defRecordItemList, def_fight_list)
   end
end

function GuildWarAchievementView:UpdateDefRecordItem(item, realIndex)
    local def_fight_list = self.m_achievementData.def_fight_list
    if def_fight_list and item and realIndex > 0 and realIndex <= #def_fight_list then
        item:UpdateData(def_fight_list[realIndex])
    end
end

return GuildWarAchievementView