local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local GameObject = CS.UnityEngine.GameObject
local GuildWarOffenceCityResultItem = require "UI.GuildWar.GuildWarOffenceCityResultItem"

local SplitString = CUtil.SplitString
local table_insert = table.insert

local GuildWarOffenceCityResultView = BaseClass("GuildWarOffenceCityResultView", UIBaseView)
local base = UIBaseView


function GuildWarOffenceCityResultView:OnCreate()
    base.OnCreate(self)

    self.m_resultItemList = {}
    self.m_resultItemListSeq = 0
    
    self:InitView()
end

function GuildWarOffenceCityResultView:OnEnable(...)
    base.OnEnable(self, ...)

    _, panelData = ...
    if not panelData then
        return 
    end

    self.m_panelData = panelData

    self:UpdateView()   
end

function GuildWarOffenceCityResultView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    if self.m_resultItemList then
        for i, v in ipairs(self.m_resultItemList) do
            v:Delete()
        end
        self.m_resultItemList = nil
    end

    base.OnDestroy(self)
end

function GuildWarOffenceCityResultView:InitView()
   
    self.m_tabText, self.m_tabText2, self.m_tabText3, self.m_tabText4 =
    UIUtil.GetChildTexts(self.transform, {
        "Container/Middle/TabList/TabText",
        "Container/Middle/TabList/TabText2",
        "Container/Middle/TabList/TabText3",
        "Container/Middle/TabList/TabText4",
    })

    local tabNames = SplitString(Language.GetString(2297), '|')
   
    self.m_tabText.text = tabNames[1]
    self.m_tabText2.text = tabNames[2]
    self.m_tabText3.text = tabNames[3]
     self.m_tabText4.text = tabNames[4]

    self.m_closeBtn, self.m_resultItemPrefab, self.m_itemGridTrans, 
    self.m_breakItemPrefab = 
    UIUtil.GetChildTransforms(self.transform, {
        "CloseBtn" , "ResultItem", "Container/Middle/ItemScrollView/Viewport/ItemContent",
        "BreakItemPrefab"
    })

    self.m_breakItemPrefab = self.m_breakItemPrefab.gameObject
    self.m_resultItemPrefab = self.m_resultItemPrefab.gameObject

    self.m_loopScrollView = self:AddComponent(LoopScrowView, "Container/Middle/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateResultItem), false)
    self.m_titleBgSpt =  self:AddComponent(UIImage, "Container/Top/TitleBg", AtlasConfig.DynamicLoad)


    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
end

function GuildWarOffenceCityResultView:OnClick(go)
    if go.name == "CloseBtn" then
        self:CloseSelf()
    end
end

function GuildWarOffenceCityResultView:UpdateView()
    if self.m_panelData.offence_result == 1 then
        self.m_titleBgSpt:SetAtlasSprite("jtzb10.png", true)
    elseif self.m_panelData.offence_result == 0 then
        self.m_titleBgSpt:SetAtlasSprite("jtzb11.png", true)
    end 

    local user_offence_result_list = self.m_panelData.user_offence_result_list
    if user_offence_result_list then
        if #self.m_resultItemList == 0 then
            for i = 1, 9 do
                local go = GameObject.Instantiate(self.m_resultItemPrefab)
                local item = GuildWarOffenceCityResultItem.New(go, self.m_itemGridTrans)
                table_insert(self.m_resultItemList, item)
            end
        end

        self.m_loopScrollView:UpdateView(true, self.m_resultItemList, user_offence_result_list)
    end
end

function GuildWarOffenceCityResultView:UpdateResultItem(item, realIndex)
    local user_offence_result_list = self.m_panelData.user_offence_result_list
    if user_offence_result_list then
        if not item or not user_offence_result_list or realIndex < 1 or realIndex > #user_offence_result_list then
            return
        end
        item:UpdateData(user_offence_result_list[realIndex], self.m_breakItemPrefab)
    end
end

return GuildWarOffenceCityResultView


