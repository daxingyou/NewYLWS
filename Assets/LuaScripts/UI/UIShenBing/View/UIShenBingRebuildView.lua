
local math_ceil = math.ceil
local string_format = string.format
local table_insert = table.insert
local table_remove = table.remove
local string_split = string.split

local ShenBingMgr = Player:GetInstance():GetShenBingMgr()
local WuJiangMgr = Player:GetInstance():GetWujiangMgr()
local UserMgr = Player:GetInstance():GetUserMgr()
local ItemMgr = Player:GetInstance():GetItemMgr()
local UIGameObjectLoader = UIGameObjectLoader:GetInstance()
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local bagItemPath = TheGameIds.CommonBagItemPrefab
local GameUtility = CS.GameUtility
local GameObject = CS.UnityEngine.GameObject
local bagItem = require "UI.UIBag.View.BagItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local ShenBingObjPath = "UI/Prefabs/Shenbing/ShenBingObj.prefab"
local Language = Language
local UILogicUtil = UILogicUtil
local UIUtil = UIUtil
local AtlasConfig = AtlasConfig
local CommonDefine = CommonDefine
local effectPath = TheGameIds.shenbing_chongzhu_fx_path

local UIShenBingRebuildView = BaseClass("UIShenBingRebuildView", UIBaseView)
local base = UIBaseView

function UIShenBingRebuildView:OnCreate()
    base.OnCreate(self)
    self:InitView()
end

