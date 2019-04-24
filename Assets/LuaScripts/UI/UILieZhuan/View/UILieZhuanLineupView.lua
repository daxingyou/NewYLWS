local UILieZhuanLineupView = BaseClass("UILieZhuanLineupView", UIBaseView)
local base = UIBaseView
local table_insert = table.insert
local CSObject = CS.UnityEngine.Object
local Type_GridLayoutGroup = typeof(CS.UnityEngine.UI.GridLayoutGroup)
local ScreenPointToWorldPointInRectangle = CS.UnityEngine.RectTransformUtility.ScreenPointToWorldPointInRectangle
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local SplitString = CUtil.SplitString
local BattleEnum = BattleEnum
local Utils = Utils
local CommonDefine = CommonDefine
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local DOTween = CS.DOTween.DOTween
local WujiangRootPath = TheGameIds.CommonWujiangRootPath
local GameObject = CS.UnityEngine.GameObject
local Vector2 = Vector2
local Vector3 = Vector3
local string_format = string.format
local loaderInstance = UIGameObjectLoader:GetInstance()
local Language = Language

local LieZhuanLineupCardItem = require "UI.UILieZhuan.View.LieZhuanLineupCardItem"
local CardItemPath = TheGameIds.CommonWujiangCardPrefab
local LieZhuanLineupItem = require "UI.UILieZhuan.View.LieZhuanLineupItem"
local LieZhuanLineupItemPath = "UI/Prefabs/LieZhuan/LieZhuanLineupItem.prefab"

local PetPosOffset = Vector3.New(0.1, 0, 0)
local LieZhuanLineUpWujiangCount = 6

function UILieZhuanLineupView:OnCreate()
    base.OnCreate(self)

    self:InitVariable()
    self:InitView()
end

function UILieZhuanLineupView:OnAddListener()
	base.OnAddListener(self)
	-- UI消息注册
    self:AddUIListener(UIMessageNames.MN_LINEUP_ITEM_SELECT, self.OnClickWuJiangCardItem)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_SELECT, self.OnSelectWuJiangCardItem)
    self:AddUIListener(UIMessageNames.MN_LIEZHUAN_UPDATE_BUZHEN_INFO, self.UpdateLineup)
    self:AddUIListener(UIMessageNames.MN_LIEZHUAN_UPDATE_READY_STATE, self.UpdateReadyState)
    self:AddUIListener(UIMessageNames.MN_LIEZHUAN_TEAM_MEMBER_CHG, self.OnLeaveBuZhen)
    self:AddUIListener(UIMessageNames.MN_LIEZHUAN_TEAM_STAT_TIME_CHG, self.UpdateLeftTime)
    self:AddUIListener(UIMessageNames.MN_LIEZHUAN_RSP_AUTO_FIGHT, self.UpdateAutoFight)
end

function UILieZhuanLineupView:OnRemoveListener()
	base.OnRemoveListener(self)
	-- UI消息注销
    self:RemoveUIListener(UIMessageNames.MN_LINEUP_ITEM_SELECT, self.OnClickWuJiangCardItem)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_SELECT, self.OnSelectWuJiangCardItem)
    self:RemoveUIListener(UIMessageNames.MN_LIEZHUAN_UPDATE_BUZHEN_INFO, self.UpdateLineup)
    self:RemoveUIListener(UIMessageNames.MN_LIEZHUAN_UPDATE_READY_STATE, self.UpdateReadyState)
    self:RemoveUIListener(UIMessageNames.MN_LIEZHUAN_TEAM_MEMBER_CHG, self.OnLeaveBuZhen)
    self:RemoveUIListener(UIMessageNames.MN_LIEZHUAN_TEAM_STAT_TIME_CHG, self.UpdateLeftTime)
    self:RemoveUIListener(UIMessageNames.MN_LIEZHUAN_RSP_AUTO_FIGHT, self.UpdateAutoFight)
end

function UILieZhuanLineupView:OnEnable(...)
    base.OnEnable(self, ...)
    local initorder
    initorder, self.m_battleType, self.m_lineupWujiangList = ...

    self.m_bottomContainer.sizeDelta = Vector2.New(1600, self.m_bottomContainer.sizeDelta.y)
    self.m_LineupSixRoleContent:SetActive(true)

    self:HandleClick()
    self:UpdatePlayerHead()
    self:UpdateTFLShow()
    self:UpdateLeftTime(self.m_lieZhuanMgr:GetLeftTime())
    if self.m_lineupWujiangList then
        self:UpdateLineup(self.m_lineupWujiangList)
        self.m_power = self:GetLineupTotalPower(self.m_lineupWujiangList)
    end
