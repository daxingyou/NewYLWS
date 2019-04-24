local UIUtil = UIUtil
local Vector3 = Vector3
local Vector2 = Vector2
local Language = Language
local ConfigUtil = ConfigUtil
local Quaternion = Quaternion
local UILogicUtil = UILogicUtil
local table_insert = table.insert
local CommonDefine = CommonDefine
local UIWindowNames = UIWindowNames
local string_format = string.format
local tostring = tostring
local tonumber = tonumber
local math_floor = math.floor
local table_sort = table.sort
local coroutine = coroutine
local GameUtility = CS.GameUtility
local GameObject = CS.UnityEngine.GameObject
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local DOTween = CS.DOTween.DOTween
local Type_Text = typeof(CS.UnityEngine.UI.Text)
local Type_Toggle = typeof(CS.UnityEngine.UI.Toggle)
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local StarPanelItemPath = "UI/Prefabs/StarPanel/StarPanelItem.prefab"
local StarPanelItem = require("UI.UIStarPanel.StarPanelItem")
local StarPanelBoxItemPath = "UI/Prefabs/StarPanel/StarPanelBoxItem.prefab"
local StarPanelBoxItem = require("UI.UIStarPanel.StarPanelBoxItem")

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"

local UIStarPanelView = BaseClass("UIStarPanelView", UIBaseView)
local base = UIBaseView

function UIStarPanelView:OnCreate()
    base.OnCreate(self)

    self:InitView()

    self:HandleClick()

    self:CreateStarAttrList()

    self.m_tabGoList = {}
    self:CreateLayerToggleList()
end

function UIStarPanelView:InitView()
    self.m_bgImage,
    self.m_backBtn,
    self.m_starLinePrefab,
    self.m_attrItemPrefab,
    self.m_starLayerBtnPrefab,
    self.m_starRoot,
    self.m_starLineRoot,
    self.m_starItemRoot,
    self.m_starAttrRoot,
    self.m_attrGrid,
    self.m_switchLayerGrid,
    self.m_starDetailRoot,
    self.m_upStageBtn,
    self.m_layerScrollView,
    self.m_starBoxItemRoot,
    self.m_starAwardDetailRoot,
    self.m_starAwardDetailBg,
    self.m_starAwardItemGrid,
    self.m_upStageCostIcon,
    self.m_bgImage,
    self.m_maskTr
    = UIUtil.GetChildRectTrans(self.transform, {
        "bgImage",
        "Panel/backBtn",
        "starLinePrefab",
        "attrItemPrefab",
        "starLayerBtnPrefab",
        "starRoot",
        "starRoot/starLineRoot",
        "starRoot/starItemRoot",
        "starAttrRoot",
        "starAttrRoot/attrScrollView/Viewport/attrGrid",
        "starAttrRoot/layerScrollView/Viewport/switchLayerGrid",
        "starDetailRoot",
        "starDetailRoot/upStage_BTN",
        "starAttrRoot/layerScrollView",
        "starRoot/starBoxItemRoot",
        "starRoot/starAwardDetailRoot",
        "starRoot/starAwardDetailRoot/starAwardDetailBg",
        "starRoot/starAwardDetailRoot/starAwardDetailBg/starAwardItemGrid",
        "starDetailRoot/upStage_BTN/upStageCostIcon",
        "bgImage",
        "Mask",
    })

    self.m_attrTitleText,
    self.m_starNameText,
    self.m_starDescText,
    self.m_upStageBtnText,
    self.m_upStageCostText,
    self.m_starActiveText
    = UIUtil.GetChildTexts(self.transform, {
        "starAttrRoot/attrTitleText",
        "starDetailRoot/starNameText",
        "starDetailRoot/starDescText",
        "starDetailRoot/upStage_BTN/upStageBtnText",
        "starDetailRoot/upStage_BTN/upStageCostIcon/upStageCostText",
        "starDetailRoot/starActiveText",
    })

    self.m_attrTitleText.text = Language.GetString(2520)
    self.m_upStageBtnText.text = Language.GetString(2501)
    self.m_starActiveText.text = Language.GetString(2505)

    self.m_attrItemPrefab.gameObject:SetActive(false)

    self.m_uiManager = UIManagerInst
    self.m_userManager = Player:GetInstance():GetUserMgr()
    self.m_star_makeid_list = {}
    self.m_starItemList = {}
    self.m_starItemDataList = {}
    self.m_starItemLoadSeq = 0
    self.m_currStarLayer = 1        --当前的星盘层
    self.m_currStarIndex = 1        --当前的星盘索引
    self.m_linkLines = {}
    self.m_currSelectStarItem = nil
    self.m_canActive = false        --是否可以点亮星

    self.m_attrItemList = {}
    self.m_attrValueTextList = {}

    self.m_starBoxItemList = {}
    self.m_boxItemLoadSeq = 0

    self.m_layerToggleList = {}
    self.m_layerToggleTextList = {}

    self.m_curClickBoxItem = false
    self.m_isShowStarAwardDetail = false
    self.m_starAwardItemList = {}
    self.m_starAwardItemLoadSeq = 0
    self.m_layerName = UILogicUtil.FindLayerName(self.transform)
    self.m_maskTr.gameObject:SetActive(false)

    self.m_recordActiveStarID = 0

    self.m_linkImageList = {}
    self.m_itemFrameList = {}
    self.m_tweener = nil
