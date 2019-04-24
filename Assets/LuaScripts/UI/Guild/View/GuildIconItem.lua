local UIUtil = UIUtil

local GuildIconItem = BaseClass("GuildIconItem", UIBaseItem)
local base = UIBaseItem


function GuildIconItem:OnCreate()
    base.OnCreate(self)

    self.m_isSelect = false
    self.m_iconID = false

    self.m_guildIconImage = UIUtil.AddComponent(UIImage, self, "GuildIconImage", AtlasConfig.DynamicLoad2)
    self.m_checkSptGo = UIUtil.FindTrans(self.transform, "CheckImage")
    self.m_checkSptGo = self.m_checkSptGo.gameObject

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self:GetGameObject(), onClick)
end

function GuildIconItem:OnClick(go)
    if go == self:GetGameObject() then
        if self.m_selfOnClickCallback then
            self.m_selfOnClickCallback(self)
        end
    end
end

function GuildIconItem:UpdateData(iconID, isSelect, selfOnClickCallback)
    local guildIconCfg = ConfigUtil.GetGuildIconCfgByID(iconID)
    if guildIconCfg then

        self.m_iconID = iconID
        self.m_guildIconImage:SetAtlasSprite(guildIconCfg.icon..".png")

        isSelect = isSelect or false
        self.m_isSelect = isSelect
        self.m_selfOnClickCallback = selfOnClickCallback
        self.m_checkSptGo:SetActive(isSelect)
    end
end

function GuildIconItem:OnDestroy()
    UIUtil.RemoveClickEvent(self:GetGameObject())
    if self.m_guildIconImage then
        self.m_guildIconImage:Delete()
        self.m_guildIconImage = nil
    end

    UIUtil.RemoveClickEvent(self:GetGameObject())

    self.m_selfOnClickCallback = nil
    base.OnDestroy(self)
end

function GuildIconItem:IsSelect()
    return self.m_isSelect
end

function GuildIconItem:SetOnSelectState(isSelect)
    self.m_checkSptGo:SetActive(isSelect)
    self.m_isSelect = isSelect
end

function GuildIconItem:GetIconID()
    return self.m_iconID
end

return GuildIconItem