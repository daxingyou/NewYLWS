local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local Type_GradientColor = typeof(CS.UiEffect.GradientColor)
local UIUtil = UIUtil
local table_insert = table.insert
local table_sort = table.sort
local TaskMgr = Player:GetInstance():GetTaskMgr()
local UISliderHelper = typeof(CS.UISliderHelper)
local UITaskItemPrefabPath = TheGameIds.TaskItemPrefabPath
local UITaskItem = require "UI.UITask.View.UITaskItem"
local RotateStart = Quaternion.Euler(0, 0, -8)
local RotateEnd = Vector3.New(0, 0, 8)

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"
local EffectPath = "UI/Effect/Prefabs/ui_baoxiang_fx"

local base = UIBaseView
local UITaskView = BaseClass("UITaskView", UIBaseView)

function UITaskView:OnAddListener()
	base.OnAddListener(self)
	-- UI消息注册
    self:AddUIListener(UIMessageNames.MN_RSP_TAKE_TASK_AWARD, self.RspTakeTaskAward)
    self:AddUIListener(UIMessageNames.MN_NTF_TASK_PROGRESS_CHG, self.NtfTaskProgressChg)
    self:AddUIListener(UIMessageNames.MN_NTF_TASK_CHG, self.NtfTaskChg)
    self:AddUIListener(UIMessageNames.MN_ONCLICK_GOTO_TASK_PANEL, self.OnClickTaskItem)
end

function UITaskView:OnRemoveListener()
	-- UI消息注销
    self:RemoveUIListener(UIMessageNames.MN_RSP_TAKE_TASK_AWARD, self.RspTakeTaskAward)
    self:RemoveUIListener(UIMessageNames.MN_NTF_TASK_PROGRESS_CHG, self.NtfTaskProgressChg)
    self:RemoveUIListener(UIMessageNames.MN_NTF_TASK_CHG, self.NtfTaskChg)
    self:RemoveUIListener(UIMessageNames.MN_ONCLICK_GOTO_TASK_PANEL, self.OnClickTaskItem)

	base.OnRemoveListener(self)
end

function UITaskView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()
end

