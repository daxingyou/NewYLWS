local table_insert = table.insert
local wujiangMgr = Player:GetInstance():GetWujiangMgr()
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()

local WujiangRankItemPrefab = "UI/Prefabs/CommonRanks/UIWuJiangRankItem.prefab"
local UIWuJiangRankItemClass = require "UI.UIWuJiang.View.UIWuJiangRankItem"
local LoopScrollView = LoopScrowView

local UIWuJiangRankView = BaseClass("UIWuJiangRankView", UIBaseView)
local base = UIBaseView


function UIWuJiangRankView:OnCreate()
    base.OnCreate(self) 
    self.m_itemLoaderSeq = 0 
    self.m_itemList = {}
    self.m_selfRankItem = nil
    self.m_selfRankSeq = 0

    self.m_localPos = nil 
    self.m_wujiangIndex = 0

    self:InitView()
    self:HandleClick()
end

function UIWuJiangRankView:InitView()
    local titleTxt, titleTxt1, titleTxt2, titleTxt3, titleTxt4
    titleTxt,
    titleTxt1, 
    titleTxt2, 
    titleTxt3, 
    titleTxt4 = UIUtil.GetChildTexts(self.transform, {
        "Panel/Top/TitleBg/TitleTxt",
        "Panel/Middle/ColumnTitles/TitleTxt1",
        "Panel/Middle/ColumnTitles/TitleTxt2",
        "Panel/Middle/ColumnTitles/TitleTxt3",
        "Panel/Middle/ColumnTitles/TitleTxt4",
    })

    titleTxt.text = Language.GetString(2123)
    titleTxt1.text = Language.GetString(2101)
    titleTxt2.text = Language.GetString(2125) 
    titleTxt3.text = Language.GetString(2124) 
    titleTxt4.text = Language.GetString(2104)

    self.m_backBtnTr,
    self.m_closeBtnTr,
    self.m_ruleBtnTr,
    self.m_itemContentTr,
    self.m_mineTr,
    self.m_panelTr = UIUtil.GetChildTransforms(self.transform, {
        "BlackBg",
        "Panel/Top/CloseBtn",
        "Panel/Top/RuleBtn",
        "Panel/Middle/ItemScrollView/Viewport/ItemContent",
        "Panel/Bottom/SelfItem",
        "Panel",
    })  

    self.m_itemLoopScrollView = self:AddComponent(LoopScrollView, "Panel/Middle/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateRankItem), false)
end

function UIWuJiangRankView:OnEnable(...)
    base.OnEnable(self, ...)
    _, self.m_localPos, curWuJiangData = ... 
    local wujiang_id = curWuJiangData.id 
    if not wujiang_id then
        return
    end 
    self.m_rankType = 100000 + wujiang_id
    self.m_wujiangIndex = curWuJiangData.index
    Player:GetInstance():GetCommonRankMgr():ReqRank(self.m_rankType, self.m_wujiangIndex)
end 

function UIWuJiangRankView:OnRankBuZhen(wujiangList)
    UIManagerInst:OpenWindow(UIWindowNames.UILineupWujiangBrief, wujiangList)
end

function UIWuJiangRankView:OnRankInfo(rank_type) 
    if rank_type ~= self.m_rankType then
        return
    end
    self.m_rankCache = Player:GetInstance():GetCommonRankMgr():GetRankCache(self.m_rankType)
    self:UpdateRankData()
    self:UpdateSelfItem()
end

function UIWuJiangRankView:UpdateRankData() 
    if not self.m_rankCache then 
        return
    end   
    local rank_list = self.m_rankCache.rank_list or {} 
    if #self.m_itemList <= 0 then
        self.m_itemLoaderSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObjects(self.m_itemLoaderSeq, WujiangRankItemPrefab, 10, function(objs)
            self.m_itemLoaderSeq = 0
            if objs then
                for i = 1, #objs do
                    local item = UIWuJiangRankItemClass.New(objs[i], self.m_itemContentTr, WujiangRankItemPrefab)
                    table_insert(self.m_itemList, item)
                end
            end
            self.m_itemLoopScrollView:UpdateView(true, self.m_itemList, rank_list)
        end)
    else
        self.m_itemLoopScrollView:UpdateView(true, self.m_itemList, rank_list)
    end

    -- if self.m_localPos then
    --     self.m_panelTr.localPosition = self.m_localPos + Vector2.New(200, 0) 
    -- end
end

function UIWuJiangRankView:UpdateRankItem(item, realIndex)
    if not item or not self.m_rankCache or realIndex < 1 or realIndex > #self.m_rankCache.rank_list then
        return
    end
    if realIndex > #self.m_rankCache.rank_list then
        return
    end 
    item:UpdateData(self.m_rankType, self.m_rankCache.rank_list[realIndex], false, 0)
end

function UIWuJiangRankView:UpdateSelfItem()  
    if self.m_selfRankItem then 
        local myRankInfo = Player:GetInstance():GetCommonRankMgr():GetMyCommonRank(self.m_rankType)
        if myRankInfo then
            self.m_selfRankItem:UpdateData(self.m_rankType, myRankInfo, true, self.m_wujiangIndex)   
        end 
    else 
        self.m_selfRankSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObject(self.m_selfRankSeq, WujiangRankItemPrefab, function(obj) 
            self.m_selfRankSeq = 0
            if not obj then
                return
            end  
            self.m_selfRankItem = UIWuJiangRankItemClass.New(obj, self.m_mineTr, WujiangRankItemPrefab)
            if self.m_selfRankItem then
                local myRankInfo = Player:GetInstance():GetCommonRankMgr():GetMyCommonRank(self.m_rankType) 
                if myRankInfo then
                    self.m_selfRankItem:UpdateData(self.m_rankType, myRankInfo, true, self.m_wujiangIndex)
                end
            end
        end)
    end
end

function UIWuJiangRankView:OnAddListener()
	base.OnAddListener(self)  
    self:AddUIListener(UIMessageNames.MN_COMMONRANK_INFO, self.OnRankInfo) 
    self:AddUIListener(UIMessageNames.MN_COMMONRANK_REQ_BUZHEN, self.OnRankBuZhen) 
end

function UIWuJiangRankView:OnRemoveListener()
	base.OnRemoveListener(self) 
    self:RemoveUIListener(UIMessageNames.MN_COMMONRANK_INFO, self.OnRankInfo) 
    self:RemoveUIListener(UIMessageNames.MN_COMMONRANK_REQ_BUZHEN, self.OnRankBuZhen)
end 

function UIWuJiangRankView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtnTr.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_closeBtnTr.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_ruleBtnTr.gameObject, onClick) 
end 

function UIWuJiangRankView:OnClick(go)
    if go.name == "BlackBg" or go.name == "CloseBtn" then
        self:CloseSelf()
    elseif go.name == "RuleBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 102) 
    end
end 

function UIWuJiangRankView:OnDisable()
    UIGameObjectLoaderInst:CancelLoad(self.m_itemLoaderSeq)
    self.m_itemLoaderSeq = 0
    UIGameObjectLoaderInst:CancelLoad(self.m_selfRankSeq)
    self.m_selfRankSeq = 0

    if self.m_itemList then
        for i, v in ipairs(self.m_itemList) do
            v:Delete()
        end
        self.m_itemList = {}
    end

    if self.m_selfRankItem then
        self.m_selfRankItem:Delete()
        self.m_selfRankItem = nil
    end

    Player:GetInstance():GetCommonRankMgr():SetQueringBuZhen(false)
	base.OnDisable(self)
end

function UIWuJiangRankView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtnTr.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtnTr.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtnTr.gameObject) 

    base.OnDestroy(self)
end 


return UIWuJiangRankView