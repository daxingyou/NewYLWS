local GameObject = CS.UnityEngine.GameObject
local Type_Toggle = typeof(CS.UnityEngine.UI.Toggle)
local Type_ScrollRect = typeof(CS.UnityEngine.UI.ScrollRect)
local table_insert = table.insert
local table_sort = table.sort
local string_format = string.format
local string_find = string.find
local string_sub = string.sub
local math_min = math.min
local tonumber = tonumber
local UIUtil = UIUtil
local Language = Language
local CommonDefine = CommonDefine
local UIWindowNames = UIWindowNames
local UILogicUtil = UILogicUtil
local ItemMgr = Player:GetInstance():GetItemMgr()
local MountMgr = Player:GetInstance():GetMountMgr()
local ShenBingMgr = Player:GetInstance():GetShenBingMgr()
local UIManagerInstance = UIManagerInst
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()
local ItemData = ItemData
local LoopScrollView = LoopScrowView
local Vector3 = Vector3
local Vector2 = Vector2
local ConfigUtil = ConfigUtil
local DOTween = CS.DOTween.DOTween
local DOTweenSettings = CS.DOTween.DOTweenSettings
local UIBagView = BaseClass("UIBagView", UIBaseView)
local base = UIBaseView

local ScrollRectPath = "ViewContainer/ItemScrollView"
local ItemGridPath = "ViewContainer/ItemScrollView/Viewport/ItemGrid"
local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab
local BagItemClass = require("UI.UIBag.View.BagItem")
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"

local DetailItemHelperClass = require "UI.UIBag.View.DetailItemHelper"
local DetailMountHelperClass = require "UI.UIBag.View.DetailMountHelper"
local DetailShenbingHelperClass = require "UI.UIBag.View.DetailShenbingHelper"

local TabBtnName = "TabBtn_"
local MAX_ITEM_SHOW_COUNT = 24

local ItemMainTypeArr = 
{
    CommonDefine.ItemMainType_MingQian, 
    CommonDefine.ItemMainType_ShenBing,
    CommonDefine.ItemMainType_Mount, 
    CommonDefine.ItemMainType_XinWu, 
    CommonDefine.ItemMainType_OtherItem,
    CommonDefine.ItemMainType_LiBao,
}

--命签的筛选方式(只显示哪些类型的命签)
local MingQianFilterType = 
{
    0,
    CommonDefine.MingQian_SubType_Tiao,
    CommonDefine.MingQian_SubType_Tong,
    CommonDefine.MingQian_SubType_Wan,
    CommonDefine.MingQian_SubType_Dong,
    CommonDefine.MingQian_SubType_Nan,
    CommonDefine.MingQian_SubType_Xi,
    CommonDefine.MingQian_SubType_Bei,
    CommonDefine.MingQian_SubType_Zhong,
    CommonDefine.MingQian_SubType_Fa,
    CommonDefine.MingQian_SubType_Bai,
}

--坐骑的筛选方式(只显示哪些类型的坐骑)
local MountFilterType = 
{
    0,
    CommonDefine.Mount_SubType_WhiteHorse,      --坐骑[白马]
    CommonDefine.Mount_SubType_RedHorse,         --坐骑[红马]
    CommonDefine.Mount_SubType_YeollowHorse,     --坐骑[黄马]
    CommonDefine.Mount_SubType_Bear,             --坐骑[熊]
    CommonDefine.Mount_SubType_Wolf,             --坐骑[狼]
    CommonDefine.Mount_SubType_deer,             --坐骑[鹿]
    CommonDefine.Mount_SubType_rhino,            --坐骑[犀牛]
}

--信物筛选方式(只显示哪些类型的信物)
local XinWuFilterType = 
{
    0,
    CommonDefine.XinWu_SubType_N,        --信物[N]阶
    CommonDefine.XinWu_SubType_R,        --信物[R]阶
    CommonDefine.XinWu_SubType_SR,       --信物[SR]阶
    CommonDefine.XinWu_SubType_SSR,      --信物[SSR]阶
}

--神兵筛选方式(只显示哪些类型的神兵)
local ShenBingFilterType = 
{
    0,
}

--杂物筛选方式(只显示哪些类型的杂物)
local OtherItemFilterType = 
{
    0,
}

local LiBaoItemFilterType = 
{
    0,
}

--命签的排列方式
local MingQianSortType = 
{
    CommonDefine.SortByStageDecrease,
    CommonDefine.SortByStageIncrease,
    CommonDefine.SortByCountDecrease,
    CommonDefine.SortByCountIncrease,
}

--神兵的排列方式
local ShenBingSortType = 
{
    CommonDefine.SortByStageDecrease,
    CommonDefine.SortByStageIncrease,
}

--坐骑的排列方式
local MountSortType = 
{
    CommonDefine.SortByStageDecrease,
    CommonDefine.SortByStageIncrease,
}

