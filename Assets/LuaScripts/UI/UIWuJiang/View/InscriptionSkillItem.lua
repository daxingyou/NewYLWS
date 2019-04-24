

local InscriptionSkillItem = BaseClass("InscriptionSkillItem", UIBaseItem)
local base = UIBaseItem


local UIEffect = UIEffect
local ui_mingqian_jihuo_path = "UI/Effect/Prefabs/ui_mingqian_jihuo"

function InscriptionSkillItem:OnCreate()
    base.OnCreate(self)

    self.m_iconImage = UIUtil.AddComponent(UIImage, self, "", AtlasConfig.DynamicLoad)
    self.m_nameText = UIUtil.FindText(self.transform, "NameText")

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self:GetGameObject(), onClick)

    self.m_skillID = 0
    self.m_sortOrder = 0
end

function InscriptionSkillItem:OnClick(go)
    if go == self:GetGameObject() then
        if self.m_onClickCallback then
            self.m_onClickCallback(self.m_combinationData, self.transform.position)
        end
    end
end

function InscriptionSkillItem:OnDestroy()
    UIUtil.RemoveClickEvent(self:GetGameObject())
    if self.m_iconImage then
        self.m_iconImage:Delete()
        self.m_iconImage = nil
    end

    self.m_onClickCallback = nil
    self:ShowJihuoEffect(false)

    base.OnDestroy(self)
end

function InscriptionSkillItem:SetData(inscriptionsCombinationData, OnClickCallback, sortOrder)
    self.m_skillID = 0
    self.m_sortOrder = sortOrder

    if inscriptionsCombinationData then
        local skillCfg = ConfigUtil.GetInscriptionAndHorseSkillCfgByID(inscriptionsCombinationData.skill_id)
        if skillCfg then

            self.m_combinationData = inscriptionsCombinationData

            self.m_skillID = inscriptionsCombinationData.skill_id
            self.m_onClickCallback = OnClickCallback

            local level = inscriptionsCombinationData.skill_level
            self.m_nameText.text = skillCfg.name

            local str = ""
            if level == 1 then
                str = "mingqian27.png"
            elseif level == 2 then
                str = "mingqian28.png"
            elseif level == 3 then
                str = "mingqian31.png"
            elseif level == 4 then
                str = "mingqian29.png"
            elseif level == 5 then
                str = "mingqian30.png"
            end
            self.m_iconImage:SetAtlasSprite(str)
        end
    end
end

function InscriptionSkillItem:ShowJihuoEffect(isShow)
    if isShow then
        if not self.m_jihuoEffect then
            UIUtil.AddComponent(UIEffect, self, "", self.m_sortOrder, ui_mingqian_jihuo_path, function(effect)
                self.m_jihuoEffect = effect
            end)
        else
            self.m_jihuoEffect:Play()
        end
    else
        if self.m_jihuoEffect then
            self.m_jihuoEffect:Delete()
            self.m_jihuoEffect = nil
        end
    end
end

return InscriptionSkillItem