end

function UILieZhuanLineupView:OnDisable()
    self:RecyleModelAndIcon()
    self:RemoveEvent()
    self:DestroyRoleContainer()
    self:ClearPlayerHead()
    
    self.m_perviousParent = nil
    self.m_transformIndex = 0
    self.m_lineupWujiangList = {}
    base.OnDisable(self)
end

-- 初始化非UI变量
function UILieZhuanLineupView:InitVariable()
    self.m_lieZhuanMgr = Player:GetInstance():GetLieZhuanMgr()
    self.m_wuJiangMgr = Player:GetInstance():GetWujiangMgr()
    self.m_wujiangIconList = {}
    self.m_iconSeq = 0 
    self.m_wujiangShowList = {}
    self.m_wujiangLoadingSeqList = {}
    self.m_perviousParent = nil
    self.m_dragOffset = nil
    self.m_transformIndex = 0
    self.m_battleType = BattleEnum.BattleType_LIEZHUAN_TEAM
    self.m_selectWujiangPos = nil
    self.m_tweenner = nil
    self.m_sceneSeq = 0

    self.m_lineupWujiangList = {}
    self.m_playerItemList = {}
    self.m_readyFlag = false
    
    self.m_leftTimeEnable = false
    self.m_teamLeftTimer = 0
    self.m_power = 0
end

-- 初始化UI变量
function UILieZhuanLineupView:InitView()
    local powerDesText, multiFightText, name1Text, name2Text, name3Text, name4Text, name5Text, name6Text
    self.m_powerText, powerDesText, self.m_leaveTimeText, multiFightText, self.m_tflConsumeText,
    name1Text, name2Text, name3Text, name4Text, name5Text, name6Text = UIUtil.GetChildTexts(self.transform, {
        "BottomContainer/center/powerBg/powerText",
        "BottomContainer/center/powerBg/powerDesText",
        "TopContainer/leaveTimeText",
        "BottomContainer/center/autoNextFightBtn/multiFightText",
        "BottomContainer/center/autoNextFightBtn/itemBg/consumeText",
        "UserNameContainer/name1Text",
        "UserNameContainer/name2Text",
        "UserNameContainer/name3Text",
        "UserNameContainer/name4Text",
        "UserNameContainer/name5Text",
        "UserNameContainer/name6Text",
    })
    powerDesText.text = Language.GetString(1102)
    multiFightText.text = Language.GetString(2610)
    self.m_nameTextList = {name1Text,name2Text,name3Text,name4Text,name5Text,name6Text}
    
    local iconBg1,iconBg2,iconBg3,iconBg4,iconBg5,iconBg6
    iconBg1,iconBg2,iconBg3,iconBg4,iconBg5,iconBg6,self.m_lineupRolesParent, self.m_backBtn, self.m_roleParent,
    self.m_fightBtn, self.m_bottomContainer, self.m_LineupSixRoleContent, self.m_topContainer, self.m_readyImage,
    self.m_readyMask, self.m_leftContainer, self.m_autoNextFightBtn, self.m_autoNextFightSelect = UIUtil.GetChildRectTrans(self.transform, {
        "BottomContainer/center/LineupSixRoleContent/roleBg/itemBg_1",
        "BottomContainer/center/LineupSixRoleContent/roleBg/itemBg_2",
        "BottomContainer/center/LineupSixRoleContent/roleBg/itemBg_3",
        "BottomContainer/center/LineupSixRoleContent/roleBg/itemBg_4",
        "BottomContainer/center/LineupSixRoleContent/roleBg/itemBg_5",
        "BottomContainer/center/LineupSixRoleContent/roleBg/itemBg_6",
        "BottomContainer/center/LineupSixRoleContent/lineupRoles",
        "panel/backBtn",
        "BottomContainer/center/roleParent",
        "BottomContainer/center/fightBtn",
        "BottomContainer",
        "BottomContainer/center/LineupSixRoleContent",
        "TopContainer",
        "BottomContainer/center/readyImage",
        "BottomContainer/center/readyMask",
        "panel/LeftContainer",
        "BottomContainer/center/autoNextFightBtn",
        "BottomContainer/center/autoNextFightBtn/select",
    })

    self.m_LineupSixRoleContent = self.m_LineupSixRoleContent.gameObject
    self.m_roleBgList = {iconBg1.gameObject,iconBg2.gameObject,iconBg3.gameObject,iconBg4.gameObject,iconBg5.gameObject,iconBg6.gameObject}
    self.m_roleGrid = self.m_lineupRolesParent:GetComponent(Type_GridLayoutGroup)
    self.m_roleRT = UIUtil.FindComponent(self.m_lineupRolesParent, Type_RectTransform)
    self.m_userMgr = Player:GetInstance():GetUserMgr()
    self.m_autoFightFlag = false
