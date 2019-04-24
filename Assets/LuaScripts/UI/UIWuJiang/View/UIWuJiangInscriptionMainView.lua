local math_ceil = math.ceil

local SceneObjPath = "UI/Prefabs/WuJiang/SceneObj2.prefab"
local ItemDetailContainerPath = TheGameIds.CommonItemDetailContainerPrefab
local WuJiangMgr = Player:GetInstance().WujiangMgr
local ItemMgr = Player:GetInstance():GetItemMgr()
local UILogicUtil = UILogicUtil
local GameObject = CS.UnityEngine.GameObject
local Quaternion = Quaternion
local BattleEnum = BattleEnum
local GameUtility = CS.GameUtility
local WuJiangInscriptionInfoView = require "UI.UIWuJiang.View.WuJiangInscriptionInfoView"
local InscriptionBagView = require "UI.UIWuJiang.View.InscriptionBagView"
local ItemDetailView = require "UI.UIWuJiang.View.ItemDetailView"
local InscriptionMergeView = require "UI.UIWuJiang.View.InscriptionMergeView"

local UIWuJiangInscriptionMainView = BaseClass("UIWuJiangInscriptionMainView", UIBaseView)
local base = UIBaseView

function UIWuJiangInscriptionMainView:OnCreate()
    base.OnCreate(self)

    self:InitView()

    self.m_itemDetailSeq = 0
    self.m_wujiangSortIndex = 1
    self.m_createWuJiangSeq = 0
    self.m_startDraging = false
    self.m_draging = false
    self.m_posX = 0
end

function UIWuJiangInscriptionMainView:InitView()
    self.m_inscriptionInfoViewGo,
        self.m_inscriptionBag,
        self.m_mergeViewGo,
        self.m_inscriptionCaseBtnTrans,
        self.m_addInscriptionCaseBtnTrans,
        self.m_maskBtn,
        self.m_backBtn =
        UIUtil.GetChildTransforms(
        self.transform,
        {
            "InscriptionInfoView",
            "InscriptionBag",
            "MergeView",
            "InscriptionCaseBtn",
            "AddInscriptionCaseBtn",
            "MaskBtn",
            "Panel/backBtn"
        }
    )

    self.m_leftBtn, self.m_rightBtn, self.m_actorBtn =
        UIUtil.GetChildRectTrans(
        self.transform,
        {
            "actorBtn/leftBtn",
            "actorBtn/rightBtn",
            "actorBtn",
        }
    )

    self.m_inscriptionInfoViewGo = self.m_inscriptionInfoViewGo.gameObject
    self.m_inscriptionBag = self.m_inscriptionBag.gameObject
    self.m_mergeViewGo = self.m_mergeViewGo.gameObject

    self:HandleClick()
    self:HandleDrag()
end

function UIWuJiangInscriptionMainView:OnEnable(...)
    base.OnEnable(self, ...)

    local initOrder
    initOrder, self.m_wujiangIndex = ...

    if not self.m_wujiangIndex then
        self.m_wujiangIndex = 1
    end

    self.m_close = false

    self:GetSortWuJiangList()

    self:UpdateData()
    GameUtility.SetSceneGOActive("Fortress", "DirectionalLight_Shadow", false)
end

function UIWuJiangInscriptionMainView:GetSortWuJiangList()
    self.m_wujiangSortList = WuJiangMgr:GetSortWuJiangList(WuJiangMgr.CurSortPriority, function(data, wujiangCfg)
        if wujiangCfg.country == WuJiangMgr.CurrCountrySortType or WuJiangMgr.CurrCountrySortType == CommonDefine.COUNTRY_5 then
            return true
        end
    end)

    if not self.m_wujiangSortList then
        Logger.LogError("GetSortWuJiangList error")
        return
    end

    for i, v in ipairs(self.m_wujiangSortList) do
        if v.index == self.m_wujiangIndex then
            self.m_wujiangSortIndex = i
            break
        end
    end
