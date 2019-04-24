local Language = Language
local CommonDefine = CommonDefine
local UIUtil = UIUtil
local SplitString = CUtil.SplitString
local string_format = string.format
local ConfigUtil = ConfigUtil
local Color = Color
local Vector3 = Vector3   
local EffectPath_Blue = TheGameIds.UI_bigmapmisson_select_blue_path
local EffectPath_Purple = TheGameIds.UI_bigmapmisson_select_purple_path

local DragonCopyHardItem = BaseClass("DragonCopyHardItem", UIBaseItem)
local base = UIBaseItem

function DragonCopyHardItem:OnCreate()
    self.m_copyID = 0
    self.m_selectEffect = nil
    self.m_effectPath = nil

    self.m_clickBtnTr,
    self.m_lockImgTr = UIUtil.GetChildTransforms(self.transform, {
        "Container/ClickBtn",
        "Container/LockImg",
    })

    self.m_nameTxt,
    self.m_descTxt = UIUtil.GetChildTexts(self.transform, {
        "Container/NameTxt", 
        "Container/DescTxt",
    })

    self.m_selectImg = UIUtil.AddComponent(UIImage, self, "Container/SelectImg", AtlasConfig.DynamicLoad) 

    self.m_layerName = UILogicUtil.FindLayerName(self.transform)
    self.m_isLocked = true

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_clickBtnTr.gameObject, onClick)
end

function DragonCopyHardItem:SetData(copyID, isLocked, isSelected, showEffectBounds, dragonLevel)
    self.m_copyID = copyID

    local copyCfg = ConfigUtil.GetGragonCopyCfgByID(copyID) 
    if not copyCfg then
        return
    end
    self.m_isLocked = isLocked 
    self.m_lockImgTr.gameObject:SetActive(isLocked)
    
    self.m_selectImg:SetAtlasSprite("zhuxian9.png", true, AtlasConfig.DynamicLoad)
    self.m_effectPath = EffectPath_Blue
    self.m_nameTxt.text = copyCfg.copyName
    if not isLocked then
        self:DoSelect(isSelected, showEffectBounds)
    else
        self:DoSelect(false)
    end

    self.m_descTxt.text = ""

    if isLocked then
        if Player:GetInstance():GetUserMgr():GetUserData().level < copyCfg.open_level then
            self.m_descTxt.text = string_format(Language.GetString(1804), copyCfg.open_level)
            return
        end

        local preCopyCfg = ConfigUtil.GetGragonCopyCfgByID(copyID - 1)
        if preCopyCfg then
            self.m_descTxt.text = string_format(Language.GetString(1805), preCopyCfg.copyName)
        end 
    end 
end

function DragonCopyHardItem:DoSelect(isSelected, showEffectBounds)
    self.m_selectImg.gameObject:SetActive(isSelected)

    if isSelected then
        if not self.m_selectEffect then
            local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
            UIUtil.AddComponent(UIEffect, self, "", sortOrder, self.m_effectPath, function(effect)
                self.m_selectEffect = effect
                self.m_selectEffect:SetLocalPosition(Vector3.New(-40, 0, 0))

                local clipRegion = Vector4.New(showEffectBounds[0].x, showEffectBounds[0].y, showEffectBounds[2].x, showEffectBounds[2].y)
                self.m_selectEffect:ClipParticleWithBounds(clipRegion)
            end) 
        end
    else
        self:ClearEffect()
    end
end

function DragonCopyHardItem:GetCopyID()
    return self.m_copyID
end

function DragonCopyHardItem:OnClick(go, x, y)
    if self.m_isLocked then
        return
    end
 
    UIManager:GetInstance():Broadcast(UIMessageNames.MN_DRAGON_COPY_HARD_ITEM_CLICK, self.m_copyID)
end


function DragonCopyHardItem:OnDestroy()
    UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)

    UIUtil.RemoveClickEvent(self.m_clickBtnTr.gameObject)

    self:ClearEffect()
    self.m_effectPath = nil

    base.OnDestroy(self)
end

function DragonCopyHardItem:ClearEffect()
    if self.m_selectEffect then
        self.m_selectEffect:Delete()
        self.m_selectEffect = nil
    end 
end

return DragonCopyHardItem