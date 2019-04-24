
local math_ceil = math.ceil
local string_format = string.format
local table_insert = table.insert

local ShenBingMgr = Player:GetInstance():GetShenBingMgr()
local WuJiangMgr = Player:GetInstance():GetWujiangMgr()
local ItemMgr = Player:GetInstance():GetItemMgr()
local UIGameObjectLoader = UIGameObjectLoader:GetInstance()
local bagItem = require "UI.UIBag.View.BagItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local ShenBingObjPath = "UI/Prefabs/Shenbing/ShenBingObj.prefab"
local bagItemPath = TheGameIds.CommonBagItemPrefab
local GameUtility = CS.GameUtility
local Language = Language
local UIUtil = UIUtil
local ConfigUtil = ConfigUtil
local CommonDefine = CommonDefine
local ItemDefine = ItemDefine
local UILogicUtil = UILogicUtil
local AtlasConfig = AtlasConfig
local Vector3 = Vector3
local DOTweenSettings = CS.DOTween.DOTweenSettings

local effectPath = TheGameIds.shenbing_qianghua_fx_path

local UIShenBingImproveView = BaseClass("UIShenBingImproveView", UIBaseView)
local base = UIBaseView

function UIShenBingImproveView:OnCreate()
    base.OnCreate(self)
    self:InitView()
end

