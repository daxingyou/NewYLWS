
local ImageConfig = ImageConfig
local UILogicUtil = UILogicUtil
local UIUtil = UIUtil
local Language = Language
local ConfigUtil = ConfigUtil
local GameUtility = CS.GameUtility
local string_format = string.format
local math_ceil = math.ceil
local math_floor = math.floor
local UserMgr = Player:GetInstance():GetUserMgr()
local dragonCopyMgr = Player:GetInstance():GetGodBeastMgr()


local DragonCopyMainItem = BaseClass("DragonCopyMainItem", UIBaseItem)
local base = UIBaseItem

function DragonCopyMainItem:OnCreate()
    base.OnCreate(self)

    self.m_nameTxt, 
    self.m_descTxt = UIUtil.GetChildTexts(self.transform, {
        "Name", 
        "LockMask/LockBg/LockText"
    })
    local lockMaskTr

    lockMaskTr = UIUtil.GetChildTransforms(self.transform, {
        "LockMask"
    })

    self.m_dragonImg = UIUtil.AddComponent(UIImage, self, "Bg", AtlasConfig.Common)

    self.m_lockMaskGo = lockMaskTr.gameObject
    -----------------------------------------------------

    self.m_leftTimes = 0
    self.m_isActive = false
    self.m_id = 0

    ---------------------------------------------------------
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self:GetGameObject(), onClick) 
end

function DragonCopyMainItem:OnDestroy()
    UIUtil.RemoveClickEvent(self:GetGameObject()) 
    base.OnDestroy(self)
end

function DragonCopyMainItem:UpdateData(id, leftTimes) 
    self.m_leftTimes= leftTimes 
    self.m_id = id

    -- self.m_id 比如3501 乘于100 + 1 默认取第一个
    local defaultId = self.m_id * 100 + 1
    local firstCopyCfg = ConfigUtil.GetGragonCopyCfgByID(defaultId) 
    if firstCopyCfg then
        self.m_descTxt.text = firstCopyCfg.tips
        self.m_dragonImg:SetAtlasSprite(firstCopyCfg.image_name, false, ImageConfig.GodBeast)
    end
end

function DragonCopyMainItem:SetActiveState(isActive)
    self.m_isActive = isActive 
    self.m_lockMaskGo:SetActive(not self.m_isActive) 
end

function DragonCopyMainItem:GetID()
    return self.m_id
end

function DragonCopyMainItem:OnClick() 
    if not self.m_isActive then
        return
    end
    if self.m_leftTimes <= 0 then
        UILogicUtil.FloatAlert(Language.GetString(3707))
        return
    end 
    UIManagerInst:OpenWindow(UIWindowNames.UIDragonCopyDetail, self.m_id)
end


return DragonCopyMainItem