end

function UIWuJiangInscriptionMainView:UpdateData()
    self:UpdateInscriptionInfoView()

    self:CreateWuJiang()

    self:CheckBtnMove()
end

function UIWuJiangInscriptionMainView:OnDisable()
    WuJiangMgr.CurrWuJiangIndex = self.m_wujiangIndex

    self:RecycleObj()
    self:DestroyRoleContainer()

    self.m_close = true

    self:Reset()

    if self.m_inscriptionBagView then
        self.m_inscriptionBagView:Delete()
        self.m_inscriptionBagView = nil
    end

    if self.m_inscriptionInfoView then
        self.m_inscriptionInfoView:Delete()
        self.m_inscriptionInfoView = nil
    end

    if self.m_itemDetailView then
        self.m_itemDetailView:Delete()
        self.m_itemDetailView = nil
    end

    if self.m_inscriptionMergeView then
        self.m_inscriptionMergeView:SetActive(false)
        self.m_inscriptionMergeView:Delete()
        self.m_inscriptionMergeView = nil
    end

    self.m_curWuJiangData = nil
    GameUtility.SetSceneGOActive("Fortress", "DirectionalLight_Shadow", true)

    self:KillTween()

    base.OnDisable(self)
end

function UIWuJiangInscriptionMainView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_inscriptionCaseBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_addInscriptionCaseBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_maskBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_leftBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 116))
    UIUtil.AddClickEvent(self.m_rightBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 116))
end

function UIWuJiangInscriptionMainView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_inscriptionCaseBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_addInscriptionCaseBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_maskBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_leftBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_rightBtn.gameObject)
    base.OnDestroy(self)
end

function UIWuJiangInscriptionMainView:UpdateInscriptionInfoView()
    if self.m_inscriptionInfoView == nil then
        self.m_inscriptionInfoView = WuJiangInscriptionInfoView.New(self.m_inscriptionInfoViewGo)
    end

    self.m_inscriptionInfoView:UpdateData(self.m_wujiangIndex)
end

function UIWuJiangInscriptionMainView:OnClick(go, x, y)
    if go.name == "InscriptionCaseBtn" then 
        self:ShowItemDetail(false)
        self:ShowEquipInscriptionDetail(false)
        UIManagerInst:OpenWindow(UIWindowNames.UIInscriptionCaseList, self.m_wujiangIndex)
    elseif go.name == "AddInscriptionCaseBtn" then 
        self:ShowItemDetail(false)
        self:ShowEquipInscriptionDetail(false)
        UIManagerInst:OpenWindow(UIWindowNames.UIAddInscriptionCase, self.m_wujiangIndex)
    elseif go.name == "MaskBtn" then
        self:HandleClickMask()
    elseif go.name == "backBtn" then
        self:CloseSelf()
    elseif go.name == "leftBtn" then
        if self:CanClick() then
            if self.m_wujiangSortList and self.m_wujiangSortIndex > 1 then
                self.m_wujiangSortIndex = self.m_wujiangSortIndex - 1
                self.m_wujiangIndex = self.m_wujiangSortList[self.m_wujiangSortIndex].index
                self:ShowEquipInscriptionDetail(false)
                self:UpdateData()
            end
        end
    elseif go.name == "rightBtn" then
        if self:CanClick() then
            if self.m_wujiangSortList and self.m_wujiangSortIndex < #self.m_wujiangSortList then
                self.m_wujiangSortIndex = self.m_wujiangSortIndex + 1
                self.m_wujiangIndex = self.m_wujiangSortList[self.m_wujiangSortIndex].index
                self:ShowEquipInscriptionDetail(false)
                self:UpdateData()
            end
        end
    end
end

function UIWuJiangInscriptionMainView:CanClick()
    --判断武将是否已加载好了
    if not self.m_actorShow then
        return false
    end
    return true
end