end

function UIStarPanelView:OnDestroy()
    self:RemoveClick()

    for _,v in ipairs(self.m_tabGoList) do
        UIUtil.RemoveClickEvent(v)
        GameObject.Destroy(v)
    end
    self.m_tabGoList = nil

    self:RecycleStarItemList()
    self.m_starItemList = nil

    self:RecycleBoxItemList()
    self.m_starBoxItemList = nil

    self:RecycleStarAwardItemList()
    self.m_starAwardItemList = nil

    self.m_bgImage = nil
    self.m_backBtn = nil
    self.m_starLinePrefab = nil
    self.m_attrItemPrefab = nil
    self.m_starLayerBtnPrefab = nil
    self.m_starRoot = nil
    self.m_starLineRoot = nil
    self.m_starItemRoot = nil
    self.m_starAttrRoot = nil
    self.m_attrGrid = nil
    self.m_switchLayerGrid = nil
    self.m_starDetailRoot = nil
    self.m_upStageBtn = nil
    self.m_starAwardDetailRoot = nil
    self.m_starAwardDetailBg = nil
    self.m_starAwardItemGrid = nil

    self.m_attrTitleText = nil
    self.m_starNameText = nil
    self.m_starDescText = nil
    self.m_upStageBtnText = nil
    self.m_upStageCostText = nil
    self.m_starActiveText = nil

    self.m_uiManager = nil
    self.m_userManager = nil
    self.m_star_makeid_list = nil
    self.m_starItemDataList = nil

    self:ClearLines()
    self.m_linkLines = nil
    self.m_currSelectStarItem = nil
    
    self.m_attrItemList = nil
    self.m_attrValueTextList = nil

    self.m_layerToggleList = nil
    self.m_layerToggleTextList = nil

    self.m_linkImageList = nil
    self.m_itemFrameList = nil
    if self.m_tweener then
        UIUtil.KillTween(self.m_tweener)
    end

    base.OnDestroy(self)
end

function UIStarPanelView:OnEnable()
    base.OnEnable(self)

    self:ChgStarAwardDetailState(false)

    self.m_userManager:ReqStarPanel()

    self:TweenOpen()
end

function UIStarPanelView:OnDisable()
    UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)
    self:ChgStarAwardDetailState(false)

    self:ClearLines()
    self:RecycleStarItemList()
    self:RecycleBoxItemList()
    self:RecycleStarAwardItemList()

    self.m_star_makeid_list = {}
    self.m_starItemDataList = {}
    
    self.m_currStarLayer = 1
    self.m_currStarIndex = 0
    self.m_currSelectStarItem = nil

    self.m_recordActiveStarID = 0

    self.m_itemFrameList = {}
    if self.m_tweener then
        UIUtil.KillTween(self.m_tweener)
    end

    self.m_maskTr.gameObject:SetActive(false)
    base.OnDisable(self)
end

function UIStarPanelView:OnAddListener()
    base.OnAddListener(self)
    
    self:AddUIListener(UIMessageNames.MN_STAR_PANEL_UPDATE, self.RspPanelData)
    self:AddUIListener(UIMessageNames.MN_NTF_STAR_CHG, self.NtfStarChg)
    self:AddUIListener(UIMessageNames.MN_STAR_PANEL_ON_ACTIVE_STAR, self.OnActiveStar)