end

function UILieZhuanLineupView:SetParent(trans, pos, parent)
    trans:SetParent(parent)
    trans.localPosition = pos
    trans.localScale = Vector3.one
end

function UILieZhuanLineupView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_fightBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_autoNextFightBtn.gameObject, onClick)
    for _,roleBgTrans in pairs(self.m_roleBgList) do
        UIUtil.AddClickEvent(roleBgTrans, onClick)
    end
end

function UILieZhuanLineupView:RemoveEvent()
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_fightBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_autoNextFightBtn.gameObject)
    for _,roleBgTrans in pairs(self.m_roleBgList) do
        UIUtil.RemoveClickEvent(roleBgTrans)
    end
end

function UILieZhuanLineupView:OnClick(go, x, y)
    local name = go.name
    if name == "backBtn" then
        self:ShowBackTips()
    elseif string.contains(name, "itemBg_1") then
        self:OpenWujiangSeleteUI(1)
    elseif string.contains(name, "itemBg_2") then
        self:OpenWujiangSeleteUI(2)
    elseif string.contains(name, "itemBg_3") then
        self:OpenWujiangSeleteUI(3)
    elseif string.contains(name, "itemBg_4") then
        self:OpenWujiangSeleteUI(4)
    elseif string.contains(name, "itemBg_5") then
        self:OpenWujiangSeleteUI(5)
    elseif string.contains(name, "itemBg_6") then
        self:OpenWujiangSeleteUI(6)
    elseif name == "fightBtn" then
        self.m_lieZhuanMgr:ReqLieZhuanReadyFight(self.m_readyFlag)
    elseif name == "autoNextFightBtn" then
        local taoFaLingCount = Player:GetInstance():GetItemMgr():GetItemCountByID(ItemDefine.TaoFaLing_ID)
        if taoFaLingCount < 1 then
            UILogicUtil.FloatAlert(Language.GetString(2627))
            return
        end

        self.m_autoFightFlag = not self.m_autoFightFlag
        self.m_lieZhuanMgr:ReqLieZhuanSetAutoFight(self.m_autoFightFlag)
    end
end

function UILieZhuanLineupView:ShowBackTips()
	UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9), Language.GetString(3735), 
    Language.GetString(3773), function()
        local teamInfo = self.m_lieZhuanMgr:GetTeamInfo()
        if teamInfo then
            self.m_lieZhuanMgr:ReqLiezhuanExitTeam(teamInfo.team_base_info.team_id)
        end
	end, Language.GetString(50))
end

function UILieZhuanLineupView:UpdateAutoFight(is_auto_fight)
    self.m_autoFightFlag = is_auto_fight
    self.m_autoNextFightSelect.gameObject:SetActive(self.m_autoFightFlag)
end

function UILieZhuanLineupView:UpdateReadyState(is_cancel, uid, is_auto_next_fight)
    if self.m_userMgr:CheckIsSelf(uid) then
        self.m_readyFlag = not is_cancel
        self.m_readyImage.gameObject:SetActive(self.m_readyFlag)
        self.m_readyMask.gameObject:SetActive(self.m_readyFlag)
    end
    self:UpdatePlayerReadyState(is_cancel, uid)
end