function UIWuJiangInscriptionMainView:HandleClickMask(onlyCheckItemDetail)
    if not onlyCheckItemDetail then
        if self.m_mergeViewShow and self.m_inscriptionMergeView then
            self:ShowMergeView(false)
        end
    end

    if self.m_equipInscriptionDetailViewShow or self.m_itemDetailViewShow then
        if self.m_equipInscriptionDetailViewShow and self.m_equipInscriptionDetailView then
            self:ShowEquipInscriptionDetail(false)
        end

        if self.m_itemDetailViewShow and self.m_itemDetailView then 
            self:ShowItemDetail(false)
        end
        return
    end

    if not onlyCheckItemDetail then
        if self.m_isShowBag then
            self.m_inscriptionBag:SetActive(false)
            self.m_isShowBag = false
            self:ShowWuJiang(true)
        end
    end
end

function UIWuJiangInscriptionMainView:OnAddListener()
    base.OnAddListener(self)

    self:AddUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_CHG, self.UpdateInscriptionInfoView)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_BAG_SHOW, self.ShowInscriptionBag)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_DETAIL_SHOW, self.ShowItemDetail)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_ITEM_CLICK, self.ShowEquipInscriptionDetail)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_MERGE_VIEW_SHOW, self.ShowMergeView)
    self:AddUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.UpdateInscriptionBag)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_OPERATION, self.OperateInscription)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_CLICK_MASK, self.HandleClickMask)
    self:AddUIListener(UIMessageNames.MN_ITEM_LOCK_CHG, self.OnLockChg)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_MERGE, self.MergeResult)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange) 
end

function UIWuJiangInscriptionMainView:OnRemoveListener()
    base.OnRemoveListener(self)

    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_CHG, self.UpdateInscriptionInfoView)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_BAG_SHOW, self.ShowInscriptionBag)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_DETAIL_SHOW, self.ShowItemDetail)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_ITEM_CLICK, self.ShowEquipInscriptionDetail)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_MERGE_VIEW_SHOW, self.ShowMergeView)
    self:RemoveUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.UpdateInscriptionBag)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_OPERATION, self.OperateInscription)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_CLICK_MASK, self.HandleClickMask)
    self:RemoveUIListener(UIMessageNames.MN_ITEM_LOCK_CHG, self.OnLockChg)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INSCRIPTION_MERGE, self.MergeResult)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange) 
end

function UIWuJiangInscriptionMainView:PowerChange(power)
    UILogicUtil.PowerChange(power)
end

function UIWuJiangInscriptionMainView:CreateWuJiang()
    local wujiangData = WuJiangMgr:GetWuJiangData(self.m_wujiangIndex)
    if not wujiangData then
        Logger.LogError("GetWuJiangData error " .. self.m_wujiangIndex)
        return
    end

    if self.m_curWuJiangData and wujiangData.id == self.m_curWuJiangData.id then
        local weaponLevel = PreloadHelper.WuqiLevelToResLevel(wujiangData.weaponLevel)
        local weaponLevel2 = PreloadHelper.WuqiLevelToResLevel(self.m_curWuJiangData.weaponLevel)
        if weaponLevel == weaponLevel2 then
            -- 不需要切换
            return
        end
    end

    self.m_curWuJiangData = wujiangData

    self:CreateRoleContainer()

    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end

    local wujiangID = math_ceil(self.m_curWuJiangData.id)
    local weaponLevel = self.m_curWuJiangData.weaponLevel

    self.m_createWuJiangSeq = ActorShowLoader:GetInstance():PrepareOneSeq()

    ActorShowLoader:GetInstance():CreateShowOffWuJiang(
        self.m_createWuJiangSeq,
        ActorShowLoader.MakeParam(wujiangID, weaponLevel),
        self.m_roleContainerTrans,
        function(actorShow)
            self.m_actorShow = actorShow
            self.m_actorShow:PlayAnim(BattleEnum.ANIM_IDLE)
            self.m_actorShow:SetPosition(Vector3.New(0.4580405, 0.01, -2.057942))
            self.m_actorShow:SetEulerAngles(Vector3.New(0, 167, 0))
            TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
        end
    )
