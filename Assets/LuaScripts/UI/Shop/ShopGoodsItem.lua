local UIUtil = UIUtil
local SplitString = CUtil.SplitString
local math_floor = math.floor
local UIBagItem = require "UI.UIBag.View.BagItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local UIBagItemPrefabPath = TheGameIds.CommonBagItemPrefab
local ShopGoodsItem = BaseClass("ShopGoodsItem", UIBaseItem)
local base = UIBaseItem

function ShopGoodsItem:OnCreate()
    self.m_bagItemSeq = 0
    self.m_item = nil
    self.m_goodsData = nil
    self.m_shopType = 0
    self.m_canBuy = false
    self.m_discountImg = UIUtil.AddComponent(UIImage, self, "discountImg")
    self.m_priceImg = UIUtil.AddComponent(UIImage, self, "bg/priceImg")
    self.m_bgImg = UIUtil.AddComponent(UIImage, self, "bg")
    self.m_titleBgImg = UIUtil.AddComponent(UIImage, self, "titleBg")

    self.m_clickBtn, self.m_itemRoot, self.m_priceImgTrans, self.m_lineImgTrans, self.m_titleBgTrans = UIUtil.GetChildRectTrans(self.transform, {
        "clickBtn",
        "ItemRoot",
        "bg/priceImg",
        "bg/priceImg/lineImg",
        "titleBg",
    })

    self.m_nameText, self.m_desText, self.m_oldPriceText, self.m_newPriceText = UIUtil.GetChildTexts(self.transform, {
        "titleBg/nameText",
        "desText",
        "bg/priceImg/oldPriceText",
        "bg/priceImg/newPriceText",
    })

    self.m_oldPriceTrans = self.m_oldPriceText.transform
    self.m_newPriceTrans = self.m_newPriceText.transform

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_clickBtn.gameObject, onClick)
end

function ShopGoodsItem:SetData(goodsData, shopType)
    local goodsCfg = nil
    if shopType == CommonDefine.SHOP_MYSTERY then
        goodsCfg = ConfigUtil.GetMysteryShopCfgByID(goodsData.goodsID)
    else
        goodsCfg = ConfigUtil.GetShopCfgByID(goodsData.goodsID)
    end
    if not goodsCfg then
        return
    end

    local itemCfg = ConfigUtil.GetItemCfgByID(goodsCfg.item_id)
    if not itemCfg then
        return
    end

    self.m_shopType = shopType
    self.m_goodsData = goodsData
    if goodsData.discount == 10 then
        self.m_discountImg.gameObject:SetActive(false)
        self.m_newPriceText.text = goodsCfg.price
        self.m_oldPriceText.text = ""
    else
        self.m_discountImg.gameObject:SetActive(true)
        self.m_newPriceText.text = math_floor(goodsCfg.price * goodsData.discount / 10)
        self.m_oldPriceText.text = goodsCfg.price
    end

    local currencyItemCfg = ConfigUtil.GetItemCfgByID(goodsCfg.currency_id)
    if currencyItemCfg then
        self.m_priceImg:SetAtlasSprite(currencyItemCfg.sIcon, false, AtlasConfig[currencyItemCfg.sAtlas])
    end

    if itemCfg.sMainType == CommonDefine.ItemMainType_ShenBing then
        local shenbingCfg = ConfigUtil.GetShenbingCfgByID(goodsCfg.item_id)
        if shenbingCfg then
            self.m_nameText.text = shenbingCfg.name1
        end
    else
        self.m_nameText.text = itemCfg.sName
    end
    local nameWidth = self.m_nameText.preferredWidth
    nameWidth = nameWidth + 30
    if nameWidth < 158 then nameWidth = 158 end
    self.m_titleBgTrans.sizeDelta = Vector2.New(nameWidth, self.m_titleBgTrans.sizeDelta.y)
            
    if goodsData.descIndex == 1 then
        self.m_desText.text = goodsCfg.cond_desc1
        self:SetItemColor(false)
    elseif goodsData.descIndex == 2 then
        self.m_desText.text = goodsCfg.cond_desc2
        self:SetItemColor(false)
    else
        if goodsData.noLimit ~= 1 then
            if goodsData.leftBuyTimes >= 1 then
                if shopType ~= CommonDefine.SHOP_MYSTERY then
                    self.m_desText.text = string.format(Language.GetString(3402), goodsData.leftBuyTimes)
                else
                    self.m_desText.text = ""
                end
                self:SetItemColor(true)
            else
                self.m_desText.text = Language.GetString(3408)
                self:SetItemColor(false, true)
            end
        else
            self.m_canBuy = true
            self.m_desText.text = ""
        end
    end

    self.m_bagItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObject(self.m_bagItemSeq, UIBagItemPrefabPath, function(go)
        self.m_bagItemSeq = 0
        if not go then
            return
        end
        
        self.m_item = UIBagItem.New(go, self.m_itemRoot)
        self.m_item:SetAnchoredPosition(Vector3.zero)
        local itemIconParam = ItemIconParam.New(itemCfg, goodsCfg.item_count)
        self.m_item:UpdateData(itemIconParam)
        self.m_item:SetIconColor(self.m_canBuy)
    end)

    self:KeepIconCenter()
