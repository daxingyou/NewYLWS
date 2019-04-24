--[[
-- added by wsh @ 2017-11-30
-- UI管理系统：提供UI操作、UI层级、UI消息、UI资源加载、UI调度、UI缓存等管理
--]]

local Type_Camera = typeof(CS.UnityEngine.Camera)
local Object = CS.UnityEngine.Object
local GameObject = CS.UnityEngine.GameObject
local UILayers = UILayers
local next = next
local table_insert = table.insert
local table_remove = table.remove
local table_indexof = table.indexof
local table_findIndex = table.findIndex
local unpack = unpack or table.unpack
local PointerEventData = CS.UnityEngine.EventSystems.PointerEventData
local EventSystem = CS.UnityEngine.EventSystems.EventSystem

local Messenger = require "Framework.Common.Messenger"
local UIManager = BaseClass("UIManager", Singleton)

-- UIRoot路径
local UIRootPath = "UIRoot"
-- EventSystem路径
local EventSystemPath = "EventSystem"
-- UICamera路径
local UICameraPath = UIRootPath.."/UICamera"
-- 分辨率
local Resolution = Vector2.New(1600, 960)
-- 窗口最大可使用的相对order_in_layer
local MaxOderPerWindow = 10
-- cs Tip
local UINoticeTip = CS.UINoticeTip.Instance

-- 构造函数
local function __init(self)
	-- 成员变量
	-- 消息中心
	self.ui_message_center = Messenger.New()
	-- 所有存活的窗体
	self.windows = {}
	-- 所有可用的层级
	self.layers = {}
	-- 窗口记录队列
	self.__window_stack = {}
	-- 是否启用记录
	self.__enable_record = true
	-- 控制整个UI点击
	self.m_blockRaycastLayer = false
	
	-- 初始化组件
	self.gameObject = GameObject.Find(UIRootPath)
	self.transform = self.gameObject.transform
	self.camera_go = GameObject.Find(UICameraPath)
	self.UICamera = self.camera_go:GetComponent(Type_Camera)
	self.Resolution = Resolution
	self.MaxOderPerWindow = MaxOderPerWindow
	self.m_blockRaycastLayer = GameObject.Find("UIRoot/BlockRaycastLayer")
	Object.DontDestroyOnLoad(self.gameObject)
	local event_system = GameObject.Find(EventSystemPath)
	Object.DontDestroyOnLoad(event_system)
	self.m_loadingUIGO = GameObject.Find("UIRoot/LuanchLayer/UILoading")
	assert(not IsNull(self.transform))
	assert(not IsNull(self.UICamera))

	self.m_pointerEventData = nil

	--self.m_eventSystem = UIUtil.FindComponent(event_system.transform, typeof(CS.UnityEngine.EventSystems.EventSystem))
	-- 初始化层级
	local layers = table.choose(UILayers, function(k, v)
		return type(v) == "table" and v.OrderInLayer ~= nil and v.Name ~= nil and type(v.Name) == "string" and #v.Name > 0
	end)
	table.walksort(layers, function(lkey, rkey)
		return layers[lkey].OrderInLayer < layers[rkey].OrderInLayer
	end, function(index, layer)
		assert(self.layers[layer.Name] == nil, "Aready exist layer : "..layer.Name)
		local go = GameObject(layer.Name)
		local trans = go.transform
		trans:SetParent(self.transform)
		local new_layer = UILayer.New(self, layer.Name)
		new_layer:OnCreate(layer)
		self.layers[layer.Name] = new_layer
	end)
	self:SetUIEnable(true)
end

-- 注册消息
local function AddListener(self, e_type, e_listener)
	self.ui_message_center:AddListener(e_type, e_listener)
end

-- 发送消息
local function Broadcast(self, e_type, ...)
	self.ui_message_center:Broadcast(e_type, ...)
end

-- 注销消息
local function RemoveListener(self, e_type, e_listener)
	self.ui_message_center:RemoveListener(e_type, e_listener)
end

