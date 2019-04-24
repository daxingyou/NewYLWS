local UIUtil = UIUtil
local UIImage = UIImage
local Vector3 = Vector3
local Language = Language
local UIEffect = UIEffect
local ConfigUtil = ConfigUtil
local AtlasConfig = AtlasConfig
local UILogicUtil = UILogicUtil
local string_format = string.format
local math_ceil = math.ceil
local UserItemPrefab = TheGameIds.UserItemPrefab
local UIManagerInstance = UIManagerInst
local ArenaMgr = Player:GetInstance():GetArenaMgr()
local UserMgr = Player:GetInstance():GetUserMgr()
local UserItemClass = require("UI.UIUser.UserItem")
local ArenaDuanWeiJinJieEffectPath = TheGameIds.ArenaDuanWeiJinJie
local ArenaDuanWeiJinJieEffectPathBg = TheGameIds.ArenaDuanWeiJinJieBg
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local Type_Image = typeof(CS.UnityEngine.UI.Image)
local UISortOrderMgrInst = UISortOrderMgr:GetInstance()

local ArenaRivalItem = BaseClass("ArenaRivalItem", UIBaseItem)
local base = UIBaseItem

function ArenaRivalItem:OnCreate()
    base.OnCreate(self)

    self:InitView()

    self:HandleClick()
end

function ArenaRivalItem:InitView()
    --初始化组件
    self.m_lineSptTrans,
    
    self.m_normalChallengeTrans, 
    self.m_wujiangPosTrans, 
    self.m_rankSptTrans, 
    self.m_normalChallengeBtnTrans,

    self.m_upStageChallangeTrans, 
    self.m_nextStageRankSptTrans, 
    self.m_currStageRankSptTrans, 
    self.m_upStageChallengeBtnTrans,
    self.m_rankRoot
    = 
    UIUtil.GetChildRectTrans(self.transform, {
        "lineSpt",

        "normalChallenge",
        "normalChallenge/wujiangPos",
        "normalChallenge/rankRoot/rankSpt",
        "normalChallenge/normalChallengeBtn",
        
        "upStageChallange",
        "upStageChallange/nextStageRankBg/nextStageRankSpt",
        "upStageChallange/currStageRankBg/currStageRankSpt",
        "upStageChallange/upStageChallengeBtn",
        "normalChallenge/rankRoot",
    })

    --初始化文本组件
    self.m_rankNumText, 
    self.m_nameText, 
    self.m_guildText, 
    self.m_powerText, 
    self.m_normalChallengeBtnText,
    
    self.m_upStageText, 
    self.m_upStageChallengeBtnText
    = UIUtil.GetChildTexts(self.transform, {
        "normalChallenge/rankRoot/rankNumText",
        "normalChallenge/nameText",
        "normalChallenge/guildText",
        "normalChallenge/PowerBg/powerText",
        "normalChallenge/normalChallengeBtn/normalChallengeBtnText",

        "upStageChallange/upStageText",
        "upStageChallange/upStageChallengeBtn/upStageChallengeBtnText",
    })

    self.m_normalChallengeBtnText.text = Language.GetString(2213)
    self.m_upStageChallengeBtnText.text = Language.GetString(2213)

    self.m_rankSpt = UIUtil.AddComponent(UIImage, self, "normalChallenge/rankRoot/rankSpt", AtlasConfig.DynamicLoad)
    self.m_nextStageRankSpt = UIUtil.AddComponent(UIImage, self, "upStageChallange/nextStageRankBg/nextStageRankSpt", AtlasConfig.DynamicLoad)
    self.m_currStageRankSpt = UIUtil.AddComponent(UIImage, self, "upStageChallange/currStageRankBg/currStageRankSpt", AtlasConfig.DynamicLoad)

    self.m_rankRoot = self.m_rankRoot.gameObject
    self.m_isShowLineSpt = true
    self.m_isNoramlChallenge = false        --是否普通挑战
    self.m_rivalInfo = nil      --对手的数据
    self.m_battleType = nil

    self.m_userItem = nil
    self.m_userItemSeq = 0

    local normalChallengeBtnImage = self.m_upStageChallengeBtnTrans:GetComponent(Type_Image)
    local upStageChallengeBtnImage = self.m_upStageChallengeBtnTrans:GetComponent(Type_Image)
    local upStageChallengeBtnTextMaterial = self.m_upStageChallengeBtnText.material
    local normalSortOrder = normalChallengeBtnImage.material.renderQueue
    self.m_upStageBtnRenderQueue = normalSortOrder + 10
    upStageChallengeBtnImage.material.renderQueue = self.m_upStageBtnRenderQueue
    upStageChallengeBtnTextMaterial.renderQueue = self.m_upStageBtnRenderQueue

    self.m_effectItem = nil
    self.m_effectItem1 = nil
    
    local layerName = UILogicUtil.FindLayerName(self.transform)
    self.m_layerSortOrder = UISortOrderMgrInst:GetCurrLayerSortOrder(layerName)

    coroutine.start(self.DelayAdaption, self)
