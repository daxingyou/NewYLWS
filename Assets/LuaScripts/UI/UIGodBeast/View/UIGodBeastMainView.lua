local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local UILogicUtil = UILogicUtil
local GameObject = CS.UnityEngine.GameObject
local ConfigUtil = ConfigUtil
local SafePack = SafePack
local Vector3 = Vector3
local Vector2 = Vector2
local string_format = string.format
local string_split = CUtil.SplitString
local string_find = string.find
local string_sub = string.sub
local table_insert = table.insert
local table_remove = table.remove
local tonumber = tonumber
local math_ceil = math.ceil
local BagItemPath = TheGameIds.CommonBagItemPrefab
local BattleEnum = BattleEnum
local GameUtility = CS.GameUtility

local TypeText = typeof(CS.TMPro.TextMeshProUGUI)
local UIGameObjectLoader = UIGameObjectLoader:GetInstance()
local ItemMgr = Player:GetInstance():GetItemMgr()
local GodBeastMgr = Player:GetInstance():GetGodBeastMgr()
local MountMgr = Player:GetInstance():GetMountMgr()

local GodBeastObjPath = "UI/Prefabs/GodBeast/GodBeastObj.prefab"
local UIGodBeastSkillItem = require "UI.UIGodBeast.View.UIGodBeastSkillItem"
local UIGodBeastTalentItem = require "UI.UIGodBeast.View.UIGodBeastTalentItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local UIBagItem = require "UI.UIBag.View.BagItem"
local ItemData = require "DataCenter.ItemData.ItemData"
local GodBsestDetailMountHelperClass = require "UI.UIGodBeast.View.GodBsestDetailMountHelper"

local UIGodBeastMainView = BaseClass("UIGodBeastMainView", UIBaseView)
local base = UIBaseView

local BtnTypeArr = {
    Upgrade = 1,
    Talent = 2,
    Awaken = 3,
    Max = 4,
}

local DataChgReason = {
    LevelUp = 1,
    ActivateSkill = 2,
    MakeAwaken = 3,
    NewTalent = 4,
    ForgetTalent = 5,
    Max = 6,
}

local EFFECT_SCALE = Vector3.one * 3.7

function UIGodBeastMainView:OnCreate()
    base.OnCreate(self)

    self:InitVariable()
    self:InitView()
end

-- 初始化非UI变量
function UIGodBeastMainView:InitVariable()
    self.m_showBtnLayer = BtnTypeArr.Upgrade
    self.m_skilliconList = {}
    self.m_talentSlotList = {}
    self.m_reqExpData = {
        itemId = 0,
        count = 0,
        addExp = 0
    }
    self.m_tmpGodBeastData = {}
    self.m_layerName = UILogicUtil.FindLayerName(self.transform)
    self.m_offeringItemDataList = {}
    self.m_offeringItemList = {}
    self.m_sellectTalent = 0
    self.m_currSelectHorseIndex = 0
    self.m_tmpForgetScore = 0
    self.m_tmpForgetCostList = {}
    self.m_tmpForgetItemList = {}
    self.m_offeringFlag = false
    self.m_totalExpItemCount = 0
    self.m_LVNumList = string_split(Language.GetString(3630), ",")

    self.m_detailHelper = GodBsestDetailMountHelperClass.New(self.transform, self)
end

