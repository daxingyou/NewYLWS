
local math_ceil = math.ceil
local math_floor = math.floor
local string_format = string.format
local table_insert = table.insert
local UIUtil = UIUtil
local Language = Language
local ConfigUtil = ConfigUtil
local CommonDefine = CommonDefine
local GameUtility = CS.GameUtility
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()
local ItemMgr = Player:GetInstance():GetItemMgr()

local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"
local ActMgr = Player:GetInstance():GetActMgr()

local ActAwardItem = BaseClass("ActAwardItem", UIBaseItem)
local base = UIBaseItem

function ActAwardItem:OnCreate()
    base.OnCreate(self)

    self.m_conditionText, self.m_descText, self.m_btnText = UIUtil.GetChildTexts(self.transform, { 
        "Condition/Text",
        "Desc",
        "GetBtn/Text",
    })

    self.m_itemParentTr, self.m_getImgTr, self.m_getBtnTr, self.m_descTr, self.m_pastImgTr = UIUtil.GetChildTransforms(self.transform, {
        "Grid",
        "GetImg",
        "GetBtn",
        "Desc",
        "PastImg"
    })

    self.m_btnImg = UIUtil.AddComponent(UIImage, self, "GetBtn")

    self.m_getImgGo = self.m_getImgTr.gameObject
    self.m_getBtnGo = self.m_getBtnTr.gameObject
    self.m_pastImgGo = self.m_pastImgTr.gameObject
    self.m_descGo = self.m_descTr.gameObject

    self.m_awardItemList = {}
    self.m_seq = 0
    self.m_actId = 0
    self.m_tagIndex = 0
    self.m_btnStatus = -1


    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_getBtnGo, onClick)
end

function ActAwardItem:OnClick(go)
    if go.name == "GetBtn" then
        if self.m_btnStatus == CommonDefine.ACT_BTN_STATUS_REACH then
            ActMgr:ReqTakeAward(self.m_actId, self.m_tagIndex, 0)
        elseif self.m_btnStatus == CommonDefine.ACT_BTN_STATUS_CHARGE then
            UIManagerInst:OpenWindow(UIWindowNames.UIVipShop)
        end
    end
end

function ActAwardItem:UpdateData(tagList, actId, tagIndex)
    if not tagList then
        return
    end
    
    self.m_actId = actId or 0
    self.m_tagIndex = tagIndex or 0
    self.m_btnStatus = tagList.btn_status or -1
    self.m_conditionText.text = tagList.tag_name
    self.m_descText.text = tagList.progress
    if #self.m_awardItemList == 0 and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoaderInstance:PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObjects(self.m_seq, CommonAwardItemPrefab, #tagList.award_list, function(objs)
            self.m_seq = 0
            
            if objs then
                for i = 1, #objs do
                    local awardItem = CommonAwardItem.New(objs[i], self.m_itemParentTr, CommonAwardItemPrefab)
                    awardItem:SetLocalScale(Vector3.one * 0.8)
                    table_insert(self.m_awardItemList, awardItem)
                    
                    local awardIconParam = PBUtil.CreateAwardParamFromAwardData(tagList.award_list[i])
                    awardItem:UpdateData(awardIconParam)
                end
            end
        end)
    else
        for i, v in ipairs(self.m_awardItemList) do
            local awardIconParam = PBUtil.CreateAwardParamFromAwardData(tagList.award_list[i])
            v:UpdateData(awardIconParam)
        end
    end

    self.m_getImgGo:SetActive(false)
    self.m_getBtnGo:SetActive(false)
    self.m_pastImgGo:SetActive(false)
    self.m_descGo:SetActive(false)
    GameUtility.SetUIGray(self.m_getBtnGo, false)
    self.m_btnImg:EnableRaycastTarget(true)
    self.m_btnText.text = Language.GetString(3435)
    if tagList.btn_status == CommonDefine.ACT_BTN_STATUS_UNREACH then
        self.m_descGo:SetActive(true)
        self.m_getBtnGo:SetActive(true)
        GameUtility.SetUIGray(self.m_getBtnGo, true)
        self.m_btnImg:EnableRaycastTarget(false)
    elseif tagList.btn_status ==  CommonDefine.ACT_BTN_STATUS_REACH then
        self.m_descGo:SetActive(true)
        self.m_getBtnGo:SetActive(true)
    elseif tagList.btn_status ==  CommonDefine.ACT_BTN_STATUS_CHARGE then
        self.m_descGo:SetActive(true)
        self.m_btnText.text = Language.GetString(3466)
        self.m_getBtnGo:SetActive(true)
    elseif tagList.btn_status == CommonDefine.ACT_BTN_STATUS_TAKEN then
        self.m_getImgGo:SetActive(true)
    elseif tagList.btn_status ==  CommonDefine.ACT_BTN_STATUS_EXPIRED then
        self.m_pastImgGo:SetActive(true)
    end

end

function ActAwardItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_getBtnGo)
    UIGameObjectLoaderInstance:CancelLoad(self.m_seq)
    self.m_seq = 0
    
    for _, v in ipairs(self.m_awardItemList) do
        v:Delete()
    end
    self.m_awardItemList = {}
    
    base.OnDestroy(self)
end

return ActAwardItem