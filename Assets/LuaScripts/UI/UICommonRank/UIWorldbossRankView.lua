local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local UIUtil = UIUtil
local table_insert = table.insert
local table_sort = table.sort
local Vector2 = Vector2
local CommonDefine = CommonDefine
local Language = Language
local UICommonRankView = require "UI.UICommonRank.UICommonRankView"
local UIWorldbossRankView = BaseClass("UIWorldbossRankView", UICommonRankView)
local base = UICommonRankView
local UIWindowNames = UIWindowNames
local LoopScrollView = LoopScrowView
local Vector3 = Vector3
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()

function UIWorldbossRankView:OnCreate()
    base.OnCreate(self)
    self.m_cur = 1    
end

function UIWorldbossRankView:InitView()
    local todayText, yestodayText = UIUtil.GetChildTexts(self.transform, {
        "worldbossBg/todaytext", "worldbossBg/yestodaytext",
    })

    todayText.text = Language.GetString(2115)
    yestodayText.text = Language.GetString(2116)

    self.m_todayBtn, self.m_yestodayBtn, self.m_todayImg, self.m_yestodayImg = UIUtil.GetChildTransforms(self.transform, {
        "worldbossBg/todayBtn",
        "worldbossBg/yestodayBtn",
        "worldbossBg/todayBtn/img",
        "worldbossBg/yestodayBtn/img",
    })

    self.m_itemScrollView = GetChildRectTrans(self.transform, {
        "middle/ItemScrollView"
    })    

    base.InitView(self)
end

function UIWorldbossRankView:FindConfig()
    self.m_rankCfg = { 
        columnLangs = { 2101, 2102, 2113, 2114, 2104 },
        titleLang = 2112,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    }
end

function UIWorldbossRankView:LayoutByRankType()
    self.m_worldBossRoot.gameObject:SetActive(true)
    self.m_middleTr.localPosition = Vector3.New(0, -71, 0)

    local lp = self.m_itemScrollView.localPosition
    self.m_itemScrollView.localPosition = Vector3.New(lp.x, 24, lp.z)
    local sizeDelta = self.m_itemScrollView.sizeDelta
    self.m_itemScrollView.sizeDelta = Vector2.New(sizeDelta.x, 412.8)
    
    self.m_cur = 1
    self:ActiveTab(1)
    self:ReleaseList()
end

function UIWorldbossRankView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
   
    UIUtil.AddClickEvent(self.m_todayBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_yestodayBtn.gameObject, onClick)

    base.HandleClick(self)
end

function UIWorldbossRankView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_todayBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_yestodayBtn.gameObject)

    base.RemoveClick(self)
end

function UIWorldbossRankView:OnClick(go)

    -- print(' on click ', go.name)

    local btn = go.name
    if btn == "todayBtn" then
        self:OnChgTab(1)
    elseif btn == "yestodayBtn" then
        self:OnChgTab(2)
    else
        base.OnClick(self, go)
    end
end

function UIWorldbossRankView:ReleaseList()
    if self.m_rankItemList then
        for i, v in ipairs(self.m_rankItemList) do
            v:Delete()
        end
        self.m_rankItemList = {}
    end

    if self.m_rankItemListSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_rankItemListSeq)
        self.m_rankItemListSeq = 0
    end
end

function UIWorldbossRankView:OnChgTab(tab)
    if tab == self.m_cur then
        return
    end

    self.m_cur = tab

    if tab == 1 then
        self:ActiveTab(1)
        self:ReleaseList()
        self.m_rankType = CommonDefine.COMMONRANK_WORLDBOSS_TODAY
        Player:GetInstance():GetCommonRankMgr():ReqRank(CommonDefine.COMMONRANK_WORLDBOSS_TODAY)
        
    elseif tab == 2 then
        self:ActiveTab(2)
        self:ReleaseList()
        self.m_rankType = CommonDefine.COMMONRANK_WORLDBOSS_YESTODAY
        Player:GetInstance():GetCommonRankMgr():ReqRank(CommonDefine.COMMONRANK_WORLDBOSS_YESTODAY)
    end
end

function UIWorldbossRankView:ActiveTab(tab)
    if tab == 1 then
        self.m_todayImg.gameObject:SetActive(true)
        self.m_yestodayImg.gameObject:SetActive(false)
    else
        self.m_todayImg.gameObject:SetActive(false)
        self.m_yestodayImg.gameObject:SetActive(true)
    end
end

return UIWorldbossRankView