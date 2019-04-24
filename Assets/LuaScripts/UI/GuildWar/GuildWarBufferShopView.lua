local Language = Language
local ConfigUtil = ConfigUtil
local math_ceil = math.ceil
local table_insert = table.insert
local GuildMgr = Player:GetInstance().GuildMgr
local GameObject = CS.UnityEngine.GameObject
local GuildWarShopShelfItem = require("UI.GuildWar.GuildWarShopShelfItem")

local GuildWarBufferShopView = BaseClass("GuildWarBufferShopView", UIBaseView)
local base = UIBaseView

function GuildWarBufferShopView:OnCreate()
    base.OnCreate(self)

    self.m_buffsItemList = {}

    self:InitView()
    
    self:HandleClick()
end

function GuildWarBufferShopView:OnEnable(...)
    base.OnEnable(self, ...)
   
    self:UpdateView()
end

function GuildWarBufferShopView:OnDisable()
    for _, item in ipairs(self.m_buffsItemList) do
        item:Delete()
    end
    self.m_buffsItemList = {} 
 
    base.OnDisable(self)
end

function GuildWarBufferShopView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtn.gameObject)

    base.OnDestroy(self)
end

function GuildWarBufferShopView:OnAddListener()
	base.OnAddListener(self)
    self:AddUIListener(UIMessageNames.MN_GUILDWAR_BUY_BUFF, self.UpdateView)
end

function GuildWarBufferShopView:OnRemoveListener()
	base.OnRemoveListener(self)
    self:RemoveUIListener(UIMessageNames.MN_GUILDWAR_BUY_BUFF, self.UpdateView)
end

function GuildWarBufferShopView:OnClick(go, x, y)
    local name = go.name
    if name == "CloseBtn" then
        self:CloseSelf() 
    elseif name == "ruleBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 121) 
    end
end

function GuildWarBufferShopView:InitView()
    self.m_closeBtn, self.m_ruleBtn, self.m_itemRoot, self.m_shopShelfItemPrefab = UIUtil.GetChildRectTrans(self.transform, {
        "CloseBtn",
        "bg/top/ruleBtn",
        "bg/ItemScrollView/Viewport/ItemContent",
        "ShopShelfItem",
    })

    self.m_resourceDescText, self.m_resourceItemCountText, self.m_resource2ItemCountText, 
    self.m_tipsText = UIUtil.GetChildTexts(self.transform, {
        "bg/Bottom/ResourceDescText",
        "bg/Bottom/ResourceItem/ResourceItemCountText",
        "bg/Bottom/Resource2Item/Resource2ItemCountText",
        "bg/Bottom/TipsText",
    })

    self.m_tipsText.text = Language.GetString(2341)
    self.m_resourceDescText.text = Language.GetString(2340)

    self.m_shopShelfItemPrefab = self.m_shopShelfItemPrefab.gameObject
end

function GuildWarBufferShopView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_ruleBtn.gameObject, onClick)
end

function GuildWarBufferShopView:UpdateResourceCount()
    local myGuildData = GuildMgr.MyGuildData
    if myGuildData then
        self.m_resourceItemCountText.text = math_ceil(myGuildData.guild_yuanbao)
        self.m_resource2ItemCountText.text = math_ceil(myGuildData.guild_coin)
    end
end


function GuildWarBufferShopView:UpdateView()
    self:UpdateResourceCount()

    self:UpdateBuffItemList()
end

function GuildWarBufferShopView:UpdateBuffItemList()
    local index = 1
    local rowIndex = 1
    local cfgList = ConfigUtil.GetGuildWarCraftShopCfgList()
    for i, cfg in ipairs(cfgList) do
        if cfg.can_buy == 1 then
            if index % 4 == 1 then
                local shopShelfItem = self.m_buffsItemList[rowIndex]
                if not shopShelfItem then
                    local go = GameObject.Instantiate(self.m_shopShelfItemPrefab)
                    shopShelfItem = GuildWarShopShelfItem.New(go, self.m_itemRoot)
                    table_insert(self.m_buffsItemList, shopShelfItem)
                end
                
                rowIndex = rowIndex + 1
                shopShelfItem:SetData(cfg.id)
            end
            index = index + 1
        end
    end
end

return GuildWarBufferShopView