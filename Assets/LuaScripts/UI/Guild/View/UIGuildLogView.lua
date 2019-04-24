
local UIGuildLogView = BaseClass("UIGuildLogView", UIBaseView)
local base = UIBaseView

local GuildLogItem = require "UI.Guild.View.GuildLogItem"
local GuildMgr = Player:GetInstance().GuildMgr
local GameObject = CS.UnityEngine.GameObject
local table_insert = table.insert
local string_format = string.format

function UIGuildLogView:OnCreate()
    base.OnCreate(self)

    self.m_closeBtn, self.m_logItemPrefab, self.m_contentView = UIUtil.GetChildTransforms(self.transform, {
        "CloseBtn",
        "DescPrefab",
        "Container/ItemScrollView/Viewport/ItemContent"
    })

    self.m_logItemPrefab = self.m_logItemPrefab.gameObject

    local titleText = UIUtil.FindText(self.transform, "Container/bg2/TitleBg/TitleText")
    titleText.text = Language.GetString(1399)

    self.m_logItemList = {}
    self.m_oneDayLogList = {}
    self.m_twoDayLogList = {}
    self.m_threeDayLogList = {}

    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
end

function UIGuildLogView:OnClick(go)
    if go.name == "CloseBtn" then
        self:CloseSelf()   
    end
end

function UIGuildLogView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    base.OnDestroy(self)
end

function UIGuildLogView:OnAddListener()
    base.OnAddListener(self)

    self:AddUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_DAILY, self.RspGuildDaily)
end

function UIGuildLogView:OnRemoveListener()
    base.OnRemoveListener(self)

    self:RemoveUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_DAILY, self.RspGuildDaily)
end

function UIGuildLogView:OnEnable(...)
    base.OnEnable(self, ...)
    
    GuildMgr:ReqGuildDaily()
end

function UIGuildLogView:GetWeekDay(index)
    if index == 1 then
        return "周日"
    elseif index == 2 then
        return "周一"
    elseif index == 3 then
        return "周二"
    elseif index == 4 then
        return "周三"
    elseif index == 5 then
        return "周四"
    elseif index == 6 then
        return "周五"
    elseif index == 7 then
        return "周六"
    end
end

function UIGuildLogView:GetBeforeDay(dayIndex)
    dayIndex = tonumber(dayIndex)
    if dayIndex == 1 then
        return 7
    else
        return dayIndex - 1
    end
end

function UIGuildLogView:RspGuildDaily(msg)
    local oneDay = os.date("*t", Player:GetInstance():GetServerTime()).wday
    local twoDay = self:GetBeforeDay(oneDay)
    local threeDay = self:GetBeforeDay(twoDay)
    if msg.guild_daily_list then
        local list = msg.guild_daily_list
        for i = #list, 1, -1 do
            local timeData = os.date("*t", list[i].curr_time)

            if timeData.wday == oneDay then
                table_insert(self.m_oneDayLogList, list[i])
            elseif timeData.wday == twoDay then
                table_insert(self.m_twoDayLogList, list[i])
            elseif timeData.wday == threeDay then
                table_insert(self.m_threeDayLogList, list[i])
            end
        end
    end

    local logCount = 0
    if #self.m_oneDayLogList > 0 then
        logCount = logCount + 1
    end
    if #self.m_twoDayLogList > 0 then
        logCount = logCount + 1
    end
    if #self.m_threeDayLogList > 0 then
        logCount = logCount + 1
    end

    for i = 1, logCount do
        local logItem = self.m_logItemList[i]
        if not logItem then
            local go = GameObject.Instantiate(self.m_logItemPrefab)
            logItem = GuildLogItem.New(go, self.m_contentView)
            table_insert(self.m_logItemList, logItem)
            if i == 1 and self.m_oneDayLogList[1] then
                local timeData = os.date("*t", self.m_oneDayLogList[1].curr_time)
                logItem:UpdateText(string_format("%s %d月%d日", self:GetWeekDay(oneDay), timeData.month, timeData.day))
            elseif i == 2 and self.m_twoDayLogList[1] then
                local timeData = os.date("*t", self.m_twoDayLogList[1].curr_time)
                logItem:UpdateText(string_format("%s %d月%d日", self:GetWeekDay(twoDay), timeData.month, timeData.day))
            elseif i == 3 and self.m_threeDayLogList[1] then
                local timeData = os.date("*t", self.m_threeDayLogList[1].curr_time)
                logItem:UpdateText(string_format("%s %d月%d日", self:GetWeekDay(threeDay), timeData.month, timeData.day))
            end
        end
    end

    if self.m_logItemList[1] then
        for i, v in pairs(self.m_oneDayLogList) do
            if v then
                self:GetDailyString(v, self.m_logItemList[1])
            end
        end
    end
    if self.m_logItemList[2] then
        for i, v in pairs(self.m_twoDayLogList) do
            if v then
                self:GetDailyString(v, self.m_logItemList[2])
            end
        end
    end
    if self.m_logItemList[3] then
        for i, v in pairs(self.m_threeDayLogList) do
            if v then
                self:GetDailyString(v, self.m_logItemList[3])
            end
        end
    end
