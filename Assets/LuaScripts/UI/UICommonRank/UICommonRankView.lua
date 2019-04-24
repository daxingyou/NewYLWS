local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local UIUtil = UIUtil
local table_insert = table.insert
local table_sort = table.sort
local CommonDefine = CommonDefine
local Language = Language
local UICommonRankView = BaseClass("UICommonRankView", UIBaseView)
local base = UIBaseView
local UIWindowNames = UIWindowNames
local LoopScrollView = LoopScrowView
local PBUtil = PBUtil
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()

local CommonRankCfg = {
    [CommonDefine.COMMONRANK_CAMPS] = { 
        columnLangs = { 2101, 2102, 2103, 2104 },
        titleLang = 2100,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
    [CommonDefine.COMMONRANK_GRAVECOPY] = { 
        columnLangs = { 2101, 2102, 2105, 2106, 2104 },
        titleLang = 2107,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
    [CommonDefine.COMMONRANK_ARENA] = { 
        columnLangs = { 2101, 2102, 2109, 2110, 2104 },
        titleLang = 2111,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
    [CommonDefine.COMMONRANK_WORLDBOSS_TODAY] = { 
        columnLangs = { 2101, 2102, 2113, 2114, 2104 },
        titleLang = 2112,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
    [CommonDefine.COMMONRANK_INSCRIPTIONCOPY] = { 
        columnLangs = { 2101, 2102, 2105, 2119, 2104 },
        titleLang = 2118,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
    [CommonDefine.COMMONRANK_YUANMEN] = { 
        columnLangs = { 2101, 2102, 2120, 2121, 2104 },
        titleLang = 2122,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
    [CommonDefine.COMMONRANK_QUNXIONGZHULU_CROSS] = { 
        columnLangs = { 3987, 3988, 3989, 3990, 3991 },
        titleLang = 3984,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
    [CommonDefine.COMMONRANK_QUNXIONGZHULU] = {
        columnLangs = { 3987, 3988, 3989, 3990, 3991 },
        titleLang = 3984,    
        prefab = "UI/Prefabs/CommonRanks/UICommonRankItem.prefab", 
        item = "UI.UICommonRank.UICommonRankItem",
    },
}

function UICommonRankView:OnCreate()
    base.OnCreate(self)
    self.m_rankItemListSeq = 0
    self.m_selfRankSeq = 0
    self.m_rankItemList = {}
    self.m_selfRankItem = nil

    self:InitView()
end

function UICommonRankView:InitView()
    self.m_titleText, self.m_colText1, self.m_colText2, self.m_colText3, self.m_colText4, self.m_colText5,
    self.m_colTextMid = 
    UIUtil.GetChildTexts(self.transform, {
        "topBg/titleBg/titleText",
        "middle/columnTitles/colText1", "middle/columnTitles/colText2", "middle/columnTitles/colText3",
        "middle/columnTitles/colText4", "middle/columnTitles/colText5", "middle/columnTitles/colTextMid",
    })

    self.m_middleTr, self.m_backBtn, self.m_closeBtn, self.m_itemGridTrans, self.m_selfItemTrans, self.m_worldBossRoot = 
    UIUtil.GetChildTransforms(self.transform, {
        "middle",
        "bg/blackBg", "topBg/closeBtn", 
        "middle/ItemScrollView/Viewport/ItemContent",
        "bottomContainer/selfItem",
        "worldbossBg"
    })

    self.m_loopScrollView = self:AddComponent(LoopScrollView, "middle/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateRankItem), false)

    self.m_itemList = {}
    self:HandleClick()
end

function UICommonRankView:OnAddListener()
	base.OnAddListener(self)
	-- UI消息注册
    self:AddUIListener(UIMessageNames.MN_COMMONRANK_INFO, self.OnRankInfo)
    self:AddUIListener(UIMessageNames.MN_COMMONRANK_REQ_BUZHEN, self.OnRankBuZhen) 
end

function UICommonRankView:OnRemoveListener()
	base.OnRemoveListener(self)
	-- UI消息注销
    self:RemoveUIListener(UIMessageNames.MN_COMMONRANK_INFO, self.OnRankInfo) 
    self:RemoveUIListener(UIMessageNames.MN_COMMONRANK_REQ_BUZHEN, self.OnRankBuZhen)
end

function UICommonRankView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
   
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick) 
end

function UICommonRankView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject) 
end 

function UICommonRankView:FindConfig()
    self.m_rankCfg = CommonRankCfg[self.m_rankType]
end

function UICommonRankView:OnEnable(...)
    base.OnEnable(self, ...)
    local order
    order, self.m_rankType = ...

    self:FindConfig()

    if not self.m_rankCfg then
        -- print(' error not rank cfg ', self.m_rankType, table.dump(CommonRankCfg))
        return
    end

    self.m_titleText.text = Language.GetString(self.m_rankCfg.titleLang)
    local colCount = #self.m_rankCfg.columnLangs
    if colCount == 5 then
        for i = 1, 5 do
            self['m_colText'..i].text = Language.GetString(self.m_rankCfg.columnLangs[i])
        end
        self.m_colTextMid.text = ''
    elseif colCount == 4 then
        self.m_colText1.text = Language.GetString(self.m_rankCfg.columnLangs[1])
        self.m_colText2.text = Language.GetString(self.m_rankCfg.columnLangs[2])
        self.m_colTextMid.text = Language.GetString(self.m_rankCfg.columnLangs[3])
        self.m_colText5.text = Language.GetString(self.m_rankCfg.columnLangs[4])
        
        self.m_colText3.text = ''
        self.m_colText4.text = ''
    end

    self:LayoutByRankType()  
    Player:GetInstance():GetCommonRankMgr():ReqRank(self.m_rankType)
end

function UICommonRankView:OnDisable()
    if self.m_rankItemList then
        for i, v in ipairs(self.m_rankItemList) do
            v:Delete()
        end
        self.m_rankItemList = {}
    end

    if self.m_selfRankItem then
        self.m_selfRankItem:Delete()
        self.m_selfRankItem = nil
    end

    self.m_rankCfg = nil
    self.m_rankCache = nil

    if self.m_rankItemListSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_rankItemListSeq)
        self.m_rankItemListSeq = 0
    end

    if self.m_selfRankSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_selfRankSeq)
        self.m_selfRankSeq = 0
    end 

    Player:GetInstance():GetCommonRankMgr():SetQueringBuZhen(false)
    base.OnDisable(self)
end

function UICommonRankView:OnDestroy()
    self:RemoveClick()

    if self.m_loopScrollView then
        self.m_loopScrollView:Delete()
        self.m_loopScrollView = nil
    end
    base.OnDestroy(self)
end

function UICommonRankView:LayoutByRankType()
    self.m_worldBossRoot.gameObject:SetActive(false)
    self.m_middleTr.localPosition = Vector3.zero
end

function UICommonRankView:OnRankBuZhen(wujiangList)
    UIManagerInst:OpenWindow(UIWindowNames.UILineupWujiangBrief, wujiangList)
end

function UICommonRankView:OnRankInfo(ranktype)
    if ranktype ~= self.m_rankType then
        return
    end
    
    self.m_rankCache = Player:GetInstance():GetCommonRankMgr():GetRankCache(self.m_rankType) 
    self:UpdateRankData()
    self:UpdateSelfRank()
end

function UICommonRankView:UpdateRankData()    
    if not self.m_rankCache then
        -- print(' ====== no rankList ', self.m_rankType)
        return
    end

    if #self.m_rankItemList == 0 then
        if self.m_rankItemListSeq == 0 then
            self.m_rankItemListSeq = UIGameObjectLoaderInst:PrepareOneSeq()

            local RankItemClass = require(self.m_rankCfg.item)

            UIGameObjectLoaderInst:GetGameObjects(self.m_rankItemListSeq, self.m_rankCfg.prefab, 10, function(objs)
                self.m_rankItemListSeq = 0
                if objs then
                    for i = 1, #objs do
                        local item = RankItemClass.New(objs[i], self.m_itemGridTrans, self.m_rankCfg.prefab)
                        if item then
                            table_insert(self.m_rankItemList, item)
                        end                        
                    end
                    self:ResetScrollView()
                end
            end)
        end
    else
        self:ResetScrollView()
    end
end

function UICommonRankView:UpdateRankItem(item, realIndex)
    if not item or not self.m_rankCache or realIndex < 1 or realIndex > #self.m_rankCache.rank_list then
        return
    end
    if realIndex > #self.m_rankCache.rank_list then
        return
    end
    item:UpdateData(self.m_rankType, self.m_rankCache.rank_list[realIndex])
end

--重置ItemScrollView
function UICommonRankView:ResetScrollView()
    self.m_loopScrollView:UpdateView(true, self.m_rankItemList, self.m_rankCache.rank_list)
end

function UICommonRankView:OnClick(go)
    if go.name == "blackBg" or go.name == "closeBtn" then
        self:CloseSelf() 
    end
end

function UICommonRankView:UpdateSelfRank()
    if self.m_selfRankItem then
        local myCommonRank = Player:GetInstance():GetCommonRankMgr():GetMyCommonRank(self.m_rankType)
        if myCommonRank then
            self.m_selfRankItem:UpdateData(self.m_rankType, myCommonRank, true)
        end
    else
        self.m_selfRankSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObject(self.m_selfRankSeq, self.m_rankCfg.prefab, function(obj)
            self.m_selfRankSeq = 0
            if not obj then
                return
            end

            local RankItemClass = require(self.m_rankCfg.item)
            self.m_selfRankItem = RankItemClass.New(obj, self.m_selfItemTrans, self.m_rankCfg.prefab)
            if self.m_selfRankItem then
                local myCommonRank = Player:GetInstance():GetCommonRankMgr():GetMyCommonRank(self.m_rankType)
                if myCommonRank then
                    self.m_selfRankItem:UpdateData(self.m_rankType, myCommonRank, true)
                end
            end
        end)
    end
end 

return UICommonRankView