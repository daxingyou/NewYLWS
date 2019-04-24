local SplitString = CUtil.SplitString
local table_insert = table.insert
local math_floor = math.floor
local Language = Language
local string_format = string.format
local ShopTabItem = require "UI.Shop.ShopTabItem"
local ShopTabItemPath = TheGameIds.ShopTabItemPath
local ShopShelfItem = require "UI.Common.ShopShelfItem"
local ShopShelfItemPath = TheGameIds.ShopShelfItemPath

local UIShopView = BaseClass("UIShopView", UIBaseView)
local base = UIBaseView

function UIShopView:OnCreate()
    base.OnCreate(self)

    self:InitVariable()
    self:InitView()
    
    self:HandleClick()
end

function UIShopView:OnEnable(...)
    base.OnEnable(self, ...)

    local _, shopType = ...
    self.m_shopType = shopType

    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_TOP_STATE, true, nil, true)
    self:UpdateView()
end

function UIShopView:OnTweenOpenComplete()
    self.m_shopMgr:ReqShopPanel(self.m_shopType)
    self:SwitchCurrency()
end

function UIShopView:OnAddListener()
	base.OnAddListener(self)
    self:AddUIListener(UIMessageNames.MN_SHOP_GET_PANEL_INFO, self.OnRspPanelData)
    self:AddUIListener(UIMessageNames.MN_SHOP_CLICK_TAB_BTN, self.OnClickTabItem)
end

function UIShopView:OnRemoveListener()
	base.OnRemoveListener(self)
    self:RemoveUIListener(UIMessageNames.MN_SHOP_GET_PANEL_INFO, self.OnRspPanelData)
    self:RemoveUIListener(UIMessageNames.MN_SHOP_CLICK_TAB_BTN, self.OnClickTabItem)
end

function UIShopView:OnDisable()
    for _, item in pairs(self.m_tabItemList) do
        item:Delete()
    end
    self.m_tabItemList = {}

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_tabLoaderSeq)
    self.m_tabLoaderSeq = 0

    self:RecyleGoodsItem()

    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_CHG_MIDDLE_CURRENCY_TYPE, ItemDefine.YuanBao_ID)
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_TOP_STATE, true)

    base.OnDisable(self)
end

-- 初始化非UI变量
function UIShopView:InitVariable()
    self.m_shopMgr = Player:GetInstance():GetShopMgr()
    self.m_player = Player:GetInstance()
    self.m_shopType = CommonDefine.SHOP_SPECIAL
    self.m_tabNameList = SplitString(Language.GetString(3401), ',')
    self.m_tabLoaderSeq = 0
    self.m_tabItemList = {}
    self.m_goodsItemList = {}
    self.m_goodsLoadseq = 0
    self.m_goodsList = nil
    self.m_refreshTime = 0
    self.m_refreshPrice = 0
    self.m_leftRefreshTimes = 0
end

-- 初始化UI变量
function UIShopView:InitView()
    self.m_closeBtn, self.m_tabRoot, self.m_ruleBtn, self.m_itemRoot, self.m_refreshRoot, self.m_scrollViewPanel, self.m_refreshBtn = UIUtil.GetChildRectTrans(self.transform, {
        "CloseBtn",
        "bg/tab/tabGrid",
        "bg/top/ruleBtn",
        "bg/ItemScrollView/Viewport/ItemContent",
        "bg/Bottom",
        "bg/ItemScrollView",
        "bg/Bottom/refreshBtn",
    })

    self.m_refreshTimeText, self.m_refreshText, self.m_refreshCostText = UIUtil.GetChildTexts(self.transform, {
        "bg/Bottom/refreshTimeText",
        "bg/Bottom/refreshBtn/refreshText",
        "bg/Bottom/refreshCostText",
    })
    self.m_refreshRoot = self.m_refreshRoot.gameObject

    self.m_refreshText.text = Language.GetString(3400)

    self.m_scrollView = self:AddComponent(LoopScrowView, "bg/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateGoodsItem))
end

function UIShopView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_ruleBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_refreshBtn.gameObject, onClick)
end


function UIShopView:RemoveEvent()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_refreshBtn.gameObject)
end

function UIShopView:OnClick(go, x, y)
    local name = go.name
    if name == "CloseBtn" then
        self:CloseSelf()
    elseif name == "ruleBtn" then
        local tipsId = self:GetCurTipsId() 
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, tipsId) 
    elseif name == "refreshBtn" then
        local content = nil
        if self.m_leftRefreshTimes > 0 then
            content = string_format(Language.GetString(3407), self.m_refreshPrice, self.m_leftRefreshTimes)
        else
            content = string_format(Language.GetString(3406), self.m_refreshPrice, self.m_leftRefreshTimes)
        end
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(1107),content, 
        Language.GetString(3400), Bind(self, self.RereshShop))
    end
end

function UIShopView:GetCurTipsId()
    local tipsId = 0
    if self.m_shopType == CommonDefine.SHOP_SPECIAL then 
        tipsId = 101
    elseif self.m_shopType == CommonDefine.SHOP_ARENA then 
        tipsId = 109
    elseif self.m_shopType == CommonDefine.SHOP_GUILD then 
        tipsId = 111
    elseif self.m_shopType == CommonDefine.SHOP_QINGYI then
        tipsId = 134
    elseif self.m_shopType == CommonDefine.SHOP_MYSTERY then  
        tipsId = 122
    else
        tipsId = 135
    end

    return tipsId
