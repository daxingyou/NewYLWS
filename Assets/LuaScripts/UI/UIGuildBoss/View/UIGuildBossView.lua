local GameObject = CS.UnityEngine.GameObject
local RectTransform = CS.UnityEngine.RectTransform
local GameUtility = CS.GameUtility
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local Quaternion = Quaternion
local ConfigUtil = ConfigUtil
local UILogicUtil = UILogicUtil
local AtlasConfig = AtlasConfig
local string_format = string.format
local userMgr = Player:GetInstance():GetUserMgr()

local tonumber = tonumber
local math_ceil = math.ceil
local table_insert = table.insert
local table_remove = table.remove
local table_choose = table.choose
local BattleEnum = BattleEnum
local string_sub = string.sub
local Vector3 = Vector3
local Vector2 = Vector2
local MotionBlurEffect = CS.MotionBlurEffect
local SkillUtil = SkillUtil
local UISliderHelper = typeof(CS.UISliderHelper)
local UIBagItem = require "UI.UIBag.View.BagItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local UIGuildBossRankItem = require "UI.UIGuildBoss.View.UIGuildBossRankItem"

local UIGuildBossView = BaseClass("UIGuildBossView", UIBaseView)
local base = UIBaseView

local Tab_Player_Rank = 1
local Tab_Guild_Rank = 2

local guildBossMgr = Player:GetInstance():GetGuildBossMgr()


function UIGuildBossView:OnCreate()
    base.OnCreate(self)
  
    self:InitView()

    self.m_currTab = Tab_Player_Rank
    self.m_specialAwardList = {}
    self.m_rankSeq = 0
    self.m_bossIndex = 0
    self.m_playerRankItemList = {}
    self.m_guildRankItemList = {}
    self.m_rankItemList = {}
end

