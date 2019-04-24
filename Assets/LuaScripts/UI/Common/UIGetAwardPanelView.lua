local UIUtil = UIUtil
local UIImage = UIImage
local Vector3 = Vector3
local tostring = tostring
local string_len = string.len
local ConfigUtil = ConfigUtil
local AtlasConfig = AtlasConfig
local CommonDefine = CommonDefine
local table_insert = table.insert
local table_remove = table.remove
local GameObject = CS.UnityEngine.GameObject
local PBUtil = PBUtil
local Type_Text = typeof(CS.UnityEngine.UI.Text)
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local CreateWuJiangHelper = require 'UI.Common.CreateWuJiangHelper'
local SpringContent = CS.SpringContent
local UIEffect = UIEffect

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local UIWuJiangDetailFirstAttrItem = require "UI.UIWuJiang.View.UIWuJiangDetailFirstAttrItem"

local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local DOTweenShortcut = CS.DOTween.DOTweenShortcut

local effectPath = "UI/Effect/Prefabs/Ui_huoqujiangli"

local UIGetAwardPanelView = BaseClass("UIGetAwardPanelView", UIBaseView)
local base = UIBaseView

local UIGetAwardPanelOpenType = {
    Get_Award = 1,      --获得奖励物品
    Open_Module = 2,      --开放了新的模块功能
    StarPanel_Attr = 3,     --星盘提升属性
    GuildSkill_Attr = 4,    --军团技能提升属性
}

local WuJiangRot = Vector3.New(0, 160, 0)
local TitleScale = Vector3.New(0.8, 0.8, 0.8)

function UIGetAwardPanelView:OnCreate()
    base.OnCreate(self)

    self.m_modeBg, 
    self.m_itemGrid, 
    self.m_openModItemPrefab, 
    self.m_contentBg,
    self.m_starPanelAttrItemPrefab,
    self.m_wujiangBgBtn, self.m_wujiangRoot, self.m_actorAnchor,
    self.m_itemScrollViewTran,
    self.m_firstAttrTrans, 
    self.m_rightContainer
    = UIUtil.GetChildTransforms(self.transform, {
        "modeBg",
        "bg/ContentRoot/itemScrollView/Viewport/itemGrid",
        "OpenModItemPrefab",
        "bg/ContentRoot/ContentBg",
        "StarPanelAttrItemPrefab",
        "WuJiangRoot/WuJiangBgBtn",
        "WuJiangRoot",
        "WuJiangRoot/actorAnchor", 
        "bg/ContentRoot/itemScrollView",
        "WuJiangRoot/rightBg/rightContainer/firstAttr", 
        "WuJiangRoot/rightBg/rightContainer"
    })

    self.m_wujiangRareImage = self:AddComponent(UIImage, "WuJiangRoot/rightBg/rightContainer/WuJiangNameText/WuJiangRareImage", AtlasConfig.DynamicLoad)
    self.m_wujiangJobImage = self:AddComponent(UIImage, "WuJiangRoot/rightBg/rightContainer/JobTypeImage", AtlasConfig.DynamicLoad)
    self.m_starList = {}
    for i = 1, 6 do
        local starImage = self:AddComponent(UIImage, "WuJiangRoot/rightBg/rightContainer/startList/star"..i, AtlasConfig.DynamicLoad)
        table_insert(self.m_starList, starImage)
    end

    self.m_wujiangNameText, self.m_wuJiangLevelText, self.m_wuJiangCountryText = UIUtil.GetChildTexts(self.transform, {
        "WuJiangRoot/rightBg/rightContainer/WuJiangNameText",
        "WuJiangRoot/rightBg/rightContainer/WuJiangNameText/WuJiangRareImage/WuJiangLevelText",
        "WuJiangRoot/rightBg/rightContainer/JobTypeImage/CountryTypeText",
    })

    self.m_panelData = nil

    self.m_wujiangRoot = self.m_wujiangRoot.gameObject

    self.m_openModItemPrefab.gameObject:SetActive(false)
    self.m_starPanelAttrItemPrefab.gameObject:SetActive(false)
    self.m_wujiangRoot:SetActive(false)

    self.m_openModItem = nil
    self.m_starPanelAttrItem = nil
    self.m_guildSkillAttrItem = nil
    self.m_awardItemList = {}
    self.m_awardItemListLoadSeq = 0
    self.maxFisrtAttrSliderValue = 0

    self.m_awardWuJiangList = {}
    self.m_wujiangFirstAttrItemList = {}
    self.m_timesItemList = {}

    self.m_attrLoaderSeq = 0
    self.m_iconLoaderSeq = 0
    self.m_itemScrollRect = self.m_itemScrollViewTran:GetComponentInParent(typeof(CS.UnityEngine.UI.ScrollRect))
    self.m_titleImage = self:AddComponent(UIImage, "bg/Image/TitleImage", ImageConfig.Common)
    self.m_isShowTween = false

    self:HandleClick()
