local GameObject = CS.UnityEngine.GameObject
local GameUtility = CS.GameUtility
local table_insert = table.insert
local string_format = string.format
local table_sort = table.sort
local math_ceil = math.ceil
local string_split = CUtil.SplitString
local Vector3 = Vector3
local UIGameObjectLoader = UIGameObjectLoader:GetInstance()
local LieZhuanCopyItemPath = "UI/Prefabs/LieZhuan/LieZhuanCopyItem.prefab"
local LieZhuanCopyItem = require "UI.UILieZhuan.View.LieZhuanCopyItem"
local LieZhuanTeamItemPath = "UI/Prefabs/LieZhuan/LieZhuanTeamItem.prefab"
local LieZhuanTeamItem = require "UI.UILieZhuan.View.LieZhuanTeamItem"
local LieZhuanMgr = Player:GetInstance():GetLieZhuanMgr()

local UILieZhuanTeamView = BaseClass("UILieZhuanTeamView", UIBaseView)
local base = UIBaseView

function UILieZhuanTeamView:OnCreate()
    base.OnCreate(self)
    self:InitVariable()
    self:InitView()
end

function UILieZhuanTeamView:InitVariable()
    self.m_sCountryNameList = string_split(Language.GetString(3750), ",")
    self.m_selectCopyId = 0
    self.m_copyDetailItemList = {}
    self.m_copyList = {}
    self.m_teamDetailItemList = {}
    self.m_teamDataList = {}
    self.m_showTeamList = {}
end

function UILieZhuanTeamView:InitView()
    self.m_closeBtn, self.m_backBtn, self.m_scrollView, self.m_copyContent, self.m_teamItemContent, self.m_updateBtn, self.m_createBtn, self.m_noTeamRoot = UIUtil.GetChildRectTrans(self.transform, {
        "closeBtn",
        "Container/top/backBtn",
        "Container/left/ItemScrollView",
        "Container/left/ItemScrollView/Viewport/ItemContent",
        "Container/right/bgImage/ItemScrollView/Viewport/ItemContent",
        "Container/right/updateBtn",
        "Container/right/createBtn",
        "Container/right/bgImage/noTeamRoot",   
    })

    local titleText, updateBtnText, createBtnText, consumeText, noTeamText
    titleText, consumeText, updateBtnText, createBtnText, self.m_countryText, self.m_consumeNumText, noTeamText = UIUtil.GetChildTexts(self.transform, {
        "Container/top/titleBg/titleText",
        "Container/top/consumeBg/consumeText",
        "Container/right/updateBtn/updateBtnText",
        "Container/right/createBtn/createBtnText",
        "Container/top/countryText",
        "Container/top/consumeBg/numText",
        "Container/right/bgImage/noTeamRoot/noTeamText",
    })

    self.m_loopScrowContent = UIUtil.AddComponent(LoopScrowView, self, "Container/left/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateCopyItemInfo))
    self.m_teamScrowContent = UIUtil.AddComponent(LoopScrowView, self, "Container/right/bgImage/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateTeamItemInfo))

    self.m_detailItemBounds = GameUtility.GetRectTransWorldCorners(self.m_scrollView)

    titleText.text = Language.GetString(3756)
    consumeText.text = Language.GetString(3762)
    updateBtnText.text = Language.GetString(3763)
    createBtnText.text = Language.GetString(3764)
    noTeamText.text = Language.GetString(3795)
end

function UILieZhuanTeamView:OnClick(go, x, y)
    if go.name == "closeBtn" or go.name == "backBtn" then
        self:CloseSelf()
    elseif go.name == "updateBtn" then
        if self.m_countryId and self.m_selectCopyId then
            LieZhuanMgr:ReqLiezhuanTeamList(self.m_countryId, self.m_selectCopyId)
        end
    elseif go.name == "createBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanCreateTeam, self.m_selectCopyId)
    end
end

function UILieZhuanTeamView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_updateBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_createBtn.gameObject, onClick)
end

function UILieZhuanTeamView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_updateBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_createBtn.gameObject)
end

function UILieZhuanTeamView:OnEnable(...)
    base.OnEnable(self, ...)
    local order
    order, selectCopyId = ...
    self.m_countryId = LieZhuanMgr:GetSelectCountry()
    
    if selectCopyId then
        self.m_selectCopyId = selectCopyId
    end
    
    if self.m_countryId then
        LieZhuanMgr:ReqLiezhuanTeamList(self.m_countryId, self.m_selectCopyId)
    end

    if self.m_countryId then
        self:HandleClick()
        self:UpdateTextView()
        self:UpdateCopyData()
    end
end

function UILieZhuanTeamView:OnDisable()
    base.OnDisable(self)
    self:RemoveClick()

    if self.m_copyDetailItemList then
        for i, v in ipairs(self.m_copyDetailItemList) do
            v:Delete()
        end
        self.m_copyDetailItemList = {}
    end

    self.m_selectCopyId = 0
    self.m_countryId = nil
end

