--[[
-- added by wsh @ 2018-02-26
-- UIBattleMain视图层
--]]

local GameUtility = CS.GameUtility
local UIUtil = UIUtil
local UIBattleMainView = BaseClass("UIBattleMainView", UIBaseView)
local base = UIBaseView
local unity_key_code = CS.UnityEngine.KeyCode
local Vector3 = Vector3
local Vector2 = Vector2
local ActorUtil = ActorUtil
local Quaternion = CS.UnityEngine.Quaternion
local GetSkillCfgByID = ConfigUtil.GetSkillCfgByID
local TypeText = typeof(CS.TMPro.TextMeshProUGUI)
local table_sort = table.sort
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format
local math_floor= math.floor
local isEditor = GameUtility.IsEditor()
local Language = Language
local MeshRenderer = CS.UnityEngine.MeshRenderer
local Type_MeshRenderer = typeof(MeshRenderer)
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local Type_Text = typeof(CS.UnityEngine.UI.Text)
local Type_Animator = typeof(CS.UnityEngine.Animator)
-- local Type_CircleRawImageTransform = typeof(CS.CircleRawImage)
local Type_UI_Image = typeof(CS.UnityEngine.UI.Image)
local Type_Texture2D = typeof(CS.UnityEngine.Texture2D)
local Shader = CS.UnityEngine.Shader
local CommonDefine = CommonDefine
local ScreenPointToLocalPointInRectangle = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local DOTweenExtensions = CS.DOTween.DOTweenExtensions
local TheGameIds = TheGameIds
local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab
local SysIDs = SysIDs
local ActorManagerInst = ActorManagerInst
local UIManagerInst = UIManagerInst
local CtlBattleInst = CtlBattleInst
local BattleEnum = BattleEnum

local UISliderHelper = typeof(CS.UISliderHelper)

local WujiangItemPrefabPath = "UI/Prefabs/Battle/BattleWujiangItem.prefab"
local BenchWujiangItem = require("UI.UIBattle.View.BenchWujiangItem")
local BattleWujiangItem = require("UI.UIBattle.View.BattleWujiangItem")
local BagItem = require "UI.UIBag.View.BagItem"
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"
local ActorBubbleItemPath = "UI/Prefabs/Battle/ActorBubbleItem.prefab"
local ActorBubbleItem = require("UI.UIBattle.View.ActorBubbleItem")
local EffectPath = "UI/Effect/Prefabs/summon_glow"

local GameObjectPoolInst = GameObjectPoolInst
local PlayerInst = Player:GetInstance()
local ChatMgr = PlayerInst:GetChatMgr()

local BOX_SCALE = Vector3.New(0.6, 0.6, 0.6)

function UIBattleMainView:__init()
	self.lineTrans = nil
	self.m_wujiangItemArray = nil
	self.m_wujiangBubbleItemList = nil
	self.m_speed = 1
end

