local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format
local CommonDefine = CommonDefine
local ConfigUtil = ConfigUtil
local UILogicUtil = UILogicUtil
local GameUtility = CS.GameUtility
local GameObject = CS.UnityEngine.GameObject
local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab
local ItemMgr = Player:GetInstance():GetItemMgr()

local BagItemClass = require("UI.UIBag.View.BagItem")
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"

local InscriptionMergeView = BaseClass("InscriptionMergeView", UIBaseItem)
local base = UIBaseItem

local ui_mingqian_ronghe_path = "UI/Effect/Prefabs/ui_mingqian_ronghe"

function InscriptionMergeView:OnCreate()
    base.OnCreate(self)

    self.m_seq = 0
    self.m_seq2 = 0
    self.m_itemList = {}
    self.m_costItemList = {}

    self.m_whiteList = {}  --满足条件 不是灰化的列表
    self.m_layerName = UILogicUtil.FindLayerName(self.transform)

    self:InitView()
end

function InscriptionMergeView:OnEnable()
    base.OnEnable(self)
    self.m_sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
end

function InscriptionMergeView:OnDisable()
    for i, v in ipairs(self.m_costItemList) do
        v:ShowEffect(false)
    end

    UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)
    base.OnDisable(self)
end

function InscriptionMergeView:InitView()
    self.m_leftBtnRectTrans, self.m_rightBtnRectTrans, self.m_costItemParent, self.m_lockItemPrefab,
    self.m_mergeBtn,  self.m_stageViewGo, self.m_fullStageViewGo = 
    UIUtil.GetChildRectTrans(self.transform, {
        "StageView/LeftItemParent",
        "StageView/RightItemParent",
        "StageView/InscriptionCostList",
        "lockItemPrefab",
        "StageView/Merge_BTN",
        "StageView",
        "FullStageView"
    })

    local mergeBtnText, fullStageText
    self.m_leftItemNameText, self.m_rightItemNameText, self.m_leftItemAttrText, self.m_rightItemAttrText, 
    mergeBtnText, self.m_tongqianText, self.m_itemDescText, 
    fullStageText, self.m_itemCountText = UIUtil.GetChildTexts(self.transform, {
        "StageView/arrow2/LeftItemNameText",
        "StageView/arrow2/RightItemNameText",
        "StageView/arrow3/LeftItemAttrText",
        "StageView/arrow3/RightItemAttrText",
        "StageView/Merge_BTN/MergeBtnText",
        "StageView/TongqianImage/TongqianText",
        "StageView/ItemDescText",
        "FullStageView/FullStageText",
        "StageView/ItemCountText"
    })

    self.m_lockItemPrefab = self.m_lockItemPrefab.gameObject
    self.m_stageViewGo = self.m_stageViewGo.gameObject
    self.m_fullStageViewTrans = self.m_fullStageViewGo
    self.m_fullStageViewGo = self.m_fullStageViewGo.gameObject

    mergeBtnText.text = Language.GetString(690)
    fullStageText.text = Language.GetString(696)

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_mergeBtn.gameObject, onClick)

    self.m_itemID = 0
    self.m_costCount = 0

    self.m_colorList = { "ffffff","32b0e4", "e041e6", "e8c04c", "d24643"}
end

function InscriptionMergeView:OnClick(go)
    if go.name == "Merge_BTN" then
        if ItemMgr:GetItemCountByID(self.m_itemID) < self.m_costCount then
            UILogicUtil.FloatAlert(Language.GetString(644))
            return
        end
        
        local itemData = ItemMgr:GetItemData(self.m_itemID)
        if itemData and itemData:GetLockState() then
            UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(704), Language.GetString(705), 
                Language.GetString(10), 
                function() 
                    ItemMgr:ReqLock(self.m_itemID, false, CommonDefine.ItemMainType_MingQian, 0) 
                end
                , Language.GetString(5))
            return
        end
        Player:GetInstance().InscriptionMgr:ReqMergeInscription(self.m_itemID, 1)
    end
end

function InscriptionMergeView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_mergeBtn.gameObject)
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq2)
    self.m_seq2 = 0


    for i, v in ipairs(self.m_itemList) do
        v:Delete()
    end
    self.m_itemList = nil

    for i, v in ipairs(self.m_costItemList) do
        GameUtility.SetUIGray(v:GetGameObject(), false)
        v:Delete()
    end
    self.m_costItemList = nil

    self.m_whiteList = nil
   
    base.OnDestroy(self)
end

