local GameObject = CS.UnityEngine.GameObject
local RectTransform = CS.UnityEngine.RectTransform
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local Type_VerticalLayoutGroup = typeof(CS.UnityEngine.UI.VerticalLayoutGroup)

local ConfigUtil = ConfigUtil
local UILogicUtil = UILogicUtil
local SkillUtil = SkillUtil

local table_insert = table.insert
local abs = math.abs
local math_ceil = math.ceil

local UIWuJiangSkillDescItem = require "UI.UIWuJiang.View.UIWuJiangSkillDescItem"

local UIWuJiangSkillDetailView = BaseClass("UIWuJiangSkillDetailView", UIBaseView)
local base = UIBaseView

local Tab_Cur = 1
local Tab_All = 2
local Match_REPL = {
    EE4000 = '#8e8e8e>'
}

function UIWuJiangSkillDetailView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()
end

function UIWuJiangSkillDetailView:InitView()

    local skillText, switchBtnText, switchBtnText2
    skillText, switchBtnText, switchBtnText2, self.m_skillNameText, self.m_skillLevelText, 
    self.m_skillConditionText, self.m_curSkillDescText = UIUtil.GetChildTexts(self.transform, {
        "Container/skillText",
        "Container/SwitchBtnText",
        "Container/SwitchBtnText2",
        "Container/SkilNameText",
        "Container/SkilNameText/SkillLevelText",
        "Container/SkillConditionText",
        "Container/CurSkillDescText",
    })

    skillText.text = Language.GetString(621)
    switchBtnText.text = Language.GetString(626)
    switchBtnText2.text = Language.GetString(625)

    self.m_skillDescPrefab, self.m_itemGroupTrans, self.backBtn, self.m_switchBtn, self.m_switchBtnImage,
    self.m_container = 
    UIUtil.GetChildTransforms(self.transform, {
        "SkillDescPrefab", "Container/ItemScrollView/Viewport/ItemContent", 
        "backBtn", "Container/SwitchBtn", "Container/SwitchBtn/SwitchBtnImage",
        "Container"
    })

    self.m_skillDescPrefab = self.m_skillDescPrefab.gameObject

    self.m_itemGroup = UIUtil.FindComponent(self.transform, Type_VerticalLayoutGroup, "Container/ItemScrollView/Viewport/ItemContent")

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_switchBtn.gameObject, onClick)
    
    self.m_skillID = 0
    self.m_wujiangIndex = 1
    self.m_skill_desc_list = {}
    self.m_tabIndex = 1
    self.m_delayEnbledTime = 0
end

function UIWuJiangSkillDetailView:OnDestroy()
    UIUtil.RemoveClickEvent(self.backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_switchBtn.gameObject)
    base.OnDestroy(self)
end

function UIWuJiangSkillDetailView:OnEnable(...)
   
    base.OnEnable(self, ...)

    self.m_wujiangIndex, self.m_skillID, self.m_tempWuJiangData = ...
    self:UpdateData()
end

function UIWuJiangSkillDetailView:OnDisable()
    
    AudioMgr:PlayAudio(105)
end


function UIWuJiangSkillDetailView:Release()
    if self.m_skill_desc_list then
        for i, v in ipairs(self.m_skill_desc_list) do
            v:Delete()
        end
        self.m_skill_desc_list = {}
    end
end

function UIWuJiangSkillDetailView:SetWuJiangData()
    if self.m_wujiangIndex < 0 then
        self.m_curWuJiangData = self.m_tempWuJiangData 
    else
        self.m_curWuJiangData = Player:GetInstance().WujiangMgr:GetWuJiangData(self.m_wujiangIndex)
    end
   
    if not self.m_curWuJiangData then
        Logger.LogError("GetWuJiangData error "..self.m_wujiangIndex)
        return
    end
end

