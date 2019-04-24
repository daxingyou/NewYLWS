local UserItem = require "UI.UIUser.UserItem"
local base = UIBaseItem
local ServerRoleItem = BaseClass("ServerRoleItem", base)

function ServerRoleItem:OnCreate()
    base.OnCreate(self)
    
    self.m_serverData = nil
    self.m_userIconItem = nil
    self.m_seq = 0
    self.m_nameText, self.m_roleNameText = UIUtil.GetChildTexts(self.transform, {
        "bg/nameText",
        "bg/roleNameText",
    })

    self.m_clickBtn, self.m_iconParent = UIUtil.GetChildTransforms(self.transform, {
        "bg/clickBtn",
        "bg",
    })
    
    UIUtil.AddClickEvent(self.m_clickBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick))
end

function ServerRoleItem:SetData(serverData)
    self.m_serverData = serverData
    self.m_nameText.text = serverData:GetServerIndexAndName()
    self.m_roleNameText.text = serverData.user_name
    
    if self.m_userIconItem == nil then
        if self.m_seq == 0 then
            self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq() 
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, TheGameIds.UserItemPrefab, function(obj)
                self.m_seq = 0
                if not IsNull(obj) then
                    self.m_userIconItem = UserItem.New(obj, self.m_iconParent, TheGameIds.UserItemPrefab)
                    self.m_userIconItem:UpdateData(serverData.icon, serverData.icon_box, serverData.level)
                    self.m_userIconItem:SetAnchoredPosition(Vector3.New(100, -63, 0))
                    self.m_userIconItem:SetLocalScale(Vector3.New(0.85,0.85,0.85))
                end
            end)
        end
    else
        self.m_userIconItem:UpdateData(serverData.icon, serverData.icon_box, serverData.level)
    end 
end

function ServerRoleItem:OnClick(go, x, y)
    if go.name == "clickBtn" then
        UIManagerInst:Broadcast(UIMessageNames.MN_LOGIN_SELECT_SERVER, self.m_serverData)
    end
end

function ServerRoleItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_clickBtn.gameObject)
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0

    if self.m_userIconItem then
        self.m_userIconItem:Delete()
        self.m_userIconItem = nil
    end

    base.OnDestroy(self)
end

return ServerRoleItem