function UIBattleMainView:OnCreate()
	base.OnCreate(self)
	self.m_wujiangItemArray = {}
	self.m_wujiangBubbleItemList = {}
	self.m_loaderSeq = 0
	self.m_benchWujiangItemArray = {}
	self.m_shaderValueID = Shader.PropertyToID("_Value")
	
	self.m_waveTR, self.m_boxRoot, self.m_tongqianRoot, self.m_tongqianImageTran, self.m_wujiangContainerTrans,
	self.m_assistWujiangRootTrans, self.m_chatTxtRoot, self.m_benchRoot, 
	self.back_btn, self.m_summonBtn, self.m_switchCameraBtn, self.m_friendBtn, self.m_chatBtn, self.m_chatBg,
	self.m_speedBtn, self.joyBtn, self.goBtn, self.m_selectorTargetTrans, self.m_bottomLeftContainerTran, 
	self.m_panelTrans = UIUtil.GetChildRectTrans(self.transform, {
        "topMiddleContainer/waveBg",
		"TopRightContainer/AwardBoxBtn",
		"TopRightContainer/TongQian",
		"TopRightContainer/TongQian/TongQianImage",
		"Panel/wujiangContainer",
		"Panel/AssistWujiangContainer",
		"BottomLeftContainer/ChatText",
		"TopRightContainer/benchRoot",
		"TopRightContainer/BackBtn",
		"BottomRightContainer/summonBtn",
		"BottomRightContainer/SwitchCamera",
		"BottomLeftContainer/friendBtn",
		"BottomLeftContainer/chatBtn",
		"BottomLeftContainer/ChatText/chatbg",
		"BottomRightContainer/speedBtn",
		"BottomRightContainer/AutoBattle",
		"DynamicCanvas/CenterRightContainer/goBtn",
		"BattleSelectorTarget",
		"BottomLeftContainer",
		"Panel",
    })

	
	self.m_boxRootPosition = self.m_boxRoot.position

	-- self.m_waveText = UIUtil.FindComponent(self.transform, TypeText, "topMiddleContainer/waveBg/waveText")
	self.m_timeText = UIUtil.FindComponent(self.transform, TypeText, "topMiddleContainer/waveBg/Time/timeText")
	self.m_boxText = UIUtil.FindComponent(self.transform, TypeText, "TopRightContainer/AwardBoxBtn/BoxBG/BoxText")
	self.m_chatText = UIUtil.FindComponent(self.transform, TypeText, "BottomLeftContainer/ChatText/ContentText")

    self.m_tongqianText = UIUtil.GetChildTexts(self.transform, {
        "TopRightContainer/TongQian/TongQianImage/TongQianText"
	})

	self.m_tongqianRoot.gameObject:SetActive(false)

	self.m_boxCount = 0
	self.m_graveBoxCount = 0
	
    self.m_hideChatTime = 0
	self.m_tongqianDict = {}
	self.m_tongqian = 0

	self.m_hideWaveGoTime = 0
	self.m_layerName = UILogicUtil.FindLayerName(self.transform)

    if CommonDefine.IS_HAIR_MODEL then
		local tmpPos = self.m_wujiangContainerTrans.anchoredPosition
		self.m_wujiangContainerTrans.anchoredPosition = Vector2.New(tmpPos.x -47, tmpPos.y)
		tmpPos = self.m_assistWujiangRootTrans.anchoredPosition
		self.m_assistWujiangRootTrans.anchoredPosition = Vector2.New(tmpPos.x -47, tmpPos.y)
		tmpPos = self.m_bottomLeftContainerTran.anchoredPosition
		self.m_bottomLeftContainerTran.anchoredPosition = Vector2.New(tmpPos.x + 72, tmpPos.y)
	end
	
	self.m_summonImg = UIUtil.AddComponent(UIImage, self, "BottomRightContainer/summonBtn", AtlasConfig.DynamicLoad)	
	self.m_summonBgImg = UIUtil.AddComponent(UIImage, self, "DynamicCanvas/BottomRightContainer/summonBg", AtlasConfig.DynamicLoad)
	self.m_speedImage = self:AddComponent(UIImage, "BottomRightContainer/speedBtn/SpeedTextImage", AtlasConfig.BattleDynamicLoad)
	self.m_autoBattleImage = self:AddComponent(UIImage, "BottomRightContainer/AutoBattle/AutoBattleImage", AtlasConfig.BattleDynamicLoad)

	-- self.goBtn.gameObject:SetActive(false)
	
	self:CheckActorCreated()

	self:UpdateAutoFight()

	self.m_waveShowGo = nil

	self.m_selectorTargetName = UIUtil.FindComponent(self.transform, TypeText, "BattleSelectorTarget/nameBg/Text")
	self.m_selectorTargetImage = UIUtil.AddComponent(UIImage, self, "BattleSelectorTarget/Mask/targetImage", AtlasConfig.RoleIcon)
	self.m_selectorTargetMaskImage = UIUtil.FindComponent(self.transform, Type_UI_Image, "BattleSelectorTarget/Fill")
	
	self.m_showSelectorTarget = false
	self.m_selectorTargetID = 0

	self:InitSpeedUpSetting()

	self:HandleClick()
end

function UIBattleMainView:OnEnable(...)
	base.OnEnable(self, ...)
	-- self.m_waveTR.gameObject:SetActive(false)
	local logic = CtlBattleInst:GetLogic()
	if logic then
		if logic:IsHideUIWhenUIStart() then
			self:Hide()
		end

		if logic:GetBattleType() == BattleEnum.BattleType_CAMPSRUSH then
			self:CreatBetchWujiangItem()
		end

		if logic:GetBattleType() == BattleEnum.BattleType_COPY or 
			logic:GetBattleType() == BattleEnum.BattleType_GRAVE then
			self.m_boxRoot.gameObject:SetActive(true)
		end
		
		if logic:GetBattleType() == BattleEnum.BattleType_SHENBING then
			self.m_boxRoot.gameObject:SetActive(false)
		end

		if logic:GetBattleType() == BattleEnum.BattleType_GRAVE then
			self.m_tongqianRoot.gameObject:SetActive(true)
		end

		local battleParam = logic:GetBattleParam()
		if battleParam.leftCamp.oneDragon then
			self.m_summonBtn.gameObject:SetActive(true)
			self.m_summonBgImg.gameObject:SetActive(true)
			UILogicUtil.SetDragonIcon(self.m_summonImg, battleParam.leftCamp.oneDragon.dragonID)
			UILogicUtil.SetDragonIcon(self.m_summonBgImg, battleParam.leftCamp.oneDragon.dragonID)
			self:LoadSummonEffect()
		else
			self.m_summonBtn.gameObject:SetActive(false)
			self.m_summonBgImg.gameObject:SetActive(false)
		end
	end
	self.back_btn.gameObject:SetActive(true)
end

