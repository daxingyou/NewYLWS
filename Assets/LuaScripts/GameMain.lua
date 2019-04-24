-- 全局模块
require "Global.Global"
	
-- 定义为全局模块，整个lua程序的入口类
GameMain = {};

-- 全局初始化
local function Initilize()
	local loadingAssetbundlePath = "UI/Prefabs/Loading"
	ResourcesManagerInst:CoLoadAssetBundleAsync(loadingAssetbundlePath)
end

-- 进入游戏
local function EnterGame()
	SceneManagerInst:SwitchScene(SceneConfig.LoginScene)
	CS.UnityEngine.Application.targetFrameRate = 30
	CS.UnityEngine.Screen.sleepTimeout = -1 --SleepTimeout.NeverSleep

	UILogicUtil.CalcScreen()
	UILogicUtil.CheckNeedHair()
end

-- Update回调
local function UpdateHandle(self)
	if GameMain.m_updater then
		GameMain.m_updater:Update()
	end
	AssetBundleMgrInst:Update()
end

local function StartUpdater()
	Logger.Log("GameMain StartUpdater")
	TimerManager:GetInstance():Startup()

    GameMain.m_updateHandle = UpdateBeat:CreateListener(UpdateHandle, GameMain)
	UpdateBeat:AddListener(GameMain.m_updateHandle)

    local updaterClass = require "GameLogic.GameLaunch.AssetbundleUpdater"
    GameMain.m_updater = updaterClass.New()
	GameMain.m_updater:Init()
	coroutine.start(GameMain.m_updater.Start, GameMain.m_updater)
end

--主入口函数。从这里开始lua逻辑
local function Start()
	Logger.Log("GameMain start...")

	if GameMain.m_updateHandle ~= nil then
		UpdateBeat:RemoveListener(GameMain.m_updateHandle)
		GameMain.m_updateHandle = nil
	end

	-- 模块启动
	UpdateManager:GetInstance():Startup()
	LogicUpdater:GetInstance():Startup()
	
	if Config.Debug then
		-- 单元测试
		local UnitTest = require "UnitTest.UnitTestMain"
		UnitTest.Run()
	end
	
	coroutine.start(function()
		Initilize()
		EnterGame()
	end)
end

-- 场景切换通知
local function OnLevelWasLoaded(level)
	collectgarbage("collect")
	Time.timeSinceLevelLoad = 0
end

local function OnApplicationQuit()
	-- 模块注销
	UpdateManager:GetInstance():Dispose()
	TimerManager:GetInstance():Dispose()
	LogicUpdater:GetInstance():Dispose()
	FrameDebuggerInst:Dispose()
	HallConnector:GetInstance():Disconnect()
end

local function OnApplicationPause(isPause)
	NetMonitor:GetInstance():OnApplicationPause(isPause)
end

-- GameMain公共接口，其它的一律为私有接口，只能在本模块访问
GameMain.Start = Start
GameMain.StartUpdater = StartUpdater
GameMain.OnLevelWasLoaded = OnLevelWasLoaded
GameMain.OnApplicationQuit = OnApplicationQuit
GameMain.OnApplicationPause = OnApplicationPause

return GameMain