function UILieZhuanLineupView:UpdatePlayerHead()
    local teamInfo = self.m_lieZhuanMgr:GetTeamInfo()
    if teamInfo and teamInfo.member_list then
        self:ClearPlayerHead()
        self.m_loaderSeq = loaderInstance:PrepareOneSeq()
        loaderInstance:GetGameObjects(self.m_loaderSeq, LieZhuanLineupItemPath, #teamInfo.member_list, function(objs)
            self.m_loaderSeq = 0
            if objs then
                for i = 1, #objs do                
                    local objItem = LieZhuanLineupItem.New(objs[i], self.m_leftContainer, LieZhuanLineupItemPath)
                    if objItem then
                        local memberInfo = teamInfo.member_list[i]
                        local userBrief = memberInfo.user_brief
                        objItem:UpdateData(teamInfo.team_base_info.captain_uid == userBrief.uid, userBrief)
                        table_insert(self.m_playerItemList, objItem)

                        if self.m_userMgr:CheckIsSelf(userBrief.uid) then
                            self:UpdateAutoFight(memberInfo.is_auto_fight)
                        end

                        self:UpdateReadyState(not memberInfo.is_buzhen_ready, userBrief.uid, memberInfo.is_auto_fight)
                    end
                end
            end
        end)
    end
end

function UILieZhuanLineupView:UpdateTFLShow()
    local taoFaLingCount = Player:GetInstance():GetItemMgr():GetItemCountByID(ItemDefine.TaoFaLing_ID)
    local costTaoFaLingCount = self.m_lieZhuanMgr:GetAutoNeedTaoFaLing()
    local num = taoFaLingCount > costTaoFaLingCount and 3628 or 3629
    self.m_tflConsumeText.text = string_format(Language.GetString(num), taoFaLingCount, costTaoFaLingCount)
end

function UILieZhuanLineupView:ClearPlayerHead()
    if self.m_playerItemList then
        for i, v in ipairs(self.m_playerItemList) do
            v:Delete()
        end
        self.m_playerItemList = {}
    end
end

function UILieZhuanLineupView:UpdatePlayerReadyState(is_cancel, uid)
    for i = 1, #self.m_playerItemList do
        if self.m_playerItemList[i]:GetUid() == uid then
            self.m_playerItemList[i]:OnSetReadyState(not is_cancel)
            break
        end
    end
end

function UILieZhuanLineupView:UpdateLineup(lineup_wujiang_list)
    if lineup_wujiang_list then
        self.m_lineupWujiangList = lineup_wujiang_list
        self:UpdateLineupIcons(lineup_wujiang_list)
        self:UpdateWujiang(lineup_wujiang_list)

        local nowPower = self:GetLineupTotalPower(lineup_wujiang_list)
        UILogicUtil.PowerChange(nowPower - self.m_power, -170)
        self.m_power = self:GetLineupTotalPower(lineup_wujiang_list)
        self.m_powerText.text = string.format("%d", self:GetLineupTotalPower(lineup_wujiang_list))
    end
end

function UILieZhuanLineupView:UpdateWujiang(lineup_wujiang_list)
    self:CreateRoleContainer()
    -- 刷新武将.
    self:WalkWujiang(lineup_wujiang_list, function(standPos, wujiangBriefData, uid)
        if wujiangBriefData then
            if self.m_wujiangLoadingSeqList[standPos] and self.m_wujiangLoadingSeqList[standPos] > 0 then
                -- 已经在加载了, 取消重新加载
                ActorShowLoader:GetInstance():CancelLoad(self.m_wujiangLoadingSeqList[standPos])
                self.m_wujiangLoadingSeqList[standPos] = 0
            end
            local actorShow = self.m_wujiangShowList[standPos]
            local weaponLevel = wujiangBriefData.weaponLevel
            if not actorShow or actorShow:GetWuJiangID() ~= wujiangBriefData.id or 
                PreloadHelper.WuqiLevelToResLevel(actorShow:GetWuQiLevel()) ~= PreloadHelper.WuqiLevelToResLevel(weaponLevel) then
                -- 武将未加载，或者已经存在但是不是同一个了重新加载
                if wujiangBriefData.id ~= 0 then
                    self:LoadWuJiangModel(standPos, wujiangBriefData.id, weaponLevel)         
                end
            else
                -- 这个位置上的武将没有变化，不再加载
            end

            if standPos <= #self.m_nameTextList then
                self:ShowUserName(standPos, uid)
            end
        else
            self:ModifyLineupSeq(standPos, 0)
            --这个位置上的武将被下了，回收模型
            if self.m_wujiangShowList[standPos] then
                self.m_wujiangShowList[standPos]:Delete()
                self.m_wujiangShowList[standPos] = nil
            end

            if standPos <= #self.m_nameTextList then
                self.m_nameTextList[standPos].text = ""
            end
        end
    end)
end

