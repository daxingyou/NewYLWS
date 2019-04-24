
local UIGodBeastView = BaseClass("UIGodBeastView", UIBaseView)
local base = UIBaseView

local GodBeastMgr = Player:GetInstance():GetGodBeastMgr()
local table_insert = table.insert
local GameObject = CS.UnityEngine.GameObject
local DOTween = CS.DOTween.DOTween
local DOTweenSettings = CS.DOTween.DOTweenSettings
local GodBeastItem = require "UI.UIGodBeast.View.GodBeastItem"
local GODBEAST_ID = {1003601, 1003603, 1003602, 1003606}

function UIGodBeastView:OnCreate()
    base.OnCreate(self)

    self.m_godBeastItemList = {}

    self:InitView()
end

function UIGodBeastView:InitView()
    self.m_godBeastItemPrefab, self.m_backBtn, self.m_itemContentTran, self.m_container = UIUtil.GetChildRectTrans(self.transform, {
        "GodBeastItemPrefab",
        "Panel/BackBtn",
        "Container/ItemContent",
        "Container",
    })
    
    self.m_godBeastItemPrefab = self.m_godBeastItemPrefab.gameObject

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
end

function UIGodBeastView:OnClick(go, x, y)
    if go.name == "BackBtn" then
        self:CloseSelf()
    end
end

function UIGodBeastView:OnEnable(...)
    base.OnEnable(self, ...)
    self:UpdateView()
    self:TweenOpen()
end

function UIGodBeastView:UpdateView()
    for i=1, #GODBEAST_ID do
        local godBeastItem = self.m_godBeastItemList[i]
        if godBeastItem == nil then
            local go = GameObject.Instantiate(self.m_godBeastItemPrefab)
            godBeastItem = GodBeastItem.New(go, self.m_itemContentTran)
            table_insert(self.m_godBeastItemList, godBeastItem)
        end
        godBeastItem:UpdateData(i, GODBEAST_ID[i])
    end
end

function UIGodBeastView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    for i, v in ipairs(self.m_godBeastItemList) do 
        v:Delete()
    end
    self.m_godBeastItemList = nil

    base.OnDestroy(self)
end


function UIGodBeastView:OnAddListener()
	base.OnAddListener(self)
end

function UIGodBeastView:OnRemoveListener()
	base.OnRemoveListener(self)
end

function UIGodBeastView:TweenOpen()
    local tweener = DOTween.ToFloatValue(function() return 0 end, function(value)
        self.m_backBtn.anchoredPosition = Vector3.New(236, -46.5 + 150 - 150 * value, 0)
        self.m_container.anchoredPosition = Vector3.New(0, -800 + 800 * value, 0)
    end, 1, 0.3)
    DOTweenSettings.OnComplete(tweener, function()
        TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
    end)
end

return UIGodBeastView