-- 初始化UI变量
function UIGodBeastMainView:InitView()

    local btnContentPathList = {}
    local btnContentTextPathList = {}
    for i = 1, BtnTypeArr.Max - 1 do
        local btnContentPath = "Container/panel/Left/contentBtn" .. i
        local btnContentTextPath = btnContentPath .. "/contentBtnText"..i
        btnContentPathList[i] = btnContentPath
        btnContentTextPathList[i] = btnContentTextPath
    end
    self.m_contentBtnTransList = SafePack(UIUtil.GetChildRectTrans(self.transform, btnContentPathList))
    local contentBtnTextList = SafePack(UIUtil.GetChildTexts(self.transform, btnContentTextPathList))
    self.m_tabBtnActiveImageList = {}
    local btnNameArr = string_split(Language.GetString(3601), ",")
    for i = 1, #contentBtnTextList do
        if i <= #btnNameArr then
            contentBtnTextList[i].text = btnNameArr[i]
        end
        local image = self:AddComponent(UIImage, btnContentPathList[i], AtlasConfig.DynamicLoad)
        if image then
            if i == 1 then
                image:SetAtlasSprite("dk02.png", false)
            else
                image:SetAtlasSprite("dik01.png", false)
            end
            self.m_tabBtnActiveImageList[i] = image
        end
    end

    local textTitlePathList = {}
    local textContentPathList = {}
    for i = 1, 3 do
        local textTitlePath = "Container/comentRoot/upgradeContent/rail"..i.."/titleText"..i
        local textContentPath = "Container/comentRoot/upgradeContent/rail"..i.."/contentText"..i
        textTitlePathList[i] = textTitlePath
        textContentPathList[i] = textContentPath
    end
    local titleTextList = SafePack(UIUtil.GetChildTexts(self.transform, textTitlePathList))
    local contentTextList = SafePack(UIUtil.GetChildTexts(self.transform, textContentPathList))
    local titleNameArr = string_split(Language.GetString(3602), ",")
    for i = 1, #titleTextList do
        if i <= #titleNameArr then
            titleTextList[i].text = titleNameArr[i]
            contentTextList[i].text = Language.GetString(3602 + i)
        end
    end

    local textPathList = {}
    for i = 1, 3 do
        local textPath = "Container/comentRoot/awakenContent/materialCountContent/itemText"..i
        textPathList[i] = textPath
    end
    self.m_awakeItemCountTextList = SafePack(UIUtil.GetChildTexts(self.transform, textPathList))


    self.m_backBtn, self.m_skillItemPrefab, self.m_upgradeContent, self.m_talentContent, self.m_awakenComent,
    self.m_upgradeNeedContent, self.m_upgradeSkillContent, self.m_talentItemContent, self.m_awakeBtn, self.m_awakenMaterialContent,
    self.m_rightSkillDetail, self.m_backCloseBtn, self.m_skillDetailLockTrans, self.m_talentItemPrefab, self.m_offeringContent,
    self.m_forgetContent, self.m_offeringItemContent, self.m_offeringBtn, self.m_forgetItemContent, self.m_forgetBtn, self.m_showAllTalentBtn,
    self.m_arrowsImage, self.m_materialCountContent, self.m_offeringCase, self.m_ruleBtnTr = UIUtil.GetChildTransforms(self.transform, {
        "Container/panel/backBtn",
        "skillItemPrefab",
        "Container/comentRoot/upgradeContent",
        "Container/comentRoot/talentContent",
        "Container/comentRoot/awakenContent",
        "Container/comentRoot/upgradeContent/rail1/needContent",
        "Container/comentRoot/upgradeContent/rail3/skillContent",
        "Container/comentRoot/talentContent/talentItemContent",
        "Container/comentRoot/awakenContent/awakeBtn",
        "Container/comentRoot/awakenContent/materialContent",
        "Container/comentRoot/upgradeContent/rightSkillDetail",
        "Container/backCloseBtn",
        "Container/comentRoot/upgradeContent/rightSkillDetail/lockText",
        "talentItemPrefab",
        "Container/comentRoot/talentContent/offeringContent",
        "Container/comentRoot/talentContent/forgetContent",
        "Container/comentRoot/talentContent/offeringContent/ItemScrollView/Viewport/ItemContent",
        "Container/comentRoot/talentContent/offeringContent/Top/offeringBtn",
        "Container/comentRoot/talentContent/forgetContent/Bottom/forgetItemContent",
        "Container/comentRoot/talentContent/forgetContent/Bottom/forgetBtn",
        "Container/comentRoot/talentContent/forgetContent/Top/showAllBtn",
        "Container/comentRoot/awakenContent/awakeTitle/arrowsImage",
        "Container/comentRoot/awakenContent/materialCountContent",
        "Container/comentRoot/talentContent/offeringContent/Top/offerinBg/offeringCase",
        "Container/comentRoot/talentContent/offeringContent/RuleBtn"
    })

    local awakeBtnText, offeringText, offeringBtnText, forgetProcessText, forgetBtnText, talentExplainText, showAllTalentText
    awakeBtnText, self.m_upgradeMainSkillText, self.m_awakeText1, self.m_awakeText2, self.m_awakeContentText,
    self.m_expText, self.m_LvText, self.m_skillDetailDesText, self.m_skillDetailLockText, offeringText, self.m_offeringScoreText,
    offeringBtnText, forgetProcessText, self.m_forgetProcessText, forgetBtnText, self.m_talentNameText, self.m_talentDesText,
    talentExplainText, self.m_awakeText1, self.m_awakeText2, self.m_awakeContentText = UIUtil.GetChildTexts(self.transform, {
        "Container/comentRoot/awakenContent/awakeBtn/awakeBtnText",
        "Container/comentRoot/upgradeContent/rail2/mainSkillText",
        "Container/comentRoot/awakenContent/awakeTitle/awakeText1",
        "Container/comentRoot/awakenContent/awakeTitle/awakeText2",
        "Container/comentRoot/awakenContent/contentText",
        "Container/comentRoot/godBeastBaseRoot/ExpSilder/ExpText",
        "Container/comentRoot/godBeastBaseRoot/LvText",
        "Container/comentRoot/upgradeContent/rightSkillDetail/skillDesText",
        "Container/comentRoot/upgradeContent/rightSkillDetail/lockText",
        "Container/comentRoot/talentContent/offeringContent/Top/offeringText",
        "Container/comentRoot/talentContent/offeringContent/Top/offeringText/offeringScoreText",
        "Container/comentRoot/talentContent/offeringContent/Top/offeringBtn/offeringBtnText",
        "Container/comentRoot/talentContent/forgetContent/Bottom/processText",
        "Container/comentRoot/talentContent/forgetContent/Bottom/processText/processNumText",
        "Container/comentRoot/talentContent/forgetContent/Bottom/forgetBtn/forgetBtnText",
        "Container/comentRoot/talentContent/forgetContent/Top/talentNameText",
        "Container/comentRoot/talentContent/forgetContent/Top/talentDesText",
        "Container/comentRoot/talentContent/forgetContent/Top/talentExplainText",
        "Container/comentRoot/awakenContent/awakeTitle/awakeText1",
        "Container/comentRoot/awakenContent/awakeTitle/awakeText2",
        "Container/comentRoot/awakenContent/contentText",
    })

    local showAllTalentText = UIUtil.FindComponent(self.transform, TypeText, "Container/comentRoot/talentContent/forgetContent/Top/showAllBtn")

    self.m_expSilder = UIUtil.FindSlider(self.transform, "Container/comentRoot/godBeastBaseRoot/ExpSilder")
    self.m_forgetSilder = UIUtil.FindSlider(self.transform, "Container/comentRoot/talentContent/forgetContent/Bottom/forgetSilder")

    self.m_skillDetaiIconImage = UIUtil.AddComponent(UIImage, self, "Container/comentRoot/upgradeContent/rightSkillDetail/skillBg/SkillIcon", ImageConfig.GodBeast)
    self.m_offeringIconImage = UIUtil.AddComponent(UIImage, self, "Container/comentRoot/talentContent/offeringContent/Top/offerinBg/offeringItemIcon", AtlasConfig.ItemIcon)
    self.m_forgetIconImage = UIUtil.AddComponent(UIImage, self, "Container/comentRoot/talentContent/forgetContent/Top/talentBg/talentIcon", ImageConfig.GodBeast)

    self.m_skillItemPrefab = self.m_skillItemPrefab.gameObject
    self.m_talentItemPrefab = self.m_talentItemPrefab.gameObject

    awakeBtnText.text = Language.GetString(3606)
    offeringText.text = Language.GetString(3615)
    offeringBtnText.text = Language.GetString(3614)
    forgetProcessText.text = Language.GetString(3616)
    forgetBtnText.text = Language.GetString(3617)
    talentExplainText.text = Language.GetString(3618)
    showAllTalentText.text = Language.GetString(3619)
    self.m_offeringScoreText.text = "0"
end

function UIGodBeastMainView:OnEnable(...)
    base.OnEnable(self, ...)
    local order
    order, self.m_GodBeastData = ...  
    self.m_GodBeastBaseInfo = ConfigUtil.GetGodBeastCfgByID(self.m_GodBeastData.dragon_id)

    if self.m_GodBeastBaseInfo and self.m_GodBeastData then  
        self:UpdateData()
        self:HandleClick()
        self:CreateRoleContainer()
        self:UpdateExp(self.m_GodBeastData)
    end
    GameUtility.SetSceneGOActive("Fortress", "DirectionalLight_Shadow", false)
end

function UIGodBeastMainView:OnDisable()
    self:RemoveClick()
    self:ClearCurrSelectItem()
    self.m_sellectTalent = 0

    if self.m_skilliconList then
        for i, v in ipairs(self.m_skilliconList) do
            v:Delete()
        end
        self.m_skilliconList = nil
    end

    if self.m_talentSlotList then
        for i, v in pairs(self.m_talentSlotList) do
            v:Delete()
        end
        self.m_talentSlotList = nil
    end

    if self.m_upgradeItemList then
        for i, v in ipairs(self.m_upgradeItemList) do
            UIUtil.RemoveEvent(v:GetGameObject())
            GameUtility.SetUIGray(v:GetGameObject(), false)   
            v:Delete()
        end
        self.m_upgradeItemList = nil
    end

    if self.m_sliderEffect then
        self.m_sliderEffect:Delete()
        self.m_sliderEffect = nil
        UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)
    end

    if self.m_forgetItemList then
        for i, v in ipairs(self.m_forgetItemList) do
            UIUtil.RemoveEvent(v:GetGameObject())
            GameUtility.SetUIGray(v:GetGameObject(), false)   
            v:Delete()
        end
        self.m_forgetItemList = {}
    end

    if self.m_awakenItemList then
        for i, v in ipairs(self.m_awakenItemList) do
            v:Delete()
        end
        self.m_awakenItemList = nil
    end

    if self.m_offeringItemList then
        for i, v in ipairs(self.m_offeringItemList) do
            UIUtil.RemoveEvent(v:GetGameObject())
            GameUtility.SetUIGray(v:GetGameObject(), false)   
            v:Delete()
        end
        self.m_offeringItemList = {}
    end
    self.m_totalExpItemCount = 0
    GameUtility.SetSceneGOActive("Fortress", "DirectionalLight_Shadow", true)

    self:ShowSkillDetail(false)
    self:ShowTalentDetail(false)
    self:DestroyRoleContainer()

    base.OnDisable(self)
