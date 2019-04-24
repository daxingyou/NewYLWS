
local math_ceil = math.ceil
local string_format = string.format
local UIUtil = UIUtil
local Language = Language
local ConfigUtil = ConfigUtil
local AtlasConfig = AtlasConfig
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()
local ItemMgr = Player:GetInstance():GetItemMgr()
local FuliMgr = Player:GetInstance():GetFuliMgr()
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"

local QiandaoItem = BaseClass("QiandaoItem", UIBaseItem)
local base = UIBaseItem

function QiandaoItem:OnCreate()
    base.OnCreate(self)

    self.m_vipDoubleText = UIUtil.GetChildTexts(self.transform, { "VipDouble/vipDoubleText"})

    self.m_itemParentTr, self.m_vipDoubleTr, self.m_finishTr, self.m_getImgTr = UIUtil.GetChildTransforms(self.transform, {
        "ItemParent",
        "VipDouble",
        "Finish",
        "GetImg"
    })
    self.m_vipDoubleGo = self.m_vipDoubleTr.gameObject
    self.m_finishGo = self.m_finishTr.gameObject
    self.m_getImgGo = self.m_getImgTr.gameObject

    self.m_fuliId = 0
    self.m_entryIndex = 0
    self.m_status = -1
    self.m_curBagItem = nil
    self.m_seq = 0

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self:GetGameObject(), onClick)
end

function QiandaoItem:OnClick(go)
    if go == self:GetGameObject() then
        if self.m_status == 1 then
            FuliMgr:ReqGetFuliAward(self.m_fuliId, self.m_entryIndex, 0, "")
        end
    end
end

function QiandaoItem:UpdateData(item, doubleLevel, entryIndex, status, fuliId)
    if not item then
        return
    end

    self.m_status = status or -1
    if not self.m_curBagItem and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoaderInstance:PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObject(self.m_seq, CommonAwardItemPrefab, function(go)
            self.m_seq = 0
            if not go then
                return
            end
            
            self.m_curBagItem = CommonAwardItem.New(go, self.m_itemParentTr, CommonAwardItemPrefab)
            self.m_curBagItem:SetLocalScale(Vector3.one * 0.8)
            local awardIconParam = AwardIconParamClass.New(item.item_id, item.count)
            if self.m_status == 1 or self.m_status == 2 then
                awardIconParam.showDetailOnClick = false
            end
            self.m_curBagItem:UpdateData(awardIconParam)
        end)
    else
        local awardIconParam = AwardIconParamClass.New(item.item_id, item.count)
        if self.m_status == 1 or self.m_status == 2 then
            awardIconParam.showDetailOnClick = false
        end
        self.m_curBagItem:UpdateData(awardIconParam)
    end
    if doubleLevel ~= -1 then
        self.m_vipDoubleGo:SetActive(true)
        self.m_vipDoubleText.text = string_format(Language.GetString(3434), math_ceil(doubleLevel)) 
    else
        self.m_vipDoubleGo:SetActive(false)
    end
    if self.m_status == 2 then
        self.m_finishGo:SetActive(true)
    else
        self.m_finishGo:SetActive(false)
    end
    if self.m_status == 1 then
        self.m_getImgGo:SetActive(true)
    else
        self.m_getImgGo:SetActive(false)
    end

    self.m_fuliId = fuliId or 0
    self.m_entryIndex = entryIndex or 0
end

function QiandaoItem:OnDestroy()
    UIUtil.RemoveClickEvent(self:GetGameObject())
    self.m_curBagItem:Delete()
    self.m_curBagItem = nil

    UIGameObjectLoaderInstance:CancelLoad(self.m_seq)
    self.m_seq = 0

    base.OnDestroy(self)
end

return QiandaoItem