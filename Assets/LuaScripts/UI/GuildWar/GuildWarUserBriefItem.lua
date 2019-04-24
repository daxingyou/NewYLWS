local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local string_format = string.format
local UserItemPrefab = TheGameIds.UserItemPrefab
local UserItemClass = require("UI.UIUser.UserItem")
local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()

local GuildWarUserBriefItem = BaseClass("GuildWarUserBriefItem", UIBaseItem)
local base = UIBaseItem

function GuildWarUserBriefItem:OnCreate()
    base.OnCreate(self)

    self.m_uID = 0

    self.m_checkBuZhenBtnText, self.m_winRateText, self.m_playerNameText, self.m_postNameText
    = UIUtil.GetChildTexts(self.transform, {
        "CheckBuZhenBtn/CheckBuZhenBtnText",
        "WinRateText",
        "PlayerNameText",
        "PostImage/PostNameText"
    })

    self.m_checkBuZhenBtnText.text = Language.GetString(2330)

    self.m_checkBuZhenBtn, self.m_userIconRoot = UIUtil.GetChildTransforms(self.transform, {
        "CheckBuZhenBtn",
        "UserIconPos"
    })

    self.m_postImage = UIUtil.AddComponent(UIImage, self, "PostImage", AtlasConfig.DynamicLoad)


    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_checkBuZhenBtn.gameObject, onClick)

    self.m_userItemSeq = 0
    self.m_userItem = false
end

function GuildWarUserBriefItem:OnClick(go)
    if go.name == "CheckBuZhenBtn" then
        GuildWarMgr:ReqUserDefBuZhenInfo(self.m_uID)
    end
end

function GuildWarUserBriefItem:UpdateData(guildUserBriefData, index)
    if guildUserBriefData then
        self.m_uID = guildUserBriefData.uid

        --军团职称
        self.m_postImage.gameObject:SetActive(guildUserBriefData.post > 0)
        UILogicUtil.SetGuildPostImage(self.m_postImage, guildUserBriefData.post)
        self.m_postNameText.text = guildUserBriefData.post_name

        self.m_playerNameText.text = guildUserBriefData.user_name
        if index == 1 then
            self.m_winRateText.text = string_format(Language.GetString(2331), guildUserBriefData.win_rate)
        else
            self.m_winRateText.text = ''
        end

        self:UpdateUserIcon(guildUserBriefData)
    end
end

function GuildWarUserBriefItem:UpdateUserIcon(guildUserBriefData)
    function loadCallBack()
        if self.m_userItem then
            self.m_userItem:UpdateData(guildUserBriefData.use_icon_data.icon, guildUserBriefData.use_icon_data.icon_box, guildUserBriefData.level)
        end
    end

    --更新玩家头像信息
    if self.m_userItem then
        loadCallBack()
    else
        if self.m_userItemSeq == 0 then
            self.m_userItemSeq = UIGameObjectLoaderInst:PrepareOneSeq()
            UIGameObjectLoaderInst:GetGameObject(self.m_userItemSeq, UserItemPrefab, function(obj)
                self.m_userItemSeq = 0
                if not obj then
                    return
                end
                self.m_userItem = UserItemClass.New(obj, self.m_userIconRoot, UserItemPrefab)
                loadCallBack()
            end)
        end
    end
end

function GuildWarUserBriefItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_checkBuZhenBtn.gameObject)
    UIGameObjectLoaderInst:CancelLoad(self.m_userItemSeq)
    self.m_userItemSeq = 0

    if self.m_userItem then
        self.m_userItem:Delete()
        self.m_userItem = nil
    end

    base.OnDestroy(self)
end

return GuildWarUserBriefItem