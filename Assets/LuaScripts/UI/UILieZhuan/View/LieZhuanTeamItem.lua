local string_format = string.format
local ConfigUtil = ConfigUtil
local table_insert = table.insert
local string_split = CUtil.SplitString
local UserItemPrefab = TheGameIds.UserItemPrefab
local UIGameObjectLoader = UIGameObjectLoader:GetInstance()
local UserItemClass = require "UI.UIUser.UserItem"
local LieZhuanMgr = Player:GetInstance():GetLieZhuanMgr()

local LieZhuanTeamItem = BaseClass("LieZhuanTeamItem", UIBaseItem)
local base = UIBaseItem

function LieZhuanTeamItem:OnCreate()
    base.OnCreate(self)
    self:InitView()
end

function LieZhuanTeamItem:InitView()
    local addBtnText
    self.m_playerNameList = {}
    self.m_countryText, addBtnText, self.m_playerNameList[1], self.m_playerNameList[2], self.m_playerNameList[3] = UIUtil.GetChildTexts(self.transform, { 
        "countryText",
        "addBtn/addBtnText",
        "nameContent/player1Text",
        "nameContent/player2Text",
        "nameContent/player3Text", 
    })

    self.m_userHeadContent = {}
    self.m_playerContent, self.m_addBtn, self.m_userHeadContent[1], self.m_userHeadContent[2], self.m_userHeadContent[3] = UIUtil.GetChildTransforms(self.transform, {
        "playerContent",
        "addBtn",
        "playerContent/UserIcon1Bg",
        "playerContent/UserIcon2Bg",
        "playerContent/UserIcon3Bg",
     })

    self.m_sCountryNameList = string_split(Language.GetString(3750), ",")
    self.m_playerHeadList = {}
    self.m_teamData = nil

    addBtnText.text = Language.GetString(3765)

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_addBtn.gameObject, onClick)
end

function LieZhuanTeamItem:OnClick(go)
    if go.name == "addBtn" then
        if self.m_teamData then
            LieZhuanMgr:ReqLiezhuanJoinTeam(self.m_teamData.team_base_info.team_id, 0, false, self.m_teamData.team_base_info.copy_id)
            LieZhuanMgr:ReqLiezhuanTeamList(LieZhuanMgr:GetSelectCountry(), self.m_teamData.team_base_info.copy_id)
        end       
    end
end

function LieZhuanTeamItem:ClearPlayerHead()
    if self.m_playerHeadList then
        for i, v in ipairs(self.m_playerHeadList) do
            v:Delete()
        end
        self.m_playerHeadList = {}
    end
end

function LieZhuanTeamItem:CreatePlayerHead(member_list)
    if not member_list then
        return
    end
    self:ClearPlayerHead()
    self.m_Seq = UIGameObjectLoader:PrepareOneSeq()
    UIGameObjectLoader:GetGameObjects(self.m_Seq, UserItemPrefab, #member_list, function(objs)
        self.m_Seq = 0
        if objs then
            for i = 1, #objs do
                local userItem = UserItemClass.New(objs[i], self.m_userHeadContent[i], UserItemPrefab)
                if userItem then
                    userItem:SetLocalScale(Vector3.New(1, 1, 1))
                    table_insert(self.m_playerHeadList, userItem)
                    local userBrief = member_list[i].user_brief
                    if userBrief and userBrief.use_icon then
                        userItem:UpdateData(userBrief.use_icon.icon, userBrief.use_icon.icon_box, userBrief.level)
                        self.m_playerNameList[i].text = userBrief.name
                    end                    
                end
            end
        end
    end)
end

function LieZhuanTeamItem:UpdateData(teamData)
    if teamData then
        self.m_teamData = teamData
        self:CreatePlayerHead(teamData.member_list)
    end

    if teamData.team_base_info then
        self.m_countryText.text = string_format(Language.GetString(3766), self.m_sCountryNameList[teamData.team_base_info.country],
            teamData.team_base_info.copy_id % 100, teamData.team_base_info.min_level,teamData.team_base_info.max_level)
    end
end

function LieZhuanTeamItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_addBtn.gameObject)
    base.OnDestroy(self)
end

return LieZhuanTeamItem