local string_format = string.format
local tostring = tostring
local table_insert = table.insert
local table_sort = table.sort
local math_ceil = math.ceil
local string_split = string.split
local GameObject = CS.UnityEngine.GameObject
local PlayerPrefs = CS.UnityEngine.PlayerPrefs
local Language = Language
local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local ConfigUtil = ConfigUtil
local CommonDefine = CommonDefine
local CountryTypeDefine = CountryTypeDefine

local UIWuJiangCardItem = require "UI.UIWuJiang.View.UIWuJiangCardItem"
local UIEmployWujiangCardItem = require "UI.Lineup.EmployWujiangItem"

local UIWuJiangSelectView = BaseClass("UIWuJiangSelectView", UIBaseView)
local base = UIBaseView

local WuJiangMgr = Player:GetInstance().WujiangMgr
local CardItemPath = TheGameIds.CommonWujiangCardPrefab
local EmployItemPath = TheGameIds.EmployWujiangItemPrefab
local Tab_Type = {
    Myself = 1,
    Employ = 2,
}

function UIWuJiangSelectView:OnCreate()
    base.OnCreate(self)
    self.m_wujiang_card_list = {}
    self.m_seq = 0
    self.m_employWujiangItemList = {}
    self.m_employLoadSeq = 0
    -- 这两个变量用来传递各模块特殊的数据，不够可以再加，或者换个实现方式
    self.m_data1 = nil
    self.m_data2 = nil
    self.m_curTabType = Tab_Type.Myself

    self.m_sortBtnText, self.m_countrySortBtnText, self.m_employBtnText, self.m_employDesText,self.m_employTimesText = UIUtil.GetChildTexts(self.transform, {
        "WuJiangBag/bg/top/btnGrid/SortBtn/FitPos/SortBtnText",
        "WuJiangBag/bg/top/btnGrid/CountrySortBtnBtn/FitPos/CountrySortBtnText",
        "WuJiangBag/bg/top/btnGrid/employBtn/FitPos/employBtnText",
        "WuJiangBag/bg/top/employ/employDesText",
        "WuJiangBag/bg/top/employ/employTimesText",
    })
    self.m_wujiangBagContent, self.m_sortBtn, self.m_countrySortBtn, self.m_employBtn, self.m_employTr,
    self.m_employRootGO, self.m_employItemContent, self.m_itemRootGO, self.m_closeBtn = UIUtil.GetChildTransforms(self.transform, {
        "WuJiangBag/bg/ItemScrollView/Viewport/ItemContent",
        "WuJiangBag/bg/top/btnGrid/SortBtn",
        "WuJiangBag/bg/top/btnGrid/CountrySortBtnBtn",
        "WuJiangBag/bg/top/btnGrid/employBtn",
        "WuJiangBag/bg/top/employ",
        "WuJiangBag/bg/EmployItemScrollView",
        "WuJiangBag/bg/EmployItemScrollView/Viewport/EmployItemContent",
        "WuJiangBag/bg/ItemScrollView",
        "CloseBtn",
    })

    self.m_employGo = self.m_employTr.gameObject
    self.m_employRootGO = self.m_employRootGO.gameObject
    self.m_itemRootGO = self.m_itemRootGO.gameObject
    self.m_scrollView = self:AddComponent(LoopScrowView, "WuJiangBag/bg/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateWuJiangItem))
    self.m_employScrollView = self:AddComponent(LoopScrowView, "WuJiangBag/bg/EmployItemScrollView/Viewport/EmployItemContent", Bind(self, self.UpdateEmployWuJiangItem))
    self.m_countryBtnImage = UIUtil.AddComponent(UIImage, self, "WuJiangBag/bg/top/btnGrid/CountrySortBtnBtn", AtlasConfig.DynamicLoad)
    self.m_employBtnImage = UIUtil.AddComponent(UIImage, self, "WuJiangBag/bg/top/btnGrid/employBtn", AtlasConfig.DynamicLoad)

    self.m_sortPriorityTexts = string_split(Language.GetString(640), "|")
    self.m_sortPriority = 2 --1星级2等级3突破次数4稀有度
    self.m_countryTexts = string_split(Language.GetString(641), "|")
    self.m_employBtnText.text = Language.GetString(1110)
    self.m_employDesText.text = Language.GetString(1112)
end

function UIWuJiangSelectView:OnAddListener()
	base.OnAddListener(self)
	-- UI消息注册
    self:AddUIListener(UIMessageNames.MN_WUJIANG_DEV_CARD_ITEM_SELECT, self.SelectWuJiangCardItem)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_DATA_CHG, self.UpdateData)
    self:AddUIListener(UIMessageNames.MN_FRIEND_EMPLOY_LIST, self.OnRspEmployWujiangList)
    self:AddUIListener(UIMessageNames.MN_LINEUP_SELECT_EMPLOY_WUJIANG, self.OnSelectEmployWuJiangItem)