end

function UIGodBeastMainView:OnAddListener()
    base.OnAddListener(self)
    self:AddUIListener(UIMessageNames.MN_GODBEAST_DATA_CHG, self.OnUpdataGodBeastData)
    self:AddUIListener(UIMessageNames.MN_GODBEAST_SURE_FORGET_TALENT,self.SureForgetTalent)
    self:AddUIListener(UIMessageNames.MN_BAG_ITEM_CHG,self.UpdateAwakenMaterials)
	-- UI消息注册
end

function UIGodBeastMainView:OnRemoveListener()
    base.OnRemoveListener(self)
    self:RemoveUIListener(UIMessageNames.MN_GODBEAST_DATA_CHG, self.OnUpdataGodBeastData)
    self:RemoveUIListener(UIMessageNames.MN_GODBEAST_SURE_FORGET_TALENT, self.SureForgetTalent)
    self:RemoveUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.UpdateAwakenMaterials)
	-- UI消息注销
end

function UIGodBeastMainView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_backCloseBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_awakeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_offeringBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_forgetBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_showAllTalentBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_offeringCase.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_ruleBtnTr.gameObject, onClick)
    for i = 1, #self.m_contentBtnTransList do
        UIUtil.AddClickEvent(self.m_contentBtnTransList[i].gameObject, onClick)
    end
end

function UIGodBeastMainView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_backCloseBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_awakeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_offeringBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_forgetBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_showAllTalentBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtnTr.gameObject)
    for i = 1, #self.m_contentBtnTransList do
        UIUtil.RemoveClickEvent(self.m_contentBtnTransList[i].gameObject)
    end
end

function UIGodBeastMainView:OnClick(go, x, y)
    if not go then
        return
    end
    local goName = go.name
    if goName == "contentBtn1" then
        self.m_upgradeContent.gameObject:SetActive(false)
        self.m_talentContent.gameObject:SetActive(false)
        self.m_awakenComent.gameObject:SetActive(false)
        self.m_tabBtnActiveImageList[self.m_showBtnLayer]:SetAtlasSprite("dik01.png", false)
        self.m_tabBtnActiveImageList[1]:SetAtlasSprite("dk02.png", false)
        self.m_showBtnLayer = BtnTypeArr.Upgrade
        self:UpdateData()

    elseif goName == "contentBtn2" then
        self.m_upgradeContent.gameObject:SetActive(false)
        self.m_talentContent.gameObject:SetActive(false)
        self.m_awakenComent.gameObject:SetActive(false)
        self.m_tabBtnActiveImageList[self.m_showBtnLayer]:SetAtlasSprite("dik01.png", false)
        self.m_tabBtnActiveImageList[2]:SetAtlasSprite("dk02.png", false)
        self.m_showBtnLayer = BtnTypeArr.Talent
        self:UpdateData()

    elseif goName == "contentBtn3" then
        self.m_upgradeContent.gameObject:SetActive(false)
        self.m_talentContent.gameObject:SetActive(false)
        self.m_awakenComent.gameObject:SetActive(false)
        self.m_tabBtnActiveImageList[self.m_showBtnLayer]:SetAtlasSprite("dik01.png", false)  
        self.m_tabBtnActiveImageList[3]:SetAtlasSprite("dk02.png", false)
        self.m_showBtnLayer = BtnTypeArr.Awaken
        self:UpdateData()

    elseif goName == "backBtn" then
        self:CloseSelf()

    elseif goName == "backCloseBtn" then
        self:ShowSkillDetail(false)
        if self.m_detailHelper:IsShow() then
            self.m_detailHelper:Close()
        else
            self:ShowTalentDetail(false)
        end

    elseif goName == "offeringBtn" then
        if self.m_currSelectHorseIndex ~= 0 and self.m_sellectTalent ~= 0 then
            GodBeastMgr:ReqActiveTalent(self.m_GodBeastData.dragon_id, self.m_currSelectHorseIndex, self.m_sellectTalent)
        end
        TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, "UIGodBeastMainOfferingBtn")

    elseif goName == "forgetBtn" then
        if self.m_sellectTalent ~= 0 then
            if self.m_tmpForgetScore >= 100 then
                local talentData = GodBeastMgr:GetGodBeastTalentByID(self.m_GodBeastData.dragon_id, self.m_sellectTalent)
                local data = {
                    showType = 2,
                    godBeastId = self.m_GodBeastData.dragon_id,
                    talentInfo = talentData,
                }    
                UIManagerInst:OpenWindow(UIWindowNames.UIGodBeastTipsDialog, data)   
            else
                UILogicUtil.FloatAlert(Language.GetString(3632))
            end
        end

    elseif goName == "showAllBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGodBeastAllTalent) 

    elseif goName == "awakeBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(3606), Language.GetString(3622), 
        Language.GetString(10),function()
            GodBeastMgr:ReqAwakening(self.m_GodBeastData.dragon_id)
        end, Language.GetString(50), nil)

    elseif goName == "offeringCase" then
        self:ClearCurrSelectItem()
        UIUtil.TryBtnEnable(self.m_offeringBtn.gameObject, false)

    elseif goName == "RuleBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 138) 
    end
end

function UIGodBeastMainView:OnUpdataGodBeastData(oneGodBeastInfo, reason)
    if not oneGodBeastInfo then
        return
    end
    if reason == DataChgReason.LevelUp then
        if self.m_actorShow then
            self.m_actorShow:ShowEffect(10000,nil,nil,EFFECT_SCALE)
        end
    elseif reason == DataChgReason.ActivateSkill then
        local newSkillIndex = 0
        for k,v in pairs(self.m_GodBeastBaseInfo.unlocklevel) do
            if oneGodBeastInfo.level >= v then
                newSkillIndex = newSkillIndex + 1
            end
        end
        UIManagerInst:OpenWindow(UIWindowNames.UIGodBeastSkillDetail, self.m_GodBeastData.dragon_id, newSkillIndex)
    elseif reason == DataChgReason.MakeAwaken then
        if self.m_actorShow then
            self.m_actorShow:ShowEffect(10001,nil,nil,EFFECT_SCALE)
        end

        local data = {
            showType = 4,
            godBeastId = self.m_GodBeastData.dragon_id,
        }
        UIManagerInst:OpenWindow(UIWindowNames.UIGodBeastTipsDialog, data)

    elseif reason == DataChgReason.NewTalent then
        local talentData = GodBeastMgr:GetGodBeastTalentByID(self.m_GodBeastData.dragon_id, self.m_sellectTalent)
        local data = {
            showType = 1,
            godBeastId = self.m_GodBeastData.dragon_id,
            talentInfo = talentData,
        }
        self.m_offeringContent.gameObject:SetActive(false)
        self:UpdateForgetContent(self.m_sellectTalent, talentData)
        UIManagerInst:OpenWindow(UIWindowNames.UIGodBeastTipsDialog, data)
    elseif reason == DataChgReason.ForgetTalent then
        local talentData = GodBeastMgr:GetGodBeastTalentByID(self.m_GodBeastData.dragon_id, self.m_sellectTalent)
        self.m_forgetContent.gameObject:SetActive(false)
        self:UpdateOfferingContent(self.m_sellectTalent, talentData)
    end
    self.m_GodBeastData = oneGodBeastInfo
    self:UpdateData()
end