function UIGuildBossView:InitView()
    self.m_backBtnTrans, self.m_startBtnTrans, self.m_enhanceBtnTrans, self.m_hurtRankBtnTrans, self.m_guildRankBtnTrans
    ,self.m_nextBossTrans, self.m_specialAwardItemTrans, self.m_rankItemTrans, self.m_myRankItemTrans, self.m_resetBtnTrans,
    self.m_bottomTipTrans, self.m_rightBottomTrans, self.m_yuanbaoTr,
    self.m_ruleBtnTr, self.m_rightContainerTr = UIUtil.GetChildTransforms(self.transform, {
        "Panel/backBtn",
        "middleContainer/BottomContainer/start_BTN",
        "middleContainer/BottomContainer/upAtk_BTN",
        "leftContainer/HurtRank",
        "leftContainer/GuildRank",
        "rightContainer/TopImage/bossBg",
        "rightContainer/MiddleImage/ItemScrollView/Viewport/ItemContent",
        "leftContainer/ItemScrollView/Viewport/ItemContent",
        "leftContainer/bottomBg/ItemScrollView/Viewport/ItemContent",
        "middleContainer/resetButton",
        "bottomContainer",
        "middleContainer/BottomContainer",
        "middleContainer/BottomContainer/yuanbaoImage",
        "bottomContainer/ruleBtn",
        "rightContainer",
    })

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_startBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_enhanceBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_hurtRankBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_guildRankBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_resetBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_ruleBtnTr.gameObject, onClick)

    self.m_starBtnText, self.m_enhanceBtnText, self.m_hurtRankBtnText, self.m_guildRankBtnText, self.m_bossNameText,
    self.m_leftBossText, self.m_killAllText, self.m_nextBossText, self.m_leftChllangeText, self.m_tipsText, self.m_yuanbaoText,
    self.m_resetBtnText, self.m_resetYBText, self.m_bloodPercentText, self.m_bossLevelText, self.m_resetLimitText, self.m_resetLimitCountText = 
    UIUtil.GetChildTexts(self.transform, {
        "middleContainer/BottomContainer/start_BTN/Text",
        "middleContainer/BottomContainer/upAtk_BTN/Text",
        "leftContainer/HurtRank/Text",
        "leftContainer/GuildRank/Text",
        "bottomContainer/bossBlood/bossName",
        "rightContainer/TopImage/leftBossText",
        "middleContainer/killAllText",
        "rightContainer/TopImage/bossBg/bossText",
        "middleContainer/BottomContainer/leftChallangeText",
        "bottomContainer/Tips",
        "middleContainer/BottomContainer/yuanbaoImage/countText",
        "middleContainer/resetButton/btnText",
        "middleContainer/resetButton/ybText",
        "bottomContainer/bossBlood/bloodSlider/bloodPercent",
        "bottomContainer/bossBlood/bossLevel",
        "middleContainer/resetLimitText",
        "middleContainer/resetLimitText/resetLimitCountText",
    })

    local nextBossText, awardText = 
    UIUtil.GetChildTexts(self.transform, {
        'rightContainer/TopImage/topText','rightContainer/MiddleImage/topText'
    })
    nextBossText.text = Language.GetString(2450)
    awardText.text = Language.GetString(2452)

    self.m_startButton = UIUtil.FindComponent(self.m_startBtnTrans, typeof(CS.UnityEngine.UI.Button))
    self.m_enhanceButton = UIUtil.FindComponent(self.m_enhanceBtnTrans, typeof(CS.UnityEngine.UI.Button))
    self.m_bloodSlider = UIUtil.FindComponent(self.transform, UISliderHelper, "bottomContainer/bossBlood/bloodSlider")

    self.m_hurtRankImage = UIUtil.AddComponent(UIImage, self, "leftContainer/HurtRank", AtlasConfig.DynamicLoad)
    self.m_guildRankImage = UIUtil.AddComponent(UIImage, self, "leftContainer/GuildRank", AtlasConfig.DynamicLoad)

    self.m_firstLoadOwnRank = true
    self.m_atkBuffReqValid = true
    self.m_atkBossReqValid = true
    self.m_userRankListInfo = {}
    self.m_guildRankListInfo = {}
    self.m_myRankItem = nil

    self.m_scrollView = self:AddComponent(LoopScrowView, "leftContainer/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateDataTaskItem))
end


function UIGuildBossView:OnEnable(...)
    base.OnEnable(self, ...)

    local _, go = ...
    self.m_preloadGo = go

    if not self.m_preloadGo then
        GameObjectPoolInst:GetGameObjectAsync(TheGameIds.GuildBossBgPath, function(go)
            if go then
                self.m_preloadGo = go
                self:LoadRoleBg()
            end
        end)
    else
        self.m_preloadGo.transform.localRotation = Quaternion.Euler(0, 0, 0)
        self.m_preloadGo.transform.localPosition = Vector3.New(0, 0, -3)
    end
    
    guildBossMgr:ReqGuildBossInfo()
end

function UIGuildBossView:RspGuildBossInfo()

    
    self.m_msgObj = guildBossMgr:GetEnterBattleMsg()
    if not self.m_msgObj then
    end

    if self.m_msgObj.atk_buff_valid == 0 then
        self.m_atkBuffReqValid = true
        self.m_enhanceButton.interactable = true
        GameUtility.SetUIGray(self.m_enhanceBtnTrans.gameObject, false)
        self.m_yuanbaoTr.gameObject:SetActive(true)
        self.m_enhanceBtnText.text = Language.GetString(2429)
    else
        self.m_atkBuffReqValid = false
        self.m_enhanceButton.interactable = false
        GameUtility.SetUIGray(self.m_enhanceBtnTrans.gameObject, true)
        self.m_yuanbaoTr.gameObject:SetActive(false)
        self.m_enhanceBtnText.text = Language.GetString(2426)
    end
    
    self:CreateBoss(self.m_msgObj)

    self.m_starBtnText.text = Language.GetString(2414)
    self.m_yuanbaoText.text = Language.GetString(2437)
    self.m_resetBtnText.text = Language.GetString(2448)
    self.m_resetYBText.text = Language.GetString(2449) -- todo
    
    if self.m_msgObj.remain_times <= 0 then
        self.m_leftChllangeText.text = Language.GetString(2456)
    else
        self.m_leftChllangeText.text = string_format(Language.GetString(2432), self.m_msgObj.remain_times)
    end

    self:ReqGuildBossRank()

    self.m_specialSeq = 0
end

function UIGuildBossView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_backBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_startBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_enhanceBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_hurtRankBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_guildRankBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_resetBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_ruleBtnTr.gameObject)
end

