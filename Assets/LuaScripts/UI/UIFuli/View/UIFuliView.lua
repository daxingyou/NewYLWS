local table_insert = table.insert
local table_sort = table.sort
local string_trim = string.trim
local string_find = string.find
local string_sub = string.sub
local string_format = string.format
local math_ceil = math.ceil
local GameObject = CS.UnityEngine.GameObject
local Type_Toggle = typeof(CS.UnityEngine.UI.Toggle)
local AtlasConfig = AtlasConfig
local Language = Language
local CommonDefine = CommonDefine
local ConfigUtil = ConfigUtil
local FuliMgr = Player:GetInstance():GetFuliMgr()
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()

local DetailQiandaoHelperClass = require "UI.UIFuli.View.DetailQiandaoHelper"
local DetailGetStamainHelperClass = require "UI.UIFuli.View.DetailGetStamainHelper"
local DetailCDKeyHelperClass = require "UI.UIFuli.View.DetailCDKeyHelper"
local DetailFundHelperClass = require "UI.UIFuli.View.DetailFundHelper"
local DetailWelfareHelperClass = require "UI.UIFuli.View.DetailWelfareHelper"
local WelfareItemPrefabPath = "UI/Prefabs/Fuli/WelfareItem.prefab"
local WelfareItemClass = require("UI.UIFuli.View.WelfareItem")

local UIFuliView = BaseClass("UIFuliView", UIBaseView)
local base = UIBaseView

local tabBtnName = "TabBtn_"

function UIFuliView:OnCreate()
    base.OnCreate(self)

    self.m_welfareItemList = {}
    self.m_seq = 0 
    
    self:InitView()
end

function UIFuliView:InitView()
    local titleText = UIUtil.GetChildTexts(self.transform, {
        "Container/Fuli/bg/title/Text",
    })

    self.m_backBtn, self.m_tagItemContentTr, self.m_tagItemTr, self.m_contentTr = UIUtil.GetChildTransforms(self.transform, {
        "backBtn",
        "Container/Fuli/bg/TagItemScrollView/Viewport/ItemContent",
        "Container/Fuli/bg/tagItem",
        "Container/Fuli/bg/RightContainer/Welfare/ItemScrollView/Viewport/ItemContent"
    }) 

    self.m_tagItemPrefab = self.m_tagItemTr.gameObject
    titleText.text = Language.GetString(3430)

    self.m_tabBtnToggleList = {}
    self.m_currItemType = CommonDefine.FuliType_Qiandao
    self.m_tabBtnList = {}
    self.m_tabBtnRedPointTrList = {}

    self.m_loopScrollView = self:AddComponent(LoopScrowView, "Container/Fuli/bg/RightContainer/Welfare/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateItem))
    
    local defaultHelper = DetailQiandaoHelperClass.New(self.transform, self)
    self.m_detailHelpers = {
        [CommonDefine.FuliType_Qiandao] = defaultHelper,
        [CommonDefine.FuliType_Online] = DetailWelfareHelperClass.New(self.transform, self),
        [CommonDefine.FuliType_GetStamain] = DetailGetStamainHelperClass.New(self.transform, self),
        [CommonDefine.FuliType_Regist] = DetailWelfareHelperClass.New(self.transform, self),
        [CommonDefine.FuliType_LevelUp] = DetailWelfareHelperClass.New(self.transform, self),
        [CommonDefine.FuliType_CDKey] = DetailCDKeyHelperClass.New(self.transform, self),
        [CommonDefine.FuliType_Fund] = DetailFundHelperClass.New(self.transform, self),
    }


    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
end

function UIFuliView:OnAddListener()
    base.OnAddListener(self)

    self:AddUIListener(UIMessageNames.MN_FULI_RSP_FULI_LIST, self.RspFuliList)
    self:AddUIListener(UIMessageNames.MN_FULI_RSP_GET_FULI_AWARD, self.RspGetFuliAward)
    self:AddUIListener(UIMessageNames.MN_FULI_RSP_BUY_FUND, self.RspBuyFund)
    self:AddUIListener(UIMessageNames.MN_FULI_NTF_FULI_CHG, self.NtfFuliChg)
    self:AddUIListener(UIMessageNames.MN_FULI_FUND_BUY_BTN_CLICK, self.UpdateFundRedPointStatus)  
end

function UIFuliView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_FULI_RSP_FULI_LIST, self.RspFuliList)
    self:RemoveUIListener(UIMessageNames.MN_FULI_RSP_GET_FULI_AWARD, self.RspGetFuliAward)
    self:RemoveUIListener(UIMessageNames.MN_FULI_RSP_BUY_FUND, self.RspBuyFund)
    self:RemoveUIListener(UIMessageNames.MN_FULI_NTF_FULI_CHG, self.NtfFuliChg)
    self:RemoveUIListener(UIMessageNames.MN_FULI_FUND_BUY_BTN_CLICK, self.UpdateFundRedPointStatus)  
    
    base.OnRemoveListener(self)