function UIShenBingRebuildView:InitView()
    local titleText, AttrOneText, AttrTwoText, AttrThreeText, InsOneName, InsTwoName,
    InsThreeName, InsOneAttrText, InsTwoAttrText, InsThreeAttrText, choiceText, rebuildBtnName,
    choiceOneItemParent, choiceTwoItemParent, choiceTwoItemParent, InsOneImg, InsTwoImg, InsThreeImg

    titleText, self.m_sortBtnText, self.m_levelSortBtnText, self.m_shenbingCountText,
    self.m_shenbingInfoText, self.m_shenbingMasterText, self.m_shenbingStageText, AttrOneText, AttrTwoText,
    AttrThreeText, InsOneName, InsTwoName, InsThreeName, InsOneAttrText, InsTwoAttrText, InsThreeAttrText, choiceText,
    rebuildBtnName, self.m_coinsCountText = UIUtil.GetChildTexts(self.transform, {
        "LeftContainer/ChoiceShenBing/bg/top/Text",
        "LeftContainer/ChoiceShenBing/bg/mid/btnGrid/SortBtn/SortBtnText",
        "LeftContainer/ChoiceShenBing/bg/mid/btnGrid/LevelSortBtn/LevelSortBtnText",
        "LeftContainer/ChoiceShenBing/bg/mid/CountText",
        "RightContainer/ShenBingInfo/bg/Info/ShenBingInfoText",
        "RightContainer/ShenBingInfo/bg/MasterText",
        "RightContainer/ShenBingInfo/bg/Info/StageText",
        "RightContainer/ShenBingInfo/bg/TextGrid/AttributeTextOne",
        "RightContainer/ShenBingInfo/bg/TextGrid/AttributeTextTwo",
        "RightContainer/ShenBingInfo/bg/TextGrid/AttributeTextThree",
        "RightContainer/Inscription/InscriptionItemOne/InscriptionImg/InscriptionName",
        "RightContainer/Inscription/InscriptionItemTwo/InscriptionImg/InscriptionName",
        "RightContainer/Inscription/InscriptionItemThree/InscriptionImg/InscriptionName",
        "RightContainer/Inscription/InscriptionItemOne/bg/attributeText",
        "RightContainer/Inscription/InscriptionItemTwo/bg/attributeText",
        "RightContainer/Inscription/InscriptionItemThree/bg/attributeText",
        "MiddleContainer/choiceText",
        "MiddleContainer/RebuildBtn/Text",
        "MiddleContainer/expend/countText"
    })

    self.m_LeftContainerTr, self.m_scrollViewTr, self.m_sortBtn, self.m_levelSortBtn, self.m_ruleBtn,
    self.m_backBtn, self.m_insOneRandomGo, self.m_insTwoRandomGo, self.m_insThreeRandomGo, self.m_rebuildBtn,
    self.m_curShenBingParent, choiceOneItemParent, choiceTwoItemParent, choiceThreeItemParent,
    self.m_rightContainerTr, self.m_midContainerTr, self.m_inscriptionItemThreeTr = UIUtil.GetChildTransforms(self.transform, {
        "LeftContainer",
        "LeftContainer/ChoiceShenBing/bg/ItemScrollView/Viewport/ItemContent",
        "LeftContainer/ChoiceShenBing/bg/mid/btnGrid/SortBtn",
        "LeftContainer/ChoiceShenBing/bg/mid/btnGrid/LevelSortBtn",
        "LeftContainer/ChoiceShenBing/bg/top/ruleButton",
        "Panel/BackBtn",
        "RightContainer/Inscription/InscriptionItemOne/InscriptionImg/randomRebuild",
        "RightContainer/Inscription/InscriptionItemTwo/InscriptionImg/randomRebuild",
        "RightContainer/Inscription/InscriptionItemThree/InscriptionImg/randomRebuild",
        "MiddleContainer/RebuildBtn",
        "RightContainer/ShenBingInfo/bg/curShenBingParent",
        "MiddleContainer/Grid/materialOne/bagItemParent",
        "MiddleContainer/Grid/materialTwo/bagItemParent",
        "MiddleContainer/Grid/materialThree/bagItemParent",
        "RightContainer",
        "MiddleContainer",
        "RightContainer/Inscription/InscriptionItemThree",
    })

    self.m_inscriptionItemThreeGo = self.m_inscriptionItemThreeTr.gameObject
    self.m_insOneRandomGo = self.m_insOneRandomGo.gameObject
    self.m_insTwoRandomGo = self.m_insTwoRandomGo.gameObject
    self.m_insThreeRandomGo = self.m_insThreeRandomGo.gameObject
    titleText.text = Language.GetString(2900)
    choiceText.text = Language.GetString(2920)
    rebuildBtnName.text = Language.GetString(2907)
    self.m_sortPriorityTexts = string_split(Language.GetString(2901), "|")
    self.m_levelSortPriorityTexts = string_split(Language.GetString(2902), "|")

    InsOneImg = UIUtil.AddComponent(UIImage, self, "RightContainer/Inscription/InscriptionItemOne/InscriptionImg")
    InsTwoImg = UIUtil.AddComponent(UIImage, self, "RightContainer/Inscription/InscriptionItemTwo/InscriptionImg")
    InsThreeImg = UIUtil.AddComponent(UIImage, self, "RightContainer/Inscription/InscriptionItemThree/InscriptionImg")

    self.m_scrollView = self:AddComponent(LoopScrowView, "LeftContainer/ChoiceShenBing/bg/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdataShenBingList))
    
    self.m_attrTextList = {AttrOneText, AttrTwoText, AttrThreeText}
    self.m_insNameTextList = {InsOneName, InsTwoName, InsThreeName}
    self.m_insAttrTextList = {InsOneAttrText, InsTwoAttrText, InsThreeAttrText}
    self.m_choiceItemParentList = {choiceOneItemParent, choiceTwoItemParent, choiceThreeItemParent}
    self.m_insImgList = {InsOneImg, InsTwoImg, InsThreeImg}

    self.m_seq = 0
    self.m_infoSeq = 0
    self.m_choiceSeq = 0
    self.m_shenbingItemList = {}
    self.m_shenbingModels = {}
    self.m_choiceShenBingItemList = {}
    self.m_choiceShenBingPrefabList = {}
    self.m_curShenBingData = false
    self.m_curShenBingInfoItem = false
    self.m_wujiangIndex = -1
    self.m_wujaingId = -1

    self.m_effectList = {} --暂时只有一个，但用list保存

    self:HandleClick()
end

function UIShenBingRebuildView:GetLeftContainerPosX()
    local posX = 800
    if CommonDefine.IS_HAIR_MODEL then
		posX = posX + 95
    end
    
    return posX
end

function UIShenBingRebuildView:ShowDoTween()
    local posX = self:GetLeftContainerPosX()

    UIUtil.LoopMoveLocalY(self.m_midContainerTr, 0, 417, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_rightContainerTr, -350, -800, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_LeftContainerTr, 232, posX, 0.4, false)
end

function UIShenBingRebuildView:HideDotween()
    local posX = self:GetLeftContainerPosX()

    UIUtil.LoopMoveLocalY(self.m_midContainerTr, 417, 0, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_rightContainerTr, -800, -350, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_LeftContainerTr, posX, 232, 0.4, false)
end

function UIShenBingRebuildView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_sortBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_levelSortBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_ruleBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_rebuildBtn.gameObject, onClick)
end

function UIShenBingRebuildView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_sortBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_levelSortBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_rebuildBtn.gameObject)
end