function UIBattleMainView:Update()
	self:UpdateTimeText()
	self:UpdateSummon()
	self:CheckHideChat()
	self:CheckHideWaveGo()
	self:UpdateWujiangBubble()
	
	if isEditor then
		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.F6) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_RIGHT then
						tmpTarget:KillSelf()
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.F5) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
						tmpTarget:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_HP, -300)
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.F7) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_RIGHT then
						local giver = StatusGiver.New(tmpTarget:GetActorID(), 1)
						local buff = StatusFactoryInst:NewStatusFrozen(giver, 1000)
						tmpTarget:GetStatusContainer():Add(buff, tmpTarget)
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.C) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_RIGHT then
						local giver = StatusGiver.New(1, 1)
						local immuneBuff = StatusFactoryInst:NewStatusImmune(giver, 3000)
						immuneBuff:AddImmune(StatusEnum.IMMUNEFLAG_CONTROL)
						tmpTarget:GetStatusContainer():DelayAdd(immuneBuff)
					end
				end
			)
		end 


		if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.F8) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
						local giver = StatusGiver.New(0, 0)
						local buff = StatusFactoryInst:NewStatusFrozen(giver, 1000)
						tmpTarget:GetStatusContainer():DelayAdd(buff)
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.D) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
						local giver = StatusGiver.New(0, 0)
						local buff = StatusFactoryInst:NewStatusDingShen(giver, 2000)
						tmpTarget:GetStatusContainer():DelayAdd(buff)
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.S) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
						local giver = StatusGiver.New(0, 0)
						local buff = StatusFactoryInst:NewStatusStun(giver, 2000)
						tmpTarget:GetStatusContainer():DelayAdd(buff)
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.F) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
						local giver = StatusGiver.New(0, 0)
						local buff = StatusFactoryInst:NewStatusFear(giver, 2000)
						tmpTarget:GetStatusContainer():DelayAdd(buff)
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.A) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
						tmpTarget:OnBeatFly(BattleEnum.ATTACK_WAY_FLY_AWAY, tmpTarget:GetPosition(), 1)
					end
				end
			)
		end 

		if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.J) then
			ActorManagerInst:Walk(
				function(tmpTarget)
					if tmpTarget:GetCamp() == BattleEnum.ActorCamp_LEFT then
						local giver = StatusGiver.New(tmpTarget:GetActorID(), 0)
						local buff = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, 5000)
						local curAtk = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
						local chgAtk = FixMath.muli(curAtk, -0.5)
						buff:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, chgAtk)
						tmpTarget:GetStatusContainer():Add(buff)
					end
				end
			)
		end

		if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.L) then
			CtlBattleInst:GetLogic():AlwaysPlayDazhaoTimeline()
		end
	end
end

function UIBattleMainView:HandleClick()
	local onClick = UILogicUtil.BindClick(self, self.OnClick)

    UIUtil.AddClickEvent(self.back_btn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_summonBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_switchCameraBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_friendBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_chatBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_chatBg.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_speedBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.joyBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.goBtn.gameObject, onClick)
end

function UIBattleMainView:RemoveClick()
    UIUtil.RemoveClickEvent(self.back_btn.gameObject)
    UIUtil.RemoveClickEvent(self.m_summonBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_switchCameraBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_friendBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_chatBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_chatBg.gameObject)
    UIUtil.RemoveClickEvent(self.m_speedBtn.gameObject)
    UIUtil.RemoveClickEvent(self.joyBtn.gameObject)
    UIUtil.RemoveClickEvent(self.goBtn.gameObject)
end

function UIBattleMainView:OnClick(go, x, y)
	local btnName = go.name

	if btnName == 'BackBtn' then
		self:Back()
	elseif btnName == 'summonBtn' then
		self:ClearEffect()
		CtlBattleInst:GetLogic():PerformDragonSkill(BattleEnum.ActorCamp_LEFT)
	elseif btnName == 'SwitchCamera' then
		if CtlBattleInst:IsInFight() then
			CtlBattleInst:GetLogic():SwitchCamera()
		end
	elseif btnName == 'friendBtn' then
		UILogicUtil.SysShowUI(SysIDs.FRIEND)
	elseif btnName == 'chatBtn' or btnName == 'chatbg' then
		UILogicUtil.SysShowUI(SysIDs.CHAT)
	elseif btnName == 'speedBtn' then
		self.m_speed = self.m_speed + 0.5
		self.m_speed = self.m_speed > 2 and 1 or self.m_speed
		TimeScaleMgr:SetTimeScaleMultiple(self.m_speed)
		CtlBattleInst:GetLogic():WriteSpeedUpSetting(self.m_speed)

		if self.m_speed == 1 then
			self.m_speedImage:SetAtlasSprite("zhandou92.png", true)
		elseif self.m_speed == 1.5 then
			self.m_speedImage:SetAtlasSprite("zhandou93.png", true)
		elseif self.m_speed == 2 then
			self.m_speedImage:SetAtlasSprite("zhandou94.png", true)
		end
	elseif btnName == 'AutoBattle' then
		local logic = CtlBattleInst:GetLogic()
		if logic and logic:GetCurWave() > 1 and self.goBtn.gameObject.activeSelf then
			CtlBattleInst:FrameResume()
			self.goBtn.gameObject:SetActive(false)
			logic:OnBattleGo()
		end
		
		self:UpdateAutoFight(true)
		FrameCmdFactory:GetInstance():ProductCommand(BattleEnum.FRAME_CMD_TYPE_AUTO_FIGHT)
	elseif btnName == 'goBtn' then
		CtlBattleInst:FrameResume()
		self.goBtn.gameObject:SetActive(false)
		local logic = CtlBattleInst:GetLogic()
		if logic then
			logic:OnBattleGo()
		end
	end
end

