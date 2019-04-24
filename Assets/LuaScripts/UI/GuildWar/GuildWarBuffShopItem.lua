local ConfigUtil = ConfigUtil
local GuildMgr = Player:GetInstance().GuildMgr
local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()
local Vector2 = Vector2

local BaseItem = UIBaseItem
local ShopGoodsItem = require "UI.Shop.ShopGoodsItem"
local GuildWarBuffShopItem = BaseClass("GuildWarBuffShopItem", ShopGoodsItem)

function GuildWarBuffShopItem:OnCreate()
    ShopGoodsItem.OnCreate(self)
    
    self.m_buffIconImage = UIUtil.AddComponent(UIImage, self, "ItemRoot/BuffIconItem/ItemIconSpt")
    self.m_buffIconFrameImage = UIUtil.AddComponent(UIImage, self, "ItemRoot/BuffIconItem/ItemLowLightFrame")

    self.m_titleBgRectTran = UIUtil.GetChildRectTrans(self.transform, {
        "titleBg",
    })

    self.m_buffID = 0
end

function GuildWarBuffShopItem:SetData(buffID)
     self.m_canBuy = false
     local guildWarCraftShopCfg = ConfigUtil.GetGuildWarCraftShopCfgByID(buffID)
     if guildWarCraftShopCfg then

        self.m_buffID = buffID

        local isEnough = self:IsEnough(guildWarCraftShopCfg)
        local canbuy = GuildWarMgr:BuffCanBuy(buffID)

        self.m_canBuy = canbuy and isEnough
       
        self:SetItemColor(self.m_canBuy, canbuy)

        self.m_nameText.text = guildWarCraftShopCfg.desc

        if guildWarCraftShopCfg.price_guild_yuanbao > 0 then
            self.m_newPriceText.text = guildWarCraftShopCfg.price_guild_yuanbao
            self.m_priceImg:SetAtlasSprite("10018.png", false, AtlasConfig.ItemIcon)
        elseif guildWarCraftShopCfg.price_guild_coin > 0 then
            self.m_newPriceText.text = guildWarCraftShopCfg.price_guild_coin
            self.m_priceImg:SetAtlasSprite("10017.png", false, AtlasConfig.ItemIcon)
        end

        self.m_buffIconImage:SetAtlasSprite(guildWarCraftShopCfg.sIcon, false, ImageConfig.GuildWar)
        self:KeepIconCenter()
      
        local width = self.m_nameText.preferredWidth + 40
        if width < 158 then
            width = 158
        end
        self.m_titleBgRectTran.sizeDelta = Vector2.New(width, 35)
     end
end

function GuildWarBuffShopItem:OnClick(go, x, y)
    if self.m_canBuy then

        local titleMsg = Language.GetString(2343)
        local btn1Msg = Language.GetString(10)
        local btn2Msg = Language.GetString(50)
        local contentMsg = Language.GetString(2342)
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, titleMsg, contentMsg, btn1Msg, function()
            GuildWarMgr:ReqBuyBuff(self.m_buffID)
        end, btn2Msg)
    end
end

function GuildWarBuffShopItem:SetItemColor(isWhite, isSoldOut)
    self.m_canBuy = isWhite
    self.m_bgImg:SetColor(isWhite and Color.white or Color.black)
    self.m_priceImg:SetColor(isWhite and Color.white or Color.black)
    self.m_titleBgImg:SetColor(isWhite and Color.white or Color.black)
    self.m_newPriceText.color = isWhite and Color.white or Color.gray
    self.m_nameText.color = isWhite and Color.white or Color.gray

    if self.m_buffIconImage then
        self.m_buffIconImage:SetColor(isWhite and Color.white or Color.black)
    end
    if self.m_buffIconFrameImage then
        self.m_buffIconFrameImage:SetColor(isWhite and Color.white or Color.black)
    end
end

function GuildWarBuffShopItem:IsEnough(guildWarCraftShopCfg)
    local myGuildData = GuildMgr.MyGuildData
    if myGuildData then
        if guildWarCraftShopCfg.price_guild_yuanbao > 0 and myGuildData.guild_yuanbao >= guildWarCraftShopCfg.price_guild_yuanbao then
            return true
        elseif guildWarCraftShopCfg.price_guild_coin > 0 and myGuildData.guild_coin >= guildWarCraftShopCfg.price_guild_coin then
            return true
        end
    end
    return false
end

function GuildWarBuffShopItem:OnDestroy()
    if self.m_buffIconImage then
        self.m_buffIconImage:Delete()
        self.m_buffIconImage = nil
    end

    if self.m_buffIconFrameImage then
        self.m_buffIconFrameImage:Delete()
        self.m_buffIconFrameImage = nil
    end

    ShopGoodsItem.OnDestroy(self)
end


return GuildWarBuffShopItem
