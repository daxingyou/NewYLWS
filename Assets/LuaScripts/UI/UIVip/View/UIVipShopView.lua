local SplitString = CUtil.SplitString
local table_insert = table.insert
local math_floor = math.floor
local Language = Language
local string_format = string.format
local PBUtil = PBUtil
local ShopTabItem = require "UI.Shop.ShopTabItem"
local ShopTabItemPath = TheGameIds.ShopTabItemPath
local VipShopGoodsItem = require "UI.UIVip.View.VipShopGoodsItem"
local VipShopGoodsItemPath = TheGameIds.VipShopGoodsItemPath

local UIVipShopView = BaseClass("UIVipShopView", UIBaseView)
local base = UIBaseView

function UIVipShopView:OnCreate()
    base.OnCreate(self)

    self:InitVariable()
    self:InitView()
    
    self:HandleClick()
end

function UIVipShopView:OnEnable(...)
    base.OnEnable(self, ...)

    self.m_shopType = CommonDefine.VIP_SHOP_YUANBAO

    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_TOP_STATE, true, nil, true)
    self:UpdateView()  

    local userData = Player:GetInstance():GetUserMgr():GetUserData()
    if userData then
        local isAllTaken = userData:IsAllVipLevelGiftTaken()
        self.m_privilegeBtnRedPointImgTr.gameObject:SetActive(not isAllTaken)
    end 
end

function UIVipShopView:OnTweenOpenComplete()
    self.m_shopMgr:ReqVipShopPanel(self.m_shopType)
end

function UIVipShopView:OnAddListener()
	base.OnAddListener(self)
    self:AddUIListener(UIMessageNames.MN_VIP_SHOP_GET_PANEL_INFO, self.OnRspPanelData)
    self:AddUIListener(UIMessageNames.MN_SHOP_CLICK_TAB_BTN, self.OnClickTabItem)
    self:AddUIListener(UIMessageNames.MN_SHOP_PRIVILEGE_RED_POINT, self.OnPrivilegeRedPoint)
    -- self:AddUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
end

function UIVipShopView:OnRemoveListener()
	base.OnRemoveListener(self)
    self:RemoveUIListener(UIMessageNames.MN_VIP_SHOP_GET_PANEL_INFO, self.OnRspPanelData)
    self:RemoveUIListener(UIMessageNames.MN_SHOP_CLICK_TAB_BTN, self.OnClickTabItem)
    self:RemoveUIListener(UIMessageNames.MN_SHOP_PRIVILEGE_RED_POINT, self.OnPrivilegeRedPoint)
    -- self:RemoveUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
end

function UIVipShopView:OnDisable()
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
function UIVipShopView:InitVariable()
    self.m_shopMgr = Player:GetInstance():GetShopMgr()
    self.m_userManager = Player:GetInstance():GetUserMgr()
    self.m_player = Player:GetInstance()
    self.m_shopType = CommonDefine.SHOP_SPECIAL
    self.m_tabNameList = SplitString(Language.GetString(3415), ',')
    self.m_tabLoaderSeq = 0
    self.m_tabItemList = {}
    self.m_goodsItemList = {}
    self.m_goodsLoadseq = 0
    self.m_goodsList = nil
end

-- 初始化UI变量
function UIVipShopView:InitView()
    self.m_closeBtn, 
    self.m_tabRoot, 
    self.m_privilegeBtn, 
    self.m_itemRoot, 
    self.m_scrollViewPanel,
    self.m_privilegeBtnRedPointImgTr = UIUtil.GetChildRectTrans(self.transform, {
        "CloseBtn",
        "bg/tab/tabGrid",
        "bg/top/privilegeBtn",
        "bg/ItemScrollView/Viewport/ItemContent",
        "bg/ItemScrollView",
         "bg/top/privilegeBtn/RedPointImg",
    })

    self.m_privilegeText, self.m_expText, self.m_expDesText = UIUtil.GetChildTexts(self.transform, {
        "bg/top/privilegeBtn/privilegeText",
        "bg/top/expText",
        "bg/top/expDesText",
    })
    self.m_privilegeText.text = Language.GetString(3410)
    self.m_expDesText.text = Language.GetString(3411)
    self.m_privilegeBtnRedPointImgTr.gameObject:SetActive(false)

    self.m_scrollView = self:AddComponent(LoopScrowView, "bg/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateGoodsItem))
end

function UIVipShopView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_privilegeBtn.gameObject, onClick)
end


function UIVipShopView:RemoveEvent()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_privilegeBtn.gameObject)
end