function UIShenBingRebuildView:OnAddListener()
    base.OnAddListener(self)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_RSP_SHENBING_REBUILD, self.RspShenBingRebuild)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_RSP_CONFIRM_SHENBING_REBUILD, self.RspConfirmShenBingRebuild)
    self:AddUIListener(UIMessageNames.MN_ITEM_LOCK_CHG, self.OnLockChg)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange)
end

function UIShenBingRebuildView:OnRemoveListener()
    base.OnRemoveListener(self)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_RSP_SHENBING_REBUILD, self.RspShenBingRebuild)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_RSP_CONFIRM_SHENBING_REBUILD, self.RspConfirmShenBingRebuild)
    self:RemoveUIListener(UIMessageNames.MN_ITEM_LOCK_CHG, self.OnLockChg)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange)
end

function UIShenBingRebuildView:PowerChange(power)
    UILogicUtil.PowerChange(power)
end

function UIShenBingRebuildView:RspConfirmShenBingRebuild(msg_obj)
    if msg_obj.confirm == 1 or msg_obj.confirm == 2 then
        for i = #self.m_choiceShenBingItemList, 1, -1 do
            self.m_choiceShenBingItemList[i]:SetOnSelectState(false)
            table_remove(self.m_choiceShenBingItemList, i)
        end
        self.m_curShenBingData = ShenBingMgr:GetShenBingDataByIndex(self.m_curShenBingData.m_index)
        self:UpdateShenBingInfo()
        self:UpdateChoiceData()
        self:UpdateShenBingItemList(false)
    end
end

function UIShenBingRebuildView:RspShenBingRebuild()
    self:ShowEffect()

    self.m_canClose = false

    coroutine.start(function()
        local data = ShenBingMgr:GetShenBingDataByIndex(self.m_curShenBingData.m_index)
        coroutine.waitforseconds(2)
        UIManagerInst:OpenWindow(UIWindowNames.UIShenBingMingWenRandShow, data)
        coroutine.waitforseconds(2.7)
        UIManagerInst:OpenWindow(UIWindowNames.UIShenBingRebuildSuccess, data)
        coroutine.waitforseconds(1)
        self.m_canClose = true
    end)

    for i = #self.m_choiceShenBingItemList, 1, -1 do
        self.m_choiceShenBingItemList[i]:SetOnSelectState(false)
        table_remove(self.m_choiceShenBingItemList, i)
    end
    self.m_curShenBingData = ShenBingMgr:GetShenBingDataByIndex(self.m_curShenBingData.m_index)
    self:UpdateShenBingInfo()
    self:UpdateChoiceData()
    self:UpdateShenBingItemList(false)
end

function UIShenBingRebuildView:OnClick(go)
    if go.name == "SortBtn" then
        for i = #self.m_choiceShenBingItemList, 1, -1 do
            table_remove(self.m_choiceShenBingItemList)
        end
        self:UpdateChoiceData()
        self.m_sortPriority = self.m_sortPriority + 1
        if self.m_sortPriority > CommonDefine.SHENBING_ALLSORT then
            self.m_sortPriority = CommonDefine.SHENBING_OENPERSONSORT
        end
        self:UpdateShenBingItemList(true)
    elseif  go.name == "LevelSortBtn" then
        for i = #self.m_choiceShenBingItemList, 1, -1 do
            table_remove(self.m_choiceShenBingItemList)
        end
        self:UpdateChoiceData()
        self.m_levelSortPriority = self.m_levelSortPriority + 1
        if self.m_levelSortPriority > CommonDefine.SHENBING_LEVEL_UP then
            self.m_levelSortPriority = CommonDefine.SHENBING_LEVEL_DOWN
        end
        self:UpdateShenBingItemList(true)
    elseif go.name == "RebuildBtn" then
        if #self.m_choiceShenBingItemList <= 0 then
            UILogicUtil.FloatAlert(Language.GetString(2935))
        else
            local indexList = {}
            for i, v in pairs(self.m_choiceShenBingItemList) do
                table_insert(indexList, v:GetIndex())
            end
            UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(2907), Language.GetString(2924),
                Language.GetString(10), Bind(WuJiangMgr, WuJiangMgr.ReqShenBingRebuild, indexList, self.m_curShenBingData.m_index),
                Language.GetString(50))
        end

    elseif go.name == "BackBtn" then
        if self.m_canClose then
            self:CloseSelf()
        end
        
    elseif go.name == "ruleButton" then
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 119) 
    end
end