function UIGuildBossView:OnDestroy()
    self:RemoveClick()
    if not IsNull(self.m_preloadGo) then
        GameObjectPoolInst:RecycleGameObject(TheGameIds.GuildBossBgPath, self.m_preloadGo)
    end

    self.m_preloadGo = nil

    base.OnDestroy(self)
end

function UIGuildBossView:OnDisable()
    self:RecycleObj()
    self:UnLoadRoleBg()
    self:DestroyRoleContainer()

    self:ReleaseRankItem()

    if self.m_specialAwardList and #self.m_specialAwardList > 0 then
        for k,v in pairs(self.m_specialAwardList) do
            v:Delete()
        end
        self.m_specialAwardList = {}
    end

    if not IsNull(self.m_preloadGo) then
        GameObjectPoolInst:RecycleGameObject(TheGameIds.GuildBossBgPath, self.m_preloadGo)
    end

    self.m_preloadGo = nil

    if self.m_myRankItem then
        self.m_myRankItem:Delete()
        self.m_myRankItem = nil
    end

    base.OnDisable(self)
end

function UIGuildBossView:ReleaseRankItem()
    if self.m_rankItemList and #self.m_rankItemList > 0 then
        for k,v in pairs(self.m_rankItemList) do
            v:Delete()
        end
        self.m_rankItemList = {}
    end
end


function UIGuildBossView:CreateRoleContainer()
    if IsNull(self.m_roleContainerGo) then
        self.m_roleContainerGo = GameObject("RoleContainer")
        self.mRoleContainerTrans = self.m_roleContainerGo.transform
    end
end

function UIGuildBossView:DestroyRoleContainer()
    if not IsNull(self.m_roleContainerGo) then
        GameObject.DestroyImmediate(self.m_roleContainerGo)
    end

    self.m_roleContainerGo = nil
    self.mRoleContainerTrans = nil
end

