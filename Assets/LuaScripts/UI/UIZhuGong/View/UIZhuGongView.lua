
local UIUtil = UIUtil
local UserMgr = Player:GetInstance():GetUserMgr()
local UIGameObjectLoader = UIGameObjectLoader:GetInstance()
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local LoopScrollView = LoopScrowView
local Vector3 = Vector3
local ConfigUtil = ConfigUtil
local table_dump = table.dump
local table_insert = table.insert
local table_sort = table.sort
local math_ceil = math.ceil
local WuJiangMgr = Player:GetInstance():GetWujiangMgr()

local UserItemPrefab = TheGameIds.UserItemPrefab
local UserItemClass = require("UI.UIUser.UserItem")

local base = UIBaseView
local UIZhuGongView = BaseClass("UIZhuGongView",UIBaseView)

local MAX_ITEM_SHOW_COUNT = 24

function UIZhuGongView:OnCreate()
    base.OnCreate(self)
    self:InitView()
end


function UIZhuGongView:OnAddListener()
    base.OnAddListener(self)
    --UI消息注册
    self:AddUIListener(UIMessageNames.MN_USER_RSP_CHANGENAME, self.RspChangName)
    self:AddUIListener(UIMessageNames.MN_USER_RSP_USE_HEAD_ICON, self.RspUseHeadIcon)
end 

function UIZhuGongView:OnRemoveListener()
    base.OnRemoveListener(self)
    --消息注销
    self:RemoveUIListener(UIMessageNames.MN_USER_RSP_CHANGENAME, self.RspChangName)
    self:RemoveUIListener(UIMessageNames.MN_USER_RSP_USE_HEAD_ICON, self.RspUseHeadIcon)
end

function UIZhuGongView:RspChangName()
    self.m_nameText.text = UserMgr:GetUserData().name
end

function UIZhuGongView:GetHeadIconList()
    local headIconCfgList = ConfigUtil.GetHeadIconCfgList()
    local wujiangList = WuJiangMgr:GetWuJiangDict()

    table_insert(self.m_headIconList, headIconCfgList[1].icon)

    for k, icon in pairs(wujiangList) do
        if icon.star >= 3 then
            local isHave = false
            for _, v in ipairs(self.m_headIconList) do
                if v == icon.id then
                    isHave = true
                    break
                end
            end
            if not isHave then
                table_insert(self.m_headIconList, icon.id)
            end
        end
    end
end

function UIZhuGongView:RspUseHeadIcon(msg_obj)
    self:HeadUpdate(msg_obj.use_icon.icon)
end