--信物的排列方式
local XinWuSortType = 
{
    CommonDefine.SortByStageDecrease,
    CommonDefine.SortByStageIncrease,
    CommonDefine.SortByCountDecrease,
    CommonDefine.SortByCountIncrease,
}

--杂物的排列方式
local OtherItemSortType = 
{
    CommonDefine.SortByCountDecrease,
    CommonDefine.SortByCountIncrease,
    CommonDefine.SortByStageDecrease,
    CommonDefine.SortByStageIncrease,
}

function UIBagView:OnCreate()
    base.OnCreate(self)

    self:InitView()

    self:CreateTabBtnGroup()

    self:HandleClick()
end

function UIBagView:InitView()
    self.m_switchTypeBtn, self.m_sortBtn, self.m_switchItemTypeBtnPrefab, self.m_tabBtnGrid, 
    self.m_maskBg, 
    self.m_viewBgTrans, self.m_viewport,
    self.m_itemGridTrans, self.m_viewContainer = 
    UIUtil.GetChildRectTrans(self.transform, {
        "ViewContainer/SwitchTypeBtn",
        "ViewContainer/SortBtn",
        "ViewContainer/TabBtnGroupBg/SwitchItemTypeBtnPrefab",
        "ViewContainer/TabBtnGroupBg/TabBtnGrid",
        "MaskBg",
        "ViewContainer/ViewBg",
        "ViewContainer/ItemScrollView/Viewport",
        ItemGridPath,
        "ViewContainer",
    })

    self.m_switchTypeBtnText, self.m_sortBtnText, self.m_itemCountText
    = UIUtil.GetChildTexts(self.transform, {
        "ViewContainer/SwitchTypeBtn/FitPos/SwitchTypeBtnText",
        "ViewContainer/SortBtn/FitPos/SortBtnText",
        "ViewContainer/ItemCountText",
    })
    
    self.m_seqList = {}
    self.m_itemList = {}
    self.m_tabBtnToggleList = {}      --缓存的是Toggle
    self.m_isShowItemDetail = false
    self.m_itemDetailTmpItem = nil      --用于展示新品详细信息的临时item
    self.m_currSelectItem = nil         --当前选中的item（显示物品详细信息）
    self.m_currShowItemDataList = nil   --当前需要显示的所有物品数据列表
    self.m_recordItemCountArr = {}
    self.m_currItemType = CommonDefine.ItemMainType_MingQian
    self.m_showItemFilterTypeArr = {}   --设置每一个主类型物品的默认筛选方式为0(All)
    for i = 1, #ItemMainTypeArr do
        self.m_showItemFilterTypeArr[ItemMainTypeArr[i]] = 1
    end
    self.m_recordOpenToggleMainTypeList = {}        --记录打开过的标签的主类型

    --物品排列顺序的方式
    self.m_itemSortTypeArr = {}
    for i = 1, #ItemMainTypeArr do
        self.m_itemSortTypeArr[ItemMainTypeArr[i]] = 1
    end

    --初始化ScrollRect
    self._onscrollRectMove = function(vec2)
        if self.m_isShowItemDetail then
            print('---打开的同时被关闭了--------------------------------------------------------')
            self:ChgItemDetailShowState(false)
        end
    end
    self.m_scrollRect = self.transform:Find(ScrollRectPath):GetComponent(Type_ScrollRect)
    -- self.m_scrollRect.onValueChanged:AddListener(self._onscrollRectMove)

    self.m_loopScrollView = self:AddComponent(LoopScrollView, ItemGridPath, Bind(self, self.UpdateBagItem))

    local defaultHelper = DetailItemHelperClass.New(self.transform, self)
    self.m_detailHelpers = {
        [CommonDefine.ItemMainType_MingQian] = defaultHelper,
        [CommonDefine.ItemMainType_ShenBing] = DetailShenbingHelperClass.New(self.transform, self),
        [CommonDefine.ItemMainType_Mount] = DetailMountHelperClass.New(self.transform, self),
        [CommonDefine.ItemMainType_XinWu] = defaultHelper,
        [CommonDefine.ItemMainType_OtherItem] = defaultHelper,
        [CommonDefine.ItemMainType_LiBao] = defaultHelper,
    }
end

function UIBagView:OnDestroy()
    self.m_switchTypeBtn = nil
    self.m_sortBtn = nil
    self.m_switchItemTypeBtnPrefab = nil 
    self.m_tabBtnGrid = nil 
    self.m_maskBg = nil 
    self.m_viewBgTrans = nil 
    self.m_viewport = nil 
    self.m_itemGridTrans = nil

    self.m_switchTypeBtnText = nil 
    self.m_sortBtnText = nil 
    self.m_itemCountText = nil 
    self.m_itemNameText = nil
    self.m_itemAttrText = nil 
    self.m_itemDescText = nil
    
    
    self.m_itemList = nil
    self.m_tabBtnToggleList = nil
    self.m_isShowItemDetail = nil
    self.m_itemDetailTmpItem = nil
    self.m_currSelectItem = nil
    self.m_currShowItemDataList = nil
    self.m_currItemType = nil
    self.m_showItemFilterTypeArr = nil
    self.m_itemSortTypeArr = nil
    self.m_recordItemCountArr = nil
    self.m_recordOpenToggleMainTypeList = nil

    if self.m_scrollRect then
        if self._onscrollRectMove then
            self.m_scrollRect.onValueChanged:RemoveListener(self._onscrollRectMove)
        end
        self.m_scrollRect = nil
    end
    self._onscrollRectMove = nil
    
    if self.m_loopScrollView then
        self.m_loopScrollView:Delete()
        self.m_loopScrollView = nil
    end

    for _, helper in pairs(self.m_detailHelpers) do
        if helper then
            helper:Delete()
        end
    end
    self.m_detailHelpers = nil

    base.OnDestroy(self)