-- 获取窗口
local function GetWindow(self, ui_name, active, view_active)
	local target = self.windows[ui_name]
	if target == nil then
		return nil
	end
	if active ~= nil and target.Active ~= active then
		return nil
	end
	if view_active ~= nil and target.View:GetActive() ~= view_active then
		return nil
	end
	return target
end

-- 初始化窗口
local function InitWindow(self, ui_name, window)
	local config = UIConfig[ui_name]
	assert(config, "No window named : "..ui_name..". You should add it to UIConfig first!")
	
	local layer = self.layers[config.Layer.Name]
	assert(layer, "No layer named : "..config.Layer.Name..".You should create it first!")
	
	window.Name = ui_name
	if config.View then
		local viewClass = require(config.View)
		window.View = viewClass.New(layer, window.Name, config.TweenTargetPath)
	end
	window.Active = false
	window.Layer = layer
	window.PrefabPath = config.PrefabPath
	
	self:Broadcast(UIMessageNames.UIFRAME_ON_WINDOW_CREATE, window)
	return window
end

-- 激活窗口
local function ActivateWindow(self, target, ...)
	assert(target)

	target.View:SetActive(true, ...)
	self:Broadcast(UIMessageNames.UIFRAME_ON_WINDOW_OPEN, target)
	TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_START, target.Name)
end

-- 反激活窗口
local function Deactivate(self, target)
	target.View:SetActive(false)
	self:Broadcast(UIMessageNames.UIFRAME_ON_WINDOW_CLOSE, target)
	TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLOSE_UI_END, target.Name)
end

-- 关闭窗口：私有
local function InnerCloseWindow(self, target)
	assert(target)
	assert(target.View)
	if target.Active then
		target.Active = false
		self:SetWindowParam(target)
		Deactivate(self, target)
	end
end

-- 打开窗口：私有，必要时准备资源
local function InnerOpenWindow(self, target, ...)
	assert(target)
	assert(target.View)

	local layer = UIConfig[target.Name].Layer 
	if layer == UILayers.BackgroudLayer then
		self:CloseWindowByLayer(UILayers.NormalLayer)
		self:CloseWindowByLayer(UILayers.BackgroudLayer)

		self:SetMunuState(target)

		
		self:EnableMainCamera(target.Name == UIWindowNames.UIMain)
	end
	-- 先关闭
	InnerCloseWindow(self, target)
	target.Active = true

	local order = target.Layer:PopWindowOder()
-- Logger.Log(' ---------- ' .. target.Name .. ' : ' .. order)
	ActivateWindow(self, target, order, ...)

    --默认是开启
	if UIConfig[target.Name].NeedOpenAudio == nil then
		target.View:PlayOpenAudio()
	end
	
	-- 窗口记录
	if layer == UILayers.BackgroudLayer or layer == UILayers.NormalLayer then
		self:AddToWindowStack(target.Name)
	end
end

-- 打开窗口：公有
local function OpenWindow(self, ui_name, ...)
	local target = self:GetWindow(ui_name)
	if not target then
		local window = {
			-- 窗口名字
			Name = "Background",
			-- Layer层级
			Layer = UILayers.NormalLayer,
			-- View实例
			View = UIBaseView,
			-- 是否激活
			Active = false,
			-- 预设路径
			PrefabPath = "",
		}
		self.windows[ui_name] = window
		target = InitWindow(self, ui_name, window)
	end

	local has_view = target.View ~= UIBaseView
	local has_prefab_res = target.PrefabPath and #target.PrefabPath > 0
	local has_loaded = not IsNull(target.View.gameObject)
	local need_load = has_view and has_prefab_res and not has_loaded
	
	if not need_load then
		InnerOpenWindow(self, target, ...)
	else
		if ui_name == UIWindowNames.UILoading then
			self:LoadUIComplete(self.m_loadingUIGO, target, ...)
		else
			local params = SafePack(...)
			GameObjectPoolInst:GetGameObjectSync(target.PrefabPath, function(go)
				self:LoadUIComplete(go, target, SafeUnpack(params))
			end)
		end
	end