function UIZhuGongView:InitView()
    local nameDesc, uidDesc, viewUserText, ChangeHeadIconDesc, notificationDesc, levelDesc, expDesc,
    guildDesc, guildIdDesc, serverDesc, soundDesc, musicDesc, headIconBtnText, headIconBoxBtnText, infoText, privilegeBtnText

    self.m_seqList = {}
    self.m_headIconList = {}
    self.m_headIconItemList = {}
    self.m_curHeadIconItem = nil
    self.m_seq = 0

    self.m_nameText, self.m_nameIdText, self.m_levelText,self.m_expText,
    self.m_juntuanText, self.m_juntuanIdText, self.m_serverText, viewUserText,
    nameDesc, uidDesc, ChangeHeadIconDesc, notificationDesc, levelDesc, expDesc,
    guildDesc, guildIdDesc, serverDesc, soundDesc, musicDesc, headIconBtnText,
    headIconBoxBtnText, infoText, privilegeBtnText = UIUtil.GetChildTexts(self.transform, {
        "zhugongPanel/upContainer/playerName/name/nameText",
        "zhugongPanel/upContainer/nameId/nameIdText",
        "zhugongPanel/middleContainer/zhugongLevel/level/levelText",
        "zhugongPanel/middleContainer/currentExp/exp/expText",
        "zhugongPanel/middleContainer/juntuan/image/juntuanText",
        "zhugongPanel/middleContainer/juntuanId/image/juntuanIdText",
        "zhugongPanel/middleContainer/server/image/serverText",
        "zhugongPanel/upContainer/viewUserBtn/viewUserText",
        "zhugongPanel/upContainer/playerName/playerName1",
        "zhugongPanel/upContainer/nameId/nameId1",
        "zhugongPanel/upContainer/changeHeadIconBtn/Text",
        "zhugongPanel/upContainer/tuisongtxBtn/Text",
        "zhugongPanel/middleContainer/zhugongLevel/Text",
        "zhugongPanel/middleContainer/currentExp/Text",
        "zhugongPanel/middleContainer/juntuan/Text",
        "zhugongPanel/middleContainer/juntuanId/Text",
        "zhugongPanel/middleContainer/server/Text",
        "zhugongPanel/middleContainer/sound/Text",
        "zhugongPanel/middleContainer/music/Text",
        "headIconPanel/bgRoot/contentRoot/headIconBtn/Text",
        "headIconPanel/bgRoot/contentRoot/headIconBoxBtn/Text",
        "headIconPanel/bgRoot/contentRoot/headIconView/text",
        "zhugongPanel/upContainer/privilegeBtn/Text",
    })

    nameDesc.text = Language.GetString(2718)
    uidDesc.text = Language.GetString(2719)
    viewUserText.text = Language.GetString(2717)
    ChangeHeadIconDesc.text = Language.GetString(2720)
    notificationDesc.text = Language.GetString(2721)
    levelDesc.text = Language.GetString(2722)
    expDesc.text = Language.GetString(2723)
    guildDesc.text = Language.GetString(2724)
    guildIdDesc.text = Language.GetString(2725)
    serverDesc.text = Language.GetString(2726)
    soundDesc.text = Language.GetString(2727)
    musicDesc.text = Language.GetString(2728)
    headIconBtnText.text = Language.GetString(2729)
    headIconBoxBtnText.text = Language.GetString(2730)
    infoText.text = Language.GetString(2731)
    privilegeBtnText.text = Language.GetString(2736)

    self.m_closeBtn, self.m_changeHeadIconBtn, self.m_changeNameBtn, self.m_itemParentTr,
    self.m_tuisongBtn, self.m_viewUserBtn, self.m_privilegeBtn = UIUtil.GetChildTransforms(self.transform, {
        "closeBtn",
        "zhugongPanel/upContainer/changeHeadIconBtn",
        "zhugongPanel/upContainer/playerName/changeNameBtn",
        "zhugongPanel/upContainer/headIcon",
        "zhugongPanel/upContainer/tuisongtxBtn",
        "zhugongPanel/upContainer/viewUserBtn",
        "zhugongPanel/upContainer/privilegeBtn",
    })

    self.m_headIconPanelTr, self.m_headIconScrollViewTr, self.m_headIconBoxScrollViewTr, self.m_bgRootTr,
    self.m_closeHeadIconBtn2, self.m_headIconBtn, self.m_headIconBoxBtn,self.m_closeHeadIconBtn1 = UIUtil.GetChildTransforms(self.transform, {
        "headIconPanel",
        "headIconPanel/bgRoot/contentRoot/headIconView",
        "headIconPanel/bgRoot/contentRoot/headIconBoxView",
        "headIconPanel/bgRoot",
        "headIconPanel/bgRoot/closeHeadIconBtn2",
        "headIconPanel/bgRoot/contentRoot/headIconBtn",
        "headIconPanel/bgRoot/contentRoot/headIconBoxBtn",
        "headIconPanel/closeHeadIconBtn1"
    })

    self.m_headIconContent, self.m_headIconBoxContent = UIUtil.GetChildTransforms(self.transform, {
        "headIconPanel/bgRoot/contentRoot/headIconView/Viewport/headIconContent",
        "headIconPanel/bgRoot/contentRoot/headIconBoxView/Viewport/headIconBoxContent"
    })

    self.m_headIconScrollView = self:AddComponent(LoopScrowView, "headIconPanel/bgRoot/contentRoot/headIconView/Viewport/headIconContent", Bind(self, self.UpdateHeadIconItem))
    --self.m_headIconBoxScrollView = self:AddComponent(LoopScrowView, "headIconPanel/contentRoot/headIconBoxView/Viewport/headIconBoxContent", Bind(self, self.UpdateHeadIconBoxItem))

    self.m_headIconBtnImg = UIUtil.AddComponent(UIImage, self, "headIconPanel/bgRoot/contentRoot/headIconBtn", AtlasConfig.DynamicLoad)
    self.m_headIconBoxBtnImg = UIUtil.AddComponent(UIImage, self, "headIconPanel/bgRoot/contentRoot/headIconBoxBtn", AtlasConfig.DynamicLoad)
    self.m_wuqitxRectTr = UIUtil.FindComponent(self.transform, Type_RectTransform, "zhugongPanel/middleContainer/wuqitx/wuqitxBtn/image")

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    UIUtil.AddClickEvent(self.m_changeHeadIconBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_changeNameBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_tuisongBtn.gameObject,onClick)
    UIUtil.AddClickEvent(self.m_closeHeadIconBtn2.gameObject,onClick)
    UIUtil.AddClickEvent(self.m_headIconBtn.gameObject,onClick)
    UIUtil.AddClickEvent(self.m_headIconBoxBtn.gameObject,onClick)
    UIUtil.AddClickEvent(self.m_closeHeadIconBtn1.gameObject,onClick)
    UIUtil.AddClickEvent(self.m_viewUserBtn.gameObject,onClick)
    UIUtil.AddClickEvent(self.m_privilegeBtn.gameObject,onClick)   
    self.m_headIconPanelTr.gameObject:SetActive(false)


    
    self.m_soundSlider = UIUtil.FindSlider(self.transform, "zhugongPanel/middleContainer/sound/soundSlider")
    self.m_soundSlider.onValueChanged:AddListener(function(slider_value)
        AudioMgr:UserSetVolume(slider_value)
    end)

    self.m_soundSlider.value = AudioMgr:GetVolume()

    self.m_musicSlider = UIUtil.FindSlider(self.transform, "zhugongPanel/middleContainer/music/musicSlider")
    self.m_musicSlider.onValueChanged:AddListener(function(slider_value)
        AudioMgr:UserSetSceneVolume(slider_value)
    end)

    self.m_musicSlider.value = AudioMgr:GetSceneVolume()
  
