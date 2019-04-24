local UIUtil = UIUtil
local SplitString = CUtil.SplitString
local math_floor = math.floor
local Vector3 = Vector3
local string_format = string.format

local VipGoodsDetailItem = BaseClass("VipGoodsDetailItem", UIBaseItem)
local base = UIBaseItem

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"

function VipGoodsDetailItem:OnCreate()
    self.m_bagItemSeq = 0
    self.m_item = nil
    
    self.m_container = UIUtil.GetChildTransforms(self.transform, {
        "container",
    })

    self.m_nameText = UIUtil.GetChildTexts(self.transform, {
        "container/nameText",
    })
end

function VipGoodsDetailItem:SetData(itemID, itemCount)    
    self.m_bagItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()

    UIGameObjectLoader:GetInstance():GetGameObject(self.m_bagItemSeq, CommonAwardItemPrefab, function(go)
        self.m_bagItemSeq = 0
        if not go then
            return
        end
        
        self.m_item = CommonAwardItem.New(go, self.m_container, CommonAwardItemPrefab)
        local itemIconParam = AwardIconParamClass.New(itemID, itemCount)
        self.m_item:UpdateData(itemIconParam)
    end)

    if Utils.IsWujiang(itemID) then
        local wujiangCfg = ConfigUtil.GetWujiangCfgByID(itemID)
        if wujiangCfg then
            self.m_nameText.text = string_format(Language.GetString(3422), wujiangCfg.sName, itemCount)
        end
    else
        local itemCfg = ConfigUtil.GetItemCfgByID(itemID)
        if itemCfg then
            self.m_nameText.text = string_format(Language.GetString(3422), itemCfg.sName, itemCount)
        end

    end
end

function VipGoodsDetailItem:OnDestroy()
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_bagItemSeq)
    self.m_bagItemSeq = 0

    if self.m_item then
        self.m_item:Delete()
        self.m_item = nil
    end
    base.OnDestroy(self)
end

return VipGoodsDetailItem