end

function UIWuJiangInscriptionMainView:RecycleObj()
    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end
    ActorShowLoader:GetInstance():CancelLoad(self.m_createWuJiangSeq)
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_itemDetailSeq)

    self.m_createWuJiangSeq = 0
    self.m_itemDetailSeq = 0
end

function UIWuJiangInscriptionMainView:CreateRoleContainer()
    if IsNull(self.m_roleContainerGo) then
        self.m_roleContainerGo = GameObject("RoleContainer")
        self.m_roleContainerTrans = self.m_roleContainerGo.transform

        self.m_sceneSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_sceneSeq,
            SceneObjPath,
            function(go)
                self.m_sceneSeq = 0
                if not IsNull(go) then
                    self.m_roleBgGo = go
                    self.m_roleBgGo.transform.localRotation = Quaternion.Euler(0, 0, 0)
                end
            end
        )
    end
end

function UIWuJiangInscriptionMainView:DestroyRoleContainer()
    if not IsNull(self.m_roleContainerGo) then
        GameObject.DestroyImmediate(self.m_roleContainerGo)
    end

    self.m_roleContainerGo = nil
    self.m_roleContainerTrans = nil

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_sceneSeq)
    self.m_sceneSeq = 0

    if not IsNull(self.m_roleBgGo) then
        UIGameObjectLoader:GetInstance():RecycleGameObject(SceneObjPath, self.m_roleBgGo)
        self.m_roleBgGo = nil
    end
end

function UIWuJiangInscriptionMainView:ShowInscriptionBag(isShow, isReplace)
    self.m_inscriptionBag:SetActive(isShow)
    self.m_isShowBag = isShow

    self:ShowWuJiang(not isShow)

    if isShow then
        if self.m_inscriptionBagView == nil then
            self.m_inscriptionBagView = InscriptionBagView.New(self.m_inscriptionBag, self.winName)
        end

        self.m_inscriptionBagView:UpdateData()

        --打开背包 会关闭 item详情，取消选中当前的命签
        --如果是更换，则不取消选中当前的命签
        self:ShowEquipInscriptionDetail(false, nil, false)

        if isReplace == nil then
            self:InscriptionInfoViewCancelSelect()
        end
    end
end

function UIWuJiangInscriptionMainView:InscriptionInfoViewCancelSelect()
    if self.m_inscriptionInfoView then
        self.m_inscriptionInfoView:CancelSelect()
    end
end

function UIWuJiangInscriptionMainView:UpdateInscriptionBag(item_data_list, itemChgReason)
    if self.m_isShowBag and self.m_inscriptionBag then
        self.m_inscriptionBagView:UpdateData(itemChgReason)
    end

    if self.m_itemDetailViewShow and self.m_itemDetailView then
        local itemData = ItemMgr:GetItemData(self.m_itemDetailView:GetItemID())
        self.m_itemDetailView:Refresh(self.m_wujiangIndex, itemData)
    end

    if self.m_mergeViewShow and self.m_inscriptionMergeView then
        self.m_inscriptionMergeView:Refresh()
    end
end 

