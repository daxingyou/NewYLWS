--[[
-- added by wsh @ 2017-12-15
-- 场景管理系统：调度和控制场景异步加载以及进度管理，展示loading界面和更新进度条数据，GC、卸载未使用资源等
-- 注意：
-- 1、资源预加载放各个场景类中自行控制
-- 2、场景loading的UI窗口这里统一管理，由于这个窗口很简单，更新进度数据时直接写Model层
--]]
local BattleEnum = BattleEnum
local isEditor = CS.GameUtility.IsEditor()
local AssetBundleConfig = CS.AssetBundles.AssetBundleConfig
local AssetBundleUtility = CS.AssetBundles.AssetBundleUtility
local EditorApplication = CS.UnityEditor.EditorApplication
local SceneManager = BaseClass("SceneManager", Singleton)

-- 构造函数
function SceneManager:__init()
	-- 成员变量
	-- 当前场景
	self.current_scene = nil
	-- 是否忙
	self.busing = false
	-- 场景对象
	self.scenes = {}
end

-- 切换场景：内部使用协程
function SceneManager:CoInnerSwitchScene(scene_config, battleType)
	local start = os.clock()
	-- 打开loading界面
	local uimgr_instance = UIManagerInst
	uimgr_instance:OpenWindow(UIWindowNames.UILoading, battleType)
	local window = uimgr_instance:GetWindow(UIWindowNames.UILoading)
	local View = window.View
	View:SetValue(0)
	coroutine.waitforframes(1)
	-- 清理旧场景
	if self.current_scene then
		self.current_scene:OnLeave()
	end
	View:SetValue(View:GetValue() + 0.01)
	coroutine.waitforframes(1)
	-- 清理UI
	uimgr_instance:DestroyWindowExceptLayer(UILayers.TopLayer)
	uimgr_instance:DestroyWindow(UIWindowNames.UIZhuGongLevelUp)
	View:SetValue(View:GetValue() + 0.01)
	coroutine.waitforframes(1)
	-- 清理资源缓存
	GameObjectPoolInst:Cleanup(true)
	GameObjectPoolNoActiveInst:Cleanup(true)
	View:SetValue(View:GetValue() + 0.01)
	coroutine.waitforframes(1)
	local resInstance = ResourcesManagerInst
	coroutine.yieldstart(resInstance.Cleanup, nil, resInstance)
	View:SetValue(View:GetValue() + 0.01)
	coroutine.waitforframes(1)
	-- 同步加载loading场景
	local scene_mgr = CS.UnityEngine.SceneManagement.SceneManager
	local resources = CS.UnityEngine.Resources
	scene_mgr.LoadScene(SceneConfig.LoadingScene.Level)
	View:SetValue(View:GetValue() + 0.01)
	coroutine.waitforframes(1)

	-- 初始化目标场景
	local logic_scene = self.scenes[scene_config.Type]
	if logic_scene == nil then
		logic_scene = scene_config.Type.New(scene_config)
		self.scenes[scene_config.Type] = logic_scene
	end
	assert(logic_scene ~= nil)
	View:SetValue(View:GetValue() + 0.02)
	coroutine.waitforframes(1)

	Logger.Log("Switch init use " .. Utils.GetExecuteTime(start) .. "ms")
	start = os.clock()

	-- 加载场景AssetBundle
	logic_scene:PreloadScene()
	local cur_progress = View:GetValue()
	coroutine.yieldstart(logic_scene.CoOnPrepare, function(co, progress)
		assert(progress <= 1.0, "Progress should be normalized value!!!")
		View:SetValue(cur_progress + 0.1 * progress)
	end, logic_scene)
	View:SetValue(cur_progress + 0.1)

	Logger.Log("Load scene assetbundle use " .. Utils.GetExecuteTime(start) .. "ms")
	start = os.clock()

	-- 异步加载目标场景
	cur_progress = View:GetValue()
	local asyncOperation = nil
	if scene_config.Name == 'BattleScene' or scene_config.Name == 'HomeScene' or scene_config.Name == 'PlotScene' then
		if isEditor and AssetBundleConfig.IsEditorMode then -- 不使用assetbundle时加载战斗场景
			asyncOperation = EditorApplication.LoadLevelAsyncInPlayMode(logic_scene:GetScenePathOfAsset())
		else -- 使用assetbundle时加载战斗场景
			asyncOperation = scene_mgr.LoadSceneAsync(logic_scene:GetSceneName())
		end
	else -- 其他场景直接添加到工程设置里面，用ID加载
		asyncOperation = scene_mgr.LoadSceneAsync(scene_config.Level)
	end
	coroutine.waitforasyncop(asyncOperation, function(co, progress)
		assert(progress <= 1.0, "What's the funck!!!")
		View:SetValue(cur_progress + 0.15 * progress)
	end)
	View:SetValue(cur_progress + 0.15)
	coroutine.waitforframes(1)

	Logger.Log("Load scene use " .. Utils.GetExecuteTime(start) .. "ms")
	start = os.clock()

	-- GC：交替重复2次，清干净一点
	collectgarbage("collect")
	CS.System.GC.Collect()
	collectgarbage("collect")
	CS.System.GC.Collect()
	cur_progress = View:GetValue()
	coroutine.waitforasyncop(resources.UnloadUnusedAssets(), function(co, progress)
		assert(progress <= 1.0, "What's the funck!!!")
		View:SetValue(cur_progress + 0.1 * progress)
	end)
	View:SetValue(cur_progress + 0.1)
	coroutine.waitforframes(1)

	logic_scene:OnCreate()

	Logger.Log("CleanUp again, use " .. Utils.GetExecuteTime(start) .. "ms")
	start = os.clock()

	-- 准备工作：预加载资源等
	-- 说明：现在的做法是不热更场景（都是空场景），所以主要的加载时间会放在场景资源的prefab上，这里给65%的进度时间
	cur_progress = View:GetValue()
	coroutine.yieldstart(logic_scene.CoOnPrepare, function(co, progress)
		assert(progress <= 1.0, "Progress should be normalized value!!!")
		View:SetValue(cur_progress + 0.55 * progress)
	end, logic_scene)
	View:SetValue(cur_progress + 0.55)
	coroutine.waitforframes(1)
	logic_scene:OnPrepareEnter()
	View:SetValue(1.0)
	coroutine.waitforframes(1)

	self.busing = false
	self.current_scene = logic_scene


	logic_scene:OnEnter()

	coroutine.waitforframes(3)
	-- 加载完成，关闭loading界面
	uimgr_instance:CloseWindow(UIWindowNames.UILoading)
	Logger.Log("Load all assetbundle total use " .. Utils.GetExecuteTime(start) .. "ms")
