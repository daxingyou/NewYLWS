


local UIWuJiangAttrView = BaseClass("UIWuJiangAttrView", UIBaseView)
local base = UIBaseView

local WuJiangAttrTextItem = require "UI.UIWuJiang.View.WuJiangAttrTextItem"
local UIWuJiangCardItem = require "UI.UIWuJiang.View.UIWuJiangCardItem"
local BagItemClass = require("UI.UIBag.View.BagItem")
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local UIWuJiangDetailIconItem = require "UI.UIWuJiang.View.UIWuJiangDetailIconItem"
local GameObject = CS.UnityEngine.GameObject

local SkillUtil = SkillUtil
local CommonDefine = CommonDefine
local string_format = string.format
local math_ceil = math.ceil
local table_insert = table.insert
local table_remove = table.remove

local CardItemPath = TheGameIds.CommonWujiangCardPrefab
local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab

local ShenBingItemScale = Vector3.New(0.86, 0.86, 0.86)
local MiddleTranPos = Vector3.New(0, -21.44, 0)

second_attr_name_list = {
    "max_hp", "mingzhong", "shanbi", 
    "phy_atk", "phy_baoji", "phy_def",
    "magic_atk", "magic_baoji", "magic_def", 
    "phy_suckblood",  "baoji_hurt", "reduce_cd",
    "magic_suckblood", "atk_speed", "move_speed", 
    "init_nuqi",  }

function UIWuJiangAttrView:OnCreate()
    base.OnCreate(self)

    self:InitVariable()

    self:InitView()

    self:HandleClick()
end

function UIWuJiangAttrView:OnEnable(...)
    base.OnEnable(self, ...)

    local _, panelData = ...
    if panelData then  
        self.m_wujiangDetailData = panelData.wujiangDetailData
        self.m_shenbingDetailData = panelData.sbDetailData
        self.m_userBriefData = panelData.userBriefData
        self.m_mountData = panelData.mountData

        self:UpdateView()   
    end
end

function UIWuJiangAttrView:OnDisable()
    
    --取消加载
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_wujiangItemSeq)
    self.m_wujiangItemSeq = 0

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_inscriptionSeq)
    self.m_inscriptionSeq = 0

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_shenbingItemSeq)
    self.m_shenbingItemSeq = 0
   
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_mountItemSeq)
    self.m_mountItemSeq = 0
    --回收
    if self.m_wujiangItem then
        self.m_wujiangItem:Delete()
        self.m_wujiangItem = nil
    end

    if self.m_mountItem then
        self.m_mountItem:Delete()
        self.m_mountItem = nil
    end

    for i, v in ipairs(self.m_inscriptionItemList) do
        v:Delete()
    end
    self.m_inscriptionItemList = {}

    if self.m_shenbingItem then
        self.m_shenbingItem:Delete()
        self.m_shenbingItem = nil
    end

    base.OnDisable(self)
end

function UIWuJiangAttrView:OnClick(go, x, y) 
    if go.name == "AddFriendBtn" then
        local FriendMgr = Player:GetInstance():GetFriendMgr()
        local isFriend = FriendMgr:CheckIsFriend(self.m_userBriefData.uid)
        if isFriend then
            UILogicUtil.FloatAlert(string.format(Language.GetString(1459), self.m_userBriefData.name))
            return
        end
        UIManagerInst:OpenWindow(UIWindowNames.UIFriendRequest, self.m_userBriefData.uid)
        self:CloseSelf()
    elseif go.name == "TalkToBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIFriendMain, 3, self.m_userBriefData.uid)
        self:CloseSelf()
    elseif go.name == "CloseBtn2" or go.name == "CloseBtn" then
        self:CloseSelf()
    elseif go.name == "RuleBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 124) 
    end
end

function UIWuJiangAttrView:OnDestroy()
    --清空
    for i,v in ipairs(self.m_attrTextList) do
        v:Delete()
    end
    self.m_attrTextList = nil

    for i,v in ipairs(self.m_skillIconList) do
        v:Delete()
    end
    self.m_skillIconList = nil

    self:RemoveClick()
    base.OnDestroy(self)
end

-- 初始化非UI变量
function UIWuJiangAttrView:InitVariable()
    self.m_wujiangDetailData = nil
    self.m_wujiangItemSeq = 0
    self.m_inscriptionSeq = 0
    self.m_shenbingItemSeq = 0
    self.m_mountItemSeq = 0

    self.m_attrTextList = {}
    self.m_skillIconList = {}
    self.m_inscriptionItemList = {}
    self.m_mountItem = nil
