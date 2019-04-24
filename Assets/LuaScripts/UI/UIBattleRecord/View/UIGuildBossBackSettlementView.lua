local base = UIBaseView
local UIGuildBossBackSettlementView = BaseClass("UIGuildBossBackSettlementView", base)
local guildBossMgr = Player:GetInstance():GetGuildBossMgr()
local GameObject = CS.UnityEngine.GameObject
local RectTransform = CS.UnityEngine.RectTransform
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local MotionBlurEffect = CS.MotionBlurEffect

local table_insert = table.insert
local string_format = string.format
local BattleEnum = BattleEnum

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local AwardIconParam = require "DataCenter.AwardData.AwardIconParam"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab

function UIGuildBossBackSettlementView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()
end

function UIGuildBossBackSettlementView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_backBtnTrans.gameObject)
    base.OnDestroy(self)
end

function UIGuildBossBackSettlementView:InitView()
    self.m_backBtnTrans, self.m_itemContentTrans = UIUtil.GetChildTransforms(self.transform, {
        "backButton","awardText/ItemScrollView/Viewport/ItemContent"
    })

    self.m_bossText, self.m_hurtNumText, self.m_hurtPercentNumText,
     self.m_ownerGuildHurtNumText, self.m_guildRankNumText = 
    UIUtil.GetChildTexts(self.transform, {
        "bossText","hurtText/hurtNumberText", 'hurtPercentText/hurtPercentNumberText',
        'ownerGuildhurtText/ownerGuildhurtNumberText', 'guildRankText/guildRankTextNumberText',
        
    })

    local hurtText, hurtPercentText, ownerGuildHurtText, guildRankText, awardText, backBtnText
    hurtText, hurtPercentText, ownerGuildHurtText, guildRankText, awardText, self.m_notAwardText, backBtnText = 
    UIUtil.GetChildTexts(self.transform, {
        "hurtText",'hurtPercentText',
        'ownerGuildhurtText', 'guildRankText', 
        'awardText','awardText/emailText','backButton/Text'
    })

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtnTrans.gameObject, onClick)

    hurtText.text = Language.GetString(2441) 
    hurtPercentText.text = Language.GetString(2442) 
    ownerGuildHurtText.text = Language.GetString(2443) 
    guildRankText.text = Language.GetString(2444) 
    awardText.text = Language.GetString(2445) 
    backBtnText.text = Language.GetString(5) 

    self.m_specialAwardList = {}
end


function UIGuildBossBackSettlementView:CreateRoleContainer()
    if IsNull(self.m_roleContainerGo) then
        self.m_roleContainerGo = GameObject("RoleContainer")
        self.mRoleContainerTrans = self.m_roleContainerGo.transform
    end
end

function UIGuildBossBackSettlementView:OnEnable(...)
    base.OnEnable(self, ...)

    local battleMsg = guildBossMgr:GetFinishBattleMsg()
    if not battleMsg then
        -- print( ' ================== no guild boss finish msg')
        return
    end
    local _,data = ...
    -- self.m_bossText  self.m_hurtNumText m_hurtPercentNumText m_ownerGuildHurtNumText m_guildRankNumText
    self.m_hurtNumText.text = string_format("%d", data[1])
    self.m_hurtPercentNumText.text = string_format(Language.GetString(2454), battleMsg.harm_percent * 100)
    
    if battleMsg.my_rank == 0 or not battleMsg.my_rank then
        self.m_ownerGuildHurtNumText.text = Language.GetString(2433)
    else
        self.m_ownerGuildHurtNumText.text = string_format("%d", battleMsg.my_rank)
    end

    if battleMsg.guild_rank == 0 or not battleMsg.guild_rank then
        self.m_guildRankNumText.text = Language.GetString(2433)
    else
        self.m_guildRankNumText.text = string_format("%d", battleMsg.guild_rank)
    end

    self:LoadRoleBg()

    self:CreateBoss()

    self.m_seq = 0
    self:HandleAwardList(battleMsg.award_list)
    if not battleMsg.award_list or #battleMsg.award_list == 0 then
        self.m_notAwardText.text = Language.GetString(2446)
    else
        self.m_notAwardText.text = ""
    end
end

function UIGuildBossBackSettlementView:HandleAwardList(awardList)
    local CreateAwardParamFromAwardData = PBUtil.CreateAwardParamFromAwardData

    local awardList = PBUtil.ParseAwardList(awardList)
    if #awardList > 0 then
        local uiData = {
            titleMsg = Language.GetString(62),
            openType = 1,
            awardDataList = awardList,
        }
        UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
    end

    for _,awardInfo in ipairs(awardList) do
        self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObject(self.m_seq, CommonAwardItemPrefab, 
        function(go)
            self.m_seq = 0
            
            if IsNull(go) then
                return
            end
            
            local specialAwardItem = CommonAwardItem.New(go, self.m_itemContentTrans, CommonAwardItemPrefab)
            table_insert(self.m_specialAwardList, specialAwardItem)
            
            local itemIconParam = CreateAwardParamFromAwardData(awardInfo)
            specialAwardItem:UpdateData(itemIconParam) 
        end)
    end

end


