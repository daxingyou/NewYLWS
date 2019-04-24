local DOTweenSettings = CS.DOTween.DOTweenSettings
local DOTween = CS.DOTween.DOTween
local UIPlotTopBottomHeidiView = BaseClass("UIPlotTopBottomHeidiView", UIBaseView)
local base = UIBaseView

function UIPlotTopBottomHeidiView:OnCreate()
	base.OnCreate(self)
	self.m_skipToEnd = false
	self.m_closeBtn, self.m_skipBtn,self.m_bottomImgTrans, self.m_topImgTrans = UIUtil.GetChildRectTrans(self.transform, {
		"CloseBtn",
		"topImg/skipBtn",
		"bottomImg",
		"topImg"
	})

	self.m_skipText = UIUtil.GetChildTexts(self.transform, {
        "topImg/skipBtn/skipText",
	})
	self.m_skipText.text = Language.GetString(909)
	
	self:HandleClick()
end

function UIPlotTopBottomHeidiView:OnEnable(...)
	base.OnEnable(self, ...)
	local _, recoverCamera = ...
	self.m_skipToEnd = recoverCamera == 0

	self.m_topImgTrans.anchoredPosition = Vector3.New(0, 75, 0)
	self.m_bottomImgTrans.anchoredPosition = Vector3.New(0, -75, 0)
	DOTween.ToFloatValue(function()
		return -75
	end, function(value)
		self:ChangePosition(value)
	end, 0, 0.5)
	UIManagerInst:SetUIEnable(true)
end

function UIPlotTopBottomHeidiView:ChangePosition(value)
	self.m_topImgTrans.anchoredPosition = Vector3.New(0, -value, 0)
	self.m_bottomImgTrans.anchoredPosition = Vector3.New(0, value, 0)
end

function UIPlotTopBottomHeidiView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)

    -- UIUtil.AddClickEvent(self.m_closeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_skipBtn.gameObject, onClick)
end

function UIPlotTopBottomHeidiView:RemoveEvent()
    -- UIUtil.RemoveClickEvent(self.m_closeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_skipBtn.gameObject)
end


function UIPlotTopBottomHeidiView:OnClick(go, x, y)
    local name = go.name
    -- if name == "CloseBtn" then
    --     self:CloseSelf()
	-- else
	if name == "skipBtn" then
		TimelineMgr:GetInstance():SkipTo(100, self.m_skipToEnd)
		self:CloseSelf()
    end
end

function UIPlotTopBottomHeidiView:OnDestroy()
	self:RemoveEvent()

	base.OnDestroy(self)
end

function UIPlotTopBottomHeidiView:OnDisable()
	UIManagerInst:SetUIEnable(false)

	base.OnDisable(self)
end

return UIPlotTopBottomHeidiView