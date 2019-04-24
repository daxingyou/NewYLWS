
local math_ceil = math.ceil
local string_format = string.format
local table_insert = table.insert
local math_floor = math.floor
local Language = Language
local UIUtil = UIUtil
local ConfigUtil = ConfigUtil
local CommonDefine = CommonDefine
local ItemDefine = ItemDefine
local UILogicUtil = UILogicUtil
local AtlasConfig = AtlasConfig
local GameObject = CS.UnityEngine.GameObject
local GameUtility = CS.GameUtility
local UIGameObjectLoader = UIGameObjectLoader:GetInstance()
local MountMgr = Player:GetInstance():GetMountMgr()
local ItemMgr = Player:GetInstance():GetItemMgr()
local WuJiangMgr = Player:GetInstance().WujiangMgr
local bagItemPath = TheGameIds.CommonBagItemPrefab
local ZuoQiObjPath = "UI/Prefabs/ZuoQi/ZuoQiObj.prefab"
local bagItem = require "UI.UIBag.View.BagItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"

local UIZuoQiImproveView = BaseClass("UIZuoQiImproveView", UIBaseView)
local base = UIBaseView

function UIZuoQiImproveView:OnCreate()
    base.OnCreate(self)
    self.m_infoSeq = 0
    self.m_nextInfoSeq = 0
    self.m_materialSeq = 0
    self.m_zuoqiIndex = 0
    self.m_curZuoQiItem = false
    self.m_nextZuoQiItem = false
    self.m_materialItem = false
    self.m_mountModels = {}

    self:InitView()
end

function UIZuoQiImproveView:InitView()
    local improveBtnText
    
    self.m_curNameText, self.m_nextNameText, self.m_nameText, self.m_stageText,
    self.m_upLimitText, self.m_curStageText, self.m_curAttrText, self.m_nextStageText,
    self.m_nextAttrText, self.m_zuoqiSkillText, improveBtnText, self.m_expendText
    = UIUtil.GetChildTexts(self.transform, {
        "RightContainer/ZuoQiInfo/bg/CurZuoQi/NameText",
        "RightContainer/ZuoQiInfo/bg/NextZuoQi/NextNameText",
        "RightContainer/ZuoQiInfo/bg/Limit/NameText",
        "RightContainer/ZuoQiInfo/bg/Limit/StageText",
        "RightContainer/ZuoQiInfo/bg/LevelLimit",
        "RightContainer/Attribute/Horizontal/LeftAttr/StageText",
        "RightContainer/Attribute/Horizontal/LeftAttr/AttrText",
        "RightContainer/Attribute/Horizontal/RightAttr/NextStageText",
        "RightContainer/Attribute/Horizontal/RightAttr/NextAttrText",
        "RightContainer/Attribute/SkillText",
        "MiddleContainer/ImproveBtn/Text",
        "MiddleContainer/expend/Text",
    })

    improveBtnText.text = Language.GetString(3510)

    self.m_backBtn, self.m_curZuoQiTr, self.m_nextZuoQiTr, self.m_limitGo,
    self.m_rightAttrGo, self.m_improveBtn, self.m_materialTr, self.m_rightContainerTr,
    self.m_middleContainerTr, self.m_nextZuoQiInfoGo, self.m_arrowGo = UIUtil.GetChildTransforms(self.transform, {
        "Panel/backBtn",
        "RightContainer/ZuoQiInfo/bg/CurZuoQi",
        "RightContainer/ZuoQiInfo/bg/NextZuoQi",
        "RightContainer/ZuoQiInfo/bg/Limit",
        "RightContainer/Attribute/Horizontal/RightAttr",
        "MiddleContainer/ImproveBtn",
        "MiddleContainer/material/itemParent",
        "RightContainer",
        "MiddleContainer",
        "RightContainer/ZuoQiInfo/bg/NextZuoQi",
        "arrow"
    })

    self.m_limitGo = self.m_limitGo.gameObject
    self.m_rightAttrGo = self.m_rightAttrGo.gameObject
    self.m_nextZuoQiInfoGo = self.m_nextZuoQiInfoGo.gameObject
    self.m_backBtn = self.m_backBtn.gameObject
    self.m_improveBtn = self.m_improveBtn.gameObject
    self.m_arrowGo = self.m_arrowGo.gameObject

    self.m_colorList = {"FFFFFF", "00a8ff", "b856ff", "ffb400", "e90404"}

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_improveBtn, onClick)
    UIUtil.AddClickEvent(self.m_backBtn, onClick)