function UIBattleMainView:OnDestroy()
	self:RemoveClick()

	for _, wujiangItem in pairs(self.m_benchWujiangItemArray) do
		if wujiangItem then
			wujiangItem:Delete()
		end
	end
	self.m_benchWujiangItemArray = {}

	for _,item in pairs(self.m_wujiangItemArray) do
		item:Delete()
	end
	for _,item in pairs(self.m_wujiangBubbleItemList) do
		item:Delete()
	end
	self.m_wujiangBubbleItemList = nil

	if self.m_waveShowGo then
		GameObjectPoolInst:RecycleGameObject(TheGameIds.WaveMsgPrefab, self.m_waveShowGo)
		self.m_waveShowGo = nil
	end

	self.m_wujiangItemArray = nil
	self.m_benchWujiangItemArray = nil
	self.m_speed = 1
	self.effectCircleMaterial = nil
	self.m_loaderSeq = 0
	self.m_shaderValueID = 0	
	-- self.m_waveText = nil
	self.m_timeText = nil
	self.m_boxText = nil
	self.m_boxCount = 0
	self.m_wujiangContainerTrans = nil
	self.back_btn = nil
	self.m_summonBtn = nil
	self.m_switchCameraBtn = nil
	self.m_speedImage = nil
	self.m_speedBtn = nil
	self.m_autoBattleImage = nil
	self.joyBtn = nil
	self.goBtn = nil
	self.m_benchRoot = nil
	-- self.m_waveTR = nil
	self.m_assistWujiangRootTrans = nil

	base.OnDestroy(self)
end

function UIBattleMainView:OnAddListener()
	base.OnAddListener(self)
	-- UI消息注册
	self:AddUIListener(UIMessageNames.UIBATTLE_START, self.OnBattleStart)
	self:AddUIListener(UIMessageNames.UIBATTLE_STOP, self.OnBattleStop)
	self:AddUIListener(UIMessageNames.UIBATTLE_ACTOR_CREATE, self.OnActorCreate)
    self:AddUIListener(UIMessageNames.UIBATTLE_ACTOR_DIE, self.OnActorDie)
	self:AddUIListener(UIMessageNames.UIBATTLE_HP_CHANGE, self.OnHPChange)
	self:AddUIListener(UIMessageNames.UIBATTLEFLOAT_SHOW_NUQI, self.OnNuqiChange)
	self:AddUIListener(UIMessageNames.UIBATTLE_WAVE_END, self.OnWaveEnd)
	self:AddUIListener(UIMessageNames.UIBATTLE_PICK_BOX, self.PickBox)
	self:AddUIListener(UIMessageNames.UIBATTLE_PICK_MONEY, self.PickMoney)
	self:AddUIListener(UIMessageNames.UIBATTLE_PICK_GRAVE_BOX, self.PickGraveBox)
	self:AddUIListener(UIMessageNames.UIBATTLE_HIDE_MAINVIEW, self.Hide)
	self:AddUIListener(UIMessageNames.UIBATTLE_SHOW_MAINVIEW, self.Show)
	self:AddUIListener(UIMessageNames.MN_BATTLE_SHOW_SELECTOR_TARGET, self.ShowBattleSelectorTarget)
	--self:AddUIListener(UIMessageNames.MN_COPY_FINISH, self.HandleCopyFinish)
	self:AddUIListener(UIMessageNames.MN_CHAT_MAIN_CHAT_LIST, self.UpdateChatMsgList)
	self:AddUIListener(UIMessageNames.MN_CLEAR_DRAGON_EFFECT, self.ClearEffect)
end

function UIBattleMainView:OnRemoveListener()
	base.OnRemoveListener(self)
	-- UI消息注销
	self:RemoveUIListener(UIMessageNames.UIBATTLE_START, self.OnBattleStart)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_STOP, self.OnBattleStop)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_ACTOR_CREATE, self.OnActorCreate)
    self:RemoveUIListener(UIMessageNames.UIBATTLE_ACTOR_DIE, self.OnActorDie)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_HP_CHANGE, self.OnHPChange)
	self:RemoveUIListener(UIMessageNames.UIBATTLEFLOAT_SHOW_NUQI, self.OnNuqiChange)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_WAVE_END, self.OnWaveEnd)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_PICK_BOX, self.PickBox)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_PICK_MONEY, self.PickMoney)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_PICK_GRAVE_BOX, self.PickGraveBox)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_HIDE_MAINVIEW, self.Hide)
	self:RemoveUIListener(UIMessageNames.UIBATTLE_SHOW_MAINVIEW, self.Show)
	self:RemoveUIListener(UIMessageNames.MN_BATTLE_SHOW_SELECTOR_TARGET, self.ShowBattleSelectorTarget)
	--self:RemoveUIListener(UIMessageNames.MN_COPY_FINISH, self.HandleCopyFinish)
	self:RemoveUIListener(UIMessageNames.MN_CHAT_MAIN_CHAT_LIST, self.UpdateChatMsgList)
	self:RemoveUIListener(UIMessageNames.MN_CLEAR_DRAGON_EFFECT, self.ClearEffect)
end

function UIBattleMainView:OnBattleStart(wave)
	local logic = CtlBattleInst:GetLogic()
	

	local localPos = Vector3.New(0, -105, 0)

	GameObjectPoolInst:GetGameObjectAsync(TheGameIds.WaveMsgPrefab,
		function(inst)
			self.m_waveShowGo = inst

			local tr = inst.transform
			tr:SetParent(self.m_waveTR)
			tr.localPosition = localPos
			tr.localScale = Vector3.New(2, 2, 2)
			
			local text = inst:GetComponentInChildren(Type_Text)
			if text then
				text.text = string_format(Language.GetString(305), wave, logic:GetMaxWave())
			end

			local ani = inst:GetComponentInChildren(Type_Animator)
			if ani then
				ani:Play('BattleMsg_wave', 0, 0)
			end
			
			self.m_hideWaveGoTime = PlayerInst:GetServerTime() + 2
		end)