end

function UIWuJiangSelectView:OnRemoveListener()
	base.OnRemoveListener(self)
    -- UI消息注销
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_DEV_CARD_ITEM_SELECT, self.SelectWuJiangCardItem)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_DATA_CHG, self.UpdateData)
    self:RemoveUIListener(UIMessageNames.MN_FRIEND_EMPLOY_LIST, self.OnRspEmployWujiangList)
    self:RemoveUIListener(UIMessageNames.MN_LINEUP_SELECT_EMPLOY_WUJIANG, self.OnSelectEmployWuJiangItem)
end

function UIWuJiangSelectView:SelectWuJiangCardItem(wujiangIndex)
    UIManagerInst:Broadcast(UIMessageNames.MN_WUJIANG_SELECT, wujiangIndex, self.m_data1, self.m_data2)
    self:CloseSelf()
end

function UIWuJiangSelectView:OnSelectEmployWuJiangItem(employBriefData)

end

function UIWuJiangSelectView:UpdateWuJiangItem(item, realIndex)
    if self.m_wujiangList then
        if item and realIndex > 0 and realIndex <= #self.m_wujiangList then
            local data = self.m_wujiangList[realIndex]
            item:SetData(data, true)
        end
    end
end

function UIWuJiangSelectView:UpdateEmployWuJiangItem(item, realIndex)
    if self.m_employWujiangList then
        if item and realIndex > 0 and realIndex <= #self.m_employWujiangList then
            local data = self.m_employWujiangList[realIndex]
            item:SetData(data, self.m_leftEmployTimes)
        end
    end
end

function UIWuJiangSelectView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
   
    UIUtil.AddClickEvent(self.m_countrySortBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_sortBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_employBtn.gameObject, onClick)
end

function UIWuJiangSelectView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_countrySortBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_sortBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_employBtn.gameObject)
end

function UIWuJiangSelectView:OnEnable(...)
   
    base.OnEnable(self, ...)

    local initOrder
    initOrder, self.m_data1, self.m_data2 = ...

    self.m_countrySortType = CommonDefine.COUNTRY_5
    local wujiangSort = PlayerPrefs.GetInt("wujiangSort")
    if wujiangSort and wujiangSort > 0 then
        self.m_sortPriority = wujiangSort 
    else
        self.m_sortPriority = 2--1星级2等级3突破次数4稀有度
    end
    
    self.m_curTabType = Tab_Type.Myself

    if self:CanEmployWujiang() then
        Player:GetInstance():GetFriendMgr():ReqFriendsRentoutWuJiangPanel()
        self.m_employBtn.gameObject:SetActive(true)
        self.m_employGo:SetActive(true)
    else
        self.m_employBtn.gameObject:SetActive(false)
        self.m_employGo:SetActive(false)
    end
    
    self:UpdateData()
    self:HandleClick()
end

function UIWuJiangSelectView:UpdateData()
    if self.m_curTabType == Tab_Type.Employ then
        self.m_countryBtnImage:SetAtlasSprite("ty31.png")
        self.m_employBtnImage:SetAtlasSprite("ty32.png")
        self.m_employRootGO:SetActive(true)
        self.m_itemRootGO:SetActive(false)
        self:UpdateEmployWuJiangBag()
    else
        self.m_countryBtnImage:SetAtlasSprite("ty32.png")
        self.m_employBtnImage:SetAtlasSprite("ty31.png")
        self.m_employRootGO:SetActive(false)
        self.m_itemRootGO:SetActive(true)
        self:UpdateWuJiangBag()
    end
end

function UIWuJiangSelectView:OnClick(go, x, y)
    if go.name == "CountrySortBtnBtn" then
        if self.m_curTabType == Tab_Type.Myself then
            local index = -1
            for i = 1, #CountryTypeDefine do
                if CountryTypeDefine[i] == self.m_countrySortType then
                    index = i
                    break
                end
            end
            self.m_countrySortType = CountryTypeDefine[index + 1]
            if self.m_countrySortType > CommonDefine.COUNTRY_4 then
                self.m_countrySortType = CommonDefine.COUNTRY_5
            end
        else
            self.m_curTabType = Tab_Type.Myself
        end

        self:UpdateData()
    elseif go.name == "SortBtn" then
        self.m_sortPriority = self.m_sortPriority + 1
            
        if self.m_sortPriority > CommonDefine.WUJIANG_SORT_PRIORITY_4 then
            self.m_sortPriority = CommonDefine.WUJIANG_SORT_PRIORITY_1
        end
        PlayerPrefs.SetInt("wujiangSort", self.m_sortPriority)
       self:UpdateData()
    elseif go.name == "CloseBtn" then
        self:CloseSelf()
    elseif go.name == "employBtn" then
        self.m_curTabType = Tab_Type.Employ
        self:UpdateData()
    end
