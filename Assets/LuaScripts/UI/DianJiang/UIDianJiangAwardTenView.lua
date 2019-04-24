local isEditor = CS.GameUtility.IsEditor()
local EditorApplication = CS.UnityEditor.EditorApplication
local SceneManager = CS.UnityEngine.SceneManagement.SceneManager 
local LoadSceneMode = CS.UnityEngine.SceneManagement.LoadSceneMode
local AssetBundleConfig = CS.AssetBundles.AssetBundleConfig
local Vector3 = Vector3
local GameObject = CS.UnityEngine.GameObject
local Language = Language
local string_format = string.format
local math_floor = math.floor
local table_remove = table.remove
local table_insert = table.insert
local UIGameObjectLoader = UIGameObjectLoader
local UIUtil = UIUtil
local UIWuJiangCardItem = require "UI.UIWuJiang.View.UIWuJiangCardItem"
local PBUtil = PBUtil
local UIImage = UIImage
local AtlasConfig = AtlasConfig
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local ItemMgr = Player:GetInstance():GetItemMgr()

local LocalEulerAngles = Vector3.New(0, 0, -50)
local TweenDeltaTime = 0.2

local dianjiangMgr = Player:GetInstance():GetDianjiangMgr()


local UIDianJiangAwardTenView = BaseClass("UIDianJiangAwardTenView", UIBaseView)
local base = UIBaseView

function UIDianJiangAwardTenView:OnCreate()
    base.OnCreate(self)

    self.m_wujiangCardItemList = {}

    self.m_iconRoot, self.m_backBtn, self.m_continueBtn, self.m_moneyImg = UIUtil.GetChildTransforms(self.transform, {
        "Container/IconRoot", "Container/Back_BTN", "Container/Continue_BTN", "Container/Continue_BTN/TongQianImage",
    })
   
    self.m_moneyComp = UIUtil.AddComponent(UIImage, self, "Container/Continue_BTN/TongQianImage", AtlasConfig.Common)

    self.m_backText, self.m_moneyText, self.m_continueText = UIUtil.GetChildTexts(self.transform, {
        "Container/Back_BTN/Text", "Container/Continue_BTN/TongQianImage/TongQianText", "Container/Continue_BTN/Text"
    })

    self.m_backText.text = Language.GetString(5)
    self.m_continueText.text = Language.GetString(1253)

    self:HandleClick()

    coroutine.start(UIDianJiangAwardTenView.MoneyCenter, self)
end

function UIDianJiangAwardTenView:OnEnable(...)
    base.OnEnable(self, ...)

    local _, recruit_type, awardObj, showImmediate = ...
    
    self.m_recuitType = recruit_type
    self.m_awardItemIndex = 0

    local curItem = 0
    if self.m_recuitType == CommonDefine.RT_N_CALL_1 or self.m_recuitType == CommonDefine.RT_N_CALL_10 then
        curItem = ItemMgr:GetItemCountByID(ItemDefine.TongQian_ID)
        self.m_moneyComp:SetAtlasSprite("10001.png", false, AtlasConfig.ItemIcon)
    elseif self.m_recuitType == CommonDefine.RT_S_CALL_1 or self.m_recuitType == CommonDefine.RT_S_CALL_10 then
        curItem = Player:GetInstance():GetUserMgr():GetUserData().yuanbao
        self.m_moneyComp:SetAtlasSprite("10002.png", false, AtlasConfig.ItemIcon)
    elseif self.m_recuitType == CommonDefine.RT_S_CALL_ITEM then
        curItem = ItemMgr:GetItemCountByID(ItemDefine.DIANJIANGLING_ID)
        self.m_moneyComp:SetAtlasSprite("20054.png", false, AtlasConfig.ItemIcon)    --todo 点将令icon
    end

    local needItem = dianjiangMgr:GetCallPrice(self.m_recuitType)
    self.m_moneyText.text = string_format(curItem >= needItem and Language.GetString(2614) or Language.GetString(2634), needItem)

    self:UpdatePanel(recruit_type, awardObj, showImmediate)
end

function UIDianJiangAwardTenView:OnDisable()
    for _, v in ipairs(self.m_wujiangCardItemList) do
        v:Delete()
    end
    self.m_wujiangCardItemList = {}

    self.m_awardList = nil
    self.m_awardItemIndex = 0

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)

    base.OnDisable(self)
end

function UIDianJiangAwardTenView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_continueBtn.gameObject, onClick)
end

function UIDianJiangAwardTenView:RemoveEvent()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_continueBtn.gameObject)
end

function UIDianJiangAwardTenView:OnClick(go, x, y)
    local name = go.name    
    if name == "Back_BTN" then
        if #self.m_awardList > 0 then
            return
        end
        self:CloseSelf()
    elseif name == "Continue_BTN" then
        if #self.m_awardList > 0 then
            return
        end

        if self.m_recuitType == CommonDefine.RT_S_CALL_10 then
            local needYuanbao = dianjiangMgr:GetCallPrice(CommonDefine.RT_S_CALL_10)
            local yuanbao = Player:GetInstance():GetUserMgr():GetUserData().yuanbao
            if needYuanbao <= 0 or needYuanbao <= yuanbao then
                UIManagerInst:OpenWindow(UIWindowNames.UIDrum, CommonDefine.RT_S_CALL_10)
            else
                UILogicUtil.FloatAlert(ErrorCode.GetString(5))
            end
        else
            dianjiangMgr:ReqRecuit(self.m_recuitType)
        end
    end