end

function UIZhuGongView:OnEnable(...)
    base.OnEnable(self, ...)

    self.m_delayCreateItem = false
    self.m_createCountRecord = 0

    local userData = UserMgr:GetUserData()
    self:GetHeadIconList()
    local headIconCfgList = ConfigUtil.GetHeadIconCfgList()
    self.m_headIconCfgList = self:SortHeadIconList(self.m_headIconList, headIconCfgList)
    
    if userData then
        local userExpCfg = ConfigUtil.GetUserExpCfgByID(userData.level)
        self.m_nameText.text = userData.name
        self.m_nameIdText.text = math_ceil(userData.uid)
        self.m_levelText.text = string.format(Language.GetString(2703), math_ceil(userData.level), UserMgr:GetSettingData().max_user_level)
        self.m_expText.text = string.format(Language.GetString(2703), math_ceil(userData.exp), userExpCfg.nExp)
        self.m_juntuanText.text = userData.guild_name
        self.m_juntuanIdText.text = math_ceil(userData.guild_id) 
    end

    if not self.m_curHeadIconItem and self.m_seq == 0 then
        self.m_seq = UIGameObjectLoader:PrepareOneSeq()
        UIGameObjectLoader:GetGameObject(self.m_seq, UserItemPrefab, function(obj)
            self.m_seq = 0
            if obj then
                self.m_curHeadIconItem = UserItemClass.New(obj, self.m_itemParentTr, UserItemPrefab)
                self.m_curHeadIconItem:SetAnchoredPosition(Vector3.zero)
                self.m_curHeadIconItem:UpdateData(userData.use_icon_data.icon, nil, nil, Bind(self, self.ChangeHeadIcon), false, nil, false)
            end
        end)
    else
        self.m_curHeadIconItem:UpdateData(userData.use_icon_data.icon, nil, nil, Bind(self, self.ChangeHeadIcon), false, nil, false)
    end

    self.m_headIconBtnImg:SetAtlasSprite("ty32.png")
    self.m_headIconBoxBtnImg:SetAtlasSprite("ty31.png")
    self.m_headIconScrollViewTr.gameObject:SetActive(true)
    self.m_headIconBoxScrollViewTr.gameObject:SetActive(false)
end

function UIZhuGongView:ChangeHeadIcon()
    self.m_headIconPanelTr.gameObject:SetActive(true)

    self:HeadIconOpen()

    self:CreateHeadIconList() 
