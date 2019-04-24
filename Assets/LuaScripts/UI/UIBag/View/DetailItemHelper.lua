local Vector3 = Vector3
local Vector2 = Vector2
local string_format = string.format
local math_min = math.min
local math_floor = math.floor
local tonumber = tonumber
local ConfigUtil = ConfigUtil
local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local Language = Language
local CommonDefine = CommonDefine
local UIWindowNames = UIWindowNames
local ItemData = ItemData
local UIManagerInstance = UIManagerInst
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()
local ItemMgr = Player:GetInstance():GetItemMgr()
local WujiangMgr = Player:GetInstance():GetWujiangMgr()
local UIManagerInstance = UIManagerInst

local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab
local BagItemClass = require("UI.UIBag.View.BagItem")
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"

local DetailItemHelper = BaseClass("DetailItemHelper")

function DetailItemHelper:__init(bagTr, bagView)
    self.m_bagView = bagView

    self.m_itemDetailContainer, self.m_saleBtn, self.m_useBtn, self.m_mergeBtn, self.m_itemCreatePos, 
    self.m_mingqianMergeBtn =
    UIUtil.GetChildRectTrans(bagTr, {        
        "ItemDetailContainer",
        "ItemDetailContainer/ItemDetailBtnGroup/Sale_BTN",
        "ItemDetailContainer/ItemDetailBtnGroup/Use_BTN",
        "ItemDetailContainer/ItemDetailBtnGroup/Merge_BTN",
        "ItemDetailContainer/ItemCreatePos",
        "ItemDetailContainer/ItemDetailBtnGroup/MingQianMerge_BTN",
    })

    self.m_saleBtnText, self.m_useBtnText, self.m_mergeBtnText, self.m_itemNameText,self.m_itemAttrText, self.m_itemDescText, 
    self.m_mingqianMergeBtnText = 
    UIUtil.GetChildTexts(bagTr, {
        "ItemDetailContainer/ItemDetailBtnGroup/Sale_BTN/SaleBtnText",
        "ItemDetailContainer/ItemDetailBtnGroup/Use_BTN/UseBtnText",
        "ItemDetailContainer/ItemDetailBtnGroup/Merge_BTN/MergeBtnText",
        "ItemDetailContainer/ItemNameText",
        "ItemDetailContainer/ItemAttrText",
        "ItemDetailContainer/ItemDescText",
        "ItemDetailContainer/ItemDetailBtnGroup/MingQianMerge_BTN/MingQianMergeBtnText",
    })

    self.m_saleBtnText.text = Language.GetString(2002)
    self.m_mingqianMergeBtnText.text = Language.GetString(2066)

    self.m_itemLockSpt = bagView:AddComponent(UIImage, "ItemDetailContainer/ItemLockSpt", AtlasConfig.DynamicLoad)

    self.m_itemDetailTmpItem = nil      --用于展示新品详细信息的临时item
    self.m_bagItemSeq = 0

    self.m_showing = false
    self:HandleClick()
end

function DetailItemHelper:__delete()
    self:RemoveClick()
    self:Close()
    self.m_bagView = nil
end

function DetailItemHelper:Close()
    self.m_itemDetailContainer.gameObject:SetActive(false)

    if self.m_itemDetailTmpItem then
        self.m_itemDetailTmpItem:Delete()
        self.m_itemDetailTmpItem = nil
    end
    
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_bagItemSeq)
    self.m_bagItemSeq = 0
    self.m_showing = false
end

function DetailItemHelper:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_itemLockSpt.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_useBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_saleBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_mergeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_mingqianMergeBtn.gameObject, onClick)
end

function DetailItemHelper:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_itemLockSpt.gameObject)
    UIUtil.RemoveClickEvent(self.m_useBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_saleBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_mergeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_mingqianMergeBtn.gameObject)
end

