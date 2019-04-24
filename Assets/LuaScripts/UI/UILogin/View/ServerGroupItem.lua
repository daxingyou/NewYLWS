local string_format = string.format
local base = UIBaseItem
local ServerGroupItem = BaseClass("ServerGroupItem", base)

function ServerGroupItem:OnCreate()
    base.OnCreate(self)
    
    self.m_index = 0
    self.m_groupText = UIUtil.GetChildTexts(self.transform, {
        "bg/groupText",
    })

    self.m_clickBtn, self.m_selectImg = UIUtil.GetChildTransforms(self.transform, {
        "bg/clickBtn",
        "bg/selectImg"
    })
    self.m_selectImg = self.m_selectImg.gameObject

    UIUtil.AddClickEvent(self.m_clickBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick))
end

function ServerGroupItem:SetData(index, startServerID, endServerID, isSelect)
    self.m_index = index
    self.m_groupText.text = string_format(Language.GetString(4119), startServerID, endServerID)
    self.m_selectImg:SetActive(isSelect)
end

function ServerGroupItem:OnClick(go, x, y)
    if go.name == "clickBtn" then
        UIManagerInst:Broadcast(UIMessageNames.MN_LOGIN_SELECT_SERVER_GROUP, self.m_index)
    end
end

function ServerGroupItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_clickBtn.gameObject)
    base.OnDestroy(self)
end

return ServerGroupItem

