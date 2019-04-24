
local UIUtil = UIUtil
local GuildMgr = Player:GetInstance().GuildMgr
local UserManager = Player:GetInstance():GetUserMgr()
local CommonDefine = CommonDefine
local UITipsHelper = require "UI.Common.UITipsHelper"
local string_split = string.split
local string_format = string.format
local FriendMgr = Player:GetInstance():GetFriendMgr()

local GuildMenuView = BaseClass("GuildMenuView", UIBaseView)
local base = UIBaseView

function GuildMenuView:OnCreate()
    base.OnCreate(self)

    self.m_tips = self:AddComponent(UITipsHelper, "Container")

    local addFriendText, downNormalText, removeGuildText,
    checkInfoText, sendInfoText, guildInviteText

    addFriendText, self.m_chgFuTuanZhangText, self.m_chgZhangLaoText, downNormalText, removeGuildText,
    checkInfoText, sendInfoText,guildInviteText = UIUtil.GetChildTexts(self.transform, {
        "Container/addFriend/Text",
        "Container/chgFuTuanZhang/Text",
        "Container/chgZhangLao/Text",
        "Container/downNormal/Text",
        "Container/removeGuild/Text",
        "Container/checkInfo/Text",
        "Container/sendInfo/Text",
        "Container/guildInvite/Text"
    })

    self.m_addFriendBtn, self.m_chgFuTuanZhangBtn, self.m_chgZhangLaoBtn, self.m_downNormalBtn,
    self.m_removeGuildBtn, self.m_checkInfoBtn, self.m_sendInfoBtn, self.m_guildInviteBtn, self.m_closeBtn = UIUtil.GetChildTransforms(self.transform, {
        "Container/addFriend",
        "Container/chgFuTuanZhang",
        "Container/chgZhangLao",
        "Container/downNormal",
        "Container/removeGuild",
        "Container/checkInfo",
        "Container/sendInfo",
        "Container/guildInvite",
        "CloseBtn"
    })

    local btnTextList = {addFriendText, downNormalText, removeGuildText, checkInfoText, sendInfoText,guildInviteText}
    local btnTexts = string_split(Language.GetString(1407), "|")

    for i, v in ipairs(btnTexts) do
        if btnTextList[i] then
            btnTextList[i].text = v
        end
    end
   

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_addFriendBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_chgFuTuanZhangBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_chgZhangLaoBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_removeGuildBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_checkInfoBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_sendInfoBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_downNormalBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_guildInviteBtn.gameObject, onClick)
end

function GuildMenuView:OnClick(go)
    if go.name == "CloseBtn" then
        self:CloseSelf()
    elseif go.name == "addFriend" then
        UIManagerInst:OpenWindow(UIWindowNames.UIFriendRequest, self.m_itemUId)
        self:CloseSelf()
    elseif go.name == "chgFuTuanZhang" then
        GuildMgr:ReqPostDseploy(self.m_itemUId, CommonDefine.GUILD_POST_DEPUTY)
        self:CloseSelf()
    elseif go.name == "chgZhangLao" then
        GuildMgr:ReqPostDseploy(self.m_itemUId, CommonDefine.GUILD_POST_MILITARY)
        self:CloseSelf()
    elseif go.name == "downNormal" then
        GuildMgr:ReqPostDseploy(self.m_itemUId, CommonDefine.GUILD_POST_NORMAL)
        self:CloseSelf()
    elseif go.name == "removeGuild" then
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(1409), Language.GetString(1408),
        Language.GetString(632), Bind(GuildMgr, GuildMgr.ReqMemberKick, self.m_itemUId), Language.GetString(50))
        self:CloseSelf()
    elseif go.name == "checkInfo" then

        -- self:CloseSelf()
        UIManagerInst:OpenWindow(UIWindowNames.UIUserDetail, self.m_itemUId)

    elseif go.name == "sendInfo" then
        UIManagerInst:OpenWindow(UIWindowNames.UIFriendMain, 3, self.m_itemUId)
        self:CloseSelf()   
    elseif go.name == "guildInvite" then
        GuildMgr:ReqInvite(self.m_itemUId)
        self:CloseSelf()
    end 
end