function DetailItemHelper:OnClick(go, x, y)
    local goName = go.name

    if goName == "ItemLockSpt" then
        self:OnItemLockSptClick()
    elseif goName == "Use_BTN" then
        self:OnUseBtnClick()
    elseif goName == "Sale_BTN" then
        self:OnSaleBtnClick()
    elseif goName == "Merge_BTN" then
        self:OnMergeBtnClick()
    elseif goName == "MingQianMerge_BTN" then
        self:MergeMingQian()
    end
end


--点击物品详细信息界面的锁按钮
function DetailItemHelper:OnItemLockSptClick()
    if self.m_bagView:GetCurrSelectBagItem() then
        self.m_bagView:GetCurrSelectBagItem():ChgLockState()
    end
end

function DetailItemHelper:OnUseBtnClick()
    self:OpenItemUseWindow()
end

function DetailItemHelper:OnSaleBtnClick()
    local selectItem = self.m_bagView:GetCurrSelectBagItem()
    if not selectItem then
        return
    end
    local itemCfg = selectItem:GetItemCfg()
    if not itemCfg then
        return
    end
    local maxCount = selectItem:GetItemCount()
    local minCount = 1
    local titleName = Language.GetString(2015)
    local openReason = 2
    local confirmCallback = function(selectCount)
        ItemMgr:ReqUse(selectItem:GetItemID(), selectCount, 2)
    end
    UIManagerInstance:OpenWindow(UIWindowNames.UIBagUse, itemCfg, minCount, maxCount, openReason, confirmCallback, nil, titleName)
end

function DetailItemHelper:OnMergeBtnClick()
    local selectItem = self.m_bagView:GetCurrSelectBagItem()
    if not selectItem then
        return
    end
    local itemCfg = selectItem:GetItemCfg()
    if not itemCfg then
        return
    end

    WujiangMgr:ReqMerge(selectItem:GetItemID())
end

function DetailItemHelper:MergeMingQian()
    local selectItem = self.m_bagView:GetCurrSelectBagItem()
    if not selectItem then
        return
    end
    local itemCfg = selectItem:GetItemCfg()
    if not itemCfg then
        return
    end

    local inscriptionStageInfo = ConfigUtil.GetInscriptionStageCfgByID(itemCfg.id)
   
    if not inscriptionStageInfo then
        return
    end

    local itemCount = selectItem:GetItemCount()
    local isEnough = itemCount >= inscriptionStageInfo.cost_count

    if isEnough then
        UIManagerInst:OpenWindow(UIWindowNames.UITipsCompound, Language.GetString(2069), Language.GetString(2067), 
        inscriptionStageInfo.cost_tongqian_count, math_floor(itemCount / inscriptionStageInfo.cost_count),
        function(count)
            Player:GetInstance().InscriptionMgr:ReqMergeInscription(itemCfg.id, count)
        end
    )
    else
        UILogicUtil.FloatAlert(Language.GetString(2068))
    end
end


--打开物品使用界面
function DetailItemHelper:OpenItemUseWindow()
    local selectItem = self.m_bagView:GetCurrSelectBagItem()
    if not selectItem then
        return
    end
    local itemCfg = selectItem:GetItemCfg()
    if not itemCfg then
        return
    end
    if selectItem:GetItemID() == ItemDefine.ChangeNameCardId then
        UIManagerInstance:OpenWindow(UIWindowNames.UIChangeName)
        return
    end

    local maxCount = selectItem:GetItemCount()    
    local minCount = 1
    local titleName = Language.GetString(2008)
    local openReason = 1
    
    local confirmCallback = function(selectCount)
        ItemMgr:ReqUse(selectItem:GetItemID(), selectCount, 1)
    end
    UIManagerInstance:OpenWindow(UIWindowNames.UIBagUse, itemCfg, minCount, maxCount, openReason, confirmCallback, nil, titleName)
end