function UIWuJiangInscriptionMainView:ShowItemDetail(isShow, itemData, onlyShow) 
    if isShow then
        -- 点击背包时，要么刷新融合界面， 要么显示item详情
        if self.m_mergeViewShow and self.m_inscriptionMergeView then
            if itemData == nil then
                Logger.Log("mergeViewShow item nil")
                return
            end
            self.m_inscriptionMergeView:UpdateData(itemData)
            return
        end
    end

    if self.m_itemDetailView then
        self.m_itemDetailView:SetActive(isShow)
    end

    self.m_itemDetailViewShow = isShow

    if isShow == false then
        if self.m_isShowBag and self.m_inscriptionBagView then
            self.m_inscriptionBagView:ClearCurrSelectItem()
        end
    end

    local function loadCallBack()
        if self.m_close then
            return
        end
        self:UpdateTwoView(itemData)
    end

    if isShow then
        if not itemData then
            Logger.Log("ShowItemDetail item nil")
            return
        end

        if self.m_itemDetailView == nil then
            self.m_itemDetailSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
                UIGameObjectLoader:GetInstance():GetGameObject(self.m_itemDetailSeq,
                ItemDetailContainerPath,
                function(go)
                    self.m_itemDetailSeq = 0
                    if not IsNull(go) then
                        self.m_itemDetailView = ItemDetailView.New(go, self.transform, ItemDetailContainerPath)
                        go.name = "ItemDetail"

                        self.m_itemDetailView:UpdateData(itemData, 1, self.m_wujiangIndex)
                        loadCallBack()
                    end
                end
            )
        else
            loadCallBack()
        end

        return
    end
    --当前有命签详情，关闭时，要更新它的位置
    loadCallBack()
end

--点击装备的命签
function UIWuJiangInscriptionMainView:ShowEquipInscriptionDetail(isShow, itemData, canCancelInscriptionInfoView)

    canCancelInscriptionInfoView = canCancelInscriptionInfoView == nil and true or false

    if self.m_equipInscriptionDetailView then
        self.m_equipInscriptionDetailView:SetActive(isShow)
    end

    self.m_equipInscriptionDetailViewShow = isShow

    if isShow then
        if not itemData then
            Logger.Log("ShowEquipInscriptionDetail item nil")
            return
        end

        local function loadCallBack()
            self:UpdateTwoView(nil, itemData)
        end

        if self.m_equipInscriptionDetailView == nil then
            self.m_seq2 = UIGameObjectLoader:GetInstance():PrepareOneSeq()
                UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq2,
                ItemDetailContainerPath,
                function(go)
                    self.m_seq2 = 0
                    if not IsNull(go) then
                        self.m_equipInscriptionDetailView = ItemDetailView.New(go, self.transform, ItemDetailContainerPath)
                        go.name = "InscriptionDetail"
                        self.m_equipInscriptionDetailView:UpdateData(itemData, 1, self.m_wujiangIndex)
                        loadCallBack()
                    end
                end
            )
        else
            loadCallBack()
        end
    else
        if canCancelInscriptionInfoView then
            self:InscriptionInfoViewCancelSelect()
        end
    end
end

function UIWuJiangInscriptionMainView:FitViewPos()
    if self.m_equipInscriptionDetailView and self.m_equipInscriptionDetailViewShow then
        if self.m_itemDetailViewShow then
            self.m_equipInscriptionDetailView:SetLocalPosition(Vector3.New(554.7, 229.3, 0))
        elseif self.m_isShowBag then
            self.m_equipInscriptionDetailView:SetLocalPosition(Vector3.New(188.8, 229.3, 0))
        else
            self.m_equipInscriptionDetailView:SetLocalPosition(Vector3.New(-235, 361.69, 0))
        end
    end

    if self.m_itemDetailView and self.m_itemDetailViewShow then
        if self.m_equipInscriptionDetailViewShow then
            self.m_itemDetailView:SetLocalPosition(Vector3.New(68.6, 229.3, 0))
        else
            self.m_itemDetailView:SetLocalPosition(Vector3.New(188.8, 229.3, 0))
        end
    end
end

function UIWuJiangInscriptionMainView:ShowInscriptionInfoView(isShow)
    self.m_inscriptionInfoViewGo:SetActive(isShow)
    self.m_inscriptionCaseBtnTrans.gameObject:SetActive(isShow)
    self.m_addInscriptionCaseBtnTrans.gameObject:SetActive(isShow)
end

