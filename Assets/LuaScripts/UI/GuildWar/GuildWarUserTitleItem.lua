local UIUtil = UIUtil
local string_format = string.format


local base = UIBaseItem
local GuildWarUserTitleItem = BaseClass("GuildWarUserTitleItem", UIBaseItem)

function GuildWarUserTitleItem:OnCreate()
    base.OnCreate(self)

    self.m_userTitleIconImage = UIUtil.AddComponent(UIImage, self, "TitleIconImage", AtlasConfig.DynamicLoad)
    self.m_titleNameText,  self.m_defWinRateDescText, self.m_defWinRateText 
    = UIUtil.GetChildTexts(self.transform, {
        "TitleNameText",
        "DefWinRateDescText",
        "DefWinRateText"
    })

    self.m_defWinRateDescText.text = Language.GetString(2394)
end

function GuildWarUserTitleItem:UpdateData(guildWarCraftDefTitleCfg)
    if guildWarCraftDefTitleCfg then
        self.m_userTitleIconImage:SetAtlasSprite(guildWarCraftDefTitleCfg.icon..".png")

        local stage = guildWarCraftDefTitleCfg.id
        if stage == 1 then
            self.m_titleNameText.text = string_format(Language.GetString(2320), guildWarCraftDefTitleCfg.name)
        elseif stage == 2 then
            self.m_titleNameText.text = string_format(Language.GetString(2319), guildWarCraftDefTitleCfg.name)
        elseif stage == 3 then
            self.m_titleNameText.text = string_format(Language.GetString(2318), guildWarCraftDefTitleCfg.name)
        elseif stage == 4 then
            self.m_titleNameText.text = string_format(Language.GetString(2317), guildWarCraftDefTitleCfg.name)
        end

        if stage == 4 then
            self.m_defWinRateText.text = string_format(Language.GetString(2322), guildWarCraftDefTitleCfg.winrate_max)
        else
            local str = string_format(Language.GetString(2321), guildWarCraftDefTitleCfg.winrate_min, guildWarCraftDefTitleCfg.winrate_max)
            self.m_defWinRateText.text = str
        end
    end
end

function GuildWarUserTitleItem:OnDestroy()
    if self.m_userTitleIconImage then
        self.m_userTitleIconImage:Delete()
        self.m_userTitleIconImage = nil
    end

    base.OnDestroy(self)
end

return GuildWarUserTitleItem