function GuildMenuView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_addFriendBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_chgFuTuanZhangBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_chgZhangLaoBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_removeGuildBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_checkInfoBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_sendInfoBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_downNormalBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_guildInviteBtn.gameObject)
    base.OnDestroy(self)
end
 
function GuildMenuView:OnEnable(...)
    base.OnEnable(self, ...)

    _, inputPos, itemPost, itemUId,futuanzhangText,zhanglaoText,view_id,item_gid = ... 

    self.m_itemUId = itemUId or 0
    view_id = view_id or -1
    local myGuildData = GuildMgr.MyGuildData
    local userData = UserManager:GetUserData()

    self.m_chgFuTuanZhangBtn.gameObject:SetActive(true)
    self.m_chgZhangLaoBtn.gameObject:SetActive(true)
    self.m_downNormalBtn.gameObject:SetActive(true)
    self.m_removeGuildBtn.gameObject:SetActive(true)
    self.m_guildInviteBtn.gameObject:SetActive(false)

    if myGuildData.self_post == CommonDefine.GUILD_POST_COLONEL then
        if itemPost == CommonDefine.GUILD_POST_DEPUTY then
            self.m_chgFuTuanZhangBtn.gameObject:SetActive(false)
            self.m_chgZhangLaoBtn.gameObject:SetActive(false)
        elseif itemPost == CommonDefine.GUILD_POST_MILITARY then
            self.m_chgZhangLaoBtn.gameObject:SetActive(false)
        elseif itemPost == CommonDefine.GUILD_POST_NORMAL then
            self.m_downNormalBtn.gameObject:SetActive(false)
        end
    elseif myGuildData.self_post == CommonDefine.GUILD_POST_DEPUTY then
        if itemPost == CommonDefine.GUILD_POST_COLONEL or itemPost == CommonDefine.GUILD_POST_DEPUTY then
            self.m_chgFuTuanZhangBtn.gameObject:SetActive(false)
            self.m_chgZhangLaoBtn.gameObject:SetActive(false)
            self.m_removeGuildBtn.gameObject:SetActive(false)
            self.m_downNormalBtn.gameObject:SetActive(false)
        elseif itemPost == CommonDefine.GUILD_POST_MILITARY then
            self.m_chgFuTuanZhangBtn.gameObject:SetActive(false)
            self.m_chgZhangLaoBtn.gameObject:SetActive(false)
        else
            self.m_chgFuTuanZhangBtn.gameObject:SetActive(false)
            self.m_downNormalBtn.gameObject:SetActive(false)
        end 
    else 
        self.m_chgFuTuanZhangBtn.gameObject:SetActive(false)
        self.m_chgZhangLaoBtn.gameObject:SetActive(false)
        self.m_downNormalBtn.gameObject:SetActive(false)
        self.m_removeGuildBtn.gameObject:SetActive(false)
    end  
    if item_gid ~= nil and userData.guild_id ~= nil and myGuildData.self_post ~= CommonDefine.GUILD_POST_NORMAL then 
        local isInGuild = GuildMgr:IsInGuild(userData.guild_id,item_gid)
        
        if not isInGuild then 
            self.m_guildInviteBtn.gameObject:SetActive(true)
        end 
    end

    if view_id and view_id == CommonDefine.CHAT_VIEW then
        self.m_chgFuTuanZhangBtn.gameObject:SetActive(false)
        self.m_chgZhangLaoBtn.gameObject:SetActive(false)
        self.m_downNormalBtn.gameObject:SetActive(false)
        self.m_removeGuildBtn.gameObject:SetActive(false)
    end 
    
    self.m_addFriendBtn.gameObject:SetActive(not FriendMgr:CheckIsFriend(self.m_itemUId))

    if self.m_tips then
        self.m_tips:Init(Vector2.New(300, 0), inputPos)
    end

    zhanglaoText = zhanglaoText or ''
    self.m_chgZhangLaoText.text = string_format(Language.GetString(1458), zhanglaoText) 
    futuanzhangText = futuanzhangText or ''
    self.m_chgFuTuanZhangText.text = string_format(Language.GetString(1458), futuanzhangText)
end

function GuildMenuView:OnDisable(...)
    base.OnDisable(self)
end

return GuildMenuView