end

function UIBagView:CreateTabBtnGroup()
    local tabNameIDList = {2010, 2011, 2012, 2013,  2014, 2070, 2015, 2016, 2017, 2018, 2019}
    local tabBtnPrefab = self.m_switchItemTypeBtnPrefab.gameObject
	tabBtnPrefab:SetActive(true)
    local GetChildTexts = UIUtil.GetChildTexts
    for i = 1, #ItemMainTypeArr do
        local itemType = ItemMainTypeArr[i]
        local tabBtn = GameObject.Instantiate(tabBtnPrefab)
        if not IsNull(tabBtn) then
            --设置标签按钮名字
            tabBtn.name = TabBtnName..ItemMainTypeArr[i]
            --设置标签按钮的大小和位置
            local tabBtnTrans = tabBtn.transform
            tabBtnTrans:SetParent(self.m_tabBtnGrid)
            tabBtnTrans.localScale = Vector3.one
            tabBtnTrans.localPosition = Vector3.zero
            --缓存所有标签按钮
            local btn_toggle = tabBtn:GetComponent(Type_Toggle)
            if btn_toggle then
                self.m_tabBtnToggleList[itemType] = btn_toggle
            end
            --设置标签按钮的文本
            local tabBtnText = GetChildTexts(tabBtnTrans, {"SwitchItemTypeBtnText"})
            if not IsNull(tabBtnText) and i <= #tabNameIDList then
                tabBtnText.text = Language.GetString(tabNameIDList[i])
            end
        end
    end
    tabBtnPrefab:SetActive(false)
end

function UIBagView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_maskBg.gameObject)
    UIUtil.RemoveClickEvent(self.m_switchTypeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_sortBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_viewBgTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_viewport.gameObject)

    for _,tabBtnToggle in pairs(self.m_tabBtnToggleList) do
        if tabBtnToggle then
            local tabBtn = tabBtnToggle.gameObject
            if tabBtn then
                UIUtil.RemoveClickEvent(tabBtn, onClick)
            end
        end
    end
end

function UIBagView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_maskBg.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_switchTypeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_sortBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_viewBgTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_viewport.gameObject, onClick)

    for _,tabBtnToggle in pairs(self.m_tabBtnToggleList) do
        if tabBtnToggle then
            local tabBtn = tabBtnToggle.gameObject
            if tabBtn then
                UIUtil.AddClickEvent(tabBtn, onClick)
            end
        end
    end
end