function UIShenBingImproveView:InitView()
    local AttrOneText, AttrTwoText, AttrThreeText, UpAttrOneText, UpAttrTwoText,
    UpAttrThreeText, InsOneName, InsTwoName, InsThreeName, InsOneAttrText, InsTwoAttrText,
    InsThreeAttrText, improveBtnText, InsOneImg, InsTwoImg, InsThreeImg, matOneImg, matTwoImg,
    matThreeImg, levelLimitText, matOneItemParent, matTwoItemParent, matThreeItemParent

    self.m_shenbingInfoText, self.m_shenbingStageText, self.m_shenbingUpInfoText, self.m_shenbingUpStageText, AttrOneText, AttrTwoText, AttrThreeText, UpAttrOneText,
    UpAttrTwoText, UpAttrThreeText, InsOneName, InsTwoName, InsThreeName, InsOneAttrText, InsTwoAttrText, InsThreeAttrText,
    improveBtnText, self.m_coinsCountText, levelLimitText = UIUtil.GetChildTexts(self.transform, {
        "RightContainer/ShenBingInfo/bg/CurShenBing/Info/InfoText",
        "RightContainer/ShenBingInfo/bg/CurShenBing/Info/StageText",
        "RightContainer/ShenBingInfo/bg/NextLevelShenBing/NextInfo/NextInfoText",
        "RightContainer/ShenBingInfo/bg/NextLevelShenBing/NextInfo/NextStageText",
        "RightContainer/ShenBingInfo/bg/TextGrid/AttributeTextOne",
        "RightContainer/ShenBingInfo/bg/TextGrid/AttributeTextTwo",
        "RightContainer/ShenBingInfo/bg/TextGrid/AttributeTextThree",
        "RightContainer/ShenBingInfo/bg/UpTextGrid/UpTextOne",
        "RightContainer/ShenBingInfo/bg/UpTextGrid/UpTextTwo",
        "RightContainer/ShenBingInfo/bg/UpTextGrid/UpTextThree",
        "RightContainer/Inscription/InscriptionItemOne/InscriptionImg/InscriptionName",
        "RightContainer/Inscription/InscriptionItemTwo/InscriptionImg/InscriptionName",
        "RightContainer/Inscription/InscriptionItemThree/InscriptionImg/InscriptionName",
        "RightContainer/Inscription/InscriptionItemOne/bg/attributeText",
        "RightContainer/Inscription/InscriptionItemTwo/bg/attributeText",
        "RightContainer/Inscription/InscriptionItemThree/bg/attributeText",
        "MiddleContainer/ImproveBtn/Text",
        "MiddleContainer/expend/Text",
        "RightContainer/ShenBingInfo/bg/LevelLimit"
    })

    self.m_improveBtn, self.m_backBtn, self.m_shenbingUpInfoGo, self.m_shenbingUpAttrGo,
    self.m_middleContainerGo, self.m_rightContainerGo, self.m_levelLimitGo, self.m_arrowGo, self.m_curShenBingInfoTr,
    self.m_nextShenBingInfoTr, matOneItemParent, matTwoItemParent, matThreeItemParent, self.m_inscriptionItemThreeTr  = UIUtil.GetChildTransforms(self.transform, {
        "MiddleContainer/ImproveBtn",
        "Panel/backBtn",
        "RightContainer/ShenBingInfo/bg/NextLevelShenBing",
        "RightContainer/ShenBingInfo/bg/UpTextGrid",
        "MiddleContainer",
        "RightContainer",
        "RightContainer/ShenBingInfo/bg/LevelLimit",
        "arrow",
        "RightContainer/ShenBingInfo/bg/CurShenBing",
        "RightContainer/ShenBingInfo/bg/NextLevelShenBing",
        "MiddleContainer/Grid/materialOne/itemParent",
        "MiddleContainer/Grid/materialTwo/itemParent",
        "MiddleContainer/Grid/materialThree/itemParent",
        "RightContainer/Inscription/InscriptionItemThree",
    })
    self.m_inscriptionItemThreeGo = self.m_inscriptionItemThreeTr.gameObject
    self.m_shenbingUpInfoGo = self.m_shenbingUpInfoGo.gameObject
    self.m_shenbingUpAttrGo = self.m_shenbingUpAttrGo.gameObject
    self.m_middleContainerGo = self.m_middleContainerGo.gameObject
    self.m_rightContainerGo = self.m_rightContainerGo.gameObject
    self.m_levelLimitGo = self.m_levelLimitGo.gameObject
    self.m_improveBtn = self.m_improveBtn.gameObject
    self.m_backBtn = self.m_backBtn.gameObject
    self.m_arrowGo = self.m_arrowGo.gameObject

    InsOneImg = UIUtil.AddComponent(UIImage, self, "RightContainer/Inscription/InscriptionItemOne/InscriptionImg")
    InsTwoImg = UIUtil.AddComponent(UIImage, self, "RightContainer/Inscription/InscriptionItemTwo/InscriptionImg")
    InsThreeImg = UIUtil.AddComponent(UIImage, self, "RightContainer/Inscription/InscriptionItemThree/InscriptionImg")

    levelLimitText.text = Language.GetString(2915)
    improveBtnText.text = Language.GetString(2906)
    self.m_attrTextList = {AttrOneText, AttrTwoText, AttrThreeText}
    self.m_attrUpTextList = {UpAttrOneText, UpAttrTwoText, UpAttrThreeText}
    self.m_insNameTextList = {InsOneName, InsTwoName, InsThreeName}
    self.m_insAttrTextList = {InsOneAttrText, InsTwoAttrText, InsThreeAttrText}
    self.m_insImgList = {InsOneImg, InsTwoImg, InsThreeImg}
    self.m_materialItemParentList = {matOneItemParent, matTwoItemParent, matThreeItemParent}

    self.m_infoSeq = 0
    self.m_nextInfoSeq = 0
    self.m_materialSeq = 0
    self.m_shenbingModels = {}
    self.m_shenbingModelsTwo = {}
    self.m_shenbingIndex = 0
    self.m_materialPrefabList = {}
    self.m_curShenBingInfoItem = false
    self.m_nextShenBingInfoItem = false
    self.m_effectList = {}
    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_improveBtn, onClick)
    UIUtil.AddClickEvent(self.m_backBtn, onClick)
end

function UIShenBingImproveView:OnClick(go)
    if go == self.m_improveBtn then
        WuJiangMgr:ReqShenBingImprove(self.m_shenbingData.m_index)
    elseif go == self.m_backBtn then
        self:CloseSelf()
    end
end

function UIShenBingImproveView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_improveBtn)
    UIUtil.RemoveClickEvent(self.m_backBtn)
    base.OnDestroy(self)