end

function UIWuJiangAttrView:InitView()
    self.m_bottomTran, self.m_addFriendBtn, self.m_talkToBtn,
    self.m_closeBtn2, self.m_closeBtn,self.m_ruleBtn, 
    self.m_secondAttrParent,
    self.m_wujiangIconRoot, 
    self.m_inscriptionItemParent,
    self.m_skillItemParent,
    self.m_shenbingRoot,
    self.m_skillItemPrefab,
    self.m_attrTextPrefab,
    self.m_middleTran,
    self.m_shenbingEmptyTrans,
    self.m_horseRootTr,
    self.m_horseEmptyTr  = 
    UIUtil.GetChildTransforms(self.transform, {
        "Container/Bottom",
        "Container/Bottom/AddFriendBtn",
        "Container/Bottom/TalkToBtn",
        "CloseBtn2",
        "Container/Top/CloseBtn",
        "Container/Top/RuleBtn",
        "Container/Middle/AttrList",
        "Container/Middle/WuJiangIconRoot",
        "Container/Middle/InscriptionList",
        "Container/Middle/SkillList",
        "Container/Middle/ShenBingRoot",
        "skillItemPrefab", "AttrTextPrefab", 
        "Container/Middle",
        "Container/Middle/ShenBingRoot/ShenBingEmptyItem",
        "Container/Middle/HorseRoot",
        "Container/Middle/HorseRoot/HorseEmptyItem",
    }) 

    self.m_skillItemPrefab = self.m_skillItemPrefab.gameObject
    self.m_attrTextPrefab = self.m_attrTextPrefab.gameObject

    self.m_powerText,
    self.m_shenbingText,
    self.m_shenbingNameText,
    self.m_playerNameText, 
    self.m_addFriendBtnText, 
    self.m_talkToBtnText, 
    self.m_titleText,
    self.m_skillText,
    self.horseTxt, self.m_horseNameText = UIUtil.GetChildTexts(self.transform, {
        "Container/Middle/WuJiangIconRoot/PowerBg/PowerText",
        "Container/Middle/ShenBingRoot/ShenBingText",
        "Container/Middle/ShenBingRoot/ShenBingNameText",
        "Container/Middle/PlayerNameText",
        "Container/Bottom/AddFriendBtn/AddFriendBtnText",
        "Container/Bottom/TalkToBtn/TalkToBtnText",
        "Container/Top/titleBg/titleText",
        "Container/Middle/SkillText",
        "Container/Middle/HorseRoot/HorseTxt", 
        "Container/Middle/HorseRoot/HorseNameText"
    })

    self.m_shenbingText.text = Language.GetString(752)
    self.m_addFriendBtnText.text = Language.GetString(753)
    self.m_talkToBtnText.text = Language.GetString(754)
    self.m_titleText.text = Language.GetString(755)
    self.m_skillText.text = Language.GetString(756)
    self.horseTxt.text = Language.GetString(3563)

    self.m_shenbingEmptyTransImage = self:AddComponent(UIImage, self.m_shenbingEmptyTrans, AtlasConfig.DynamicLoad)
    self.m_horseEmptyTransImage = self:AddComponent(UIImage, self.m_horseEmptyTr, AtlasConfig.DynamicLoad)
end

function UIWuJiangAttrView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_addFriendBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_talkToBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_closeBtn2.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_ruleBtn.gameObject, onClick)
end

function UIWuJiangAttrView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_addFriendBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_talkToBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtn2.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtn.gameObject)
end

function UIWuJiangAttrView:IsNCard(wujiangCfg)
    return wujiangCfg.rare == CommonDefine.WuJiangRareType_1 or wujiangCfg.rare == CommonDefine.WuJiangRareType_2
end

