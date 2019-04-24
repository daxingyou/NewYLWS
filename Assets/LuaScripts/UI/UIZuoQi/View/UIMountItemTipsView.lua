local math_ceil = math.ceil
local string_format = string.format
local Language = Language
local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local ConfigUtil = ConfigUtil
local CommonDefine = CommonDefine
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local MountMgr = Player:GetInstance():GetMountMgr()
local bagItemPath = TheGameIds.CommonBagItemPrefab
local bagItem = require "UI.UIBag.View.BagItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local UITipsHelper = require "UI.Common.UITipsHelper"

local UIMountItemTipsView = BaseClass("UIMountItemTipsView", UIBaseView)
local base = UIBaseView

function UIMountItemTipsView:OnCreate()
    base.OnCreate(self)
    local improveBtnText
    self.m_mountNameText, self.m_mountStageText, self.m_mountTypeText,
    self.m_mountAttrText, self.m_mountSkillText, improveBtnText = UIUtil.GetChildTexts(self.transform, {
        "Container/IconRoot/MountNameText",
        "Container/IconRoot/MountStageText",
        "Container/IconRoot/MountTypeText",
        "Container/MountAttrText",
        "Container/MountSkillText",
        "Container/ImproveButton/Text"
    })

    self.m_backBtn, self.m_improveBtn, self.m_iconRoot = UIUtil.GetChildTransforms(self.transform, {
        "backBtn",
        "Container/ImproveButton",
        "Container/IconRoot"
    })

    improveBtnText.text = Language.GetString(3510)
    self.m_tips = self:AddComponent(UITipsHelper, "Container") 
    self.m_mountItem = false
    self.m_seq = 0
    self.m_callback = nil

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_improveBtn.gameObject, onClick)
end

function UIMountItemTipsView:OnClick(go)
    if go.name == "ImproveButton" then
        if self.m_callback then
            self.m_callback()
            self.m_callback = nil
            self:CloseSelf()
        end
    elseif go.name == "backBtn" then
        self:CloseSelf()
    end
end

function UIMountItemTipsView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_improveBtn.gameObject)
    base.OnDestroy(self)
end

function UIMountItemTipsView:OnEnable(...)
    base.OnEnable(self, ...)
    local _, mountIndex, inputPos, callback, theMountData = ...

    if not inputPos then
        return
    end  
    
    if not mountIndex and not theMountData then 
        Logger.LogError("not have mountIndex")
        return 
    end

    local mountData = nil
    if mountIndex then
        mountData =  MountMgr:GetDataByIndex(mountIndex)
    elseif not mountIndex and theMountData then
        mountData = theMountData
    end
    if mountData == nil then
        return
    end

    self.m_callback = callback or nil
    self.m_improveBtn.gameObject:SetActive(callback ~= nil)

    if self.m_tips then
        self.m_tips:Init(Vector2.New(-250, -300), inputPos)
    end 
    
    local mountCfg = ConfigUtil.GetZuoQiCfgByID(mountData.m_id)
    local itemCfg = ConfigUtil.GetItemCfgByID(mountData.m_id)

    if itemCfg then
        if not self.m_mountItem and self.m_seq == 0 then
            self.m_seq = UIGameObjectLoaderInst:PrepareOneSeq()
            UIGameObjectLoaderInst:GetGameObject(self.m_seq, bagItemPath, function(go)
                self.m_seq = 0
                if not IsNull(go) then
                    self.m_mountItem = bagItem.New(go, self.m_iconRoot, bagItemPath)
                    self.m_mountItem:SetAnchoredPosition(Vector3.zero)
                    local itemIconParam = ItemIconParam.New(itemCfg, 1, mountData.m_stage, mountData.m_index, nil, false, false, false,
                        false, false, mountData.m_stage, false)
                    self.m_mountItem:UpdateData(itemIconParam)
                end
            end)
        else
            local itemIconParam = ItemIconParam.New(itemCfg, 1, mountData.m_stage, mountData.m_index, nil, false, false, false,
                        false, false, mountData.m_stage, false)
            self.m_mountItem:UpdateData(itemIconParam)
        end
    end
    
    if mountCfg then
        self.m_mountNameText.text = UILogicUtil.GetZuoQiNameByStage(mountData.m_stage, mountCfg)
        self.m_mountStageText.text = string_format(Language.GetString(3539), mountData.m_stage, mountData.m_max_stage)
        self.m_mountTypeText.text = string_format(Language.GetString(3540), mountCfg.horse_name)
        
        local baseAttr = mountData.m_base_first_attr
        local extraAttr = mountData.m_extra_first_attr
        if baseAttr and extraAttr then
            local attrNameList = CommonDefine.first_attr_name_list
            local attrStr = ""
            for i, v in pairs(attrNameList) do
                local val = baseAttr[v]
                local val2 = extraAttr[v]
                if val and val2 then
                    local attrType = CommonDefine[v]
                    if attrType then
                        if val2 == 0 then
                            attrStr = attrStr..string_format(Language.GetString(3513), Language.GetString(attrType + 10), val)
                        else
                            attrStr = attrStr..string_format(Language.GetString(3541), Language.GetString(attrType + 10), val, val2)
                        end
                    end
                end
            end
            self.m_mountAttrText.text =  attrStr
        end

        local skillCfg = ConfigUtil.GetInscriptionAndHorseSkillCfgByID(mountCfg.skill_id)
        if skillCfg then
            local stage = math_ceil(mountData.m_stage)
            local desc = skillCfg["exdesc"..stage]
            if desc and desc ~= "" then
                local exdesc = desc:gsub("{(.-)}", function(m)
                    local v = skillCfg[m]
                    if v then
                        return v
                    end
                end)
                self.m_mountSkillText.text = string_format(Language.GetString(3514), exdesc)
            end
        end
    end
end

function UIMountItemTipsView:OnDisable()
    if self.m_mountItem then
        self.m_mountItem:Delete()
        self.m_mountItem = nil
    end
    
    UIGameObjectLoaderInst:CancelLoad(self.m_seq)
    self.m_seq = 0

    base.OnDisable(self)
end
 

return UIMountItemTipsView