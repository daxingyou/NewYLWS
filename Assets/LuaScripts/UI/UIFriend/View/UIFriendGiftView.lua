local UIUtil = UIUtil
local Language = Language
local ConfigUtil = ConfigUtil
local table_insert = table.insert
local string_format = string.format
local LoopScrollView = LoopScrowView
local ItemMgr = Player:GetInstance():GetItemMgr()
local FriendMgr = Player:GetInstance():GetFriendMgr()
local BagItemClass = require("UI.UIBag.View.BagItem")
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()

local UIFriendGiftView = BaseClass("UIFriendGiftView", UIBaseView)
local base = UIBaseView

local MAX_ITEM_SHOW_COUNT = 24

function UIFriendGiftView:OnCreate()
    base.OnCreate(self)

    self:InitView()
    
    self:HandleClick()
end

function UIFriendGiftView:InitView()
    self.m_blackBgTrans,
    self.m_itemGridTrans
    = UIUtil.GetChildRectTrans(self.transform, {
        "blackBg",
        "winPanel/itemScrollView/itemGrid",
    })

    self.m_loopScrollView = self:AddComponent(LoopScrollView, self.m_itemGridTrans, Bind(self, self.UpdateItem))

    self.m_itemList = {}
    self.m_itemListLoadSeq = nil
    self.m_currShowItemDataList = nil

    self.m_friendData = nil
end

function UIFriendGiftView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_blackBgTrans.gameObject)

    self.m_blackBgTrans = nil
    self.m_itemGridTrans = nil

    if self.m_loopScrollView then
        self.m_loopScrollView:Delete()
        self.m_loopScrollView = nil
    end
    
    self.m_currShowItemDataList = nil
    
    self:RecycleItemList()
    self.m_itemList = nil
    self.m_itemListLoadSeq = nil

    self.m_friendData = nil

    base.OnDestroy(self)
end

function UIFriendGiftView:HandleClick()
    UIUtil.AddClickEvent(self.m_blackBgTrans.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
end

function UIFriendGiftView:OnClick(go, x, y)
    if not go then
        return
    end
    local goName = go.name
    if goName == "blackBg" then
        self:CloseSelf()
    end
end

function UIFriendGiftView:OnEnable(initOrder, friendData)
    base.OnEnable(self)

    if not friendData then
        return
    end

    self.m_friendData = friendData
    self:UpdateView()
end

function UIFriendGiftView:OnDisable()
    base.OnDisable(self)
end

function UIFriendGiftView:OnAddListener()
    base.OnAddListener(self)
    
    self:AddUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
end

function UIFriendGiftView:OnRemoveListener()
    base.OnRemoveListener(self)
    
    self:RemoveUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
end

function UIFriendGiftView:UpdateView()
    local cfgList = ConfigUtil.GetFriendGiftCfgList()
    if not cfgList then
        return
    end
    self.m_currShowItemDataList = {}
    for k, cfg in pairs(cfgList) do
        if cfg then
            local itemData = ItemMgr:GetItemData(cfg.id)
            if itemData then
                local itemCfg = itemData:GetItemCfg()
                if itemCfg and not itemData:GetLockState() then
                    table_insert(self.m_currShowItemDataList, itemData)
                end
            end
        end
    end
    if #self.m_itemList == 0 then
        self.m_itemListLoadSeq = UIGameObjectLoaderInstance:PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObjects(self.m_itemListLoadSeq, BagItemPrefabPath, MAX_ITEM_SHOW_COUNT,
        function(objs)
            self.m_itemListLoadSeq = 0
            if IsNull(objs) then
                return
            end

            for i = 1, #objs do
                local bagItem = BagItemClass.New(objs[i], self.m_itemGridTrans, BagItemPrefabPath)
                if bagItem then
                    table_insert(self.m_itemList, bagItem)
                end
            end
            self:ResetScrollView()
        end)
    else
        self:ResetScrollView()
    end
end

--重置ItemScrollView
function UIFriendGiftView:ResetScrollView()
    self.m_loopScrollView:UpdateView(true, self.m_itemList, self.m_currShowItemDataList)
end

function UIFriendGiftView:UpdateItem(item, realIndex)
    if not item or realIndex <= 0 or realIndex > #self.m_currShowItemDataList then
        return
    end
    local itemData = self.m_currShowItemDataList[realIndex]
    local itemCfg = itemData:GetItemCfg()
    local itemCount = itemData:GetItemCount()
    local itemIconParam = ItemIconParam.New(itemCfg, itemCount, itemCfg.nColor, 0, function(item)
        if not item then
            return
        end
        local itemCfg = item:GetItemCfg()
        if not itemCfg then
            return
        end
        local friendGiftCfg = ConfigUtil.GetFriendGiftCfgByID(itemCfg.id)
        if not friendGiftCfg then
            return
        end
        if not self.m_friendData or not self.m_friendData.friend_brief then
            return
        end
        local titleMsg = Language.GetString(3042)
        local btn1Msg = Language.GetString(10)
        local btn2Msg = Language.GetString(50)
        local contentMsg = string_format(Language.GetString(3043), itemCfg.sName, friendGiftCfg.friendship, friendGiftCfg.qingyi)
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, titleMsg, contentMsg, btn1Msg, function()
            FriendMgr:ReqSendGift(self.m_friendData.friend_brief.uid, itemCfg.id, 1)
        end, btn2Msg, nil, true)
    end)
    item:UpdateData(itemIconParam)
end

function UIFriendGiftView:RecycleItemList()
    if self.m_itemListLoadSeq ~= 0 then
        UIGameObjectLoaderInstance:CancelLoad(self.m_itemListLoadSeq)
        self.m_itemListLoadSeq = 0
    end
    for i = 1, #self.m_itemList do
        self.m_itemList[i]:Delete()
    end
    self.m_itemList = {}
end

function UIFriendGiftView:OnItemChg(chg_item_data_list, itemChgReason)
    if not chg_item_data_list then
        return
    end
    for i = 1, #self.m_itemList do
        local bagItem = self.m_itemList[i]
        if bagItem then
            local bagItemID = bagItem:GetItemID()
            for i = 1, #chg_item_data_list do
                local itemData = chg_item_data_list[i]
                if itemData and bagItemID == itemData:GetItemID() then
                    bagItem:UpdateItemCount(itemData:GetItemCount())
                end
            end
        end
    end
end

return UIFriendGiftView