function UIWuJiangAttrView:UpdateView()
    if self.m_wujiangDetailData then
        self:CreateWuJiangIcon()
        self:UpdateWuJiangPower()
        self:UpdateInscriptionList()
        self:UpdateSkill()
        self:UpdateSecondAttrList()
    end

    self.m_shenbingNameText.text = ""
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_wujiangDetailData.id)
   

    if self.m_shenbingDetailData == nil or self.m_shenbingDetailData.id == 0 then
        self.m_shenbingEmptyTrans.gameObject:SetActive(true)
        
        if wujiangCfg then
            if self:IsNCard(wujiangCfg) then
                self.m_shenbingEmptyTransImage:SetAtlasSprite("peiyang41.png")
            else
                self.m_shenbingEmptyTransImage:SetAtlasSprite("peiyang40.png")
                self.m_shenbingNameText.text = Language.GetString(768)
            end
        end
    else
        self.m_shenbingEmptyTrans.gameObject:SetActive(false)
    end
  
    if self.m_shenbingDetailData then 
        self:CreateShenBingIcon()
    end

    self.m_playerNameText.text = ""

    if self.m_userBriefData then
        self:UpdatePlayerInfo()
    end
    
    self.m_horseNameText.text = ''
    if self.m_mountData == nil or self.m_mountData.m_id == 0 then
        self.m_horseEmptyTr.gameObject:SetActive(true)

        if wujiangCfg then
            if self:IsNCard(wujiangCfg) then
                self.m_horseEmptyTransImage:SetAtlasSprite("peiyang41.png")
            else
                self.m_horseEmptyTransImage:SetAtlasSprite("peiyang40.png")
                self.m_horseNameText.text = Language.GetString(768)
            end
        end
    else
        self.m_horseEmptyTr.gameObject:SetActive(false)
    end

    if self.m_mountData then
        self:CreateMountIcon()
    end
end

function UIWuJiangAttrView:UpdateSecondAttrList()
    if not self.m_wujiangDetailData then
        return
    end

    local base_second_attr = self.m_wujiangDetailData.base_second_attr
    local extra_second_attr = self.m_wujiangDetailData.extra_second_attr

    

    if base_second_attr and extra_second_attr then
        local index = 1
        local nameList = second_attr_name_list
        for _, name in ipairs(nameList) do
            local baseVal = base_second_attr[name]
            local extraVal = extra_second_attr[name]
    
            if baseVal and extraVal then

                local attrType = CommonDefine[name]
                if attrType then
                    local attrText = self.m_attrTextList[index]
                    if not attrText then
                        local go = GameObject.Instantiate(self.m_attrTextPrefab)
                        attrText = WuJiangAttrTextItem.New(go, self.m_secondAttrParent)
                        table_insert(self.m_attrTextList, attrText)
                    end
                    attrText:SetData(name, Language.GetString(attrType + 10), baseVal, extraVal)
                    index = index + 1
                end

                
            end
        end
    end
end

function UIWuJiangAttrView:CreateWuJiangIcon()
    if not self.m_wujiangItem then
        self.m_wujiangItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObject(self.m_wujiangItemSeq, CardItemPath, function(go)
            self.m_wujiangItemSeq = 0
            if not IsNull(go) then
                self.m_wujiangItem = UIWuJiangCardItem.New(go, self.m_wujiangIconRoot, CardItemPath)
                self.m_wujiangItem:SetData(self.m_wujiangDetailData)
            end
        end)
    else
        self.m_wujiangItem:SetData(self.m_wujiangDetailData)
    end
end

function UIWuJiangAttrView:UpdateWuJiangPower()
    self.m_powerText.text = math_ceil(self.m_wujiangDetailData.power)
end

function UIWuJiangAttrView:UpdateInscriptionList()
    local inscription_list = self.m_wujiangDetailData.inscription_list 
    if inscription_list then 
        if #self.m_inscriptionItemList == 0 then
            self.m_inscriptionSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObjects(self.m_inscriptionSeq, BagItemPrefabPath, #inscription_list, function(objs)
                self.m_inscriptionSeq = 0
                if objs then
                    for i = 1, #objs do
                        local bagItem = BagItemClass.New(objs[i], self.m_inscriptionItemParent, BagItemPrefabPath)
                        table_insert(self.m_inscriptionItemList, bagItem) 
                        local itemCfg = ConfigUtil.GetItemCfgByID(inscription_list[i])
                        local itemIconParam = ItemIconParam.New(itemCfg)
                        itemIconParam.onClickShowDetail = true
                        bagItem:UpdateData(itemIconParam)
                    end
                end
            end)
        end
    end
end

function UIWuJiangAttrView:UpdateSkill()
    local skill_list = self.m_wujiangDetailData.skill_list
    if not skill_list then
        return
    end

    local function ClickIconItem(iconItem)
        if iconItem then
            -- print("ClickIconItem ", iconItem:GetSkillID(), iconItem:GetIconIndex())
        end
    end

    local index = 1
    for _, v in ipairs(skill_list) do
        local skillCfg = ConfigUtil.GetSkillCfgByID(v.id)
        if skillCfg then
            if not SkillUtil.IsAtk(skillCfg) then
                local iconItem = self.m_skillIconList[index]
                if not iconItem then
                    local go = GameObject.Instantiate(self.m_skillItemPrefab)
                    iconItem  = UIWuJiangDetailIconItem.New(go, self.m_skillItemParent)
                    table_insert(self.m_skillIconList, iconItem)
                end
                iconItem:SetData(v, nil, 0, index, ClickIconItem, true)
                index = index + 1
            end
        end
    end

    --删除多用的Icon
    for i = #self.m_skillIconList, index, -1  do
        self.m_skillIconList[i]:Delete()
        table_remove(self.m_skillIconList, i)
    end