function UITaskView:InitView()
    self.m_topTitleText, self.m_mainBtnText, self.m_dailyBtnText, self.m_weekBtnText, self.m_achieveBtnText, self.m_todayText, self.m_todayNumText,
    self.m_achieveText, self.m_noneTaskTxt =
    UIUtil.GetChildTexts(self.transform, {
        "Bg/contanierBg/topText",
        "RightContainer/btnGroupContainer/mainButton/Text",
        "RightContainer/btnGroupContainer/dailyButton/Text",
        "RightContainer/btnGroupContainer/weekButton/Text",
        "RightContainer/btnGroupContainer/achievementButton/Text",
        "BottomContainer/todayText",
        "BottomContainer/todayTextNum",
        "BottomContainer/achivementSlider/Text",
        "TaskContainer/NoneTaskContent/Text",
    })

    self.m_mainBtn, self.m_dailyBtn, self.m_weekBtn, self.m_achieveBtn, self.m_closeBtn, self.m_backBtn,
    self.m_box1Btn, self.m_box2Btn, self.m_box3Btn, self.m_box4Btn = 
    UIUtil.GetChildTransforms(self.transform, {
        "RightContainer/btnGroupContainer/mainButton", 
        "RightContainer/btnGroupContainer/dailyButton", 
        "RightContainer/btnGroupContainer/weekButton", 
        "RightContainer/btnGroupContainer/achievementButton", 
        "TopContainer/CloseButton",
        "Bg/backBtn",
        "BottomContainer/awardRoot/box1/boxBtn1",
        "BottomContainer/awardRoot/box2/boxBtn2",
        "BottomContainer/awardRoot/box3/boxBtn3",
        "BottomContainer/awardRoot/box4/boxBtn4",
    })

    self:HandleClick()

    self.m_scrollView = self:AddComponent(LoopScrowView, "TaskContainer/taskScrollView/Viewport/Content", Bind(self, self.UpdateDataTaskItem), false)

    self.m_mainBtnBgTrans, self.m_dailyBtnBgTrans, self.m_weekBtnBgTrans, self.m_achieveBtnBgTrans,
    self.m_mainBtnRedTrans, self.m_dailyBtnRedTrans, self.m_weekBtnRedTrans, self.m_achieveBtnRedTrans,
    self.m_bottomBoxContainerTrans, self.m_taskItemContentTrans, self.m_bottomBoxMsgTrans, 
    self.m_bottomBoxMsgItemTrans, self.m_boxSliderTrans, self.m_achieveSliderTrans, self.m_box1Trans, self.m_box2Trans,
    self.m_box3Trans, self.m_box4Trans, self.m_box1RedPointTrans, self.m_box2RedPointTrans, self.m_box3RedPointTrans, 
    self.m_box4RedPointTrans, self.m_boxMsgBg, self.m_boxMsgScrollView, self.m_noneTaskContentTr = 
    UIUtil.GetChildRectTrans(self.transform, {
        "RightContainer/btnGroupContainer/mainButton/bg", 
        "RightContainer/btnGroupContainer/dailyButton/bg", 
        "RightContainer/btnGroupContainer/weekButton/bg", 
        "RightContainer/btnGroupContainer/achievementButton/bg",
        "RightContainer/btnGroupContainer/mainButton/redImage", 
        "RightContainer/btnGroupContainer/dailyButton/redImage", 
        "RightContainer/btnGroupContainer/weekButton/redImage", 
        "RightContainer/btnGroupContainer/achievementButton/redImage",
        "BottomContainer/awardRoot", 
        "TaskContainer/taskScrollView/Viewport/Content",
        "BottomContainer/awardRoot/boxMsgContainer",
        "BottomContainer/awardRoot/boxMsgContainer/awardScroll View/Viewport/Content",
        "BottomContainer/Slider", 
        "BottomContainer/achivementSlider",
        "BottomContainer/awardRoot/box1",
        "BottomContainer/awardRoot/box2",
        "BottomContainer/awardRoot/box3",
        "BottomContainer/awardRoot/box4",
        "BottomContainer/awardRoot/box1/boxBtn1/redPoint1",
        "BottomContainer/awardRoot/box2/boxBtn2/redPoint1",
        "BottomContainer/awardRoot/box3/boxBtn3/redPoint1",
        "BottomContainer/awardRoot/box4/boxBtn4/redPoint1",
        "BottomContainer/awardRoot/boxMsgContainer/bg",
        "BottomContainer/awardRoot/boxMsgContainer/awardScroll View",
        "TaskContainer/NoneTaskContent",
    })

    self.m_taskViewPort = UIUtil.FindComponent(self.transform, Type_RectTransform, "TaskContainer/taskScrollView/Viewport")

    -- 宝箱进度/成就进度
    self.m_boxSlider = UIUtil.FindComponent(self.transform, UISliderHelper, "BottomContainer/Slider")
    self.m_achieveSlider = UIUtil.FindComponent(self.transform, UISliderHelper, "BottomContainer/achivementSlider")

    -- 宝箱图片
    self.m_box1Image = UIUtil.AddComponent(UIImage, self, "BottomContainer/awardRoot/box1/boxBtn1", AtlasConfig.DynamicLoad)
    self.m_box2Image = UIUtil.AddComponent(UIImage, self, "BottomContainer/awardRoot/box2/boxBtn2", AtlasConfig.DynamicLoad)
    self.m_box3Image = UIUtil.AddComponent(UIImage, self, "BottomContainer/awardRoot/box3/boxBtn3", AtlasConfig.DynamicLoad)
    self.m_box4Image = UIUtil.AddComponent(UIImage, self, "BottomContainer/awardRoot/box4/boxBtn4", AtlasConfig.DynamicLoad)
    

    -- 右侧按钮渐变颜色组件
    self.m_mainBtnTextGra = UIUtil.FindComponent(self.transform, Type_GradientColor, "RightContainer/btnGroupContainer/mainButton/Text")
    self.m_dailyBtnTextGra = UIUtil.FindComponent(self.transform, Type_GradientColor, "RightContainer/btnGroupContainer/dailyButton/Text")
    self.m_weekBtnTextGra = UIUtil.FindComponent(self.transform, Type_GradientColor, "RightContainer/btnGroupContainer/weekButton/Text")
    self.m_achieveBtnTextGra = UIUtil.FindComponent(self.transform, Type_GradientColor, "RightContainer/btnGroupContainer/achievementButton/Text")

    self.m_itemList = {}
    self.m_currSelectItem = false
    self.m_currTaskTable = 0
    self.m_boxTweenList = {}
    self.m_taskItemSeq = 0
    self.m_boxItemSeq = 0
    self.m_boxItemList = {}
    self.m_boxMsgIsShow = false
    self.m_isScaled = false
    self.m_effectList = {}
    self.m_layerName = UILogicUtil.FindLayerName(self.transform)

    self.m_bottomBoxMsgTrans.gameObject:SetActive(false)
    self.m_taskList = {}