end

function UIManager:LoadUIComplete(go, target, ...)
	if IsNull(go) then
		return
	end
	
	local trans = go.transform
	trans:SetParent(target.Layer.transform)
	trans.name = target.Name
	
	target.View:OnCreate()
	InnerOpenWindow(self, target, ...)
end

-- 关闭窗口：公有
local function CloseWindow(self, ui_name) 
	local target = self:GetWindow(ui_name, true)
	if not target then
		return
	end

	if UIConfig[target.Name].NeedOpenAudio == nil then
		target.View:PlayCloseAudio()
	end

	InnerCloseWindow(self, target)
	
	-- 窗口记录
	local layer = UIConfig[ui_name].Layer
	if layer == UILayers.BackgroudLayer or layer == UILayers.NormalLayer then
		self:RemoveFormWindowStack(target.Name, true)
	end

	if layer == UILayers.BackgroudLayer then
		self:OpenWindowRecorded()
	end
end

-- 关闭层级所有窗口
local function CloseWindowByLayer(self, layer) 
	for _,v in pairs(self.windows) do
		if v.Layer:GetName() == layer.Name then
			InnerCloseWindow(self, v)
		end
	end
end

-- 关闭其它层级窗口
local function CloseWindowExceptLayer(self, layer) 
	for _,v in pairs(self.windows) do
		if v.Layer:GetName() ~= layer.Name then
			InnerCloseWindow(self, v)
		end
	end
end

function UIManager:CloseWindowExceptMain() 
	for _,v in pairs(self.windows) do
		if v.Name ~= UIWindowNames.UIMainMenu and v.Name ~= UIWindowNames.UIMain and v.Name ~= UIWindowNames.UIServerNotice then
			InnerCloseWindow(self, v)
		end
	end
	self.__window_stack = {}
end

function UIManager:CloseWindowExceptRemain(remainWindowList) 
	for _,v in pairs(self.windows) do
		local isRemain = false
		for _, remainName in ipairs(remainWindowList) do
			if v.Name == remainName then
				isRemain = true
				break
			end
		end
		if not isRemain then
			InnerCloseWindow(self, v)
		end
	end
end

-- 关闭所有窗口
local function CloseAllWindows(self)
	for _,v in pairs(self.windows) do
		InnerCloseWindow(self, v)
	end
end

-- 展示窗口
local function OpenView(self, ui_name, ...)
	local target = self:GetWindow(ui_name)
	assert(target, "Try to show a window that does not exist: "..ui_name)
	if not target.View:GetActive() then
		target.View:SetActive(true)
	end
end

-- 隐藏窗口
local function CloseView(self, ui_name)
	local target = self:GetWindow(ui_name)
	assert(target, "Try to hide a window that does not exist: "..ui_name)
	if target.View:GetActive() then
		target.View:SetActive(false)
	end
end

local function InnerDelete(plugin)
	if plugin.__ctype == ClassType.instance then
		plugin:Delete()
	end
end

local function InnerDestroyWindow(self, ui_name, target)
	self:Broadcast(UIMessageNames.UIFRAME_ON_WINDOW_DESTROY, target)
	-- 说明：一律缓存，如果要真的清理，那是清理缓存时需要管理的功能
	if not IsNull(target.View.gameObject) then -- 加载时会弹出加载提示，如果取消，gameObject是nil
		GameObjectPoolInst:RecycleGameObject(self.windows[ui_name].PrefabPath, target.View.gameObject)
		InnerDelete(target.View)
	end
	self.windows[ui_name] = nil
end

-- 销毁窗口
local function DestroyWindow(self, ui_name)
	local target = self:GetWindow(ui_name)
	if not target then
		return
	end
	
	InnerCloseWindow(self, target)
	InnerDestroyWindow(self, ui_name, target)
end

-- 销毁层级所有窗口
local function DestroyWindowByLayer(self, layer)
	for k,v in pairs(self.windows) do
		if v.Layer:GetName() == layer.Name then
			DestroyWindow(self, v.Name)
		end
	end
