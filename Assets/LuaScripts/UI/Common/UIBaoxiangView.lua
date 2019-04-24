

local UIBaoxiangView = BaseClass("UIBaoxiangView", UIBaseView)
local base = UIBaseView

local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local GameUtility = CS.GameUtility
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab 
local Type_Image = typeof(CS.UnityEngine.UI.Image)
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings

local LocalEulerAngles = Vector3.New(0, 0, -50)
local TweenDeltaTime = 0.2

function UIBaoxiangView:OnCreate()
	base.OnCreate(self)
    
    self.m_bagItemList = {}

	self.m_baoxiangRootTran, self.m_awardParentTran, self.m_closeBtn = UIUtil.GetChildTransforms(self.transform, {
        "Container/BaoxiangRoot",
        "Container/AwardList",
        "CloseBtn"
    })
    
    self:AddComponent(UICanvas, "Container/AwardList", 3)


    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
end

function UIBaoxiangView:OnClick(go)

    if go.name == "CloseBtn" then
        if self.m_awardCount == self.m_awardItemIndex then
            self:CloseSelf()   
        end
    end
end

function UIBaoxiangView:OnEnable(...)
    base.OnEnable(self, ...)
    
    local _, awardList = ...
    self.m_awardList = awardList

    self.m_awardCount = 0
    self.m_awardItemIndex = 0

    if not self.m_awardList then
        return
    end
    
    self.m_awardCount = #self.m_awardList

    self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, TheGameIds.Baoxiang2Prefab, function(go)
        self.m_seq = 0
        if not IsNull(go) then

            self.m_baoxiangGo = go

            local baoxiangTran = go.transform
            GameUtility.RecursiveSetLayer(go, Layers.UI)
            baoxiangTran:SetParent(self.m_baoxiangRootTran)
            baoxiangTran.localPosition = Vector3.New(0, 0, -3)
            baoxiangTran.localScale = Vector3.one

            local animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
            if animator then
                GameUtility.ForceCrossFade(animator, "baoxiang2", 0)
            end

            coroutine.start(self.ShowAwardList, self)
        end
    end)
end


function UIBaoxiangView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    base.OnDestroy(self)
end

function UIBaoxiangView:ShowAwardList()
    coroutine.waitforseconds(0.6)

    self:CheckShowAward()
end

function UIBaoxiangView:CheckShowAward()
    if #self.m_awardList > 0 then
        local awardData = self.m_awardList[1]
        table_remove(self.m_awardList, 1)

        self:ShowAwardItem(awardData)
    end
end

function UIBaoxiangView:ShowAwardItem(awardData)
    if awardData then
        local CreateAwardParamFromAwardData = PBUtil.CreateAwardParamFromAwardData
        local itemData = awardData:GetItemData()
        if itemData then
            self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, CommonAwardItemPrefab, function(go)
                self.m_seq = 0
                if not IsNull(go) then
                    local bagItem = CommonAwardItem.New(go, self.m_awardParentTran, CommonAwardItemPrefab)
                    bagItem:SetLocalEulerAngles(LocalEulerAngles)
                    local itemIconParam = CreateAwardParamFromAwardData(awardData) 
                    bagItem:UpdateData(itemIconParam)
    
                    local index = math_floor(self.m_awardItemIndex / 5)
                    local index2 = math_floor(self.m_awardItemIndex % 5)
                    local targetPos =  Vector3.New(-400 + 200 * index2, 400 - 180 * index, 0)
                    DOTweenShortcut.DOLocalMove(bagItem:GetTransform(), targetPos, TweenDeltaTime)
                    local tweener = DOTweenShortcut.DOLocalRotate(bagItem:GetTransform(), Vector3.zero, TweenDeltaTime)
                    DOTweenSettings.OnComplete(tweener, function()
                        self:CheckShowAward()
                    end)

                    self.m_awardItemIndex = self.m_awardItemIndex + 1
                    table_insert(self.m_bagItemList, bagItem)
                end
            end)
        end
    end
end

function UIBaoxiangView:OnDisable()
    if not IsNull(self.m_baoxiangGo) then
        GameObjectPoolInst:RecycleGameObject(TheGameIds.Baoxiang2Prefab, self.m_baoxiangGo)
        self.m_baoxiangGo = nil
    end

    for _, item in ipairs(self.m_bagItemList) do
        item:Delete()
    end
    self.m_bagItemList = {}

    base.OnDisable(self)
end

return UIBaoxiangView