end

function UIZhuGongView:OnClick(go)
    if go.name == "closeBtn" then 
        -- print(" UIZhuGong Close "..go.name)
        self:CloseSelf()

    elseif go.name == "changeHeadIconBtn" then
        self.m_headIconPanelTr.gameObject:SetActive(true)
        self:HeadIconOpen()
        self:CreateHeadIconList() 

    elseif go.name == "changeNameBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIChangeName)

    elseif go.name == "closeHeadIconBtn2" then
        self:HeadIconClose()

    elseif go.name == "headIconBtn" then
        self.m_headIconScrollViewTr.gameObject:SetActive(true)
        self.m_headIconBoxScrollViewTr.gameObject:SetActive(false)
        self.m_headIconBtnImg:SetAtlasSprite("ty32.png")
        self.m_headIconBoxBtnImg:SetAtlasSprite("ty31.png")

    elseif go.name == "headIconBoxBtn" then
        self.m_headIconScrollViewTr.gameObject:SetActive(false)
        self.m_headIconBoxScrollViewTr.gameObject:SetActive(true)
        self.m_headIconBtnImg:SetAtlasSprite("ty31.png")
        self.m_headIconBoxBtnImg:SetAtlasSprite("ty32.png")

    elseif go.name == "closeHeadIconBtn1" then
        self:HeadIconClose()

    elseif go.name == "viewUserBtn" then

        UIManagerInst:OpenWindow(UIWindowNames.UIUserDetail)
    elseif go.name == "tuisongtxBtn" then
        

        UIManagerInst:OpenWindow(UIWindowNames.UINotificationSetting)
    elseif go.name == "privilegeBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIVip)
    end
end

function UIZhuGongView:HeadIconOpen()
	self.m_bgRootTr.localScale = Vector3.one * 0.01
	local tweener = DOTweenShortcut.DOScale(self.m_bgRootTr, 1, 0.4)
	DOTweenSettings.SetEase(tweener, DoTweenEaseType.OutBack)
end

function UIZhuGongView:HeadIconClose()
	local tweener = DOTweenShortcut.DOScale(self.m_bgRootTr, 0.01, 0.3)
	DOTweenSettings.SetEase(tweener, DoTweenEaseType.InBack)
    DOTweenSettings.OnComplete(tweener, function()
        self.m_headIconScrollView:OnDisable()
        if self.m_headIconItemList then
            for _, item in pairs(self.m_headIconItemList) do
                item:Delete()
            end
            self.m_headIconItemList = {}
        end

        self.m_headIconPanelTr.gameObject:SetActive(false)
    end)
end

function UIZhuGongView:HasIcon(icon)
    for k,v in ipairs(self.m_headIconList) do
        if v == icon then
            return false
        end
    end
    return true
end

function UIZhuGongView:SortHeadIconList(useList, allList)
    local headIconList = {}
    
    for k, v in pairs(allList) do
        for i, j in pairs(useList) do
            if j == v.icon then
                table_insert(headIconList, v)
                break
            end
        end
    end

    for k, v in pairs(allList) do
        local isHave = false
        for i, j in pairs(headIconList) do
            if j.icon == v.icon then
                isHave = true
                break
            end
        end
        if not isHave then
            table_insert(headIconList, v)
        end
    end
    return headIconList
end

function UIZhuGongView:GetHeadIconByID(id)
    if self.m_headIconCfgList then
        for k, v in pairs(self.m_headIconCfgList) do
            if v.id == id then
                return v.icon
            end
        end
    end
    return 0
end

function UIZhuGongView:HeadUpdate(headIconId)
    self.m_curHeadIconItem:UpdateData(headIconId, nil, nil, Bind(self, self.ChangeHeadIcon), false, nil, false)

    for i = 1, #self.m_headIconCfgList do
        if self.m_headIconCfgList[i].id == headIconId then
            for k,v in pairs(self.m_headIconItemList) do
                v:SetUseHeadIcon(tonumber(v:GetHeadIconId()) == headIconId)
            end
        end
    end
end