end

function UIShopView:RereshShop()
    self.m_shopMgr:ReqRefreshShop(self.m_shopType)
end

function UIShopView:OnRspPanelData(panelData)
    self:UpdateView(panelData)
end

function UIShopView:UpdateView(panelData)
    if self.m_shopType == CommonDefine.SHOP_MYSTERY then
        self.m_refreshRoot:SetActive(true)
        self.m_scrollViewPanel.sizeDelta = Vector2.New(1190, 675)
    else
        self.m_refreshRoot:SetActive(false)
        self.m_scrollViewPanel.sizeDelta = Vector2.New(1190, 750)
    end
    self:UpdateTabItemPanel()
    self:UpdateGoodsItemPanel(panelData)
end

function UIShopView:UpdateGoodsItemPanel(panelData)
    if not panelData then
        return 
    end
    self:RecyleGoodsItem()

    self.m_goodsList = panelData.goodsList
    self.m_refreshPrice = panelData.refreshPrice
    self.m_refreshCostText.text = string_format("%d", panelData.refreshPrice)
    self.m_refreshTime = panelData.refreshTime
    self.m_leftRefreshTimes = panelData.leftRefreshTimes
    
    self.m_goodsLoadseq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObjects(self.m_goodsLoadseq, ShopShelfItemPath, #self.m_goodsList, function(objs)
        self.m_goodsLoadseq = 0
        if objs then
            for i = 1, #objs do
                local shelfItem = ShopShelfItem.New(objs[i], self.m_itemRoot, ShopShelfItemPath)
                table_insert(self.m_goodsItemList, shelfItem)
            end

            self.m_scrollView:UpdateView(true, self.m_goodsItemList, self.m_goodsList)
        end
    end)
end

function UIShopView:UpdateTabItemPanel()
    if #self.m_tabItemList == 0 then
        if self.m_tabLoaderSeq == 0 then
            self.m_tabLoaderSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObjects(self.m_tabLoaderSeq, ShopTabItemPath, 6, function(objs)
                self.m_tabLoaderSeq = 0
                if objs then
                    for i = 1, #objs do
                        local tabItem = ShopTabItem.New(objs[i], self.m_tabRoot, ShopTabItemPath)
                        tabItem:SetData(i, self.m_tabNameList[i], i == self.m_shopType)
                        table_insert(self.m_tabItemList, tabItem)
                    end
                end
            end)
        end
    else
        for i, item in ipairs(self.m_tabItemList) do
            item:SetData(i, self.m_tabNameList[i], i == self.m_shopType)
        end
    end
end

function UIShopView:UpdateGoodsItem(item, realIndex)
    if item and realIndex > 0 and realIndex <= #self.m_goodsList then
        item:SetData(self.m_goodsList[realIndex], self.m_shopType)
    end
end

function UIShopView:OnClickTabItem(shopType)
    if self.m_shopType == shopType then
        return
    end
    
    self.m_shopType = shopType
    self.m_shopMgr:ReqShopPanel(shopType)
    self:SwitchCurrency()
    self:UpdateView()
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_TOP_STATE, true, nil, true)
end

function UIShopView:SwitchCurrency()
    local currency = 0
    if self.m_shopType == CommonDefine.SHOP_ARENA then
        currency = ItemDefine.ArenaCoin_ID
    elseif self.m_shopType == CommonDefine.SHOP_GUILD then
        currency = ItemDefine.GuildCoin_ID
    elseif self.m_shopType == CommonDefine.SHOP_QINGYI then
        currency = ItemDefine.QingYi_ID
    elseif self.m_shopType == CommonDefine.SHOP_QUNXIONGZHULU then
        currency = ItemDefine.QunXiongZhuLu_ID
    else
        currency = ItemDefine.YuanBao_ID
    end
    
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_CHG_MIDDLE_CURRENCY_TYPE, currency)
end

function UIShopView:RecyleGoodsItem()
    for _,item in pairs(self.m_goodsItemList) do
        item:Delete()
    end
    self.m_goodsItemList = {}

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_goodsLoadseq)
    self.m_goodsLoadseq = 0

    self.m_goodsList = nil
end

function UIShopView:Update()
    if self.m_shopType == CommonDefine.SHOP_MYSTERY and self.m_refreshTime > 0 then
        local leftTime = self.m_refreshTime - self.m_player:GetServerTime()
        if leftTime <= 0 then
            leftTime = 0
        end
        local hour = math_floor(leftTime / 3600)
        leftTime = leftTime - hour * 3600
        local min = math_floor(leftTime / 60)
        local sec = leftTime - min * 60
        sec = string_format(sec < 10 and "0%d" or "%d", sec)
        min = string_format(min < 10 and "0%d" or "%d", min)
        hour = string_format(hour < 10 and "0%d" or "%d", hour)
        self.m_refreshTimeText.text = string_format(Language.GetString(3403), hour, min, sec)
    end
end

return UIShopView