end

function UIBattleMainView:OnBattleStop(wave)

end

function UIBattleMainView:CheckActorCreated()
	ActorManagerInst:Walk(
		function(tmpTarget)
			local actorID = tmpTarget:GetActorID()			
			self:OnActorCreate(actorID)
        end
    )
end

function UIBattleMainView:OnActorCreate(actorID)
    local actor = ActorManagerInst:GetActor(actorID)
    if not actor then
       return 
	end
	
	if CtlBattleInst:GetLogic():GetBattleType() == BattleEnum.BattleType_GRAVE and actor:GetWujiangID() == 6011 then
		self:CreateWujiangBubbleItem(actor)
	else
		self:CreateBattleWujiangItem(actor)
	end
end

function UIBattleMainView:CreateBattleWujiangItem(actor)
	local wujiangItem1 = self:GetWujiangItem(actor:GetActorID())
	if wujiangItem1 then
		return
	end
	
	if actor:GetCamp() ~= BattleEnum.ActorCamp_LEFT or actor:IsCalled() or ActorUtil.IsAnimal(actor) then
		return
	end

	self:CheckItemForCampsRush(actor)

	GameObjectPoolInst:GetGameObjectAsync(WujiangItemPrefabPath, function(inst)
        local wujiangItem = BattleWujiangItem.New(inst, actor:GetWujiangSeq() == 9999 and self.m_assistWujiangRootTrans or self.m_wujiangContainerTrans, WujiangItemPrefabPath)
		wujiangItem:SetData(actor:GetActorID(), self.base_order)
		table_insert(self.m_wujiangItemArray, wujiangItem)
		self:SortWujiangItem()
    end)
end

function UIBattleMainView:CreateWujiangBubbleItem(actor)
	GameObjectPoolInst:GetGameObjectAsync(ActorBubbleItemPath, function(inst)
		local actorBubbleItem = ActorBubbleItem.New(inst, self.m_panelTrans, ActorBubbleItemPath)
		actorBubbleItem:SetData(actor:GetActorID(), 1123, {1120,1121,1122}, self.m_panelTrans)
		table_insert(self.m_wujiangBubbleItemList, actorBubbleItem)
    end)
end

function UIBattleMainView:OnActorDie(actorID)
	local wujiangItem = self:GetWujiangItem(actorID)
	if wujiangItem then
		wujiangItem:OnActorDie()
	end
end

function UIBattleMainView:OnHPChange(actorID, hpChgVal)
	local wujiangItem = self:GetWujiangItem(actorID)
	if wujiangItem then
		wujiangItem:UpdateBloodBar(hpChgVal)
	end
end

function UIBattleMainView:OnNuqiChange(actor, chgVal, reason)
	if not actor then
		return
	end

	local wujiangItem = self:GetWujiangItem(actor:GetActorID())
	if wujiangItem then
		wujiangItem:UpdateNuqiBar(chgVal)
	end
end

function UIBattleMainView:GetWujiangItem(actorID)
	for i,item in pairs(self.m_wujiangItemArray) do
		if item and item:GetActorID() == actorID then
			return item,i
		end
	end
end

function UIBattleMainView:SortWujiangItem()
	table_sort(self.m_wujiangItemArray, function(itemA, itemB)
		return itemA:GetLineupPos() < itemB:GetLineupPos()
	end)
	for i,item in pairs(self.m_wujiangItemArray) do
		if item then
			item:SetSiblingIndex(i)
		end
	end
end

function UIBattleMainView:Back()
	local ctlInstance = CtlBattleInst
	if ctlInstance:GetLogic():IsFinished() then
		return
	end
	
	local isAlreadPause = ctlInstance:IsFramePause()
	if ctlInstance:IsInFight() and (isAlreadPause or ctlInstance:IsPause()) then
		return
	end

	BattleCameraMgr:Pause()
	ctlInstance:Pause(BattleEnum.PAUSEREASON_WANT_EXIT, 111)
	if not isAlreadPause then
		CtlBattleInst:FramePause()
	end

	self:ShowBackTips()
end

function UIBattleMainView:ShowBackTips()
	UIManagerInst:OpenWindow(UIWindowNames.UITipsDialog, Language.GetString(9), self:GetBackLanguage(), 
	Language.GetString(8), function()
		local battleLogic = CtlBattleInst:GetLogic()
		if battleLogic then
			PlayerInst:GetMainlineMgr():GetUIData().isAutoFight = false
			battleLogic:OnCityReturn()
		end
	end, Language.GetString(7), function()
		BattleCameraMgr:Resume()
		CtlBattleInst:Resume(BattleEnum.PAUSEREASON_WANT_EXIT)
		if not isAlreadPause then
			CtlBattleInst:FrameResume()
		end
	end)
end

function UIBattleMainView:GetBackLanguage()
	return Language.GetString(6)
end

function UIBattleMainView:OnWaveEnd()
	self.goBtn.gameObject:SetActive(true)
	CtlBattleInst:FramePause()

    UIUtil.LoopTweenLocalScale(self.goBtn.transform, Vector3.one, Vector3.New(1.2, 1.2, 1.2), 0.8)
