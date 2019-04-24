local string_split = string.split
local math_floor = math.floor

local UIGuildManageView = BaseClass("UIGuildManageView", UIBaseView)
local base = UIBaseView

local GuildMgr = Player:GetInstance().GuildMgr
local CommonDefine = CommonDefine


function UIGuildManageView:OnCreate()

    base.OnCreate(self)

    self:InitView()
end

function UIGuildManageView:InitView()

    local editBtnText, postBtnText, examineBtnText, abdicateBtnText, 
    exitBtnText, titleText = UIUtil.GetChildTexts(self.transform, {
        "Container/Edit_BTN/EditBtnText",
        "Container/Post_BTN/PostBtnText",
        "Container/Examine_BTN/ExamineBtnText",
        "Container/Abdicate_BTN/AbdicateBtnText",
        "Container/Exit_BTN/ExitBtnText",
        "Container/bg2/TitleBg/TitleText",
    })

    self.m_editBtnRectTran, self.m_postBtnRectTran, self.m_examineBtnRectTran, self.m_abdicateBtnRectTran, 
    self.m_exitBtnRectTran, self.m_closeBtn, self.m_bgRectTran, self.m_examineRedPointGo = UIUtil.GetChildRectTrans(self.transform, {
        "Container/Edit_BTN",
        "Container/Post_BTN",
        "Container/Examine_BTN",
        "Container/Abdicate_BTN",
        "Container/Exit_BTN",
        "CloseBtn",
        "Container/bg2",
        "Container/Examine_BTN/redPoint",
    })

    self.m_examineRedPointGo = self.m_examineRedPointGo.gameObject
    self.m_btnList = { self.m_editBtnRectTran, self.m_postBtnRectTran, 
        self.m_examineBtnRectTran, self.m_abdicateBtnRectTran, self.m_exitBtnRectTran }

    local btnList = { editBtnText, postBtnText, examineBtnText, abdicateBtnText, exitBtnText }
    local btnNameTexts = string_split(Language.GetString(1366), "|")

    for i, v in ipairs(btnNameTexts) do 
        if btnList[i] then
            btnList[i].text = v
        end
    end

    titleText.text = Language.GetString(1336)

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_editBtnRectTran.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_postBtnRectTran.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_examineBtnRectTran.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_abdicateBtnRectTran.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_exitBtnRectTran.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_closeBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
end

function UIGuildManageView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_DETAIL, self.UpdateRedPoint) 
end

function UIGuildManageView:OnRemoveListener()
	base.OnRemoveListener(self)
	
    self:AddUIListener(UIMessageNames.MN_GUILD_RSP_GUILD_DETAIL, self.UpdateRedPoint)
end

function UIGuildManageView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_editBtnRectTran.gameObject)
    UIUtil.RemoveClickEvent(self.m_postBtnRectTran.gameObject)
    UIUtil.RemoveClickEvent(self.m_examineBtnRectTran.gameObject)
    UIUtil.RemoveClickEvent(self.m_abdicateBtnRectTran.gameObject)
    UIUtil.RemoveClickEvent(self.m_exitBtnRectTran.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    base.OnDestroy(self)
end

function UIGuildManageView:OnEnable(...)
   
    base.OnEnable(self, ...)

    local myGuildData = GuildMgr.MyGuildData
    if not myGuildData then
        return
    end

    self:UpdateRedPoint()

    for i, v in ipairs(self.m_btnList) do
        v.gameObject:SetActive(myGuildData.self_post == CommonDefine.GUILD_POST_COLONEL)
        local posX = (i - 1) % 2 == 0 and -140 or 140
        local posY = 103.7 - 120 * math_floor((i - 1) / 2)
        v.anchoredPosition = Vector2.New(posX, posY)
    end

    if myGuildData.self_post == CommonDefine.GUILD_POST_NORMAL then
        self.m_exitBtnRectTran.gameObject:SetActive(true)
        self.m_exitBtnRectTran.anchoredPosition = Vector2.New(0, 0)
        self.m_bgRectTran.sizeDelta = Vector2.New(604, 422)
    elseif myGuildData.self_post == CommonDefine.GUILD_POST_COLONEL then
        self.m_bgRectTran.sizeDelta = Vector2.New(688.9, 506.8)
    else
        self.m_exitBtnRectTran.gameObject:SetActive(true)
        self.m_examineBtnRectTran.gameObject:SetActive(true)
        self.m_examineBtnRectTran.anchoredPosition = Vector2.New(0, 60)
        self.m_exitBtnRectTran.anchoredPosition = Vector2.New(0, -60)
        self.m_bgRectTran.sizeDelta = Vector2.New(604, 422)
    end
end

function UIGuildManageView:UpdateRedPoint()
    local myGuildData = GuildMgr.MyGuildData
    if not myGuildData then
        return
    end

    if #myGuildData.red_point_list > 0 then
        for i, v in ipairs(myGuildData.red_point_list) do
            if v == 1 then
                self.m_examineRedPointGo:SetActive(true)
                break
            end
        end
    else
        self.m_examineRedPointGo:SetActive(false)
    end
end

function UIGuildManageView:OnClick(go, x, y)
    if go.name == "CloseBtn" then
        self:CloseSelf() 

    elseif go.name == "Examine_BTN" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildApplyList)

    elseif go.name == "Edit_BTN" then
        local myGuildData = GuildMgr.MyGuildData
        local data = {Language.GetString(1416), Language.GetString(1417), myGuildData.name, myGuildData.declaration}
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildCreate, data)

    elseif go.name == "Post_BTN" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildPost)
    elseif go.name == "Abdicate_BTN" then
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(1405), Language.GetString(1406),
        Language.GetString(632), Bind(GuildMgr, GuildMgr.ReqAbdicate), Language.GetString(50))

    elseif go.name == "Exit_BTN" then
        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(1402), Language.GetString(1403),
        Language.GetString(632), Bind(GuildMgr, GuildMgr.ReqExit), Language.GetString(50))

    end
end



return UIGuildManageView