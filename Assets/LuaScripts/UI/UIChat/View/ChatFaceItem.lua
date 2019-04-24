local UIUtil = UIUtil
local UIImage = UIImage
local AtlasConfig = AtlasConfig

local ChatFaceItem = BaseClass("ChatFaceItem", UIBaseItem)
local base = UIBaseItem

function ChatFaceItem:OnCreate()
    base.OnCreate(self)

    self.m_image = UIUtil.AddComponent(UIImage, self, self.transform, AtlasConfig.DynamicLoad)

    self.m_chatFaceCfg = nil
    self.m_selfOnClickCallback = nil

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_gameObject, onClick)
end

function ChatFaceItem:OnClick(go, x, y)
    if go == self.m_gameObject then
        if self.m_selfOnClickCallback then
            self.m_selfOnClickCallback(self.m_chatFaceCfg)
        end
    end
end

function ChatFaceItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_gameObject)

    if self.m_image then
        self.m_image:Delete()
        self.m_image = nil
    end
    
    self.m_chatFaceCfg = nil
    self.m_selfOnClickCallback = nil

    base.OnDestroy(self)
end

function ChatFaceItem:UpdateData(chatFaceCfg, selfOnClick)
    if not chatFaceCfg then
        return
    end
    self.m_chatFaceCfg = chatFaceCfg
    self.m_selfOnClickCallback = selfOnClick

    self.m_image:SetAtlasSprite(chatFaceCfg.sIcon, true)
end

function ChatFaceItem:GetChatFaceCfg()
    return self.m_chatFaceCfg
end

return ChatFaceItem