end

function UIBattleMainView:UpdateTimeText()

	local logic = CtlBattleInst:GetLogic()
	if logic then
		local leftS = logic:GetLeftS()
		if leftS ~= self.lastLeftS then
			local min = math_floor(leftS / 60)
			local sec = math_floor(leftS % 60)
			self.m_timeText.text = string_format("%02d:%02d", min, sec)
			self.lastLeftS = leftS
		end
	end
end

function UIBattleMainView:UpdateAutoFight(isClick)
	if isClick == nil then
		isClick = false
	end

    local logic = CtlBattleInst:GetLogic()
	if logic then
		if isClick then --AutoFight 下一帧才更新
			if logic:IsAutoFight() then
				self.m_autoBattleImage:SetAtlasSprite("zhandou100.png", true)
				logic:WriteAutoFightSetting(false)
			else
				self.m_autoBattleImage:SetAtlasSprite("zhandou99.png", true)
				logic:WriteAutoFightSetting(true)
			end
		else
			local autoFightSetting = logic:ReadAutoFightSetting()
			if autoFightSetting then
				self.m_autoBattleImage:SetAtlasSprite("zhandou99.png", true)
				if not logic:IsAutoFight() then
					FrameCmdFactory:GetInstance():ProductCommand(BattleEnum.FRAME_CMD_TYPE_AUTO_FIGHT)
				end
			else
				if logic:IsAutoFight() then
					self.m_autoBattleImage:SetAtlasSprite("zhandou99.png", true)
				else
					self.m_autoBattleImage:SetAtlasSprite("zhandou100.png", true)
				end
			end
		end
	end
end

function UIBattleMainView:InitSpeedUpSetting()
    local logic = CtlBattleInst:GetLogic()
	if logic then
		self.m_speed = logic:ReadSpeedUpSetting()
        TimeScaleMgr:SetTimeScaleMultiple(self.m_speed)
		if self.m_speed == 1 then
			self.m_speedImage:SetAtlasSprite("zhandou92.png", true)
		elseif self.m_speed == 1.5 then
			self.m_speedImage:SetAtlasSprite("zhandou93.png", true)
		elseif self.m_speed == 2 then
			self.m_speedImage:SetAtlasSprite("zhandou94.png", true)
		end
	end
end

function UIBattleMainView:UpdateSummon()
	local logic = CtlBattleInst:GetLogic()
    if not logic then
        return
    end
	
	local battleParam = logic:GetBattleParam()
	if not battleParam.leftCamp.oneDragon then
		return
	end

	local summonLogic = logic:GetDragonLogic()
    if not summonLogic then
        return
    end

	local value = summonLogic:GetConditionPercent(BattleEnum.ActorCamp_LEFT)
	if self.effectCircleMaterial then
		self.effectCircleMaterial:SetFloat(self.m_shaderValueID, value)
	end
	
	self.m_summonBgImg:SetFillAmount(value)
	if value >= 1 then
		if not self.m_effect then
			local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
			UIUtil.AddComponent(UIEffect, self, "DynamicCanvas/BottomRightContainer/summonBg", sortOrder, EffectPath, function(effect)
				effect:SetLocalPosition(Vector3.zero)
				effect:SetLocalScale(Vector3.one)
				self.m_effect = effect
			end)
		end
	end
end

function UIBattleMainView:ClearEffect()
	if self.m_effect then
        self.m_effect:Delete()
        self.m_effect = nil
    end
end

function UIBattleMainView:LoadSummonEffect()
	if not self.summonEffect then
		
		local sortOrder = self:PopSortingOrder()
		self:AddComponent(UIEffect, "DynamicCanvas/BottomRightContainer/summonBg", sortOrder, "UI/Effect/Prefabs/summon", function(effect)
			self.summonEffect = effect
			self.summonEffect:SetLocalPosition(Vector3.New(-1.9, -71.2, 0))
			self.summonEffect:SetLocalScale(Vector3.New(1.05, 1.05, 1.05))

			if not self.effectCircleMaterial then
				local effectTrans = self.summonEffect.rectTrans
				if not IsNull(effectTrans) then
					local renderer = UIUtil.FindComponent(effectTrans,Type_MeshRenderer, "zhaohuanshou_qiti/qiti")
					if renderer and renderer.material then
						self.effectCircleMaterial = renderer.material
						self.effectCircleMaterial:SetFloat(self.m_shaderValueID, 0)
					end
				end
			end
		end)
	end
end

--[[ function UIBattleMainView:HandleCopyFinish(copyAwardData)
	local logic = CtlBattleInst:GetLogic()
	if logic then
		logic:OnAward(copyAwardData)
	end
end ]]

function UIBattleMainView:CreatBetchWujiangItem()
	local benchWujiangList = CtlBattleInst:GetLogic():GetBenchWujiangList()

	if #benchWujiangList > 0 and self.m_loaderSeq == 0 then
		self.m_loaderSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(self.m_loaderSeq, WujiangItemPrefabPath, #benchWujiangList, function(objs)
            self.m_loaderSeq = 0
            if objs then
				for i = 1, #objs do
					local wujiangItem = BenchWujiangItem.New(objs[i], self.m_benchRoot, WujiangItemPrefabPath)
					wujiangItem:SetData(benchWujiangList[i], self.base_order)
					table_insert(self.m_benchWujiangItemArray, wujiangItem)
				end
            end
        end)
	end