end

-- 销毁其它层级窗口
local function DestroyWindowExceptLayer(self, layer)
	for k,v in pairs(self.windows) do
		if v.Layer:GetName() ~= layer.Name then
			DestroyWindow(self, v.Name)
		end
	end
end

-- 销毁所有窗口
local function DestroyAllWindow(self, ui_name)
	for k,v in pairs(self.windows) do
		DestroyWindow(self, v.Name)
	end
end

-- 加入窗口记录栈
local function AddToWindowStack(self, ui_name)
	if not self.__enable_record then
		return
	end

	if not SceneManagerInst:IsHomeScene() then
		return
	end

	local openMode = UIConfig[ui_name].OpenMode
	if openMode == nil then
		openMode = CommonDefine.UI_OPEN_MODE_NONE
	end

	if openMode == CommonDefine.UI_OPEN_MODE_APPEND then
		local findIndex = table_findIndex(self.__window_stack, function(v)
			return v.WindowName == ui_name
		end)
		if findIndex > 0 then
			return  --已有记录，不要去改变记录的顺序
		end
		table_insert(self.__window_stack, self:WindowDataNew(ui_name))

	elseif openMode == CommonDefine.UI_OPEN_MODE_CLEAR then
		self.__window_stack = { self:WindowDataNew(UIWindowNames.UIMain), self:WindowDataNew(ui_name) }
	end
end

-- 从窗口记录栈中移除
local function RemoveFormWindowStack(self, ui_name, only_check_top)
	if not self.__enable_record then
		return
	end

	if not SceneManagerInst:IsHomeScene() then
		return
	end
	
	local findIndex = table_findIndex(self.__window_stack, function(v)
		return v.WindowName == ui_name
	end)
	
	if findIndex == 0 then
		return
	end

	if only_check_top and findIndex ~= #self.__window_stack then
		return
	end
	
	table_remove(self.__window_stack, findIndex)
end

local function CheckWindowIsOpen(self, windowName)
	for i = 1, #self.__window_stack do
		local one_window = self.__window_stack[i]
		if one_window then
			local ui_name = one_window.WindowName
			if uiName and ui_name == windowName then
				return true
			end
		end
	end
	return false
end

-- 获取最后添加的一个背景窗口索引
local function GetLastBgWindowIndexInWindowStack(self)
	local window_stack_count = #self.__window_stack
	for i = window_stack_count, 1, -1 do
		local ui_name = self.__window_stack[i].WindowName
		if UIConfig[ui_name].Layer == UILayers.BackgroudLayer then
			return i
		end
	end

	return -1
end

function UIManager:OpenWindowRecorded()
	if not SceneManagerInst:IsHomeScene() then
		return
	end
	local window_stack_count = #self.__window_stack
	local bg_index = self:GetLastBgWindowIndexInWindowStack()
	if bg_index == -1 then
		-- 没找到背景UI
		if window_stack_count > 0 then
			error("There is something wrong!")
		end
		return
	end
	self.__enable_record = false
	
	for i = bg_index, window_stack_count  do
		local ui_name = self.__window_stack[i].WindowName
		local param = self.__window_stack[i].Param
		
		if param then
			self:OpenWindow(ui_name, unpack(param))
		else
			self:OpenWindow(ui_name)
		end
	end
	self.__enable_record = true
end

function UIManager:OnPromptClear()
	local guideMgrIntance = GuideMgr:GetInstance()
	if Player:GetInstance():IsFirstIn() then
		Player:GetInstance():SetFirstIn(false)
		guideMgrIntance:CheckAndPerformGuide(true)
	else
		guideMgrIntance:CheckAndPerformGuide()
	end
	-- 这个逻辑先去掉了，不清楚这么写是为了什么，现在这样的话引导的时候不打开UI记录会导致从战斗回来主界面都没有的问题
	-- local isGuide = guideMgrIntance:IsPlayingGuide()
	-- if isGuide then
	-- 	self.__window_stack = { self:WindowDataNew(UIWindowNames.UIMain) }
	-- else
		if #self.__window_stack == 0 then
			self.__window_stack = { self:WindowDataNew(UIWindowNames.UIMain) }
		end
		
		if #self.__window_stack > 1 then
			self:OpenWindowRecorded()
		end
	-- end