end

function UIShenBingImproveView:OnAddListener()
    base.OnAddListener()

    self:AddUIListener(UIMessageNames.MN_WUJIANG_RSP_SHENBING_IMPROVE_STAGE, self.RspShenBingIprove)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange)
end

function UIShenBingImproveView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_RSP_SHENBING_IMPROVE_STAGE, self.RspShenBingIprove)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange)
    base.OnRemoveListener()
end

function UIShenBingImproveView:PowerChange(power)
    UILogicUtil.PowerChange(power)
end

function UIShenBingImproveView:RspShenBingIprove()
    self.m_shenbingData = ShenBingMgr:GetShenBingDataByIndex(self.m_shenbingIndex)

    self.m_canShowEffect = true

    self:UpdateData()

    coroutine.start(function()
        coroutine.waitforseconds(0.5)
        UIManagerInst:OpenWindow(UIWindowNames.UIShenBingStageUp, self.m_shenbingIndex)
    end)
end

function UIShenBingImproveView:ShowDotween()
    local tweener = UIUtil.LoopMoveLocalY(self.m_middleContainerGo.transform, 0, 420, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_rightContainerGo.transform, -350, -800, 0.4, false)

    DOTweenSettings.OnComplete(tweener, function()
        TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.TWEEN_END, "ShowDoTween")
    end)
end

function UIShenBingImproveView:HideDotween()
    UIUtil.LoopMoveLocalY(self.m_middleContainerGo.transform, 420, 0, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_rightContainerGo.transform, -800, -350, 0.4, false)
end

function UIShenBingImproveView:OnEnable(...)
    base.OnEnable(self, ...)
    local _, shenbingIndex = ...
    self:ShowDotween()
    self:CreateRoleContainer()
    
    self.m_shenbingIndex = shenbingIndex or self.m_shenbingIndex
    self.m_shenbingData = ShenBingMgr:GetShenBingDataByIndex(shenbingIndex)
    self:UpdateData()

    TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
end