--更新界面
function UIGodBeastMainView:UpdateData()
    if not self.m_showBtnLayer then
        return
    end
    if self.m_showBtnLayer == BtnTypeArr.Upgrade then
        self:UpdateUpgradeData()
    elseif self.m_showBtnLayer == BtnTypeArr.Talent then
        self:UpdateTalentData()
    elseif self.m_showBtnLayer == BtnTypeArr.Awaken then
        self:UpdateAwakenData()
    end
end

--升级
function UIGodBeastMainView:UpdateUpgradeData()
    self:ResetFeedData()
    self:UpdateMainSkillDec()
    self:UpdateExp(self.m_GodBeastData)
    local item_list = self.m_GodBeastBaseInfo.nItemId
    if not self.m_upgradeItemList then
        self.m_upgradeItemList = {}
    end

    --升级道具
    for i=1,#item_list do
        local itemID = item_list[i]
        local count = ItemMgr:GetItemCountByID(itemID) or 0
        if itemID and itemID > 0 then
            local bagItem = self.m_upgradeItemList[i]
            if not bagItem then
                self.m_seq = UIGameObjectLoader:PrepareOneSeq()
                UIGameObjectLoader:GetGameObject(self.m_seq, BagItemPath, function(go)
                    self.m_seq = 0
                    if not IsNull(go) then
                        local bagItem = UIBagItem.New(go, self.m_upgradeNeedContent, BagItemPath)
                        bagItem.m_gameObject.name = itemID
                        table_insert(self.m_upgradeItemList, bagItem)
                        local itemCfg = ConfigUtil.GetItemCfgByID(itemID)
                        if itemCfg and count then
                            local itemIconParam = ItemIconParam.New(itemCfg, count)                          
                            bagItem:UpdateData(itemIconParam)
                            GameUtility.SetUIGray(bagItem:GetGameObject(), count == 0)
                            self:HandleExpItemPress(bagItem:GetGameObject())
                        end
                    end
                    TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
                end)
            else
                bagItem:UpdateItemCount(count)
                GameUtility.SetUIGray(bagItem:GetGameObject(), count == 0)
            end
        end
    end

    if not self.m_skilliconList then
        self.m_skilliconList = {}
    end
    for i = 1, 4 do
        local iconItem = self.m_skilliconList[i]
        local unlocked = self.m_GodBeastData.level >= self.m_GodBeastBaseInfo.unlocklevel[i] and 0 or self.m_GodBeastBaseInfo.unlocklevel[i]
        if not iconItem then
            local go = GameObject.Instantiate(self.m_skillItemPrefab)
            if not IsNull(go) then
               local iconItem  = UIGodBeastSkillItem.New(go, self.m_upgradeSkillContent)
               iconItem:SetData(self.m_GodBeastData.dragon_id, i, unlocked, Bind(self, self.ClickSkillItem))
               table_insert(self.m_skilliconList, iconItem)
            end
        else
            iconItem:SetData(self.m_GodBeastData.dragon_id, i, unlocked, Bind(self, self.ClickSkillItem))
        end
    end

    self.m_upgradeContent.gameObject:SetActive(true)
end

--技能
function UIGodBeastMainView:ClickSkillItem(iconItem)
    if iconItem then
        local lock = self.m_GodBeastData.level < self.m_GodBeastBaseInfo.unlocklevel[iconItem:GetSkillIndex()]
        self:ShowSkillDetail(true, iconItem:GetSkillIndex(), lock)
    end
end

function UIGodBeastMainView:GetSkillDecStr(str, skillCount)
    if str and skillCount then
        local y = self.m_GodBeastBaseInfo.y + self.m_GodBeastBaseInfo.ay * skillCount
        local y1 = math_ceil(y)
        y = y == y1 and y1 or y
        str = str:gsub("{y}", y)
        return str
    end
end

function UIGodBeastMainView:UpdateMainSkillDec() 
    local str = self.m_GodBeastBaseInfo.sSkillDesc
    local x = self.m_GodBeastBaseInfo.x + self.m_GodBeastBaseInfo.ax * self.m_GodBeastData.level
    local x1 = math_ceil(x)
    x = x == x1 and x1 or x
    local openSkillCount = 0
    for k,v in pairs(self.m_GodBeastBaseInfo.unlocklevel) do
        if self.m_GodBeastData.level >= v then
            openSkillCount = openSkillCount + 1
        end
    end
    str = str:gsub("{x}", x)
    str = self:GetSkillDecStr(str,openSkillCount)
    self.m_upgradeMainSkillText.text = self.m_GodBeastBaseInfo.sSkillName.."："..str
end

function UIGodBeastMainView:ShowSkillDetail(isShow, skillIndex, lock)
    if isShow then
        self.m_skillDetaiIconImage:SetAtlasSprite(self.m_GodBeastBaseInfo.id..skillIndex..".png", false)
        self.m_skillDetailDesText.text = self:GetSkillDecStr(self.m_GodBeastBaseInfo.extra_skill_des, skillIndex)
        self.m_skillDetailLockText.text = string_format(Language.GetString(3610), self.m_GodBeastBaseInfo.sName,self.m_GodBeastBaseInfo.unlocklevel[skillIndex])
        self.m_skillDetailLockTrans.gameObject:SetActive(lock)
    end
    self.m_rightSkillDetail.gameObject:SetActive(isShow)
    self:CheckSelectSkillIcon(isShow,skillIndex)
end

function UIGodBeastMainView:CheckSelectSkillIcon(isShow, skillIndex)
    if self.m_skilliconList then
        for i = 1, #self.m_skilliconList do
            if self.m_skilliconList[i] then
                local isSelect = false
                
                if isShow then
                    isSelect = skillIndex == self.m_skilliconList[i]:GetSkillIndex()
                end
                self.m_skilliconList[i]:SetSelect(isSelect)
            end
        end
    end
end

--天赋
function UIGodBeastMainView:UpdateTalentData()

    if not self.m_talentSlotList then
        self.m_talentSlotList = {}
    end

    local talentList = self.m_GodBeastData.dragon_talent_list
    local unlocked = talentList ~= nil
    for i = 1, 5 do
        local talentItem = self.m_talentSlotList[i]
        unlocked = unlocked and talentList[i] ~= nil or nil
        local talentInfo = unlocked and talentList[i] or nil
        if not talentItem then
            local go = GameObject.Instantiate(self.m_talentItemPrefab)
            if not IsNull(go) then
                go.name = i
                local talentItem  = UIGodBeastTalentItem.New(go, self.m_talentItemContent)
                talentItem:SetData(i, talentInfo, unlocked, Bind(self, self.ClickTalentItem))
                table_insert(self.m_talentSlotList, talentItem)
            end
        else
            self.m_talentSlotList[i]:SetData(i, talentInfo, unlocked, Bind(self, self.ClickTalentItem))
        end
    end

    self:ClearCurrSelectItem()
    UIUtil.TryBtnEnable(self.m_offeringBtn.gameObject, false)
    self.m_talentContent.gameObject:SetActive(true)

    if self.m_sellectTalent == 0 then
        self.m_sellectTalent = 1
    end
    local unlocked = talentList ~= nil
    unlocked = unlocked and talentList[self.m_sellectTalent] ~= nil or nil
    local talentInfo = unlocked and talentList[self.m_sellectTalent] or nil
    self:ShowTalentDetail(true, self.m_sellectTalent, talentInfo, unlocked)

    TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CHILD_UI_SHOW_END, "UIGodBeastMainTalnet")