end

function UIZuoQiImproveView:OnClick(go)
    if go == self.m_improveBtn then
        if self.m_zuoqiData then
            local zuoqiImproveCfg = ConfigUtil.GetZuoQiImproveCfgByID(self.m_zuoqiData.m_stage)
            if zuoqiImproveCfg then
                local materialHaveCount = ItemMgr:GetItemCountByID(zuoqiImproveCfg.cost_item_id2)
                local needMaterialCount = zuoqiImproveCfg.cost_item_count2
                local itemCfg = ConfigUtil.GetItemCfgByID(zuoqiImproveCfg.cost_item_id2)
                if materialHaveCount < needMaterialCount then
                    UILogicUtil.FloatAlert(string_format(Language.GetString(5000), itemCfg.sName))
                    return
                end

                local contentMsg = string_format(Language.GetString(3509), zuoqiImproveCfg.cost_item_count2, itemCfg.sName, self.m_colorList[self.m_zuoqiData.m_stage + 1], self:GetStageNameByStage(self.m_zuoqiData.m_stage +1))
                UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(3510), contentMsg, Language.GetString(3516),
                    Bind(MountMgr, MountMgr.ReqHorseImprove, self.m_zuoqiIndex), Language.GetString(50))
            end
        end
    elseif go == self.m_backBtn then
        self:CloseSelf()
    end
end

function UIZuoQiImproveView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_improveBtn)
    UIUtil.RemoveClickEvent(self.m_backBtn)
    base.OnDestroy(self)
end

function UIZuoQiImproveView:OnAddListener()
    base.OnAddListener(self)

    self:AddUIListener(UIMessageNames.MN_WUJIANG_RSP_HORSE_IMPROVE_STAGE, self.RspZuoQiImprove)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange)
end

function UIZuoQiImproveView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_RSP_HORSE_IMPROVE_STAGE, self.RspZuoQiImprove)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange)
    
    base.OnRemoveListener(self)
end

function UIZuoQiImproveView:PowerChange(power)
    UILogicUtil.PowerChange(power)
end

function UIZuoQiImproveView:ShowDotween()
    UIUtil.LoopMoveLocalY(self.m_middleContainerTr, -450, 0, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_rightContainerTr, 394, 0, 0.4, false)
end

function UIZuoQiImproveView:HideDotween()
    UIUtil.LoopMoveLocalY(self.m_middleContainerTr, 0, -450, 0.4, false)
    UIUtil.LoopMoveLocalX(self.m_rightContainerTr, 0, 394, 0.4, false)
end

