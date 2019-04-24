local string_format = string.format
local table_insert = table.insert
local Language = Language
local ConfigUtil = ConfigUtil
local UIUtil = UIUtil
local GameObject = CS.UnityEngine.GameObject
local DOTween = CS.DOTween.DOTween
local DragonCopyMainItem = require "UI.UIDragonCopy.View.DragonCopyMainItem"
local dragonCopyMgr = Player:GetInstance():GetGodBeastMgr()


local UIDragonCopyMainView = BaseClass("UIDragonCopyMainView", UIBaseView)
local base = UIBaseView

function UIDragonCopyMainView:OnCreate()
    base.OnCreate(self)
   
    self.m_leftTimesTxt = UIUtil.GetChildTexts(self.transform, {
        "Bg/LeftTimes",
    })

    self.m_gridContentTr, 
    self.m_backBtnTr, 
    self.m_mainItemPrefab, 
    self.m_ruleBtnTr = UIUtil.GetChildRectTrans(self.transform, {
        "Bg/GridContent",
        "Bg/Panel/BackBtn",
        "Bg/DragonCopyMainItemPrefab",
        "Bg/Panel/RuleBtn",
    })

    self.m_mainItemPrefab = self.m_mainItemPrefab.gameObject

    self:HandleClick() 
    ------------------------------------
    self.m_mainItemList = {}
end

function UIDragonCopyMainView:OnEnable(...)
    base.OnEnable(self, ...)
    
    self.m_mainItemIDList = {3501, 3503, 3502, 3506}   --由于配置表没有规律，只能写死。。。。。
    dragonCopyMgr:ReqCopyInfo()
end

function UIDragonCopyMainView:OnDragonCopyInfo()
    local dragonCopyInfo = dragonCopyMgr:GetCopyInfo()
    if not dragonCopyInfo then
        return
    end

    local passTimes = dragonCopyInfo.today_challenge_time
    local leftTimes = dragonCopyInfo.dragoncopy_max_challenge_times - passTimes
    if dragonCopyInfo.dragoncopy_max_challenge_times >= passTimes then
        self.m_leftTimesTxt.text = string_format(Language.GetString(3700), leftTimes)
    else
        self.m_leftTimesTxt.text = string_format(Language.GetString(3700), 0)
    end 

    for i = 1, 4 do 
        local dragonCopyItem = self.m_mainItemList[i]
        if not dragonCopyItem then
            local go = GameObject.Instantiate(self.m_mainItemPrefab)
            dragonCopyItem = DragonCopyMainItem.New(go, self.m_gridContentTr)
            self.m_mainItemList[i] = dragonCopyItem
            dragonCopyItem:UpdateData(self.m_mainItemIDList[i], leftTimes) 
        end 
    end

    for i = 1, #self.m_mainItemList do
        local curID = self.m_mainItemList[i]:GetID()
        local isActive = self:IsMainItemActive(curID) 
        self.m_mainItemList[i]:SetActiveState(isActive)
    end
end

function UIDragonCopyMainView:IsMainItemActive(cur_id)
    local dragonCopyInfo = dragonCopyMgr:GetCopyInfo()
    local dragonCopyInfoList = dragonCopyInfo.dragoncopy_info_list 
    if not dragonCopyInfoList then
        return
    end

    local isActive = false
    for i = 1, #dragonCopyInfoList do  
        local id = math.floor(dragonCopyInfoList[i].copy_id / 100)
        if id == cur_id then
            isActive = true
            break
        end
    end
    return isActive
end 

function UIDragonCopyMainView:OnAddListener()
    base.OnAddListener(self)

    self:AddUIListener(UIMessageNames.MN_RSP_DRAGON_COPY_INFO, self.OnDragonCopyInfo)
end

function UIDragonCopyMainView:OnRemoveListener()
    base.OnRemoveListener(self)

    self:RemoveUIListener(UIMessageNames.MN_RSP_DRAGON_COPY_INFO, self.OnDragonCopyInfo)
end

function UIDragonCopyMainView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_backBtnTr.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_ruleBtnTr.gameObject, onClick)
end

function UIDragonCopyMainView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_backBtnTr.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtnTr.gameObject)
end

function UIDragonCopyMainView:OnClick(go, x, y)
    if go.name == "BackBtn" then
        self:CloseSelf()
    elseif go.name == "RuleBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 105) 
    end
end

function UIDragonCopyMainView:OnDestroy()
    self:RemoveClick()
    base.OnDestroy(self)
end

function UIDragonCopyMainView:OnDisable()
    for _, v in pairs(self.m_mainItemList) do
        v:Delete()
    end
    self.m_mainItemList = {}

    base.OnDisable(self)
end

return UIDragonCopyMainView