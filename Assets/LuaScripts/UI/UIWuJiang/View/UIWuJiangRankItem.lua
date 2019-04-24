local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local Language = Language
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()  

local UIWuJiangCardItem = require "UI.UIWuJiang.View.UIWuJiangCardItem"
local CardItemPath = TheGameIds.CommonWujiangCardPrefab
local wujiangMgr = Player:GetInstance():GetWujiangMgr()

local UIWuJiangRankItem = BaseClass("UIWuJiangRankItem", UIBaseItem)
local base = UIBaseItem      

function UIWuJiangRankItem:__delete()
    
end

function UIWuJiangRankItem:OnCreate()
    base.OnCreate(self)
    self.m_rankIconItem = nil
    self.m_itemLoaderSeq = 0
    
    self:InitView()
end

function UIWuJiangRankItem:InitView()
    self.m_rankNumTxt,
    self.m_rankNum0Txt,
    self.m_userNameTxt,
    self.m_guildNameTxt,
    self.m_victoryDotTxt,
    self.m_checkLineupBtnTxt = UIUtil.GetChildTexts(self.transform, {
        "RankNumTxt",
        "RankNum0Txt",
        "UserNameTxt",
        "GuildNameTxt",
        "VictoryDotsTxt",
        "CheckLineupBtn/Txt",
    }) 
    
    self.m_rankBgImgTr,
    self.m_rankNumImgTr,
    self.m_userIconPosTr,
    self.m_checkLineupBtnTr = UIUtil.GetChildTransforms(self.transform, {
        "RankBgImg",
        "RankNumImg",
        "UserIconPos",
        "CheckLineupBtn",
    })

    self.m_bgImg = UIUtil.AddComponent(UIImage, self,  "BgImg", AtlasConfig.DynamicLoad)
    self.m_circleBgSpt = UIUtil.AddComponent(UIImage, self,  "BgImg/CircleBg", AtlasConfig.DynamicLoad)
    self.m_rankBgImg = UIUtil.AddComponent(UIImage, self, "RankBgImg", AtlasConfig.DynamicLoad)
    self.m_rankNumImg = UIUtil.AddComponent(UIImage, self, "RankNumImg", AtlasConfig.DynamicLoad)

    self.m_checkLineupBtnTxt.text = Language.GetString(2221)

    local onClick = UILogicUtil.BindClick(self, self.OnClick) 
    UIUtil.AddClickEvent(self.m_checkLineupBtnTr.gameObject, onClick)
end

function UIWuJiangRankItem:UpdateData(rank_type, one_rank_info, is_self, wujiangIndex)
    self.m_isSelfRank = is_self 
    self.m_rankType = rank_type 
    self.m_wujiangIndex = wujiangIndex
    if not one_rank_info then
        return
    end 
    if is_self then
        self.m_checkLineupBtnTr.gameObject:SetActive(false) 
    end

    local tempUserBrief = one_rank_info.userBrief
    self.m_userNameTxt.text = tempUserBrief.name
    self.m_guildNameTxt.text = UILogicUtil.GetCorrectGuildName(tempUserBrief.guild_name)

    self.m_rankNum = one_rank_info.rank or 0
    self:UpdateRankNum(one_rank_info.rank)
    local isYou = Player:GetInstance():GetUserMgr():CheckIsSelf(tempUserBrief.uid)
    self:UpdateBgImg(isYou)
    
    self:UpdateWuJiangIcon(one_rank_info)

    self.m_victoryDotTxt.text = math.ceil(one_rank_info.param1)    --胜点积分 
end 

function UIWuJiangRankItem:UpdateRankNum(rank_num)
    local num = rank_num or 0 
    if self.m_isSelfRank then
        self.m_rankBgImgTr.gameObject:SetActive(true)
        self.m_rankBgImg:SetAtlasSprite("ph09.png", true)
    else
        self.m_rankBgImgTr.gameObject:SetActive(false)
    end

    if num <= 0 then
        self.m_rankNumImgTr.gameObject:SetActive(false)
        self.m_rankNumTxt.text = ""
        self.m_rankNum0Txt.text = Language.GetString(2108)
    elseif num <= 3 then
        self.m_rankNumImgTr.gameObject:SetActive(true)
        self.m_rankNumTxt.text = ""
        self.m_rankNum0Txt.text = ""
        UILogicUtil.SetNumSpt(self.m_rankNumImg, num, true)
    else
        self.m_rankNumImgTr.gameObject:SetActive(false)
        self.m_rankNumTxt.text = math.floor(num)
        self.m_rankNum0Txt.text = ""
    end
end
 
function UIWuJiangRankItem:UpdateBgImg(isYou)
    local isCurPlayer = isYou or false
    if self.m_isSelfRank then
        self.m_bgImg.gameObject:SetActive(false)
    else
        self.m_bgImg.gameObject:SetActive(true)
        if isCurPlayer then
            self.m_bgImg:SetAtlasSprite("ph02.png", false)
            self.m_circleBgSpt:SetAtlasSprite("ph06.png", false)
        else
            self.m_bgImg:SetAtlasSprite("ph01.png", false)
            self.m_circleBgSpt:SetAtlasSprite("ph07.png", false)
        end
    end
end

function UIWuJiangRankItem:UpdateWuJiangIcon(one_rank_info)  
    local selfCallBack = nil
    if not self.m_isSelfRank then
        selfCallBack = function()
            Player:GetInstance():GetCommonRankMgr():ReqWuJiangRankDetail(self.m_rankNum, self.m_rankType) 
        end
    end 
    local wujiangBriefData = nil
    if self.m_isSelfRank then
        wujiangBriefData = wujiangMgr:GetWuJiangData(self.m_wujiangIndex) 
    else
        wujiangBriefData = {
            id = one_rank_info.param2,
            level = one_rank_info.param3,
            star = one_rank_info.param4,
            index = 0,
            tupo = 0,
        } 
    end

    if self.m_rankIconItem then
        self.m_rankIconItem:SetData(wujiangBriefData,true, true, selfCallBack)
    else
        self.m_itemLoaderSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObject(self.m_itemLoaderSeq, CardItemPath, function(obj)
            self.m_itemLoaderSeq = 0
            if not obj then
                return
            end
            local rankIconItem = UIWuJiangCardItem.New(obj, self.m_userIconPosTr, CardItemPath)
            local scale = 0.68
            rankIconItem:SetLocalScale(Vector3.New(scale, scale, scale))
            rankIconItem:SetAnchoredPosition(Vector3.New(42, -58, 0))
            rankIconItem:HideName()
            rankIconItem:SetData(wujiangBriefData, true, true, selfCallBack, false, scale)
            self.m_rankIconItem = rankIconItem
        end)
    end
end

function UIWuJiangRankItem:OnClick(go, x, y)
    if go.name == "CheckLineupBtn" then 
        Player:GetInstance():GetCommonRankMgr():ReqRankBuzhen(self.m_rankType, self.m_rankNum)     
    end
end

function UIWuJiangRankItem:OnDestroy()
    UIGameObjectLoaderInst:CancelLoad(self.m_itemLoaderSeq)
    self.m_itemLoaderSeq = 0
    if self.m_rankIconItem then
        self.m_rankIconItem:Delete()
        self.m_rankIconItem = nil
    end

    self.m_checkLineupBtnTr.gameObject:SetActive(true)
    UIUtil.RemoveClickEvent(self.m_checkLineupBtnTr.gameObject)

    base.OnDestroy(self)
end

return UIWuJiangRankItem