end

function UIWuJiangAttrView:CreateShenBingIcon()
    local itemCfg = ConfigUtil.GetItemCfgByID(self.m_shenbingDetailData.id)
    local stage =  UILogicUtil.GetShenBingStageByLevel(self.m_shenbingDetailData.stage)

    local function ClickIconItem(iconItem)
        if iconItem then
            UIManagerInst:OpenWindow(UIWindowNames.UIShenBingItemTips, self.m_shenbingDetailData, self.m_wujiangDetailData.id)
        end
    end

    local itemIconParam = ItemIconParam.New(itemCfg, 1, stage, 0, ClickIconItem, false, false, false,
        false, false, self.m_shenbingDetailData.stage) 
    --itemIconParam.onClickShowDetail = true 
    if itemCfg then
        if not self.m_shenbingItem then
            self.m_shenbingItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObject(self.m_shenbingItemSeq, BagItemPrefabPath, function(go)
                self.m_shenbingItemSeq = 0
                if not IsNull(go) then
                    self.m_shenbingItem = BagItemClass.New(go, self.m_shenbingRoot, BagItemPrefabPath)
                    self.m_shenbingItem:SetLocalScale(ShenBingItemScale)
                    --self.m_shenbingItem:SetAnchoredPosition(Vector3.zero)
                    self.m_shenbingItem:UpdateData(itemIconParam)
                end
            end)
        else
            self.m_shenbingItem:UpdateData(itemIconParam)
        end

        local shenbingCfg = ConfigUtil.GetShenbingCfgByID(self.m_shenbingDetailData.id)
        if shenbingCfg then
            local shenbingName = UILogicUtil.GetShenBingNameByStage(self.m_shenbingDetailData.stage, shenbingCfg)
            if self.m_shenbingDetailData.stage > 0 then
                shenbingName = shenbingName..string_format("+%d", self.m_shenbingDetailData.stage)
            end
            self.m_shenbingNameText.text = shenbingName
        end
    end 
end

function UIWuJiangAttrView:CreateMountIcon()
    local itemCfg = ConfigUtil.GetItemCfgByID(self.m_mountData.m_id)
    local horseCfg = ConfigUtil.GetZuoQiCfgByID(self.m_mountData.m_id)
    if not itemCfg or not horseCfg then
        return
    end
    
    if not self.m_mountItem then
        self.m_mountItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObject(self.m_mountItemSeq, BagItemPrefabPath, function(obj)
            self.m_mountItemSeq = 0
            if obj then
                local zuoqiItem = BagItemClass.New(obj, self.m_horseRootTr, BagItemPrefabPath)
                self.m_mountItem = zuoqiItem
                self.m_mountItem:SetLocalScale(ShenBingItemScale)
            end
        end) 
    end 

    local zuoqiItemClick = function()
        local screenPoint = UIManagerInst.UICamera:WorldToScreenPoint(self.m_mountItem:GetTransform().position)
        UIManagerInst:OpenWindow(UIWindowNames.UIMountItemTips, nil, screenPoint, nil, self.m_mountData)
    end

    local itemIconParam = ItemIconParam.New(itemCfg, 1, self.m_mountData.m_stage, self.m_mountData.m_index, zuoqiItemClick,
                                            false, false, false, false, false, self.m_mountData.m_stage, false)
  
    self.m_mountItem:UpdateData(itemIconParam)
    self.m_horseNameText.text = horseCfg["name"..math_ceil(self.m_mountData.m_stage)]
end

function UIWuJiangAttrView:UpdatePlayerInfo()
    local isMySelf = self.m_userBriefData.uid == Player:GetInstance():GetUserMgr():GetUserData().uid
    self.m_bottomTran.gameObject:SetActive(not isMySelf)
   
    if not isMySelf then
        self.m_playerNameText.text = string.format(Language.GetString(1460), self.m_userBriefData.name)
        self.m_middleTran.localPosition = Vector3.zero
    else
        self.m_middleTran.localPosition = MiddleTranPos
    end
end

return UIWuJiangAttrView