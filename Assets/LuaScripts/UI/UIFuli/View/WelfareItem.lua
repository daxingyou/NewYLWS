
local math_ceil = math.ceil
local table_insert = table.insert
local math_floor = math.floor
local string_format = string.format
local UIUtil = UIUtil
local Language = Language
local ConfigUtil = ConfigUtil
local GameUtility = CS.GameUtility
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()
local ItemMgr = Player:GetInstance():GetItemMgr()
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"
local FuliMgr = Player:GetInstance():GetFuliMgr()

local WelfareItem = BaseClass("WelfareItem", UIBaseItem)
local base = UIBaseItem

function WelfareItem:OnCreate()
    base.OnCreate(self)

    self.m_descText, self.m_btnText = UIUtil.GetChildTexts(self.transform, { 
        "Desc",
        "GetBtn/Text",
    })

    self.m_gridTr, self.m_getBtn, self.m_getImgTr = UIUtil.GetChildTransforms(self.transform, {
       "Grid",
       "GetBtn",
       "GetImg"
    })

    self.m_getImgGo = self.m_getImgTr.gameObject
    self.m_getBtnGo = self.m_getBtn.gameObject
    self.m_btnImg = UIUtil.AddComponent(UIImage, self, "GetBtn")

    self.m_fuliId = 0
    self.m_index = 0
    self.m_awardItemList = {}
    self.m_seq = 0

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_getBtn.gameObject, onClick)
end

function WelfareItem:OnClick(go)
    if go.name == "GetBtn" then
        FuliMgr:ReqGetFuliAward(self.m_fuliId, self.m_index, 0, "")
    end
end

function WelfareItem:GetFuliID()
    return self.m_fuliId
end

function WelfareItem:GetIndex()
    return self.m_index
end

function WelfareItem:UpdateData(entry, fuliId)
    if not entry then
        return
    end
    self:RecycleItem()
    
    self.m_fuliId = fuliId or 0
    self.m_index = entry.index
    self.m_btnText.text = Language.GetString(3435)
    self.m_descText.text = entry.desc
    GameUtility.SetUIGray(self.m_getBtn.gameObject, false)
    self.m_getImgGo:SetActive(false)
    self.m_getBtnGo:SetActive(true)
    self.m_btnImg:EnableRaycastTarget(true)
    if entry.status == 0 then
        GameUtility.SetUIGray(self.m_getBtn.gameObject, true)
        self.m_btnImg:EnableRaycastTarget(false)
    elseif entry.status == 2 then
        self.m_getImgGo:SetActive(true)
        self.m_getBtnGo:SetActive(false)
    end

    if #self.m_awardItemList == 0 and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoaderInstance:PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObjects(self.m_seq, CommonAwardItemPrefab, #entry.award_list, function(objs)
            self.m_seq = 0
            
            if objs then
                for i = 1, #objs do
                    local awardItem = CommonAwardItem.New(objs[i], self.m_gridTr, CommonAwardItemPrefab)
                    awardItem:SetLocalScale(Vector3.one * 0.8)
                    table_insert(self.m_awardItemList, awardItem)
                    local awardIconParam = AwardIconParamClass.New(entry.award_list[i].item_id, entry.award_list[i].count)
                    awardItem:UpdateData(awardIconParam)
                end
            end
        end)
    else
        for i, v in ipairs(self.m_awardItemList) do
            local awardIconParam = AwardIconParamClass.New(entry.award_list[i].item_id, entry.award_list[i].count)
            v:UpdateData(awardIconParam)
        end
    end
end

function WelfareItem:RecycleItem()
    UIGameObjectLoaderInstance:CancelLoad(self.m_seq)
    self.m_seq = 0
    
    for _, v in ipairs(self.m_awardItemList) do
        v:Delete()
    end
    self.m_awardItemList = {}
end

function WelfareItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_getBtn.gameObject)
    self:RecycleItem()

    base.OnDestroy(self)
end

return WelfareItem