end

function ShopGoodsItem:OnClick(go, x, y)
    if self.m_canBuy then
        UIManagerInst:OpenWindow(UIWindowNames.UIBuyGoods, self.m_goodsData, self.m_shopType)
    end
end

function ShopGoodsItem:OnDestroy()
    self:SetItemColor(true)
    UIUtil.RemoveClickEvent(self.m_clickBtn.gameObject)

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_bagItemSeq)
    self.m_bagItemSeq = 0

    if self.m_item then
        self.m_item:SetIconColor(true)
        self.m_item:Delete()
        self.m_item = nil
    end

    if self.m_bgImg then
        self.m_bgImg:Delete()
        self.m_bgImg = nil
    end

    if self.m_discountImg then
        self.m_discountImg:Delete()
        self.m_discountImg = nil
    end

    if self.m_priceImg then
        self.m_priceImg:Delete()
        self.m_priceImg = nil
    end

    if self.m_titleBgImg then
        self.m_titleBgImg:Delete()
        self.m_titleBgImg = nil
    end
   
    base.OnDestroy(self)
end

function ShopGoodsItem:KeepIconCenter()
    local iconWidth = self.m_priceImgTrans.sizeDelta.x + 2
    local oldTextWidth = self.m_oldPriceText.preferredWidth + 6
    local newTextWidth = self.m_newPriceText.preferredWidth
    self.m_priceImgTrans.localPosition = Vector3.New(-(iconWidth + oldTextWidth + newTextWidth)/2 - 5, -6, 0)
    self.m_oldPriceTrans.localPosition = Vector3.New(iconWidth, 0, 0)
    self.m_newPriceTrans.localPosition = Vector3.New(iconWidth + oldTextWidth, 0, 0)
    self.m_lineImgTrans.localPosition = Vector3.New(iconWidth, -1.5, 0)
    self.m_lineImgTrans.sizeDelta = Vector2.New(oldTextWidth - 6, 3)
end

function ShopGoodsItem:SetItemColor(isWhite, isSoldOut)
    self.m_canBuy = isWhite
    self.m_bgImg:SetColor(isWhite and Color.white or Color.black)
    self.m_priceImg:SetColor(isWhite and Color.white or Color.black)
    self.m_discountImg:SetColor(isWhite and Color.white or Color.black)
    self.m_titleBgImg:SetColor(isWhite and Color.white or Color.black)

    self.m_oldPriceText.color = isWhite and Color.white or Color.gray
    self.m_newPriceText.color = isWhite and Color.white or Color.gray
    self.m_nameText.color = isWhite and Color.white or Color.gray
    if isSoldOut then
        self.m_desText.color = isWhite and Color.New255(235, 204, 145, 255) or Color.gray
    else
        self.m_desText.color = isWhite and Color.New255(235, 204, 145, 255) or Color.red
    end
end

return ShopGoodsItem