
local math_ceil = math.ceil
local math_floor = math.floor
local string_format = string.format
local table_insert = table.insert
local UIUtil = UIUtil
local Language = Language
local ConfigUtil = ConfigUtil
local Vector3 = Vector3
local Vector2 = Vector2
local CommonDefine = CommonDefine
local GameUtility = CS.GameUtility
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()
local ItemMgr = Player:GetInstance():GetItemMgr()
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"
local ActMgr = Player:GetInstance():GetActMgr()

local ActExchangeItem = BaseClass("ActExchangeItem", UIBaseItem)
local base = UIBaseItem

function ActExchangeItem:OnCreate()
    base.OnCreate(self)

    self.m_getCountText, self.m_btnText = UIUtil.GetChildTexts(self.transform, { 
        "BtnStatus/GetCountText",
        "BtnStatus/GetBtn/Text",
    })

    self.m_expendGridTr, self.m_awardParentTr, self.m_getImgTr, self.m_getBtnTr, self.m_btnStatusTr,
    self.m_pastImgTr, self.m_arrowTr = UIUtil.GetChildTransforms(self.transform, {
        "expendGrid",
        "awardParent",
        "GetImg",
        "BtnStatus/GetBtn",
        "BtnStatus",
        "PastImg",
        "arrow",
    })

    self.m_btnImg = UIUtil.AddComponent(UIImage, self, "BtnStatus/GetBtn")
    self.m_btnText.text = Language.GetString(3464)

    self.m_getImgGo = self.m_getImgTr.gameObject
    self.m_btnStatusGo = self.m_btnStatusTr.gameObject
    self.m_pastImgGo = self.m_pastImgTr.gameObject

    self.m_expendItemList = {}
    self.m_seq = 0
    self.m_awardItem = nil
    self.m_awardSeq = 0
    self.m_actId = 0
    self.m_tagIndex = 0

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_getBtnTr.gameObject, onClick)
end

function ActExchangeItem:OnClick(go)
    if go.name == "GetBtn" then
        ActMgr:ReqTakeAward(self.m_actId, self.m_tagIndex, 0)
    end
end


function ActExchangeItem:UpdateData(tagList, actId, tagIndex)
    if not tagList then
        return
    end
    
    self.m_actId = actId or 0
    self.m_tagIndex = tagIndex or 0
    if #self.m_expendItemList == 0 and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoaderInstance:PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObjects(self.m_seq, CommonAwardItemPrefab, #tagList.expend_list, function(objs)
            self.m_seq = 0
            
            if objs then
                for i = 1, #objs do
                    local awardItem = CommonAwardItem.New(objs[i], self.m_expendGridTr, CommonAwardItemPrefab)
                    awardItem:SetLocalScale(Vector3.one * 0.8)
                    table_insert(self.m_expendItemList, awardItem)
                    
                    local awardIconParam = AwardIconParamClass.New(tagList.expend_list[i].item_id, tagList.expend_list[i].count)
                    awardItem:UpdateData(awardIconParam)
                end
            end
        end)
    else
        for i, v in ipairs(self.m_expendItemList) do
            local awardIconParam = AwardIconParamClass.New(tagList.expend_list[i].item_id, tagList.expend_list[i].count)
            v:UpdateData(awardIconParam)
        end
    end

    if not self.m_awardItem and self.m_awardSeq == 0 then
        self.m_awardSeq = UIGameObjectLoaderInstance:PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObject(self.m_awardSeq, CommonAwardItemPrefab, function(obj)
            self.m_awardSeq = 0
            if obj then
                self.m_awardItem = CommonAwardItem.New(obj, self.m_awardParentTr, CommonAwardItemPrefab)
                self.m_awardItem:SetLocalPosition(Vector3.zero)

                local awardIconParam = PBUtil.CreateAwardParamFromAwardData(tagList.award_list[1])
                self.m_awardItem:UpdateData(awardIconParam)
            end
        end)
    else
        local awardIconParam = PBUtil.CreateAwardParamFromAwardData(tagList.award_list[1])
        self.m_awardItem:UpdateData(awardIconParam)
    end

    self.m_arrowTr.anchoredPosition = Vector2.New(-345 + #tagList.expend_list * 125, 0)
    self.m_awardParentTr.anchoredPosition = Vector2.New(-252 + #tagList.expend_list * 125, 0)

    self.m_getImgGo:SetActive(false)
    self.m_btnStatusGo:SetActive(false)
    self.m_pastImgGo:SetActive(false)
    GameUtility.SetUIGray(self.m_getBtnTr.gameObject, false)
    self.m_btnImg:EnableRaycastTarget(true)
    if tagList.btn_status == CommonDefine.ACT_BTN_STATUS_CANNOTEXCHANGE then
        self.m_btnStatusGo:SetActive(true)
        GameUtility.SetUIGray(self.m_getBtnTr.gameObject, true)
        self.m_btnImg:EnableRaycastTarget(false)
        self.m_getCountText.text = tagList.progress
    elseif tagList.btn_status ==  CommonDefine.ACT_BTN_STATUS_CANEXCHANGE then
        self.m_btnStatusGo:SetActive(true)
        self.m_getCountText.text = tagList.progress
    elseif tagList.btn_status == CommonDefine.ACT_BTN_STATUS_EXCHANGED then
        self.m_getImgGo:SetActive(true)
    elseif tagList.btn_status ==  CommonDefine.ACT_BTN_STATUS_EXPIRED then
        self.m_pastImgGo:SetActive(true)
    end

end

function ActExchangeItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_getBtnTr.gameObject)
    UIGameObjectLoaderInstance:CancelLoad(self.m_seq)
    self.m_seq = 0
    UIGameObjectLoaderInstance:CancelLoad(self.m_awardSeq)
    self.m_awardSeq = 0
    
    for _, v in ipairs(self.m_expendItemList) do
        v:Delete()
    end
    self.m_expendItemList = {}

    self.m_awardItem:Delete()
    self.m_awardItem = nil

    base.OnDestroy(self)
end

return ActExchangeItem