function UILieZhuanLineupView:CreateRoleContainer()
    if IsNull(self.m_roleContainerGo) then
        self.m_roleContainerGo = GameObject("RoleContainer")
        self.m_roleContainerTrans = self.m_roleContainerGo.transform

        self.m_sceneSeq = loaderInstance:PrepareOneSeq()
        loaderInstance:GetGameObject(self.m_sceneSeq, WujiangRootPath, function(go)
            self.m_sceneSeq = 0
            if not IsNull(go) then
                self.m_roleBgGo = go
                self.m_roleContainerTrans:SetParent(self.m_roleBgGo.transform)
                self.m_roleCameraTrans = self.m_roleBgGo.transform:Find("RoleCamera")
            end
            self:TweenOpen()
        end)
    end
end

function UILieZhuanLineupView:LoadWuJiangModel(standPos, wujiangID, weaponLevel)
    local loadingSeq = ActorShowLoader:GetInstance():PrepareOneSeq()
    self.m_wujiangLoadingSeqList[standPos] = loadingSeq 
    ActorShowLoader:GetInstance():CreateShowOffWuJiang(loadingSeq, ActorShowLoader.MakeParam(wujiangID, weaponLevel), self.m_roleContainerTrans, function(actorShow)
        self.m_wujiangLoadingSeqList[standPos] = 0
        
        -- 把当前位置上的武将回收了
        if self.m_wujiangShowList[standPos] then
            self.m_wujiangShowList[standPos]:Delete()
            self.m_wujiangShowList[standPos] = nil
        end
        self.m_wujiangShowList[standPos] = actorShow

        if actorShow:GetPetID() > 0 then
            actorShow:SetPosition(self:GetStandPos(standPos) - PetPosOffset)
        else
            actorShow:SetPosition(self:GetStandPos(standPos))
        end
        actorShow:SetEulerAngles(self:GetWujiangEuler(standPos))
        actorShow:PlayAnim(BattleEnum.ANIM_IDLE)
        if self.m_selectWujiangPos and self.m_selectWujiangPos == standPos then
            actorShow:PlayAnim(BattleEnum.ANIM_SHOWOFF)
            self.m_selectWujiangPos = nil
        end
    end)
end

function UILieZhuanLineupView:GetLineupTotalPower(lineup_wujiang_list)
    local totalPower = 0
    
    self:WalkWujiang(lineup_wujiang_list, function(standPos,wujiangBriefData,uid)
        totalPower = totalPower + wujiangBriefData.power
    end)

    return totalPower
end

function UILieZhuanLineupView:UpdateLineupIcons(lineup_wujiang_list)
    -- 刷新icon
    local selfUid = self.m_userMgr:GetUserData().uid
    if #self.m_wujiangIconList == 0 and self.m_iconSeq == 0 then
        self.m_iconSeq = loaderInstance:PrepareOneSeq()
        loaderInstance:GetGameObjects(self.m_iconSeq, CardItemPath, LieZhuanLineUpWujiangCount, function(objs)
            self.m_iconSeq = 0
            if objs then
                for i = 1, #objs do
                    objs[i].name = "lineupItem_" .. i
                    if selfUid == self.m_lieZhuanMgr:GetTeamCaptainUid() then
                        self:HandleDrag(objs[i])
                    end
                local wujiangItem = LieZhuanLineupCardItem.New(objs[i], self:GetIconParent(), CardItemPath)
                table_insert(self.m_wujiangIconList, wujiangItem)
            end
            self:HideAllIcon()
            self:WalkWujiang(lineup_wujiang_list,function(standPos, wujiangBriefData, uid)
                    if wujiangBriefData then
                        --self.m_wujiangIconList[standPos]:SetActive(wujiangBriefData.id > 0)
                        self.m_wujiangIconList[standPos]:SetData(wujiangBriefData)
                        self.m_wujiangIconList[standPos]:DoSelect(uid ~= selfUid)
                        local isLineupIllegal = true
                        self.m_wujiangIconList[standPos]:SetIconColor(isLineupIllegal and Color.white or Color.red)
                    end
                end)
            end
        end)
    else
        self:HideAllIcon()
        self:WalkWujiang(lineup_wujiang_list,function(standPos, wujiangBriefData, uid)
            if wujiangBriefData then
                --self.m_wujiangIconList[standPos]:SetActive(wujiangBriefData.id > 0)
                self.m_wujiangIconList[standPos]:SetData(wujiangBriefData)
                self.m_wujiangIconList[standPos]:DoSelect(uid ~= self.m_userMgr:GetUserData().uid)
                local isLineupIllegal = true
                self.m_wujiangIconList[standPos]:SetIconColor(isLineupIllegal and Color.white or Color.red)
            end
        end)
    end