end

--技能
function UIGodBeastMainView:ClickTalentItem(talentItem)
    if talentItem then
        self:ShowTalentDetail(true, talentItem:GetTalentIndex(), talentItem:GetTalentInfo(), talentItem:GetTalentUnlocked())
    end
end

function UIGodBeastMainView:ShowTalentDetail(isShow, talentIndex, talentInfo, unlocked)
    self.m_forgetContent.gameObject:SetActive(false)
    self.m_offeringContent.gameObject:SetActive(false)
    if isShow and unlocked then
        local showForget = talentInfo ~= nil
        showForget = showForget and talentInfo.talent_id ~= 0 or false
        if showForget then
            self:UpdateForgetContent(talentIndex, talentInfo)
        else
            self:UpdateOfferingContent(talentIndex, talentInfo)
        end
    end
    self.m_sellectTalent = talentIndex or 0
    self:CheckSelectTalentIcon(isShow,talentIndex)
end

function UIGodBeastMainView:CheckSelectTalentIcon(isShow, talentIndex)
    self.m_detailHelper:Close()
    if self.m_talentSlotList then
        for i = 1, #self.m_talentSlotList do
            if self.m_talentSlotList[i] then
                local isSelect = false
                
                if isShow then
                    isSelect = talentIndex == self.m_talentSlotList[i]:GetTalentIndex()
                end
                self.m_talentSlotList[i]:SetSelect(isSelect)
            end
        end
    end
end

--天赋献祭
function UIGodBeastMainView:UpdateOfferingContent(talentIndex, talentInfo)
    UIUtil.TryBtnEnable(self.m_offeringBtn.gameObject, false)
    self.m_offeringContent.gameObject:SetActive(true)
    if self.m_offeringFlag == false then
        self.m_offeringScrollView = UIUtil.AddComponent(LoopScrowView, self, "Container/comentRoot/talentContent/offeringContent/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateOfferingBagItem))
        self.m_offeringFlag = true
    end
    self.m_offeringItemDataList = self:GetAllItemDataList()

    if self.m_offeringScrollView then
        if #self.m_offeringItemList == 0 then
            self:CreateOfferingItemList()
        else
            self.m_offeringScrollView:UpdateView(true, self.m_offeringItemList, self.m_offeringItemDataList)
        end
        self:ClearCurrSelectItem()
    end
    UIUtil.TryBtnEnable(self.m_offeringBtn.gameObject, self.m_currSelectHorseIndex ~= 0)
end

function UIGodBeastMainView:GetAllItemDataList()
    local allItemDataList = {}
    MountMgr:Walk(function(mountData)
        if mountData then
            local mountItemCfg = mountData:GetItemCfg()
            if mountItemCfg and mountItemCfg.sMainType == CommonDefine.ItemMainType_Mount and mountData.m_equiped_wujiang_index == 0 and not mountData:GetLockState() then
                table_insert(allItemDataList,mountData)
            end
        end
    end)
    return allItemDataList
end

function UIGodBeastMainView:CreateOfferingItemList()
    if #self.m_offeringItemList > 0 then
        return
    end
    self.m_seq = UIGameObjectLoader:PrepareOneSeq()
    UIGameObjectLoader:GetGameObjects(self.m_seq, BagItemPath, 24, function(objs)
        self.m_seq = 0
        if objs then
            for i = 1, #objs do
                local bagItem = UIBagItem.New(objs[i], self.m_offeringItemContent, BagItemPath)
                if bagItem then
                table_insert(self.m_offeringItemList, bagItem)
                end
            end
            self.m_offeringScrollView:UpdateView(true, self.m_offeringItemList, self.m_offeringItemDataList)
            TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CHILD_UI_SHOW_END, "UIGodBeastMainOfferingItem")
        end
    end)
end

function UIGodBeastMainView:UpdateOfferingBagItem(item, realIndex)
    if not item then
        return
    end
    if realIndex > #self.m_offeringItemDataList then
        return
    end

    local itemData = self.m_offeringItemDataList[realIndex]
    if not itemData then
        return
    end
    local itemIconParam = ItemIconParam.New(itemData:GetItemCfg(), itemData:GetItemCount(), itemData:GetStage(), itemData:GetIndex(), function(bagItem)
        if not bagItem then
            return
        end
        self:ClearCurrSelectItem()
        bagItem:SetOnSelectState(true)
        self.m_currSelectItem = bagItem
        self.m_currSelectItemID = bagItem:GetItemID()
        self.m_currSelectHorseIndex = bagItem:GetIndex()
        self.m_offeringIconImage.gameObject:SetActive(true)
        self.m_offeringIconImage:SetAtlasSprite(math_ceil(bagItem:GetItemID())..math_ceil(bagItem:GetStage())..".png", false)
        UIUtil.TryBtnEnable(self.m_offeringBtn.gameObject, self.m_currSelectHorseIndex ~= 0)
        local mountData = MountMgr:GetDataByIndex(bagItem:GetIndex())
        if mountData then
            local scoreNum = mountData.m_base_first_attr.fangyu + mountData.m_base_first_attr.zhili + mountData.m_base_first_attr.wuli + mountData.m_base_first_attr.tongshuai +
            mountData.m_extra_first_attr.tongshuai + mountData.m_extra_first_attr.fangyu + mountData.m_extra_first_attr.zhili + mountData.m_extra_first_attr.wuli
            scoreNum = scoreNum * mountData:GetStage()
            self.m_offeringScoreText.text = math_ceil(scoreNum)

            self.m_detailHelper:UpdateInfo()
            TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CHILD_UI_SHOW_END, "UIGodBeastMainMountDetail")
        end 
    end,true, true, itemData:GetLockState(), nil)

    item:UpdateData(itemIconParam)
    if self.m_currSelectOfferingItemID and item then
        bagItem:SetOnSelectState(self.m_currSelectItemID == item:GetItemID())
    end
end

function UIGodBeastMainView:ClearCurrSelectItem()
    if self.m_currSelectItem then
        self.m_currSelectItem:SetOnSelectState(false)
        self.m_currSelectItem = nil
        self.m_currSelectItemID = 0
        self.m_currSelectHorseIndex = 0
        self.m_offeringIconImage.gameObject:SetActive(false)
        self.m_offeringScoreText.text = "0"
    end
    self.m_detailHelper:Close()
end

function UIGodBeastMainView:GetCurrSelectBagItem()
    return self.m_currSelectItem
end

