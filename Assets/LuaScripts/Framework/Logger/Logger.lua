--[[
-- added by wsh @ 2017-11-30
-- Logger系统：Lua中所有错误日志输出均使用本脚本接口，以便上报服务器
--]]
local unity_logger = CS.Logger
local Logger = BaseClass("Logger")

local function Init(clientResVersion)
	unity_logger.clientVerstion = clientResVersion
end

local function SetReportUri(uri)
	unity_logger.errorReportUri = uri
end

local function Log(msg)
	if Config.Debug then
		CS.Logger.Log(debug.traceback(msg, 2))
	end
end

local function LogError(msg)
	if Config.Debug then
		error(msg, 2)
	else
		CS.Logger.LogError(debug.traceback(msg, 2))
	end
end

-- 重定向event错误处理函数
event_err_handle = function(msg)
	LogError(msg)
end

Logger.Init = Init
Logger.SetReportUri = SetReportUri
Logger.Log = Log
Logger.LogError = LogError

return Logger