function UIShenBingImproveView:UpdateData()
    if self.m_shenbingData then
        local curData = self.m_shenbingData
        local curShenBingCfg = ConfigUtil.GetShenbingCfgByID(curData.m_id)
        local wujiangCfg = ConfigUtil.GetWujiangCfgByID(curShenBingCfg.wujiang_id)
        local shenbingCfgList = ConfigUtil.GetShenbingCfgList()
        local shenbingImproveCfg = ConfigUtil.GetShenbingImproverCfgByID(wujiangCfg.nTypeJob * 100 + curData.m_stage)

        if wujiangCfg.rare == CommonDefine.WuJiangRareType_3 then
            self.m_inscriptionItemThreeGo:SetActive(false)
        elseif wujiangCfg.rare == CommonDefine.WuJiangRareType_4 then
            self.m_inscriptionItemThreeGo:SetActive(true)
        end
        local levelLimit = (wujiangCfg.rare - 1) * 5
        local active = curData.m_stage == levelLimit
        self.m_shenbingUpInfoGo:SetActive(not active)
        self.m_shenbingUpAttrGo:SetActive(not active)
        self.m_middleContainerGo:SetActive(not active)
        if self.m_shenbingModelTwoTr then
            self.m_shenbingModelTwoTr.gameObject:SetActive(not active)
        end
        self.m_arrowGo:SetActive(not active)
        self.m_levelLimitGo:SetActive(active)
        if curData.m_stage == levelLimit and self.m_shenbingModelOneTr then
            local pos = self.m_shenbingModelOneTr.localPosition
            self.m_shenbingModelOneTr.localPosition = Vector3.New(0.35, pos.y, pos.z)
        else
            local pos = self.m_shenbingModelOneTr.localPosition
            self.m_shenbingModelOneTr.localPosition = Vector3.New(2.26, pos.y, pos.z)
        end
        

        self:ShowShenBingModel(curData.m_id, curData.m_stage)
        
        --左属性

        local itemCfg = ConfigUtil.GetItemCfgByID(curData.m_id)
        local stage = self:GetStageByLevel(curData.m_stage)
        if not self.m_curShenBingInfoItem and self.m_infoSeq == 0 then
            self.m_infoSeq = UIGameObjectLoader:PrepareOneSeq()
            UIGameObjectLoader:GetGameObject(self.m_infoSeq, bagItemPath, function(go)
                self.m_infoSeq = 0
                if not IsNull(go) then
                    self.m_curShenBingInfoItem = bagItem.New(go, self.m_curShenBingInfoTr, bagItemPath)
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
        
        if shenbingCfgList then
            for i, v in pairs(shenbingCfgList) do
                if v.id == curData.m_id then
                    self.m_shenbingInfoText.text = UILogicUtil.GetShenBingNameByStage(curData.m_stage, v)
                    if curData.m_stage > 0 then
                        self.m_shenbingStageText.text = string_format("+%d", curData.m_stage)
                    else
                        self.m_shenbingStageText.text = ""
                    end
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
        --右属性
        if curData.m_stage < levelLimit then
            local shenbingNextImproveCfg = ConfigUtil.GetShenbingImproverCfgByID(wujiangCfg.nTypeJob * 100 + curData.m_stage + 1)
            local nextStage = self:GetStageByLevel(curData.m_stage + 1)
            if not self.m_nextShenBingInfoItem and self.m_nextInfoSeq == 0 then
                self.m_nextInfoSeq = UIGameObjectLoader:PrepareOneSeq()
                UIGameObjectLoader:GetGameObject(self.m_nextInfoSeq, bagItemPath, function(go)
                    self.m_nextInfoSeq = 0
                    if not IsNull(go) then
                        self.m_nextShenBingInfoItem = bagItem.New(go, self.m_nextShenBingInfoTr, bagItemPath)
                        self.m_nextShenBingInfoItem:SetAnchoredPosition(Vector3.zero)
                        local itemIconParam = ItemIconParam.New(itemCfg, 1, stage, curData.m_index, nil, false, false, false,
                            false, false, curData.m_stage + 1, false)
                        self.m_nextShenBingInfoItem:UpdateData(itemIconParam)
                    end
                end)
            else
                local itemIconParam = ItemIconParam.New(itemCfg, 1, nextStage, curData.m_index, nil, false, false, false,
                    false, false, curData.m_stage + 1, false)
                self.m_nextShenBingInfoItem:UpdateData(itemIconParam)
            end

            if shenbingCfgList then
                for i, v in pairs(shenbingCfgList) do
                    if v.id == curData.m_id then
                        self.m_shenbingUpInfoText.text = UILogicUtil.GetShenBingNameByStage(curData.m_stage + 1, v)
                        if curData.m_stage + 1 > 0 then
                            self.m_shenbingUpStageText.text = string_format("+%d", curData.m_stage + 1)
                        end
                    end
                end
            end

            if attrList and shenbingNextImproveCfg then
                local index = 1
                local attrNameList = CommonDefine.mingwen_second_attr_name_list
                for i, v in ipairs(attrNameList) do
                    local val = attrList[v]
                    if val and val > 0 then
                        local val2 = shenbingNextImproveCfg[v]
                        if val2 then
                            self.m_attrUpTextList[index].text = string_format("<color=#feb500>+%d</color>", val2)
                            index = index + 1
                        end
                    end
                end
            end
        end

        --铭文
        local mingwenList = curData.m_mingwen_list
        for i, v in ipairs(mingwenList) do
            self:UpdateInscription(i, v.mingwen_id, v.wash_times)
        end

        for i, v in pairs(self.m_insAttrTextList) do
            if i > #mingwenList then
                if (curData.m_stage + 1) == i * 5 then
                    v.text = string_format(Language.GetString(2908), i * 5)
                else
                    v.text = string_format(Language.GetString(2914), i * 5)
                end
                self.m_insNameTextList[i].text = ''
                self.m_insImgList[i]:SetAtlasSprite("default.png", false, ImageConfig.MingWen)
            end
        end
        --材料
        if shenbingImproveCfg and curData.m_stage < 15 then
            local matOneHaveCount = ItemMgr:GetItemCountByID(shenbingImproveCfg.item_id2)
            local matTwoHaveCount = ItemMgr:GetItemCountByID(shenbingImproveCfg.item_id3)
            local matThreeHaveCount = ItemMgr:GetItemCountByID(shenbingImproveCfg.item_id4)
            local temp2916 = Language.GetString(2916)
            local temp2917 = Language.GetString(2917)
            local text1, text2, text3
            
            if matOneHaveCount >= shenbingImproveCfg.item_count2 then
                text1 = string_format(temp2917, matOneHaveCount, shenbingImproveCfg.item_count2)
            else
                text1 = string_format(temp2916, matOneHaveCount, shenbingImproveCfg.item_count2)
            end
            if matTwoHaveCount >= shenbingImproveCfg.item_count3 then
                text2 = string_format(temp2917, matTwoHaveCount, shenbingImproveCfg.item_count3)
            else
                text2 = string_format(temp2916, matTwoHaveCount, shenbingImproveCfg.item_count3)
            end
            if matThreeHaveCount >= shenbingImproveCfg.item_count4 then
                text3 = string_format(temp2917, matThreeHaveCount, shenbingImproveCfg.item_count4)
            else
                text3 = string_format(temp2916, matThreeHaveCount, shenbingImproveCfg.item_count4)
            end

            local textList = {text1, text2, text3}
            
            for i, v in ipairs(textList) do
                local item = self.m_materialPrefabList[i]
                local materialCfg
                if i == 1 then
                    materialCfg = ConfigUtil.GetItemCfgByID(shenbingImproveCfg.item_id2)
                elseif i == 2 then
                    materialCfg = ConfigUtil.GetItemCfgByID(shenbingImproveCfg.item_id3)
                elseif i == 3 then
                    materialCfg = ConfigUtil.GetItemCfgByID(shenbingImproveCfg.item_id4)
                end
        
                if not item and self.m_materialSeq == 0 then
                    self.m_materialSeq = UIGameObjectLoader:PrepareOneSeq()
                    UIGameObjectLoader:GetGameObject(self.m_materialSeq, bagItemPath, function(objs)
                        self.m_materialSeq = 0
                        if objs then
                            item = bagItem.New(objs, self.m_materialItemParentList[i], bagItemPath)
                            item:SetAnchoredPosition(Vector3.zero)
                            table_insert(self.m_materialPrefabList, item)
                            local itemIconParam = ItemIconParam.New(materialCfg, 1, materialCfg.nColor, 0, nil, false, false, false,
                            false, false, -1, false, v)
                            itemIconParam.onClickShowDetail = true
                            item:UpdateData(itemIconParam)
                        end
                    end)
                else
                    local itemIconParam = ItemIconParam.New(materialCfg, 1, materialCfg.nColor, 0, nil, false, false, false,
                    false, false, -1, false, v)
                    itemIconParam.onClickShowDetail = true
                    item:UpdateData(itemIconParam)
                end
            end
        
            self.m_coinsCountText.text = shenbingImproveCfg.item_count1
        end

    end
end

function UIShenBingImproveView:CreateRoleContainer()
    self.m_sceneSeq = UIGameObjectLoader:PrepareOneSeq()
    UIGameObjectLoader:GetGameObject(self.m_sceneSeq, ShenBingObjPath, function(go)
        self.m_sceneSeq = 0
        if not IsNull(go) then
            self.m_shenbingObjGo = go
            self.m_shenbingModelOneTr = self.m_shenbingObjGo.transform:GetChild(0)
            self.m_shenbingModelTwoTr = self.m_shenbingObjGo.transform:GetChild(1)
            self.m_shenbingModelTwoTr.gameObject:SetActive(true)
            if self.m_shenbingData and self.m_shenbingData.m_stage == levelLimit then
                local pos = self.m_shenbingModelOneTr.localPosition
                self.m_shenbingModelOneTr.localPosition = Vector3.New(0.35, pos.y, pos.z)
            else
                local pos = self.m_shenbingModelOneTr.localPosition
                self.m_shenbingModelOneTr.localPosition = Vector3.New(2.26, pos.y, pos.z)
            end
        end
    end)
    
end

function UIShenBingImproveView:DestroyRoleContainer()

    UIGameObjectLoader:CancelLoad(self.m_sceneSeq)
    self.m_sceneSeq = 0
    self.m_shenbingModelOneTr = nil
    self.m_shenbingModelTwoTr = nil

    if not IsNull(self.m_shenbingObjGo) then
        UIGameObjectLoader:RecycleGameObject(ShenBingObjPath, self.m_shenbingObjGo)
        self.m_shenbingObjGo = nil
    end

end

function UIShenBingImproveView:GetStageByLevel(level)
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

function UIShenBingImproveView:ShowShenBingModel(shenbingId, stage)
    
    local pool = GameObjectPoolInst
    local shenbingCfg = ConfigUtil.GetShenbingCfgByID(shenbingId)
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(shenbingCfg.wujiang_id)
    if not shenbingCfg then
        Logger.LogError('no shenbing cfg ', shenbingID)
        return
    end
    local leftUpdate, rightUpdate = false, false

    for i, v in ipairs(self.m_shenbingModels) do
        if v.path ~= PreloadHelper.GetWeaponPath(shenbingCfg.wujiang_id, stage) then
            for _, v in ipairs(self.m_shenbingModels) do        
                pool:RecycleGameObject(v.path, v.go)
            end
            self.m_shenbingModels = {}
            for _, v in ipairs(self.m_shenbingModelsTwo) do        
                pool:RecycleGameObject(v.path, v.go)
            end
            self.m_shenbingModelsTwo = {}
        else
            leftUpdate = true
        end
    end

    for i, v in ipairs(self.m_shenbingModelsTwo) do
        if v.path ~= PreloadHelper.GetWeaponPath(shenbingCfg.wujiang_id, stage + 1) then
            for _, v in ipairs(self.m_shenbingModels) do        
                pool:RecycleGameObject(v.path, v.go)
            end
            self.m_shenbingModels = {}
            for _, v in ipairs(self.m_shenbingModelsTwo) do        
                pool:RecycleGameObject(v.path, v.go)
            end
            self.m_shenbingModelsTwo = {}
        else
            rightUpdate = true
        end
    end
    if self.m_shenbingModels == {} then
        leftUpdate = false
    end

    if leftUpdate and rightUpdate then
        self:CheckShowEffect()
        return
    end
    
    local resPath1, resPath2, exPath1 = PreloadHelper.GetWeaponPath(shenbingCfg.wujiang_id, stage)
    local resPath3, resPath4, exPath2 = PreloadHelper.GetWeaponPath(shenbingCfg.wujiang_id, stage + 1)

    if shenbingCfg.wujiang_id == 1038 then
        pool:GetGameObjectAsync(exPath1, function(inst)
            if IsNull(inst) then
                pool:RecycleGameObject(exPath1, inst)
                return
            end

            inst.transform:SetParent(self.m_shenbingModelOneTr)
            inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
            inst.transform.localPosition = Vector3.New(shenbingCfg.pos_right[1][1], shenbingCfg.pos_right[1][2], shenbingCfg.pos_right[1][3])
            inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_right[1][1],shenbingCfg.rotation_right[1][2],shenbingCfg.rotation_right[1][3])
            
            GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
            table_insert(self.m_shenbingModels, {path = exPath1, go = inst})

            self:CheckShowEffect()
        end)

    else
        if wujiangCfg.rightWeaponPath ~= "" then
            if resPath1 then
                pool:GetGameObjectAsync(resPath1, function(inst)
                    if IsNull(inst) then
                        pool:RecycleGameObject(resPath1, inst)
                        return
                    end

                    inst.transform:SetParent(self.m_shenbingModelOneTr)
                    inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
                    inst.transform.localPosition = Vector3.New(shenbingCfg.pos_right[1][1], shenbingCfg.pos_right[1][2], shenbingCfg.pos_right[1][3])
                    inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_right[1][1],shenbingCfg.rotation_right[1][2],shenbingCfg.rotation_right[1][3])
                    
                    GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
                    table_insert(self.m_shenbingModels, {path = resPath1, go = inst})

                    self:CheckShowEffect()
                end)
            end
            if resPath3 then
                pool:GetGameObjectAsync(resPath3, function(inst)
                    if IsNull(inst) then
                        pool:RecycleGameObject(resPath3, inst)
                        return
                    end

                    inst.transform:SetParent(self.m_shenbingModelTwoTr)
                    inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
                    inst.transform.localPosition = Vector3.New(shenbingCfg.pos_right[1][1], shenbingCfg.pos_right[1][2], shenbingCfg.pos_right[1][3])
                    inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_right[1][1],shenbingCfg.rotation_right[1][2],shenbingCfg.rotation_right[1][3])
                    
                    GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
                    table_insert(self.m_shenbingModelsTwo, {path = resPath3, go = inst})

                    self:CheckShowEffect()
                end)
            end
        end
    end

    if shenbingCfg.wujiang_id == 1038 then
        pool:GetGameObjectAsync(exPath2, function(inst)
            if IsNull(inst) then
                pool:RecycleGameObject(exPath2, inst)
                return
            end

            inst.transform:SetParent(self.m_shenbingModelTwoTr)
            inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
            inst.transform.localPosition = Vector3.New(shenbingCfg.pos_right[1][1], shenbingCfg.pos_right[1][2], shenbingCfg.pos_right[1][3])
            inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_right[1][1],shenbingCfg.rotation_right[1][2],shenbingCfg.rotation_right[1][3])
            
            GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
            table_insert(self.m_shenbingModelsTwo, {path = exPath2, go = inst})

            self:CheckShowEffect()
        end)

    else
        if wujiangCfg.leftWeaponPath ~= "" then
            if resPath2 then
                pool:GetGameObjectAsync(resPath2, function(inst)
                    if IsNull(inst) then
                        pool:RecycleGameObject(resPath2, inst)
                        return
                    end

                    inst.transform:SetParent(self.m_shenbingModelOneTr)
                    inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
                    inst.transform.localPosition = Vector3.New(shenbingCfg.pos_left[1][1], shenbingCfg.pos_left[1][2], shenbingCfg.pos_left[1][3])
                    inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_left[1][1],shenbingCfg.rotation_left[1][2],shenbingCfg.rotation_left[1][3])
                    
                    GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
                    table_insert(self.m_shenbingModels, {path = resPath2, go = inst})

                    self:CheckShowEffect()
                end)
            end
            if resPath4 then
                pool:GetGameObjectAsync(resPath4, function(inst)
                    if IsNull(inst) then
                        pool:RecycleGameObject(resPath4, inst)
                        return
                    end

                    inst.transform:SetParent(self.m_shenbingModelTwoTr)
                    inst.transform.localScale = Vector3.New(shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui, shenbingCfg.scale_in_ui)
                    inst.transform.localPosition = Vector3.New(shenbingCfg.pos_left[1][1], shenbingCfg.pos_left[1][2], shenbingCfg.pos_left[1][3])
                    inst.transform.localEulerAngles = Vector3.New(shenbingCfg.rotation_left[1][1],shenbingCfg.rotation_left[1][2],shenbingCfg.rotation_left[1][3])
                    
                    GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
                    table_insert(self.m_shenbingModelsTwo, {path = resPath4, go = inst})

                    self:CheckShowEffect()
                end)
            end
        end
    end
