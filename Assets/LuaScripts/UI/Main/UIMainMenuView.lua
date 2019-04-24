local UIUtil = UIUtil
local math_floor = math.floor
local string_format = string.format
local UserMgr = Player:GetInstance():GetUserMgr()
local ArenaMgr = Player:GetInstance():GetArenaMgr()
local ConfigUtil = ConfigUtil
local ItemDefine = ItemDefine
local UILogicUtil = UILogicUtil
local DOTween = CS.DOTween.DOTween
local UIMainMenuView = BaseClass("UIMainMenuView", UIBaseView)
local base = UIBaseView

function UIMainMenuView:OnCreate()
    base.OnCreate(self)

    self.m_nextRecoverTime = 0
    self.m_allRecoverTime = 0

    self.m_arenaNextRecoverTime = 0
    self.m_arenaAllRecoverTime = 0
    
    self.m_yuanbaoText, self.m_tongqianText, self.m_staminaText, self.m_recoverDesTxt,
    self.m_nextRecoverText, self.m_allRecoverText = UIUtil.GetChildTexts(self.transform, {
        "TopRightContainer/YuanBao/YuanBaoText",
        "TopRightContainer/TongQian/TongQianText",
        "TopRightContainer/Stamina/StaminaText",
        "staminaRecover/recover/DesTxt",
        "staminaRecover/recover/nextRecover",
        "staminaRecover/recover/allRecover"
    })

    self.m_rightCurrencySpt = UIUtil.AddComponent(UIImage, self, "TopRightContainer/Stamina/StaminaImage", AtlasConfig.DynamicLoad)
    self.m_middleCurrencySpt = UIUtil.AddComponent(UIImage, self, "TopRightContainer/YuanBao/YuanBaoImage", AtlasConfig.DynamicLoad)

    self.m_topRightContainerTrans, self.m_yuanbaoAddBtnGO, self.m_staminaBtn,
    self.m_staminaAddBtn,self.m_closeRecoverBtn,self.m_staminaRecoverTr,
    self.m_staminaImgTrans, self.m_tongqianAddBtn = 
    UIUtil.GetChildRectTrans(self.transform, {
        "TopRightContainer",
        "TopRightContainer/YuanBao/YuanBaoAddBtn",
        "TopRightContainer/Stamina",
        "TopRightContainer/Stamina/StaminaAddBtn",
        "staminaRecover/closeBtn",
        "staminaRecover",
        "TopRightContainer/Stamina/StaminaImage",
        "TopRightContainer/TongQian/TongQianAddBtn",
    })

    self.m_topRightContainer = self.m_topRightContainerTrans.gameObject
    self.m_yuanbaoAddBtnGO = self.m_yuanbaoAddBtnGO.gameObject

    self.m_rightCurrency = ItemDefine.Stamina_ID
    self.m_middleCurrency = ItemDefine.YuanBao_ID
end

function UIMainMenuView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_yuanbaoAddBtnGO, onClick)
    UIUtil.AddClickEvent(self.m_staminaBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_staminaAddBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_closeRecoverBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_tongqianAddBtn.gameObject, onClick)
end

function UIMainMenuView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_yuanbaoAddBtnGO)
    UIUtil.RemoveClickEvent(self.m_staminaBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_staminaAddBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeRecoverBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_tongqianAddBtn.gameObject)
end

function UIMainMenuView:OnClick(go, x, y)
    if go.name == "StaminaAddBtn" then
        self:OnClickAdd()

    elseif go.name == "TongQianAddBtn" then
        if not UIManagerInst:IsWindowOpen(UIWindowNames.UIShop) then
            UILogicUtil.SysShowUI(SysIDs.SHOP)
        end

    elseif go.name == "YuanBaoAddBtn" then
        if not UIManagerInst:IsWindowOpen(UIWindowNames.UIVipShop) then
            UILogicUtil.SysShowUI(SysIDs.SHANG_CHENG)
        end

    elseif go.name == "Stamina" then
        local userData = UserMgr:GetUserData()
        local player = Player:GetInstance()

        if self.m_rightCurrency == ItemDefine.Stamina_ID  then
            self.m_recoverDesTxt.text = Language.GetString(1709)
            self.m_nextRecoverText.text = UILogicUtil.ChangeSecondToTime(userData.stamina_recovering_time - player:GetServerTime())
            self.m_allRecoverText.text = UILogicUtil.ChangeSecondToTime(userData.stamina_all_recovering_time - player:GetServerTime())
            self.m_staminaRecoverTr.gameObject:SetActive(true) 
        elseif self.m_rightCurrency == ItemDefine.ArenaFight_ID then
            self.m_recoverDesTxt.text = Language.GetString(1710)
            self.m_nextRecoverText.text = UILogicUtil.ChangeSecondToTime(userData.arena_ling_recovering_time - player:GetServerTime())
            self.m_allRecoverText.text = UILogicUtil.ChangeSecondToTime(userData.arena_ling_all_recovering_time - player:GetServerTime())
            self.m_staminaRecoverTr.gameObject:SetActive(true) 
        end 
    elseif go.name == "closeBtn" then
        self.m_staminaRecoverTr.gameObject:SetActive(false)
    end