end

function UIGetAwardPanelView:GetOpenAudio()
	return 115
end

function UIGetAwardPanelView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_modeBg.gameObject)
    UIUtil.RemoveClickEvent(self.m_wujiangBgBtn.gameObject)

    self:ClearOpenModItemList()
    self:RecycleAwardItemList()
    self.m_awardItemList = nil
    self.m_modeBg = nil
    self.m_itemGrid  = nil
    self.m_openModItemPrefab = nil
    self.m_starPanelAttrItemPrefab = nil
    self.m_panelData = nil

    for i,v in ipairs(self.m_wujiangFirstAttrItemList) do
        v:Delete()
    end
    self.m_wujiangFirstAttrItemList = nil

    self.m_starList = nil

    base.OnDestroy(self)
end

function UIGetAwardPanelView:OnEnable(...)
    base.OnEnable(self, ...)

    local initOrder, panelData = ... 
    if not panelData then
        return
    end

    self.m_panelData = panelData

    local sortOrder = self:PopSortingOrder()

    if not self.m_huoqoEffect then
        self:AddComponent(UIEffect, "", sortOrder, effectPath, function(effect)
            self.m_huoqoEffect = effect
            self.m_huoqoEffect:SetLocalPosition(Vector3.New(0, 200, 0))
            self.m_huoqoEffect:SetLocalScale(Vector3.one) 
        end)
    end

    self:UpdateTitle()

    self:UpdateItemList()
end

function UIGetAwardPanelView:OnDisable()
    self.m_itemGrid.anchoredPosition = Vector2.zero

    self:RecycleAwardItemList()
    self:ClearOpenModItemList()
    self:ClearStarPanelAttrItem()
    self:ClearGuildSkillAttrItem()
    self:ClearWuJiang()

    if self.m_wujiangIconItem then
        self.m_wujiangIconItem:Delete()
        self.m_wujiangIconItem = nil
    end

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_attrLoaderSeq)
    self.m_attrLoaderSeq = 0

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_iconLoaderSeq)
    self.m_iconLoaderSeq = 0

    if self.m_huoqoEffect then
        self:RemoveComponent(self.m_huoqoEffect:GetName(), UIEffect)
        self.m_huoqoEffect = nil
    end

    self.m_awardWuJiangList = {}
    self.m_panelData = nil
    
    base.OnDisable(self)
end

function UIGetAwardPanelView:UpdateTitle()
    if not self.m_panelData then
        return
    end

    local openType = self.m_panelData.openType
    if openType == UIGetAwardPanelOpenType.Get_Award then
        self.m_titleImage:SetAtlasSprite("05.png", true)
    elseif openType == UIGetAwardPanelOpenType.Open_Module then
        self.m_titleImage:SetAtlasSprite("04.png", true)
    elseif openType == UIGetAwardPanelOpenType.StarPanel_Attr or openType == UIGetAwardPanelOpenType.GuildSkill_Attr then
        self.m_titleImage:SetAtlasSprite("05.png", true)
    end

    self.m_titleImage.transform.localScale = TitleScale
