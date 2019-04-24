local UIFingerGuideDialogView = BaseClass("UIFingerGuideDialogView", UIBaseView)
local base = UIBaseView
local TimelineType = TimelineType
local SequenceEventType = SequenceEventType
local Type_Grid = typeof(CS.UnityEngine.UI.GridLayoutGroup)
local Type_HorizontalGrid = typeof(CS.UnityEngine.UI.HorizontalLayoutGroup)
local Type_VerticalGrid = typeof(CS.UnityEngine.UI.VerticalLayoutGroup)
local Vector3 = Vector3
local Quaternion = Quaternion
local SplitString = CUtil.SplitString
local DOTweenSettings = CS.DOTween.DOTweenSettings
local DOTweenExtensions = CS.DOTween.DOTweenExtensions
local DOTween = CS.DOTween.DOTween
local Type_ContentSizeFitter = typeof(CS.UnityEngine.UI.ContentSizeFitter)
local Vector3ScaleR = Vector3.New(1, 1, 1)
local Vector3Pos1 = Vector3.New(125, -25, 0)
local Vector3Pos2= Vector3.New(280, -69, 0)
local Vector3ScaleL = Vector3.New(-1, 1, 1)
local VectorPos4 = Vector3.New(110, -25, 0)
local VectorPos5 = Vector3.New(265, -69, 0)

function UIFingerGuideDialogView:OnCreate()
	base.OnCreate(self)
	self.m_targetUIName = nil
	self.m_highLightChildPath = nil
	self.m_focusTargetPath = nil
	self.m_highLightParent = nil
	self.m_focusTargetParent = nil
	self.m_focusTargetIndex = 0
	self.m_highLightTrans = nil
	self.m_focusTargetTrans = nil
	self.m_focusTargetGrid = nil
	self.m_focusTargetGridState = false
	self.m_focusTargetPosZ = false
	self.m_selectEffect = nil
	self.m_layerName = UILogicUtil.FindLayerName(self.transform)

	self.m_contentRoot, self.m_bgTrans, self.m_nameRectTrans, self.m_msgRectTrans,
	self.m_highLightRoot, self.m_focusRoot, self.m_fingerTrans, self.m_shieldBtn = UIUtil.GetChildRectTrans(self.transform, {
		"ContentRoot",
		"ContentRoot/bg",
		"ContentRoot/nameLbl",
		"ContentRoot/msgLbl",
		"HighLightRoot",
		"FocusRoot",
		"FocusRoot/Finger",
		"shieldBtn",
	})

	self.m_nameText, self.m_msgText = UIUtil.GetChildTexts(self.transform, {
		"ContentRoot/nameLbl",
		"ContentRoot/msgLbl",
	})
	
	self.m_bgImg = UIUtil.AddComponent(UIImage, self, "ContentRoot/bg", AtlasConfig.DynamicLoad)
	self.m_bgTrans = self.m_bgTrans.transform
	self:AddComponent(UICanvas, "FocusRoot", 1)

	self:HandleClick()
end

function UIFingerGuideDialogView:HandleClick()
	local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)

	UIUtil.AddClickEvent(self.m_shieldBtn.gameObject, onClick)
end

function UIFingerGuideDialogView:RemoveClick()
	UIUtil.RemoveClickEvent(self.m_shieldBtn.gameObject)
end

function UIFingerGuideDialogView:OnClick(go, x, y)
	if not self.m_focusTargetTrans then
		TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, self.winName)
	end
end

function UIFingerGuideDialogView:OnEnable(...)
	base.OnEnable(self, ...)
	UIManagerInst:SetUIEnable(true)
	local initOrder, sParam1, message, title, posx, posy, languageCfgName = ...
	local paramList = SplitString(sParam1, ',')
	self.m_targetUIName = paramList[1]
	self.m_highLightChildPath = paramList[2]
	self.m_focusTargetPath = paramList[3]
	self.m_focusTargetIndex = tonumber(paramList[4])
	self.m_fingerRotate = SplitString(paramList[5], '|')
	self.m_fingerOffset = SplitString(paramList[6], '|')

	self.m_contentRoot.gameObject:SetActive(message ~= 0)
	self.m_fingerTrans.gameObject:SetActive(false)
	self.m_nameText.text = PlotLanguage.GetString(languageCfgName, title)
	self.m_msgText.text = PlotLanguage.GetString(languageCfgName, message)
	self.m_contentRoot.anchoredPosition = Vector3.New(posx, posy, 0)
	self.m_bgTrans.localScale = Vector3ScaleL
	self.m_nameRectTrans.anchoredPosition = VectorPos4
	self.m_msgRectTrans.anchoredPosition = VectorPos5
	self.m_effectSortOrder = self:PopSortingOrder()

	-- 69是text顶部到bg顶部偏移， 14是text底部到bg底部的偏移
	local bgHeight = 14 + 69 + self.m_msgText.preferredHeight
	if bgHeight < 139 then
		bgHeight = 139
	end
	self.m_contentRoot.sizeDelta = Vector2.New(525, bgHeight)

	self:UpdateHighLightPanel()