function UILieZhuanTeamView:UpdateTextView()
    self.m_countryText.text = string_format(Language.GetString(3753), self.m_sCountryNameList[self.m_countryId])
    self.m_consumeNumText.text = math_ceil(LieZhuanMgr:GetTeamFightNeedTili())
end

function UILieZhuanTeamView:UpdateCopyData()
    local copyCfg = {id = 0} -- 全部
    self.m_copyList = LieZhuanMgr:GetCountryCopyCount(self.m_countryId)
    table_insert(self.m_copyList,copyCfg)
    table_sort(self.m_copyList, function(ltb, rtb)
        return ltb.id < rtb.id
    end
    )

    if #self.m_copyDetailItemList == 0 then
        self.m_loaderSeq = UIGameObjectLoader:PrepareOneSeq()
        UIGameObjectLoader:GetGameObjects(self.m_loaderSeq, LieZhuanCopyItemPath, 16, function(objs)
            self.m_loaderSeq = 0
            if objs then
                for i = 1, #objs do
                    local copyDetailItem = LieZhuanCopyItem.New(objs[i], self.m_copyContent, LieZhuanCopyItemPath)
                    table_insert(self.m_copyDetailItemList, copyDetailItem)
                end
                self.m_loopScrowContent:UpdateView(true, self.m_copyDetailItemList, self.m_copyList)
            end
        end)
    else
        self.m_loopScrowContent:UpdateView(true, self.m_copyDetailItemList, self.m_copyList)
    end
end

function UILieZhuanTeamView:UpdateCopyItemInfo(item, realIndex)
    if not item then
        return
    end
    if realIndex > #self.m_copyList then
        return
    end

    local copyId = self.m_copyList[realIndex].id
    if copyId then
        local islocked = LieZhuanMgr:IsLockedCopy(self.m_countryId, copyId)
        item:UpdateData(self.m_copyList[realIndex], islocked, Bind(self, self.OnSelectCopy), self.m_countryId)
    end
    
    if self.m_selectCopyId and item then
        item:SetSelectState(self.m_selectCopyId == item:GetCopyId(), self.m_detailItemBounds)
    end
end

function UILieZhuanTeamView:OnSelectCopy(copyItem)
    if copyItem then
        for k,v in pairs(self.m_copyDetailItemList) do
            v:SetSelectState(v:GetCopyId() == copyItem:GetCopyId(), self.m_detailItemBounds)
        end
        self.m_selectCopyId = copyItem:GetCopyId()
    end
    if self.m_countryId and self.m_selectCopyId and self.m_teamDataList then
        self:UpdateTeamData(self.m_teamDataList)
        --LieZhuanMgr:ReqLiezhuanTeamList(self.m_countryId, self.m_selectCopyId)
    end
end

function UILieZhuanTeamView:UpdateTeamData(team_data_list)
    if not team_data_list then
        return
    end
    self.m_teamDataList = team_data_list
    local showTeamList = {}
    for _,v in ipairs(self.m_teamDataList) do
        if v.team_base_info.copy_id == self.m_selectCopyId or self.m_selectCopyId == 0 and v.team_base_info.country == self.m_countryId and v.team_base_info.country == self.m_countryId and not LieZhuanMgr:IsLockedCopy(self.m_countryId, v.team_base_info.copy_id) then
            table_insert(showTeamList,v)
        end
    end

    self.m_noTeamRoot.gameObject:SetActive(showTeamList == nil or #showTeamList == 0)
    if showTeamList then
        self.m_showTeamList = showTeamList
        if #self.m_teamDetailItemList == 0 then
            self.m_loaderSeq = UIGameObjectLoader:PrepareOneSeq()
            UIGameObjectLoader:GetGameObjects(self.m_loaderSeq, LieZhuanTeamItemPath, 6, function(objs)
                self.m_loaderSeq = 0
                if objs then
                    for i = 1, #objs do
                        local teamDetailItem = LieZhuanTeamItem.New(objs[i], self.m_teamItemContent, LieZhuanTeamItemPath)
                        table_insert(self.m_teamDetailItemList, teamDetailItem)
                    end
                    self.m_teamScrowContent:UpdateView(true, self.m_teamDetailItemList, self.m_showTeamList)
                end
            end)
        else
            self.m_teamScrowContent:UpdateView(true, self.m_teamDetailItemList, self.m_showTeamList)
        end
    end
end

function UILieZhuanTeamView:UpdateTeamItemInfo(item, realIndex)
    if not item then
        return
    end
    if realIndex > #self.m_showTeamList then
        return
    end

    local teamData = self.m_showTeamList[realIndex]
    if teamData then
        item:UpdateData(teamData)
    end
end

function UILieZhuanTeamView:OnDestroy()
    base.OnDestroy(self)
end

function UILieZhuanTeamView:OnAddListener()
    self:AddUIListener(UIMessageNames.MN_LIEZHUAN_UPDATE_TEAM, self.UpdateTeamData)
	base.OnAddListener(self)
end

function UILieZhuanTeamView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_LIEZHUAN_UPDATE_TEAM, self.UpdateTeamData)
	base.OnRemoveListener(self)
end

return UILieZhuanTeamView