end

function UIGetAwardPanelView:UpdateItemList()
    if not self.m_panelData then
        return
    end
    if self.m_panelData.openType == UIGetAwardPanelOpenType.Get_Award then

        self:CheckAwardWuJiang()
        self:CheckShowAward()

        self:UpdateAwardItemList()
    elseif self.m_panelData.openType == UIGetAwardPanelOpenType.Open_Module then
        self:UpdateOpenModuleList()
    elseif self.m_panelData.openType == UIGetAwardPanelOpenType.StarPanel_Attr then
        self:UpdateStarPanelAttrItem()
    elseif self.m_panelData.openType == UIGetAwardPanelOpenType.GuildSkill_Attr then
        self:UpdateGuildSkillAttrItem()
    end
end

function UIGetAwardPanelView:UpdateAwardItemList()
    self:RecycleAwardItemList() 
    if not self.m_panelData then
        return
    end
    local awardDataList = self.m_panelData.awardDataList
    if not awardDataList then
        return
    end
    
    self.m_timesItemList = {}
    for _, v in ipairs(awardDataList) do
        if v:GetAwardType() == CommonDefine.AWARD_TYPE_ITEM then
            local itemId = v:GetItemData():GetItemID()
            local count = v:GetItemData():GetItemCount()
            if itemId == CommonDefine.ITEM_TYPE_GRAVECOPY_ID or
                itemId == CommonDefine.ITEM_TYPE_INSCRIPTIONCOPY_ID or
                itemId == CommonDefine.ITEM_TYPE_GUILDBOSS_ID or
                itemId == CommonDefine.ITEM_TYPE_SHENBINGCOPY_ID or
                itemId == CommonDefine.ITEM_TYPE_HORSESHOW_ID then

                self.m_timesItemList[itemId] = count
            end
        end
    end

    self.m_awardItemListLoadSeq = UIGameObjectLoaderInst:PrepareOneSeq()
    UIGameObjectLoaderInst:GetGameObjects(self.m_awardItemListLoadSeq, CommonAwardItemPrefab, #awardDataList, function(objs)
        if not objs then
            return
        end

        local CreateAwardParamFromAwardData = PBUtil.CreateAwardParamFromAwardData
        for i = 1, #objs do
            local awardData = awardDataList[i]
            if awardData then                
                local bagItem = CommonAwardItem.New(objs[i], self.m_itemGrid, CommonAwardItemPrefab)
                if bagItem then
                    local itemIconParam = CreateAwardParamFromAwardData(awardData)

                    bagItem:SetLocalScale(Vector3.zero)
                    bagItem:UpdateData(itemIconParam)
                    table_insert(self.m_awardItemList, bagItem)
                end
            end
        end

        self.m_awardItemIndex = 1
        coroutine.start(self.TweenShow, self)
    end)
end

function UIGetAwardPanelView:ResetItemContentPos()
    if #self.m_awardItemList < 5 then
        self.m_itemScrollRect.horizontal = false
        UIUtil.KeepCenterAlign(self.m_itemGrid, self.m_itemScrollViewTran)
    else
        self.m_itemScrollRect.horizontal = true
    end
end

local ItemContentSize = 640
local ItemSize = 150

function UIGetAwardPanelView:TweenShow()
    self.m_isShowTween = true
    coroutine.waitforframes(1)
    self:ResetItemContentPos()

    coroutine.waitforseconds(0.2)
    
    while self.m_awardItemIndex <= #self.m_awardItemList do
        local awardItem = self.m_awardItemList[self.m_awardItemIndex]
        local awardItemTran = awardItem:GetTransform()
        if awardItemTran then
            DOTweenShortcut.DOScale(awardItemTran, 1, 0.1)
        end

        local nextIndex = self.m_awardItemIndex + 1
        if nextIndex <= #self.m_awardItemList then
            local size = nextIndex * ItemSize - 15
            if size > ItemContentSize then
                SpringContent.Begin(self.m_itemGrid.gameObject, Vector3.New(ItemContentSize - size, 0, 0), 8)
            end
        end

        self.m_awardItemIndex = self.m_awardItemIndex + 1
        coroutine.waitforseconds(0.1)
    end

    coroutine.waitforseconds(0.5)
    self.m_isShowTween = false
