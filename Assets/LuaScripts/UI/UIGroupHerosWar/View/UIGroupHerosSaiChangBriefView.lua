
local table_insert = table.insert
local string_split = string.split
local GameObject = CS.UnityEngine.GameObject
local string_format = string.format
local math_ceil = math.ceil
local DOTween = CS.DOTween.DOTween
local UIUtil = UIUtil
local AtlasConfig = AtlasConfig
local Language = Language
local CommonDefine = CommonDefine
local UILogicUtil = UILogicUtil
local Vector3 = Vector3
local SaiChangItemClass = require ("UI.UIGroupHerosWar.View.SaiChangItem")

local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local GroupHerosMgr = Player:GetInstance():GetGroupHerosMgr()

local UIGroupHerosSaiChangBriefView = BaseClass("UIGroupHerosSaiChangBriefView", UIBaseView)
local base = UIBaseView

function UIGroupHerosSaiChangBriefView:OnCreate()
    base.OnCreate(self)

    self.m_saichangItemList = {}

    self:InitView()
end

function UIGroupHerosSaiChangBriefView:InitView()
    local titleText = UIUtil.GetChildTexts(self.transform, {
        "titleContainer/TitleText",
    })
    
    self.m_backBtn, self.m_contentTr, self.m_saichangItemTr = UIUtil.GetChildTransforms(self.transform, {
        "Panel/BackBtn",
        "ScrollView/Viewport/Content",
        "SaichangItem",
    })

    titleText.text = Language.GetString(3998)
    
    self.m_saichangItemPrefab = self.m_saichangItemTr.gameObject

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
end

function UIGroupHerosSaiChangBriefView:OnClick(go)
    if go.name == "BackBtn" then
        self:CloseSelf()
    end
end

function UIGroupHerosSaiChangBriefView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)

    base.OnDestroy(self)
end

function UIGroupHerosSaiChangBriefView:OnEnable(...)
    base.OnEnable(self, ...)

    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_TOP_RIGHT_CURRENCY_TYPE, ItemDefine.QunXiongZhuLu_ID)
    
    local saichangCfgList = ConfigUtil.GetGroupHerosSaichangCfgList()
    for i, v in ipairs(saichangCfgList) do
        local saichangItem = self.m_saichangItemList[i]
        if not saichangItem then
            local go = GameObject.Instantiate(self.m_saichangItemPrefab)
            saichangItem = SaiChangItemClass.New(go, self.m_contentTr)
            table_insert(self.m_saichangItemList, saichangItem)
        end
        saichangItem:UpdateData(v)
    end
end

function UIGroupHerosSaiChangBriefView:OnDisable()
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_TOP_RIGHT_CURRENCY_TYPE, ItemDefine.Stamina_ID)
    for _, v in ipairs(self.m_saichangItemList) do
        GameObject.Destroy(v:GetGameObject())
    end 
    self.m_saichangItemList = {}
    base.OnDisable(self)
end

return UIGroupHerosSaiChangBriefView