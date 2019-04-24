--[[
-- added by wsh @ 2017-11-30
-- UI视图层基类：该界面所有UI刷新操作，只和展示相关的数据放在这，只有操作相关数据放Model去
-- 注意：
-- 1、被动刷新：所有界面刷新通过消息驱动---除了打开界面时的刷新
-- 2、对Model层可读，不可写---调试模式下强制
-- 3、所有写数据、游戏控制操作、网络相关操作全部放Ctrl层
-- 4、Ctrl层不依赖View层，但是依赖Model层
-- 5、任何情况下不要在游戏逻辑代码操作界面刷新---除了打开、关闭界面
--]]
local Vector3 = Vector3
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local UIBaseView = BaseClass("UIBaseView", UIBaseContainer)
local base = UIBaseContainer
local InitScale = Vector3.one * 0.01

-- 构造函数：必须把基类需要的所有参数列齐---即使在这里不用，提高代码可读性
-- 子类别再写构造函数，初始化工作放OnCreate
local function __init(self, holder, var_arg1, var_arg2)
	-- 窗口画布
	self.canvas = nil
	-- 窗口基础order，窗口内添加的其它canvas设置的order都以它做偏移
	self.base_order = 0
	self.IsNeedSetTop = true
	self.IsNeedSetRightMenu = true
	self.winName = var_arg1
	self.tweenTargetPath = var_arg2
end

-- 创建：资源加载完毕
local function OnCreate(self)
	base.OnCreate(self)
	-- 窗口画布
	self.canvas = self:AddComponent(UICanvas, "", 0)
	-- 回调管理，使其最长保持和View等同的生命周期
	self.__ui_callback = {}
	-- 初始化RectTransform
	self.rectTransform.offsetMax = Vector2.zero
	self.rectTransform.offsetMin = Vector2.zero
	self.rectTransform.localScale = Vector3.one
	self.rectTransform.localPosition = Vector3.zero
	if self.tweenTargetPath then
		self.tweenTarget = UIUtil.FindTrans(self.transform, self.tweenTargetPath)
	end
end

-- 打开：窗口显示
local function OnEnable(self, initOrder)
	self.base_order = initOrder or self.holder:PopWindowOder()
	base.OnEnable(self)
	self:OnAddListener()

	if self.tweenTarget then
		self:TweenOpen()
	end
end

-- 注册消息
local function OnAddListener(self)
end

-- 注销消息
local function OnRemoveListener(self)
end

local function AddCallback(keeper, msg_name, callback)
	assert(callback ~= nil)
	keeper[msg_name] = callback
end

local function GetCallback(keeper, msg_name)
	return keeper[msg_name]
end

local function RemoveCallback(keeper, msg_name, callback)
	assert(callback ~= nil)
	keeper[msg_name] = nil
end

-- 注册UI数据监听事件，别重写
local function AddUIListener(self, msg_name, callback)
	local bindFunc = Bind(self, callback)
	AddCallback(self.__ui_callback, msg_name, bindFunc)
	UIManagerInst:AddListener(msg_name, bindFunc)
end

-- 注销UI数据监听事件，别重写
local function RemoveUIListener(self, msg_name, callback)
	local bindFunc = GetCallback(self.__ui_callback, msg_name)
	RemoveCallback(self.__ui_callback, msg_name, bindFunc)
	UIManagerInst:RemoveListener(msg_name, bindFunc)
end

-- 关闭：窗口隐藏
local function OnDisable(self)
	self:OnRemoveListener()
	self:PushSortingOrder()
	self.holder:PushWindowOrder()
	base.OnDisable(self)
end

-- 销毁：窗口销毁
local function OnDestroy(self)
	for k,v in pairs(self.__ui_callback) do
		self:RemoveUIListener(k, v)
	end
	self.__ui_callback = nil

	base.OnDestroy(self)
end

local function CloseSelf(self)
	if self.tweenTarget then
		self:TweenClose()
	else
		UIManagerInst:CloseWindow(self.winName)
	end
end

local function GetRecoverParam(self)
	
end

local function PopSortingOrder(self, count)
    return UISortOrderMgr:GetInstance():PopSortingOrder(self, self.holder.LayerName, count)
end

local function PushSortingOrder(self, count)
	return UISortOrderMgr:GetInstance():PushSortingOrder(self, self.holder.LayerName, count)
end

function UIBaseView:TweenOpen()
	self.tweenTarget.localScale = InitScale
	local tweener = DOTweenShortcut.DOScale(self.tweenTarget, 1, 0.4)
	DOTweenSettings.SetEase(tweener, DoTweenEaseType.OutBack)
	DOTweenSettings.OnComplete(tweener, function()
        self:OnTweenOpenComplete()
    end)
end

function UIBaseView:OnTweenOpenComplete()

end

function UIBaseView:TweenClose()
	local tweener = DOTweenShortcut.DOScale(self.tweenTarget, 0.01, 0.3)
	DOTweenSettings.SetEase(tweener, DoTweenEaseType.InBack)
	DOTweenSettings.OnComplete(tweener, function()
        UIManagerInst:CloseWindow(self.winName)
    end)
end

function UIBaseView:SetLayerOrder(order)
	if self.canvas then
		self.canvas:SetLayerOrder(order)
	end
end

function UIBaseView:GetLayerOrder()
	if self.canvas then
		return self.canvas:GetLayerOrder()
	end
end

function UIBaseView:GetChildTrans(childPath)
	return UIUtil.FindTrans(self.transform, childPath)
end


function UIBaseView:PlayOpenAudio()
	local audioID = self:GetOpenAudio()
	if audioID > 0 then
		AudioMgr:PlayUIAudio(audioID)
	end
end

function UIBaseView:GetOpenAudio()
	local audioID = 0
	if self.holder.LayerName == UILayers.BackgroudLayer.Name then
		audioID = 104
	elseif self.holder.LayerName == UILayers.NormalLayer.Name then
		audioID = 103
	end
	return audioID
end

function UIBaseView:PlayCloseAudio()
	local audioID = self:GetCloseAudio()
	if audioID > 0 then
		AudioMgr:PlayUIAudio(audioID)
	end
end

function UIBaseView:GetCloseAudio()
	local audioID = 0
	if self.holder.LayerName == UILayers.BackgroudLayer.Name then
		audioID = 106
	elseif self.holder.LayerName == UILayers.NormalLayer.Name then
		audioID = 105
	end
	return audioID
end

UIBaseView.__init = __init
UIBaseView.OnCreate = OnCreate
UIBaseView.OnEnable = OnEnable
UIBaseView.OnAddListener = OnAddListener
UIBaseView.OnRemoveListener = OnRemoveListener
UIBaseView.OnDisable = OnDisable
UIBaseView.AddUIListener = AddUIListener
UIBaseView.RemoveUIListener = RemoveUIListener
UIBaseView.OnDestroy = OnDestroy
UIBaseView.CloseSelf = CloseSelf
UIBaseView.GetRecoverParam = GetRecoverParam
UIBaseView.PopSortingOrder = PopSortingOrder
UIBaseView.PushSortingOrder = PushSortingOrder

return UIBaseView