end

function UILieZhuanLineupView:HideAllIcon()
    for _, wujiangItem in pairs(self.m_wujiangIconList) do
        wujiangItem:HideAll()
    end
end

function UILieZhuanLineupView:GetStandPos(standPos)
    if not self.m_standPosList then
        self.m_standPosList = {
            Vector3.New(-0.6, 0, 5.64), 
            Vector3.New(0.6, 0, 5.64), 
            Vector3.New(-1.7, 0, 6.24),  
            Vector3.New(1.7, 0, 6.24),
            Vector3.New(-3, 0, 7),
            Vector3.New(3, 0, 7)
        }
    end
    return self.m_standPosList[standPos]
end

function UILieZhuanLineupView:GetWujiangEuler(standPos)
    if not self.m_wujiangEulerList then
        self.m_wujiangEulerList = {
            Vector3.New(0, 180, 0), 
            Vector3.New(0, 180, 0),  
            Vector3.New(0, 180, 0),  
            Vector3.New(0, 180, 0),  
            Vector3.New(0, 180, 0),
            Vector3.New(0, 180, 0)
        }
    end
    return self.m_wujiangEulerList[standPos]
end

function UILieZhuanLineupView:HandleDrag(dragGO)
    local function DragBegin(go, x, y, eventData)
        self:OnDragBegin(go, x, y, eventData)
    end

    local function DragEnd(go, x, y, eventData)
        self:OnDragEnd(go, x, y, eventData)
    end

    local function Drag(go, x, y, eventData)
        self:OnDrag(go, x, y, eventData)
    end
   
    UIUtil.AddDragBeginEvent(dragGO, DragBegin)
    UIUtil.AddDragEndEvent(dragGO, DragEnd)
    UIUtil.AddDragEvent(dragGO, Drag)
end

function UILieZhuanLineupView:OnDragBegin(go, x, y, eventData)
    local dragTrans = go.transform
    self.m_transformIndex = dragTrans:GetSiblingIndex()
    if self.m_wujiangIconList[self.m_transformIndex + 1]:IsHide() then
        return
    end
    self.m_roleGrid.enabled = false

    local _, worldPos = ScreenPointToWorldPointInRectangle(self.m_roleRT, eventData.position, eventData.pressEventCamera)
    self.m_dragOffset = dragTrans.position - worldPos
    self.m_perviousParent = dragTrans.parent
    dragTrans:SetParent(self.m_roleParent)
    self.m_wujiangIconList[self.m_transformIndex + 1]:EnableRaycast(false)
    self:EnableItemRaycast(false)
end

function UILieZhuanLineupView:OnDrag(go, x, y, eventData)
    if self.m_wujiangIconList[self.m_transformIndex + 1]:IsHide() then
        return
    end

    local _, nowPos = ScreenPointToWorldPointInRectangle(self.m_roleRT, eventData.position, eventData.pressEventCamera)
    go.transform.position = nowPos + self.m_dragOffset
end

function UILieZhuanLineupView:OnDragEnd(go, x, y, eventData)
    if self.m_wujiangIconList[self.m_transformIndex + 1]:IsHide() then
        return
    end

    self:EnableItemRaycast(true)
    -- 拖出来的头像放回原来的位置
    local dragTrans = go.transform
    dragTrans:SetParent(self.m_perviousParent)
    dragTrans:SetSiblingIndex(self.m_transformIndex)

    local dropGO = eventData.pointerCurrentRaycast.gameObject
    if IsNull(dropGO) then
        -- 拖到外面了，这个武将从阵容中去掉
        --self:ModifyLineupSeq(self.m_transformIndex + 1, 0)
        --self:UpdateLineup()
    elseif string.contains(dropGO.name, "itemBg_") then
        -- 交换武将阵容数据
        local dropGOIndex = dropGO.transform:GetSiblingIndex()
        self:SwapLineupSeq(self.m_transformIndex + 1, dropGOIndex + 1)
        -- 重新刷新icon,武将因为要做动画，单独刷新
        self:UpdateLineupIcons(self.m_lineupWujiangList)
        self:SwapWujiang(self.m_transformIndex + 1, dropGOIndex + 1)
    else
        -- 拖到外面了，这个武将从阵容中去掉
        --self:ModifyLineupSeq(self.m_transformIndex + 1, 0)
        --self:UpdateLineup()
    end

    self.m_roleGrid.enabled = true
