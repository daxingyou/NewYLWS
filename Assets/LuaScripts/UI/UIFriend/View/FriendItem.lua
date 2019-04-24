local UIUtil = UIUtil
local TimeUtil = TimeUtil
local Language = Language
local UILogicUtil = UILogicUtil
local string_format = string.format
local UIWindowNames = UIWindowNames
local UIManagerInst = UIManagerInst
local UserItemPrefab = TheGameIds.UserItemPrefab
local UserItemClass = require("UI.UIUser.UserItem")
local FriendMgr = Player:GetInstance():GetFriendMgr()
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()

local FriendItem = BaseClass("FriendItem", UIBaseItem)
local base = UIBaseItem

function FriendItem:OnCreate()
    base.OnCreate(self)

    self:InitView()

    self:HandleClick()
end

function FriendItem:InitView()
    self.m_friendItemBgTrans,
    self.m_detailBtnTrans,
    self.m_takeStaminaBtnTrans,
    self.m_sendStaminaBtnTrans,
    self.m_requestFriendBtnTrans,
    self.m_userIconPosTrans,
    self.m_selectSpt,
    self.m_redPointImgTr = UIUtil.GetChildRectTrans(self.transform, {
        "friendItemBg",
        "detailBtn",
        "takeStaminaBtn",
        "sendStaminaBtn",
        "requestFriendBtn",
        "userIconPos",
        "selectSpt",
        "redPointImg",
    })

    self.m_freindNameText,
    self.m_lastLoginTimeText,
    self.m_redPointTxt = UIUtil.GetChildTexts(self.transform, {
        "freindNameText",
        "lastLoginTimeText",
        "redPointImg/Text",
    })

    self.m_data = nil
    self.m_uid = 0
    self.m_isFriendList = false
    self.m_isBlackList = false
    self.m_selfOnClickCallback = nil
    self.m_isSelected = false

    self.m_userItem = nil
    self.m_userItemSeq = 0

    self.m_redPointImgTr.gameObject:SetActive(false)
end

function FriendItem:OnDestroy()
    self:RemoveClick()

    self.m_friendItemBgTrans = nil
    self.m_detailBtnTrans = nil
    self.m_takeStaminaBtnTrans = nil
    self.m_sendStaminaBtnTrans = nil
    self.m_requestFriendBtnTrans = nil
    self.m_userIconPosTrans = nil
    self.m_selectSpt = nil
    
    self.m_freindNameText = nil
    self.m_lastLoginTimeText = nil

    self.m_data = nil
    self.m_selfOnClickCallback = nil

    if self.m_userItemSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_userItemSeq)
        self.m_userItemSeq = nil
    end
    if self.m_userItem then
        self.m_userItem:Delete()
        self.m_userItem = nil
    end

    base.OnDestroy(self)
end

function FriendItem:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_friendItemBgTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_detailBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_takeStaminaBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_sendStaminaBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_requestFriendBtnTrans.gameObject, onClick)
end

function FriendItem:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_friendItemBgTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_detailBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_takeStaminaBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_sendStaminaBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_requestFriendBtnTrans.gameObject)
end

function FriendItem:OnClick(go, x, y)
    if not go then
        return
    end
    local goName = go.name
    if goName == "friendItemBg" then
        if self.m_selfOnClickCallback then
            self.m_selfOnClickCallback(self)
        end
    elseif goName == "detailBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIFriendDetail, self.m_data, self.m_isFriendList, self.m_isBlackList)
    elseif goName == "takeStaminaBtn" then
        FriendMgr:ReqTakeStamina(self.m_uid)
    elseif goName == "sendStaminaBtn" then
        FriendMgr:ReqSendStamina(self.m_uid)
    elseif goName == "requestFriendBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIFriendRequest, self.m_uid)
    end
end

function FriendItem:UpdateData(data, isFriendList, isBlackList, selfOnClick)
    if not data or not data.friend_brief then
        return
    end
    self.m_data = data
    self.m_selfOnClickCallback = selfOnClick
    self.m_uid = data.friend_brief.uid
    if isFriendList ~= nil then
        self.m_isFriendList = isFriendList
    else
        self.m_isFriendList = false
    end
    if isBlackList ~= nil then
        self.m_isBlackList = isBlackList
    else
        self.m_isBlackList = false
    end

    self.m_freindNameText.text = data.friend_brief.name

    local friend_brief = data.friend_brief
    local isFriend = FriendMgr:CheckIsFriend(self.m_uid)
    self.m_detailBtnTrans.gameObject:SetActive(isFriend)
    self.m_requestFriendBtnTrans.gameObject:SetActive(not isFriend)
    self.m_takeStaminaBtnTrans.gameObject:SetActive(isFriend and data.stamina_status == 3)
    self.m_sendStaminaBtnTrans.gameObject:SetActive(isFriend and data.stamina_status == 1 and isFriend)

    local timeStr = UILogicUtil.GetLoginStateOrPassTime(data.last_login_time)
    if data.last_login_time < 0 then
        self.m_lastLoginTimeText.text = ""
    else
        self.m_lastLoginTimeText.text = timeStr
    end
    
    --更新玩家头像信息
    if self.m_userItem then
        if friend_brief.use_icon then
            self.m_userItem:UpdateData(friend_brief.use_icon.icon, friend_brief.use_icon.icon_box, friend_brief.level)
        end
    else
        self.m_userItemSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObject(self.m_userItemSeq, UserItemPrefab, function(obj)
            self.m_userItemSeq = 0
            if not obj then
                return
            end
            local userItem = UserItemClass.New(obj, self.m_userIconPosTrans, UserItemPrefab)
            if userItem then
                userItem:SetLocalScale(Vector3.New(0.9, 0.9, 0.9))
                if friend_brief.use_icon then
                    userItem:UpdateData(friend_brief.use_icon.icon, friend_brief.icon_box, friend_brief.level)
                end
                self.m_userItem = userItem
            end
        end)
    end

    self:SetSelectState(self.m_isSelected)
    self:UpdateRedPointStatus(data)
end

function FriendItem:UpdateRedPointStatus(data)
    local count = math.ceil(data.unread_msg_count)
    if count > 0 then
        self.m_redPointImgTr.gameObject:SetActive(true)
    else
        self.m_redPointImgTr.gameObject:SetActive(false)
    end
    self.m_redPointTxt.text = count
end

function FriendItem:SetRedPointStatus(status)
    self.m_redPointImgTr.gameObject:SetActive(status)
end

function FriendItem:GetUID()
    return self.m_uid
end

function FriendItem:SetSelectState(isSelect)
    if self.m_selectSpt then
        self.m_isSelected = isSelect
        self.m_selectSpt.gameObject:SetActive(isSelect)
    end
end

return FriendItem