end

function ArenaRivalItem:DelayAdaption()
    coroutine.waitforseconds(0.1)
    self.m_rankRoot:SetActive(false)
    self.m_rankRoot:SetActive(true)
end

function ArenaRivalItem:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.m_normalChallengeBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_upStageChallengeBtnTrans.gameObject, onClick)
end

function ArenaRivalItem:OnClick(go, x, y)
    if not go then
        return
    end
    local goName = go.name
    if goName == "normalChallengeBtn" or goName == "upStageChallengeBtn" then
        if self:CheckArenaFightEnough() then
            if self.m_rivalInfo then
                ArenaMgr:SetTmpRivalUID(self.m_rivalInfo.uid)
                UIManagerInstance:OpenWindow(UIWindowNames.UILineupMain, self.m_battleType)
            end
        else
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
                isShowCancelBtn = true
            }        
            UIManagerInst:OpenWindow(UIWindowNames.UIBuyTipsDialog, data)
        end
    end
end

function ArenaRivalItem:CheckArenaFightEnough()
    local arenaFightCount = Player:GetInstance():GetItemMgr():GetItemCountByID(ItemDefine.ArenaFight_ID)
    return arenaFightCount > 0
end

function ArenaRivalItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_normalChallengeBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_upStageChallengeBtnTrans.gameObject)

    self.m_lineSptTrans = nil

    self.m_normalChallengeTrans = nil
    self.m_wujiangPosTrans = nil
    self.m_rankSptTrans = nil
    self.m_normalChallengeBtnTrans = nil
    
    self.m_upStageChallangeTrans = nil
    self.m_nextStageRankSptTrans = nil
    self.m_currStageRankSptTrans = nil
    self.m_upStageChallengeBtnTrans = nil

    if self.m_rankSpt then
        self.m_rankSpt:Delete()
        self.m_rankSpt = nil
    end
    if self.m_nextStageRankSpt then
        self.m_nextStageRankSpt:Delete()
        self.m_nextStageRankSpt = nil
    end
    if self.m_currStageRankSpt then
        self.m_currStageRankSpt:Delete()
        self.m_currStageRankSpt = nil
    end
    self.m_rivalInfo = nil
    self.m_battleType = nil

    if self.m_userItemSeq ~= 0 then
        UIGameObjectLoaderInst:CancelLoad(self.m_userItemSeq)
    end
    if self.m_userItem then
        self.m_userItem:Delete()
        self.m_userItem = nil
    end
    if self.m_effectItem then
        self.m_effectItem:Delete()
        self.m_effectItem = nil
    end
    if self.m_effectItem1 then
        self.m_effectItem1:Delete()
        self.m_effectItem1 = nil
    end

    base.OnDestroy(self)
end

function ArenaRivalItem:UpdateData(rivalInfo, battleType)
    if not rivalInfo then
        return
    end
    self.m_rivalInfo = rivalInfo
    self.m_battleType = battleType

    self:SetChallengeType(not rivalInfo.is_advance)

    self:SetLineSptShowState(true)
end

function ArenaRivalItem:SetChallengeType(isNormalChallenge)
    self.m_isNoramlChallenge = isNormalChallenge

    self.m_normalChallengeTrans.gameObject:SetActive(isNormalChallenge)
    self.m_upStageChallangeTrans.gameObject:SetActive(not isNormalChallenge)

    if isNormalChallenge then
        self:UpdateNormalChallenge()
    else
        self:UpdateUpStageChellenge()
    end
end