end

function UIStarPanelView:OnRemoveListener()
    base.OnRemoveListener(self)
    
    self:RemoveUIListener(UIMessageNames.MN_STAR_PANEL_UPDATE, self.RspPanelData)
    self:RemoveUIListener(UIMessageNames.MN_NTF_STAR_CHG, self.NtfStarChg)
    self:RemoveUIListener(UIMessageNames.MN_STAR_PANEL_ON_ACTIVE_STAR, self.OnActiveStar)
end

function UIStarPanelView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_bgImage.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_upStageBtn.gameObject, onClick)
end

function UIStarPanelView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_bgImage.gameObject)
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_upStageBtn.gameObject)
end

function UIStarPanelView:OnClick(go, x, y)
    if not go then
        return
    end

    local goName = go.name
    if goName == "upStage_BTN" then
        if self.m_currSelectStarItem then
            local starCfg = self.m_currSelectStarItem:GetStarItemCfg()
            if starCfg then
                self.m_userManager:ReqActiveStar(starCfg.id)
                self.m_recordActiveStarID = starCfg.id
            end
            TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, "UIStarPanelUpStageBtn")
        end
    elseif goName == "backBtn" then
        self.m_uiManager:CloseWindow(UIWindowNames.UIStarPanel)
        TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, "UIStarPanelBackBtn")
    elseif goName == "bgImage" then
        self:ChgStarAwardDetailState(false)
    end
end

function UIStarPanelView:NtfStarChg()
    if GuideMgr:GetInstance():IsPlayingGuide(GuideEnum.GUIDE_STAR) then
        return
    end
    coroutine.start(function()
        self.m_maskTr.gameObject:SetActive(true)
        coroutine.waitforseconds(1)
        self.m_maskTr.gameObject:SetActive(false)
        self:RspPanelData()
    end)
end

function UIStarPanelView:CreateStarAttrList()
    self.m_attrItemPrefab.gameObject:SetActive(true)
    local startIndex = CommonDefine.battle_attr_min
    for i = startIndex + 1, CommonDefine.battle_attr_max - 14 do
        local attrItemGo = GameObject.Instantiate(self.m_attrItemPrefab.gameObject)
        if attrItemGo then
            local attrItemTrans = attrItemGo.transform
            attrItemTrans:SetParent(self.m_attrGrid)
            attrItemTrans.localScale = Vector3.one
            attrItemTrans.localPosition = Vector3.zero
            local attrNameText = UIUtil.FindComponent(attrItemTrans, Type_Text, "attrNameText")
            local attrValueText = UIUtil.FindComponent(attrItemTrans, Type_Text, "attrValueText")
            if attrNameText then
                attrNameText.text = Language.GetString(2540 + i - startIndex)
            end
            if attrValueText then
                self.m_attrValueTextList[i] = attrValueText
            end
        end
    end
    self.m_attrItemPrefab.gameObject:SetActive(false)
end

function UIStarPanelView:CreateLayerToggleList()
    self.m_starLayerBtnPrefab.gameObject:SetActive(true)
    local maxLayer = UILogicUtil.GetStarCfgMaxLayer()
    for i = 1, maxLayer do
        local layerBtn = GameObject.Instantiate(self.m_starLayerBtnPrefab.gameObject)
        if layerBtn then
            layerBtn.name = tostring(i)
            local layerBtnTrans = layerBtn.transform
            layerBtnTrans:SetParent(self.m_switchLayerGrid)
            layerBtnTrans.localPosition = Vector3.zero
            layerBtnTrans.localScale = Vector3.one
            local lowLightText, hightLightText = UIUtil.GetChildTexts(layerBtnTrans, {"lowLightSpt/lowLightText", "highLightSpt/highLightText"})
            local numStr = string_format(Language.GetString(2500), UILogicUtil.GetChineseNumByArabNum(i))
            lowLightText.text = numStr
            hightLightText.text = numStr
            local toggle = layerBtn:GetComponent(Type_Toggle)
            self.m_layerToggleList[i] = toggle
            self.m_layerToggleTextList[i] = hightLightText
            
            local onClick = UILogicUtil.BindClick(self, self.OnLayerBtnClick)
            UIUtil.AddClickEvent(layerBtn, onClick)

            table_insert(self.m_tabGoList, layerBtn)
        end
    end
    self.m_starLayerBtnPrefab.gameObject:SetActive(false)