end

function UIWuJiangSelectView:GetCardItemClass()
    return UIWuJiangCardItem
end

function UIWuJiangSelectView:UpdateWuJiangBag()
    if self.m_curTabType ~= Tab_Type.Myself then
        return
    end

    self:GetWuJiangList()
   
    if #self.m_wujiang_card_list == 0 and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(self.m_seq, CardItemPath, 36, function(objs)
            self.m_seq = 0
            if objs then
                for i = 1, #objs do
                    local cardItem = self:GetCardItemClass().New(objs[i], self.m_wujiangBagContent, CardItemPath)
                    table_insert(self.m_wujiang_card_list, cardItem)
                end

                self:UpdateScrollView()
            end
        end)
    else
        self:UpdateScrollView()
    end

    if self.m_sortPriority <= #self.m_sortPriorityTexts then
        self.m_sortBtnText.text = self.m_sortPriorityTexts[self.m_sortPriority]
    end

    if self.m_countrySortType <= #self.m_countryTexts then
        self.m_countrySortBtnText.text = self.m_countryTexts[self.m_countrySortType + 1]
    end
end

function UIWuJiangSelectView:UpdateScrollView()
    self.m_scrollView:UpdateView(true, self.m_wujiang_card_list, self.m_wujiangList)

    coroutine.start(function()
        coroutine.waitforframes(5)
        TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
    end)
end

function UIWuJiangSelectView:GetWuJiangList()
    local wujiangList = WuJiangMgr:GetWuJiangList(function(data, wujiangCfg)
        data.sortNum = 0
        if wujiangCfg.country == self.m_countrySortType or self.m_countrySortType == CommonDefine.COUNTRY_5 then
            data.sortNum = WuJiangMgr:GetSortNum(data, self.m_sortPriority)
            return true
        end
    end)

    table_sort(wujiangList, function(l, r)
        if l.sortNum ~= r.sortNum then
            return l.sortNum > r.sortNum
        end
        return l.id < r.id
    end)

    self.m_wujiangList = WuJiangMgr:ConvertToWuJiangBriefList(wujiangList)
end

function UIWuJiangSelectView:OnRspEmployWujiangList(leftEmployTimes)
    self.m_leftEmployTimes = leftEmployTimes
    self.m_employTimesText.text = string_format(Language.GetString(1111), leftEmployTimes)
    self:UpdateData()
end

function UIWuJiangSelectView:UpdateEmployWuJiangBag()
    self.m_employWujiangList = Player:GetInstance():GetFriendMgr():GetSortEmployWuJiangList(self.m_sortPriority)

    if self.m_curTabType ~= Tab_Type.Employ or not self.m_employWujiangList then
        return
    end

    if #self.m_employWujiangItemList == 0 and self.m_employLoadSeq == 0 then
        self.m_employLoadSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(self.m_employLoadSeq, EmployItemPath, 36, function(objs)
            self.m_employLoadSeq = 0
            if objs then
                for i = 1, #objs do
                    local cardItem = UIEmployWujiangCardItem.New(objs[i], self.m_employItemContent, EmployItemPath)
                    table_insert(self.m_employWujiangItemList, cardItem)
                end

                self.m_employScrollView:UpdateView(true, self.m_employWujiangItemList, self.m_employWujiangList)
            end
        end)
    else
        self.m_employScrollView:UpdateView(true, self.m_employWujiangItemList, self.m_employWujiangList)
    end

    if self.m_sortPriority <= #self.m_sortPriorityTexts then
        self.m_sortBtnText.text = self.m_sortPriorityTexts[self.m_sortPriority]
    end

    if self.m_countrySortType <= #self.m_countryTexts then
        self.m_countrySortBtnText.text = self.m_countryTexts[self.m_countrySortType + 1]
    end
end

function UIWuJiangSelectView:OnDisable()
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_employLoadSeq)
    self.m_employLoadSeq = 0
    
    for _,item in pairs(self.m_wujiang_card_list) do
        item:Delete()
    end
    self.m_wujiang_card_list = {}
    for _,item in pairs(self.m_employWujiangItemList) do
        item:Delete()
    end
    self.m_employWujiangItemList = {}
    
    self.m_wujiangList = nil
    self.m_employWujiangList = nil
    self:RemoveClick()

    base.OnDisable(self)
end

function UIWuJiangSelectView:CanEmployWujiang()
    return true
end



return UIWuJiangSelectView