function UIShenBingRebuildView:OnEnable(...)
    base.OnEnable(self, ...)

    self.m_canClose = true

    local _, shenbingData, wujiangIndex, wujiangId = ...
    self:ShowDoTween()
    self:CreateRoleContainer()

    self.m_wujiangId = wujiangId or self.m_wujiangId
    self.m_wujiangIndex = wujiangIndex or self.m_wujiangIndex
    if shenbingData then
        self.m_curShenBingData = shenbingData
    end
    self.m_sortPriority = CommonDefine.SHENBING_ALLSORT
    self.m_levelSortPriority = ShenBingMgr.CurLevelSortPriority
    self.m_coinsCountText.text = 0

    self:UpdateShenBingItemList(false)
    self:ShowShenBingModel(self.m_curShenBingData.m_id, self.m_curShenBingData.m_stage)
    self:UpdateShenBingInfo()
    self:UpdateChoiceData()
end

function UIShenBingRebuildView:ShowShenBingModel(shenbingId, stage)
    local pool = GameObjectPoolInst
    for _, v in ipairs(self.m_shenbingModels) do        
        pool:RecycleGameObject(v.path, v.go)
    end
    self.m_shenbingModels = {}

    local shenbingCfg = ConfigUtil.GetShenbingCfgByID(shenbingId)
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(shenbingCfg.wujiang_id)
    if not shenbingCfg then
        Logger.LogError('no shenbing cfg ', shenbingID)
        return
    end

    local resPath2, resPath3, exPath = PreloadHelper.GetWeaponPath(shenbingCfg.wujiang_id, stage)

    if shenbingCfg.wujiang_id == 1038 then
        pool:GetGameObjectAsync(exPath, function(inst)
            if IsNull(inst) then
                pool:RecycleGameObject(exPath, inst)
                return
            end

            inst.transform:SetParent(self.m_shenbingModelTr)
            inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
            inst.transform.localPosition = Vector3.New(shenbingCfg.pos_right[1][1], shenbingCfg.pos_right[1][2], shenbingCfg.pos_right[1][3])
            inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_right[1][1],shenbingCfg.rotation_right[1][2],shenbingCfg.rotation_right[1][3])
            
            GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
            table_insert(self.m_shenbingModels, {path = exPath, go = inst})
        end)

    else
        if wujiangCfg.rightWeaponPath ~= "" then
            pool:GetGameObjectAsync(resPath2, function(inst)
                if IsNull(inst) then
                    pool:RecycleGameObject(resPath2, inst)
                    return
                end

                inst.transform:SetParent(self.m_shenbingModelTr)
                inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
                inst.transform.localPosition = Vector3.New(shenbingCfg.pos_right[1][1], shenbingCfg.pos_right[1][2], shenbingCfg.pos_right[1][3])
                inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_right[1][1],shenbingCfg.rotation_right[1][2],shenbingCfg.rotation_right[1][3])
                
                
                GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
                table_insert(self.m_shenbingModels, {path = resPath2, go = inst})
            end)
        end

        if wujiangCfg.leftWeaponPath ~= "" then
            pool:GetGameObjectAsync(resPath3, function(inst)
                if IsNull(inst) then
                    pool:RecycleGameObject(resPath3, inst)
                    return
                end

                inst.transform:SetParent(self.m_shenbingModelTr)
                inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
                inst.transform.localPosition = Vector3.New(shenbingCfg.pos_left[1][1], shenbingCfg.pos_left[1][2], shenbingCfg.pos_left[1][3])
                inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_left[1][1],shenbingCfg.rotation_left[1][2],shenbingCfg.rotation_left[1][3])
                
                GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
                table_insert(self.m_shenbingModels, {path = resPath3, go = inst})
            end)
        end
    end
end

function UIShenBingRebuildView:Update()
    for _, item in ipairs(self.m_shenbingModels) do
        if item and self.m_curShenBingData and self.m_shenbingModelTr then
            local shenbingCfg = ConfigUtil.GetShenbingCfgByID(self.m_curShenBingData.m_id)
            if shenbingCfg.turn_around == 1 then
                item.go.transform:Rotate(Vector3.forward * Time.deltaTime * 100)
            end
            item.go.transform:RotateAround(self.m_shenbingModelTr.position, Vector3.up, Time.deltaTime * 50)
        end
    end
end

function UIShenBingRebuildView:CreateRoleContainer()
    self.m_sceneSeq = UIGameObjectLoader:PrepareOneSeq()
    UIGameObjectLoader:GetGameObject(self.m_sceneSeq, ShenBingObjPath, function(go)
        self.m_sceneSeq = 0
        if not IsNull(go) then
            self.m_shenbingObjGo = go
            self.m_shenbingModelTr = self.m_shenbingObjGo.transform:GetChild(0)
            self.m_shenbingObjGo.transform:GetChild(1).gameObject:SetActive(false)
            local pos = self.m_shenbingModelTr.localPosition
            self.m_shenbingModelTr.localPosition = Vector3.New(0.35, pos.y, pos.z)
        end
    end)
    