function UIBagView:OnClick(go, x, y)
    if IsNull(go) then
        return
    end

    local goName = go.name
    if string_find(goName, TabBtnName) then
        local startIndex, endIndex = string_find(goName, TabBtnName)
        local itemTypeStr = string_sub(goName, endIndex + 1, #goName)
        local itemType = tonumber(itemTypeStr)

        self:ChgItemDetailShowState(false)

        self.m_currItemType = itemType
        self:UpdateCurrShowType()

    elseif goName == "MaskBg" then
        if self.m_isShowItemDetail then
            self:ChgItemDetailShowState(false)
            return
        end

        self:CloseSelf()
        return

    elseif goName == "SwitchTypeBtn" then
        self:ChgItemDetailShowState(false)
        self:OnSwitchFilterType()

    elseif goName == "SortBtn" then
        self:ChgItemDetailShowState(false)
        self:OnSwitchSortType()
    end
end

function UIBagView:OnEnable(...)
    base.OnEnable(self, ...)

    self.m_recordOpenToggleMainTypeList = {}

    self.m_delayCreateItem = false
    self.m_createCountRecord = 0
    UIManagerInst:SetUIEnable(false)

    self:UpdateRecordItemCountArr()

    self:ChgItemDetailShowState(false)

    self:TweenOpen()
end

function UIBagView:OnDisable(...)
    self:RecycleItemList()

    self:ClearItemDetailContainer()

    self.m_currShowItemDataList = nil
    self.m_recordItemCountArr = {}

    ItemMgr:ClearNewGetItemDictByType(self.m_recordOpenToggleMainTypeList)

    for i, v in pairs(self.m_seqList) do
        UIGameObjectLoaderInstance:CancelLoad(i)
    end
    self.m_seqList = {}

    base.OnDisable(self, ...)
end

function UIBagView:GetCurrSelectBagItem()
    return self.m_currSelectItem
end

function UIBagView:OnSwitchFilterType()
    local filterTypeIndex = self.m_showItemFilterTypeArr[self.m_currItemType]
    local filterTypeArr = self:GetItemFilterTypeArr()
    if filterTypeIndex and filterTypeArr then
        local typeArrLen = #filterTypeArr
        if filterTypeIndex > 0 and filterTypeIndex <= typeArrLen then
            if typeArrLen > 1 then
                filterTypeIndex = filterTypeIndex + 1
            end
            if filterTypeIndex > typeArrLen then
                filterTypeIndex = (filterTypeIndex) % typeArrLen
            end
            self.m_showItemFilterTypeArr[self.m_currItemType] = filterTypeIndex
        end
    end

    self:UpdateSwitchTypeBtnName()

    self:UpdateItemList()
end

function UIBagView:OnSwitchSortType()
    local sortTypeIndex = self.m_itemSortTypeArr[self.m_currItemType]
    local sortTypeArr = self:GetItemSortTypeArr()
    if sortTypeIndex and sortTypeArr then
        local typeArrLen = #sortTypeArr
        if sortTypeIndex > 0 and sortTypeIndex <= typeArrLen then
            if typeArrLen > 1 then
                sortTypeIndex = sortTypeIndex + 1
            end
            if sortTypeIndex > typeArrLen then
                sortTypeIndex = sortTypeIndex % typeArrLen
            end
            self.m_itemSortTypeArr[self.m_currItemType] = sortTypeIndex
        end
    end

    self:UpdateSortBtnName()

    self:UpdateItemList()
end

--更新当前显示的物品类型
function UIBagView:UpdateCurrShowType()

    self:UpdateSwitchTypeBtnName()

    self:UpdateSortBtnName()
    
    self:UpdateTabBtn()

    self:UpdateItemList()
end

--更新类型切换按钮的文本
function UIBagView:UpdateSwitchTypeBtnName()
    self.m_recordOpenToggleMainTypeList[ItemMainTypeArr[self.m_currItemType]] = true
    local switchTypeBtnName = self:GetFilterNameByType()
    if switchTypeBtnName then
        self.m_switchTypeBtnText.text = switchTypeBtnName
    end
end

--更新排列顺序按钮的文本
function UIBagView:UpdateSortBtnName()
    local sortTypeBtnName = self:GetSortTypeName()
    if sortTypeBtnName then
        self.m_sortBtnText.text = sortTypeBtnName
    end
end

--切换标签按钮
function UIBagView:UpdateTabBtn()
    local tabBtnToggle = self.m_tabBtnToggleList[self.m_currItemType]
    if tabBtnToggle then
        tabBtnToggle.isOn = true
    end
end

--更新物品列表
function UIBagView:UpdateItemList()
    --先获取到所有需要显示的物品数据列表
    self.m_currShowItemDataList = self:GetAllItemDataList()
    if not self.m_currShowItemDataList then
        return
    end
    
    if #self.m_itemList == 0 then
        self:CreateItemList()
    else
        self:ResetScrollView()
    end
    self:UpdateAllItemCount()
end

--创建物品列表
function UIBagView:CreateItemList()
    if #self.m_itemList > 0 then
        return
    end

    self.m_delayCreateItem = true

    self.m_loopScrollView:ResetPosition()
end

--重置ItemScrollView
function UIBagView:ResetScrollView()
    self.m_loopScrollView:UpdateView(true, self.m_itemList, self.m_currShowItemDataList)
end

--更新当前物品的数量之和
function UIBagView:UpdateAllItemCount()
    local currShowCount = 0
    if self.m_currShowItemDataList then
        for _, itemData in pairs(self.m_currShowItemDataList) do
            if itemData then
                currShowCount = currShowCount + itemData:GetItemCount()
            end
        end
    end
    local totalCount = self.m_recordItemCountArr[self.m_currItemType]
    self.m_itemCountText.text = string_format(Language.GetString(2001), currShowCount, totalCount)
end

function UIBagView:RecycleItemList()
    for _,item in pairs(self.m_itemList) do
        if item then
            item:Delete()
        end
    end
    self.m_itemList = {}
end

function UIBagView:ChgItemDetailShowState(isShow)
    self.m_isShowItemDetail = isShow
    
    if isShow then
        self:UpdateItemDetailContainer()
    else
        if self.m_currSelectItem then
            self.m_currSelectItem:SetOnSelectState(false)
            self.m_currSelectItem = nil
        end

        local helper = self:GetDetailHelper()
        if helper then
            helper:Close()
        end
    end
end

function UIBagView:UpdateItemDetailContainer()
    if not self.m_currSelectItem or self.m_currSelectItem:GetItemCount() <= 0 then
        self:ChgItemDetailShowState(false)
        return
    end

    local helper = self:GetDetailHelper()
    if helper then
        helper:UpdateInfo()
    end
end

--清除用于显示物品详细信息的缓存
function UIBagView:ClearItemDetailContainer()    
    self.m_currSelectItem = nil

    local currItemType = ItemMainTypeArr[self.m_currItemType]
    local helper = self.m_detailHelpers[currItemType]
    if helper then
        helper:Close()
    end
end

function UIBagView:UpdateBagItem(item, realIndex)
    if not item then
        return
    end
    if realIndex > #self.m_currShowItemDataList then
        return
    end
    self:UpdateBagItemData(item, self.m_currShowItemDataList[realIndex])
end

function UIBagView:UpdateBagItemData(targetBagItem, itemData)
    if not itemData then
        return
    end

    local itemCount = 1
    local currItemMainType = ItemMainTypeArr[self.m_currItemType]
    if UILogicUtil.IsNormalItem(currItemMainType) then
        itemCount = itemData:GetItemCount()
    end

    local lvl = itemData:GetStage()
    local luStage = nil
    if currItemMainType == CommonDefine.ItemMainType_ShenBing then
        lvl = UILogicUtil.GetShenBingStageByLevel(itemData:GetStage())
        luStage = itemData:GetStage()
    end
    local itemIconParam = ItemIconParam.New(itemData:GetItemCfg(), itemCount, lvl, itemData:GetIndex(), function(bagItem)
        if not bagItem then
            return
        end
    
        if self.m_currSelectItem then
            if self.m_currSelectItem ~= bagItem then
                self.m_currSelectItem:SetOnSelectState(false)
                self.m_currSelectItem = bagItem
                self:ChgItemDetailShowState(true)
            else
                self.m_currSelectItem = nil
                self:ChgItemDetailShowState(false)
            end
        else
            self.m_currSelectItem = bagItem
            self:ChgItemDetailShowState(true)
        end
    end, true, true, itemData:GetLockState(), nil, ItemMgr:CheckIsNewGet(itemData:GetItemID()), luStage)
    targetBagItem:UpdateData(itemIconParam)
end

function UIBagView:GetAllItemDataList()
    local currFilterType = self:GetItemFilterType()     --当前的筛选方式(按子类型筛选)
    local allItemDataList = {}
    local currMainItemType = ItemMainTypeArr[self.m_currItemType]
    if currMainItemType == CommonDefine.ItemMainType_MingQian or currMainItemType == CommonDefine.ItemMainType_OtherItem 
        or currMainItemType == CommonDefine.ItemMainType_LiBao then
        ItemMgr:Walk(function(itemData)
            if itemData then
                local itemCfg = itemData:GetItemCfg()
                if itemCfg and itemCfg.nShowInBag == 0 and itemCfg.sMainType == currMainItemType then
                    if currFilterType and (currFilterType == 0 or currFilterType == itemCfg.sSubType) then
                        table_insert(allItemDataList, itemData)
                    end
                end
            end
        end)
    elseif currMainItemType == CommonDefine.ItemMainType_XinWu then
        ItemMgr:Walk(function(itemData)
            if itemData then
                local itemCfg = itemData:GetItemCfg()
                if itemCfg and itemCfg.nShowInBag == 0 and itemCfg.sMainType == currMainItemType then
                    if currFilterType and (currFilterType == 0 or currFilterType == itemCfg.nColor) then
                        table_insert(allItemDataList, itemData)
                    end
                end
            end
        end)
    elseif currMainItemType == CommonDefine.ItemMainType_Mount then
        MountMgr:Walk(function(mountData)
            if mountData then
                local mountItemCfg = mountData:GetItemCfg()
                if mountItemCfg and mountItemCfg.sMainType == currMainItemType then
                    if currFilterType and (currFilterType == 0 or currFilterType == mountItemCfg.sSubType) then
                        table_insert(allItemDataList, mountData)
                    end
                end
            end
        end)
    elseif currMainItemType == CommonDefine.ItemMainType_ShenBing then
        ShenBingMgr:Walk(function(shenbingData)
            if shenbingData then
                local shenbingItemCfg = shenbingData:GetItemCfg()
                local b = (shenbingItemCfg and shenbingItemCfg.sMainType == currMainItemType)
                if shenbingItemCfg and shenbingItemCfg.sMainType == currMainItemType then
                    if currFilterType and (currFilterType == 0 or currFilterType == shenbingItemCfg.sSubType) then
                        table_insert(allItemDataList, shenbingData)
                    end
                end
            end
        end)
    end
    --对要显示的物品进行排序
    local sortFunc = self:GetSortFunc()
    if sortFunc then
        table_sort(allItemDataList, sortFunc)
    end
    return allItemDataList
end

function UIBagView:GetItemFilterType()
    local itemFilterTypes = self:GetItemFilterTypeArr()
    if itemFilterTypes then
        local currFilterIndex = self.m_showItemFilterTypeArr[self.m_currItemType]
        if currFilterIndex and currFilterIndex > 0 and currFilterIndex <= #itemFilterTypes then
            return itemFilterTypes[currFilterIndex]
        end
    end
    return nil
end

function UIBagView:GetItemFilterTypeArr()
    local itemFilterTypes = nil
    local currItemType = ItemMainTypeArr[self.m_currItemType]
    if currItemType == CommonDefine.ItemMainType_MingQian then
        itemFilterTypes = MingQianFilterType
    elseif currItemType == CommonDefine.ItemMainType_ShenBing then
        itemFilterTypes = ShenBingFilterType
    elseif currItemType == CommonDefine.ItemMainType_Mount then
        itemFilterTypes = MountFilterType
    elseif currItemType == CommonDefine.ItemMainType_XinWu then
        itemFilterTypes = XinWuFilterType
    elseif currItemType == CommonDefine.ItemMainType_OtherItem then
        itemFilterTypes = OtherItemFilterType
    elseif currItemType == CommonDefine.ItemMainType_LiBao then
        itemFilterTypes = LiBaoItemFilterType
    end
    return itemFilterTypes
end

function UIBagView:GetItemSortTypeArr()
    local itemSortTypes = nil
    local currItemType = ItemMainTypeArr[self.m_currItemType]
    if currItemType == CommonDefine.ItemMainType_MingQian then
        itemSortTypes = MingQianSortType
    elseif currItemType == CommonDefine.ItemMainType_ShenBing then
        itemSortTypes = ShenBingSortType
    elseif currItemType == CommonDefine.ItemMainType_Mount then
        itemSortTypes = MountSortType
    elseif currItemType == CommonDefine.ItemMainType_XinWu then
        itemSortTypes = XinWuSortType
    elseif currItemType == CommonDefine.ItemMainType_OtherItem then
        itemSortTypes = OtherItemSortType
    elseif currItemType == CommonDefine.ItemMainType_LiBao then
        itemSortTypes = OtherItemSortType
    end
    return itemSortTypes
end

--获得排序的方法
function UIBagView:GetSortFunc()
    local sortFunc = nil
    local itemSortTypes = self:GetItemSortTypeArr()
    local sortTypeIndex = self.m_itemSortTypeArr[self.m_currItemType]

    if sortTypeIndex and itemSortTypes and sortTypeIndex > 0 and sortTypeIndex <= #itemSortTypes then
        local sortType = itemSortTypes[sortTypeIndex]
        if sortType == CommonDefine.SortByCountDecrease then
            --按数量降序排序
            sortFunc = function(itemData1, itemData2)
                if itemData1 and itemData2 then
                    local itemCount1 = itemData1:GetItemCount() or 0
                    local itemCount2 = itemData2:GetItemCount() or 0
                    if itemCount1 ~= itemCount2 then
                        return itemCount1 > itemCount2
                    end
                    local itemCfg1 = itemData1:GetItemCfg()
                    local itemCfg2 = itemData2:GetItemCfg()
                    return self:BagItemDefaultSort(itemCfg1, itemCfg2)
                end
            end

        elseif sortType == CommonDefine.SortByCountIncrease then
            --按数量降序升序
            sortFunc = function(itemData1, itemData2)
                if itemData1 and itemData2 then
                    local itemCount1 = itemData1:GetItemCount() or 0
                    local itemCount2 = itemData2:GetItemCount() or 0
                    if itemCount1 ~= itemCount2 then
                        return itemCount1 < itemCount2
                    end
                    local itemCfg1 = itemData1:GetItemCfg()
                    local itemCfg2 = itemData2:GetItemCfg()
                    return self:BagItemDefaultSort(itemCfg1, itemCfg2)
                end
            end

        elseif sortType == CommonDefine.SortByStageDecrease then
            --按品阶降序排序
            sortFunc = function(itemData1, itemData2)
                if itemData1 and itemData2 then
                    local itemStage1 = itemData1:GetStage()
                    local itemStage2 = itemData2:GetStage()
                    if itemStage1 ~= itemStage2 then
                        return itemStage1 > itemStage2
                    end
                    local itemCfg1 = itemData1:GetItemCfg()
                    local itemCfg2 = itemData2:GetItemCfg()
                    return self:BagItemDefaultSort(itemCfg1, itemCfg2)
                end
            end

        elseif sortType == CommonDefine.SortByStageIncrease then
            --按品阶升序排序
            sortFunc = function(itemData1, itemData2)
                if itemData1 and itemData2 then
                    local itemStage1 = itemData1:GetStage()
                    local itemStage2 = itemData2:GetStage()
                    if itemStage1 ~= itemStage2 then
                        return itemStage1 < itemStage2
                    end
                    local itemCfg1 = itemData1:GetItemCfg()
                    local itemCfg2 = itemData2:GetItemCfg()
                    return self:BagItemDefaultSort(itemCfg1, itemCfg2)
                end
            end

        elseif sortType == CommonDefine.SortByLevelDecrease then
            --按等级降序排序
            sortFunc = function(itemData1, itemData2)
                if itemData1 and itemData2 then
                    local itemCfg1 = itemData1:GetItemCfg()
                    local itemCfg2 = itemData2:GetItemCfg()
                    if itemCfg1 and itemCfg2 then
                        local itemColor1 = itemCfg1.nColor or 0
                        local itemColor2 = itemCfg2.nColor or 0
                        if itemColor1 ~= itemColor2 then
                            return itemColor1 < itemColor2
                        end
                    end
                    return self:BagItemDefaultSort(itemCfg1, itemCfg2)
                end
            end

        elseif sortType == CommonDefine.SortByLevelIncrease then
            --按等级降序排序
            sortFunc = function(itemData1, itemData2)
                if itemData1 and itemData2 then
                    local itemCfg1 = itemData1:GetItemCfg()
                    local itemCfg2 = itemData2:GetItemCfg()
                    if itemCfg1 and itemCfg2 then
                        local itemColor1 = itemCfg1.nColor or 0
                        local itemColor2 = itemCfg2.nColor or 0
                        if itemColor1 ~= itemColor2 then
                            return itemColor1 > itemColor2
                        end
                    end
                    return self:BagItemDefaultSort(itemCfg1, itemCfg2)
                end
            end

        end
    end
    return sortFunc
end

--物品默认排序方法
function UIBagView:BagItemDefaultSort(itemCfg1, itemCfg2)
    if itemCfg1 and itemCfg2 then
        local sSubType = itemCfg1.sSubType
        local sSubType2 = itemCfg2.sSubType
        if sSubType ~= sSubType2 then
            return sSubType < sSubType2
        end
        return itemCfg1.nBagsort > itemCfg2.nBagsort
    end
    return false
end

--获取类型筛选按钮的文本
function UIBagView:GetFilterNameByType()
    local filterName = nil
    local filterNameIDArr = nil
    local currItemType = ItemMainTypeArr[self.m_currItemType]
    if currItemType == CommonDefine.ItemMainType_MingQian then
        filterNameIDArr = {2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029}
    elseif currItemType == CommonDefine.ItemMainType_ShenBing then
        filterNameIDArr = {2019}
    elseif currItemType == CommonDefine.ItemMainType_Mount then
        filterNameIDArr = {2019, 2030, 2031, 2032, 2033, 2034, 2035, 2036}
    elseif currItemType == CommonDefine.ItemMainType_XinWu then
        filterNameIDArr = {2019, 2037, 2038, 2039, 2040}
    elseif currItemType == CommonDefine.ItemMainType_OtherItem then
        filterNameIDArr = {2019}
    elseif currItemType == CommonDefine.ItemMainType_OtherItem then
        filterNameIDArr = { 2070 }
    end
    
    if filterNameIDArr then
        local currFilterIndex = self.m_showItemFilterTypeArr[self.m_currItemType]
        if currFilterIndex and currFilterIndex > 0 and currFilterIndex <= #filterNameIDArr then
            filterName = Language.GetString(filterNameIDArr[currFilterIndex])
        end
    end
    return filterName
end

--获取排序按钮的文本
function UIBagView:GetSortTypeName()
    local sortTypeName = nil
    local currSortType = nil
    local sortTypeNameID = nil
    local currSortIndex = self.m_itemSortTypeArr[self.m_currItemType]
    local sortTypeArr = self:GetItemSortTypeArr()
    if sortTypeArr then
        currSortType = sortTypeArr[currSortIndex]
    end
    if currSortType then
        if currSortType == CommonDefine.SortByCountDecrease then
            sortTypeNameID = 2060
        elseif currSortType == CommonDefine.SortByCountIncrease then
            sortTypeNameID = 2061
        elseif currSortType == CommonDefine.SortByStageDecrease then
            sortTypeNameID = 2062
        elseif currSortType == CommonDefine.SortByStageIncrease then
            sortTypeNameID = 2063
        elseif currSortType == CommonDefine.SortByLevelDecrease then
            sortTypeNameID = 2064
        elseif currSortType == CommonDefine.SortByLevelIncrease then
            sortTypeNameID = 2065
        end
    end

    if sortTypeNameID then
        sortTypeName = Language.GetString(sortTypeNameID)
    end
    return sortTypeName
end

--增加事件监听
function UIBagView:OnAddListener()
    base.OnAddListener(self)

    self:AddUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
    self:AddUIListener(UIMessageNames.MN_MOUNT_ITEM_CHG, self.OnMountChg)
    self:AddUIListener(UIMessageNames.MN_SHENBING_ITEM_CHG, self.OnShenBingChg)
    self:AddUIListener(UIMessageNames.MN_ITEM_LOCK_CHG, self.OnLockChg)
end

--移除事件监听
function UIBagView:OnRemoveListener()
    base.OnRemoveListener(self)
    
    self:RemoveUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
    self:RemoveUIListener(UIMessageNames.MN_MOUNT_ITEM_CHG, self.OnMountChg)
    self:RemoveUIListener(UIMessageNames.MN_SHENBING_ITEM_CHG, self.OnShenBingChg)
    self:RemoveUIListener(UIMessageNames.MN_ITEM_LOCK_CHG, self.OnLockChg)
end

function UIBagView:OnItemChg(item_data_list, itemChgReason)
    self:OperateItemChg(item_data_list, itemChgReason)

    self:UpdateRecordItemCount(CommonDefine.ItemMainType_MingQian)
    self:UpdateRecordItemCount(CommonDefine.ItemMainType_XinWu)
    self:UpdateRecordItemCount(CommonDefine.ItemMainType_OtherItem)
end

function UIBagView:OnMountChg(item_data_list, itemChgReason)
    self:OperateItemChg(item_data_list, itemChgReason)

    self:UpdateRecordItemCount(CommonDefine.ItemMainType_Mount)
end

function UIBagView:OnShenBingChg(item_data_list, itemChgReason)
    self:OperateItemChg(item_data_list, itemChgReason)

    self:UpdateRecordItemCount(CommonDefine.ItemMainType_ShenBing)
end

function UIBagView:OnLockChg(param)
    if not self.m_currSelectItem then
        return
    end

    if param.item_id == self.m_currSelectItem:GetItemID() and param.index == self.m_currSelectItem:GetIndex() then
        local isLocked = param.lock == 1
        local canLock = self.m_currSelectItem:NeedShowLock()

        self.m_currSelectItem:SetLockState(isLocked)
        
        local helper = self:GetDetailHelper()
        if helper then
            helper:ChangeLock(canLock, isLocked)
        end
    end
end

function UIBagView:OperateItemChg(item_data_list, itemChgReason)
    if not item_data_list or itemChgReason == CommonDefine.ItemChgReason_Lock then
        return
    end
    --更新物品详细信息面板
    
    if itemChgReason == CommonDefine.ItemChgReason_Count then
        self:UpdateCurrShowType()

        if self.m_currSelectItem and self.m_currShowItemDataList then
            local found = false
            for _, itemData in ipairs(self.m_currShowItemDataList) do
                if self.m_currSelectItem:GetItemID() == itemData:GetItemID() then
                    found = true
                    break
                end
            end
            if not found then
                self.m_currSelectItem = nil
            end
        end
    end
    self:UpdateItemDetailContainer()
end

--记录每种类型的物品总数量
function UIBagView:UpdateRecordItemCountArr()
    for _, mainType in pairs(ItemMainTypeArr) do
        self:UpdateRecordItemCount(mainType)
    end
end

function UIBagView:GetDetailHelper()
    local currItemType = ItemMainTypeArr[self.m_currItemType]
    local helper = self.m_detailHelpers[currItemType]
    return helper
end

function UIBagView:GetCurrMainType()
    return ItemMainTypeArr[self.m_currItemType]
end

--记录相应类型的物品总数量
function UIBagView:UpdateRecordItemCount(mainType)
    if mainType == CommonDefine.ItemMainType_Mount then
        self.m_recordItemCountArr[mainType] = MountMgr:GetTotalCount(mainType)
    elseif mainType == CommonDefine.ItemMainType_ShenBing then
        self.m_recordItemCountArr[mainType] = ShenBingMgr:GetTotalCount(mainType)
    else
        self.m_recordItemCountArr[mainType] = ItemMgr:GetTotalCountByMainType(mainType)
    end
    if mainType == ItemMainTypeArr[self.m_currItemType] then
        self:UpdateAllItemCount()
    end
end

function UIBagView:TweenOpen()
    local tweener = DOTween.ToFloatValue(function()
        return 0
    end, 
    function(value)
        self.m_viewContainer.anchoredPosition = Vector3.New(500 - 500 * value, 0, 0)
    end, 1, 0.2)

    DOTweenSettings.OnComplete(tweener, function()
        self:UpdateCurrShowType()
    end)
end

function UIBagView:Update()
    if not self.m_delayCreateItem then
        return
    end

    if self.m_createCountRecord < MAX_ITEM_SHOW_COUNT then
        local seq = UIGameObjectLoaderInstance:PrepareOneSeq()
        self.m_seqList[seq] = true
        UIGameObjectLoaderInstance:GetGameObject(seq, BagItemPrefabPath, function(obj, seq)
            self.m_seqList[seq] = false
            if not IsNull(obj) then
                local bagItem = BagItemClass.New(obj, self.m_itemGridTrans, BagItemPrefabPath)
                table_insert(self.m_itemList, bagItem)

                if #self.m_itemList == MAX_ITEM_SHOW_COUNT then
                    self:ResetScrollView()
                else
                    local dataIndex = self.m_createCountRecord + 1
                    self.m_loopScrollView:UpdateOneItem(bagItem, dataIndex, #self.m_currShowItemDataList)
                end
            end
        end, seq)

        self.m_createCountRecord = self.m_createCountRecord + 1
        if self.m_createCountRecord >= MAX_ITEM_SHOW_COUNT then
            self.m_delayCreateItem = false
            UIManagerInst:SetUIEnable(true)
        end
    end
end

return UIBagView