--天赋遗忘
function UIGodBeastMainView:UpdateForgetContent(talentIndex, talentInfo)
    
    self.m_tmpForgetScore = 0
    self.m_tmpForgetCostList = {}
    self:ResetFeedData()
    self:UpdateForgetProcess()

    local item_list = self.m_GodBeastBaseInfo.nItemId
    if not self.m_forgetItemList then
        self.m_forgetItemList = {}
    end

    self.m_tmpForgetItemList = {}
    --道具
    for i=1,#item_list do
        local itemID = item_list[i]
        local count = ItemMgr:GetItemCountByID(itemID) or 0
        self.m_tmpForgetItemList[itemID] = ItemMgr:GetItemData(itemID)
        if itemID and itemID > 0 then
            local bagItem = self.m_forgetItemList[i]
            if not bagItem then
                self.m_seq = UIGameObjectLoader:PrepareOneSeq()
                UIGameObjectLoader:GetGameObject(self.m_seq, BagItemPath, function(go)
                    self.m_seq = 0
                    if not IsNull(go) then
                        local bagItem = UIBagItem.New(go, self.m_forgetItemContent, BagItemPath)
                        bagItem.m_gameObject.name = itemID
                        table_insert(self.m_forgetItemList, bagItem)
                        local itemCfg = ConfigUtil.GetItemCfgByID(itemID)
                        if itemCfg and count then
                            local itemIconParam = ItemIconParam.New(itemCfg, count)                          
                            bagItem:UpdateData(itemIconParam)
                            GameUtility.SetUIGray(bagItem:GetGameObject(), count == 0)
                            self:HandleExpItemPress(bagItem:GetGameObject())
                        end
                    end
                end)
            else
                bagItem:UpdateItemCount(count)
            end
        end
    end

    if talentInfo then
        local talentCfg = ConfigUtil.GetGodBeastTalentCfgByID(talentInfo.talent_id)
        if talentCfg then
            local str = talentCfg.exdesc
            local x1 = talentCfg.x + talentCfg.ax * talentInfo.talent_level
            local x2 = math_ceil(x1)
            x1 = x1 == x2 and x2 or x1
            local y1 = talentCfg.y + talentCfg.ay * talentInfo.talent_level
            local y2 = math_ceil(y1)
            y1 = y1 == y2 and y2 or y1
            str = str:gsub("{(.-)}", {x=x1, y=y1})

            self.m_talentDesText.text = str
    
            if self.m_LVNumList then
                self.m_talentNameText.text = string_format(self.m_LVNumList[talentInfo.talent_level],talentCfg.name)
            end
            self.m_forgetIconImage:SetAtlasSprite(talentCfg.sIcon, false)
        end
    end
    self.m_forgetContent.gameObject:SetActive(true)
end

function UIGodBeastMainView:SetTmpForgetScoreData()
end

function UIGodBeastMainView:CheckScore(addscore)
    if addscore then
        if addscore > 100 then
            addscore = 100
        end
        self.m_tmpForgetScore = addscore
    end
    self:UpdateForgetProcess()
end

function UIGodBeastMainView:UpdateForgetProcess()
    self.m_forgetProcessText.text = self.m_tmpForgetScore.."%"
    self.m_forgetSilder.value = self.m_tmpForgetScore / 100
    GameUtility.SetUIGray(self.m_forgetBtn.gameObject, self.m_tmpForgetScore < 100)  
end

function UIGodBeastMainView:SimulationUpdateScoreItem(itemID, count)
    for i, v in ipairs(self.m_forgetItemList) do
        if v then
            local expItemID = v:GetItemID()
            if expItemID == itemID then
                count = math_ceil(count)
                v:UpdateItemCount(count)
                break
            end
        end
    end
end

function UIGodBeastMainView:AddForgetCostItem(expItem)
    self:ReduceTmpItemCountByID(expItem.item_id, expItem.count)
    for k,v in pairs(self.m_tmpForgetCostList) do
        if v.item_id == expItem.item_id then
            self.m_tmpForgetCostList[k].count = self.m_tmpForgetCostList[k].count + expItem.count
            return
        end
    end
    table_insert(self.m_tmpForgetCostList, expItem)
end

function UIGodBeastMainView:ReduceTmpItemCountByID(id, count)
    local itemData = self.m_tmpForgetItemList[id]
    if itemData then
        if itemData:GetItemCount() > count then
            local tempItemData = ItemData.New(id, itemData:GetItemCount() - count, false)
            self.m_tmpForgetItemList[id] = tempItemData
        else
            self.m_tmpForgetItemList[id] = nil
        end
    end
end

function UIGodBeastMainView:SureForgetTalent()
    if self.m_sellectTalent ~= 0 and self.m_tmpForgetCostList then
        GodBeastMgr:ReqForgetTalent(self.m_GodBeastData.dragon_id, self.m_sellectTalent, self.m_tmpForgetCostList)
    end
end

--觉醒
function UIGodBeastMainView:UpdateAwakenData()

    local talentList = self.m_GodBeastData.dragon_talent_list
    local unlockAwakeCount = 0
    if talentList then
        unlockAwakeCount = #talentList
    end

    local canAwakenFlag = true
    self.m_awakeText1.text = string_format(Language.GetString(3625), unlockAwakeCount)
    self.m_awakeText2.text = string_format(Language.GetString(3625), unlockAwakeCount + 1)
    if unlockAwakeCount >= 5 then
        self.m_awakeContentText.text = Language.GetString(3627)
    else
        local unloclLevel = self.m_GodBeastBaseInfo.juexing_level[unlockAwakeCount + 1]
        if unloclLevel then
            local tmpS = {}
            if self.m_GodBeastData.level < unloclLevel then 
                tmpS = string_format(Language.GetString(3629), self.m_GodBeastData.level, unloclLevel)
            else
                tmpS = string.format(Language.GetString(3628), self.m_GodBeastData.level, unloclLevel)
            end
            self.m_awakeContentText.text = string_format(Language.GetString(3626),unlockAwakeCount + 1,self.m_GodBeastBaseInfo.sName,tmpS)
            if self.m_GodBeastData.level < unloclLevel then
                canAwakenFlag = false
            end
        end
        --觉醒材料
        local item_list = self.m_GodBeastBaseInfo.nItemId
        if not self.m_awakenItemList then
            self.m_awakenItemList = {}
        end
        for i=1,#item_list do
            local itemID = item_list[i]
            local count = ItemMgr:GetItemCountByID(itemID) or 0
            if itemID and itemID > 0 then
                local bagItem = self.m_awakenItemList[i]
                if not bagItem then
                    self.m_seq = UIGameObjectLoader:PrepareOneSeq()
                    UIGameObjectLoader:GetGameObject(self.m_seq, BagItemPath, function(go)
                        self.m_seq = 0
                        if not IsNull(go) then
                            local bagItem = UIBagItem.New(go, self.m_awakenMaterialContent, BagItemPath)
                            bagItem.m_gameObject.name = itemID
                            table_insert(self.m_awakenItemList, bagItem)
                            local itemCfg = ConfigUtil.GetItemCfgByID(itemID)
                            if itemCfg and count then
                                local itemIconParam = ItemIconParam.New(itemCfg)
                                itemIconParam.onClickShowDetail = true                        
                                bagItem:UpdateData(itemIconParam)
                            end
                        end
                    end)
                end
            end
        end
    end
    self:UpdateAwakenMaterials()
    UIUtil.TryBtnEnable(self.m_awakeBtn.gameObject,canAwakenFlag)
    self.m_arrowsImage.gameObject:SetActive(unlockAwakeCount < 5)
    self.m_awakeText2.gameObject:SetActive(unlockAwakeCount < 5)
    self.m_awakenMaterialContent.gameObject:SetActive(unlockAwakeCount < 5)
    self.m_materialCountContent.gameObject:SetActive(unlockAwakeCount < 5)
    self.m_awakeBtn.gameObject:SetActive(unlockAwakeCount < 5)
    self.m_awakenComent.gameObject:SetActive(true)
end