end

function UILieZhuanLineupView:SwapWujiang(index1, index2)
    -- 武将逻辑位置交换下
    local wujiang = self.m_wujiangShowList[index1]
    self.m_wujiangShowList[index1] = self.m_wujiangShowList[index2]
    self.m_wujiangShowList[index2] = wujiang
    -- 武将位置交换下
    if self.m_wujiangShowList[index1] then
        local trans = self.m_wujiangShowList[index1]:GetWujiangTransform()
        local tweener = DOTweenShortcut.DOLocalMove(trans, self:GetStandPos(index1), 0.2)
        self.m_wujiangShowList[index1]:SetEulerAngles(self:GetWujiangEuler(index1))
        DOTweenSettings.OnUpdate(tweener, function()
            self.m_wujiangShowList[index1]:SetPosition(trans.localPosition)
        end)
    end
    if self.m_wujiangShowList[index2] then
        local trans = self.m_wujiangShowList[index2]:GetWujiangTransform()
        local tweener = DOTweenShortcut.DOLocalMove(trans, self:GetStandPos(index2), 0.2)
        self.m_wujiangShowList[index2]:SetEulerAngles(self:GetWujiangEuler(index2))
        DOTweenSettings.OnUpdate(tweener, function()
            self.m_wujiangShowList[index2]:SetPosition(trans.localPosition)
        end)
    end
end

function UILieZhuanLineupView:EnableItemRaycast(enabled)
    for _, item in pairs(self.m_wujiangIconList) do
        if item then
            item:EnableRaycast(enabled)
        end
    end
end

function UILieZhuanLineupView:OnClickWuJiangCardItem(standPos)

    self:OpenWujiangSeleteUI(standPos)
end

function UILieZhuanLineupView:OnSelectWuJiangCardItem(selectWujiangSeq, data1, standPos)

    self:ModifyLineupSeq(standPos, selectWujiangSeq)
    self.m_selectWujiangPos = standPos

    self:UpdateLineup(self.m_lineupWujiangList)
    self:TweenItemPos(standPos)
end

function UILieZhuanLineupView:TweenItemPos(standPos)
    self.m_roleGrid.enabled = false
    UIUtil.KillTween(self.m_tweenner)
    local trans = self.m_wujiangIconList[standPos].transform
    local localPos = trans.localPosition
    trans.localPosition = Vector3.New(localPos.x, localPos.y + 30, 0)
    self.m_tweenner = DOTweenShortcut.DOLocalMoveY(trans, localPos.y, 0.5)
    DOTweenSettings.SetEase(self.m_tweenner, DoTweenEaseType.OutBounce)
    DOTweenSettings.OnComplete(self.m_tweenner, function()
        self.m_roleGrid.enabled = true
    end)
end

function UILieZhuanLineupView:OpenWujiangSeleteUI(standPos)
    UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanTeamLineupSelect, self.m_lineupWujiangList, standPos)
end

function UILieZhuanLineupView:RecyleModelAndIcon()
    loaderInstance:CancelLoad(self.m_iconSeq)
    self.m_iconSeq = 0

    for _,seq in pairs(self.m_wujiangLoadingSeqList) do
        if seq > 0 then
            ActorShowLoader:GetInstance():CancelLoad(seq)
        end
    end
    self.m_wujiangLoadingSeqList = {}

    for _,wujiangIcon in pairs(self.m_wujiangIconList) do
        UIUtil.RemoveDragEvent(wujiangIcon:GetGameObject())
        wujiangIcon:Delete()
    end
    self.m_wujiangIconList = {}

    for _,wujiangShow in pairs(self.m_wujiangShowList) do
        if wujiangShow then
            wujiangShow:Delete()
        end
    end

    self.m_petSeq = 0
    self.m_wujiangShowList = {}
end

function UILieZhuanLineupView:GetIconParent()
    return self.m_lineupRolesParent
end

function UILieZhuanLineupView:DestroyRoleContainer()
    if not IsNull(self.m_roleContainerGo) then
        GameObject.DestroyImmediate(self.m_roleContainerGo)
    end

    self.m_roleContainerGo = nil
    self.m_roleContainerTrans = nil
    self.m_roleCameraTrans = nil

    loaderInstance:CancelLoad(self.m_sceneSeq)
    self.m_sceneSeq = 0

    if not IsNull(self.m_roleBgGo) then
        loaderInstance:RecycleGameObject(WujiangRootPath, self.m_roleBgGo)
        self.m_roleBgGo = nil
    end