end

function UIShenBingImproveView:Update()
    for _, item in ipairs(self.m_shenbingModels) do
        if item and self.m_shenbingData and self.m_shenbingModelOneTr then
            local shenbingCfg = ConfigUtil.GetShenbingCfgByID(self.m_shenbingData.m_id)
            if shenbingCfg.turn_around == 1 then
                item.go.transform:Rotate(Vector3.forward * Time.deltaTime * 100)
            end
            item.go.transform:RotateAround(self.m_shenbingModelOneTr.position, Vector3.up, Time.deltaTime * 50)
        end
    end
    for _, item in ipairs(self.m_shenbingModelsTwo) do
        if item and self.m_shenbingData and self.m_shenbingModelTwoTr then
            local shenbingCfg = ConfigUtil.GetShenbingCfgByID(self.m_shenbingData.m_id)
            if shenbingCfg.turn_around == 1 then
                item.go.transform:Rotate(Vector3.forward * Time.deltaTime * 100)
            end
            item.go.transform:RotateAround(self.m_shenbingModelTwoTr.position, Vector3.up, Time.deltaTime * 50)
        end
    end
end

function UIShenBingImproveView:UpdateInscription(i, mingwenId, washCount)
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

function UIShenBingImproveView:OnDisable()
    for i = 1, #self.m_effectList do 
        if not IsNull(self.m_effectList[i]) then
            GameObjectPoolInst:RecycleGameObject(effectPath, self.m_effectList[i])
        end
    end
    self.m_effectList = {}


    self:HideDotween()
    UIGameObjectLoader:CancelLoad(self.m_nextInfoSeq)
    self.m_nextInfoSeq = 0
    UIGameObjectLoader:CancelLoad(self.m_infoSeq)
    self.m_infoSeq = 0
    UIGameObjectLoader:CancelLoad(self.m_materialSeq)
    self.m_materialSeq = 0
    for _, v in pairs(self.m_materialPrefabList) do
        v:Delete()
    end
    self.m_materialPrefabList = {}

    local pool = GameObjectPoolInst
    for _, v in ipairs(self.m_shenbingModels) do        
        pool:RecycleGameObject(v.path, v.go)
    end
    self.m_shenbingModels = {}
    for _, v in ipairs(self.m_shenbingModelsTwo) do        
        pool:RecycleGameObject(v.path, v.go)
    end
    self.m_shenbingModelsTwo = {}
    self.m_shenbingIndex = 0
    self.m_shenbingData = false
    if self.m_curShenBingInfoItem then
        self.m_curShenBingInfoItem:Delete()
    end
    self.m_curShenBingInfoItem = false
    if self.m_nextShenBingInfoItem then
        self.m_nextShenBingInfoItem:Delete()
    end
    self.m_nextShenBingInfoItem = false
    self:DestroyRoleContainer()
    base.OnDisable(self)