end

function UIShenBingRebuildView:DestroyRoleContainer()

    UIGameObjectLoader:CancelLoad(self.m_sceneSeq)
    self.m_sceneSeq = 0
    self.m_shenbingModelTr= nil

    if not IsNull(self.m_shenbingObjGo) then
        UIGameObjectLoader:RecycleGameObject(ShenBingObjPath, self.m_shenbingObjGo)
        self.m_shenbingObjGo = nil
    end

end

function UIShenBingRebuildView:GetStageByLevel(level)
    local stage = 0
    if level < 5 then
        stage = CommonDefine.ItemStageType_1
    elseif level >= 5 and level < 10 then
        stage = CommonDefine.ItemStageType_2
    elseif level >= 10 and level < 15 then
        stage = CommonDefine.ItemStageType_3
    elseif level == 15 then
        stage = CommonDefine.ItemStageType_4
    end
    return stage
end

function UIShenBingRebuildView:UpdateShenBingInfo()
    local curData = self.m_curShenBingData
    if not curData then
        return
    end
    local curShenBingCfg = ConfigUtil.GetShenbingCfgByID(curData.m_id)
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(curShenBingCfg.wujiang_id)
    if wujiangCfg then
        if wujiangCfg.rare == CommonDefine.WuJiangRareType_3 then
            self.m_inscriptionItemThreeGo:SetActive(false)
        elseif wujiangCfg.rare == CommonDefine.WuJiangRareType_4 then
            self.m_inscriptionItemThreeGo:SetActive(true)
        end
    end

    local shenbingCfgList = ConfigUtil.GetShenbingCfgList()
    local itemCfg = ConfigUtil.GetItemCfgByID(curData.m_id)
    local stage = self:GetStageByLevel(curData.m_stage)
    if not self.m_curShenBingInfoItem and self.m_infoSeq == 0 then
        self.m_infoSeq = UIGameObjectLoader:PrepareOneSeq()
        UIGameObjectLoader:GetGameObject(self.m_infoSeq, bagItemPath, function(go)
            self.m_infoSeq = 0
            if not IsNull(go) then
                self.m_curShenBingInfoItem = bagItem.New(go, self.m_curShenBingParent, bagItemPath)
                self.m_curShenBingInfoItem:SetAnchoredPosition(Vector3.zero)
                local itemIconParam = ItemIconParam.New(itemCfg, 1, stage, curData.m_index, nil, false, false, false,
                false, false, curData.m_stage, false)
                self.m_curShenBingInfoItem:UpdateData(itemIconParam)
            end
        end)
    else
        local itemIconParam = ItemIconParam.New(itemCfg, 1, stage, curData.m_index, nil, false, false, false,
        false, false, curData.m_stage, false)
        self.m_curShenBingInfoItem:UpdateData(itemIconParam)
    end
    
    for i, v in pairs(shenbingCfgList) do
        if v.id == curData.m_id then
            self.m_shenbingInfoText.text = UILogicUtil.GetShenBingNameByStage(curData.m_stage, v)
            self.m_shenbingMasterText.text = string_format("%s专属", v.wujiang_name)
            if curData.m_stage > 0 then
                self.m_shenbingStageText.text = string_format("+%d", curData.m_stage)
            else
                self.m_shenbingStageText.text = ""
            end
        end
    end

    local attrList = curData.m_attr_list
    if attrList then
        local index = 1
        local attrNameList = CommonDefine.mingwen_second_attr_name_list
        for i, v in ipairs(attrNameList) do
            local val = attrList[v]
            if val and val > 0 then
                local attrType = CommonDefine[v]
                if attrType then
                    self.m_attrTextList[index].text = Language.GetString(attrType + 10)..string_format("<color=#17f100>+%d</color>", val)
                    index = index + 1
                end
            end
        end
    end

    local mingwenList = curData.m_mingwen_list
    for i, v in ipairs(mingwenList) do
        self:UpdateInscription(i, v.mingwen_id, v.wash_times)
    end

    for k, v in ipairs(self.m_insAttrTextList) do
        if k > #mingwenList then
            v.text = string_format(Language.GetString(2914), k * 5)
            self.m_insNameTextList[k].text = ''
            self.m_insImgList[k]:SetAtlasSprite("default.png", false, ImageConfig.MingWen)
        end
    end