end

function UIManager:SetMunuState(target)
	if target.View then
		if target.View.IsNeedSetTop then
			local isShowTop = UIConfig[target.Name].IsShowTop
			if isShowTop == nil then
				isShowTop = false
			end
			self:Broadcast(UIMessageNames.MN_MAIN_TOP_STATE, isShowTop)
		end

		if target.View.IsNeedSetRightMenu then
			local isShowRightMenu = UIConfig[target.Name].isShowRightMenu
			if isShowRightMenu == nil then
				isShowRightMenu = false
			end
			self:Broadcast(UIMessageNames.MN_RIGHT_MENU_STATE, isShowRightMenu)
		end
	end
end

-- 获取记录栈
local function GetWindowStack(self)
	return self.__window_stack
end

-- 清空记录栈
local function ClearWindowStack(self)
	self.__window_stack = {}
end


-- 展示Tip：单按钮
local function OpenOneButtonTip(self, title, content, btnText, callback)
	local ui_name = UIWindowNames.UINoticeTip
	local cs_func = UINoticeTip.ShowOneButtonTip
	self:OpenWindow(ui_name, cs_func, title, content, btnText, callback)
end

-- 展示Tip：双按钮
local function OpenTwoButtonTip(self, title, content, btnText1, btnText2, callback1, callback2)
	local ui_name = UIWindowNames.UINoticeTip
	local cs_func = UINoticeTip.ShowTwoButtonTip
	self:OpenWindow(ui_name, cs_func, title, content, btnText1, btnText2, callback1, callback2)
end

-- 隐藏Tip
local function CloseTip(self)
	local ui_name = UIWindowNames.UINoticeTip
	self:CloseWindow(ui_name)
end

-- 等待View层窗口创建完毕（资源加载完毕）：用于协程
local function WaitForViewCreated(self, ui_name)
	local window = self:GetWindow(ui_name, true)
	assert(window ~= nil, "Try to wait for a not opened window : "..ui_name)
	if IsNull(window.View.gameObject) then
		window.View:WaitForCreated()
	end
	return window
end

local function SetUIEnable(self, isEnable)
	if IsNull(self.m_blockRaycastLayer) then
		return
	end

	Logger.Log("SetUIEnable : " .. (isEnable and "true" or "false"))
	self.m_blockRaycastLayer:SetActive(not isEnable)
	UIUtil.SetUIClickable(isEnable)
end

local function GetUICamera(self)
	return self.UICamera
end

function UIManager:GetLastWindowRecord()
	local window_stack_count = #self.__window_stack
	for i = window_stack_count, 1, -1 do
		local ui_name = self.__window_stack[i].WindowName
		if UIConfig[ui_name].Layer == UILayers.BackgroudLayer then
			return ui_name
		end
	end
end

function UIManager:GetRootTrans()
	return self.transform
end

function UIManager:LeaveScene()
	local del = {}
	for i, v in ipairs(self.__window_stack) do
		local config = UIConfig[v.WindowName]
		if config and config.IsClearWhenSceneChg then
			table_insert(del, i)
		end
	end
	
	for i = #del, 1, -1 do
		local index = del[i]
		if self.__window_stack[index] then
			table_remove(self.__window_stack, index)
		end
	end

	self.m_mainCam = nil
	self.m_cinemachineBrain = nil
	self.m_pointerEventData = nil
end

function UIManager:SetWindowParam(target)
	local findIndex = table_findIndex(self.__window_stack, function(v)
		return v.WindowName == target.Name
	end)
	
	if findIndex == 0 then
		return
	end
	
    local windowData = self.__window_stack[findIndex]
	if target.View then
		local param = target.View:GetRecoverParam()
		if param then
			param = { target.View:GetRecoverParam() }
			windowData.Param = param
		end
	end
end