end

function UIBattleMainView:OnDisable()
	UIGameObjectLoader:GetInstance():CancelLoad(self.m_loaderSeq)
	UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)
	self:ClearEffect()
	self.m_loaderSeq = 0
    base.OnDisable(self)
end

function UIBattleMainView:CheckItemForCampsRush(actor)
	if CtlBattleInst:GetLogic():GetBattleType() ~= BattleEnum.BattleType_CAMPSRUSH then
		return
	end

	for i,item in pairs(self.m_wujiangItemArray) do
		if item and item:GetLineupPos() == actor:GetLineupPos() then
			item:Delete()
			table_remove(self.m_wujiangItemArray, i)
			break
		end
	end


	for i, wujiangItem in pairs(self.m_benchWujiangItemArray) do
		if wujiangItem:GetWujiangID() == actor:GetWujiangID() then
			wujiangItem:Delete()
			table_remove(self.m_benchWujiangItemArray, i)
			break
		end
	end
end

function UIBattleMainView:MoveBoxIcon(bagItem)
	local boxGO = bagItem:GetGameObject()

	-- local targetPos = self.m_boxRoot.position
	local selfPos = bagItem.transform.position

    local pathArray = {
		Vector3.New(selfPos.x, selfPos.y, selfPos.z), self.m_boxRootPosition
	}
		
    local tweener = DOTweenShortcut.DOPath(bagItem.transform, pathArray, 1)
    DOTweenSettings.SetEase(tweener, DoTweenEaseType.OutSine)
    DOTweenSettings.OnComplete(tweener, function()
		self.m_boxCount = self.m_boxCount + 1
		self.m_boxText.text = '' .. self.m_boxCount
		bagItem:Delete()
    end)
end

function UIBattleMainView:PickBox(worldPos, item_id)	
	local itemCfg = ConfigUtil.GetItemCfgByID(item_id)
	if not itemCfg then
		return
	end

	local loaderSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
	UIGameObjectLoader:GetInstance():GetGameObject(loaderSeq, BagItemPrefabPath, 
		function(go)
			if IsNull(go) then
				return
			end

			local mainCamera = BattleCameraMgr:GetMainCamera()			
			local ok, outV2 = GameUtility.PosWorld2RectPos(mainCamera, UIManagerInst.UICamera, worldPos.x, worldPos.y, worldPos.z, self.rectTransform, 0.2)
    
			local v_new = Vector3.New(outV2.x, outV2.y, 0)

			local bagItem = BagItem.New(go, self.transform, BagItemPrefabPath)
			bagItem:SetLocalScale(BOX_SCALE)
			bagItem:SetLocalPosition(v_new)
			local itemIconParam = ItemIconParam.New(itemCfg, 0, nil, 0, nil, false, false)
			itemIconParam.onClickShowDetail = true

			bagItem:UpdateData(itemIconParam)

			self:MoveBoxIcon(bagItem)			
		end)
end

function UIBattleMainView:PickGraveBox(boxItem)
	if not boxItem then
		return
	end

	local _, pos = boxItem[1], boxItem[2]
	local targetPos = self.m_boxText.transform.position

	GameObjectPoolInst:GetGameObjectAsync(TheGameIds.BaoxiangPrefab, function(obj)
        if IsNull(obj) then
            return
		end

		local mainCamera = BattleCameraMgr:GetMainCamera()
		
		local ok, outV2 = GameUtility.PosWorld2RectPos(mainCamera, UIManagerInst.UICamera, pos.x, pos.y, pos.z, self.rectTransform, 0)
		
		local boxTran = obj.transform
		GameUtility.RecursiveSetLayer(obj, Layers.UI)
		boxTran:SetParent(self.transform)
		GameUtility.SetLocalPosition(boxTran, outV2.x, outV2.y, 0)
		GameUtility.SetLocalScale(boxTran, 160, 160, 160)

		local selfPos = boxTran.position
		local pathArray = {
			Vector3.New(selfPos.x, selfPos.y, selfPos.z), Vector3.New(targetPos.x, targetPos.y, targetPos.z)
		}
			
		local tweener = DOTweenShortcut.DOPath(boxTran, pathArray, 1)
		DOTweenSettings.SetEase(tweener, DoTweenEaseType.OutSine)
		DOTweenSettings.OnComplete(tweener, function()
			GameObjectPoolInst:RecycleGameObject(TheGameIds.BaoxiangPrefab, obj)
			self.m_graveBoxCount = self.m_graveBoxCount + 1
			self.m_boxText.text = '' .. self.m_graveBoxCount
		end)
    end)
end

