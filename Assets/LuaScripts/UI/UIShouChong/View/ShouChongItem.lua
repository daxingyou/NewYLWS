local GameUtility = CS.GameUtility 
local shopMgr = Player:GetInstance():GetShopMgr()  
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam" 

local ShouChongItem = BaseClass("ShouChongItem", UIBaseItem)
local base = UIBaseItem
 

function ShouChongItem:OnCreate()
    base.OnCreate(self)
    self.m_awardItemList = {}
    self.m_awardItemSeq = 0  

    self.m_awardItemContentTr, 
    self.m_getAwardBtnTr,
    self.m_sliderContainerTr,
    self.m_gotImgTr = UIUtil.GetChildTransforms(self.transform, { 
        "AwardItemContent", 
        "GetAwardBtn",
        "ProgressSliderContainer",
        "GotImg",
    }) 

    self.m_moneyDesTxt,
    self.m_desTxt,
    self.m_getAwardBtnTxt,
    self.m_sliderValueTxt = UIUtil.GetChildTexts(self.transform, {   
        "MoneyBg/MoneyDesTxt",
        "Des",
        "GetAwardBtn/Text",
        "ProgressSliderContainer/ValueTxt"
    })

    self.m_moneySlider = UIUtil.FindSlider(self.transform, "ProgressSliderContainer/TopUpSlider") 

    self.m_sliderContainerTr.gameObject:SetActive(false)
    self.m_getAwardBtnTr.gameObject:SetActive(false)
end

function ShouChongItem:UpdateData(award_info, wujiang_id)
    if not award_info then
        return
    end

    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(wujiang_id)
    local wujiangName = ""
    if wujiangCfg then
        wujiangName = wujiangCfg.sName
    end

    local price = award_info.price 
    local extralPrice = award_info.extral_charge_money
    
    if price <= 1 then
        self.m_desTxt.text = string.format(Language.GetString(3805), wujiangName)
        self.m_takeAwardType = 1
        self.m_moneyDesTxt.text = Language.GetString(3801)
        if extralPrice > 0 then
            self.m_moneySlider.value = 0
        else
            self.m_moneySlider.value = 1
        end
        self.m_sliderValueTxt.text = string.format(Language.GetString(3804), 0, extralPrice)
    else
        self.m_desTxt.text = string.format(Language.GetString(3806), wujiangName)
        self.m_takeAwardType = 98
        self.m_moneyDesTxt.text = string.format(Language.GetString(3802), price)
       
        local percent = (price - extralPrice) / price
        if percent >= 1 then
            percent = 1
        end
        self.m_moneySlider.value = percent
        self.m_sliderValueTxt.text = string.format(Language.GetString(3804), (price - extralPrice), price)
    end
    
    self:CreateAwardItem(award_info.award_list)

    local btnStatus = award_info.btn_status
    self:SetStatus(btnStatus) 
end

function ShouChongItem:CreateAwardItem(award_list) 
    if not award_list then
        return
    end   
    if #self.m_awardItemList <= 0 then
        for i = 1,#award_list do 
            self.m_awardItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_awardItemSeq, CommonAwardItemPrefab, function(go)
                self.m_awardItemSeq = 0
                if not IsNull(go) then
                    local bagItem = CommonAwardItem.New(go, self.m_awardItemContentTr, CommonAwardItemPrefab) 
                    table.insert(self.m_awardItemList, bagItem)
                    local itemIconParam = AwardIconParamClass.New(award_list[i].item_id, award_list[i].count)
                    bagItem:SetLocalScale(Vector3.New(0.9, 0.9, 0.9))
                    bagItem:UpdateData(itemIconParam)
                end
            end) 
        end
    else
        for i = 1, #self.m_awardItemList do
            local itemIconParam = AwardIconParamClass.New(award_list[i].item_id, award_list[i].count)
            self.m_awardItemList[i]:UpdateData(itemIconParam) 
        end
    end 
end

function ShouChongItem:SetStatus(btnStatus)
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    if btnStatus == 0 then
        --不可领取
        self.m_sliderContainerTr.gameObject:SetActive(true)
        self.m_getAwardBtnTr.gameObject:SetActive(false)
        self.m_gotImgTr.gameObject:SetActive(false)
    elseif btnStatus == 1 then
        --可领取
        self.m_sliderContainerTr.gameObject:SetActive(false)
        self.m_getAwardBtnTr.gameObject:SetActive(true)
        self.m_getAwardBtnTr.gameObject:SetActive(true)
        UIUtil.AddClickEvent(self.m_getAwardBtnTr.gameObject, onClick)
        self.m_gotImgTr.gameObject:SetActive(false)
    elseif btnStatus == 2 then
        --已领取 
        self.m_sliderContainerTr.gameObject:SetActive(false)
        self.m_getAwardBtnTr.gameObject:SetActive(false) 
        self.m_gotImgTr.gameObject:SetActive(true)
    end
end  

function ShouChongItem:GetTakeAwardType()
    return self.m_takeAwardType
end

function ShouChongItem:OnClick(go)
    if go.name == "GetAwardBtn" then  
        shopMgr:ReqTakeRechargeAward(self.m_takeAwardType)
    end
end

function ShouChongItem:OnDestroy()
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_awardItemSeq)
    self.m_awardItemSeq = 0

    for i = 1, #self.m_awardItemList do
        self.m_awardItemList[i]:Delete()
    end
    self.m_awardItemList = {}  

    UIUtil.RemoveClickEvent(self.m_getAwardBtnTr.gameObject)

    base.OnDestroy(self)
end

return ShouChongItem