end

function UIStarPanelView:OnLayerBtnClick(go, x, y)
    if not go then
        return
    end
    local layer = tonumber(go.name)
    if self.m_currStarLayer ~= layer then
        self:ChgStarAwardDetailState(false)
        self.m_currStarLayer = layer
        self.m_currStarIndex = 0
        self:UpdatePanel()
    end
end

function UIStarPanelView:RspPanelData()
    local currStarLayer, currStarIndex = UILogicUtil.GetMaxStarLayerAndIndex(self.m_userManager:GetStarMakeIDList())
    local makeID = currStarLayer * 100 + currStarIndex + 1
    -- local cfg = ConfigUtil.GetStarCfgByID(makeID)
    -- if not cfg then
    --     currStarLayer = currStarLayer + 1
    --     currStarIndex = 1
    -- end

    self.m_currStarLayer = currStarLayer
    self.m_currStarIndex = currStarIndex

    -- print('self.m_currStarLayer self.m_currStarIndex ', self.m_currStarLayer , self.m_currStarIndex )
    self:CheckCanGetBoxAward()
    self:UpdatePanel()
end

function UIStarPanelView:CheckCanGetBoxAward()
    for i = 1, self.m_currStarLayer do
        local starCfgList = UILogicUtil.GetStarCfgListByLayer(i)
        local canGetAward = false
        local canBreak = false
        for k, v in ipairs(starCfgList) do
            local haveGetAward = self.m_userManager:CheckHaveGetStarBoxAward(v.id)
            local haveActive = self.m_userManager:CheckStarIsActive(v.id)
            canGetAward = not haveGetAward and haveActive
            if canGetAward and v.item_id1 ~= 0 then
                canBreak = true
                self.m_currStarLayer = i
                break
            end
        end
        if canBreak then
            break
        end
    end
end

function UIStarPanelView:UpdatePanel()

    self:InitStarData()

    self:CreateStarItemList()

    self:UpdateStarBoxItemList()

    self:UpdateStarAttrContainer()

    self:UpdateCurrLayerBtn()

    self:ChgStarAwardDetailState(false)

    TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
end

function UIStarPanelView:InitStarData()
    self.m_starItemDataList = UILogicUtil.GetStarCfgListByLayer(self.m_currStarLayer)
end

function UIStarPanelView:CreateStarItemList()
    self:RecycleStarItemList()
    if not self.m_starItemDataList then
        return
    end

    self.m_starItemLoadSeq = UIGameObjectLoaderInst:PrepareOneSeq()
    UIGameObjectLoaderInst:GetGameObjects(self.m_starItemLoadSeq, StarPanelItemPath, #self.m_starItemDataList, function(objs)
        self.m_starItemLoadSeq = 0
        if not objs then
            return
        end

        for i = 1, #objs do
            local starItem = StarPanelItem.New(objs[i], self.m_starItemRoot, StarPanelItemPath)
            if starItem then
                table_insert(self.m_starItemList, starItem)
                local itemFramImage = starItem:GetFrameImage()
                if itemFramImage then
                    table_insert(self.m_itemFrameList, itemFramImage)
                end
            end
        end

        self:UpdateStarItemList()
        self:UpdateLinkLines()
    end)

    self:TweenStar()
end

function UIStarPanelView:UpdateStarItemList()
    
    local onStarItemClick = Bind(self, self.OnStarItemClick)
    
    for i = 1, #self.m_starItemDataList do
        local starItem = self.m_starItemList[i]
        if starItem then
            local starItemCfg = self.m_starItemDataList[i]
            if starItemCfg then
                starItem:UpdateData(starItemCfg, onStarItemClick)
                starItem:SetActiveState(self.m_userManager:CheckStarIsActive(starItemCfg.id))
            end
        end
    end
    table_sort(self.m_starItemList, function(x, y)
        if not x or not y then
            return false
        end
        local indexX = x:GetStarIndex()
        local indexY = y:GetStarIndex()
        return indexX < indexY
    end)

    if self.m_currStarIndex + 1 <= #self.m_starItemList then
        local selectStarItem = self.m_starItemList[self.m_currStarIndex + 1]
        self:UpdateSelectItemDetail(selectStarItem)
    else
        if self.m_currStarLayer < #self.m_layerToggleTextList then
            self.m_currStarLayer = self.m_currStarLayer + 1
            self.m_currStarIndex = 0
            self:CheckCanGetBoxAward()
            self:UpdatePanel()
        else
            local selectStarItem = self.m_starItemList[self.m_currStarIndex]
            self:UpdateSelectItemDetail(selectStarItem)
        end
    end