function UIManager:WindowDataNew(windowName, param)
	return { WindowName = windowName, Param = param }
end

function UIManager:IsWindowOpen(uiName)
	local target = self:GetWindow(uiName, true, true)
	return target ~= nil
end

-- 这个会打开一个最顶层的tips窗口
function UIManager:OpenTipsWindow(titleMsg, contentMsg, btn1Msg, btn1Callback, btn2Msg, btn2Callback, closeWhenClickBG)
	if self:IsWindowOpen(UIWindowNames.UITopTipsDialog) then
		return false
	end
	self:OpenWindow(UIWindowNames.UITopTipsDialog, titleMsg, contentMsg, btn1Msg, btn1Callback, btn2Msg, btn2Callback, closeWhenClickBG)
	return true
end

function UIManager:GetScaleRate()
	local layer = self.layers[UILayers.BackgroudLayer.Name]
	return layer:ScaleRate()
end

function UIManager:EnableMainCamera(isEnable)
	if not SceneManagerInst:IsHomeScene() then
		return
	end

	self:GetMainCamera()

	if not IsNull(self.m_mainCam) then
		self.m_mainCam.enabled = isEnable
		if IsNull(self.m_cinemachineBrain) then
			self.m_cinemachineBrain = self.m_mainCam.gameObject:GetComponent(typeof(CS.Cinemachine.CinemachineBrain))
		end
		if not IsNull(self.m_cinemachineBrain) then
			self.m_cinemachineBrain.enabled = isEnable
		end
    end
end

--[[ function UIManager:GetEventSystem()
	return self.m_eventSystem
end ]]

function UIManager:GetCurPointerEventData()
	if not self.m_pointerEventData then
		self.m_pointerEventData = PointerEventData(EventSystem.current)
	end

	return self.m_pointerEventData
end

function UIManager:GetMainCamera()
	if IsNull(self.m_mainCam) then
		local cameraGO = GameObject.Find("FortressMainCamera")
        self.m_mainCam = cameraGO:GetComponent(Type_Camera)
	end

	return self.m_mainCam
end

-- 析构函数
local function __delete(self)
	self.ui_message_center = nil
	self.windows = nil
	self.layers = nil
	self.m_pointerEventData = nil
end

UIManager.__init = __init
UIManager.AddListener = AddListener
UIManager.Broadcast = Broadcast
UIManager.RemoveListener = RemoveListener
UIManager.GetWindow = GetWindow
UIManager.OpenWindow = OpenWindow
UIManager.CloseWindow = CloseWindow
UIManager.CloseWindowByLayer = CloseWindowByLayer
UIManager.CloseWindowExceptLayer = CloseWindowExceptLayer
UIManager.CloseAllWindows = CloseAllWindows
UIManager.OpenView = OpenView
UIManager.CloseView = CloseView
UIManager.DestroyWindow = DestroyWindow
UIManager.DestroyWindowByLayer = DestroyWindowByLayer
UIManager.DestroyWindowExceptLayer = DestroyWindowExceptLayer
UIManager.DestroyAllWindow = DestroyAllWindow
UIManager.AddToWindowStack = AddToWindowStack
UIManager.RemoveFormWindowStack = RemoveFormWindowStack
UIManager.GetLastBgWindowIndexInWindowStack = GetLastBgWindowIndexInWindowStack
UIManager.GetWindowStack = GetWindowStack
UIManager.ClearWindowStack = ClearWindowStack
UIManager.PopWindowStack = PopWindowStack
UIManager.OpenOneButtonTip = OpenOneButtonTip
UIManager.OpenTwoButtonTip = OpenTwoButtonTip
UIManager.CloseTip = CloseTip
UIManager.WaitForViewCreated = WaitForViewCreated
UIManager.GetTipLastClickIndex = GetTipLastClickIndex
UIManager.SetUIEnable = SetUIEnable
UIManager.GetUICamera = GetUICamera
UIManager.CheckWindowIsOpen = CheckWindowIsOpen
UIManager.__delete = __delete

return UIManager