function UIGuildBossView:CreateBoss()
    self:CreateRoleContainer()
    
    if self.m_msgObj.remain_times <= 0 or self.m_msgObj.can_atk_boss ~= 1 then
        self.m_startButton.interactable = false
        GameUtility.SetUIGray(self.m_startBtnTrans.gameObject, true)
        self.m_atkBossReqValid = false
        self.m_enhanceButton.interactable = false
        GameUtility.SetUIGray(self.m_enhanceBtnTrans.gameObject, true)
        self.m_atkBuffReqValid = false
    else
        self.m_atkBossReqValid = true
        self.m_startButton.interactable = true
        GameUtility.SetUIGray(self.m_startBtnTrans.gameObject, false)
    end

    local bossID = 0
    local weaponLevel = 4 -- todo

    local bossList = self.m_msgObj.boss_list
    local bossCount = #bossList
    local leftBossCount = 0
    local curBossCount = 0
    for i=1,bossCount do
        local bossInfo = bossList[i]
        if bossInfo.status == 0 then -- 未激活
            leftBossCount = leftBossCount + 1

        elseif bossInfo.status == 1 then -- 激活
            local bossCfg = ConfigUtil.GetGuildBossCfgByID(bossInfo.cfg_id)
            if not bossCfg then
                Logger.LogError(' no guild boss cfg ', bossInfo.cfg_id)
                return
            end
            bossID = bossCfg.boss_id % 10000
            self.m_bossNameText.text = bossCfg.boss_name
            self.m_tipsText.text = bossCfg.description
            self.m_bossIndex = bossInfo.cfg_id

            guildBossMgr:SetBossCfg(bossCfg)

            local specialAwardList = bossCfg.kill_award
            for i=1,#specialAwardList do
                if i == 1 then
                    self:CreateSpecialAward(specialAwardList[i])
                end
            end

            local nextIndex = bossInfo.index + 1
            if nextIndex <= bossCount then
                local bossCfg1 = ConfigUtil.GetGuildBossCfgByID(bossList[i+1].cfg_id)
                if not bossCfg1 then
                    Logger.LogError(' no guild boss cfg ', bossList[i+1].cfg_id)
                    self.m_nextBossText.text = ''
                else
                    self.m_nextBossText.text = bossCfg1.boss_name
                end
            end

            leftBossCount = leftBossCount + 1
            curBossCount = curBossCount + 1
            self.m_bloodSlider:UpdateSliderImmediately(bossInfo.hp_percent / 100)
            self.m_bloodPercentText.text = string_format("%.2f%%", bossInfo.hp_percent)
            self.m_bossLevelText.text = string_format(Language.GetString(2457), bossInfo.boss_level)
        end
    end

    if leftBossCount == 0 then
        self.m_killAllText.text = Language.GetString(2428)
        self.m_resetLimitText.text = Language.GetString(2466)
        self.m_resetLimitCountText.text = string_format(Language.GetString(2467), self.m_msgObj.reset_limit)
        self.m_leftBossText.text = ''
        self.m_nextBossTrans.gameObject:SetActive(false)
        local userData = userMgr:GetUserData()
        if userData.guild_job ~= CommonDefine.GUILD_POST_NORMAL then
            self.m_resetBtnTrans.gameObject:SetActive(true)
        else
            self.m_resetBtnTrans.gameObject:SetActive(false)
        end
    else
        self.m_resetBtnTrans.gameObject:SetActive(false)
        self.m_nextBossTrans.gameObject:SetActive(true)
        self.m_killAllText.text = ''
        self.m_resetLimitText.text = ''
        self.m_resetLimitCountText.text = ''
        self.m_leftBossText.text = string_format(Language.GetString(2427), leftBossCount)
    end

    if curBossCount > 0 then
        self:ResetRoleCamPos()
        self.m_seq = ActorShowLoader:GetInstance():PrepareOneSeq()
        ActorShowLoader:GetInstance():CreateShowOffWuJiang(self.m_seq, ActorShowLoader.MakeParam(bossID, weaponLevel), self.mRoleContainerTrans, function(actorShow)
            self.m_seq = 0
            self.m_actorShow = actorShow
            actorShow:SetPosition(self:GetStandPos(1))
            -- actorShow:SetLocalScale(self:GetWujiangScale(standPos))
            actorShow:PlayAnim(BattleEnum.ANIM_IDLE)
            actorShow:SetEulerAngles(Vector3.New(18, 180, -3.5))
            actorShow:SetActorShadowHeight(self:GetStandPos(1).y + 0.05)
            -- local modelTrans = actorShow:GetWujiangTransform()
            -- if modelTrans then
            --     modelTrans.forward = modelTrans.forward * -1
            --     local roleCfg = ConfigUtil.GetWujiangCfgByID(wujiangID)
            --     if roleCfg then
            --         modelTrans:Rotate(Vector3.down, roleCfg.showRotate)
            --     end
            -- end
        end)

        self.m_rightBottomTrans.gameObject:SetActive(true)
        self.m_bottomTipTrans.gameObject:SetActive(true)
        self.m_rightContainerTr.gameObject:SetActive(true)
    else
        self:RecycleObj()
        self.m_bottomTipTrans.gameObject:SetActive(false)
        self.m_rightBottomTrans.gameObject:SetActive(false)
        self.m_rightContainerTr.gameObject:SetActive(false)
    end