end


function UIGetAwardPanelView:UpdateOpenModuleList()
    self:ClearOpenModItemList()

    self.m_openModItemPrefab.gameObject:SetActive(true)
    local go = GameObject.Instantiate(self.m_openModItemPrefab.gameObject)
    if go then
        self.m_openModItem = go
        local trans = go.transform
        trans:SetParent(self.m_contentBg)
        trans.localScale = Vector3.one
        trans.localPosition =  Vector3.New(0, 24, 0)
        local openModIcon = UIUtil.AddComponent(UIImage, self.m_itemGrid, go, AtlasConfig.DynamicLoad)
        local openModIconText = UIUtil.FindText(trans, "Text")
        local sysopenCfg = ConfigUtil.GetSysopenCfgByID(self.m_panelData.openModID)
        if sysopenCfg and sysopenCfg.sIcon and string_len(sysopenCfg.sIcon) > 0 then
            openModIcon:SetAtlasSprite(sysopenCfg.sIcon, true, { AtlasPath = sysopenCfg.sAtlas })
            openModIconText.text = sysopenCfg.sName
        end
    end

    self.m_openModItemPrefab.gameObject:SetActive(false)
end

function UIGetAwardPanelView:UpdateStarPanelAttrItem()
    self:ClearStarPanelAttrItem()
    
    self.m_starPanelAttrItemPrefab.gameObject:SetActive(true)
    local itemGo = GameObject.Instantiate(self.m_starPanelAttrItemPrefab.gameObject)
    if itemGo then
        self.m_starPanelAttrItem = itemGo
        local itemTrans = itemGo.transform
        itemTrans:SetParent(self.m_contentBg)
        itemTrans.localPosition = Vector3.New(0, 24, 0)
        itemTrans.localScale = Vector3.one
        local text = UIUtil.FindText(itemTrans, "Text")
        local attrIcon = UIUtil.AddComponent(UIImage, itemTrans, "")
        if text then
            text.text = self.m_panelData.starPanelAtteDesc
        end
        local cfg = ConfigUtil.GetStarCfgByID(self.m_panelData.starID)
        if attrIcon and cfg then
            attrIcon:SetAtlasSprite(cfg.sIcon, false, ImageConfig[cfg.sAtlas])
        end
    end
    self.m_starPanelAttrItemPrefab.gameObject:SetActive(false)
end

function UIGetAwardPanelView:UpdateGuildSkillAttrItem()
    self:ClearGuildSkillAttrItem()

    self.m_starPanelAttrItemPrefab.gameObject:SetActive(true)
    local itemGo = GameObject.Instantiate(self.m_starPanelAttrItemPrefab.gameObject)
    if itemGo then
        self.m_guildSkillAttrItem = itemGo
        local itemTrans = itemGo.transform
        itemTrans:SetParent(self.m_contentBg)
        itemTrans.localPosition = Vector3.New(0, 24, 0)
        itemTrans.localScale = Vector3.one
        local text = UIUtil.FindText(itemTrans, "Text")
        local attrIcon = UIUtil.AddComponent(UIImage, itemTrans, "")
        local cfg = ConfigUtil.GetGuildSkillCfgByID(self.m_panelData.guildSkillID)
        if cfg then
            if text then
                text.text = cfg.desc
            end
            if attrIcon then
                attrIcon:SetAtlasSprite(cfg.img_name, false, ImageConfig.SkillIcon)
            end
        end
    end
    self.m_starPanelAttrItemPrefab.gameObject:SetActive(false)
end