function UIZhuGongView:CreateHeadIconList()
    if #self.m_headIconItemList == 0 then
        self.m_delayCreateItem = true
        self.m_createCountRecord = 0
        UIManagerInst:SetUIEnable(false)

        self.m_headIconScrollView:ResetPosition() 
    else
        self.m_headIconScrollView:UpdateView(false, self.m_headIconItemList, self.m_headIconCfgList)
    end
end

function UIZhuGongView:UpdateHeadIconItem(item, realIndex)
   
    local userIconData = UserMgr:GetUserData().use_icon_data
    if self.m_headIconCfgList then
        if item and realIndex > 0 and realIndex < #self.m_headIconCfgList then
            local data = self.m_headIconCfgList[realIndex]
           
            local hasIcon = self:HasIcon(data.icon)
            if hasIcon then
                item:UpdateData(data.id, nil, nil, nil, userIconData.icon == data.id, nil, hasIcon)
            else
                item:UpdateData(data.id, nil, nil, Bind(self, self.HeadIconItemClick), userIconData.icon == data.id, nil, hasIcon)
            end
        end
    end
end

function UIZhuGongView:HeadIconItemClick(item)
    if not item:GetIsUsed() then
        local titleMsg = Language.GetString(2709)
        local contentMsg = Language.GetString(2708)
        local btnOneMsg = Language.GetString(10)
        local btnTwoMsg = Language.GetString(50)
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, titleMsg, contentMsg, btnOneMsg, Bind(UserMgr, UserMgr.ReqUseHeadIcon, item:GetHeadIconId()), btnTwoMsg)
    end
end

function UIZhuGongView:UpdateHeadIconBoxItem(item, realIndex)

end

function UIZhuGongView:OnDisable()
    if self.m_seq > 0 then
        UIGameObjectLoader:CancelLoad(self.m_seq)
        self.m_seq = 0
    end

 

    if self.m_headIconItemList then
        for _, item in pairs(self.m_headIconItemList) do
            item:Delete()
        end
        self.m_headIconItemList = {}
    end

    self.m_curHeadIconItem:Delete()
    self.m_curHeadIconItem = nil

    self.m_springContent = nil
    self.m_headIconList = {}

    for i, v in pairs(self.m_seqList) do
        UIGameObjectLoader:CancelLoad(i)
    end
    self.m_seqList = {}

    base.OnDisable(self)
end

function UIZhuGongView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_changeHeadIconBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_changeNameBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_tuisongBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeHeadIconBtn2.gameObject)
    UIUtil.RemoveClickEvent(self.m_headIconBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_headIconBoxBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeHeadIconBtn1.gameObject)
    UIUtil.RemoveClickEvent(self.m_viewUserBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_privilegeBtn.gameObject)

    if self.m_musicSlider then
        self.m_musicSlider.onValueChanged:RemoveAllListeners()
        self.m_musicSlider = nil
    end

    if self.m_soundSlider then
        self.m_soundSlider.onValueChanged:RemoveAllListeners()
        self.m_soundSlider = nil
    end

    base.OnDestroy(self)
end

function UIZhuGongView:Update()
    if not self.m_delayCreateItem then
        return
    end

    if self.m_createCountRecord < MAX_ITEM_SHOW_COUNT then
        local seq = UIGameObjectLoader:PrepareOneSeq()
        self.m_seqList[seq] = true
        UIGameObjectLoader:GetGameObject(seq, UserItemPrefab, function(obj, seq)
            self.m_seqList[seq] = false
            if not IsNull(obj) then
                local headIconItem = UserItemClass.New(obj, self.m_headIconContent, UserItemPrefab)
                table_insert(self.m_headIconItemList, headIconItem)

                if #self.m_headIconItemList == MAX_ITEM_SHOW_COUNT then
                    self.m_headIconScrollView:UpdateView(true, self.m_headIconItemList, self.m_headIconCfgList)
                else
                    local dataIndex = self.m_createCountRecord + 1
                    self.m_headIconScrollView:UpdateOneItem(headIconItem, dataIndex, #self.m_headIconItemList)
                end
            end
        end, seq)

        self.m_createCountRecord = self.m_createCountRecord + 1
        if self.m_createCountRecord >= MAX_ITEM_SHOW_COUNT then
            self.m_delayCreateItem = false
            UIManagerInst:SetUIEnable(true)
        end
    end
end


return UIZhuGongView