end

function UIShenBingRebuildView:UpdateInscription(i, mingwenId, washCount)
    if mingwenId and mingwenId > 0 then
        local mingwenCfg = ConfigUtil.GetShenbingInscriptionCfgByID(mingwenId)
        if mingwenCfg then
            local quality = mingwenCfg.quality
            local attrStr = ""
            local nameList = CommonDefine.mingwen_second_attr_name_list
            for _, name in ipairs(nameList) do
                local hasPercent = true
                local val = mingwenCfg[name]
                if val and val > 0 then
                    if name == "init_nuqi" then
                        hasPercent = false
                    end
                    local attrType = CommonDefine[name]
                    if attrType then
                        local tempStr = nil
                        if hasPercent then
                            tempStr = Language.GetString(2910)
                            if i == 2 then
                                tempStr = Language.GetString(2911)
                            elseif i == 3 then
                                tempStr = Language.GetString(2912)
                            end
                        else
                            tempStr = Language.GetString(2942)
                            if i == 2 then
                                tempStr = Language.GetString(2943)
                            elseif i == 3 then
                                tempStr = Language.GetString(2944)
                            end
                        end
                        attrStr = attrStr..string_format(tempStr, Language.GetString(attrType + 10), val)
                    end
                end
            end
            
            attrStr = attrStr..string_format(Language.GetString(2913), washCount)
            self.m_insAttrTextList[i].text = attrStr
            self.m_insNameTextList[i].text = mingwenCfg.name
        end
        self.m_insImgList[i]:SetAtlasSprite(math_ceil(mingwenId)..".png", false, ImageConfig.MingWen)
    else
        self.m_insAttrTextList[i].text = ''
        self.m_insNameTextList[i].text = ''
        self.m_insImgList[i]:SetAtlasSprite("default.png", false, ImageConfig.MingWen)
    end
end

function UIShenBingRebuildView:UpdateShenBingItemList(reset)
    self:GetSortShenBingList()

    self.m_shenbingCountText.text = string_format(Language.GetString(2903), #self.m_shenbingList) 
    if #self.m_shenbingItemList == 0 and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoader:PrepareOneSeq()
        UIGameObjectLoader:GetGameObjects(self.m_seq, bagItemPath, 27, function(objs)
            self.m_seq = 0
            if objs then
                for i = 1, #objs do
                    local shenbingItem = bagItem.New(objs[i], self.m_scrollViewTr, bagItemPath)
                    table_insert(self.m_shenbingItemList, shenbingItem)
                end
            end
            self.m_scrollView:UpdateView(true, self.m_shenbingItemList, self.m_shenbingList)
        end)
    else
        self.m_scrollView:UpdateView(reset, self.m_shenbingItemList, self.m_shenbingList)
    end

    if self.m_sortPriority <= #self.m_sortPriorityTexts then
        self.m_sortBtnText.text = self.m_sortPriorityTexts[self.m_sortPriority]
    end

    if self.m_levelSortPriority <= #self.m_levelSortPriorityTexts then
        self.m_levelSortBtnText.text = self.m_levelSortPriorityTexts[self.m_levelSortPriority]
    end
end

function UIShenBingRebuildView:GetSortShenBingList()
    self.m_shenbingList = ShenBingMgr:GetShenBingList(self.m_levelSortPriority, -1, function(data)
        local shenbingCfg = ConfigUtil.GetShenbingCfgByID(data.m_id)
        if (shenbingCfg and shenbingCfg.wujiang_id == self.m_wujiangId or self.m_sortPriority == CommonDefine.SHENBING_ALLSORT) and data.m_index ~= self.m_curShenBingData.m_index and data.m_equiped_wujiang_index == 0 then
            return true
        end
    end)
end

function UIShenBingRebuildView:UpdataShenBingList(item, realIndex)
    if self.m_shenbingList then
        if item and realIndex > 0 and realIndex <= #self.m_shenbingList then
            local data = self.m_shenbingList[realIndex]
            local itemCfg = ConfigUtil.GetItemCfgByID(data.m_id)
            local stage = 0
            if data.m_stage < 5 then
                stage = CommonDefine.ItemStageType_1
            elseif data.m_stage >= 5 and data.m_stage < 10 then
                stage = CommonDefine.ItemStageType_2
            elseif data.m_stage >= 10 and data.m_stage < 15 then
                stage = CommonDefine.ItemStageType_3
            elseif data.m_stage == 15 then
                stage = CommonDefine.ItemStageType_4
            end

            local isLock = data:GetLockState()
            local itemIconParam = ItemIconParam.New(itemCfg, 1, stage, data.m_index, Bind(self, self.ItemClick), true, false, isLock,
                false, false, data.m_stage, data.m_equiped_wujiang_index == self.m_wujiangIndex)
            item:UpdateData(itemIconParam)
        end
    end
end

function UIShenBingRebuildView:ItemClick(item)
    if not item then
        return
    end

    if item:GetLockState() then
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(704), Language.GetString(705), 
            Language.GetString(10), 
            function() 
                ItemMgr:ReqLock(item:GetItemID(), false, CommonDefine.ItemMainType_ShenBing, item:GetIndex()) 
            end
            , Language.GetString(5))
        return
    end
    
    if not item:IsOnSelected() then
        if #self.m_choiceShenBingItemList < 3 then
            if item:GetStageText() > self.m_curShenBingData.m_stage then
                UILogicUtil.FloatAlert(Language.GetString(2921))
                return
            elseif item:GetStageText() < 5 then
                UILogicUtil.FloatAlert(Language.GetString(2923))
                return
            else
                item:SetOnSelectState(true)
                table_insert(self.m_choiceShenBingItemList, item)
            end
        end
    else
        local index = 0
        for i, v in ipairs(self.m_choiceShenBingItemList) do
            if item == v then
                index = i
                break
            end
        end
        table_remove(self.m_choiceShenBingItemList, index)
        item:SetOnSelectState(false)
    end
    self:UpdateChoiceData()