end

function UIStarPanelView:OnStarItemClick(starItem)
    self:UpdateSelectItemDetail(starItem)
    self:ChgStarAwardDetailState(false)
    TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, "UIStarPanelItem0")
end

function UIStarPanelView:UpdateStarBoxItemList()
    self:RecycleBoxItemList()

    if not self.m_starItemDataList then
        return
    end

    local itemDataList = {}
    for i = 1, #self.m_starItemDataList do
        local _, count = UILogicUtil.GetStarBoxAwardList(self.m_starItemDataList[i])
        if count > 0 then
            local tmp = {index = i, data = self.m_starItemDataList[i]}
            table_insert(itemDataList, tmp)
        end
    end
    local onStarBoxItemClick = Bind(self,self.OnStarBoxItemClick)
    self.m_boxItemLoadSeq = UIGameObjectLoaderInst:PrepareOneSeq()
    UIGameObjectLoaderInst:GetGameObjects(self.m_boxItemLoadSeq, StarPanelBoxItemPath, #itemDataList, function(objs)
        if not objs then
            return
        end
        for i = 1, #objs do
            local boxItem = StarPanelBoxItem.New(objs[i], self.m_starBoxItemRoot, StarPanelBoxItemPath)
            if boxItem then
                local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
                boxItem:UpdateData(itemDataList[i].data, sortOrder, onStarBoxItemClick)
                table_insert(self.m_starBoxItemList, boxItem)
            end
        end
    end)
end

function UIStarPanelView:OnStarBoxItemClick(boxItem)
    if not boxItem then
        return
    end
    if self.m_curClickBoxItem ~= boxItem or not self.m_isShowStarAwardDetail then
        self.m_curClickBoxItem = boxItem
        self.m_starAwardDetailRoot.localScale = Vector3.New(1, 0, 1)
        self:ChgStarAwardDetailState(true, boxItem)
    end
end

function UIStarPanelView:ChgStarAwardDetailState(isShow, boxItem)
    isShow = isShow and boxItem
    self.m_isShowStarAwardDetail = isShow
    if isShow then
        self:UpdateStarAwardDetail(boxItem:GetStarItemCfg())
        DOTweenShortcut.DOKill(self.m_starAwardDetailRoot)
        DOTweenShortcut.DOScaleY(self.m_starAwardDetailRoot, 1, 0.1)
    else
        DOTweenShortcut.DOKill(self.m_starAwardDetailRoot)
        DOTweenShortcut.DOScaleY(self.m_starAwardDetailRoot, 0, 0.1)
    end
end

function UIStarPanelView:UpdateStarAwardDetail(starItemCfg)
    if not starItemCfg then
        return
    end

    local starItemPos = UILogicUtil.GetStarCfgItemPos(starItemCfg)
    local boxOffset = UILogicUtil.GetStarCfgBoxOffset(starItemCfg)
    if starItemPos and boxOffset then
        local boxItemPos = Vector3.New(starItemPos.x + boxOffset.x, starItemPos.y + boxOffset.y, starItemPos.z + boxOffset.z)
        local isUp = boxOffset.y > 0
        self.m_starAwardDetailBg.localScale = Vector3.New(1, (isUp and -1 or 1), 1)
        self.m_starAwardItemGrid.localScale = Vector3.New(1, (isUp and -1 or 1), 1)
        local pos = Vector3.New(boxItemPos.x, boxItemPos.y + (isUp and 115 or -115), boxItemPos.z)
        self.m_starAwardDetailRoot.localPosition = pos
    end

    self:RecycleStarAwardItemList()
    local awardList, awardCount = UILogicUtil.GetStarBoxAwardList(starItemCfg)
    self.m_starAwardItemLoadSeq = UIGameObjectLoaderInst:PrepareOneSeq()
    UIGameObjectLoaderInst:GetGameObjects(self.m_starAwardItemLoadSeq, CommonAwardItemPrefab, awardCount, function(objs)
        if not objs then
            return
        end
        self.m_starAwardItemLoadSeq = 0

        local index = 1
        for id, count in pairs(awardList) do
            local awardItem = CommonAwardItem.New(objs[index], self.m_starAwardItemGrid, CommonAwardItemPrefab)
            awardItem:SetLocalScale(Vector3.New(0.6, 0.6, 0.6))
            local itemIconParam = AwardIconParamClass.New(id, count)
            awardItem:UpdateData(itemIconParam)
            
            table_insert(self.m_starAwardItemList, awardItem)

            index = index + 1
        end
    end)
    
    self.m_starAwardDetailRoot.sizeDelta = Vector2.New(awardCount * 115, self.m_starAwardDetailRoot.sizeDelta.y)