function UIWuJiangSkillDetailView:UpdateData()
    self:SetWuJiangData()
    local skill_list = self.m_curWuJiangData.skill_list
    if not skill_list then
        return
    end

    self.m_skillCfg = ConfigUtil.GetSkillCfgByID(self.m_skillID)
    if not self.m_skillCfg then
       return
    end 
    local skillLevel = 0

    for i, v in ipairs(skill_list) do
        if v and v.id == self.m_skillID then
            skillLevel = v.skillLevel
        end
    end

    self.m_skillLevel = skillLevel

    self.m_skillNameText.text = self.m_skillCfg.name
   
    if SkillUtil.IsDazhao(self.m_skillCfg) then
        self.m_skillConditionText.text = string.format(Language.GetString(623), abs(self.m_skillCfg.chgnuqi))
    elseif SkillUtil.IsActiveSkill(self.m_skillCfg) then
        self.m_skillConditionText.text = string.format(Language.GetString(627), self.m_skillCfg.cooldown, self.m_skillCfg.firstcd)
    else
        self.m_skillConditionText.text = Language.GetString(628)
    end

    self.m_curSkillDescText.text = UILogicUtil.GetSkillDesc(self.m_skillID, math_ceil(skillLevel))
    
    local descList = {}

    for i = 1, 6 do
        local exdesc = self.m_skillCfg['exdesc'..i]
        if exdesc ~= '' then
            table_insert(descList, exdesc)
        end
    end

    local str629 = Language.GetString(629)
    local str624 = Language.GetString(624)

    for i = 1, #descList do
        local v = descList[i]
        if v then
            local exdesc1 = v:gsub("{(.-)}", self.m_skillCfg)

            if i > 1 then
                if i > skillLevel then --未达到等级
                    exdesc1 = exdesc1:gsub("#(.-)>", Match_REPL)
                    descList[i] = string.format(str629, i, exdesc1)
                else
                    descList[i] = string.format(str624, i, exdesc1)
                end
            else
                descList[i] = exdesc1
            end
        end
    end

    local count = #self.m_skill_desc_list

    for i = 1, #descList do
        if i > count then
            local go = GameObject.Instantiate(self.m_skillDescPrefab)
            if not IsNull(go) then
                local descItem  = UIWuJiangSkillDescItem.New(go, self.m_itemGroupTrans)
                table_insert(self.m_skill_desc_list, descItem)
            end
        end

        self.m_skill_desc_list[i]:SetActive(true)
        self.m_skill_desc_list[i]:SetData(descList[i])
    end

    
    for i = #descList + 1, count do
        self.m_skill_desc_list[i]:SetActive(false)
    end

    self:OnTabChg()
end

function UIWuJiangSkillDetailView:OnClick(go, x, y)
    if go.name == "backBtn" then
        UIManagerInst:Broadcast(UIMessageNames.MN_WUJIANG_SKILL_DETAIL_SHOW, false)

    elseif go.name == "SwitchBtn" then
        self.m_tabIndex = self.m_tabIndex + 1
        if self.m_tabIndex > Tab_All then
            self.m_tabIndex = Tab_Cur
        end

        self:OnTabChg()
    end
end

function UIWuJiangSkillDetailView:OnTabChg()
    if self.m_tabIndex == Tab_Cur then
        self.m_curSkillDescText.gameObject:SetActive(true)
        self.m_itemGroupTrans.gameObject:SetActive(false)
    elseif self.m_tabIndex == Tab_All then
        self.m_curSkillDescText.gameObject:SetActive(false)
        self.m_itemGroupTrans.gameObject:SetActive(true)
    end

    local posX = self.m_tabIndex == Tab_Cur and -39 or 39
    local pos = self.m_switchBtnImage.localPosition
    self.m_switchBtnImage.localPosition = Vector3.New(posX, pos.y, pos.z)

    if self.m_tabIndex == Tab_All then
        self:ResetItemGroupPos()
    end

    local skillLevel = self.m_tabIndex == Tab_Cur and self.m_skillLevel or 1 --全部的话，等级一直显示1
    self.m_skillLevelText.text = string.format(Language.GetString(622), skillLevel) 
end

function UIWuJiangSkillDetailView:ResetItemGroupPos()
    self.m_itemGroupTrans.anchoredPosition = Vector2.zero
    --self.m_itemGroup.enabled = true
    --self.m_delayEnbledTime = 0.1
end

function UIWuJiangSkillDetailView:IsQingYuan()
    return false
end

function UIWuJiangSkillDetailView:GetContainerTran()
    return self.m_container
end

return UIWuJiangSkillDetailView