end

function UILieZhuanLineupView:WalkWujiang(lineup_wujiang_list, filter)
    for _,v in ipairs(lineup_wujiang_list) do
        filter(v.pos, v.wujiang_brief, v.uid)
    end
end

function UILieZhuanLineupView:ModifyLineupSeq(standPos, newSeq)
    local wujiangBriefData = self.m_wuJiangMgr:GetWuJiangBriefData(newSeq)
    if self.m_lineupWujiangList and wujiangBriefData then
        for i = 1, #self.m_lineupWujiangList do
            if standPos == self.m_lineupWujiangList[i].pos then
                self.m_lineupWujiangList[i].wujiang_brief = wujiangBriefData
            end
        end

        self.m_lieZhuanMgr:ReqLieZhuanSelectWuJiang(newSeq,standPos,wujiangBriefData.id)
    end
end

function UILieZhuanLineupView:SwapLineupSeq(standPos1, standPos2)
    local index1 = 0
    local index2 = 0 
    if self.m_lineupWujiangList then
        for i = 1, #self.m_lineupWujiangList do
            if standPos1 == self.m_lineupWujiangList[i].pos then
                index1 = i
            elseif standPos2 == self.m_lineupWujiangList[i].pos then
                index2 = i
            end
        end
        
        if index1 ~= index2 and index1 ~= 0 and index2 ~= 0 then
            self.m_lineupWujiangList[index1].pos = standPos2
            self.m_lineupWujiangList[index2].pos = standPos1

            self.m_lieZhuanMgr:ReqLieZhuanExchangeWuJiang(standPos1, standPos2)
        end
    end
end

function UILieZhuanLineupView:TweenOpen()
    DOTween.ToFloatValue(function()
        return 0
    end, 
    function(value)
        self.m_topContainer.anchoredPosition = Vector3.New(0, 130 - 130 * value, 0)
        local pos = Vector3.New(0, 0.9, 0.6 + 0.4 * value)
        self.m_roleCameraTrans.localPosition = pos
    end, 1, 0.3)

    local tweener = DOTween.ToFloatValue(function()
        return 0
    end, 
    function(value)
        self.m_bottomContainer.anchoredPosition = Vector3.New(0, -133 + 260 * value, 0)
    end, 1, 0.4)
    DOTweenSettings.SetEase(tweener, DoTweenEaseType.InOutBack)
end

function UILieZhuanLineupView:OnLeaveBuZhen(teamInfo, action, uid)
    local someOneLeave = action == 3 or action == 2
    if someOneLeave then
        if teamInfo then 
            UIManagerInst:OpenWindow(UIWindowNames.UILieZhuanFightTroop,teamInfo)             
        else
            self:CloseSelf()
        end
    end
end

function UILieZhuanLineupView:UpdateLeftTime(left_time)
    if left_time then
        self.m_teamLeftTimer = Player:GetInstance():GetServerTime() + left_time
        self.m_leftTimeEnable = true
    end
end

function UILieZhuanLineupView:Update()
    if self.m_leftTimeEnable then
        self:UpdateTimeText()
    end
end

function UILieZhuanLineupView:UpdateTimeText()
    if not self.m_teamLeftTimer then
        return
    end
    local refreshTime = self.m_teamLeftTimer
    local curTime = Player:GetInstance():GetServerTime() 

    local leftS = refreshTime - curTime
    if leftS and leftS < 0 then
        leftS = 0
        self.m_leftTimeEnable = false
        return
    end
    if leftS and leftS ~= self.lastLeftS then
        self.m_leaveTimeText.text = string.format(Language.GetString(3796), leftS)
        self.lastLeftS = leftS
    end 
end

function UILieZhuanLineupView:ShowUserName(standPos, uid) 
    local name, strDistId = self.m_lieZhuanMgr:GetUserNameDistFromTeamByUid(uid)
    if name and strDistId then
        self.m_nameTextList[standPos].text = string_format(Language.GetString(3733), name, strDistId)
    else
        self.m_nameTextList[standPos].text = ""
    end
end

function UILieZhuanLineupView:PrepareFight()

end

return UILieZhuanLineupView