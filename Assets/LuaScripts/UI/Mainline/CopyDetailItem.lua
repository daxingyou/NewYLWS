local Language = Language
local CommonDefine = CommonDefine
local UIUtil = UIUtil
local SplitString = CUtil.SplitString
local string_format = string.format
local ConfigUtil = ConfigUtil
local Color = Color
local EffectPath_Blue = "UI/Effect/Prefabs/Ui_bigmapmisson_select_blue"
local EffectPath_Purple = "UI/Effect/Prefabs/Ui_bigmapmisson_select_purple"

local CopyDetailItem = BaseClass("CopyDetailItem", UIBaseItem)
local base = UIBaseItem

function CopyDetailItem:OnCreate()
    self.m_sectionID = 0
    self.m_copyID = 0
    self.m_wujiangItem = nil
    self.m_selectEffect = nil
    self.m_effectPath = nil
    
    self.m_clickBtn, self.m_starRoot, self.m_lockImage = UIUtil.GetChildTransforms(self.transform, {
        "clickBtn",
        "starRoot/",
        "lockImage"
    })

    self.m_nameText = UIUtil.GetChildTexts(self.transform, {
        "nameText",
    })

    self.m_selectImage = UIUtil.AddComponent(UIImage, self, "selectImage", AtlasConfig.DynamicLoad)
    self.m_selectImageGO = self.m_selectImage.gameObject
    self.m_starRoot = self.m_starRoot.gameObject
    self.m_lockImage = self.m_lockImage.gameObject
    local star1 = UIUtil.AddComponent(UIImage, self, "starRoot/star1", AtlasConfig.DynamicLoad)
    local star2 = UIUtil.AddComponent(UIImage, self, "starRoot/star2", AtlasConfig.DynamicLoad)
    local star3 = UIUtil.AddComponent(UIImage, self, "starRoot/star3", AtlasConfig.DynamicLoad)
    self.m_starList = {star1, star2, star3}

    self.m_wujiangIcon = UIUtil.AddComponent(UIImage, self, "wujiang/icon", AtlasConfig.RoleIcon)
    self.m_layerName = UILogicUtil.FindLayerName(self.transform)

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_clickBtn.gameObject, onClick)
end

function CopyDetailItem:SetData(sectionID, copyID, sectionType, isSelected, showEffectBounds)
    self.m_sectionID = sectionID
    self.m_copyID = copyID

    local mainlineMgr = Player:GetInstance():GetMainlineMgr()
    local sectionData = mainlineMgr:GetSectionData(sectionID)
    if not sectionData then
        return
    end

    local copyCfg = ConfigUtil.GetCopyCfgByID(copyID)
    if not copyCfg then
        return
    end

    local copyIndex = 0
    if sectionType == CommonDefine.SECTION_TYPE_NORMAL then
        copyIndex = sectionData:GetNormalLevelByID(copyID)
        self.m_selectImage:SetAtlasSprite("zhuxian9.png", true, AtlasConfig.DynamicLoad)
        self.m_effectPath = EffectPath_Blue
    else
        copyIndex = sectionData:GetEliteLevelByID(copyID)
        self.m_selectImage:SetAtlasSprite("zhuxian10.png", true, AtlasConfig.DynamicLoad)
        self.m_effectPath = EffectPath_Purple
    end
    if sectionID >= CommonDefine.MAINLINE_SECTION_MONSTER_HOME then
        self.m_nameText.text = copyCfg.name
    else
        self.m_nameText.text = string_format(Language.GetString(2608), sectionData:GetSectionCfg().section_index, copyIndex, copyCfg.name)
    end

    local starCount = 0
    local copyData = mainlineMgr:GetCopyData(copyID)
    if copyData then
        starCount = copyData:GetStarCount()
        self.m_starRoot:SetActive(true)
        self.m_lockImage:SetActive(false)
    else
        self.m_starRoot:SetActive(false)
        self.m_lockImage:SetActive(true)
    end
    if copyCfg.isOnce == 1 then
        self.m_starRoot:SetActive(false)
    end

    for i = 1, 3 do
        if i <= starCount then
            self.m_starList[i]:SetColor(Color.white)
        else
            self.m_starList[i]:SetColor(Color.black)
        end
    end

    self.m_wujiangIcon:SetAtlasSprite(copyCfg.icon)
    self:DoSelect(isSelected, showEffectBounds)
end

function CopyDetailItem:DoSelect(isSelected, showEffectBounds)
    self.m_selectImageGO:SetActive(isSelected)
    if isSelected then
        if not self.m_selectEffect then
            local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
            self.m_selectEffect = UIUtil.AddComponent(UIEffect, self, "", sortOrder, self.m_effectPath, function(effect)
                self.m_selectEffect = effect
                local clipRegion = Vector4.New(showEffectBounds[0].x, showEffectBounds[0].y, showEffectBounds[2].x, showEffectBounds[2].y)
                self.m_selectEffect:ClipParticleWithBounds(clipRegion)
            end)
        end
    else
        self:ClearNuqiEffect()
    end
end

function CopyDetailItem:GetCopyID()
    return self.m_copyID
end

function CopyDetailItem:OnClick(go, x, y)
    local copyData = Player:GetInstance():GetMainlineMgr():GetCopyData(self.m_copyID)
    if copyData then
        UIManagerInst:Broadcast(UIMessageNames.MN_MAINLINE_CLICK_COPY, self.m_copyID)
    end
end

function CopyDetailItem:OnDestroy()
    UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)

    UIUtil.RemoveClickEvent(self.m_clickBtn.gameObject)

    self:ClearNuqiEffect()
    self.m_effectPath = nil

    if self.m_wujiangItem then
        self.m_wujiangItem:Delete()
        self.m_wujiangItem = nil
    end
    base.OnDestroy(self)
end

function CopyDetailItem:ClearNuqiEffect()
    if self.m_selectEffect then
        self.m_selectEffect:Delete()
        self.m_selectEffect = nil
    end 
end

return CopyDetailItem