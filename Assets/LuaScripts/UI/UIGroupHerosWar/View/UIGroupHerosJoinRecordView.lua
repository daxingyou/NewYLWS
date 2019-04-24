
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

local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local GroupHerosMgr = Player:GetInstance():GetGroupHerosMgr()

local UIGroupHerosJoinRecordView = BaseClass("UIGroupHerosJoinRecordView", UIBaseView)
local base = UIBaseView

function UIGroupHerosJoinRecordView:OnCreate()
    base.OnCreate(self)

    self.m_saijiItemList = {}

    self:InitView()
end

function UIGroupHerosJoinRecordView:InitView()
    local title1Text, title2Text, title3Text, title4Text, title5Text

    title1Text, title2Text, title3Text, title4Text, title5Text = UIUtil.GetChildTexts(self.transform, {
        "Container/Titlebg/Title1",
        "Container/Titlebg/Title2",
        "Container/Titlebg/Title3",
        "Container/Titlebg/Title4",
        "Container/Titlebg/Title5",
    })
    
    self.m_backBtn, self.m_contentTr, self.m_saijiItemTr = UIUtil.GetChildTransforms(self.transform, {
        "BackBtn",
        "Container/ScrollView/Viewport/Content",
        "Container/SaijiItem",
    })

    local titleTextList = {title1Text, title2Text, title3Text, title4Text, title5Text}
    local titleNameList = string_split(Language.GetString(3976), "|")
    for i, name in ipairs(titleNameList) do
        titleTextList[i].text = name
    end
    
    self.m_saijiItemPrefab = self.m_saijiItemTr.gameObject

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
end

function UIGroupHerosJoinRecordView:OnClick(go)
    if go.name == "BackBtn" then
        self:CloseSelf()
    end
end

function UIGroupHerosJoinRecordView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    base.OnDestroy(self)
end

function UIGroupHerosJoinRecordView:OnAddListener()
    base.OnAddListener(self)

    self:AddUIListener(UIMessageNames.MN_QUNXIONGZHULU_RSP_SEASON_RECORDS, self.RspPanel)
end

function UIGroupHerosJoinRecordView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_QUNXIONGZHULU_RSP_SEASON_RECORDS, self.RspPanel)
    
    base.OnRemoveListener(self)
end

function UIGroupHerosJoinRecordView:OnEnable(...)
    base.OnEnable(self, ...)
    
    GroupHerosMgr:ReqSeasonRecord()
end

function UIGroupHerosJoinRecordView:RspPanel(recordList)

    if not recordList then
        return
    end

    for i, v in ipairs(recordList) do
        local saijiItem = self.m_saijiItemList[i]
        if not saijiItem then
            saijiItem = GameObject.Instantiate(self.m_saijiItemPrefab)
            local saijiItemTr = saijiItem.transform
            saijiItemTr:SetParent(self.m_contentTr)
            saijiItemTr.localScale = Vector3.one
            saijiItemTr.localPosition = Vector3.zero
            table_insert(self.m_saijiItemList, saijiItem)
        end
        local indexText = UIUtil.GetChildTexts(saijiItem.transform, {"IndexText"})
        local notJoinText = UIUtil.GetChildTexts(saijiItem.transform, {"NotJoinText"})
        local joinCountText = UIUtil.GetChildTexts(saijiItem.transform, {"JoinCountText"})
        local winCountText = UIUtil.GetChildTexts(saijiItem.transform, {"WinCountText"})
        local winRateText = UIUtil.GetChildTexts(saijiItem.transform, {"WinRateText"})
        local rankText = UIUtil.GetChildTexts(saijiItem.transform, {"RankText"})

        if v.total_times <= 0 then
            indexText.text = math_ceil(v.season)
            notJoinText.text = Language.GetString(3977)
            joinCountText.text = ""
            winCountText.text = ""
            winRateText.text = ""
            rankText.text = ""
        else
            indexText.text = math_ceil(v.season)
            notJoinText.text = ""
            joinCountText.text = math_ceil(v.total_times)
            winCountText.text = math_ceil(v.win_times)
            winRateText.text = math_ceil((v.win_times/v.total_times) * 100).."%"
            rankText.text = string_format(Language.GetString(3975), v.world_rank)
        end
    end
end

function UIGroupHerosJoinRecordView:OnDisable()
    
    for _, v in ipairs(self.m_saijiItemList) do
        GameObject.Destroy(v)
    end 
    self.m_saijiItemList = {}
    base.OnDisable(self)
end


return UIGroupHerosJoinRecordView