function UIVipShopView:OnClick(go, x, y)
    local name = go.name
    if name == "CloseBtn" then
        self:CloseSelf()
    elseif name == "privilegeBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIVip)
    end
end

function UIVipShopView:OnRspPanelData(goodsList)
    self:UpdateView(goodsList)
end

function UIVipShopView:UpdateView(goodsList)
    self:UpdateVipExpInfo()
    self:UpdateTabItemPanel()
    self:UpdateGoodsItemPanel(goodsList)
end

function UIVipShopView:UpdateVipExpInfo()
    local myLevel = self.m_userManager:GetUserData().vip_level
    local myExp = self.m_userManager:GetUserData().vip_exp

    local myCfg = ConfigUtil.GetVipPrivilegeCfgByLvl(myLevel)
    if not myCfg then
        return
    end

    local nextCfg = ConfigUtil.GetVipPrivilegeCfgByLvl(myLevel + 1)
    if nextCfg then
        self.m_expText.text = string_format(Language.GetString(3412), myLevel, myCfg.exp - myExp, myLevel + 1)
    else
        self.m_expText.text = string_format(Language.GetString(3416), myLevel)
    end
end

function UIVipShopView:UpdateGoodsItemPanel(goodsList)
    if not goodsList then
        return 
    end
    self:RecyleGoodsItem()

    self.m_goodsList = goodsList
    
    self.m_goodsLoadseq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObjects(self.m_goodsLoadseq, VipShopGoodsItemPath, #self.m_goodsList, function(objs)
        self.m_goodsLoadseq = 0
        if objs then
            for i = 1, #objs do
                local goodsItem = VipShopGoodsItem.New(objs[i], self.m_itemRoot, VipShopGoodsItemPath)
                table_insert(self.m_goodsItemList, goodsItem)
            end

            self.m_scrollView:UpdateView(true, self.m_goodsItemList, self.m_goodsList)
        end
    end)
end

function UIVipShopView:UpdateTabItemPanel()
    if #self.m_tabItemList == 0 then
        if self.m_tabLoaderSeq == 0 then
            self.m_tabLoaderSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObjects(self.m_tabLoaderSeq, ShopTabItemPath, 2, function(objs)
                self.m_tabLoaderSeq = 0
                if objs then
                    for i = 1, #objs do
                        local shopType = i + 1
                        local tabItem = ShopTabItem.New(objs[i], self.m_tabRoot, ShopTabItemPath)
                        tabItem:SetData(shopType, self.m_tabNameList[shopType], shopType == self.m_shopType)
                        table_insert(self.m_tabItemList, tabItem)
                    end
                end
            end)
        end
    else
        for i, item in ipairs(self.m_tabItemList) do
            local shopType = i + 1
            item:SetData(shopType, self.m_tabNameList[shopType], shopType == self.m_shopType)
        end
    end
end

function UIVipShopView:UpdateGoodsItem(item, realIndex)
    if item and realIndex > 0 and realIndex <= #self.m_goodsList then
        item:SetData(self.m_goodsList[realIndex], self.m_shopType)
    end
end

function UIVipShopView:OnClickTabItem(shopType)
    if self.m_shopType == shopType then
        return
    end
    
    self.m_shopType = shopType
    self.m_shopMgr:ReqVipShopPanel(shopType)
    self:UpdateView()
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_TOP_STATE, true, nil, true)
end

function UIVipShopView:RecyleGoodsItem()
    for _,item in pairs(self.m_goodsItemList) do
        item:Delete()
    end
    self.m_goodsItemList = {}

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_goodsLoadseq)
    self.m_goodsLoadseq = 0

    self.m_goodsList = nil
end

function UIVipShopView:OnPrivilegeRedPoint(isAllTaken)
    self.m_privilegeBtnRedPointImgTr.gameObject:SetActive(not isAllTaken)
end

-- function UIVipShopView:OnItemChg(chg_item_data_list, reason)
--     if reason == CommonDefine.ItemChgReason_Vip_Charge then
--         if self.m_shopType ~= CommonDefine.VIP_SHOP_YUANBAO then
--             if chg_item_data_list then
--                 local awardList = {}
--                 local CreateAwardData = PBUtil.CreateAwardData
--                 for _, item in ipairs(chg_item_data_list) do
--                     local oneAward = CreateAwardData(item:GetItemID(), item:GetItemCount())
--                     table_insert(awardList, oneAward)
--                 end

--                 local uiData = {
--                     openType = 1,
--                     awardDataList = awardList
--                 }
--                 UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
--             end
--         end
--         self.m_shopMgr:ReqVipShopPanel(self.m_shopType)
--     end
-- end

return UIVipShopView