end

function UIGuildBossView:CreateSpecialAward(awardList)
    self.m_specialSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObject(self.m_specialSeq, TheGameIds.CommonBagItemPrefab, 
        function(go)
            if IsNull(go) then
                return
            end

            local specialAwardItem = UIBagItem.New(go, self.m_specialAwardItemTrans, TheGameIds.CommonBagItemPrefab)
            table_insert(self.m_specialAwardList, specialAwardItem)
            
            local itemCfg = ConfigUtil.GetItemCfgByID(awardList[1])
            local itemIconParam = ItemIconParam.New(itemCfg, 1)-- todo num
            itemIconParam.onClickShowDetail = true
            specialAwardItem:UpdateData(itemIconParam) 
        end
    )
end

function UIGuildBossView:HandleRank(msgObj)
    self:HandleMyRank(msgObj)

    if self.m_currTab == Tab_Player_Rank then
        self:CreatePlayerRankItem(msgObj)
        self.m_hurtRankImage:SetAtlasSprite("ty75.png", false, AtlasConfig.DynamicLoad)
        self.m_guildRankImage:SetAtlasSprite("ty74.png", false, AtlasConfig.DynamicLoad)

        self.m_hurtRankBtnText.text = string_format(Language.GetString(2455), Language.GetString(2430))
        self.m_guildRankBtnText.text = Language.GetString(2431)

    elseif self.m_currTab == Tab_Guild_Rank then
        self:CreateGuildRankItem(msgObj)
        self.m_hurtRankImage:SetAtlasSprite("ty74.png", false, AtlasConfig.DynamicLoad)
        self.m_guildRankImage:SetAtlasSprite("ty75.png", false, AtlasConfig.DynamicLoad)

        self.m_hurtRankBtnText.text = Language.GetString(2430)
        self.m_guildRankBtnText.text = string_format(Language.GetString(2455), Language.GetString(2431))
    end
end

function UIGuildBossView:CreatePlayerRankItem(msgObj)
    local rankList = msgObj.player_hurt_rank_list
    for i=1,#rankList do 
        local info = {
            sumHurt = tonumber(rankList[i].sum_hurt),
            level = rankList[i].user_brief.level,
            name = rankList[i].user_brief.name,
            rank = rankList[i].rank, 
            icon = rankList[i].user_brief.use_icon.icon, 
            iconBox = rankList[i].user_brief.use_icon.icon_box,
            isGuildRank = false
        }

        self.m_userRankListInfo[i] = info
    end

    if #self.m_rankItemList <= 0 then
        self.m_rankSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(self.m_rankSeq, TheGameIds.GuildRankItemPrefab, 8, function(objs)
            self.m_rankSeq = 0
            if objs then
                for i = 1, #objs do
                    local rankItem = UIGuildBossRankItem.New(objs[i], self.m_rankItemTrans, TheGameIds.GuildRankItemPrefab)
                    rankItem:SetLocalScale(Vector3.New(0.9, 0.9, 0.9))
                    table_insert(self.m_rankItemList, rankItem)
                    self.m_scrollView:UpdateView(true, self.m_rankItemList, self.m_userRankListInfo)
                end
            end
        end)
    else
        self.m_scrollView:UpdateView(true, self.m_rankItemList, self.m_userRankListInfo)
    end
end

