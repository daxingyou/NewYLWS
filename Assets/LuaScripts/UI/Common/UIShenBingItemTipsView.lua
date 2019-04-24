local UIShenBingItemTipsView = BaseClass("UIShenBingItemTipsView", UIBaseView)
local base = UIBaseView

local Screen = CS.UnityEngine.Screen
local UIUtil = UIUtil
local CommonDefine = CommonDefine
local table_insert = table.insert
local string_format = string.format

local UITipsHelper = require "UI.Common.UITipsHelper"
local BagItemClass = require("UI.UIBag.View.BagItem")
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local ShenBingInscriptionItem = require "UI.UIWuJiang.View.ShenBingInscriptionItem"

local ShenBingInscriptionItemPath = "UI/Prefabs/Common/ShenBingInscriptionItemPrefab.prefab"
local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab

function UIShenBingItemTipsView:OnCreate()
    base.OnCreate(self)
    
    self:InitVariable()

    self:InitView()
end

function UIShenBingItemTipsView:OnEnable(...)
    base.OnEnable(self)

    _, self.m_shenbingDetailData, self.m_wujiangId = ...

    if self.m_shenbingDetailData then

        self:UpdateView()

        if self.m_tips then
            local offset = Vector2.New(300, -200) * (Screen.height / CommonDefine.MANUAL_HEIGHT)
           
            self.m_tips:Init(offset)
        end
    end
end

function UIShenBingItemTipsView:OnDisable()
    --取消加载
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_shenbingItemSeq)
    self.m_shenbingItemSeq = 0
   
    --回收
    if self.m_shenbingItem then
        self.m_shenbingItem:Delete()
        self.m_shenbingItem = nil
    end

    for i,v in ipairs(self.m_attrTextList) do
        v.text = ""
    end

    for i,v in ipairs(self.m_shenbingInscriptionList) do
        v:Delete()
    end
    self.m_shenbingInscriptionList = {}

    base.OnDisable(self)
end

function UIShenBingItemTipsView:OnClick(go, x, y)
    self:CloseSelf()
end

-- 初始化非UI变量
function UIShenBingItemTipsView:InitVariable()
    self.m_shenbingInscriptionList = {}
    self.m_shenbingItemSeq = 0
    self.m_shenbingItem = nil
end

function UIShenBingItemTipsView:InitView()

    self.m_tips = self:AddComponent(UITipsHelper, "Container")
     
    self.m_shenbingInscriptionItemParent, self.m_backBtn, self.m_shenbingRoot = 
    UIUtil.GetChildTransforms(self.transform, {
        "Container/ShenbingInscriptionList",
        "backBtn",
        "Container/IconRoot",
    })

    self.m_attrText1, self.m_attrText2, self.m_attrText3, 
    self.m_shenbingStageText, self.m_masterText, self.m_shenbingNameText = 
    UIUtil.GetChildTexts(self.transform, {
        "Container/AttrTextGrid/AttrText1",
        "Container/AttrTextGrid/AttrText2",
        "Container/AttrTextGrid/AttrText3",
        "Container/IconRoot/Info/StageText",
        "Container/IconRoot/MasterText",
        "Container/IconRoot/Info/ShenbingNameText"
    })

    self.m_attrTextList = { self.m_attrText1, self.m_attrText2, self.m_attrText3 }
 
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
end

function UIShenBingItemTipsView:UpdateView()

    self:CreateShenBingIcon()

    self:UpdateAttrList()

    self:UpdateMingWenList()
end

function UIShenBingItemTipsView:CreateShenBingIcon()

    local itemCfg = ConfigUtil.GetItemCfgByID(self.m_shenbingDetailData.id)
    local shenbingCfg = ConfigUtil.GetShenbingCfgByID(self.m_shenbingDetailData.id)

    if not itemCfg or not shenbingCfg then
        return
    end 

    local stage =  UILogicUtil.GetShenBingStageByLevel(self.m_shenbingDetailData.stage)

    local itemIconParam = ItemIconParam.New(itemCfg, 1, stage, 0)
    itemIconParam.stageText = self.m_shenbingDetailData.stage

    if not self.m_shenbingItem then
        self.m_shenbingItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObject(self.m_shenbingItemSeq, BagItemPrefabPath, function(go)
            self.m_shenbingItemSeq = 0
            if not IsNull(go) then
                self.m_shenbingItem = BagItemClass.New(go, self.m_shenbingRoot, BagItemPrefabPath)
                self.m_shenbingItem:UpdateData(itemIconParam)
            end
        end)
    else
        self.m_shenbingItem:UpdateData(itemIconParam)
    end

    self.m_shenbingNameText.text = UILogicUtil.GetShenBingNameByStage(self.m_shenbingDetailData.stage, shenbingCfg)
    if self.m_shenbingDetailData.stage > 0 then
        self.m_shenbingStageText.text = string_format("+%d", self.m_shenbingDetailData.stage)
    else
        self.m_shenbingStageText.text = ""
    end

    self.m_masterText.text = string_format(Language.GetString(760), shenbingCfg.wujiang_name)
end

function UIShenBingItemTipsView:UpdateAttrList()
    local attrList = self.m_shenbingDetailData.attr_list
    if attrList then
        local index = 1
        local nameList = CommonDefine.mingwen_second_attr_name_list
        for _, name in ipairs(nameList) do
            local val = attrList[name]
            if val then
                local attrType = CommonDefine[name]
                if attrType then
                    if index <= #self.m_attrTextList then
                        local attrText = self.m_attrTextList[index]
                        attrText.text = Language.GetString(attrType + 10)..string_format("<color=#17f100>+%d</color>", val)
                        index = index + 1
                    end
                end
            end
        end
    end
end

function UIShenBingItemTipsView:UpdateMingWenList()
    local mingwenList = self.m_shenbingDetailData.mingwen_list

    local function loadCallBack()
        for i, v in ipairs(self.m_shenbingInscriptionList) do
            local mingwenData = mingwenList and mingwenList[i] or nil
            v:SetData(i, mingwenData)
        end
    end
    local insCount = 3
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_wujiangId)
    if wujiangCfg then
        if wujiangCfg.rare == CommonDefine.WuJiangRareType_3 then
            insCount = 2
        elseif wujiangCfg.rare == CommonDefine.WuJiangRareType_4 then
            insCount = 3
        end
    end

    if #self.m_shenbingInscriptionList == 0 then
        self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(self.m_seq, ShenBingInscriptionItemPath, insCount, function(objs)
            self.m_seq = 0
            if objs then
                for i = 1, #objs do
                    local bagItem = ShenBingInscriptionItem.New(objs[i], self.m_shenbingInscriptionItemParent, ShenBingInscriptionItemPath)
                    table_insert(self.m_shenbingInscriptionList, bagItem)
                end

                loadCallBack()
            end
        end)
    else
        loadCallBack()
    end
end

function UIShenBingItemTipsView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    base.OnDestroy(self)
end

return UIShenBingItemTipsView