local table_insert = table.insert
local table_sort = table.sort

local UIGuildTaskView = BaseClass("UIGuildTaskView", UIBaseView)
local base = UIBaseView

local GuildTaskItem = require "UI.Guild.View.GuildTaskItem"
local GuildMgr = Player:GetInstance().GuildMgr
local GameObject = CS.UnityEngine.GameObject
local UIUtil = UIUtil

function UIGuildTaskView:OnCreate()
    base.OnCreate(self)

    self.m_taskItemList = {}
    self:InitView()
end

function UIGuildTaskView:InitView()
    self.m_taskItemPrefab, 
    self.m_closeBtn, 
    self.m_closeBtnTwo, 
    self.m_helpBtn, 
    self.m_containerTr = UIUtil.GetChildTransforms(self.transform, {
        "TaskItemPrefab",
        "CloseBtn",
        "Container/CloseBtnTwo",
        "Container/helpBtn",
        "Container"
    })

    self.m_taskItemPrefab = self.m_taskItemPrefab.gameObject

    local titleText = UIUtil.FindText(self.transform, "Container/bg2/TitleBg/TitleText")
    titleText.text = Language.GetString(1410)

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_closeBtnTwo.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_helpBtn.gameObject, onClick)
end

function UIGuildTaskView:OnClick(go, x, y)
    if go.name == "CloseBtn" or go.name == "CloseBtnTwo" then
        self:CloseSelf()
    elseif go.name == "helpBtn" then 
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 115) 
    end 
end

function UIGuildTaskView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtnTwo.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_helpBtn.gameObject)
    base.OnDestroy(self)
end

function UIGuildTaskView:OnAddListener()
    base.OnAddListener(self)
    
    self:AddUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_TASK_LIST, self.UpdateData)
    self:AddUIListener(UIMessageNames.MN_GUILD_RSP_COMPLETE_TASK, self.UpdateItemCompleteState)
end

function UIGuildTaskView:OnRemoveListener()
    base.OnRemoveListener(self)

    self:RemoveUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_TASK_LIST, self.UpdateData)
    self:RemoveUIListener(UIMessageNames.MN_GUILD_RSP_COMPLETE_TASK, self.UpdateItemCompleteState)
end

function UIGuildTaskView:OnEnable(...)
    base.OnEnable(self, ...)

    GuildMgr:ReqGuildTask()
end

function UIGuildTaskView:OnDisable(...)
    
    for i, v in ipairs(self.m_taskItemList) do
        v:Delete()
    end
    self.m_taskItemList = {}
    
    base.OnDisable(self)
end

function UIGuildTaskView:UpdateItemCompleteState(msg_obj, awardList)
    for i, v in pairs(self.m_taskItemList) do
        if v then
            if v:GetTaskId() == msg_obj.task_id then
                v:ChangeCompleteState()
            end
        end
    end

    local uiData = {
        titleMsg = Language.GetString(62),
        openType = 1,
        awardDataList = awardList,
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function UIGuildTaskView:UpdateData(msg_obj)

    for i = 1, #msg_obj.task_list do
        local taskItem = self.m_taskItemList[i]
        if not taskItem then
            local go = GameObject.Instantiate(self.m_taskItemPrefab)
            taskItem = GuildTaskItem.New(go, self.m_containerTr)
            taskItem:SetLocalPosition(Vector3.New(-285 + (i - 1) * 285, 25, 0))
            table_insert(self.m_taskItemList, taskItem)
        end

        taskItem:UpdateData(msg_obj.task_list[i].task_id, msg_obj.task_list[i].process, msg_obj.task_list[i].take_flag)
    end
end

function UIGuildTaskView:OnDeatroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtnTwo.gameObject)
    UIUtil.RemoveClickEvent(self.m_helpBtn.gameObject)
    base.OnDeatroy(self)
end

return UIGuildTaskView