end

function UIMainMenuView:Update()
    local run = self.m_staminaRecoverTr.gameObject.activeSelf
    local userData = UserMgr:GetUserData()

    if run and userData.stamina < userData.stamina_limit then
        local delta = Time.deltaTime
        if self.m_rightCurrency == ItemDefine.Stamina_ID  then
            if self.m_nextRecoverTime > 0 then
                self.m_nextRecoverTime = self.m_nextRecoverTime - delta
                self.m_nextRecoverText.text = UILogicUtil.ChangeSecondToTime(self.m_nextRecoverTime)
            else
                self.m_nextRecoverTime = userData.stamina_recovering_time - Player:GetInstance():GetServerTime()
            end

            if self.m_allRecoverTime > 0 then
                self.m_allRecoverTime = self.m_allRecoverTime - delta
                self.m_allRecoverText.text = UILogicUtil.ChangeSecondToTime(self.m_allRecoverTime)
            else
                self.m_allRecoverTime = 0
            end 
        end
    end

    if run and self.m_rightCurrency == ItemDefine.ArenaFight_ID then
        local delta = Time.deltaTime
        if self.m_arenaNextRecoverTime > 0 then
            self.m_arenaNextRecoverTime = self.m_arenaNextRecoverTime - delta
            self.m_nextRecoverText.text = UILogicUtil.ChangeSecondToTime(self.m_arenaNextRecoverTime)
        else
            if userData.arena_ling_recovering_time <= 0 then
                self.m_arenaNextRecoverTime = 0
            else
                self.m_arenaNextRecoverTime = userData.arena_ling_recovering_time - Player:GetInstance():GetServerTime()
            end 
        end

        if self.m_arenaAllRecoverTime > 0 then
            self.m_arenaAllRecoverTime = self.m_arenaAllRecoverTime - delta
            self.m_allRecoverText.text = UILogicUtil.ChangeSecondToTime(self.m_arenaAllRecoverTime)
        else
            self.m_arenaAllRecoverTime = 0
        end
    end 
end

function UIMainMenuView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_MAIN_TOP_STATE, self.ShowTopRightContainer)
    self:AddUIListener(UIMessageNames.MN_RIGHT_MENU_STATE, self.ShowBottomRightContainer)
    self:AddUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
    self:AddUIListener(UIMessageNames.MN_VIGOR_CHG, self.UpdateStamina)
    self:AddUIListener(UIMessageNames.MN_GOLD_CHG, self.UpdateMiddle)
    self:AddUIListener(UIMessageNames.MN_RSP_HEARTBEAT, self.RspHeartBeat)
    self:AddUIListener(UIMessageNames.MN_MAIN_TOP_RIGHT_CURRENCY_TYPE, self.ChgRightCurrencyType)
    self:AddUIListener(UIMessageNames.MN_MAIN_CHG_MIDDLE_CURRENCY_TYPE, self.ChgMiddleCurrencyType)
end

function UIMainMenuView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:RemoveUIListener(UIMessageNames.MN_MAIN_TOP_STATE, self.ShowTopRightContainer)
    self:RemoveUIListener(UIMessageNames.MN_RIGHT_MENU_STATE, self.ShowBottomRightContainer)
    self:RemoveUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
    self:RemoveUIListener(UIMessageNames.MN_VIGOR_CHG, self.UpdateStamina)
    self:RemoveUIListener(UIMessageNames.MN_GOLD_CHG, self.UpdateMiddle)
    self:RemoveUIListener(UIMessageNames.MN_RSP_HEARTBEAT, self.RspHeartBeat)
    self:RemoveUIListener(UIMessageNames.MN_MAIN_TOP_RIGHT_CURRENCY_TYPE, self.ChgRightCurrencyType)
    self:RemoveUIListener(UIMessageNames.MN_MAIN_CHG_MIDDLE_CURRENCY_TYPE, self.ChgMiddleCurrencyType)
end