function ArenaRivalItem:UpdateNormalChallenge()
    if not self.m_rivalInfo then
        return
    end
    
    --更新玩家信息
    self.m_nameText.text = self.m_rivalInfo.user_name
    self.m_powerText.text = math_ceil(self.m_rivalInfo.power)
    self.m_rankNumText.text = string_format(Language.GetString(2212), self.m_rivalInfo.rank)
    local guildName = UILogicUtil.GetCorrectGuildName(self.m_rivalInfo.guild_name)
    self.m_guildText.text = guildName

    --更新排名组的图标
    local arenaDanAwardCfg = self.m_rivalInfo:GetArenaDanAwardCfg()
    if arenaDanAwardCfg then
        self.m_rankSpt:SetAtlasSprite(arenaDanAwardCfg.sIcon, false, AtlasConfig[arenaDanAwardCfg.sAtlas])
    end

    --更新玩家头像信息
    if self.m_userItem then
        if self.m_rivalInfo.use_icon then
            self.m_userItem:UpdateData(self.m_rivalInfo.use_icon.icon, self.m_rivalInfo.use_icon.icon_box, self.m_rivalInfo.level)
        end
    else
        self.m_userItemSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObject(self.m_userItemSeq, UserItemPrefab, function(obj)
            if not obj then
                return
            end
            local userItem = UserItemClass.New(obj, self.m_wujiangPosTrans, UserItemPrefab)
            if userItem then
                userItem:SetLocalScale(Vector3.one)
                if self.m_rivalInfo.use_icon then
                    userItem:UpdateData(self.m_rivalInfo.use_icon.icon, self.m_rivalInfo.use_icon.icon_box, self.m_rivalInfo.level)
                end
                self.m_userItem = userItem
            end
        end)
    end
end

function ArenaRivalItem:UpdateUpStageChellenge()
    if not self.m_rivalInfo then
        return
    end
    
    local curr_rank_dan = ArenaMgr:GetRankDan()
    local currRankDanAwardCfg = ConfigUtil.GetArenaDanAwardCfgByID(curr_rank_dan)
    local nextRankDanAwardCfg = ConfigUtil.GetArenaDanAwardCfgByID(curr_rank_dan - 1)
    if currRankDanAwardCfg then
        self.m_currStageRankSpt:SetAtlasSprite(currRankDanAwardCfg.sIcon, false, AtlasConfig[currRankDanAwardCfg.sAtlas])
        self.m_upStageText.text = string_format(Language.GetString(2228), currRankDanAwardCfg.dan_name)
    end
    if nextRankDanAwardCfg then
        self.m_nextStageRankSpt:SetAtlasSprite(nextRankDanAwardCfg.sIcon, false, AtlasConfig[nextRankDanAwardCfg.sAtlas])
    end

    self:CreateJinjieEffect()
end

function ArenaRivalItem:SetLineSptShowState(isShowLineSpt)
    self.m_isShowLineSpt = isShowLineSpt
    
    self.m_lineSptTrans.gameObject:SetActive(isShowLineSpt)
end

function ArenaRivalItem:CreateJinjieEffect()
    local renderQueue = self.m_upStageBtnRenderQueue - 5
    if not self.m_effectItem then
       
        UIUtil.AddComponent(UIEffect, self, "", self.m_layerSortOrder, ArenaDuanWeiJinJieEffectPath, function(effect)
            self.m_effectItem = effect
            self.m_effectItem:SetRenderQueue(renderQueue)
            self.m_effectItem:SetLocalScale(Vector3.one)
            self.m_effectItem:SetLocalPosition(Vector3.New(0, -85, 0))
        end)
    else
        self.m_effectItem:SetRenderQueue(renderQueue)
        self.m_effectItem:SetLocalScale(Vector3.one)
        self.m_effectItem:SetLocalPosition(Vector3.New(0, -85, 0))
    end
    if not self.m_effectItem1 then
        UIUtil.AddComponent(UIEffect, self, "", self.m_layerSortOrder, ArenaDuanWeiJinJieEffectPathBg, function(effect)
            self.m_effectItem1 = effect
            self.m_effectItem1:SetRenderQueue(renderQueue)
            self.m_effectItem1:SetLocalScale(Vector3.one)
            self.m_effectItem1:SetLocalPosition(Vector3.New(0, -125, 0))
        end)
    else
        self.m_effectItem1:SetRenderQueue(renderQueue)
        self.m_effectItem1:SetLocalScale(Vector3.one)
        self.m_effectItem1:SetLocalPosition(Vector3.New(0, -125, 0))
    end
end

return ArenaRivalItem