end

function UIFingerGuideDialogView:OnDisable()
	if self.m_tweener then
		DOTweenExtensions.Kill(self.m_tweener)
		self.m_tweener  = nil
	end

	local UIMgrIntance = UIManagerInst
	local uiWindow =  UIMgrIntance:GetWindow(self.m_targetUIName)
	if not uiWindow then
		return
	end

	if self.m_highLightTrans then
		self.m_highLightTrans:SetParent(self.m_highLightParent)
	end

	if self.m_focusTargetTrans then
		if self.m_focusTargetGrid then
			self.m_focusTargetGrid.enabled = self.m_focusTargetGridState
		end

		local parentTran = self.m_focusTargetTrans.parent
		if parentTran then
			--没有回收的情况下
			if GameObjectPoolInst:GetCacheTransRoot() ~= parentTran then
				self.m_focusTargetTrans:SetParent(self.m_focusTargetParent)
				self:ResetFocusTargetPosZ()
				if self.m_focusTargetIndex >= 0 then
					self.m_focusTargetTrans:SetSiblingIndex(self.m_focusTargetIndex)
				end
			end
		end

		if self.m_focusTargetContentSizeFitter then
			self.m_focusTargetContentSizeFitter.enabled = true
			self.m_focusTargetContentSizeFitter = nil
		end
	end
	UIMgrIntance:SetUIEnable(false)
	UIMgrIntance:Broadcast(UIMessageNames.MN_GUIDE_RECOVER_EFFECT_ORDER, self.m_targetUIName)

	self.m_targetUIName = nil
	self.m_highLightChildPath = nil
	self.m_focusTargetPath = nil
	self.m_highLightParent = nil
	self.m_focusTargetParent = nil
	self.m_focusTargetIndex = 0
	self.m_highLightTrans = nil
	self.m_focusTargetTrans = nil
	self.m_focusTargetGrid = nil
	self.m_focusTargetGridState = false
	self.m_focusTargetPosZ = false
	self:ClearNuqiEffect()
    base.OnDisable(self)
end

function UIFingerGuideDialogView:UpdateHighLightPanel()
	local uiWindow =  UIManagerInst:GetWindow(self.m_targetUIName, true, true)
	if not uiWindow then
		return
	end

	if self.m_focusTargetPath and self.m_focusTargetPath ~= '' then
		self.m_focusRoot.gameObject:SetActive(true)
		self.m_focusTargetTrans = uiWindow.View:GetChildTrans(self.m_focusTargetPath)
		self.m_focusTargetGrid = self.m_focusTargetTrans:GetComponent(Type_Grid)
		if not self.m_focusTargetGrid then
			self.m_focusTargetGrid = self.m_focusTargetTrans:GetComponent(Type_HorizontalGrid)
			if not self.m_focusTargetGrid then
				self.m_focusTargetGrid = self.m_focusTargetTrans:GetComponentInParent(Type_VerticalGrid)
			end
		end

		if self.m_focusTargetGrid then
			self.m_focusTargetGridState = self.m_focusTargetGrid.enabled
			self.m_focusTargetGrid.enabled = false
		end

		self.m_focusTargetContentSizeFitter = self.m_focusTargetTrans:GetComponent(Type_ContentSizeFitter)
		if self.m_focusTargetContentSizeFitter then
			self.m_focusTargetContentSizeFitter.enabled = false
		end
		
		if self.m_focusTargetIndex >= 0 then
			self.m_focusTargetTrans = self.m_focusTargetTrans:GetChild(self.m_focusTargetIndex)
		else
			self.m_focusTargetIndex = self.m_focusTargetTrans:GetSiblingIndex()
		end
		self.m_focusTargetParent = self.m_focusTargetTrans.parent

		local tmpPos = self.m_focusTargetTrans.localPosition
		self.m_focusTargetPosZ = tmpPos.z

		self.m_focusTargetTrans:SetParent(self.m_focusRoot)
		
		tmpPos = self.m_focusTargetTrans.localPosition
		tmpPos.z = -1000  -- 神兵模型在这里 显示不对
		self.m_focusTargetTrans.localPosition = tmpPos
		
		self:UpdateFinger(self.m_focusTargetTrans.localPosition)
		self:ShowEffect(self.m_focusTargetTrans)
	else
		self.m_focusRoot.gameObject:SetActive(false)
	end
	
	if self.m_highLightChildPath and self.m_highLightChildPath ~= '' then
		self.m_highLightTrans = uiWindow.View:GetChildTrans(self.m_highLightChildPath)
		self.m_highLightParent = self.m_highLightTrans.parent
		self.m_highLightTrans:SetParent(self.m_highLightRoot)
	end

	UIManagerInst:Broadcast(UIMessageNames.MN_GUIDE_SET_EFFECT_ORDER, self.m_targetUIName, self.m_effectSortOrder + 6)