end

function UIShenBingRebuildView:ChoiceItemClick(item)
    if not item then
        return
    end
    local index = 0
    for i, v in ipairs(self.m_choiceShenBingItemList) do
        if item:GetIndex() == v:GetIndex() then
            v:SetOnSelectState(false)
            index = i
            break
        end
    end
    table_remove(self.m_choiceShenBingItemList, index)
    self:UpdateChoiceData()
end

function UIShenBingRebuildView:UpdateChoiceData()
    self.m_insOneRandomGo:SetActive(false)
    self.m_insTwoRandomGo:SetActive(false)
    self.m_insThreeRandomGo:SetActive(false)
    local mingwenList = self.m_curShenBingData.m_mingwen_list
    for i, v in ipairs(mingwenList) do
        self:UpdateInscription(i, v.mingwen_id, v.wash_times)
    end
    local gameSetting = UserMgr:GetSettingData()
    local coinsCount = 0
    local attrCount1 = 0
    local attrCount2 = 0
    local attrCount3 = 0
    for i, v in ipairs(self.m_choiceShenBingItemList) do
        if v then
            local item = self.m_choiceShenBingPrefabList[i]
            local itemCfg = ConfigUtil.GetItemCfgByID(v:GetItemID())
            if not item and self.m_choiceSeq == 0 then
                self.m_choiceSeq  = UIGameObjectLoader:PrepareOneSeq()
                UIGameObjectLoader:GetGameObject(self.m_choiceSeq, bagItemPath, function(objs)
                    self.m_choiceSeq = 0
                    if objs then
                        item = bagItem.New(objs, self.m_choiceItemParentList[i], bagItemPath)
                        item:SetAnchoredPosition(Vector3.zero)
                        table_insert(self.m_choiceShenBingPrefabList, item)
                        local itemIconParam = ItemIconParam.New(itemCfg, 1, v:GetStage(), v:GetIndex(), Bind(self, self.ChoiceItemClick), false, false, false,
                        false, false, v:GetStageText(), false)
                        item:UpdateData(itemIconParam)
                    end
                end)
            else
                local itemIconParam = ItemIconParam.New(itemCfg, 1, v:GetStage(), v:GetIndex(), Bind(self, self.ChoiceItemClick), false, false, false,
                false, false, v:GetStageText(), false)
                item:UpdateData(itemIconParam)
            end
            
            local choiceData = ShenBingMgr:GetShenBingDataByIndex(v:GetIndex())
            if v:GetStageText() >= 5 and v:GetStageText() < 10 then
                coinsCount = coinsCount + gameSetting.rebuild_shenbing_cost_1
                self.m_insOneRandomGo:SetActive(true)
                attrCount1 = attrCount1 + choiceData.m_mingwen_list[1].wash_times + 1
                self.m_insAttrTextList[1].text = Language.GetString(2922)..string_format(Language.GetString(2913), self.m_curShenBingData.m_mingwen_list[1].wash_times + attrCount1)
            elseif v:GetStageText() >= 10 and v:GetStageText() < 15 then
                coinsCount = coinsCount + gameSetting.rebuild_shenbing_cost_2
                self.m_insTwoRandomGo:SetActive(true)
                attrCount2 = attrCount2 + choiceData.m_mingwen_list[2].wash_times + 1
                self.m_insAttrTextList[2].text = Language.GetString(2922)..string_format(Language.GetString(2913), self.m_curShenBingData.m_mingwen_list[2].wash_times + attrCount2)
            elseif v:GetStageText() == 15 then
                coinsCount = coinsCount + gameSetting.rebuild_shenbing_cost_3
                self.m_insThreeRandomGo:SetActive(true)
                attrCount3 = attrCount3 + choiceData.m_mingwen_list[3].wash_times + 1
                self.m_insAttrTextList[3].text = Language.GetString(2922)..string_format(Language.GetString(2913), self.m_curShenBingData.m_mingwen_list[3].wash_times + attrCount3)
            end
        end
    end

    for i, v in ipairs(self.m_choiceItemParentList) do
        if i > #self.m_choiceShenBingItemList then
            v.gameObject:SetActive(false)
        else
            v.gameObject:SetActive(true)
        end
    end

    self.m_coinsCountText.text = math_ceil(coinsCount)