function DetailItemHelper:UpdateInfo()
    local selectItem = self.m_bagView:GetCurrSelectBagItem()
    if not selectItem or selectItem:GetItemCount() <= 0 then
        return
    end

    local itemCfg = selectItem:GetItemCfg()
    local itemCount = selectItem:GetItemCount()
    local stage = selectItem:GetStage()
    local index = selectItem:GetIndex()
    if not itemCfg then
        return
    end

    self.m_showing = true

    self.m_itemDetailContainer.gameObject:SetActive(true)

    --显示物品图标
    if not self.m_itemDetailTmpItem then
        self.m_bagItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObject(self.m_bagItemSeq, BagItemPrefabPath, function(go)
            self.m_bagItemSeq = 0
            if not go then
                return
            end
            
            self.m_itemDetailTmpItem = BagItemClass.New(go, self.m_itemCreatePos, BagItemPrefabPath)
            local itemIconParam = ItemIconParam.New(itemCfg, itemCount, stage, index)
            self.m_itemDetailTmpItem:UpdateData(itemIconParam)
        end)
    else
        local itemIconParam = ItemIconParam.New(itemCfg, itemCount, stage, index)
        self.m_itemDetailTmpItem:UpdateData(itemIconParam)
    end
    --更新物品信息
    self.m_itemNameText.text = itemCfg.sName
    self.m_itemDescText.text = itemCfg.sTips
    --更新物品的属性加成
    local stage  = UILogicUtil.GetInscriptionStage(itemCfg.id)
    local color = CommonDefine.colorList[stage]
    self.m_itemAttrText.text = string_format(Language.GetString(689), color, UILogicUtil.GetInscriptionDesc(itemCfg.id)) 
    --更新使用按钮的状态
    local itemMainType = itemCfg.sMainType
    local canUse = (itemCfg.nUseType == 1) and not isLocked
    self.m_useBtn.gameObject:SetActive(canUse)
    if canUse then
        self.m_useBtnText.text = self:GetItemDetailUseBtnName()
    end

    if itemMainType == CommonDefine.ItemMainType_XinWu then
        self.m_mergeBtn.gameObject:SetActive(true)
        self.m_mergeBtnText.text = self:GetItemDetailUseBtnName()
    else
        self.m_mergeBtn.gameObject:SetActive(false)
    end

    --更新锁的状态
    local canLock = selectItem:NeedShowLock()
    local isLocked = selectItem:GetLockState() or false
    self:ChangeLock(canLock, isLocked)

    local isMingQian = itemCfg.sMainType == CommonDefine.ItemMainType_MingQian
    local isShow = isMingQian
    if isShow then
        local inscriptionStageInfo = ConfigUtil.GetInscriptionStageCfgByID(itemCfg.id)
        if inscriptionStageInfo then
            isShow = inscriptionStageInfo.new_inscription_id > 0
        end
    end

    self.m_mingqianMergeBtn.gameObject:SetActive(isShow)
end

function DetailItemHelper:GetItemDetailUseBtnName()
    local nameID = 2003
    local currItemMainType = self.m_bagView:GetCurrMainType()
    if currItemMainType == CommonDefine.ItemMainType_MingQian then
        nameID = 2004
    elseif currItemMainType == CommonDefine.ItemMainType_Mount then
        nameID = 2006
    elseif currItemMainType == CommonDefine.ItemMainType_ShenBing then
        nameID = 2005
    elseif currItemMainType == CommonDefine.ItemMainType_XinWu then
        nameID = 2007
    end
    return Language.GetString(nameID)
end

function DetailItemHelper:ChangeLock(canLock, isLocked)
    if not self.m_showing then
        return
    end

    if canLock then
        UILogicUtil.SetLockImage(self.m_itemLockSpt, isLocked)
    else
        self.m_itemLockSpt:SetAtlasSprite("realempty.tga", false, AtlasConfig.DynamicLoad)
    end

    local canSale = not isLocked and self.m_bagView:GetCurrSelectBagItem():GetItemCfg().nCanSell == 1
    self.m_saleBtn.gameObject:SetActive(canSale)
end

return DetailItemHelper