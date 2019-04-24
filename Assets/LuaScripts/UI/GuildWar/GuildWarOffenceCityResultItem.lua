local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local UserItemPrefab = TheGameIds.UserItemPrefab
local UserItemClass = require("UI.UIUser.UserItem")
local GuildWarUserTitleBriefItem = require("UI.GuildWar.GuildWarUserTitleBriefItem")
local GameObject = CS.UnityEngine.GameObject
local Vector3 = Vector3

local table_insert = table.insert
local math_ceil = math.ceil
local math_floor = math.floor
local base = UIBaseItem
local GuildWarOffenceCityResultItem = BaseClass("GuildWarOffenceCityResultItem", UIBaseItem)

function GuildWarOffenceCityResultItem:OnCreate()
    base.OnCreate(self)

    self:InitView()

    self.m_userItem = nil
    self.m_userItemSeq = 0
    self.m_breakItemList = {}
end

function GuildWarOffenceCityResultItem:OnDestroy()
    if self.m_bgSpt then
        self.m_bgSpt:Delete()
        self.m_bgSpt = nil
    end
    if self.m_rankNumSpt then
        self.m_rankNumSpt:Delete()
        self.m_rankNumSpt = nil
    end

    if self.m_userItemSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_userItemSeq)
        self.m_userItemSeq = 0
    end
    if self.m_userItem then
        self.m_userItem:Delete()
        self.m_userItem = nil
    end

    for i, v in ipairs(self.m_breakItemList) do
        v:Delete()
    end
    self.m_breakItemList = nil
    
    base.OnDestroy(self)
end

function GuildWarOffenceCityResultItem:InitView()
    self.m_bgSpt = UIUtil.AddComponent(UIImage, self, "bgSpt", AtlasConfig.DynamicLoad)
    self.m_circleBgSpt = UIUtil.AddComponent(UIImage, self, "bgSpt/CircleBg", AtlasConfig.DynamicLoad)
    self.m_rankNumSpt = UIUtil.AddComponent(UIImage, self, "rankNumSpt", AtlasConfig.DynamicLoad)

    self.m_breakItemParent, self.m_rankNumSptTrans = UIUtil.GetChildTransforms(self.transform, {
        "breakItemList",
        "rankNumSpt"
    }) 

    self.m_playerNameText, self.m_jungongText, self.m_rankNumText, self.m_rankNum0Text =
    UIUtil.GetChildTexts(self.transform, {
        "playerNameText",
        "jungongText",
        "rankNumText",
        "rankNum0Text",
    })
end

function GuildWarOffenceCityResultItem:UpdateData(resultData, breakItemPrefab)
    if not resultData then
        return
    end

    local user_brief = resultData.user_brief
    if user_brief then
        self.m_playerNameText.text = user_brief.name
        self:UpdateUserIcon(user_brief)
        self:UpdateBgSpt(self:IsCurrPlayer(user_brief))
    end

    self.m_rank_num = resultData.rank or 0
    self:UpdateRankNum()
    self:UpdateBreakList(resultData.break_info_list, breakItemPrefab)

    self.m_jungongText.text = math_ceil(resultData.award_jungong)
end

function GuildWarOffenceCityResultItem:UpdateUserIcon(userBrief)
-- 更新玩家头像信息
    if self.m_userItem then
        if userBrief.use_icon then
            self.m_userItem:UpdateData(userBrief.use_icon.icon, userBrief.use_icon.icon_box, userBrief.level)
        end
    else
        self.m_userItemSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObject(self.m_userItemSeq, UserItemPrefab, function(obj)
            self.m_userItemSeq = 0
            if not obj then
                return
            end
            local userItem = UserItemClass.New(obj, self.m_userIconPosTrans, UserItemPrefab)
            if userItem then
                userItem:SetLocalScale(Vector3.New(0.8, 0.8, 0.8))
                if userBrief.use_icon then
                    userItem:UpdateData(userBrief.use_icon.icon, userBrief.use_icon.icon_box, userBrief.level)
                end
                self.m_userItem = userItem
            end
        end)
    end
end

function GuildWarOffenceCityResultItem:UpdateBgSpt(isCurrPlayer)
    if isCurrPlayer then
        self.m_bgSpt:SetAtlasSprite("ph02.png", false)
        self.m_circleBgSpt:SetAtlasSprite("ph06.png", false)
    else
        self.m_bgSpt:SetAtlasSprite("ph01.png", false)
        self.m_circleBgSpt:SetAtlasSprite("ph07.png", false)
    end
end

function GuildWarOffenceCityResultItem:UpdateRankNum()
    if self.m_rank_num <= 0 then
        self.m_rankNumSptTrans.gameObject:SetActive(false)
        self.m_rankNumText.gameObject:SetActive(false)
        self.m_rankNum0Text.gameObject:SetActive(true)
        self.m_rankNum0Text.text = Language.GetString(2108)
    elseif self.m_rank_num <= 3 then
        --前三名
        self.m_rankNumSptTrans.gameObject:SetActive(true)
        self.m_rankNumText.gameObject:SetActive(false)
        self.m_rankNum0Text.gameObject:SetActive(false)
        UILogicUtil.SetNumSpt(self.m_rankNumSpt, self.m_rank_num, true)
    else
        self.m_rankNumSptTrans.gameObject:SetActive(false)
        self.m_rankNum0Text.gameObject:SetActive(false)
        self.m_rankNumText.gameObject:SetActive(true)
        self.m_rankNumText.text = math_floor(self.m_rank_num)
    end
end

function GuildWarOffenceCityResultItem:IsCurrPlayer(userBrief)
    if Player:GetInstance():GetUserMgr():CheckIsSelf(userBrief.uid) then
        return true
    end
    return false
end

function GuildWarOffenceCityResultItem:UpdateBreakList(break_info_list, breakItemPrefab)
    if break_info_list and breakItemPrefab then
        for i = 1, #break_info_list do
            local breakItem = self.m_breakItemList[i]
            if not breakItem then
                local go = GameObject.Instantiate(breakItemPrefab)
                breakItem = GuildWarUserTitleBriefItem.New(go, self.m_breakItemParent)
                breakItem:SetLocalPosition(Vector3.New((i - 1) * 130, 0, 0))
                table_insert(self.m_breakItemList, breakItem)
            end

            breakItem:SetActive(true)
            breakItem:UpdateData(break_info_list[i].user_title, break_info_list[i].break_count)
        end
        
        for i = #break_info_list + 1, #self.m_breakItemList do
            self.m_breakItemList[i]:SetActive(false)
        end
    end
end

return GuildWarOffenceCityResultItem