end

function UIShenBingRebuildView:OnLockChg(param)
    for _, v in pairs(self.m_shenbingItemList) do
        if param.item_id == v:GetItemID() and param.index == v:GetIndex() then
            local isLocked = param.lock == 1
            v:SetLockState(isLocked)
            break
        end
    end
end

function UIShenBingRebuildView:OnDestroy()
    self:RemoveClick()
    base.OnDestroy(self)
end

function UIShenBingRebuildView:OnDisable()

    for i = 1, #self.m_effectList do 
        if not IsNull(self.m_effectList[i]) then
            GameObjectPoolInst:RecycleGameObject(effectPath, self.m_effectList[i])
        end
    end
    self.m_effectList = {}

    UIGameObjectLoader:CancelLoad(self.m_seq)
    self.m_seq = 0
    UIGameObjectLoader:CancelLoad(self.m_infoSeq)
    self.m_infoSeq = 0
    UIGameObjectLoader:CancelLoad(self.m_choiceSeq)
    self.m_choiceSeq = 0

    local pool = GameObjectPoolInst
    for _, v in ipairs(self.m_shenbingModels) do        
        pool:RecycleGameObject(v.path, v.go)
    end
    self.m_shenbingModels = {}
    for _, v in pairs(self.m_shenbingItemList) do
        v:Delete()
    end
    self.m_shenbingItemList = {}
    self.m_choiceShenBingItemList = {}
    for _, v in pairs(self.m_choiceShenBingPrefabList) do
        if v then
            v:Delete()
        end
    end
    self.m_choiceShenBingPrefabList = {}
    if self.m_curShenBingInfoItem then
        self.m_curShenBingInfoItem:Delete()
    end
    self.m_curShenBingInfoItem = false
    self.m_curShenBingData = false
    self.m_shenbingList = nil
    self.m_wujiangIndex = -1
    
    UIUtil.LoopMoveLocalX(self.m_LeftContainerTr, 800, 232, 0.4, false)
    self:HideDotween()
    self:DestroyRoleContainer()
    ShenBingMgr.CurLevelSortPriority = self.m_levelSortPriority
    base.OnDisable(self)
end

local OffsetPos = Vector3.New(0, -0.9, 0) 

function UIShenBingRebuildView:ShowEffect()
    if not self.m_shenbingModels or #self.m_shenbingModels == 0 then
        return
    end

    if #self.m_effectList > 0 then
        for i = 1, #self.m_effectList do 
            if not IsNull(self.m_effectList[i]) then
                GameUtility.PlayEffectGo(self.m_effectList[i])
            end
        end
        return
    end

    GameObjectPoolInst:GetGameObjectAsync(effectPath,
        function(go)
            if IsNull(go) then
                return
            end

            local isCancel = not self.m_shenbingModels or #self.m_shenbingModels == 0

            if isCancel then
                GameObjectPoolInst:RecycleGameObject(effectPath, go)
            else
                local parent = self.m_shenbingModels[1].go
                if not IsNull(parent) then
                    local parent2 = parent.transform.parent
                    if not IsNull(parent2) then
                        go.transform:SetParent(parent2)
                        go.transform.localPosition = OffsetPos
                        go.transform.localScale = Vector3.one 
                        GameUtility.SetLayer(go, Layers.IGNORE_RAYCAST)
                    end
                end

                table_insert(self.m_effectList, go)
            end
        end)
end


return UIShenBingRebuildView