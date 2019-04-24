local UIUtil = UIUtil
local Vector2 = Vector2
local Vector3 = Vector3
local Language = Language
local coroutine = coroutine
local Quaternion = Quaternion
local string_format = string.format
local UserItemPrefab = TheGameIds.UserItemPrefab
local UserItemClass = require("UI.UIUser.UserItem")
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local UserMgr = Player:GetInstance():GetUserMgr()
local TextMeshProUGUI = CS.TMPro.TextMeshProUGUI
local Type_LayoutElement = typeof(CS.UnityEngine.UI.LayoutElement)

local ChatSysItem = BaseClass("ChatSysItem", UIBaseItem)
local base = UIBaseItem

function ChatSysItem:OnCreate()
    base.OnCreate(self) 
   
    self.m_contentBgTrans,
    self.m_contentTextRectTrans
    = UIUtil.GetChildRectTrans(self.transform, {
        "ContentBg",
        "ContentText",
        
    })

    self.m_contentText = self.m_contentTextRectTrans:GetComponent(typeof(TextMeshProUGUI))

    self.m_sysNameText = UIUtil.GetChildTexts(self.transform, {
        "ContentBg/SysNameBg/SysNameText"
    })

    self.m_layoutElement = self.transform:GetComponent(Type_LayoutElement)
end

function ChatSysItem:OnDestroy()
    self.m_contentBgTrans = nil
    self.m_contentTextRectTrans = nil
    self.m_contentText = nil

    base.OnDestroy(self)
end

function ChatSysItem:UpdateData(chatData)
    if chatData then
        self.m_contentText.text = chatData.words
        self.m_sysNameText.text = '系统' --todo

        local textHeight = self.m_contentText.preferredHeight
        if textHeight < 26.1 then
            self.m_layoutElement.preferredHeight = 100
        else
            self.m_layoutElement.preferredHeight = 100 + textHeight - 26
        end

        local textWidth = self.m_contentText.preferredWidth 
        --更新文字底图
        self.m_contentBgTrans.sizeDelta = Vector2.New(textWidth + 45, 40 + textHeight)
        
    end
end

return ChatSysItem