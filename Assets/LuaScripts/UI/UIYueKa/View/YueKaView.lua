
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam" 
local shopMgr = Player:GetInstance():GetShopMgr()
local GameUtility = CS.GameUtility 

local YueKaView = BaseClass("YueKaView", UIBaseView)
local base = UIBaseView 

function YueKaView:OnCreate()
    base.OnCreate(self) 
    self.m_leftAwardItemList = {}
    self.m_rightAwardItemList = {}

    self:InitView()
    self:HandleClick()
end

function YueKaView:InitView()
    self.m_maskBgTr,
    self.m_backBtnTr,
    self.m_leftBuyBtnTr,
    self.m_leftGetAwardBtnTr,
    self.m_leftItemContainerTr,
    self.m_rightBuyBtnTr,
    self.m_rightGetAwardBtnTr,
    self.m_rightItemContainerTr = UIUtil.GetChildTransforms(self.transform, {
        "MaskBg",
        "BackBtn",
        "Panel/LeftBottom/LeftBuy_BTN",
        "Panel/LeftBottom/LeftGetAward_BTN", 
        "Panel/LeftBottom/ItemContainer",
        "Panel/RightBottom/RightBuy_BTN",
        "Panel/RightBottom/RightGetAward_BTN",
        "Panel/RightBottom/ItemContainer",
    })

    self.m_leftBottomDesTxt,
    self.m_leftBuyBtnTxt,
    self.m_leftGetAwardBtnTxt,
    self.m_leftRemainingTimeTxt,
    self.m_rightBottomDesTxt,
    self.m_rightBuyBtnTxt,
    self.m_rightGetAwardBtnTxt,
    self.m_rightRemainingTimeTxt = UIUtil.GetChildTexts(self.transform, {  
          "Panel/LeftBottom/Des",
          "Panel/LeftBottom/LeftBuy_BTN/Text",
          "Panel/LeftBottom/LeftGetAward_BTN/Text",
          "Panel/LeftBottom/LeftTimeTxt",
          "Panel/RightBottom/Des",
          "Panel/RightBottom/RightBuy_BTN/Text",
          "Panel/RightBottom/RightGetAward_BTN/Text",
          "Panel/RightBottom/LeftTimeTxt", 
    })

    self.m_leftBottomDesTxt.text = string.format(Language.GetString(3840), 300, 30)
    self.m_rightBottomDesTxt.text = string.format(Language.GetString(3840), 980, 30)

    self.m_leftGetAwardBtnTr.gameObject:SetActive(false)
    self.m_rightGetAwardBtnTr.gameObject:SetActive(false)

end

function YueKaView:OnEnable(...)
    base.OnEnable(self, ...)     
    shopMgr:ReqYueKaInfo()
end  

function YueKaView:OnRspPanelInfo(panel_info)
    self:UpdateData(panel_info)
end

function YueKaView:OnNtfPanelInfo(panel_info)
    self:UpdateData(panel_info)
end

function YueKaView:OnRspTakeAward(award_list)
    local uiData = {
       titleMsg = Language.GetString(62),
       openType = 1,
       awardDataList = award_list,
   }
   UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function YueKaView:UpdateData(panel_info)
    if not panel_info then
        return
    end 

    local small_yueka = panel_info.small_yueka
     self:CreateAwardItem(small_yueka.item_list, self.m_leftAwardItemList, self.m_leftItemContainerTr)
    self.m_leftBuyBtnTxt.text = string.format(Language.GetString(3841), math.ceil(small_yueka.price) or 30)
    self.m_leftRemainingTimeTxt.text = string.format(Language.GetString(3844), small_yueka.left_days)
    local leftStatus = small_yueka.status
    if leftStatus == 1 then
        --可购买
        self.m_leftBuyBtnTr.gameObject:SetActive(true) 
        self.m_leftGetAwardBtnTr.gameObject:SetActive(false)
        self.m_leftRemainingTimeTxt.text = ""
    elseif leftStatus == 2 then
        --可领取
        self.m_leftBuyBtnTr.gameObject:SetActive(false) 
        self.m_leftGetAwardBtnTr.gameObject:SetActive(true) 
        local onClick = UILogicUtil.BindClick(self, self.OnClick)
        UIUtil.AddClickEvent(self.m_leftGetAwardBtnTr.gameObject, onClick)
        GameUtility.SetUIGray(self.m_leftGetAwardBtnTr.gameObject, false) 
        self.m_leftGetAwardBtnTxt.text = Language.GetString(3842)
    elseif leftStatus == 3 then
        -- 已领取
        self.m_leftBuyBtnTr.gameObject:SetActive(false) 
        self.m_leftGetAwardBtnTr.gameObject:SetActive(true) 
        UIUtil.RemoveClickEvent(self.m_leftGetAwardBtnTr.gameObject)  
        GameUtility.SetUIGray(self.m_leftGetAwardBtnTr.gameObject, true) 
        self.m_leftGetAwardBtnTxt.text = Language.GetString(3843)
    end

    local big_yueka = panel_info.big_yueka
    self:CreateAwardItem(big_yueka.item_list, self.m_rightAwardItemList, self.m_rightItemContainerTr)
    self.m_rightBuyBtnTxt.text = string.format(Language.GetString(3841), math.ceil(big_yueka.price) or 98)
    self.m_rightRemainingTimeTxt.text = string.format(Language.GetString(3844), big_yueka.left_days)
    local rightStatus = big_yueka.status 
    if rightStatus == 1 then
        --可购买
        self.m_rightBuyBtnTr.gameObject:SetActive(true) 
        self.m_rightGetAwardBtnTr.gameObject:SetActive(false)
        self.m_rightRemainingTimeTxt.text = ""
    elseif rightStatus == 2 then
        --可领取
        self.m_rightBuyBtnTr.gameObject:SetActive(false) 
        self.m_rightGetAwardBtnTr.gameObject:SetActive(true) 
        local onClick = UILogicUtil.BindClick(self, self.OnClick)
        UIUtil.AddClickEvent(self.m_rightGetAwardBtnTr.gameObject, onClick)
        GameUtility.SetUIGray(self.m_rightGetAwardBtnTr.gameObject, false) 
        self.m_rightGetAwardBtnTxt.text = Language.GetString(3842)
    elseif rightStatus == 3 then
        -- 已领取
        self.m_rightBuyBtnTr.gameObject:SetActive(false) 
        self.m_rightGetAwardBtnTr.gameObject:SetActive(true) 
        UIUtil.RemoveClickEvent(self.m_rightGetAwardBtnTr.gameObject)  
        GameUtility.SetUIGray(self.m_rightGetAwardBtnTr.gameObject, true) 
        self.m_rightGetAwardBtnTxt.text = Language.GetString(3843)
    end