function UIGuildBossView:CreateGuildRankItem(msgObj)
    local rankList = msgObj.guild_hurt_rank_list
    for i=1,#rankList do 
        local info = {
            sumHurt = tonumber(rankList[i].sum_hurt),
            level = rankList[i].guild_brief.level,
            name = rankList[i].guild_brief.name,
            rank = rankList[i].rank, 
            icon = rankList[i].guild_brief.icon, 
            iconBox = nil,
            isGuildRank = true
        }

        self.m_guildRankListInfo[i] = info
    end


    if #self.m_rankItemList <= 0 then
        self.m_rankSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(self.m_rankSeq, TheGameIds.GuildRankItemPrefab, 8, function(objs)
            self.m_rankSeq = 0
            if objs then
                for i = 1, #objs do
                    local rankItem = UIGuildBossRankItem.New(objs[i], self.m_rankItemTrans, TheGameIds.GuildRankItemPrefab)
                    rankItem:SetLocalScale(Vector3.New(0.9, 0.9, 0.9))
                    table_insert(self.m_rankItemList, rankItem)
                    self.m_scrollView:UpdateView(true, self.m_rankItemList, self.m_guildRankListInfo)
                end
            end
        end)
    else
        self.m_scrollView:UpdateView(true, self.m_rankItemList, self.m_guildRankListInfo)
    end
end

function UIGuildBossView:HandleMyRank(msgObj)
    if self.m_myRankItem then
        return
    end

    local ownerRankSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObject(ownerRankSeq, TheGameIds.GuildRankItemPrefab, 
        function(go)
            if IsNull(go) then
                return
            end

            local rankItem = UIGuildBossRankItem.New(go, self.m_myRankItemTrans, TheGameIds.GuildRankItemPrefab)
            rankItem:SetLocalScale(Vector3.New(0.9, 0.9, 0.9))
            self.m_myRankItem = rankItem
            local info = msgObj.own_hurt_info
            local userData = userMgr:GetUserData()
            rankItem:UpdateData(tonumber(info.sum_hurt) ,userData.level, userData.name, info.rank, userData.use_icon_data.icon, userData.use_icon_data.icon_box, false, true)
        end
    )
end

function UIGuildBossView:GetStandPos(standPos)
    if not self.m_standPosList then
        self.m_standPosList = {
            Vector3.New(0.11, -0.82, -1.74),
            Vector3.New(2.5, 0.1, -2.16),
            Vector3.New(-2.5, 0.1, -2.16),
            Vector3.New(1.48, 0.1, -4.5),
            Vector3.New(-1.48, 0.1, -4.5),
        }
    end
    return self.m_standPosList[standPos]
end

function UIGuildBossView:RecycleObj()
    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end
    ActorShowLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0
end

function UIGuildBossView:LoadRoleBg()
    if not IsNull(self.m_preloadGo) then        
        self.m_preloadGo.transform.localRotation = Quaternion.Euler(0, 0, 0)
        self.m_preloadGo.transform.localPosition = Vector3.New(0, 0, -3)

        self.m_roleCamTrans = UIUtil.FindTrans(self.m_preloadGo.transform, "RoleCamera")
        self.m_roleCam = UIUtil.FindComponent(self.m_roleCamTrans, typeof(CS.UnityEngine.Camera))

        self.m_roleCamTrans.localPosition = Vector3.New(0.01, 0.24, -5.34)
        self.m_roleCam.fieldOfView = 30
    end
end

function UIGuildBossView:UnLoadRoleBg()
    self.m_roleCam = nil
    self.m_roleCamTrans = nil
end


function UIGuildBossView:UpdatePanelView()
    self:UpdateFirstAttr()
    self:UpdateSkillAndQingYuan()
    self:UpdateWuJiangBaseInfo()
end


function UIGuildBossView:UpdateDataTaskItem(item, realIndex)
    local info = {}
    if self.m_currTab == Tab_Player_Rank then
        if realIndex > 0 and realIndex <= #self.m_userRankListInfo then
            info = self.m_userRankListInfo[realIndex]
        end
    elseif self.m_currTab == Tab_Guild_Rank then
        if realIndex > 0 and realIndex <= #self.m_guildRankListInfo then
            info = self.m_guildRankListInfo[realIndex]
        end
    end
    
    if item then
        item:UpdateData(info.sumHurt, info.level, info.name, info.rank, info.icon, info.iconBox, info.isGuildRank)
    end
end


