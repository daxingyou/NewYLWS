local Language = Language
local Vector3 = Vector3
local UIWuJiangCardItem = require "UI.UIWuJiang.View.UIWuJiangCardItem"
local CardItemPath = TheGameIds.CommonWujiangCardPrefab
local EmployWujiangItem = BaseClass("EmployWujiangItem", UIBaseItem)
local base = UIBaseItem

function EmployWujiangItem:OnCreate()
    self.m_wujiangItem = nil
    self.m_seq = 0
    self.m_employWujiang = 0    
    self.m_leftEmployTimes = 0

    self.m_bgRoot, self.m_clickBtn = UIUtil.GetChildTransforms(self.transform, {
        "bg",
        "clickBtn",
    })

    self.m_nameText = UIUtil.GetChildTexts(self.transform, {
        "bg/nameText",
    })

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_clickBtn.gameObject, onClick)
end

function EmployWujiangItem:SetData(employBrief, leftEmployTimes)
    self.m_employWujiang = employBrief
    self.m_leftEmployTimes = leftEmployTimes
    self.m_nameText.text = string.format(Language.GetString(1113), employBrief.friendBriefData.name, employBrief.leftEmployTimes)
    if not self.m_wujiangItem and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, CardItemPath, function(go)
            self.m_seq = 0
            if not IsNull(go) then
                self.m_wujiangItem = UIWuJiangCardItem.New(go, self.m_bgRoot, CardItemPath)
                self.m_wujiangItem:SetAnchoredPosition(Vector3.New(105, -105, 0))
                self.m_wujiangItem:SetData(employBrief.wujiangBriefData, true)
            end
        end)
    else
        self.m_wujiangItem:SetData(employBrief.wujiangBriefData, true)
    end
end

function EmployWujiangItem:DoSelect(bSelect, isLineupIllegal)
    if self.m_wujiangItem then
        self.m_wujiangItem:DoSelect(bSelect)
        if bSelect then
            self.m_wujiangItem:SetIconColor(isLineupIllegal and Color.white or Color.red)
        end
    end
end

function EmployWujiangItem:OnClick(go, x, y)
    if go.name == "clickBtn" then
        if self.m_employWujiang.leftEmployTimes <= 0 then
            UILogicUtil.FloatAlert(Language.GetString(1114))
            return
        end
        if self.m_leftEmployTimes <= 0 then
            UILogicUtil.FloatAlert(Language.GetString(1115))
            return
        end
        UIManagerInst:Broadcast(UIMessageNames.MN_LINEUP_SELECT_EMPLOY_WUJIANG, self.m_employWujiang)
    end
end

function EmployWujiangItem:OnDestroy()
    if self.m_wujiangItem then
        self.m_wujiangItem:Delete()
        self.m_wujiangItem = nil
    end

    UIUtil.RemoveClickEvent(self.m_clickBtn.gameObject)
    base.OnDestroy(self)
end

return EmployWujiangItem