end

function UIStarPanelView:UpdateLinkLines()
    self:ClearLines()

    self.m_starLinePrefab.gameObject:SetActive(true)
    for i = 1, #self.m_starItemList - 1 do
        local line = GameObject.Instantiate(self.m_starLinePrefab.gameObject)
        if line then
            local lineRectTrans = line:GetComponent(Type_RectTransform)
            lineRectTrans:SetParent(self.m_starLineRoot)
            local index1 = self.m_starItemList[i]:GetStarItemCfg().star_index
            local index2 = self.m_starItemList[i + 1]:GetStarItemCfg().star_index
            local startPos = self.m_starItemList[i]:GetPos()
            local endPos = self.m_starItemList[i + 1]:GetPos()
            local pos = Vector3.New((startPos.x + endPos.x) * 0.5, (startPos.y + endPos.y) * 0.5, 0)
            lineRectTrans.localPosition = pos

            local len = Vector3.Distance(startPos, endPos) - 130
            lineRectTrans.sizeDelta = Vector2.New(2, len)
            lineRectTrans.localScale = Vector3.one

            local angle = Vector3.Angle((endPos - startPos), Vector3.right)
            local dir = Vector3.New(endPos.x - startPos.x, endPos.y - startPos.y, 0)
            local cross1 = Vector3.Cross(dir, Vector3.right)
            local cross2 = Vector3.Cross(Vector3.up, Vector3.right)
            if Vector3.Dot(cross1, cross2) < 0 then
                 angle = 90 - angle
            else
                angle = 90 + angle
            end
            lineRectTrans.localRotation = Quaternion.Euler(0, 0, angle)
            table_insert(self.m_linkLines, line)

            local lineImage = UIUtil.AddComponent(UIImage, line, "")
            if lineImage then
                table_insert(self.m_linkImageList, lineImage)
            end
        end
    end
    self.m_starLinePrefab.gameObject:SetActive(false)
end

function UIStarPanelView:UpdateSelectItemDetail(selectStarItem)
    if not selectStarItem or self.m_currSelectStarItem == selectStarItem then
        return
    end
    if self.m_currSelectStarItem then
        self.m_currSelectStarItem:SetOnSelectState(false)
    end
    self.m_currSelectStarItem = selectStarItem
    self.m_currSelectStarItem:SetOnSelectState(true)
    self:UpdateStarDetailContainer()
end

function UIStarPanelView:UpdateStarAttrContainer()
    if not self.m_starItemDataList then
        return
    end

    local tbl = ConfigUtil.GetStarCfgList()
    local startIndex = CommonDefine.battle_attr_min + 1
    local endIndex = CommonDefine.battle_attr_max - 14
    for i = startIndex, endIndex do
        local filedName = UILogicUtil.GetFiledNameByBattleAttrType(i)
        if filedName then
            local currAttrValue = 0
            local totalAttrValue = 0
            for id, starItemCfg in pairs(tbl) do
                if starItemCfg then
                    local attrValue = starItemCfg[filedName] or 0
                    totalAttrValue = totalAttrValue + attrValue
                    if self.m_userManager:CheckStarIsActive(id) then
                        currAttrValue = currAttrValue + attrValue
                    end
                end
            end
            self.m_attrValueTextList[i].text = string_format(Language.GetString(2504), currAttrValue, totalAttrValue)
        end
    end
end

