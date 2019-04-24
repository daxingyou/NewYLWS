local string_format = string.format
local table_insert = table.insert
local math_ceil = math.ceil
local GameObject = CS.UnityEngine.GameObject

local Type_LayoutElement = typeof(CS.UnityEngine.UI.LayoutElement)
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local ScreenPointToLocalPointInRectangle = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle
local UIUtil = UIUtil

local UIWuJiangSkillTipsView = BaseClass("UIWuJiangSkillTipsView", UIBaseView)
local base = UIBaseView

local ORIGIN_TEXT_SIZE = Vector2.New(0, 25)
local ORIGIN_IMAGE_SIZE = Vector2.New(50, 105)

-- tips 暂时只适用于命签技能与坐骑技能，如需添加其他，需要再另写方法获取技能配置 
-- 不同点只在于获取技能配置不同 
-- 命签技能与坐骑技能：GetInscriptionAndHorseSkillCfgByID   位于 otherskill 表
-- 武将技能 GetSkillCfgByID 位于 skill 表

function UIWuJiangSkillTipsView:OnCreate()
    base.OnCreate(self)
    
    self.m_skillTipsRectTran, self.m_skillTipsTextRectTran, self.m_closeBtn , self.m_containerRectTran = 
    UIUtil.GetChildRectTrans(self.transform, {
        "Container/SkillTips",
        "Container/SkillTips/SkillTipsText",
        "CloseBtn",
        "Container"
    })

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)

    self.m_skillTipsText = UIUtil.FindText(self.transform, "Container/SkillTips/SkillTipsText")
    self.m_colorList = { "ffffff","32b0e4", "e041e6", "e8c04c", "d24643"}

    self.m_textLayoutElement = self.m_skillTipsText.transform:GetComponent(Type_LayoutElement)

    self.m_setContentSize = false
    self.m_delayFrameCount = 0

    self.m_goList = {}
end

function UIWuJiangSkillTipsView:OnClick(go)
    if go.name == "CloseBtn" then
        self:CloseSelf()
    end
end

function UIWuJiangSkillTipsView:OnDestroy()

    self.m_textLayoutElement = nil
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    base.OnDestroy(self)
end

function UIWuJiangSkillTipsView:OnEnable(...)
    base.OnEnable(self, ...)
    
    local _, targetPos, skillData , goList, index = ...
    if not targetPos or not skillData then
        return 
    end

    self.m_textLayoutElement.enabled = false
    self.m_skillTipsText.gameObject:SetActive(false)
    self.m_skillTipsText.gameObject:SetActive(true)

    self.m_index = index

   
    local uiCamera = UIManagerInst.UICamera
    local screenPos = uiCamera:WorldToScreenPoint(targetPos)
    local v2 = Vector2.New(screenPos.x, screenPos.y)

    local ok, outV2 = ScreenPointToLocalPointInRectangle(self.m_containerRectTran, v2, uiCamera)

    self.m_skillTipsRectTran.anchoredPosition = Vector2.New(outV2.x, outV2.y - 30)

     --策划说 命签和坐骑技能ID 和 武将技能不重复
   
    local skillType = 0 -- 1是命签和坐骑技能 2武将技能

    local level = math_ceil(skillData.skill_level)
    local skillCfg = ConfigUtil.GetInscriptionAndHorseSkillCfgByID(skillData.skill_id)
    if skillCfg then
        skillType = 1
    end

    if not skillCfg then
        skillCfg = ConfigUtil.GetSkillCfgByID(skillData.skill_id)
        if skillCfg then
            skillType = 2
        end
    end
   
    if not skillCfg then
        return
    end
    
    local desc = skillCfg["exdesc"..level]
    if desc and desc ~= "" then
        if skillType == 1 then
            local exdesc = desc:gsub("{(.-)}",  function(m)
                local v = skillCfg[m]
                if v then
                    if self.m_colorList[level] then
                        return string_format(Language.GetString(689), self.m_colorList[level], v)
                    end
                end
            end)
            self.m_skillTipsText.text = exdesc
        elseif skillType == 2 then
            local desc = skillCfg["exdesc"..level]
            if desc and desc ~= "" then
                local exdesc = desc:gsub("{(.-)}", skillCfg)
                self.m_skillTipsText.text = exdesc
            end
        end
    end

    self.m_setContentSize = true
    self.m_delayFrameCount = 2

    if goList then
        for i, v in ipairs(goList) do
            local trans = v.transform
            local go = GameObject.Instantiate(v, self.transform)
            local trans2 = go.transform
            trans2.position = trans.position
            trans2.localScale = trans.parent.localScale
            table_insert(self.m_goList, go)
        end
    end
end

function UIWuJiangSkillTipsView:OnDisable()
    for i = 1, #self.m_goList do
        GameObject.Destroy(self.m_goList[i])
    end
    self.m_goList = {}
    self:ResetSkillTipsSize()
    base.OnDisable(self)
end

function UIWuJiangSkillTipsView:Update()
    if self.m_delayFrameCount > 0 then
        self.m_delayFrameCount = self.m_delayFrameCount - 1
        return
    end

    if self.m_setContentSize then
        self.m_setContentSize = false
        local sizeDelta = self.m_skillTipsTextRectTran.sizeDelta

        for i = 1, #self.m_goList do
            if not IsNull(self.m_goList[i]) then
                local trans = self.m_goList[i].transform
                UIUtil.OnceTweenScale(trans, trans.localScale, trans.localScale * 1.5)
            end
        end

        if self.m_index and self.m_index % 4 == 0 then
            if sizeDelta.x > 300 then
                self.m_textLayoutElement.enabled = true
                self.m_setContentSize = true
                return 
            end
        end

        self.m_skillTipsRectTran.sizeDelta = Vector2.New(sizeDelta.x + 50, sizeDelta.y + 80)
    end
end

function UIWuJiangSkillTipsView:ResetSkillTipsSize()
    self.m_skillTipsText.text = ""
    self.m_skillTipsTextRectTran.sizeDelta = ORIGIN_TEXT_SIZE
    self.m_skillTipsRectTran.sizeDelta = ORIGIN_IMAGE_SIZE
end

return UIWuJiangSkillTipsView