function InscriptionMergeView:UpdateData(itemData)
    if not itemData then
        UILogicUtil.SetItemCountText(self.m_itemCountText, 0, self.m_costCount, 81)
        return
    end

    self.m_itemData = itemData

    self.m_itemID = itemData:GetItemID()

    local inscriptionStageInfo = ConfigUtil.GetInscriptionStageCfgByID(self.m_itemID)
    if not inscriptionStageInfo then
        return
    end

    local isFullStage = false
    local nextItemCfg = ConfigUtil.GetItemCfgByID(inscriptionStageInfo.new_inscription_id)
    if not nextItemCfg then
        isFullStage = true
    end

    local itemCfg = itemData:GetItemCfg()
    if not itemCfg then
        return
    end

    self.m_costCount = inscriptionStageInfo.cost_count

    self.m_stageViewGo:SetActive(not isFullStage)
    self.m_fullStageViewGo:SetActive(isFullStage)

    if isFullStage then
        if self.m_bagItem == nil then
            if self.m_seq2 == 0 then
                self.m_seq2 = UIGameObjectLoader:GetInstance():PrepareOneSeq() 
                UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq2, BagItemPrefabPath, 
                    function(go)
                        self.m_seq2 = 0
                        if IsNull(go) then
                            return
                        end
    
                        self.m_bagItem = BagItemClass.New(go, self.m_fullStageViewTrans, BagItemPrefabPath)
                        self.m_bagItem:SetLocalPosition(Vector3.New(0, 274.8))
                        self.m_bagItem:SetLocalScale(Vector3.New(0.75, 0.75, 0.75))
                        self:UpdateInscriptionItem(self.m_bagItem, itemCfg)

                    end)
            end
        else
            self:UpdateInscriptionItem(self.m_bagItem, itemCfg)
        end

        return
    end



    local function loadCallBack()

        local delCount = #self.m_costItemList - self.m_costCount
        if delCount > 0 then
            for i = #self.m_costItemList, #self.m_costItemList - delCount + 1 , -1 do
                self.m_costItemList[i]:Delete()
                table_remove(self.m_costItemList, i)
            end
        end

        local isEnough = self.m_itemData:GetItemCount() >= self.m_costCount

        self.m_whiteList = {}

        for i = 1, 5 do
            if i <= #self.m_costItemList then
                self:UpdateInscriptionItem(self.m_costItemList[i], itemCfg)

                local isGray =  not(isEnough or i <= self.m_itemData:GetItemCount())
                GameUtility.SetUIGray(self.m_costItemList[i]:GetGameObject(), isGray)   
                
                if not isGray then
                    table_insert(self.m_whiteList, i)
                end
            end
        end
    end

    local createCount = self.m_costCount - #self.m_costItemList
    if createCount > 0 then
        local seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(seq, BagItemPrefabPath, createCount, function(objs)
            if objs then
                for i = 1, #objs do
                    if not IsNull(objs[i]) then
                        local bagItem = BagItemClass.New(objs[i], self.m_costItemParent, BagItemPrefabPath)
                        table_insert(self.m_costItemList, bagItem)
                    end
                end
                loadCallBack()
            end
        end)
    else
        loadCallBack()
    end


    local function loadCallBack2()
        if #self.m_itemList >= 2 then
            self:UpdateInscriptionItem(self.m_itemList[1], itemCfg)
            self:UpdateInscriptionItem(self.m_itemList[2], nextItemCfg)
        end
    end

    if #self.m_itemList == 0 then
        if self.m_seq == 0 then
            self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObjects(self.m_seq, BagItemPrefabPath, 2, function(objs)
                self.m_seq = 0
                if objs then
                    for i = 1, #objs do
                        local itemParent = i == 1 and self.m_leftBtnRectTrans or self.m_rightBtnRectTrans
                        local bagItem = BagItemClass.New(objs[i], itemParent, BagItemPrefabPath)
                        table_insert(self.m_itemList, bagItem)
                    end
                    loadCallBack2()
                end
            end)
        end
    else
        loadCallBack2()
    end

    local stage  = UILogicUtil.GetInscriptionStage(self.m_itemID)
    local stage2  = UILogicUtil.GetInscriptionStage(inscriptionStageInfo.new_inscription_id)

    local color = self.m_colorList[stage]
    local color2 = self.m_colorList[stage2]

    self.m_leftItemNameText.text = string_format(Language.GetString(689), color, itemCfg.sName) 
    self.m_rightItemNameText.text = string_format(Language.GetString(689), color2, nextItemCfg.sName)
    self.m_leftItemAttrText.text = string_format(Language.GetString(689), color, UILogicUtil.GetInscriptionDesc(itemCfg.id)) 
    self.m_rightItemAttrText.text = string_format(Language.GetString(689), color2, UILogicUtil.GetInscriptionDesc(nextItemCfg.id)) 
    self.m_tongqianText.text = inscriptionStageInfo.cost_tongqian_count
    self.m_itemDescText.text = nextItemCfg.sTips

    UILogicUtil.SetItemCountText(self.m_itemCountText, self.m_itemData:GetItemCount(), self.m_costCount, 81)
end

function InscriptionMergeView:Refresh()
    if self.m_itemID > 0 then
        local itemData = ItemMgr:GetItemData(self.m_itemID)
        self:UpdateData(itemData)
    end
end 

function InscriptionMergeView:UpdateInscriptionItem(inscriptionItem, itemCfg, count, isenough)
    count = count or 0
    if inscriptionItem then
        local itemIconParam = ItemIconParam.New(itemCfg, count)
        itemIconParam.onClickShowDetail = true
        inscriptionItem:UpdateData(itemIconParam)
    end
end

function InscriptionMergeView:ShowEffect()
    for i, v in ipairs(self.m_costItemList) do
        if self.m_whiteList[i] then
            v:ShowEffect(true, self.m_sortOrder, ui_mingqian_ronghe_path)
        end
    end
end


return InscriptionMergeView