function UIGetAwardPanelView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
   
    UIUtil.AddClickEvent(self.m_modeBg.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_wujiangBgBtn.gameObject, onClick)
end


function UIGetAwardPanelView:OnClick(go, x, y)
    if not go then
        return
    end

    if self.m_isShowTween then
        return
    end

    local goName = go.name
    if goName == "ButtonTwo" or goName == "modeBg" then
        if self.m_panelData and self.m_panelData.btn2Callback then
            self.m_panelData.btn2Callback()
        end
    elseif go.name == "ButtonOne" then
        if self.m_panelData and self.m_panelData.btn1Callback then
            self.m_panelData.btn1Callback()
        end

    elseif go.name == "WuJiangBgBtn" then
        if self.m_panelData then
            self:CheckShowAward()
            return
        end
    end

    self:CloseSelf()

    for k, v in pairs(self.m_timesItemList) do
        local tempStrId = 4500
        if k == CommonDefine.ITEM_TYPE_GRAVECOPY_ID then
            tempStrId = 4500
        elseif k == CommonDefine.ITEM_TYPE_INSCRIPTIONCOPY_ID then 
            tempStrId = 4501
        elseif k == CommonDefine.ITEM_TYPE_GUILDBOSS_ID then 
            tempStrId = 4502
        elseif k == CommonDefine.ITEM_TYPE_SHENBINGCOPY_ID then 
            tempStrId = 4503
        elseif k == CommonDefine.ITEM_TYPE_HORSESHOW_ID then 
            tempStrId = 4504
        else
            return
        end

        UILogicUtil.FloatAlert(string.format(Language.GetString(tempStrId), v))
    end
end

function UIGetAwardPanelView:RecycleAwardItemList()
    if self.m_awardItemListLoadSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_awardItemListLoadSeq)
        self.m_awardItemListLoadSeq = 0
    end

    for i = 1, #self.m_awardItemList do
        self.m_awardItemList[i]:Delete()
    end
    self.m_awardItemList = {}
end

function UIGetAwardPanelView:ClearOpenModItemList()
    if self.m_openModItem then
        GameObject.DestroyImmediate(self.m_openModItem)
        self.m_openModItem = nil
    end
end

function UIGetAwardPanelView:ClearStarPanelAttrItem()
    if self.m_starPanelAttrItem then
        GameObject.DestroyImmediate(self.m_starPanelAttrItem)
        self.m_starPanelAttrItem = nil
    end
end

function UIGetAwardPanelView:ClearGuildSkillAttrItem()
    if self.m_guildSkillAttrItem then
        GameObject.DestroyImmediate(self.m_guildSkillAttrItem)
        self.m_guildSkillAttrItem = nil
    end
end

function UIGetAwardPanelView:ClearWuJiang()
    if self.m_createHelper then
        self.m_createHelper:Delete()
        self.m_createHelper = nil
    end
end

function UIGetAwardPanelView:CheckAwardWuJiang()
    if not self.m_panelData then
        return
    end

    local awardDataList = self.m_panelData.awardDataList
    if not awardDataList then
        return
    end 

    for i, v in ipairs(awardDataList) do
        if v then
            if v:GetAwardType() == CommonDefine.AWARD_TYPE_HERO then
                table_insert(self.m_awardWuJiangList, v)
            end
        end
    end
end

function UIGetAwardPanelView:CheckShowAward()
    if #self.m_awardWuJiangList > 0 then
        self.m_wujiangRoot:SetActive(true)
        --显示武将
        local awardData = self.m_awardWuJiangList[1]
        local wujiangData = awardData:GetWujiangData()
        table_remove(self.m_awardWuJiangList, 1)
        if wujiangData then
            function CreateWuJiangCallBack(actorShow)
                if actorShow then
                    self.m_createHelper:SetAnchorPos()
                    actorShow:SetEulerAngles(WuJiangRot)
                end
            end
    
            if not self.m_createHelper then
                local createParam = {
                    actorAnchor = self.m_actorAnchor,
                    callBack = CreateWuJiangCallBack,
                    needCreate3DCam = true
                }
                self.m_createHelper = CreateWuJiangHelper.New(createParam)
            end

            self.m_createHelper:CreateWuJiang(wujiangData)

            self:CreateWujiangItem(awardData)
            self:UpdateWuJiangBaseInfo(wujiangData)
            self:UpdateFirstAttr(wujiangData)
        end
    else
        self:ClearWuJiang()
        self.m_wujiangRoot:SetActive(false)
    end
