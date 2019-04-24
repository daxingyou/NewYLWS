local UIAwardDetailView = BaseClass("UIAwardDetailView", UIBaseView)
local base = UIBaseView
local UIUtil = UIUtil
local table_insert = table.insert
local UITipsHelper = require "UI.Common.UITipsHelper"
local CommonDefine = CommonDefine
local ConfigUtil = ConfigUtil
local UILogicUtil = UILogicUtil
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()
local Utils = Utils

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"

function UIAwardDetailView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()
end

function UIAwardDetailView:InitView()

    self.m_tips = self:AddComponent(UITipsHelper, "ItemDetailContainer")
     
    self.m_itemCreatePos, self.m_backBtn, self.m_itemContainerTr = 
    UIUtil.GetChildRectTrans(self.transform, {
        "ItemDetailContainer/ItemCreatePos",
        "backBtn",
        "ItemDetailContainer",
    })

    self.m_itemNameText, self.m_itemDescText, self.m_attrText = 
    UIUtil.GetChildTexts(self.transform, {
        "ItemDetailContainer/ItemNameText",
        "ItemDetailContainer/ItemDescText",
        "ItemDetailContainer/ItemAttrText",
    })

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    self.m_itemDetailTmpItem = nil 
    self.m_currSelectItem = nil      
end

function UIAwardDetailView:OnEnable(...)
    base.OnEnable(self)
    local order 
    order, self.m_currSelectItem = ...

    if self.m_currSelectItem then
        local posZ = self.m_currSelectItem:GetItemDetailPosZ()
        local pos = self.transform.localPosition
        if posZ ~= 0 then
            pos.z = posZ
        else
            pos.z = 0  --reset
        end
        self.transform.localPosition = pos
    end

    self:ChgItemDetailShowState(true)

    if self.m_tips then
        self.m_tips:Init(Vector2.New(-260, -30))
    end
end

function UIAwardDetailView:UpdateData()
end

function UIAwardDetailView:ChgItemDetailShowState(isShow)
    if isShow then
        self:UpdateItemDetailContainer()    
    end
end

function UIAwardDetailView:UpdateItemDetailContainer()
    if not self.m_currSelectItem  then
        self:ChgItemDetailShowState(false)
        return
    end

    if self.m_itemDetailTmpItem then
        self.m_itemDetailTmpItem:Delete()
        self.m_itemDetailTmpItem = nil
    end
   
    local iconParam = self.m_currSelectItem:GetParam()

    --显示物品图标
    self.m_bagItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoaderInstance:GetGameObject(self.m_bagItemSeq, CommonAwardItemPrefab, function(go)
        self.m_bagItemSeq = 0
        if not go then
            return
        end
        
        self.m_itemDetailTmpItem = CommonAwardItem.New(go, self.m_itemCreatePos, CommonAwardItemPrefab)
        self.m_itemDetailTmpItem:UpdateData(iconParam)
    end)
    
    --更新物品信息
    if Utils.IsWujiang(iconParam.itemID) then
        local wujiangCfg = ConfigUtil.GetWujiangCfgByID(iconParam.itemID)
        if wujiangCfg then
            self.m_itemNameText.text = wujiangCfg.sName
            self.m_itemDescText.text = wujiangCfg.nWujiangBrief
        end
        self.m_attrText.text = ''
    else
        local itemCfg = ConfigUtil.GetItemCfgByID(iconParam.itemID)
        if itemCfg then
            local itemMainType = itemCfg.sMainType
            if itemMainType == CommonDefine.ItemMainType_ShenBing then
                local shenbingCfg = ConfigUtil.GetShenbingCfgByID(iconParam.itemID)
                if shenbingCfg then
                    self.m_itemNameText.text = UILogicUtil.GetShenBingNameByStage(iconParam.level, shenbingCfg)
                end
            else
                self.m_itemNameText.text = itemCfg.sName
            end

            self.m_itemDescText.text = itemCfg.sTips

            if itemMainType == CommonDefine.ItemMainType_MingQian then
                local stage  = UILogicUtil.GetInscriptionStage(iconParam.itemID)
                local color = CommonDefine.colorList[stage]
                self.m_attrText.text = string.format(Language.GetString(689), color, UILogicUtil.GetInscriptionDesc(iconParam.itemID)) 
            else
                self.m_attrText.text = ''
            end
        end
    end
    
    -- self.m_currNumText.text = string.format("%.d",itemCount)
    
end

function UIAwardDetailView:OnDisable()
    base.OnDisable(self)
    
    self:ChgItemDetailShowState(false)

    if self.m_bagItemSeq and self.m_bagItemSeq > 0 then
        UIGameObjectLoader:GetInstance():CancelLoad(self.m_bagItemSeq)
    end
    self.m_bagItemSeq = 0
    
    if self.m_itemDetailTmpItem then
        self.m_itemDetailTmpItem:Delete()
        self.m_itemDetailTmpItem = nil
    end   
end

function UIAwardDetailView:OnClick(go, x, y)
    self:CloseSelf()
end

function UIAwardDetailView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    base.OnDestroy(self)
end

return UIAwardDetailView