end

function UIGuildLogView:GetDailyString(dailyList, logItem)
    if dailyList.daily_type == 1440 then
        logItem:UpdateText(string_format(Language.GetString(1440), dailyList.member1.name))
    elseif dailyList.daily_type == 1441 then
        logItem:UpdateText(string_format(Language.GetString(1441), dailyList.member1.name))
    elseif dailyList.daily_type == 1442 then
        local str = ""
        if dailyList.param1 == 1 then
            str = Language.GetString(1435)
        elseif dailyList.param1 == 2 or 3 then
            str = Language.GetString(1436)
        end
        logItem:UpdateText(string_format(Language.GetString(1442), dailyList.member1.name, dailyList.str1, dailyList.param2, str))
    elseif dailyList.daily_type == 1443 then
        logItem:UpdateText(string_format(Language.GetString(1443), dailyList.guild_name1))
    elseif dailyList.daily_type == 1444 then
        logItem:UpdateText(string_format(Language.GetString(1444), dailyList.guild_name1))
    elseif dailyList.daily_type == 1445 then
        logItem:UpdateText(string_format(Language.GetString(1445), dailyList.guild_name1))
    elseif dailyList.daily_type == 1446 then
        logItem:UpdateText(string_format(Language.GetString(1446), dailyList.guild_name1))
    elseif dailyList.daily_type == 1447 then
        logItem:UpdateText(string_format(Language.GetString(1447), dailyList.guild_name1))
    elseif dailyList.daily_type == 1448 then
        logItem:UpdateText(string_format(Language.GetString(1448), dailyList.guild_name1))
    elseif dailyList.daily_type == 1449 then
        logItem:UpdateText(string_format(Language.GetString(1449), dailyList.str1))
    elseif dailyList.daily_type == 1450 then
        logItem:UpdateText(string_format(Language.GetString(1450)))
    elseif dailyList.daily_type == 1451 then
        logItem:UpdateText(string_format(Language.GetString(1451), dailyList.member1.name, dailyList.member2.name))
    elseif dailyList.daily_type == 1452 then
        logItem:UpdateText(string_format(Language.GetString(1452), dailyList.member1.name, dailyList.str1))
    elseif dailyList.daily_type == 1453 then
        logItem:UpdateText(string_format(Language.GetString(1453), dailyList.member1.name, GuildMgr:GetPostName(dailyList.param2)))
    elseif dailyList.daily_type == 1454 then
        logItem:UpdateText(string_format(Language.GetString(1454), dailyList.member1.name, GuildMgr:GetPostName(dailyList.param2)))
    elseif dailyList.daily_type == 1455 then
        logItem:UpdateText(string_format(Language.GetString(1455), dailyList.member1.name, dailyList.str1))
    end


end

function UIGuildLogView:OnDisable()
    for i, v in ipairs(self.m_logItemList) do 
        v:Delete()
    end
    self.m_logItemList = {}

    self.m_oneDayLogList = {}
    self.m_twoDayLogList = {}
    self.m_threeDayLogList = {}

    base.OnDisable(self)
end

return UIGuildLogView