function UIStarPanelView:UpdateCurrLayerBtn()
    local toggle = self.m_layerToggleList[self.m_currStarLayer]
    if toggle then
        toggle.isOn = true
    end
    
    local childCount = #self.m_layerToggleList
    local width = self.m_starLayerBtnPrefab.sizeDelta.x * childCount
    local avgWidth = width / childCount
    local posX = (childCount * 0.5 - self.m_currStarLayer + 0.5) * avgWidth
    if self.m_currStarLayer == 1 then
        posX = posX - avgWidth
    elseif self.m_currStarLayer == childCount then
        posX = posX + avgWidth
    end
    for i = 1, childCount do
        self.m_layerToggleTextList[i].gameObject:SetActive(i == self.m_currStarLayer)
    end
    DOTweenShortcut.DOKill(self.m_switchLayerGrid)
    DOTweenShortcut.DOLocalMoveX(self.m_switchLayerGrid, posX, 0.2)
end

function UIStarPanelView:UpdateStarDetailContainer()
    if self.m_currSelectStarItem then
        local starItemCfg = self.m_currSelectStarItem:GetStarItemCfg()
        if starItemCfg then
            self.m_starDescText.text = starItemCfg.star_desc
            self.m_starNameText.text = starItemCfg.star_name
            --更新star数量
            local totalStarCount = self.m_userManager:GetCopyStarCount()
            local costStarCount = starItemCfg.star_count
            self.m_upStageCostText.text = string_format(Language.GetString(2503), totalStarCount, costStarCount)
            coroutine.start(UIStarPanelView.ResetCostText, self)
            --更新激活状态
            self.m_canActive = self.m_userManager:CheckStarIsActive(starItemCfg.id)
            self.m_upStageBtn.gameObject:SetActive(not self.m_canActive)
            self.m_starActiveText.gameObject:SetActive(self.m_canActive)
            local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
            for i, v in ipairs(self.m_starItemList) do
                if v == self.m_currSelectStarItem then
                    if totalStarCount >= costStarCount then
                        v:Effect(sortOrder, not self.m_canActive)
                    else
                        v:Effect(sortOrder, false)
                    end
                else
                    v:Effect(sortOrder, false)
                end
            end
        end
    end
end

function UIStarPanelView:ResetCostText()
    coroutine.waitforframes(1)
    GameUtility.KeepCenterAlign(self.m_upStageCostIcon, self.m_upStageBtn)
end

--备份，宇华
-- function UIStarPanelView:OnActiveStar(msg_obj)
--     if not msg_obj then
--         return
--     end
--     local uiData = {}
--     uiData.openModID = msg_obj.open_mod
--     if uiData.openModID > 0 then
--         uiData.openType = 2
--         uiData.btn1Callback = function()
--             GuideMgr:GetInstance():CheckAndPerformGuide()
--         end
--         uiData.btn2Callback = function()
--             GuideMgr:GetInstance():CheckAndPerformGuide()
--         end
--         UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
--     else
--         local attrIndex, attrVal = self:GetStarPanelActiveAttr(self.m_recordActiveStarID)
--         if attrVal > 0 then
--             uiData.openType = 3
--             local attrName = Language.GetString(2521 + attrIndex)
--             local attrDesc = string_format(Language.GetString(2508), attrName, attrVal)
--             uiData.starPanelAtteDesc = attrDesc
--             UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
--         end
--     end
--     self.m_recordActiveStarID = 0
-- end

--修改，赵文韬
function UIStarPanelView:OnActiveStar(msg_obj)
    if not msg_obj then
        return
    end
    local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
    if self.m_currSelectStarItem then
        self.m_currSelectStarItem:Effect(sortOrder, false, false)
        self.m_currSelectStarItem:Effect(sortOrder, false, true)
        self.m_currSelectStarItem:SetActiveState(true)
    end
    coroutine.start(function()
        self.m_maskTr.gameObject:SetActive(true)
        coroutine.waitforseconds(0.6)
        self.m_maskTr.gameObject:SetActive(false)
        local uiData = {}
        uiData.openModID = msg_obj.open_mod
        if uiData.openModID > 0 then
            uiData.openType = 2
            uiData.btn1Callback = function()
                GuideMgr:GetInstance():CheckAndPerformGuide()
            end
            uiData.btn2Callback = function()
                GuideMgr:GetInstance():CheckAndPerformGuide()
            end
            UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
        else
            local attrIndex, attrVal = self:GetStarPanelActiveAttr(self.m_recordActiveStarID)
            if attrVal > 0 then
                uiData.openType = 3
                local attrName = Language.GetString(2521 + attrIndex)
                local attrDesc = string_format(Language.GetString(2508), attrName, attrVal)
                uiData.starPanelAtteDesc = attrDesc
                uiData.starID = self.m_recordActiveStarID
                UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
            end
        end
        self.m_recordActiveStarID = 0
    end)
