local base = require "UI.UIBattleRecord.View.BattleSettlementView"
local UIGraveCopySettlementView = BaseClass("UIGraveCopySettlementView", base)

local string_format = string.format
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local Quaternion = Quaternion
local GameUtility = CS.GameUtility
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab 
local Type_Image = typeof(CS.UnityEngine.UI.Image)
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings

local scale = Vector3.one * 0.75

function UIGraveCopySettlementView:OnCreate()
    base.OnCreate(self)

   self.m_graveInfoRoot, self.m_graveTheBestGo, self.m_itemContent2Tran = 
    UIUtil.GetChildTransforms(self.transform, {
        "bottomContainer/GraveInfoRoot",
        "bottomContainer/GraveInfoRoot/PassTimeText/TheBestImage",
        "Canvas/ItemContent2"
    })

    self.m_gravePassTimeText = 
    UIUtil.GetChildTexts(self.transform, {
        "bottomContainer/GraveInfoRoot/PassTimeText",
    })

    self.m_graveTheBestGo = self.m_graveTheBestGo.gameObject
    self.m_graveInfoRoot.gameObject:SetActive(true)

    self.m_awardItemList = {}
end

function UIGraveCopySettlementView:OnEnable(...)
    base.OnEnable(self, ...)
   
    self:SetDelayShowTime(2)
    self:UpdateGraveCopyResult()
end

function UIGraveCopySettlementView:UpdateGraveCopyResult()

    if self.m_msgObj then
        
        local battle_result = self.m_msgObj.battle_result.gravecopy_result
        if battle_result then
            self.m_gravePassTimeText.text = string_format(Language.GetString(1806), TimeUtil.ToMinSecStr(battle_result.consumed_time))
        end
        
        self.m_graveTheBestGo:SetActive(self.m_msgObj.history_best == 1)
        coroutine.start(UIGraveCopySettlementView.FitPos, self)

        local awardList = PBUtil.ParseAwardList(self.m_msgObj.award_list)
        if awardList and #awardList > 0 then
            --UIManagerInst:OpenWindow(UIWindowNames.UIBaoxiang, awardList)

            self:ShowBaoxiang(awardList)
        end
    end
end

function UIGraveCopySettlementView:FitPos()
    coroutine.waitforframes(1)
    UIUtil.KeepCenterAlign(self.m_gravePassTimeText.transform, self.m_graveInfoRoot)
end

local BaoxiangScale = Vector3.New(80, 80, 80)
local LocalEulerAngles = Vector3.New(0, 0, -50)
local TweenDeltaTime = 0.2

function UIGraveCopySettlementView:ShowBaoxiang(awardList)

    self.m_awardList = awardList
    self.m_awardCount = #self.m_awardList
    self.m_awardBoxItemIndex = 0

    self.m_baoxiangSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObject(self.m_baoxiangSeq, TheGameIds.Baoxiang2Prefab, function(go)
        self.m_baoxiangSeq = 0
        if not IsNull(go) then

            self.m_baoxiangGo = go

            local baoxiangTran = go.transform
            GameUtility.RecursiveSetLayer(go, Layers.UI)
            baoxiangTran:SetParent(self.m_canvasTran)
            baoxiangTran.localPosition = Vector3.New(0, -34.2, -200)
            baoxiangTran.localRotation = Quaternion.Euler(18, -180, 0)
            baoxiangTran.localScale = BaoxiangScale

            local animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
            if animator then
                GameUtility.ForceCrossFade(animator, "baoxiang2", 0)
            end

            coroutine.start(self.ShowAwardList, self)
        end
    end)
    
end

function UIGraveCopySettlementView:ShowAwardList()
    coroutine.waitforseconds(0.5)

    self:CheckShowAward()
end

function UIGraveCopySettlementView:CheckShowAward()
    if self.m_awardList and #self.m_awardList > 0 then
        local awardData = self.m_awardList[1]
        table_remove(self.m_awardList, 1)

        self:ShowAwardItem(awardData)
    end
end

function UIGraveCopySettlementView:ShowAwardItem(awardData)
    if awardData then
        local itemData = awardData:GetItemData()
        if itemData then
            local CreateAwardParamFromAwardData = PBUtil.CreateAwardParamFromAwardData
            self.m_awardItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_awardItemSeq, CommonAwardItemPrefab, function(go)
                self.m_awardItemSeq = 0
                if not IsNull(go) then
                    local bagItem = CommonAwardItem.New(go, self.m_itemContent2Tran, CommonAwardItemPrefab)
                    bagItem:SetLocalEulerAngles(LocalEulerAngles)
                    local itemIconParam = CreateAwardParamFromAwardData(awardData) 
                    bagItem:UpdateData(itemIconParam)
                    bagItem:SetLocalPosition(Vector3.New(88, -68.5, 0))
                    bagItem:SetItemDetailPosZ(-210)
                    bagItem:SetLocalScale(scale)

                    local targetPos =  Vector3.New(88, -275.5, 0)

                    DOTweenShortcut.DOLocalMove(bagItem:GetTransform(), targetPos, TweenDeltaTime)

                    local tweener = DOTweenShortcut.DOLocalRotate(bagItem:GetTransform(), Vector3.zero, TweenDeltaTime)
                    DOTweenSettings.OnComplete(tweener, function()
                        if self.m_awardList then
                            if bagItem then
                                bagItem:SetParent(self.m_attachItemContentTr)
                                bagItem:SetLocalScale(Vector3.zero)
                            end
                            self:CheckShowAward()
                        end
                    end)

                    self.m_awardBoxItemIndex = self.m_awardBoxItemIndex + 1
                    table_insert(self.m_dropAttachList, bagItem)
                end
            end)
        end
    end
end

function UIGraveCopySettlementView:OnDestroy()
    self.m_awardList = nil

    if not IsNull(self.m_baoxiangGo) then
        GameObjectPoolInst:RecycleGameObject(TheGameIds.Baoxiang2Prefab, self.m_baoxiangGo)
        self.m_baoxiangGo = nil
    end

    for _, item in ipairs(self.m_awardItemList) do
        item:Delete()
    end
    self.m_awardItemList = nil

	base.OnDestroy(self)
end

return UIGraveCopySettlementView