function UIGodBeastMainView:UpdateAwakenMaterials()
    local talentList = self.m_GodBeastData.dragon_talent_list
    local unlockAwakeCount = 0
    if talentList then
        unlockAwakeCount = #talentList
    end
    local item_list = self.m_GodBeastBaseInfo.nItemId
    if item_list then
        for i=1,#item_list do
            local count = ItemMgr:GetItemCountByID(item_list[i]) or 0
            local awakeNeedCountList = self:GetAwakeItemCountList(unlockAwakeCount + 1)
            if awakeNeedCountList then
                if awakeNeedCountList[i] > count then
                    self.m_awakeItemCountTextList[i].text = string_format(Language.GetString(3629), count, awakeNeedCountList[i])
                    canAwakenFlag = false
                else
                    self.m_awakeItemCountTextList[i].text = string_format(Language.GetString(3628), count, awakeNeedCountList[i])
                end
            end
        end
    end
end

function UIGodBeastMainView:GetAwakeItemCountList(awakeIndex)
    if self.m_GodBeastBaseInfo then
        if awakeIndex == 1 then
            return self.m_GodBeastBaseInfo.nItemCount1
        elseif awakeIndex == 2 then
            return self.m_GodBeastBaseInfo.nItemCount2
        elseif awakeIndex == 3 then
            return self.m_GodBeastBaseInfo.nItemCount3
        elseif awakeIndex == 4 then
            return self.m_GodBeastBaseInfo.nItemCount4
        elseif awakeIndex == 5 then
            return self.m_GodBeastBaseInfo.nItemCount5
        end
    end
end

function UIGodBeastMainView:Update()
    if self.m_showBtnLayer == BtnTypeArr.Upgrade or self.m_showBtnLayer == BtnTypeArr.Talent then
        self:UpdateFeedExp(Time.deltaTime)
    end
end

function UIGodBeastMainView:HandleExpItemPress(expItemGo)
   
    if IsNull(expItemGo) then
        return
    end

    --按下
    local touch_begin = function(go, x, y)
        self:ShowSkillDetail(false)
        DOTweenShortcut.DOScale(go.transform, 0.9, 0.2)
        if self.m_expItemNameOnPress == "" then
            
            local itemID = tonumber(go.name)
            if self.m_showBtnLayer == BtnTypeArr.Upgrade then
                self.m_onPressItemNum = ItemMgr:GetItemCountByID(itemID)
            elseif self.m_showBtnLayer == BtnTypeArr.Talent then
                self.m_onPressItemNum = 0
                if self.m_tmpForgetItemList[itemID] then
                    self.m_onPressItemNum = self.m_tmpForgetItemList[itemID]:GetItemCount()
                end
            end
           
           if self.m_onPressItemNum <= 0 then
                UILogicUtil.FloatAlert(Language.GetString(644))
                return
           end

           local itemFuncCfg = ConfigUtil.GetItemFuncCfgByID(itemID)
           if not itemFuncCfg then
               return
           end

           self.m_reqExpData.itemId = itemID
           
           self.m_isOnPressExp = true
           self.m_expItemNameOnPress = go.name

            if self.m_showBtnLayer == BtnTypeArr.Upgrade then
                self:SetTmpGodBeastData()
                self.m_reqExpData.addExp = itemFuncCfg.func_value1
            elseif self.m_showBtnLayer == BtnTypeArr.Talent then
                self.m_reqExpData.addExp = itemFuncCfg.func_value2
            end
        end
    end

    --松开
    local touch_end = function (go, x, y)

        DOTweenShortcut.DOScale(go.transform, 1, 0.2)

        if go.name == self.m_expItemNameOnPress and self.m_isOnPressExp then
           self:EndPressExpItem()
        end
    end
   
    UIUtil.AddDownEvent(expItemGo, touch_begin)
    UIUtil.AddUpEvent(expItemGo, touch_end)
end

function UIGodBeastMainView:EndPressExpItem()
    
    local itemNum = ItemMgr:GetItemCountByID(self.m_reqExpData.itemId)
    if itemNum > 0 then

        if self.m_reqExpData.count == 0 then
            self.m_reqExpData.count = 1
            if self.m_showBtnLayer == BtnTypeArr.Talent and self.m_tmpForgetScore < 100 then                
                local nowItemCount = self.m_onPressItemNum - self.m_reqExpData.count
                --刷新道具
                self:SimulationUpdateScoreItem(self.m_reqExpData.itemId, nowItemCount)
                addExp = self.m_reqExpData.addExp * self.m_reqExpData.count + self.m_tmpForgetScore
                self:CheckScore(addExp)
            end

        end

        if self.m_reqExpData.count > itemNum then
            self.m_reqExpData.count = itemNum
        end

        local expItem = {
            item_id = self.m_reqExpData.itemId,
            count = self.m_reqExpData.count
        }

        --升级或者遗忘
        if self.m_showBtnLayer == BtnTypeArr.Upgrade then
            GodBeastMgr:ReqImproveGodBeast(self.m_GodBeastData.dragon_id, expItem)
        elseif self.m_showBtnLayer == BtnTypeArr.Talent then
            self:AddForgetCostItem(expItem)
        end

        self.m_totalExpItemCount = self.m_totalExpItemCount + self.m_reqExpData.count
        if self.m_totalExpItemCount >= 8 then
            TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CHILD_UI_SHOW_END, "UIGodBeastMainEXP")
        end
    end

    self:ResetFeedData()
    --特效去掉
end

function UIGodBeastMainView:SetTmpGodBeastData()
    self.m_tmpGodBeastData.level = self.m_GodBeastData.level
    self.m_tmpGodBeastData.dragon_exp = self.m_GodBeastData.dragon_exp
    self.m_tmpGodBeastData.dragon_id = self.m_GodBeastData.dragon_id
end

function UIGodBeastMainView:ResetFeedData()
    self.m_feedTime = 0
    self.m_feedInterval = 0.5
    self.m_expItemNameOnPress = "" --当前按了哪个Item
    self.m_isOnPressExp = false
    self.m_reqExpData.count = 0
end

function UIGodBeastMainView:UpdateFeedExp(deltaTime)
    
    if not self.m_isOnPressExp then
        return
    end

    if self.m_showBtnLayer == BtnTypeArr.Upgrade then
        if self:FeedExpIsUpLimit() then
            return
        end
    elseif self.m_showBtnLayer == BtnTypeArr.Talent then
        if self.m_tmpForgetScore >= 100 then
            self.m_tmpForgetScore = 100
            return
        end
    end

    
    self.m_feedTime = self.m_feedTime + deltaTime
    if self.m_feedTime < self.m_feedInterval then
        return
    end

    self.m_feedTime = 0
    if self.m_reqExpData.itemId > 0 and self.m_expItemNameOnPress ~= "" and self.m_onPressItemNum > 0 then

        local fMinFrame = 0.1  --最小帧数间隔
        if self.m_reqExpData.itemId == self.m_GodBeastBaseInfo.nItemId[1] then
            fMinFrame = 0.033
        elseif self.m_reqExpData.itemId == self.m_GodBeastBaseInfo.nItemId[2] then
            fMinFrame = 0.067
        elseif self.m_reqExpData.itemId == self.m_GodBeastBaseInfo.nItemId[3] then
            fMinFrame = 0.1
        end

        --更新频率递增
        if self.m_feedInterval > fMinFrame then
            self.m_feedInterval = self.m_feedInterval - 0.333
            if self.m_feedInterval < fMinFrame then
                self.m_feedInterval = fMinFrame
            end
        end
        self.m_reqExpData.count = self.m_reqExpData.count + 1

        local nowItemCount = self.m_onPressItemNum - self.m_reqExpData.count
        if nowItemCount > -1 then 
            local addExp = 0
            if self.m_showBtnLayer == BtnTypeArr.Upgrade then
                --刷新道具
                self:SimulationUpdateExpItem(self.m_reqExpData.itemId, nowItemCount)
                addExp = self.m_reqExpData.addExp + self.m_tmpGodBeastData.dragon_exp
                self:CheckLevelUp(addExp)
            elseif self.m_showBtnLayer == BtnTypeArr.Talent then
                --刷新道具
                self:SimulationUpdateScoreItem(self.m_reqExpData.itemId, nowItemCount)
                addExp = self.m_reqExpData.addExp + self.m_tmpForgetScore
                self:CheckScore(addExp)
            end

            if nowItemCount == 0 then
                self:EndPressExpItem()
            end
        end
    end
