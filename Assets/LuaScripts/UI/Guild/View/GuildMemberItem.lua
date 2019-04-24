local string_split = string.split
local math_ceil = math.ceil

local GuildMemberItem = BaseClass("GuildMemberItem", UIBaseItem)
local base = UIBaseItem

local GuildMgr = Player:GetInstance().GuildMgr
local UserItem = require "UI.UIUser.UserItem"
local UIUtil = UIUtil
local CommonDefine = CommonDefine


function GuildMemberItem:OnCreate()

    self.m_guildMemberData = nil
    self.m_uid = nil
    self.m_post = nil
    self.m_seq = 0
    self.m_userIconItem = nil
    self.m_selfOnClickCallback = nil
    self.m_isOnSelected = false
    self.m_index = 0
    self.m_headIconOnClickCallback = nil

    self:InitView()
end

function GuildMemberItem:OnDestroy()
    self.m_guildMemberData = nil
    self.m_selfOnClickCallback = nil
    self.m_headIconOnClickCallback = nil

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0

    if self.m_userIconItem then
        self.m_userIconItem:Delete()
        self.m_userIconItem = nil
    end

    if self.m_postImage then
        self.m_postImage:Delete()
        self.m_postImage = nil
    end
    
    UIUtil.RemoveClickEvent(self:GetGameObject())
    UIUtil.RemoveClickEvent(self.m_worshipBtn)

    base.OnDestroy(self)
end

function GuildMemberItem:InitView()

    local worshipBtnText

    self.m_postImage = UIUtil.AddComponent(UIImage, self, "PostImage", AtlasConfig.DynamicLoad)
    self.m_postNameText, self.m_playerNameText, self.m_totalDonationText, 
    self.m_weeklyDonationText, self.m_onlineText, worshipBtnText = UIUtil.GetChildTexts(self.transform, {
        "PostImage/PostNameText",  "PlayerNameText" , 
        "TotalDonationText", "WeeklyDonationText" , "OnlineText", "WorshipBtn/WorshipBtnText"})

    self.m_selectImgeGo, self.m_iconParent, self.m_worshipBtn = UIUtil.GetChildTransforms(self.transform, {
        "SelectImage", 
        "IconParent",
        "WorshipBtn"
    })
    
    self.m_selectImgeGo = self.m_selectImgeGo.gameObject
    self.m_worshipBtn = self.m_worshipBtn.gameObject
    worshipBtnText.text = Language.GetString(1369)


    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self:GetGameObject(), onClick)
    UIUtil.AddClickEvent(self.m_worshipBtn, onClick)
end

function GuildMemberItem:OnClick(go)
    if go == self:GetGameObject() then
        if self.m_selfOnClickCallback then
            self.m_selfOnClickCallback(self)
        end
    elseif go == self.m_worshipBtn then
        if self.m_uid then
            UIManagerInst:OpenWindow(UIWindowNames.UIGuildWorship, self.m_uid)
        end
    end
end


function GuildMemberItem:UpdateData(guildMemberData, index, selfOnClickCallback, selfHeadIconCallback)
    if guildMemberData then

        self.m_index = index
        self.m_guildMemberData = guildMemberData
        self.m_uid = guildMemberData.uid
        self.m_post = guildMemberData.post

        self.m_playerNameText.text = guildMemberData.user_name
        self.m_totalDonationText.text = math_ceil(guildMemberData.sum_huoyue)
        self.m_weeklyDonationText.text = math_ceil(guildMemberData.week_huoyue)

        local canWorship = GuildMgr:CanWorship(guildMemberData.uid, guildMemberData.level)
        self.m_worshipBtn:SetActive(canWorship)
        -- print("canWorship ",canWorship)
        if not canWorship then

            if guildMemberData.off_online_time == 0 then
                self.m_onlineText.text = Language.GetString(1346)
            else
                self.m_onlineText.text = string.format("<color=#9d9d9d>%s</color>", TimeUtil.GetTimePassStr(guildMemberData.off_online_time))
            end
        else
            self.m_onlineText.text = ""
        end
       
        self:UpdatePost(guildMemberData)
        self.m_headIconOnClickCallback = selfHeadIconCallback
        self.m_selfOnClickCallback = selfOnClickCallback
        
        self:UpdateUserIcon()
        self:SetOnSelectState(self.m_isOnSelected)
    end
    
end

function GuildMemberItem:UpdatePost(guildMemberData)

    self.m_postNameText.text = GuildMgr:GetPostName(guildMemberData.post)
    self.m_postImage.gameObject:SetActive(guildMemberData.post > 0)

    if guildMemberData.post == 0 then
        return
    end

    UILogicUtil.SetGuildPostImage(self.m_postImage, guildMemberData.post)
end

function GuildMemberItem:UpdateUserIcon()
    if not self.m_guildMemberData then
        return
    end

    if self.m_userIconItem == nil then
        if self.m_seq == 0 then
            self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq() 
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, TheGameIds.UserItemPrefab, function(obj)
                self.m_seq = 0
                if not IsNull(obj) then
                    if self.m_guildMemberData then
                        self.m_userIconItem = UserItem.New(obj, self.m_iconParent, TheGameIds.UserItemPrefab)
                        self.m_userIconItem:UpdateData(self.m_guildMemberData.icon, self.m_guildMemberData.icon_box, 
                            self.m_guildMemberData.level, self.m_headIconOnClickCallback, false, self)
                    end
                end
            end)
        end
    else
        self.m_userIconItem:UpdateData(self.m_guildMemberData.icon, self.m_guildMemberData.icon_box, 
        self.m_guildMemberData.level, self.m_headIconOnClickCallback, false, self)
    end
end

function GuildMemberItem:SetOnSelectState(isOnSelected)
    self.m_selectImgeGo:SetActive(isOnSelected)
end

function GuildMemberItem:IsOnSelected()
    return self.m_isOnSelected
end

function GuildMemberItem:GetIndex()
    return self.m_index
end

function GuildMemberItem:GetPost()
    return self.m_post
end

function GuildMemberItem:GetUId()
    return self.m_uid
end

function GuildMemberItem:GetUserIconPosition()
    if self.m_userIconItem then
        return self.m_userIconItem:GetTransform().position
    end
end

return GuildMemberItem