end

function UIStarPanelView:GotoNextItem()
    if self.m_currStarIndex < #self.m_starItemList then
        self.m_currSelectStarItem:SetOnSelectState(false)
        self.m_currSelectStarItem = self.m_starItemList[self.m_currStarIndex + 1]
        self.m_currSelectStarItem:SetOnSelectState(true)
        self:UpdateStarDetailContainer()
    end
end

function UIStarPanelView:GetStarPanelActiveAttr(activeStarID)
    local attrVal = 0
    local attrIndex = 0
    local startIndex = CommonDefine.battle_attr_min + 1
    local endIndex = CommonDefine.battle_attr_max - 14
    local cfg = ConfigUtil.GetStarCfgByID(activeStarID)
    if cfg then
        for i = startIndex, endIndex do
            local filedName = UILogicUtil.GetFiledNameByBattleAttrType(i)
            if filedName then
                attrVal = cfg[filedName]
                attrIndex = i
                if attrVal > 0 then
                    break
                end
            end
        end
    end
    local index = attrIndex - startIndex
    return index, attrVal
end

function UIStarPanelView:RecycleStarItemList()
    if self.m_starItemLoadSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_starItemLoadSeq)
        self.m_starItemLoadSeq = 0
    end

    for i = 1, #self.m_starItemList do
        self.m_starItemList[i]:Delete()
    end
    self.m_starItemList = {}
    
    self.m_currSelectStarItem = nil
end

function UIStarPanelView:ClearLines()
    for i = 1, #self.m_linkLines do
        GameObject.Destroy(self.m_linkLines[i])
    end

    for i = 1, #self.m_linkImageList do
        if self.m_linkImageList[i] then
            self.m_linkImageList[i]:Delete()
            self.m_linkImageList[i] = nil
        end
    end 

    self.m_linkImageList = {}
    self.m_linkLines = {}
end

function UIStarPanelView:RecycleBoxItemList()
    if self.m_boxItemLoadSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_boxItemLoadSeq)
        self.m_boxItemLoadSeq = 0
    end

    for i = 1, #self.m_starBoxItemList do
        self.m_starBoxItemList[i]:Delete()
    end
    self.m_starBoxItemList = {}
end

function UIStarPanelView:RecycleStarAwardItemList()
    if self.m_starAwardItemLoadSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_starAwardItemLoadSeq)
        self.m_starAwardItemLoadSeq = 0
    end

    for i = 1, #self.m_starAwardItemList do
        self.m_starAwardItemList[i]:Delete()
    end
    self.m_starAwardItemList = {}
end

function UIStarPanelView:TweenStar()
    if self.m_tweener then
        UIUtil.KillTween(self.m_tweener)
    end

    self.m_tweener = DOTween.ToFloatValue(function()
        return 0
    end, 
    function(value)
        
        for i = 1, #self.m_linkImageList do
            self.m_linkImageList[i]:SetColor(Color.New(1, 1, 1, 1 - value * 0.9))
        end

        for i = 1, #self.m_itemFrameList do
            self.m_itemFrameList[i]:SetColor(Color.New(1, 1, 1, 1 - value * 0.9))
        end

    end, 1, 2)
    DOTweenSettings.SetLoops(self.m_tweener, -1, 1)
end

function UIStarPanelView:TweenOpen()
    DOTween.ToFloatValue(function()
        return 0
    end, 
    function(value)
        self.m_backBtn.anchoredPosition = Vector3.New(236, -46.5 + 150 - 150 * value, 0)
        self.m_starAttrRoot.anchoredPosition = Vector3.New(1069 - 500 * value, 0, 0)
        self.m_starDetailRoot.anchoredPosition = Vector3.New(0, -585 + 200 * value, 0)
        local scale = 1.5 - 0.5 * value
        self.m_bgImage.localScale = Vector3.New(scale, scale, scale)
        local scale = 1.25 - 0.25 * value
        self.m_starRoot.localScale = Vector3.New(scale, scale, scale)
    end, 1, 0.3)
end

return UIStarPanelView