end

function UITaskView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_mainBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_dailyBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_weekBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_achieveBtn.gameObject, onClick) 
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_box1Btn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_box2Btn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_box3Btn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_box4Btn.gameObject, onClick)
end

function UITaskView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_mainBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_dailyBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_weekBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_achieveBtn.gameObject) 
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_box1Btn.gameObject)
    UIUtil.RemoveClickEvent(self.m_box2Btn.gameObject)
    UIUtil.RemoveClickEvent(self.m_box3Btn.gameObject)
    UIUtil.RemoveClickEvent(self.m_box4Btn.gameObject)
end

function UITaskView:OnEnable(...)
    base.OnEnable(self, ...)
    local _, curType = ... 

    local taskInfo = TaskMgr:GetCurTaskInfo()
    if not taskInfo then
        return
    end

    self.m_topTitleText.text = Language.GetString(3200)
    self.m_mainBtnText.text = Language.GetString(3201)
    self.m_dailyBtnText.text = Language.GetString(3202)
    self.m_weekBtnText.text = Language.GetString(3203)
    self.m_achieveBtnText.text = Language.GetString(3204)
    if self.m_noneTaskContentTr.gameObject.activeSelf then
        self.m_noneTaskContentTr.gameObject:SetActive(false)
    end
     
    if not curType or curType <= 0 then
        self.m_currTaskTable = taskInfo.type
    elseif curType > 0 then
        self.m_currTaskTable = curType
    end 

    self:HandleTaskType()
end 

function UITaskView:GetRecoverParam()
    return self.m_currTaskTable
end

function UITaskView:OnClickTaskItem(sysID)
    if sysID == SysIDs.TASK_DAILY then
        self.m_currTaskTable = TaskMgr.TaskType.Daily
        self:HandleTaskType()
    end
end

function UITaskView:HandleTaskType()
    if self.m_currTaskTable == TaskMgr.TaskType.Main then
        self.m_todayText.text = ''
        self.m_todayNumText.text = ''
        self.m_achieveText.text = ''
        
    elseif self.m_currTaskTable == TaskMgr.TaskType.Daily then
        self.m_todayText.text = Language.GetString(3205)
        local boxCurValue = TaskMgr:GetTaskBoxCurValueByType(TaskMgr.TaskType.Daily)
        local boxLimitValue = TaskMgr:GetTaskLimitValueByType(TaskMgr.TaskType.Daily)
        self.m_todayNumText.text = string.format(Language.GetString(3208), boxCurValue or 0, boxLimitValue or 0)
        self.m_boxSlider:UpdateSliderImmediately(boxCurValue/boxLimitValue)
        self.m_achieveText.text = ''
        self:HandBoxView(TaskMgr.TaskType.Daily, boxLimitValue)

    elseif self.m_currTaskTable == TaskMgr.TaskType.Weekly then
        self.m_todayText.text = Language.GetString(3213)
        local boxCurValue = TaskMgr:GetTaskBoxCurValueByType(TaskMgr.TaskType.Weekly)
        local boxLimitValue = TaskMgr:GetTaskLimitValueByType(TaskMgr.TaskType.Weekly)
        self.m_todayNumText.text = string.format(Language.GetString(3208), boxCurValue or 0, boxLimitValue or 0)
        self.m_boxSlider:UpdateSliderImmediately(boxCurValue/boxLimitValue)
        self.m_achieveText.text = ''
        self:HandBoxView(TaskMgr.TaskType.Weekly, boxLimitValue)

    elseif self.m_currTaskTable == TaskMgr.TaskType.Achievement then
        self.m_todayText.text = Language.GetString(3209)
        self.m_todayNumText.text = ''
        local boxCurValue = TaskMgr:GetTaskAchievementCurValue(self.m_currTaskTable)
        local boxLimitValue = TaskMgr:GetTaskAchievementLimitValue(self.m_currTaskTable)
        self.m_achieveSlider:UpdateSliderImmediately(boxCurValue/boxLimitValue)
        self.m_achieveText.text = string.format(Language.GetString(3208), boxCurValue, boxLimitValue)
    end

    self:HandleTaskItem()