end

--神兽升级
function UIGodBeastMainView:SimulationUpdateExpItem(itemID, count)
    for i, v in ipairs(self.m_upgradeItemList) do
        if v then
            local expItemID = v:GetItemID()
            if expItemID == itemID then
                count = math_ceil(count)
                v:UpdateItemCount(count)
                break
            end
        end
    end
end

function UIGodBeastMainView:CheckLevelUp(currExp)
    --直接修改本地数据
    local bLevelUp = false
    if self.m_tmpGodBeastData then  

        self.m_tmpGodBeastData.dragon_exp = currExp

        local godBeastLevelCfg = ConfigUtil.GetGodBeastLevelCfgByID(self.m_tmpGodBeastData.level)
        --升级
        if godBeastLevelCfg then
            while self.m_tmpGodBeastData.dragon_exp >= godBeastLevelCfg.dragon_exp do
        
                self.m_tmpGodBeastData.dragon_exp = self.m_tmpGodBeastData.dragon_exp - godBeastLevelCfg.dragon_exp
                self.m_tmpGodBeastData.level = self.m_tmpGodBeastData.level + 1
                godBeastLevelCfg = ConfigUtil.GetGodBeastLevelCfgByID(self.m_tmpGodBeastData.level)
                bLevelUp = true
                if not godBeastLevelCfg  then
                    self.m_tmpGodBeastData.level = self.m_tmpGodBeastData.level - 1
                    break
                end
            end
        end

        if bLevelUp then
            self:ShowUpLvEffect(true)
        end
        self:UpdateExp(self.m_tmpGodBeastData)
    end
    return bLevelUp
end

function UIGodBeastMainView:UpdateExp(tempGodBeastData)
    -- 可能用临时数据
    local godBeastLevelCfg = ConfigUtil.GetGodBeastLevelCfgByID(tempGodBeastData.level)
    if not godBeastLevelCfg then
        return
    end

    local maxLv = Player:GetInstance():GetUserMgr():GetSettingData().dragon_max_level
    self.m_LvText.text = string_format(Language.GetString(3607), self.m_GodBeastBaseInfo.sName, tempGodBeastData.level, maxLv)
    if maxLv == tempGodBeastData.level then
        self.m_expText.text = Language.GetString(3631)
        self.m_expSilder.value = 0
    else
        self.m_expText.text = string_format(Language.GetString(630), tempGodBeastData.dragon_exp, godBeastLevelCfg.dragon_exp)
        self.m_expSilder.value = tempGodBeastData.dragon_exp / godBeastLevelCfg.dragon_exp
    end
end

function UIGodBeastMainView:FeedExpIsUpLimit()
    local godBeastLevelCfg = ConfigUtil.GetGodBeastLevelCfgByID(self.m_tmpGodBeastData.level)
    if not godBeastLevelCfg then
        return true
    end

    if self.m_tmpGodBeastData.level == Player:GetInstance():GetUserMgr():GetSettingData().dragon_max_level then
        return true
    end
end

function UIGodBeastMainView:ShowUpLvEffect(isShow)
    if isShow then
        if not self.m_sliderEffect then
            local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
            UIUtil.AddComponent(UIEffect, self, "Container/comentRoot/godBeastBaseRoot/ExpSilder", sortOrder, TheGameIds.ui_shengjitiao01_fx_path, function(effect)
                self.m_sliderEffect = effect
            end)
        else
            self.m_sliderEffect:Show(true)
        end
    else
        if self.m_sliderEffect then
            self.m_sliderEffect:Delete()
            self.m_sliderEffect = nil
        end
    end
end

--神兽模型
function UIGodBeastMainView:CreateRoleContainer()
    self.m_sceneSeq = UIGameObjectLoader:PrepareOneSeq()
    UIGameObjectLoader:GetGameObject(self.m_sceneSeq, GodBeastObjPath, function(go)
        self.m_sceneSeq = 0
        if not IsNull(go) then
            self.m_godBeastObjGo = go
            self.m_godBeastModelTr = self.m_godBeastObjGo.transform:GetChild(0)
            local pos = self.m_godBeastModelTr.localPosition
            self.m_godBeastModelTr.localPosition = Vector3.New(0.35, pos.y, pos.z)
            if self.m_GodBeastBaseInfo then
                self:ShowGodBeastModel(self.m_GodBeastBaseInfo.role_id)
            end
        end
    end)
end

function UIGodBeastMainView:DestroyRoleContainer()

    UIGameObjectLoader:CancelLoad(self.m_sceneSeq)
    self.m_sceneSeq = 0
    self.m_godBeastModelTr= nil

    if not IsNull(self.m_godBeastObjGo) then
        UIGameObjectLoader:RecycleGameObject(GodBeastObjPath, self.m_godBeastObjGo)
        self.m_godBeastObjGo = nil
    end

    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end
end

function UIGodBeastMainView:ShowGodBeastModel(godBeastId)

    if not self.m_godBeastModelTr and godBeastId then
        return
    end

    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end

    if godBeastId and godBeastId > 0 then
        self.m_sceneSeq = ActorShowLoader:GetInstance():PrepareOneSeq() 
        ActorShowLoader:GetInstance():CreateShowOffWuJiang(self.m_sceneSeq, ActorShowLoader.MakeParam(godBeastId, 1), self.m_godBeastModelTr, function(actorShow)
            self.m_sceneSeq = 0
            self.m_actorShow = actorShow
            local pos,scale,rotate = GodBeastMgr:GetGodBeastVector3ById(godBeastId)
            self.m_actorShow:PlayAnim(BattleEnum.ANIM_IDLE)
            self.m_actorShow:SetPosition(pos)
            self.m_actorShow:SetLocalScale(scale)
            self.m_actorShow:SetEulerAngles(rotate)
        end)
    end 
end

function UIGodBeastMainView:OnDestroy()
    if self.m_skillDetaiIconImage then
        self.m_skillDetaiIconImage:Delete()
        self.m_skillDetaiIconImage = nil  
    end
    if self.m_offeringIconImage then
        self.m_offeringIconImage:Delete()
        self.m_offeringIconImage = nil   
    end
    if self.m_forgetIconImage then
        self.m_forgetIconImage:Delete()
        self.m_forgetIconImage = nil   
    end

    if self.m_detailHelper then
        self.m_detailHelper:Delete()
    end
    self.m_detailHelper = nil

    base.OnDestroy(self)
end

return UIGodBeastMainView