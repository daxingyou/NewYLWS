local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local GodBeastMgr = Player:GetInstance():GetGodBeastMgr()
local string_split = CUtil.SplitString
local ConfigUtil = ConfigUtil
local math_ceil = math.ceil
local UIGodBeastSkillDetailView = BaseClass("UIGodBeastSkillDetailView", UIBaseView)
base = UIBaseView

function UIGodBeastSkillDetailView:OnCreate()
    base.OnCreate(self)
    self:InitView()
end

function UIGodBeastSkillDetailView:InitView()

    self.m_unLockSkillTitleText, self.m_unLockSkillDesText = UIUtil.GetChildTexts(self.transform, {
        "BgRoot/skillTitleText",
        "BgRoot/skillDesText",
    })

    self.m_closeBtn = UIUtil.GetChildTransforms(self.transform, {
        "closeBtn",
    })

    self.m_unLockSkillIconImage = UIUtil.AddComponent(UIImage, self, "BgRoot/skillBg/SkillIcon", ImageConfig.GodBeast)
end

function UIGodBeastSkillDetailView:OnEnable(...)
    base.OnEnable(self, ...)
    local initOrder, godBeastId, skillIndex = ...
    self:HandleClick()
    if godBeastId and skillIndex then
        local godBeastCfg = ConfigUtil.GetGodBeastCfgByID(godBeastId)
        if godBeastCfg then
            self:UpdateData(godBeastCfg, skillIndex)
        end
    end
end

function UIGodBeastSkillDetailView:UpdateData(godBeastCfg, skillIndex)
    self.m_unLockSkillIconImage:SetAtlasSprite(godBeastCfg.id..skillIndex..".png", false)
    self.m_unLockSkillTitleText.text = Language.GetString(3611)
    self.m_unLockSkillDesText.text = self:GetSkillDecStr(godBeastCfg, skillIndex)
end

function UIGodBeastSkillDetailView:GetSkillDecStr(godBeastCfg, skillCount)
    if godBeastCfg and skillCount then
        local str = godBeastCfg.extra_skill_des
        local y = godBeastCfg.y + godBeastCfg.ay * skillCount
        local y1 = math_ceil(y)
        y = y == y1 and y1 or y
        str = str:gsub("{y}", y)
        return str
    end
end

function UIGodBeastSkillDetailView:OnDisable()
    self:RemoveClick()
end

function UIGodBeastSkillDetailView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
end

function UIGodBeastSkillDetailView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
end

function UIGodBeastSkillDetailView:OnClick(go, x, y)
    if go.name == "closeBtn" then
        self:CloseSelf()
    end
end

function UIGodBeastSkillDetailView:OnDestroy()
    if self.m_unLockSkillIconImage then
        self.m_unLockSkillIconImage:Delete()
        self.m_unLockSkillIconImage = nil
    end

    base.OnDestroy(self)
end

return UIGodBeastSkillDetailView