end

function UITaskView:HandleGameObjectActive(showRedPoint)
    local isMain = (self.m_currTaskTable == TaskMgr.TaskType.Main)
    local isDaily = (self.m_currTaskTable == TaskMgr.TaskType.Daily)
    local isWeekly = (self.m_currTaskTable == TaskMgr.TaskType.Weekly)
    local isAchieve = (self.m_currTaskTable == TaskMgr.TaskType.Achievement)

    self.m_mainBtnBgTrans.gameObject:SetActive(isMain)
    self.m_dailyBtnBgTrans.gameObject:SetActive(isDaily)
    self.m_weekBtnBgTrans.gameObject:SetActive(isWeekly)
    self.m_achieveBtnBgTrans.gameObject:SetActive(isAchieve)
    self.m_bottomBoxContainerTrans.gameObject:SetActive(isDaily or isWeekly)
    self.m_boxSliderTrans.gameObject:SetActive(isDaily or isWeekly)
    self.m_achieveSliderTrans.gameObject:SetActive(isAchieve)

    self.m_mainBtnTextGra.enabled = isMain
    self.m_dailyBtnTextGra.enabled = isDaily
    self.m_weekBtnTextGra.enabled = isWeekly
    self.m_achieveBtnTextGra.enabled = isAchieve

    local showMainRedPoint = false
    if not isMain then
        local mainTaskList = TaskMgr:GetTaskListByType(TaskMgr.TaskType.Main)
        for _,task in pairs(mainTaskList) do
            if type(task) == "table" and task.status == 1 then
                showMainRedPoint = true
            end
        end
    end
    
    local showDailyRedPoint = false
    if not isDaily then
        local dailyTaskList = TaskMgr:GetTaskListByType(TaskMgr.TaskType.Daily)
        for _,task in pairs(dailyTaskList) do
            if type(task) == "table" and task.status == 1 then
                showDailyRedPoint = true
            end
        end
    end
    
    local showWeekRedPoint = false
    if not isWeekly then
        local weekTaskList = TaskMgr:GetTaskListByType(TaskMgr.TaskType.Weekly)
        for _,task in pairs(weekTaskList) do
            if type(task) == "table" and task.status == 1 then
                showWeekRedPoint = true
            end
        end
    end
    
    local showAchieveRedPoint = false
    if not isAchieve then
        local achieveTaskList = TaskMgr:GetTaskListByType(TaskMgr.TaskType.Achievement)
        for _,task in pairs(achieveTaskList) do
            if type(task) == "table" and task.status == 1 then
                showAchieveRedPoint = true
            end
        end
    end

    self.m_mainBtnRedTrans.gameObject:SetActive(showMainRedPoint)
    self.m_dailyBtnRedTrans.gameObject:SetActive(showDailyRedPoint)
    self.m_weekBtnRedTrans.gameObject:SetActive(showWeekRedPoint)
    self.m_achieveBtnRedTrans.gameObject:SetActive(showAchieveRedPoint)
end


function UITaskView:HandBoxView(type, boxLimitValue)
    local boxInfo = TaskMgr:GetTaskBoxInfoByType(type)
    self:ClearEffect()
    if boxInfo then
        for i=1, #boxInfo do
            local box = boxInfo[i]
            local boxID = box.id
            local boxStatus = box.status   -- 0未达成 1已达成未领取  2已领取
            local boxCfg = ConfigUtil.GetTaskBoxCfgByID(boxID)
            if boxCfg then
                -- 895
                local boxCond = boxCfg.cond
                local posPercent = boxCond/boxLimitValue -- boxCond/boxLimitValue
                if i == 1  then
                    local pos = self.m_box1Trans.localPosition
                    self:HandleBoxLocalPos(self.m_box1Trans, posPercent)
                    self:HandleBoxRedPoint(boxStatus, self.m_box1RedPointTrans, self.m_box1Image, i, self.m_box1Btn)

                elseif i== 2 then
                    local pos = self.m_box2Trans.localPosition
                    self:HandleBoxLocalPos(self.m_box2Trans, posPercent)
                    self:HandleBoxRedPoint(boxStatus, self.m_box2RedPointTrans, self.m_box2Image, i, self.m_box2Btn)

                elseif i== 3 then
                    local pos = self.m_box3Trans.localPosition
                    self:HandleBoxLocalPos(self.m_box3Trans, posPercent)
                    self:HandleBoxRedPoint(boxStatus, self.m_box3RedPointTrans, self.m_box3Image, i, self.m_box3Btn)

                elseif i== 4 then
                    local pos = self.m_box4Trans.localPosition
                    self:HandleBoxLocalPos(self.m_box4Trans, posPercent)
                    self:HandleBoxRedPoint(boxStatus, self.m_box4RedPointTrans, self.m_box4Image, i, self.m_box4Btn)
                end
            else 
                
            end
        end
    end