end

function UIFingerGuideDialogView:ResetFocusTargetPosZ()
	if self.m_focusTargetPosZ then
		local tmpPos = self.m_focusTargetTrans.localPosition
		tmpPos.z = self.m_focusTargetPosZ
		self.m_focusTargetTrans.localPosition = tmpPos
	end
end

function UIFingerGuideDialogView:UpdateFinger(pos)
	if self.m_tweener then
		DOTweenExtensions.Kill(self.m_tweener)
		self.m_tweener  = nil
	end

	self.m_fingerTrans.localRotation = Quaternion.Euler(0, tonumber(self.m_fingerRotate[1]), tonumber(self.m_fingerRotate[2]))

	local targetPosX = tonumber(self.m_fingerOffset[1]) + pos.x
	local targetPosY = tonumber(self.m_fingerOffset[2]) + pos.y
	local dir = self.m_fingerTrans.right
	local dirX = dir.x * 20
	local dirY = dir.y * 20
	self.m_fingerTrans.anchoredPosition = Vector3.New(targetPosX + dirX, targetPosY + dirY, 0)

	self.m_tweener = DOTween.ToFloatValue(function()
        return 0
    end, 
    function(value)
        self.m_fingerTrans.anchoredPosition = Vector3.New(targetPosX + dirX * (1 - value), targetPosY + dirY * (1 - value), 0)
	end, 1, 0.5)
	DOTweenSettings.SetLoops(self.m_tweener, -1, 1)
	DOTweenSettings.SetEase(self.m_tweener, DoTweenEaseType.OutExpo)
	self.m_fingerTrans.gameObject:SetActive(true)
end

function UIFingerGuideDialogView:ShowEffect(rectTrans)
		local pos = rectTrans.localPosition
		local pivot = rectTrans.pivot
		local sizeDelta = rectTrans.sizeDelta
		pos.x = pos.x - (pivot.x - 0.5) * sizeDelta.x 
		pos.y = pos.y - (pivot.y - 0.5) * sizeDelta.y

		if self.m_selectEffect then
				self.m_selectEffect:SetLocalPosition(pos)
		else
				local sortOrder = UISortOrderMgr:GetInstance():PopSortingOrder(self, self.m_layerName)
				UIUtil.AddComponent(UIEffect, self, "FocusRoot", sortOrder, TheGameIds.ui_zhiyin, function(effect)
						self.m_selectEffect = effect
						self.m_selectEffect:SetLocalPosition(pos)
				end)
		end
end

function UIFingerGuideDialogView:ClearNuqiEffect()
	if self.m_selectEffect then
			self.m_selectEffect:Delete()
			self.m_selectEffect = nil
	end 
end

function UIFingerGuideDialogView:OnDestroy()
	self:RemoveClick()
	UISortOrderMgr:GetInstance():PushSortingOrder(self, self.m_layerName)
	base.OnDestroy(self)
end

return UIFingerGuideDialogView