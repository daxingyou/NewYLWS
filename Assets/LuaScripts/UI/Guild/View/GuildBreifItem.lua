local math_ceil = math.ceil
local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local ConfigUtil = ConfigUtil
local string_format = string.format

local GuildBreifItem = BaseClass("GuildBreifItem", UIBaseItem)
local base = UIBaseItem

local GuildMgr = Player:GetInstance().GuildMgr

function GuildBreifItem:OnCreate()

    self.m_selectImgeGo = UIUtil.GetChildTransforms(self.transform, {
        "SelectImage",
    })

    self.m_selectImgeGo = self.m_selectImgeGo.gameObject

    self.m_rankNumImage = UIUtil.AddComponent(UIImage, self, "rankNumImage", AtlasConfig.DynamicLoad)
    self.m_guildIconImage = UIUtil.AddComponent(UIImage, self, "Icon/GuildIconImage", AtlasConfig.DynamicLoad2)

    self.m_rankNumText, self.m_guildNameText, self.m_guildLevelText, self.m_guildMemberNumText =  
    UIUtil.GetChildTexts(self.transform, {"rankNumText", "GuildNameText" , "GuildLevelText", "GuildMemberNumText"})

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self:GetGameObject(), onClick)

    self.m_isOnSelected = false
    self.m_personCount = -1
    self.m_index = 0
end

function GuildBreifItem:OnClick(go)
    if go == self:GetGameObject() then
        if self.m_selfOnClickCallback then
             self.m_selfOnClickCallback(self)
        end
     end
end

function GuildBreifItem:OnDestroy()
    UIUtil.RemoveClickEvent(self:GetGameObject())
    self.m_selfOnClickCallback = nil
    base.OnDestroy(self)
end

function GuildBreifItem:UpdateData(guildBriefData, index, isOnSelected, selfOnClickCallback, isRank)
    if guildBriefData then
        self.m_index = index

        self:UpdateRankNum(guildBriefData.rank)

        local guildIconCfg = ConfigUtil.GetGuildIconCfgByID(guildBriefData.icon)
        if guildIconCfg then
            self.m_guildIconImage:SetAtlasSprite(guildIconCfg.icon..".png")
        end

        self.m_guildNameText.text = guildBriefData.name
        self.m_guildLevelText.text = string_format(Language.GetString(1327), guildBriefData.level)
        if isRank then
            self.m_guildMemberNumText.text = guildBriefData.warcraft_score
        else
            local strID = guildBriefData.member_count < guildBriefData.member_limit and 1328 or 1329
            self.m_guildMemberNumText.text = string_format(Language.GetString(strID), guildBriefData.member_count, guildBriefData.member_limit)
        end
        self.m_personCount = string_format("%d/%d", guildBriefData.member_count, guildBriefData.member_limit)
        self.m_isOnSelected = isOnSelected or false
        self.m_selfOnClickCallback = selfOnClickCallback
        self:SetOnSelectState(self.m_isOnSelected)
    end
end

function GuildBreifItem:UpdateRankNum(rankNum)
    if rankNum <= 3 then
        --前三名
        self.m_rankNumImage.gameObject:SetActive(true)
        self.m_rankNumText.gameObject:SetActive(false)
        UILogicUtil.SetNumSpt(self.m_rankNumImage, rankNum, true)
    else
        self.m_rankNumImage.gameObject:SetActive(false)
        self.m_rankNumText.gameObject:SetActive(true)
        self.m_rankNumText.text = math_ceil(rankNum)
    end
end

function GuildBreifItem:GetPersonCount()
    return self.m_personCount
end

function GuildBreifItem:SetOnSelectState(isOnSelected)
    self.m_selectImgeGo:SetActive(isOnSelected)
end

function GuildBreifItem:IsOnSelected()
    return self.m_isOnSelected
end

function GuildBreifItem:GetIndex()
    return self.m_index
end

return GuildBreifItem