end

function UITaskView:HandleTaskItem()
    self.m_taskList = {}
    local taskList = TaskMgr:GetTaskListByType(self.m_currTaskTable) 
    local taskCount = 0

    local taskList1 = {}
    local taskList2 = {}
    local showRedPoint = false
    for taskId,_ in pairs(taskList) do
        local task = taskList[taskId]
        if task and type(task) == "table" and task.id then
            if task.status == 0 then -- 0未达成
                table_insert(taskList1, task)
            elseif task.status == 1 then -- 1已达成未领取
                table_insert(self.m_taskList, task)
                showRedPoint = true
            elseif task.status == 2 then -- 2已领取
                table_insert(taskList2, task)
            end
            taskCount = taskCount + 1
        end 
    end 

    if self.m_currTaskTable ~= TaskMgr.TaskType.Achievement then
        if taskCount <= 0 then
            self.m_noneTaskContentTr.gameObject:SetActive(true)
            local str = ""
            if self.m_currTaskTable == TaskMgr.TaskType.Main then
                str = Language.GetString(3226)
            elseif self.m_currTaskTable == TaskMgr.TaskType.Daily then
                str = Language.GetString(3227)
            elseif self.m_currTaskTable == TaskMgr.TaskType.Weekly then
                str = Language.GetString(3228)
            end
            self.m_noneTaskTxt.text = str
        else    
            self.m_noneTaskContentTr.gameObject:SetActive(false)
        end
    end

    for i=1,#taskList1 do 
        table_insert(self.m_taskList, taskList1[i])
    end

    for i=1,#taskList2 do 
        table_insert(self.m_taskList, taskList2[i])
    end

    self:UpdateTaskData()

    self:HandleGameObjectActive(showRedPoint)
end

function UITaskView:HandleBoxLocalPos(trans, posPercent)
    local pos = trans.localPosition
    trans.localPosition = Vector3.New(posPercent * 700 - 296, pos.y, pos.z)
end

function UITaskView:HandleBoxRedPoint(status, trans, image, i, roteTrans)
    if status == 0 then -- 未达成，屏蔽红点
        trans.gameObject:SetActive(false)
        image:SetAtlasSprite("zhuxian18.png", false, AtlasConfig.DynamicLoad)

        UIUtil.KillTween(self.m_boxTweenList[i])

    elseif status == 1 then -- 以达成未领取 开启红点
        trans.gameObject:SetActive(true)
        image:SetAtlasSprite("zhuxian18.png", false, AtlasConfig.DynamicLoad)

        local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
        UIUtil.AddComponent(UIEffect, self, roteTrans, sortOrder, EffectPath, function(effect)
            effect:SetLocalPosition(Vector3.zero)
            effect:SetLocalScale(Vector3.one)
            table_insert(self.m_effectList, effect)
        end)

        UIUtil.KillTween(self.m_boxTweenList[i])
        local lastTweener = self.m_boxTweenList[i]
        local sequence = UIUtil.TweenRotateToShake(roteTrans, lastTweener, RotateStart, RotateEnd)
        self.m_boxTweenList[i] = sequence

    elseif status == 2 then -- 已领取 更换图片，屏蔽红点
        trans.gameObject:SetActive(false)
        image:SetAtlasSprite("zhuxian17.png", false, AtlasConfig.DynamicLoad)

        UIUtil.KillTween(self.m_boxTweenList[i])

    end
end

function UITaskView:ClearEffect()
    for i, v in ipairs(self.m_effectList) do
        v:Delete()
    end
    self.m_effectList = {}
end

function UITaskView:OnDisable()
    self:Release()
    UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)
    self:ClearEffect()

    for _, tweenner in pairs(self.m_boxTweenList) do
        if tweenner then
            UIUtil.KillTween(tweenner)
        end
    end

    if #self.m_boxItemList > 0 then
        for _,item in pairs(self.m_boxItemList) do
            item:Delete()
        end
    end
    self.m_boxItemList = {}

    self.m_boxTweenList = {}
    self.m_currTaskTable = 0
    self.m_boxMsgIsShow = false

	base.OnDisable(self)