function UIMainMenuView:RspHeartBeat(msg_obj)
    local userData = UserMgr:GetUserData() 
    self.m_nextRecoverTime = userData.stamina_recovering_time - msg_obj.game_time
    self.m_allRecoverTime = userData.stamina_all_recovering_time - msg_obj.game_time

    self.m_arenaNextRecoverTime = userData.arena_ling_recovering_time - msg_obj.game_time
    self.m_arenaAllRecoverTime = userData.arena_ling_all_recovering_time - msg_obj.game_time
end

function UIMainMenuView:ShowTopRightContainer(bShow, bShowStamina, layerOrderSetOrReStore)
    if IsNull(self.m_topRightContainer) then
        return
    end

    self.m_topRightContainer:SetActive(bShow)
    if bShowStamina ~= nil then
        self.m_staminaBtn.gameObject:SetActive(bShowStamina)
    end

    -- true,表示重写，false,表示恢复
    if layerOrderSetOrReStore then
        self.m_layerOrder = self:GetLayerOrder()
        self:SetLayerOrder(2500)
    else
        if self.m_layerOrder then
            self:SetLayerOrder(self.m_layerOrder)
            self.m_layerOrder = nil
        end
    end
    self:TweenOpen()
end

function UIMainMenuView:ShowBottomRightContainer(bShow)
    
end

function UIMainMenuView:OnEnable()
    base.OnEnable(self)

    self:HandleClick()
    self:UpdateTongQian()
    self:UpdateMiddle()
    self:UpdateRight()
    self:TweenOpen()
end

function UIMainMenuView:OnDisable()
    self:RemoveClick()
    base.OnDisable(self)
end

function UIMainMenuView:OnDestroy()
    self.m_nextRecoverTime = 0
    self.m_allRecoverTime = 0 

    self.m_topRightContainer = nil
    base.OnDestroy(self)
end

function UIMainMenuView:OnItemChg(chg_item_data_list)
    for _, item in ipairs(chg_item_data_list) do
        local itemID = item:GetItemID()

        if itemID == ItemDefine.TongQian_ID then
            self:UpdateTongQian()
        elseif itemID == ItemDefine.ArenaFight_ID or itemID == ItemDefine.YuanmenLing_ID or itemID == ItemDefine.DIANJIANGLING_ID 
        or itemID == ItemDefine.LieYuan_ID then
            if self.m_rightCurrency == itemID then
                self:UpdateRight()
            end
        elseif itemID == ItemDefine.ArenaCoin_ID or itemID == ItemDefine.QingYi_ID or itemID == ItemDefine.GuildCoin_ID then
            if self.m_middleCurrency == itemID then
                self:UpdateMiddle()
            end
        elseif itemID == ItemDefine.QunXiongZhuLu_ID then
            if self.m_rightCurrency == itemID then
                self:UpdateRight()
            end
            if self.m_middleCurrency == itemID then
                self:UpdateMiddle()
            end
        end
    end
end

function UIMainMenuView:UpdateTongQian()
    local count = Player:GetInstance():GetItemMgr():GetItemCountByID(ItemDefine.TongQian_ID)
    count = math_floor(count)
    self.m_tongqianText.text = count
end

function UIMainMenuView:UpdateMiddle()
    local currencyItemCfg = ConfigUtil.GetItemCfgByID(self.m_middleCurrency)
    if currencyItemCfg then
        self.m_middleCurrencySpt:SetAtlasSprite(currencyItemCfg.sIcon, false, AtlasConfig[currencyItemCfg.sAtlas])
    end
    if self.m_middleCurrency == ItemDefine.YuanBao_ID then
        local userData =  Player:GetInstance():GetUserMgr():GetUserData()
        self.m_yuanbaoText.text = string_format("%d", userData.yuanbao)
        self.m_yuanbaoAddBtnGO:SetActive(true)
    else
        self.m_yuanbaoAddBtnGO:SetActive(false)
        self.m_yuanbaoText.text =  string_format("%d", Player:GetInstance():GetItemMgr():GetItemCountByID(self.m_middleCurrency))
    end
end