end

-- 切换场景
function SceneManager:SwitchScene(scene_config, battleType, isReplayVideo)
	assert(scene_config ~= LaunchScene and scene_config ~= LoadingScene)
	assert(scene_config.Type ~= nil)
	if self.busing then 
		return
	end
	if self.current_scene and self.current_scene:Name() == scene_config.Name then
		return
	end
	
	self.busing = true
	
	local function InnerSwitchScene()
		if isReplayVideo then
			local downloadList = {}
			local bRet = self:CheckDownload(scene_config, downloadList, battleType, isReplayVideo)
			if bRet and not GuideMgr:GetInstance():IsPlayingGuide() then
				ABTipsMgr:GetInstance():ShowABLoadTips(downloadList, function ()
					coroutine.start(SceneManager.CoInnerSwitchScene, self, scene_config, battleType)
				end)
			else
				coroutine.start(SceneManager.CoInnerSwitchScene, self, scene_config, battleType)
			end
		else
			coroutine.start(SceneManager.CoInnerSwitchScene, self, scene_config, battleType)
		end
	end

	local uiLoading =  UIManagerInst:GetWindow(UIWindowNames.UILoading)
	if uiLoading then
		uiLoading.View:PreloadLoadingBg(battleType, InnerSwitchScene)
	else
		InnerSwitchScene()
	end
end

function SceneManager:CheckDownload(scene_config, downloadList, battleType, isReplayVideo, ...)
	if isEditor and AssetBundleConfig.IsEditorMode then
        return false
	end
	
	local finalRet = false
	local mapID = 0

	local preloadList = nil
	if scene_config.Name == 'BattleScene' and (not isReplayVideo) then
		local helper = CtlBattleInst:GetLogicHelper(battleType)
		preloadList = helper:GetPreloadList(...)

		mapID = helper:GetMapID(...)
	else
		local logic_scene = self.scenes[scene_config.Type]
		if logic_scene == nil then
			logic_scene = scene_config.Type.New(scene_config)
			self.scenes[scene_config.Type] = logic_scene
		end
		preloadList = logic_scene:GetPreloadList()

		if scene_config.Name == "BattleScene" then
			mapID = CtlBattleInst:GetLogic():GetMapid()
		else
			mapID = logic_scene:GetMapID()
		end
	end

	local abMgrInstance = AssetBundleMgrInst
	for _, item in ipairs(preloadList) do
		local bRet = false
		if item.type == PreloadHelper.TYPE_ASSETBUNDLE then
			local assetbundleName = AssetBundleUtility.AssetBundlePathToAssetBundleName(item.path)
			bRet= abMgrInstance:IsABNeedDownload(assetbundleName, downloadList)
		else
			bRet = abMgrInstance:IsAssetNeedDownload(item.path, downloadList)
		end
		if bRet then
			finalRet = true
		end
	end

	local mapCfg = ConfigUtil.GetMapCfgByID(mapID)
	if mapCfg then
		local bRet = abMgrInstance:IsABNeedDownload(PreloadHelper.GetScenePath(mapCfg), downloadList)
		if bRet then
			finalRet = true
		end
	end
	
	return finalRet
end

-- 析构函数
function SceneManager:__delete()
	for _, scene in pairs(self.scenes) do
		scene:Delete()
	end
end

function SceneManager:IsBattleScene()
	return self.current_scene and self.current_scene:Name() == "BattleScene"
end

function SceneManager:IsHomeScene()
	return self.current_scene and self.current_scene:Name() == "HomeScene"
end

function SceneManager:IsLoginScene()
	return self.current_scene and self.current_scene:Name() == "LoginScene"
end

function SceneManager:IsLoadingScene()
	-- return self.current_scene and self.current_scene:Name() == "LoadingScene"
	return self.busing
end

function SceneManager:CurrSceneName()
	if self.current_scene then
		return self.current_scene:Name()
	end
	return ''
end

function SceneManager:GetSceneAudio()
	if self.current_scene then
		return self.current_scene:GetAudioID()
	end
	return 0
end

return SceneManager