end

function UITaskView:OnDestroy()
    self:RemoveClick()
    self:Release()

    base.OnDestroy(self)
end

function UITaskView:Release()
    if self.m_taskItemSeq > 0 then
        UIGameObjectLoader:GetInstance():CancelLoad(self.m_taskItemSeq)
        self.m_taskItemSeq = 0
    end
end

function UITaskView:UpdateTaskData() 
    if #self.m_itemList == 0 then
        local seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(seq, UITaskItemPrefabPath, 8, function(objs)
            seq = 0
            if objs then
                for i = 1, #objs do
                    local taskItem = UITaskItem.New(objs[i], self.m_taskItemContentTrans, UITaskItemPrefabPath)
                    table_insert(self.m_itemList, taskItem)
                    
                end

                self.m_scrollView:UpdateView(true, self.m_itemList, self.m_taskList)
            end
        end)
    else
        self.m_scrollView:UpdateView(true, self.m_itemList, self.m_taskList)
    end

    if self.m_currTaskTable == TaskMgr.TaskType.Main then
        if not self.m_isScaled then
            local tmpSizeDelta = self.m_taskViewPort.sizeDelta
            self.m_taskViewPort.sizeDelta = Vector2.New(tmpSizeDelta.x, tmpSizeDelta.y * 1.25)
            
            self.m_isScaled = true
        end

    else
        if self.m_isScaled then
            local tmpSizeDelta = self.m_taskViewPort.sizeDelta
            self.m_taskViewPort.sizeDelta = Vector2.New(tmpSizeDelta.x, tmpSizeDelta.y / 1.25)
            
            self.m_isScaled = false
        end
    end
end


function UITaskView:NtfTaskNew(task) 
    local seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObject(seq, UITaskItemPrefabPath, function(go)
        seq = 0
        if not IsNull(go) then
            local taskItem = UITaskItem.New(go, self.m_taskItemContentTrans, UITaskItemPrefabPath)

            taskItem:UpdateData(task)
            table_insert(self.m_itemList, taskItem)
        end
    end)
end

function UITaskView:NtfTaskProgressChg(taskType)
    if taskType == TaskMgr.TaskType.Daily or taskType == TaskMgr.TaskType.Weekly then
        local boxCurValue = TaskMgr:GetTaskBoxCurValueByType(taskType)
        local boxLimitValue = TaskMgr:GetTaskLimitValueByType(taskType)
        self.m_todayNumText.text = string.format(Language.GetString(3208), boxCurValue, boxLimitValue)
        self.m_boxSlider:UpdateSliderImmediately(boxCurValue/boxLimitValue)
        self:HandBoxView(taskType, boxLimitValue)

    elseif taskType == TaskMgr.TaskType.Achievement then
        local achievementCurValue = TaskMgr:GetTaskAchievementCurValue(taskType)
        local achievementLimitValue = TaskMgr:GetTaskAchievementLimitValue(taskType)
        self.m_achieveSlider:UpdateSliderImmediately(achievementCurValue/achievementLimitValue)
        self.m_achieveText.text = string.format(Language.GetString(3208), achievementCurValue, achievementLimitValue)
    end
end

function UITaskView:RspTakeTaskAward(awardList)
    if awardList and #awardList > 0 then
        local uiData = {
            openType = 1,
            awardDataList = awardList,
        }
        UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
    end
end

function UITaskView:DeleteTask(taskID) 
    if self.m_itemList and #self.m_itemList > 0 then
        local count = #self.m_itemList
        for i=count,1,-1 do
            if self.m_itemList[i]:GetTaskID() == taskID then
                self.m_itemList[i]:Delete()
                table.remove(self.m_itemList, i)
            end
        end
    end
end

function UITaskView:OnReleaseTaskItem()
    if self.m_itemList and #self.m_itemList > 0 then
        for i=1,#self.m_itemList do
            self.m_itemList[i]:Delete()
        end
    end

    self.m_itemList = {}
end

function UITaskView:OnReleaseItem(itemList)
    if itemList and #itemList > 0 then
        for i, v in ipairs(itemList) do
            v:Delete()
        end
    end
end