end

function UIGetAwardPanelView:UpdateFirstAttr(wujiangData)
    local prefab = ResourcesManagerInst:LoadSync(TheGameIds.FirstAttrItemPrefab, typeof(GameObject))
    if IsNull(prefab) then
        return
    end

    if #self.m_wujiangFirstAttrItemList == 0 then
        for i = 1, 4 do
            local go = GameObject.Instantiate(prefab)
            local attrItem  = UIWuJiangDetailFirstAttrItem.New(go, self.m_firstAttrTrans)
            table_insert(self.m_wujiangFirstAttrItemList, attrItem)
        end
    end
    
    for i = 1, #self.m_wujiangFirstAttrItemList do
        if self.m_wujiangFirstAttrItemList[i] then
            self.m_wujiangFirstAttrItemList[i]:SetData(wujiangData, i, nil, self.maxFisrtAttrSliderValue)
            self.m_wujiangFirstAttrItemList[i]:SetValueTextSize(24)
        end
    end
end 

function UIGetAwardPanelView:UpdateWuJiangBaseInfo(wujiangData)
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(wujiangData.id)
    if wujiangCfg then
        self.m_wujiangNameText.text = wujiangCfg.sName

        local wujiangStarCfg = ConfigUtil.GetWuJiangStarCfgByID(wujiangData.star)
        if wujiangStarCfg then
            self.m_wuJiangLevelText.text = Language.GetString(609)..string.format("%d", wujiangData.level).."/"..wujiangStarCfg.level_limit
        end
    
        self.m_wuJiangCountryText.text = UILogicUtil.GetWuJiangCountryName(wujiangCfg.country).." • "..UILogicUtil.GetWuJiangJobName(wujiangCfg.nTypeJob)
        UILogicUtil.SetWuJiangRareImage(self.m_wujiangRareImage, wujiangCfg.rare)
        UILogicUtil.SetWuJiangJobImage(self.m_wujiangJobImage, wujiangCfg.nTypeJob)
    
        local star = wujiangData.star
        for i = 1, #self.m_starList do
            if i <= star then
                self.m_starList[i]:SetAtlasSprite("ty11.png")
            else
                self.m_starList[i]:SetAtlasSprite("peiyang23.png")
            end
        end

        self.maxFisrtAttrSliderValue = UILogicUtil.GetCurMaxSliderValueByStars(star)
    end
end

function UIGetAwardPanelView:CreateWujiangItem(awardData)
    function UpdateIconItem()
        if self.m_wujiangIconItem then
            local itemIconParam = PBUtil.CreateAwardParamFromAwardData(awardData)
            self.m_wujiangIconItem:UpdateData(itemIconParam)
        end
    end

    if not self.m_wujiangIconItem then
        self.m_iconLoaderSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()

        UIGameObjectLoader:GetInstance():GetGameObject(self.m_iconLoaderSeq, CommonAwardItemPrefab, function(obj)
            self.m_iconLoaderSeq = 0
            if obj then
                self.m_wujiangIconItem = CommonAwardItem.New(obj, self.m_rightContainer, CommonAwardItemPrefab)
                self.m_wujiangIconItem:SetAnchoredPosition(Vector3.New(-155, 22, 0))
                self.m_wujiangIconItem:SetLocalScale(Vector3.New(0.72, 0.72, 1))
                UpdateIconItem()
            end
        end)
    else
        UpdateIconItem()
    end
end


return UIGetAwardPanelView