function UIZuoQiImproveView:RspZuoQiImprove(award_horse)
    self.m_zuoqiData = MountMgr:GetDataByIndex(self.m_zuoqiIndex)
    self:UpdateData()
    self:ShowMountModel(self.m_zuoqiData.m_id, self.m_zuoqiData.m_stage)
    local curZuoQiCfg = ConfigUtil.GetZuoQiCfgByID(self.m_zuoqiData.m_id)
    local name = UILogicUtil.GetZuoQiNameByStage(self.m_zuoqiData.m_stage, curZuoQiCfg)

    local awardList = {
        {
            award_type = CommonDefine.AWARD_TYPE_ZUOQI,
            award_horse = award_horse,
        }
    }
    local awardList2 = PBUtil.ParseAwardList(awardList)
    local uiData = {
        openType = 1,
        awardDataList = awardList2,
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function UIZuoQiImproveView:OnEnable(...)
    base.OnEnable(self, ...)
    local _, zuoqiIndex = ...
    self:ShowDotween()
    
    
    self.m_zuoqiIndex = zuoqiIndex or 0
    self.m_zuoqiData = MountMgr:GetDataByIndex(self.m_zuoqiIndex)
    
    self:CreateRoleContainer()
    self:UpdateData()
end

function UIZuoQiImproveView:UpdateData()
    local curData = self.m_zuoqiData

    if curData then

        local curZuoQiCfg = ConfigUtil.GetZuoQiCfgByID(curData.m_id)

        if not curZuoQiCfg then
            return
        end

        if curData.m_stage >= curData.m_max_stage then
            self.m_nextZuoQiInfoGo:SetActive(false)
            self.m_limitGo:SetActive(true)
            self.m_rightAttrGo:SetActive(false)
            self.m_middleContainerTr.gameObject:SetActive(false)
            self.m_upLimitText.text = Language.GetString(3505)
            self.m_nameText.text = UILogicUtil.GetZuoQiNameByStage(curData.m_stage, curZuoQiCfg)
            self.m_stageText.text = string_format(Language.GetString(3512), curData.m_stage, curData.m_max_stage)
            if self.m_mountModelOneTr then
                local pos = self.m_mountModelOneTr.localPosition
                self.m_mountModelOneTr.localPosition = Vector3.New(0.9, pos.y, pos.z)
            end
        else
            if self.m_mountModelOneTr then
                local pos = self.m_mountModelOneTr.localPosition
                self.m_mountModelOneTr.localPosition = Vector3.New(2.1, pos.y, pos.z)
            end
            self.m_nextZuoQiInfoGo:SetActive(true)
            self.m_limitGo:SetActive(false)
            self.m_rightAttrGo:SetActive(true)
            self.m_middleContainerTr.gameObject:SetActive(true)
            self.m_upLimitText.text = string_format(Language.GetString(3577), curData.m_max_stage) 
        end
        self.m_arrowGo:SetActive(curData.m_stage < curData.m_max_stage)
        if self.m_mountModelTwoTr then
            self.m_mountModelTwoTr.gameObject:SetActive(curData.m_stage < curData.m_max_stage)
        end
        
        local itemCfg = ConfigUtil.GetItemCfgByID(curData.m_id)
        if not itemCfg then
            return
        end

        if not self.m_curZuoQiItem and self.m_infoSeq == 0 then
            self.m_infoSeq = UIGameObjectLoader:PrepareOneSeq()
            UIGameObjectLoader:GetGameObject(self.m_infoSeq, bagItemPath, function(go)
                self.m_infoSeq = 0
                if not IsNull(go) then
                    self.m_curZuoQiItem = bagItem.New(go, self.m_curZuoQiTr, bagItemPath)
                    self.m_curZuoQiItem:SetAnchoredPosition(Vector3.zero)
                    local itemIconParam = ItemIconParam.New(itemCfg, 1, curData.m_stage, curData.m_index, nil, false, false, false,
                        false, false, curData.m_stage, false)
                    self.m_curZuoQiItem:UpdateData(itemIconParam)
                end
            end)
        else
            local itemIconParam = ItemIconParam.New(itemCfg, 1, curData.m_stage, curData.m_index, nil, false, false, false,
                false, false, curData.m_stage, false)
            self.m_curZuoQiItem:UpdateData(itemIconParam)
        end
        
        self.m_curNameText.text = UILogicUtil.GetZuoQiNameByStage(curData.m_stage, curZuoQiCfg)
        self.m_curStageText.text = string_format(Language.GetString(3507), self.m_colorList[curData.m_stage], self:GetStageNameByStage(curData.m_stage))
        
        if curData.m_stage < curData.m_max_stage then
            if not self.m_nextZuoQiItem and self.m_nextInfoSeq == 0 then
                self.m_nextInfoSeq = UIGameObjectLoader:PrepareOneSeq()
                UIGameObjectLoader:GetGameObject(self.m_nextInfoSeq, bagItemPath, function(go)
                    self.m_nextInfoSeq = 0
                    if not IsNull(go) then
                        self.m_nextZuoQiItem = bagItem.New(go, self.m_nextZuoQiTr, bagItemPath)
                        self.m_nextZuoQiItem:SetAnchoredPosition(Vector3.zero)
                        local itemIconParam = ItemIconParam.New(itemCfg, 1, curData.m_stage + 1, curData.m_index, nil, false, false, false,
                            false, false, curData.m_stage + 1, false)
                        self.m_nextZuoQiItem:UpdateData(itemIconParam)
                    end
                end)
            else
                local itemIconParam = ItemIconParam.New(itemCfg, 1, curData.m_stage + 1, curData.m_index, nil, false, false, false,
                    false, false, curData.m_stage + 1, false)
                self.m_nextZuoQiItem:UpdateData(itemIconParam)
            end

            self.m_nextNameText.text = UILogicUtil.GetZuoQiNameByStage(curData.m_stage + 1, curZuoQiCfg)
            self.m_nextStageText.text = string_format(Language.GetString(3508), self.m_colorList[curData.m_stage + 1], self:GetStageNameByStage(curData.m_stage + 1))
        end

        local baseAttr = curData.m_base_first_attr
        local extraAttr = curData.m_extra_first_attr
        if baseAttr and extraAttr then
            local attrNameList = CommonDefine.first_attr_name_list
            local attrStr = ""
            local nextAttrStr = ""
            for i, v in pairs(attrNameList) do
                local val = baseAttr[v]
                local val2 = extraAttr[v]
                if val and val2 then
                    local attrType = CommonDefine[v]
                    if attrType then
                        attrStr = attrStr..string_format(Language.GetString(3515), Language.GetString(attrType + 10), val2)
                        nextAttrStr = nextAttrStr..string_format("%d\n", math_floor(curData.m_stage * (val / 2)))
                    end
                end
            end
            self.m_curAttrText.text = attrStr
            self.m_nextAttrText.text = nextAttrStr
        end
        
        local skillCfg = ConfigUtil.GetInscriptionAndHorseSkillCfgByID(curZuoQiCfg.skill_id)
        if skillCfg then
            local stage = math_ceil(curData.m_stage + 1)
            if curData.m_stage == curData.m_max_stage then
                stage = math_ceil(curData.m_stage)
            end
            local desc = skillCfg["exdesc"..stage]
            if desc and desc ~= "" then
                local exdesc = desc:gsub("{(.-)}", function(m)
                    local v = skillCfg[m]
                    if v then
                        return "<color=#1DE2DB>" .. v .. "</color>"
                    end
                end)
                self.m_zuoqiSkillText.text = string_format(Language.GetString(3514), exdesc)
            end
        end

        self:UpdateMaterial()
    end
end

function UIZuoQiImproveView:ShowMountModel(mountId, stage)
    if not mountId then
        Logger.LogError("no mountId!")
        return
    end
    
    local pool = GameObjectPoolInst
    for _, v in ipairs(self.m_mountModels) do        
        pool:RecycleGameObject(v.path, v.go)
    end
    self.m_mountModels = {}
    local resPath = PreloadHelper.GetShowoffHorsePath(mountId, stage)
    local resPath2 = PreloadHelper.GetShowoffHorsePath(mountId, stage + 1)
    
    pool:GetGameObjectAsync(resPath, function(inst)
        if IsNull(inst) then
            pool:RecycleGameObject(resPath, inst)
            return
        end

        inst.transform:SetParent(self.m_mountModelOneTr)
        inst.transform.localScale = Vector3.New(0.7, 0.7, 0.7)
        inst.transform.localPosition = Vector3.New(0, 0, 1.3)
        inst.transform.localEulerAngles = Vector3.New(0, -15, 0)
        
        GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
        GameUtility.SetShadowHeight(inst, inst.transform.position.y, 0)
        table_insert(self.m_mountModels, {path = resPath, go = inst})
    end)

    if stage + 1 <= 5 then
        pool:GetGameObjectAsync(resPath2, function(inst)
            if IsNull(inst) then
                pool:RecycleGameObject(resPath2, inst)
                return
            end

            inst.transform:SetParent(self.m_mountModelTwoTr)
            inst.transform.localScale = Vector3.New(0.7, 0.7, 0.7)
            inst.transform.localPosition = Vector3.New(0, 0, 1.3)
            inst.transform.localEulerAngles = Vector3.New(0, -10, 0)
            
            GameUtility.RecursiveSetLayer(inst, Layers.IGNORE_RAYCAST)
            GameUtility.SetShadowHeight(inst, inst.transform.position.y, 0)
            table_insert(self.m_mountModels, {path = resPath2, go = inst})
        end)
    end
end

function UIZuoQiImproveView:UpdateMaterial()
    local curData = self.m_zuoqiData
    local zuoqiImproveCfg = ConfigUtil.GetZuoQiImproveCfgByID(curData.m_stage)
    if curData and zuoqiImproveCfg then
        local materialHaveCount = ItemMgr:GetItemCountByID(zuoqiImproveCfg.cost_item_id2)
        local tempStr = materialHaveCount >= zuoqiImproveCfg.cost_item_count2 and Language.GetString(2917) or Language.GetString(2916)
        local materialText = string_format(tempStr, materialHaveCount, zuoqiImproveCfg.cost_item_count2)

        local itemCfg = ConfigUtil.GetItemCfgByID(zuoqiImproveCfg.cost_item_id2)
        if not self.m_materialItem and self.m_materialSeq then
            self.m_materialSeq = UIGameObjectLoader:PrepareOneSeq()
            UIGameObjectLoader:GetGameObject(self.m_materialSeq, bagItemPath, function(go)
                self.m_materialSeq = 0
                if not IsNull(go) then
                    self.m_materialItem = bagItem.New(go, self.m_materialTr, bagItemPath)
                    self.m_materialItem:SetAnchoredPosition(Vector3.zero)
                    local itemIconParam = ItemIconParam.New(itemCfg, 1, -1, nil, nil, false, false, false,
                    false, false, -1, false, materialText)
                    itemIconParam.onClickShowDetail = true
                    self.m_materialItem:UpdateData(itemIconParam)
                end
            end)
        else
            local itemIconParam = ItemIconParam.New(itemCfg, 1, -1, nil, nil, false, false, false,
            false, false, -1, false, materialText)
            itemIconParam.onClickShowDetail = true
            self.m_materialItem:UpdateData(itemIconParam)
        end

        self.m_expendText.text = zuoqiImproveCfg.cost_item_count1
    end
end

function UIZuoQiImproveView:GetStageNameByStage(stage)
    if stage == CommonDefine.ItemStageType_1 then
        return "一阶属性"
    elseif stage == CommonDefine.ItemStageType_2 then
        return "二阶属性"
    elseif stage == CommonDefine.ItemStageType_3 then
        return "三阶属性"
    elseif stage == CommonDefine.ItemStageType_4 then
        return "四阶属性"
    elseif stage == CommonDefine.ItemStageType_5 then
        return "五阶属性"
    else
        return ""
    end
end

function UIZuoQiImproveView:CreateRoleContainer()
    if IsNull(self.m_zuoqiObjGo) then

        self.m_sceneSeq = UIGameObjectLoader:PrepareOneSeq()
        UIGameObjectLoader:GetGameObject(self.m_sceneSeq, ZuoQiObjPath, function(go)
            self.m_sceneSeq = 0
            if not IsNull(go) then
                self.m_zuoqiObjGo = go
                self.m_mountModelOneTr = self.m_zuoqiObjGo.transform:GetChild(0)
                self.m_mountModelTwoTr = self.m_zuoqiObjGo.transform:GetChild(1)
                self.m_mountModelTwoTr.gameObject:SetActive(true)
                if self.m_zuoqiData and self.m_zuoqiData.m_stage  == self.m_zuoqiData.m_max_stage then
                    local pos = self.m_mountModelOneTr.localPosition
                    self.m_mountModelOneTr.localPosition = Vector3.New(0.9, pos.y, pos.z)
                    self.m_mountModelTwoTr.gameObject:SetActive(false)
                else
                    local pos = self.m_mountModelOneTr.localPosition
                    self.m_mountModelOneTr.localPosition = Vector3.New(2.1, pos.y, pos.z)
                end
                if self.m_zuoqiData then
                    self:ShowMountModel(self.m_zuoqiData.m_id, self.m_zuoqiData.m_stage)
                end
            end
        end)
    end
end

function UIZuoQiImproveView:DestroyRoleContainer()

    UIGameObjectLoader:CancelLoad(self.m_sceneSeq)
    self.m_sceneSeq = 0
    self.m_mountModelOneTr = nil
    self.m_mountModelTwoTr = nil

    if not IsNull(self.m_zuoqiObjGo) then
        UIGameObjectLoader:RecycleGameObject(ZuoQiObjPath, self.m_zuoqiObjGo)
        self.m_zuoqiObjGo = nil
    end
end

function UIZuoQiImproveView:OnDisable()
    UIGameObjectLoader:CancelLoad(self.m_infoSeq)
    self.m_infoSeq = 0
    UIGameObjectLoader:CancelLoad(self.m_nextInfoSeq)
    self.m_nextInfoSeq = 0
    UIGameObjectLoader:CancelLoad(self.m_materialSeq)
    self.m_materialSeq = 0
    
    self.m_infoSeq = 0
    self.m_nextInfoSeq = 0
    self.m_materialSeq = 0
    self.m_zuoqiIndex = 0
    if self.m_curZuoQiItem then
        self.m_curZuoQiItem:Delete()
    end
    self.m_curZuoQiItem = false
    if self.m_nextZuoQiItem then
        self.m_nextZuoQiItem:Delete()
    end
    self.m_nextZuoQiItem = false
    if self.m_materialItem then
        self.m_materialItem:Delete()
    end
    self.m_materialItem = false
    self.m_zuoqiData = false

    local pool = GameObjectPoolInst
    for _, v in ipairs(self.m_mountModels) do        
        pool:RecycleGameObject(v.path, v.go)
    end
    self.m_mountModels = {}
    self:DestroyRoleContainer()
    self:HideDotween()
    base.OnDisable(self)
end

return UIZuoQiImproveView