end

function UIShenBingImproveView:CheckShowEffect()
    if self.m_canShowEffect then
        if self.m_shenbingModels and #self.m_shenbingModels > 0 and self.m_shenbingModelsTwo and #self.m_shenbingModelsTwo > 0 then
            self:ShowEffect()
        end
    end
end

local OffsetPos = Vector3.New(0, -1, 0) 

function UIShenBingImproveView:ShowEffect()

    --武器模型会替换，先回收特效
    for i = 1, #self.m_effectList do 
        if not IsNull(self.m_effectList[i]) then
            GameObjectPoolInst:RecycleGameObject(effectPath, self.m_effectList[i])
        end
    end
    self.m_effectList = {}

    self.m_canShowEffect = false

    GameObjectPoolInst:GetGameObjectAsync2(effectPath, 2,
        function(objs)
            if not objs then
                return
            end

            local isCancel = not self.m_shenbingModels or #self.m_shenbingModels == 0 or not self.m_shenbingModelsTwo or #self.m_shenbingModelsTwo == 0

            for i = 1, 2 do
                local go = objs[i]
                if not IsNull(go) then
                    if isCancel then
                        GameObjectPoolInst:RecycleGameObject(effectPath, go)
                    else
                        local parent = i == 1 and self.m_shenbingModels[#self.m_shenbingModels].go or self.m_shenbingModelsTwo[#self.m_shenbingModelsTwo].go
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
                end
            end
        end)
end

return UIShenBingImproveView