function UIMainMenuView:UpdateRight()        
    local currencyItemCfg = ConfigUtil.GetItemCfgByID(self.m_rightCurrency)        
    if currencyItemCfg then
        self.m_rightCurrencySpt:SetAtlasSprite(currencyItemCfg.sIcon, false, AtlasConfig[currencyItemCfg.sAtlas])
    end

    if self.m_rightCurrency == ItemDefine.Stamina_ID then
        local userData = Player:GetInstance():GetUserMgr():GetUserData()
        self.m_staminaText.text = string_format(Language.GetString(77), userData.stamina, userData.stamina_limit)
    elseif self.m_rightCurrency == ItemDefine.ArenaFight_ID then
        local count = Player:GetInstance():GetItemMgr():GetItemCountByID(self.m_rightCurrency)
        local limit = Player:GetInstance():GetUserMgr():GetSettingData().arena_lingpai_limit
        if count >= limit then
            self.m_staminaText.text = string_format(Language.GetString(83), count, limit)
        else
            self.m_staminaText.text = string_format(Language.GetString(77), count, limit)
        end
    else
        self.m_staminaText.text = string_format("%d", Player:GetInstance():GetItemMgr():GetItemCountByID(self.m_rightCurrency))
    end

    if self.m_rightCurrency == ItemDefine.ArenaFight_ID or self.m_rightCurrency == ItemDefine.Stamina_ID then
        self.m_staminaAddBtn.gameObject:SetActive(true)
    else
        self.m_staminaAddBtn.gameObject:SetActive(false)
    end
end

function UIMainMenuView:UpdateStamina()
    if self.m_rightCurrency == ItemDefine.Stamina_ID then
        self.m_staminaAddBtn.gameObject:SetActive(true)

        local currencyItemCfg = ConfigUtil.GetItemCfgByID(ItemDefine.Stamina_ID)
        if currencyItemCfg then
            self.m_rightCurrencySpt:SetAtlasSprite(currencyItemCfg.sIcon, false, AtlasConfig[currencyItemCfg.sAtlas])
        end
        local userData =  Player:GetInstance():GetUserMgr():GetUserData()
        self.m_staminaText.text = string_format(Language.GetString(77), userData.stamina, userData.stamina_limit)  
    end
end

function UIMainMenuView:SetStaminaImgTransScale(scale)
    if not scale then
        return
    end
    self.m_staminaImgTrans.localScale = Vector3.New(scale,scale,scale)
end

function UIMainMenuView:ChgRightCurrencyType(currency)
    self.m_rightCurrency = currency
    self:UpdateRight()
end

function UIMainMenuView:ChgMiddleCurrencyType(currency)
    self.m_middleCurrency = currency

    self:UpdateMiddle()
end

function UIMainMenuView:OnClickAdd()
    if self.m_rightCurrency == ItemDefine.Stamina_ID then
        local userData = UserMgr:GetUserData()
        local max_buy_stamina_count = ConfigUtil.GetVipPrivilegeValue(userData.vip_level, 'stamina_count')

        if userData.today_buy_stamina_count >= max_buy_stamina_count then
            local contentMsg = string_format(Language.GetString(2707), userData.today_buy_stamina_count, max_buy_stamina_count)
            UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(2704), contentMsg, Language.GetString(10))

        else
            local data = {
                titleMsg = Language.GetString(2704),
                contentMsg = string_format(Language.GetString(2702), userData.today_buy_stamina_count, max_buy_stamina_count),
                yuanbao = string_format("%d",userData.next_buy_stamina_cost),
                buyCallback = Bind(UserMgr, UserMgr.ReqBuyStamina),
                currencyID = ItemDefine.Stamina_ID,
                currencyCount = 120,
            }           

            UIManagerInst:OpenWindow(UIWindowNames.UIBuyTipsDialog, data)
        end
    elseif self.m_rightCurrency == ItemDefine.ArenaFight_ID then
        local buyTimes = ArenaMgr:GetBuyArenaTimes()
        local costCfg = ConfigUtil.GetArenaBuyCost(buyTimes + 1)
        if not costCfg then
            UILogicUtil.FloatAlert(Language.GetString(2715))
            return
        end

        local userData = UserMgr:GetUserData()

        local data = {
            titleMsg = Language.GetString(2714),
            contentMsg = string_format(Language.GetString(2702), buyTimes, ConfigUtil.GetVipPrivilegeValue(userData.vip_level, 'arena_buy_times')),
            yuanbao = string_format("%d", costCfg.price),
            buyCallback = Bind(ArenaMgr, ArenaMgr.ReqBuyArenaTimes),
            currencyID = ItemDefine.ArenaFight_ID,
            currencyCount = 6,
        }        
        UIManagerInst:OpenWindow(UIWindowNames.UIBuyTipsDialog, data)
    end
end

function UIMainMenuView:TweenOpen()
    DOTween.ToFloatValue(function()
        return 0
    end, 
    function(value)
        self.m_topRightContainerTrans.anchoredPosition = Vector3.New(0, 150 - 150 * value, 0)
    end, 1, 0.3)
end

return UIMainMenuView