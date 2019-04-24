local GuildWarCityLineupSelectItem = BaseClass("GuildWarCityLineupSelectItem", UIBaseItem)
local base = UIBaseItem

local string_format = string.format
local ConfigUtil = ConfigUtil
local LineupMgr = Player:GetInstance():GetLineupMgr()
local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()
local UIUtil = UIUtil

local lineupNames = CUtil.SplitString(Language.GetString(2336), '|')

function GuildWarCityLineupSelectItem:OnCreate()
    base.OnCreate(self)

    self.m_buzhenID = 0
    self.m_cityID = 0
    self.m_showTips = ''

    self.m_lineupText, self.m_cityNameText = UIUtil.GetChildTexts(self.transform, {
        "lineupItemImage/lineupText",
        "CityNameText"
    })

    self.m_lineupItem = UIUtil.GetChildTransforms(self.transform, {
        "lineupItemImage",
    })

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_lineupItem.gameObject, onClick)
end

function GuildWarCityLineupSelectItem:OnClick(go)
    if go.name == "lineupItemImage" then
        if self.m_showTips ~= '' then
            UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(2327), self.m_showTips, 
                Language.GetString(10), Bind(self, self.ConfirmLineup), Language.GetString(5))

            return
        end

        self:ConfirmLineup()
    end
end

function GuildWarCityLineupSelectItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_lineupItem.gameObject)
    base.OnDestroy(self)
end

function GuildWarCityLineupSelectItem:UpdateData(cityID, buzhenID)
    local lineupData = LineupMgr:GetLineupDataByID(buzhenID)
    if lineupData then
        self.m_cityID = cityID
        self.m_buzhenID = buzhenID

        local index = buzhenID % 10000
        local lineupName = ''
        if index <= #lineupNames then
            lineupName = lineupNames[index]
            self.m_lineupText.text = lineupName
        end

        local cityConfig = ConfigUtil.GetGuildWarCraftCityCfgByID(lineupData.def_city_id)
        if cityConfig then
            self.m_cityNameText.text = cityConfig.name
            self.m_showTips = string_format(Language.GetString(2294), lineupName, cityConfig.name)
        else
            self.m_cityNameText.text = ""
        end
    end
end

function GuildWarCityLineupSelectItem:ConfirmLineup()
    if self.m_cityID > 0 and self.m_buzhenID > 0 then
        GuildWarMgr:ReqSendDefBuZhenToCity(self.m_cityID, self.m_buzhenID)
    end
end

return GuildWarCityLineupSelectItem