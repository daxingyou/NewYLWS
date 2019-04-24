local UIUtil = UIUtil
local ConfigUtil = ConfigUtil
local table_insert = table.insert
local table_remove = table.remove
local GameObject = CS.UnityEngine.GameObject
local SplitString = CUtil.SplitString
local Language = Language

local UIWuJiangCardItem = require "UI.UIWuJiang.View.UIWuJiangCardItem"
local CardItemPath = TheGameIds.CommonWujiangCardPrefab
local UIMutiLinpupView = BaseClass("UIMutiLinpupView", UIBaseView)
local base = UIBaseView

local WuJiangMgr = Player:GetInstance().WujiangMgr

function UIMutiLinpupView:OnCreate()
    base.OnCreate(self)
  
    self.m_seq = 0
    self.m_buzhenList = false
    self.m_wujiang_card_list = {}
    self.m_placeHolderItemList = {}

    local lineupItem, lineupItem2, lineupItem3
    self.m_itemParent, self.m_closeBtn, self.bgTrans, self.m_placeHolderItemPrefab,
    lineupItem, lineupItem2, lineupItem3 = UIUtil.GetChildTransforms(self.transform, {
        "bg/ItemGrid",
        "CloseBtn",
        "bg",
        "placeHolderItemPrefab",
        "bg/lineupItem",
        "bg/lineupItem2",
        "bg/lineupItem3"
    })

    self.m_lineupItemList = { lineupItem, lineupItem2, lineupItem3 }

    local lineupItemText, lineupItemText2, lineupItemText3
    = UIUtil.GetChildTexts(self.transform, {
        "bg/lineupItem/lineupText",
        "bg/lineupItem2/lineup2Text",
        "bg/lineupItem3/lineup3Text"
    })

    self.m_lineupNames = SplitString(Language.GetString(2336), '|')
    self.m_lineupNameTextList = { lineupItemText, lineupItemText2, lineupItemText3 }

    self.m_placeHolderItemPrefab = self.m_placeHolderItemPrefab.gameObject
    self.m_bgRT = UIUtil.FindComponent(self.bgTrans, typeof(CS.UnityEngine.RectTransform))
end

function UIMutiLinpupView:OnEnable(...)
    base.OnEnable(self, ...)
    local _, buzhenList = ...

    if not buzhenList then
        return
    end

    self.m_buzhenList = buzhenList

    local buzhenCount = #buzhenList
    local sizeHeight = 250 + (233 * (buzhenCount - 1))
    self.m_bgRT.sizeDelta = Vector2.New(880, sizeHeight)

    self:UpdateLineupTitle()
    self:CheckBuzhenList()
    self:HandleClick()
end

function UIMutiLinpupView:OnDisable()
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0

    for _,item in ipairs(self.m_wujiang_card_list) do
        item:Delete()
    end
    self.m_wujiang_card_list = {}

    for _,item in ipairs(self.m_placeHolderItemList) do
        GameObject.DestroyImmediate(item)
    end
    self.m_placeHolderItemList = {}

    self:RemoveClick()
    base.OnDisable(self)
end

function UIMutiLinpupView:OnClick(go, x, y)
    self:CloseSelf()
end

function UIMutiLinpupView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
   
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
end

function UIMutiLinpupView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
end

function UIMutiLinpupView:CreateWuJiangItemList(buzhenData)
    local wujiang_list = buzhenData.wujiang_list
    if not wujiang_list then
        return
    end

    function localCallBack()
        local placeHolderCount = 5 - #wujiang_list
        for i = 1, placeHolderCount do
            local go = GameObject.Instantiate(self.m_placeHolderItemPrefab, self.m_itemParent)
            table_insert(self.m_placeHolderItemList, go)
        end

        self:CheckBuzhenList()
    end

    self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObjects(self.m_seq, CardItemPath, #wujiang_list, function(objs)
        self.m_seq = 0
        if objs then
            for i = 1, #objs do
                local cardItem = UIWuJiangCardItem.New(objs[i], self.m_itemParent, CardItemPath)
                cardItem:SetData(wujiang_list[i])
                table_insert(self.m_wujiang_card_list, cardItem)
            end

            localCallBack()
        end
    end)
end

function UIMutiLinpupView:CheckBuzhenList()
    if #self.m_buzhenList > 0 then
        local buzhenData = self.m_buzhenList[1]
        table_remove(self.m_buzhenList, 1)
        self:CreateWuJiangItemList(buzhenData)
    end
end

function UIMutiLinpupView:UpdateLineupTitle()
    for i = 1, #self.m_lineupItemList do
        local isShow = self.m_buzhenList[i] ~= nil
        self.m_lineupItemList[i].gameObject:SetActive(isShow)

        if isShow then
            local buzhenIndex = self.m_buzhenList[i].buzhen_id % 10000 -- 10001
            if buzhenIndex > 0 and buzhenIndex <= #self.m_lineupNames then
                self.m_lineupNameTextList[i].text = self.m_lineupNames[buzhenIndex]
            end
        end
    end
end


return UIMutiLinpupView