end

function UIDianJiangAwardTenView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_DIANJIANG_ON_RECURIT, self.UpdatePanel)
end

function UIDianJiangAwardTenView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:RemoveUIListener(UIMessageNames.MN_DIANJIANG_ON_RECURIT, self.UpdatePanel)
end

function UIDianJiangAwardTenView:UpdatePanel(recruit_type, awardObj, showImmediate)
    for _, v in ipairs(self.m_wujiangCardItemList) do
        v:Delete()
    end
    self.m_wujiangCardItemList = {} 
    self.m_awardList = awardObj.normal_award_list
    self.m_awardItemIndex = 0

    if showImmediate then
        self:ShowAwardsImmediate()
    else
        self:CheckShowAward()
    end 

    coroutine.start(self.DelayGetAdditionalAward, self, awardObj)
end

function UIDianJiangAwardTenView:DelayGetAdditionalAward(awardObj)
    coroutine.waitforseconds(1)
    if #awardObj.addition_award_list > 0 then
        local uiData = 
        {
            openType = 1,
            awardDataList = awardObj.addition_award_list,
        }

        UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
    end
end

function UIDianJiangAwardTenView:ShowAwardsImmediate()
    self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObjects(self.m_seq, TheGameIds.CommonWujiangCardPrefab, #self.m_awardList, function(objs)
        self.m_seq = 0
        for i = 1, #objs do
            local cardItem = UIWuJiangCardItem.New(objs[i], self.m_iconRoot, TheGameIds.CommonWujiangCardPrefab)
            cardItem:SetData(PBUtil.ConvertWujiangDataToBrief(self.m_awardList[i]:GetWujiangData()))
            local index = math_floor((i-1) / 5)
            local index2 = math_floor((i-1) % 5)
            cardItem:SetAnchoredPosition(Vector3.New(-365 + 190 * index2, 375 - 225 * index, 0))
            cardItem:SetLocalScale(Vector3.zero)
            table_insert(self.m_wujiangCardItemList, cardItem)
        end
        self.m_awardList = {}

        self.m_wujiangIndex = 1
        coroutine.start(self.TweenShow, self)
    end)
end

function UIDianJiangAwardTenView:TweenShow()
    while self.m_wujiangIndex <= #self.m_wujiangCardItemList do
        local cardItem = self.m_wujiangCardItemList[self.m_wujiangIndex]
        local cardItemTran = cardItem:GetTransform()
        if cardItemTran then
            DOTweenShortcut.DOScale(cardItemTran, 1, 0.1)
        end
        self.m_wujiangIndex = self.m_wujiangIndex + 1
        coroutine.waitforseconds(0.1)
    end
end

function UIDianJiangAwardTenView:CheckShowAward()
    if #self.m_awardList > 0 then
        local awardData = self.m_awardList[1]
        table_remove(self.m_awardList, 1)

        self:ShowAwardItem(awardData)
    end
end

function UIDianJiangAwardTenView:ShowAwardItem(awardData)
    if awardData then

        -- print(' --------------------------- award ', table.dump(awardData))
        local oneWujiang = awardData:GetWujiangData()
        if oneWujiang then
            self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, TheGameIds.CommonWujiangCardPrefab, function(go)
                self.m_seq = 0
                if not IsNull(go) then
                    local cardItem = UIWuJiangCardItem.New(go, self.m_iconRoot, TheGameIds.CommonWujiangCardPrefab)
                    cardItem:SetData(PBUtil.ConvertWujiangDataToBrief(oneWujiang))
                    cardItem:SetLocalEulerAngles(LocalEulerAngles)

                    local index = math_floor(self.m_awardItemIndex / 5)
                    local index2 = math_floor(self.m_awardItemIndex % 5)
                    local targetPos =  Vector3.New(-365 + 190 * index2, 370 - 210 * index, 0)
                    DOTweenShortcut.DOLocalMove(cardItem:GetTransform(), targetPos, TweenDeltaTime)
                    local tweener = DOTweenShortcut.DOLocalRotate(cardItem:GetTransform(), Vector3.zero, TweenDeltaTime)
                    DOTweenSettings.OnComplete(tweener, function()
                        self:CheckShowAward()
                    end)

                    self.m_awardItemIndex = self.m_awardItemIndex + 1
                    table_insert(self.m_wujiangCardItemList, cardItem)
                end
            end)
        end
    end
end

function UIDianJiangAwardTenView:OnDestroy()
    self:RemoveEvent()
    base.OnDestroy(self)
end

function UIDianJiangAwardTenView:MoneyCenter()
    coroutine.waitforframes(1)
    UIUtil.KeepCenterAlign(self.m_moneyImg, self.m_continueBtn)
end

return UIDianJiangAwardTenView