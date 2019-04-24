local UIUtil = UIUtil
local table_insert = table.insert
local CommonDefine = CommonDefine
local UIManagerInstance = UIManagerInst
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local LineupWuJiangCardItem = require("UI.UIWuJiang.View.LineupWuJiangCardItem")
local WuJiangItemPath = TheGameIds.CommonWujiangCardPrefab

local UICheckLineupView = BaseClass("UICheckLineupView", UIBaseView)
local base = UIBaseView

function UICheckLineupView:OnCreate()
    base.OnCreate(self)

    self:InitView()

    self:HandleClick()
end

function UICheckLineupView:InitView()
    self.m_blackBgTrans, self.m_wujiangItemGridTrans, self.m_winPanelTrans = UIUtil.GetChildRectTrans(self.transform, {
        "blackBg",
        "winPanel/wujiangItemGrid",
        "winPanel"
    })

    self.m_rivalInfo = {}
    self.m_lineupWuJiangItemSeq = 0
    self.m_lineupWuJiangItemList = {}
end

function UICheckLineupView:OnDestroy()

    UIUtil.RemoveClickEvent(self.m_blackBgTrans.gameObject)

    self.m_blackBgTrans = nil
    self.m_wujiangItemGridTrans = nil
    self.m_winPanelTrans = nil
    
    self:RecycleLineupWuJiangItemList()
    self.m_lineupWuJiangItemList = nil

    base.OnDestroy(self)
end

function UICheckLineupView:OnEnable(initOrder, ...)
    base.OnEnable(self)

    local targetPos = nil
    self.m_rivalInfo, targetPos = ...

    if targetPos then
        local invPos = self.transform:InverseTransformPoint(targetPos)
        local localPos = self.m_winPanelTrans.localPosition
        localPos.y = invPos.y
        self.m_winPanelTrans.localPosition = localPos
    end
    self:UpdatePanel()
end

function UICheckLineupView:OnDisable()
    self.m_rivalInfo = nil
    self:RecycleLineupWuJiangItemList()

    base.OnDisable(self)
end

function UICheckLineupView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)

    UIUtil.AddClickEvent(self.m_blackBgTrans.gameObject, onClick)
end

function UICheckLineupView:OnClick(go, x, y)
    if not go then
        return
    end
    local goName = go.name
    if goName == "blackBg" then
        UIManagerInstance:CloseWindow(UIWindowNames.UICheckLineup)
    end
end

function UICheckLineupView:UpdatePanel()
    if not self.m_rivalInfo then
        return
    end
    --更新武将item
    self:RecycleLineupWuJiangItemList()
    if #self.m_lineupWuJiangItemList == 0 then
        self.m_lineupWuJiangItemSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObjects(self.m_lineupWuJiangItemSeq, WuJiangItemPath, CommonDefine.LINEUP_WUJIANG_COUNT,
        function(objs)
            self.m_lineupWuJiangItemSeq = 0
            if not objs then
                return
            end
            for i = 1, #objs do
                objs[i].name = "lineupItem_"..i
                local wujiangItem = LineupWuJiangCardItem.New(objs[i], self.m_wujiangItemGridTrans, WuJiangItemPath)
                table_insert(self.m_lineupWuJiangItemList, wujiangItem)
            end

            self:UpdateLineupWuJiangItemList()
        end)
    else
        self:UpdateLineupWuJiangItemList()
    end
end

--更新武将item的UI信息
function UICheckLineupView:UpdateLineupWuJiangItemList()
    local wujiangInfoList = {}
    local defendWujiangList = self.m_rivalInfo.def_wujiang_list
    if defendWujiangList then
        for _, defendWujiangInfo in pairs(defendWujiangList) do
            if defendWujiangInfo then
                wujiangInfoList[defendWujiangInfo.pos] = defendWujiangInfo
            end
        end
    end

    for i = 1, #self.m_lineupWuJiangItemList do
        local wujiangItem = self.m_lineupWuJiangItemList[i]
        if wujiangItem then
            local wujiangInfo = wujiangInfoList[i]
            if wujiangInfo then
                wujiangItem:SetDefendData(wujiangInfo)
                wujiangItem:SetNameActive(true)
            else
                wujiangItem:HideAll()
            end
        end
    end
end

function UICheckLineupView:RecycleLineupWuJiangItemList()
    if self.m_rankAwardItemSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_lineupWuJiangItemSeq)
        self.m_lineupWuJiangItemSeq = 0
    end

    for i = 1, #self.m_lineupWuJiangItemList do
        self.m_lineupWuJiangItemList[i]:Delete()
    end
    self.m_lineupWuJiangItemList = {}
end

return UICheckLineupView