end

function YueKaView:CreateAwardItem(award_list, item_list, parent_tran)  
    if not award_list then
        return
    end   
    if #item_list <= 0 then
        for i = 1,#award_list do 
            local seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObject(seq, CommonAwardItemPrefab, function(go)
                seq = 0
                if not IsNull(go) then
                    local awardtem = CommonAwardItem.New(go, parent_tran, CommonAwardItemPrefab) 
                    table.insert(item_list, awardtem)
                    local itemIconParam = AwardIconParamClass.New(award_list[i].item_id, award_list[i].count)
                    awardtem:UpdateData(itemIconParam)
                end
            end) 
        end
    else
        for i = 1, #item_list do
            local itemIconParam = AwardIconParamClass.New(award_list[i].item_id, award_list[i].count)
            item_list[i]:UpdateData(itemIconParam) 
        end
    end 
end

function YueKaView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_maskBgTr.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0)) 
    UIUtil.AddClickEvent(self.m_backBtnTr.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0)) 
    UIUtil.AddClickEvent(self.m_leftBuyBtnTr.gameObject, onClick) 
    UIUtil.AddClickEvent(self.m_rightBuyBtnTr.gameObject, onClick) 
end

function YueKaView:OnClick(go, x, y)
    if go.name == "MaskBg" or go.name == "BackBtn" then
        self:CloseSelf()
    elseif go.name == "LeftBuy_BTN" then
        -- UIManagerInst:OpenWindow(UIWindowNames.UIGMView)
    elseif go.name == "LeftGetAward_BTN" then
        local yuekaType = 1 
        shopMgr:ReqTakeYueKaAward(yuekaType)
    elseif go.name == "RightBuy_BTN" then 
        -- UIManagerInst:OpenWindow(UIWindowNames.UIGMView)
    elseif go.name == "RightGetAward_BTN" then
        local yuekaType = 2
        shopMgr:ReqTakeYueKaAward(yuekaType)
    end
end 

function YueKaView:OnAddListener()
    base.OnAddListener(self)
    
    self:AddUIListener(UIMessageNames.MN_RSP_YUEKA_PANEL_INFO, self.OnRspPanelInfo) 
    self:AddUIListener(UIMessageNames.MN_NTF_YUEKA_PANEL_INFO, self.OnNtfPanelInfo) 
    self:AddUIListener(UIMessageNames.MN_RSP_YUEKA_TAKE_AWARD, self.OnRspTakeAward) 
end

function YueKaView:OnRemoveListener()
    base.OnRemoveListener(self)
    
    self:RemoveUIListener(UIMessageNames.MN_RSP_YUEKA_PANEL_INFO, self.OnRspPanelInfo) 
    self:RemoveUIListener(UIMessageNames.MN_NTF_YUEKA_PANEL_INFO, self.OnNtfPanelInfo) 
    self:RemoveUIListener(UIMessageNames.MN_RSP_YUEKA_TAKE_AWARD, self.OnRspTakeAward) 
end

function YueKaView:OnDisable()
    for i = 1, #self.m_leftAwardItemList do
        self.m_leftAwardItemList[i]:Delete()
    end
    self.m_leftAwardItemList = {}  

    for i = 1, #self.m_rightAwardItemList do
        self.m_rightAwardItemList[i]:Delete()
    end
    self.m_rightAwardItemList = {}  

    base.OnDisable(self)
end 

function YueKaView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_maskBgTr.gameObject) 
    UIUtil.RemoveClickEvent(self.m_leftBuyBtnTr.gameObject) 
    UIUtil.RemoveClickEvent(self.m_rightBuyBtnTr.gameObject) 
    UIUtil.RemoveClickEvent(self.m_rightGetAwardBtnTr.gameObject) 
    UIUtil.RemoveClickEvent(self.m_leftGetAwardBtnTr.gameObject) 
    UIUtil.RemoveClickEvent(self.m_backBtnTr.gameObject) 

    base.OnDestroy(self)
end

return YueKaView