function UIWuJiangInscriptionMainView:ShowMergeView(isShow, itemData)
    --打开融合界面时，同时打开背包且关闭命签信息界面

    self.m_mergeViewShow = isShow

    self:ShowInscriptionBag(isShow)
    self:ShowInscriptionInfoView(not isShow)

    if isShow then
        self:ShowEquipInscriptionDetail(false) 
        self:ShowItemDetail(false)
    end

    if self.m_inscriptionMergeView then
        self.m_inscriptionMergeView:SetActive(isShow)
    else
        if self.m_inscriptionMergeView == nil then
            self.m_mergeViewGo:SetActive(true)
            self.m_inscriptionMergeView = InscriptionMergeView.New(self.m_mergeViewGo, nil, '')
        end
    end

    if not itemData then
        --Logger.Log("ShowMergeView itemData nil")
        return
    end

    if isShow then
        self.m_inscriptionMergeView:UpdateData(itemData)
    end
end

function UIWuJiangInscriptionMainView:OnLockChg(param)  
    if self.m_itemDetailView then
        self.m_itemDetailView:OnLockChg(param)
    end

    if self.m_inscriptionBagView then
        self.m_inscriptionBagView:OnLockChg(param)
    end

    if self.m_equipInscriptionDetailView then
        self.m_equipInscriptionDetailView:OnLockChg(param)
    end
end

function UIWuJiangInscriptionMainView:Reset()
    self:ShowMergeView(false)
    self:ShowEquipInscriptionDetail(false) 
    self:ShowItemDetail(false)
    self:ShowInscriptionBag(false)
end

function UIWuJiangInscriptionMainView:IsInscriptionItemSelected()
    if self.m_inscriptionInfoView then
        local selectInscriptionItem = self.m_inscriptionInfoView:GetSelectInscriptionItem()
        if selectInscriptionItem then
            return true
        end
    end
end

function UIWuJiangInscriptionMainView:OperateInscription(inscription_id_list, isReplace)
    --更换操作之前 打开背包：
    if isReplace then
        if not self.m_isShowBag then
            self:ShowInscriptionBag(true, true)
            return
        end
    end

    if inscription_id_list then
        Player:GetInstance().InscriptionMgr:ReqEquipInscription(self.m_wujiangIndex, inscription_id_list)
    end
end

--背包item数据 itemData， 命签数据itemData2
function UIWuJiangInscriptionMainView:UpdateTwoView(itemData, itemData2)
    local isSelected = self:IsInscriptionItemSelected()
    local selectInscriptionItem = self.m_inscriptionInfoView:GetSelectInscriptionItem()

    local function show()
        if isSelected then
            if selectInscriptionItem then
                local itemData = ItemMgr:GetItemData(selectInscriptionItem:GetItemID())
                self:ShowEquipInscriptionDetail(true, itemData)
            end
        end
    end

    --有选中命签，则更换，否则装备
    if self.m_itemDetailViewShow and self.m_itemDetailView then
        local operateType = isSelected and 3 or 1
        self.m_itemDetailView:Refresh(self.m_wujiangIndex, itemData, operateType)
        if selectInscriptionItem then
            self.m_itemDetailView:SetReplaceItemID(selectInscriptionItem:GetItemID())
        end

        --会触发打开命签Detail
        if not self.m_equipInscriptionDetailViewShow then
            show()
        end
    end

    -- 3种情况，1， (背包没打开之前，)可更换，可以卸下，2，已装备，3卸下
    if self.m_equipInscriptionDetailViewShow and self.m_equipInscriptionDetailView then
        if itemData2 == nil then
            itemData2 = self.m_equipInscriptionDetailView:GetItemData()
        end

        if itemData2 then
            local operateType = 2
            local itemID = itemData2:GetItemID()

            local isTheSame = selectInscriptionItem and selectInscriptionItem:GetItemID() == itemID

            --如果显示itemDatail就更换，如果没的话，打开背包，且有选中命签自身，则卸下，默认是可更换，可以卸下
            if self.m_itemDetailViewShow then
                operateType = 5
            else
                if isSelected and self.m_isShowBag then
                    if isTheSame then
                        operateType = 4
                    end
                end
            end

            local isEquiped = isTheSame
            self.m_equipInscriptionDetailView:Refresh(self.m_wujiangIndex, itemData2, operateType, isEquiped)
        end
    end

    self:FitViewPos()
