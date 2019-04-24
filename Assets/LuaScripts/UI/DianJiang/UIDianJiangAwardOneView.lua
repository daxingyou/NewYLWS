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
local UIGameObjectLoader = UIGameObjectLoader
local TheGameIds = TheGameIds
local UIUtil = UIUtil
local UIWuJiangCardItem = require "UI.UIWuJiang.View.UIWuJiangCardItem"
local PBUtil = PBUtil
local UIImage = UIImage
local AtlasConfig = AtlasConfig
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local ItemMgr = Player:GetInstance():GetItemMgr()

local LocalEulerAngles = Vector3.New(0, 0, -50)
local CardBornPos = Vector3.New(0, -239, 800)

local TweenDeltaTime = 0.2

local dianjiangMgr = Player:GetInstance():GetDianjiangMgr()


local UIDianJiangAwardOneView = BaseClass("UIDianJiangAwardOneView", UIBaseView)
local base = UIBaseView

function UIDianJiangAwardOneView:OnCreate()
    base.OnCreate(self)

    self.m_wujiangCardItem = nil

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

    coroutine.start(UIDianJiangAwardOneView.MoneyCenter, self)
end

function UIDianJiangAwardOneView:OnEnable(...)
    base.OnEnable(self, ...)

    local _, recruit_type, awardObj = ...
    
    self.m_recuitType = recruit_type

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

    if self.m_recuitType == 0 then
        self.m_continueBtn.gameObject:SetActive(false)
        local p = self.m_backBtn.transform.localPosition
        self.m_backBtn.transform.localPosition = Vector3.New(0, p.y, p.z)
    else
        self.m_continueBtn.gameObject:SetActive(true)
        local p = self.m_backBtn.transform.localPosition
        self.m_backBtn.transform.localPosition = Vector3.New(-156, p.y, p.z)
        
        local needItem = dianjiangMgr:GetCallPrice(self.m_recuitType)
        self.m_moneyText.text = string_format(curItem >= needItem and Language.GetString(2614) or Language.GetString(2634), needItem)
    end

    self:UpdatePanel(recruit_type, awardObj)
end

function UIDianJiangAwardOneView:OnDisable()
    if self.m_wujiangCardItem then
        self.m_wujiangCardItem:Delete()
        self.m_wujiangCardItem = nil
    end

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)

    base.OnDisable(self)
end

function UIDianJiangAwardOneView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_continueBtn.gameObject, onClick)
end

function UIDianJiangAwardOneView:RemoveEvent()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_continueBtn.gameObject)
end

function UIDianJiangAwardOneView:OnClick(go, x, y)
    local name = go.name
    if name == "Back_BTN" then
        if self.m_tweening then
            return
        end
        TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, self.winName)
        self:CloseSelf()
    elseif name == "Continue_BTN" then
        if self.m_tweening then
            return
        end

        if self.m_recuitType == CommonDefine.RT_S_CALL_1 then
            local needYuanbao = dianjiangMgr:GetCallPrice(CommonDefine.RT_S_CALL_1)
            local yuanbao = Player:GetInstance():GetUserMgr():GetUserData().yuanbao
            if needYuanbao <= 0 or needYuanbao <= yuanbao then
                UIManagerInst:OpenWindow(UIWindowNames.UIDrum, CommonDefine.RT_S_CALL_1)
            else
                UILogicUtil.FloatAlert(ErrorCode.GetString(5))
            end
        elseif self.m_recuitType == CommonDefine.RT_S_CALL_ITEM then
            local itemCount = Player:GetInstance():GetItemMgr():GetItemCountByID(ItemDefine.DIANJIANGLING_ID)
            local needItemCount = dianjiangMgr:GetCallPrice(CommonDefine.RT_S_CALL_ITEM)
            if needItemCount <= 0 or needItemCount <= itemCount then
                UIManagerInst:OpenWindow(UIWindowNames.UIDrum, CommonDefine.RT_S_CALL_ITEM)
            else
                UILogicUtil.FloatAlert(ErrorCode.GetString(501))
            end
        else
            dianjiangMgr:ReqRecuit(self.m_recuitType)
        end
    end
end

function UIDianJiangAwardOneView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_DIANJIANG_ON_RECURIT, self.UpdatePanel)
end

function UIDianJiangAwardOneView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:RemoveUIListener(UIMessageNames.MN_DIANJIANG_ON_RECURIT, self.UpdatePanel)
end

function UIDianJiangAwardOneView:UpdatePanel(recruit_type, awardObj)
    if self.m_wujiangCardItem then
        self.m_wujiangCardItem:Delete()
        self.m_wujiangCardItem = nil
    end

    local awardData = awardObj.normal_award_list[1]
    if awardData then
        self:ShowAwardItem(awardData)
    end

     coroutine.start(self.DelayGetAdditionalAward, self, awardObj)
end

function UIDianJiangAwardOneView:DelayGetAdditionalAward(awardObj)
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

function UIDianJiangAwardOneView:ShowAwardItem(awardData)
    local oneWujiang = awardData:GetWujiangData()
    if oneWujiang then
        self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, TheGameIds.CommonWujiangCardPrefab, function(go)
            self.m_seq = 0
            if not IsNull(go) then
                local cardItem = UIWuJiangCardItem.New(go, self.m_iconRoot, TheGameIds.CommonWujiangCardPrefab)
                cardItem:SetData(PBUtil.ConvertWujiangDataToBrief(oneWujiang))
                cardItem:SetLocalEulerAngles(LocalEulerAngles)
                cardItem:SetLocalPosition(CardBornPos)

                self.m_tweening = true

                local targetPos =  self.m_iconRoot.position
                DOTweenShortcut.DOLocalMove(cardItem:GetTransform(), targetPos, TweenDeltaTime)
                local tweener = DOTweenShortcut.DOLocalRotate(cardItem:GetTransform(), Vector3.zero, TweenDeltaTime)
                DOTweenSettings.OnComplete(tweener, function()
                    self.m_tweening = false
                end)

                self.m_wujiangCardItem = cardItem
            end
        end)
    end
end

function UIDianJiangAwardOneView:OnDestroy()
    self:RemoveEvent()
    base.OnDestroy(self)
end

function UIDianJiangAwardOneView:MoneyCenter()
    coroutine.waitforframes(1)
    UIUtil.KeepCenterAlign(self.m_moneyImg, self.m_continueBtn)
end

function UIDianJiangAwardOneView:OnTweenOpenComplete()
    TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
end

return UIDianJiangAwardOneView