end

function UIFuliView:NtfFuliChg(msg)

    for i, v in ipairs(self.m_welfareItemList) do
        if v:GetFuliID() == msg.fuli_id then
            v:UpdateData(msg.entry_list[v:GetIndex()], msg.fuli_id)
        end
    end

end

function UIFuliView:RspBuyFund()
    self:ChgDetailShowState(true)
end

function UIFuliView:RspGetFuliAward(awardList)
    if not awardList then
        return
    end
    
    self:ChgDetailShowState(true)
        
    local uiData = {
        titleMsg = Language.GetString(64),
        openType = 1,
        awardDataList = awardList,
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
    self:UpdateRedPointStatus()
end

function UIFuliView:HandleToggleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    for _,tabBtnToggle in pairs(self.m_tabBtnToggleList) do
        if tabBtnToggle then
            local tabBtn = tabBtnToggle.gameObject
            if tabBtn then
                UIUtil.AddClickEvent(tabBtn, onClick)
            end
        end
    end
end

function UIFuliView:RemoveToggleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    for _,tabBtnToggle in pairs(self.m_tabBtnToggleList) do
        if tabBtnToggle then
            local tabBtn = tabBtnToggle.gameObject
            if tabBtn then
                UIUtil.RemoveClickEvent(tabBtn, onClick)
            end
        end
    end
end

function UIFuliView:OnEnable(...)
    base.OnEnable(self, ...)
    
    for _, helper in pairs(self.m_detailHelpers) do
        helper:Close()
    end

    self.m_currItemType = CommonDefine.FuliType_Qiandao
end

function UIFuliView:OnTweenOpenComplete()
    FuliMgr:ReqFuliList()
end

function UIFuliView:RspFuliList()
    local fuliList = FuliMgr.FuliList

    table_sort(fuliList, function(l, r)
        return l.fuli_id < r.fuli_id
    end)
    
    for i, v in ipairs(fuliList) do
        local fuliCfg = ConfigUtil.GetFuliCfgByID(v.fuli_id)
        local tabBtn = self.m_tabBtnList[v.fuli_id]
        if not tabBtn then
            tabBtn = GameObject.Instantiate(self.m_tagItemPrefab)
            tabBtn.name = tabBtnName..math_ceil(v.fuli_id)
            local tabBtnTr = tabBtn.transform
            tabBtnTr:SetParent(self.m_tagItemContentTr)
            tabBtnTr.localScale = Vector3.one
            tabBtnTr.localPosition = Vector3.zero
            local toggle = tabBtn:GetComponent(Type_Toggle)
            if toggle then
                self.m_tabBtnToggleList[v.fuli_id] = toggle
            end
            local tabBtnText = UIUtil.GetChildTexts(tabBtnTr, {"Text"})
            if not IsNull(tabBtnText) and fuliCfg then
                tabBtnText.text = fuliCfg.name
            end
            
            self.m_tabBtnList[v.fuli_id] = tabBtn

            local redPointImgTr = UIUtil.GetChildTransforms(tabBtnTr, {"RedPointImg"})
            redPointImgTr.gameObject:SetActive(false)
            self.m_tabBtnRedPointTrList[v.fuli_id] = redPointImgTr
        end
    end
    self:ChgDetailShowState(true, true)
    self:HandleToggleClick()
    self:UpdateRedPointStatus()
end

function UIFuliView:OnClick(go) 
    local goName = go.name
    if go.name == "backBtn" then
        self:CloseSelf()
    elseif string_find(goName, tabBtnName) then
        local startIndex, endIndex = string_find(goName, tabBtnName)
        local itemTypeStr = string_sub(goName, endIndex + 1, #goName)
        local itemType = tonumber(itemTypeStr)

        if itemType ~= self.m_currItemType then
            self:ChgDetailShowState(false)
            self.m_currItemType = itemType
        end
        self:ChgDetailShowState(true, true)
    end

    self:UpdateRedPointStatus()
end

function UIFuliView:ChgDetailShowState(show, isReset)
    self:UpdateTabBtn()
    if show then
        self:UpdateDetail(isReset)
    else
        local helper = self:GetDetailHelper()
        if helper then
            helper:Close()
        end
    end

end

function UIFuliView:UpdateDetail(isReset)
    local helper = self:GetDetailHelper()
    if helper then
        helper:UpdateInfo(isReset)
    end
end

function UIFuliView:UpdateTabBtn()
    local tabBtnToggle = self.m_tabBtnToggleList[self.m_currItemType]
    if tabBtnToggle then
        tabBtnToggle.isOn = true
    end
end

function UIFuliView:UpdateItem(item, realIndex)
    local oneFuli = self:GetOneFuli()
    if oneFuli.entry_list then
        if item and realIndex > 0 and realIndex <= #oneFuli.entry_list then
            local data = oneFuli.entry_list[realIndex]
            item:UpdateData(data, self:GetFuliId())
        end
    end
end

function UIFuliView:UpdateScrollView(isReset)
    local oneFuli = self:GetOneFuli()
    if not oneFuli then
        return
    end

    UIGameObjectLoaderInstance:CancelLoad(self.m_seq)
    self.m_seq = 0
    for i, v in ipairs(self.m_welfareItemList) do
        v:Delete()
    end
    self.m_welfareItemList = {}
    if #self.m_welfareItemList == 0 and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoaderInstance:PrepareOneSeq()
        UIGameObjectLoaderInstance:GetGameObjects(self.m_seq, WelfareItemPrefabPath, 7, function(objs)
            self.m_seq = 0 
            if objs then
                for i = 1, #objs do
                    local welfareItem = WelfareItemClass.New(objs[i], self.m_contentTr, WelfareItemPrefabPath)
                    table_insert(self.m_welfareItemList, welfareItem)
                end
            end
            self.m_loopScrollView:UpdateView(true, self.m_welfareItemList, oneFuli.entry_list)
        end)
    end
    
end

function UIFuliView:GetOneFuli()
    local fuliList = FuliMgr.FuliList

    for i, v in ipairs(fuliList) do
        if math_ceil(v.fuli_id) == self.m_currItemType then
            return v
        end
    end
    return nil
end

function UIFuliView:GetTitleName()
    local fuliCfg = ConfigUtil.GetFuliCfgByID(self.m_currItemType)
    if self.m_currItemType == CommonDefine.FuliType_Qiandao then
        return string_format(Language.GetString(3431), os.date("%m", Player:GetInstance():GetServerTime()))
    else
        return fuliCfg.name
    end
end

function UIFuliView:GetFuliId()
    return self.m_currItemType
end

function UIFuliView:GetDetailHelper()
    return self.m_detailHelpers[self.m_currItemType]
end 

function UIFuliView:UpdateRedPointStatus()
    local fuliList = FuliMgr.FuliList
    for k, v in ipairs(fuliList) do 
        local redPointImgTr = self.m_tabBtnRedPointTrList[v.fuli_id]
        if redPointImgTr then
            local entry_list = v.entry_list
            local status = false
            for k1, v1 in ipairs(entry_list) do
                if v1.status == 1 then
                    status = true
                end
            end
            if v.fuli_id == CommonDefine.FuliType_Fund then
                if FuliMgr:GetFundRedPointStatus() then
                    status = true
                end
            end
            redPointImgTr.gameObject:SetActive(status)
        end
    end 
end

function UIFuliView:UpdateFundRedPointStatus()
    FuliMgr:SetFundRedPointStatus()
    self:UpdateRedPointStatus()
end

function UIFuliView:OnDisable(...)
    UIGameObjectLoaderInstance:CancelLoad(self.m_seq)
    self.m_seq = 0

    for i, v in ipairs(self.m_welfareItemList) do
        v:Delete()
    end
    self.m_welfareItemList = {}
   
    for _, v in pairs(self.m_tabBtnList) do
        GameObject.Destroy(v)
    end
    self.m_tabBtnList = {}

    local helper = self.m_detailHelpers[self.m_currItemType]
    if helper then
        helper:Close()
    end
    
    self.m_currItemType = nil
    self.m_tabBtnToggleList = {}
    self:RemoveToggleClick()
    base.OnDisable(self)
end

function UIFuliView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    for _, helper in pairs(self.m_detailHelpers) do
        if helper then
            helper:Delete()
        end
    end

    self.m_detailHelpers = nil
    base.OnDestroy(self)
end

return UIFuliView