end

function UIWuJiangInscriptionMainView:ShowWuJiang(isShow)
    if self.m_actorShow then
        local pos = isShow and Vector3.New(0.4580405, 0.01, -2.057942) or Vector3.New(100000, 100000, 100000)
        self.m_actorShow:SetPosition(pos)
    end

    self:CheckBtnMove()
end

function UIWuJiangInscriptionMainView:CheckBtnMove()
    self:KillTween()

    if self.m_isShowBag then
        self.m_leftBtn.gameObject:SetActive(false)
        self.m_rightBtn.gameObject:SetActive(false)
        return
    end

    local isShowBtn = self.m_wujiangSortIndex > 1
    self.m_leftBtn.gameObject:SetActive(isShowBtn)
    self.m_leftBtn.anchoredPosition = Vector2.New(-30, self.m_leftBtn.anchoredPosition.y)

    if isShowBtn then
        self.m_tweener = UIUtil.LoopMoveLocalX(self.m_leftBtn, -6, -36, 0.6)
    end

    isShowBtn = self.m_wujiangSortList and self.m_wujiangSortIndex < #self.m_wujiangSortList
    self.m_rightBtn.gameObject:SetActive(isShowBtn)
    self.m_rightBtn.anchoredPosition = Vector2.New(34.95, self.m_rightBtn.anchoredPosition.y)

    if isShowBtn then
        self.m_tweener2 = UIUtil.LoopMoveLocalX(self.m_rightBtn, 6, 36, 0.6)
    end
end

function UIWuJiangInscriptionMainView:KillTween()
    UIUtil.KillTween(self.m_tweener)
    UIUtil.KillTween(self.m_tweener2)
end

function UIWuJiangInscriptionMainView:HandleDrag()
    local function DragBegin(go, x, y)
        self.m_startDraging = false
        self.m_draging = false
    end

    local function DragEnd(go, x, y)
        self.m_startDraging = false
        self.m_draging = false
    end

    local function Drag(go, x, y)
        if not self.m_startDraging then
            self.m_startDraging = true

            if x then
                self.m_posX = x
            end
            return
        end

        self.m_draging = true

        if x and self.m_posX then
            if self.m_actorShow then
                local deltaX = x - self.m_posX
                if deltaX > 0 then
                    self.m_actorShow:RolateUp(-12)
                else 
                    self.m_actorShow:RolateUp(12)
                end
            end

            self.m_posX = x
           
        else
            -- print("error pos, ", x, self.m_posX)
        end
    end
   
    UIUtil.AddDragBeginEvent(self.m_actorBtn.gameObject, DragBegin)
    UIUtil.AddDragEndEvent(self.m_actorBtn.gameObject, DragEnd)
    UIUtil.AddDragEvent(self.m_actorBtn.gameObject, Drag)
end

local ItemData = require "DataCenter.ItemData.ItemData"

function UIWuJiangInscriptionMainView:MergeResult(new_inscription_id)
    if self.m_mergeViewShow and self.m_inscriptionMergeView then
        self.m_inscriptionMergeView:ShowEffect()
        AudioMgr:PlayUIAudio(114)
    end

    coroutine.start(function()
        coroutine.waitforseconds(1)
        local itemData = ItemMgr:GetItemData(new_inscription_id)
        itemData = ItemData.New(new_inscription_id, 1, itemData and itemData:GetLockState() or false)
        UIManagerInst:OpenWindow(UIWindowNames.UIWuJiangInscriptionMergeSucc, { itemData })
	end)
end

return UIWuJiangInscriptionMainView
