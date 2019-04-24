local Language = Language
local string_format = string.format
local math_ceil = math.ceil
local UIUtil = UIUtil
local table_insert = table.insert
local Time = Time
local PBUtil = PBUtil

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()

local base = require "UI.UIBattleRecord.View.BattleSettlementView"
local UIGroupHerosSettlementView = BaseClass("UIGroupHerosSettlementView", base)

local CtlBattleInst = CtlBattleInst
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local SpringContent = CS.SpringContent
local ItemContentSize = 750
local ItemSize = 150

function UIGroupHerosSettlementView:OnCreate()
    base.OnCreate(self)
    self.m_isSwitchScene = true

end

function UIGroupHerosSettlementView:OnEnable(...)
    base.OnEnable(self)
    local order, msgObj, isSwitchScene, playerWin = ...

    self.m_msgObj = msgObj
    self.m_isSwitchScene = isSwitchScene

    if playerWin then
        self:HandleWinOrLoseEffect(0)
    else
        self:HandleWinOrLoseEffect(1)
    end

    self.m_finish = true
    self:CoroutineDrop()

    if self.m_isSwitchScene then
        local finishBtnPos = self.m_finishBtnTrans.anchoredPosition
        self.m_finishBtnTrans.anchoredPosition = Vector2.New(-155, finishBtnPos.y)
        self.m_recordBtnTrans.gameObject:SetActive(true)
    else
        local finishBtnPos = self.m_finishBtnTrans.anchoredPosition
        self.m_finishBtnTrans.anchoredPosition = Vector2.New(0, finishBtnPos.y)
        self.m_recordBtnTrans.gameObject:SetActive(false)
    end
    
    self.starListTrans.gameObject:SetActive(false)
end

function UIGroupHerosSettlementView:OnClick(go, x, y)
    if go.name == "finish_BTN" then
        if self.m_isSwitchScene then
            if self.m_finish then
                SceneManagerInst:SwitchScene(SceneConfig.HomeScene)
            end
        else
            self:CloseSelf()
        end
    elseif go.name == "record_BTN" then
        if self.m_finish then
            self:Hide()
            UIManagerInst:OpenWindow(UIWindowNames.BattleRecordFromSever, self.m_msgObj)
        end
    end
end

function UIGroupHerosSettlementView:UpdateDropList()
    local dropSth = false
    if not self.m_msgObj then
        self.m_finish = true
        return 
    end
    if not self.m_msgObj.drop_list or #self.m_msgObj.drop_list == 0 then
        self.m_finish = true
    else
        self.m_finish = false
    end

    self.m_dropAttachList = {}
    local dropList = self.m_msgObj.drop_list
    if dropList and #dropList > 0 then
        dropSth = true

        self.m_bagItemSeq = UIGameObjectLoaderInstance:PrepareOneSeq()
        local count = #dropList
        UIGameObjectLoaderInstance:GetGameObjects(self.m_bagItemSeq, CommonAwardItemPrefab, count, function(objs)
            self.m_bagItemSeq = 0
            if objs then

                local CreateAwardParamFromPbAward = PBUtil.CreateAwardParamFromPbAward
                for i = 1, #objs do
                    local dropAttachItem = CommonAwardItem.New(objs[i], self.m_attachItemContentTr, CommonAwardItemPrefab)
                    dropAttachItem:SetLocalScale(Vector3.zero)   
                    table_insert(self.m_dropAttachList, dropAttachItem)
                                      
                    local itemIconParam = CreateAwardParamFromPbAward(dropList[i])
                    dropAttachItem:UpdateData(itemIconParam)
                end
            end
        end)
        
        self.m_awardItemIndex = 1
        coroutine.start(self.TweenShow, self)
    end

    if self.m_msgObj.score_chg > 0 then
        self.m_groupHerosScoreText.text = string_format(Language.GetString(3973), math_ceil(self.m_msgObj.src_score), "+"..math_ceil(self.m_msgObj.score_chg))
    else
        self.m_groupHerosScoreText.text = string_format(Language.GetString(3974), math_ceil(self.m_msgObj.src_score), math_ceil(self.m_msgObj.score_chg))
    end

    if dropSth then
        self.m_dropBg.gameObject:SetActive(true)
    else
        self.m_dropBg.gameObject:SetActive(false)
    end

end

function UIGroupHerosSettlementView:HandleWinOrLoseEffect(result)
    local function ResetEffect(eff, iswin)
        if eff then
            self.m_showStarDedayTime = 1.5
            if iswin then
                eff:SetLocalPosition(Vector3.New(0, 47, 0))
                eff:SetLocalScale(Vector3.New(92, 86, 90))
            else
                eff:SetLocalPosition(Vector3.New(0, 47, 0))
                eff:SetLocalScale(Vector3.New(88, 83, 90))
            end
        end
    end

    if result == 0 then
        if not self.m_winEffect then
            local sortOrder = self:PopSortingOrder()
            self.m_winEffect = self:AddComponent(UIEffect, "Container", sortOrder, TheGameIds.BattleWin, function()
                ResetEffect(self.m_winEffect, true)
            end)

        end

        ResetEffect(self.m_winEffect, true)
    elseif result == 1 then
        if not self.m_loseEffect then
            local sortOrder = self:PopSortingOrder()
            self.m_loseEffect = self:AddComponent(UIEffect, "Container", sortOrder, TheGameIds.BattleLose, function()
                ResetEffect(self.m_loseEffect, false)
            end)
        end

        ResetEffect(self.m_loseEffect, false)
    end
end

function UIGroupHerosSettlementView:GetBattleResult()
    return self.m_msgObj.battle_result
end

function UIGroupHerosSettlementView:Update()
    if self.m_showStarDedayTime > 0 then
        self.m_showStarDedayTime = self.m_showStarDedayTime - Time.deltaTime
        if  self.m_showStarDedayTime <= 0 then
            self.m_groupHerosScoreTr.gameObject:SetActive(true)
        end
    end
end


return UIGroupHerosSettlementView