function UIBattleMainView:PickMoney(tongqianItem)	
	if not tongqianItem then
		return
	end

	local _, pos, dieActorID, dropMoney = tongqianItem[1], tongqianItem[2], tongqianItem[3], tongqianItem[4]
	local targetPos = self.m_tongqianImageTran.position

	GameObjectPoolInst:GetGameObjectAsync(TheGameIds.TongQianPrefab, function(obj)
        if IsNull(obj) then
            return
		end

		local mainCamera = BattleCameraMgr:GetMainCamera()
		
		local ok, outV2 = GameUtility.PosWorld2RectPos(mainCamera, UIManagerInst.UICamera, pos.x, pos.y, pos.z, self.rectTransform, 0)
		
		local tongqianTran = obj.transform
		GameUtility.RecursiveSetLayer(obj, Layers.UI)
		tongqianTran:SetParent(self.transform)		
		GameUtility.SetLocalPosition(tongqianTran, outV2.x, outV2.y, 0)
		GameUtility.SetLocalScale(tongqianTran, 160, 160, 160)

		local selfPos = tongqianTran.position
		local pathArray = {
			Vector3.New(selfPos.x, selfPos.y, selfPos.z), Vector3.New(targetPos.x, targetPos.y, targetPos.z)
		}
			
		local tweener = DOTweenShortcut.DOPath(tongqianTran, pathArray, 1)
		DOTweenSettings.SetEase(tweener, DoTweenEaseType.OutSine)
		DOTweenSettings.OnComplete(tweener, function()
			GameObjectPoolInst:RecycleGameObject(TheGameIds.TongQianPrefab, obj)
			if not self.m_tongqianDict[dieActorID] then
				self.m_tongqianDict[dieActorID] = true
				self.m_tongqian = self.m_tongqian + dropMoney
				self.m_tongqianText.text = self.m_tongqian
			end
		end)
    end)
end

function UIBattleMainView:Hide()
	self.rectTransform.localPosition = Vector3.New(0, 3000, 0)
end

function UIBattleMainView:Show()
	self.rectTransform.localPosition = Vector3.zero
end

function UIBattleMainView:ShowBattleSelectorTarget(isShow, target)
	if isShow then
		if target:GetActorID() == self.m_selectorTargetID then
			return
		end

		local bloodBar = target:GetBloodBarTransform()
		if not bloodBar then
			return
		end


		self.m_selectorTargetTrans.gameObject:SetActive(true)
		local mainCamera = BattleCameraMgr:GetMainCamera()

		-- local x, y, z = Vector3.Get(bloodBar.position)
		local x, y, z = target:GetPosition():GetXYZ()
		
		local ok, outV2 = GameUtility.PosWorld2RectPos(mainCamera, UIManagerInst.UICamera, x, y, z, self.rectTransform, 0)

		GameUtility.SetLocalPosition(self.m_selectorTargetTrans, outV2.x + 60, outV2.y + 200, 0)
  
		local targetCurHp = target:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
		local targetMaxHp = target:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_MAXHP)
		local hpPercent = targetCurHp / targetMaxHp
		self.m_selectorTargetMaskImage.fillAmount = hpPercent
		local wujiangCfg = ConfigUtil.GetWujiangCfgByID(target:GetWujiangID())
		if wujiangCfg then
			self.m_selectorTargetImage:SetAtlasSprite(wujiangCfg.sIcon)
			self.m_showSelectorTarget = true
			self.m_selectorTargetID = target:GetActorID()
		end
		
	else
		self.m_selectorTargetID = 0

		if self.m_showSelectorTarget then
			self.m_selectorTargetTrans.gameObject:SetActive(false)
			self.m_showSelectorTarget = false
		end
	end
end

function UIBattleMainView:UpdateChatMsgList()
    local chatDataList = ChatMgr:GetMainChatList()
	if chatDataList and #chatDataList > 0 then
		local lastOne = chatDataList[#chatDataList]

		local chatData = lastOne.chatData
		local chatType = lastOne.chatType
		
		if chatData then            
			self.m_chatTxtRoot.gameObject:SetActive(true)
			self.m_hideChatTime = PlayerInst:GetServerTime() + 30
        
            local speaker_brief = chatData.speaker_brief
    
            if chatType == CommonDefine.CHAT_TYPE_SYS then
                self.m_chatText.text = string_format(Language.GetString(3115), chatData.words)  
            elseif chatType == CommonDefine.CHAT_TYPE_WORLD then
                if speaker_brief then
                    self.m_chatText.text = string_format(Language.GetString(3114), speaker_brief.name, chatData.words)  
                end
            elseif chatType == CommonDefine.CHAT_TYPE_GUILD then
                if speaker_brief then
                    self.m_chatText.text = string_format(Language.GetString(3116), speaker_brief.name, chatData.words)  
                end
            else
                self.m_chatText.text = ''
            end
        end
	end
end

function UIBattleMainView:CheckHideChat()	
    if self.m_hideChatTime > 0 and PlayerInst:GetServerTime() >= self.m_hideChatTime then
        self.m_chatTxtRoot.gameObject:SetActive(false)
        self.m_hideChatTime = 0
	end
end

function UIBattleMainView:CheckHideWaveGo()
	if self.m_hideWaveGoTime > 0 and PlayerInst:GetServerTime() >= self.m_hideWaveGoTime then
		self.m_hideWaveGoTime = 0

		if self.m_waveShowGo then
			GameObjectPoolInst:RecycleGameObject(TheGameIds.WaveMsgPrefab, self.m_waveShowGo)
			self.m_waveShowGo = nil
		end
	end
end

function UIBattleMainView:UpdateWujiangBubble()
	local count = #self.m_wujiangBubbleItemList
	for i = count, 1, -1 do
		local item = self.m_wujiangBubbleItemList[i]
		item:Update()
		if item:IsOver() then
			item:Delete()
			table_remove(self.m_wujiangBubbleItemList, i)
		end
	end
end

return UIBattleMainView