function UITaskView:OnClick(go)
     if self.m_boxMsgIsShow then
        self.m_bottomBoxMsgTrans.gameObject:SetActive(false)
        self.m_boxMsgIsShow = false
        return
    end

    if go.name == "mainButton" then
        if self.m_currTaskTable == TaskMgr.TaskType.Main then
            return
        end
        self.m_currTaskTable = TaskMgr.TaskType.Main
        self:HandleTaskType()

    elseif go.name == "dailyButton" then
        if self.m_currTaskTable == TaskMgr.TaskType.Daily then
            return
        end
        self.m_currTaskTable = TaskMgr.TaskType.Daily
        self:HandleTaskType()

    elseif go.name == "weekButton" then
        if self.m_currTaskTable == TaskMgr.TaskType.Weekly then
            return
        end
        self.m_currTaskTable = TaskMgr.TaskType.Weekly
        self:HandleTaskType()

    elseif go.name == "achievementButton" then
        if self.m_currTaskTable == TaskMgr.TaskType.Achievement then
            return
        end
        self.m_currTaskTable = TaskMgr.TaskType.Achievement
        self:HandleTaskType()

    elseif go.name == "CloseButton" then
        UIManagerInst:CloseWindow(UIWindowNames.UITaskMain)

    elseif go.name == "backBtn" then
        UIManagerInst:CloseWindow(UIWindowNames.UITaskMain)

    elseif go.name == "boxBtn1" then
        self:HandleBoxClick(1)

    elseif go.name == "boxBtn2" then
        self:HandleBoxClick(2)

    elseif go.name == "boxBtn3" then
        self:HandleBoxClick(3)

    elseif go.name == "boxBtn4" then
        self:HandleBoxClick(4)

    elseif go.name == "HelpButton" then
    end
end

function UITaskView:HandleBoxClick(index)
    local boxInfo = TaskMgr:GetTaskBoxInfoByType(self.m_currTaskTable)
    local box = boxInfo[index]
    if box then
        if box.status == 1 then
            TaskMgr:ReqTakeTaskBoxAward(box.id)

        else
            if #self.m_boxItemList > 0 then
                for _,item in pairs(self.m_boxItemList) do
                    item:Delete()
                end
            end
            self.m_boxItemList = {}
            self.m_boxMsgIsShow = true
        
            local itemPos = nil
            if index == 1 then
                itemPos = self.m_box1Trans.localPosition
        
            elseif index == 2  then
                itemPos = self.m_box2Trans.localPosition
                      
            elseif index == 3  then
                itemPos = self.m_box3Trans.localPosition
               
            elseif index == 4  then
                itemPos = self.m_box4Trans.localPosition
            end
        
            self.m_bottomBoxMsgTrans.gameObject:SetActive(true)
            self.m_bottomBoxMsgTrans.localPosition = Vector3.New(itemPos.x + 25, itemPos.y + 320, itemPos.z)
            local boxID = box.id
            local boxCfg = ConfigUtil.GetTaskBoxCfgByID(boxID)
            if boxCfg then
                local awardCount = 0
                for i=1,12 do
                    local itemID = boxCfg['award_item_id'..i]
                    local itemCount = boxCfg['award_item_count'..i]
                    if itemID and itemCount > 0 then
                        awardCount = awardCount + 1
                        local seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
                        UIGameObjectLoader:GetInstance():GetGameObject(seq, CommonAwardItemPrefab, function(go)
                            seq = 0
                            if not IsNull(go) then
                                local bagItem = CommonAwardItem.New(go, self.m_bottomBoxMsgItemTrans, CommonAwardItemPrefab)
                                table_insert(self.m_boxItemList, bagItem)
                                local itemIconParam = AwardIconParamClass.New(itemID, itemCount)         
                                bagItem:UpdateData(itemIconParam)
                            end
                        end)
                    end
                end
                self.m_boxMsgBg.sizeDelta = Vector2.New(awardCount * 135, self.m_boxMsgBg.sizeDelta.y)
                self.m_boxMsgScrollView.sizeDelta = Vector2.New(awardCount * 135, self.m_boxMsgScrollView.sizeDelta.y)
            end
        end
    end

end 

function UITaskView:UpdateDataTaskItem(item, realIndex)
    if self.m_taskList then
        if item and realIndex > 0 and realIndex <= #self.m_taskList then
            local data = self.m_taskList[realIndex]
            item:UpdateData(data, self.m_currTaskTable)
        end
    end
end

function UITaskView:NtfTaskChg()
    self:HandleTaskType()
end

return UITaskView