function UIGuildBossView:OnClick(go, x, y)
    if go.name == "upAtk_BTN" then 
        if not self.m_atkBuffReqValid then
            return
        end

        UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(2400), Language.GetString(2453), 
                                           Language.GetString(10),Bind(self, self.ReqEnhanceAtk),Language.GetString(50))
    elseif go.name == "start_BTN" then
        if not self.m_atkBossReqValid then
            return
        end
        UIManagerInst:OpenWindow(UIWindowNames.UILineupMain, BattleEnum.BattleType_GUILD_BOSS, self.m_bossIndex)

    elseif go.name == "HurtRank" then
        if self.m_currTab == Tab_Player_Rank then
            return
        end
        self.m_currTab = Tab_Player_Rank
        self:ReqGuildBossRank()

    elseif go.name == "GuildRank" then
        if self.m_currTab == Tab_Guild_Rank then
            return
        end
        self.m_currTab = Tab_Guild_Rank
        self:ReqGuildBossRank()

    elseif go.name == "backBtn" then
        self:CloseSelf()

    elseif go.name == "resetButton" then
        self:ReqResetBoss()
    elseif go.name == "ruleBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIQuestionsMarkTips, 137) 
    end
end

function UIGuildBossView:ResetRoleCamPos(isTween)
    if self.m_roleCam then
        self.m_roleCam.fieldOfView = 30
        self.m_roleCamTrans.localPosition = Vector3.New(0.01, 0.24, -5.34)

        MotionBlurEffect.StopEffect()
    end
end

function UIGuildBossView:ReqGuildBossRank()
    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_BOSS_RANK_LIST
	local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIGuildBossView:ReqEnhanceAtk()
    local msg_id = MsgIDDefine.GUILD_REQ_BUY_BUFF
	local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIGuildBossView:GuildBuyBuff(msgObj)
    if msgObj.result == 0 then
        if msgObj.atk_buff_valid == 0 then
            self.m_enhanceButton.interactable = true
            GameUtility.SetUIGray(self.m_enhanceBtnTrans.gameObject, false)
            self.m_atkBuffReqValid = true
            self.m_yuanbaoTr.gameObject:SetActive(true)
            self.m_enhanceBtnText.text = Language.GetString(2429)
        else
            self.m_atkBuffReqValid = false
            self.m_enhanceButton.interactable = false
            GameUtility.SetUIGray(self.m_enhanceBtnTrans.gameObject, true)
            self.m_yuanbaoTr.gameObject:SetActive(false)
            self.m_enhanceBtnText.text = Language.GetString(2426)
        end
    end
end

function UIGuildBossView:ReqResetBoss()
    local msg_id = MsgIDDefine.GUILD_REQ_RESET_BOSS
	local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIGuildBossView:GuildResetBoss(msgObj)
    guildBossMgr:ReqGuildBossInfo()
end

function UIGuildBossView:OnAddListener()
    base.OnAddListener(self)
    self:AddUIListener(UIMessageNames.MN_GUILDBOSS_RSP_BOSSRANKINFO, self.HandleRank)
    self:AddUIListener(UIMessageNames.MN_GUILDBOSS_BUYBUFF, self.GuildBuyBuff)
    self:AddUIListener(UIMessageNames.MN_GUILDBOSS_RESETBOSS, self.GuildResetBoss)
    self:AddUIListener(UIMessageNames.MN_GUILD_RSP_ALL_GUILD_BOSS_INFO, self.RspGuildBossInfo)
end

function UIGuildBossView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_GUILDBOSS_RSP_BOSSRANKINFO, self.HandleRank)
    self:RemoveUIListener(UIMessageNames.MN_GUILDBOSS_BUYBUFF, self.GuildBuyBuff)
    self:RemoveUIListener(UIMessageNames.MN_GUILDBOSS_RESETBOSS, self.GuildResetBoss)
    self:RemoveUIListener(UIMessageNames.MN_GUILD_RSP_ALL_GUILD_BOSS_INFO, self.RspGuildBossInfo)
    base.OnRemoveListener(self)
end



return UIGuildBossView