function UIGuildBossBackSettlementView:CreateBoss()
    self:CreateRoleContainer()

    local bossID = 0
    local weaponLevel = 4 -- todo

    local bossCfg = guildBossMgr:GetBossCfg()
    if not bossCfg then
        -- print(' no guild boss cfg ', bossInfo.cfg_id)
        return
    end

    bossID = bossCfg.boss_id % 10000

    self:ResetRoleCamPos()

    self.m_seq = ActorShowLoader:GetInstance():PrepareOneSeq()
    ActorShowLoader:GetInstance():CreateShowOffWuJiang(self.m_seq, ActorShowLoader.MakeParam(bossID, weaponLevel), self.mRoleContainerTrans, function(actorShow)
        self.m_seq = 0
        self.m_actorShow = actorShow
        actorShow:SetPosition(self:GetStandPos(1))
        actorShow:PlayAnim(BattleEnum.ANIM_IDLE)
        actorShow:SetActorShadowHeight(self:GetStandPos(1).y + 0.05)
        local modelTrans = actorShow:GetWujiangTransform()
        if modelTrans then
            modelTrans.forward = modelTrans.forward * -1
            modelTrans.localRotation = Quaternion.Euler(12, 138, -10)
        end
    end)

end

function UIGuildBossBackSettlementView:ResetRoleCamPos(isTween)
    if self.m_roleCam then
        self.m_roleCam.fieldOfView = self.m_roleCamOriginFOV
        self.m_roleCamTrans.localPosition = Vector3.New(0, 1.06, -3.6)
        self.m_roleCamOriginPos = self.m_roleCamTrans.localPosition
        self.m_roleCamChg = false
        self.m_roleCamChgTime = 0

        MotionBlurEffect.StopEffect()
    end
end

function UIGuildBossBackSettlementView:GetStandPos(standPos)
    if not self.m_standPosList then
        self.m_standPosList = {
            Vector3.New(-0.78, -0.14, -0.04),
            Vector3.New(2.5, 0.1, -2.16),
            Vector3.New(-2.5, 0.1, -2.16),
            Vector3.New(1.48, 0.1, -4.5),
            Vector3.New(-1.48, 0.1, -4.5),
        }
    end
    return self.m_standPosList[standPos]
end


function UIGuildBossBackSettlementView:LoadRoleBg()
    GameObjectPoolInst:GetGameObjectAsync(TheGameIds.GuildBossBgPath, 
        function(go)
            if not IsNull(go) then
                self.roleBgGo = go
                self.m_roleCamTrans = UIUtil.FindTrans(self.roleBgGo.transform, "RoleCamera")
                self.m_roleCam = UIUtil.FindComponent(self.m_roleCamTrans, typeof(CS.UnityEngine.Camera))

                self.m_roleCamOriginPos = self.m_roleCamTrans.localPosition
                self.m_roleCamOriginFOV = self.m_roleCam.fieldOfView
            end
        end)
end

function UIGuildBossBackSettlementView:OnDisable()
    self:RecycleObj()
    self:UnLoadRoleBg()
    self:DestroyRoleContainer()

    if self.m_specialAwardList and #self.m_specialAwardList > 0 then
        for k,v in pairs(self.m_specialAwardList) do
            v:Delete()
        end
        self.m_specialAwardList = {}
    end

    base.OnDisable(self)
end

function UIGuildBossBackSettlementView:RecycleObj()
    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end
    ActorShowLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0
end

function UIGuildBossBackSettlementView:UnLoadRoleBg()
    if not IsNull(self.roleBgGo) then
        GameObjectPoolInst:RecycleGameObject(TheGameIds.GuildBossBgPath, self.roleBgGo)
    end
    self.m_roleCamTrans.localPosition = Vector3.New(self.m_roleCamOriginPos.x - 1.47, self.m_roleCamOriginPos.y, self.m_roleCamOriginPos.z)
    self.roleBgGo = nil
    self.m_roleCam = nil
    self.m_roleCamTrans = nil
    self.m_roleCamOriginPos = nil
    self.m_roleCamOriginFOV = nil
end

function UIGuildBossBackSettlementView:DestroyRoleContainer()
    if not IsNull(self.m_roleContainerGo) then
        GameObject.DestroyImmediate(self.m_roleContainerGo)
    end

    self.m_roleContainerGo = nil
    self.mRoleContainerTrans = nil
end

function UIGuildBossBackSettlementView:OnClick(go, x, y)
    UIManagerInst:OpenWindow(UIWindowNames.UIGuildBoss)
end

function UIGuildBossBackSettlementView:EnterGuildBossFight(go)
    UIManagerInst:CloseWindow(UIWindowNames.UIGuildBossBackSettlement)
	UIManagerInst:OpenWindow(UIWindowNames.UIGuildBoss, go)
end

function UIGuildBossBackSettlementView:OnAddListener()
	base.OnAddListener(self)
    self:AddUIListener(UIMessageNames.MN_GUILDBOSS_RSP_BOSSINFO, self.EnterGuildBossFight)
end

function UIGuildBossBackSettlementView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_GUILDBOSS_RSP_BOSSINFO, self.EnterGuildBossFight)
	base.OnRemoveListener(self)
end

return UIGuildBossBackSettlementView