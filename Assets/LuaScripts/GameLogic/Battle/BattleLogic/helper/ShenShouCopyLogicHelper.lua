local BaseLogicHelper = require("GameLogic.Battle.BattleLogic.helper.BaseLogicHelper")
local ShenShouCopyLogicHelper = BaseClass("ShenShouCopyLogicHelper", BaseLogicHelper)
local base = BaseLogicHelper
local BattleEnum = BattleEnum

function ShenShouCopyLogicHelper:GetPreloadList(...)
    base.GetPreloadList(self, ...)
    local copyID = ...
    
    Player:GetInstance():GetLineupMgr():Walk(Utils.GetBuZhenIDByBattleType(BattleEnum.BattleType_SHENSHOU), function(wujiangBriefData)
        self:AddWujiangPreloadObj(wujiangBriefData.id, wujiangBriefData.weaponLevel or 1,
            wujiangBriefData.mountID, wujiangBriefData.mountLevel)
    end)
 
    local copyCfg = ConfigUtil.GetShenshouCopyCfgByID(copyID)
    self:AddWujiangPreloadObj(copyCfg.monsterid, 1, 0, 0)

    local mapCfg = ConfigUtil.GetMapCfgByID(self:GetMapID(...))
    for _, tmName in ipairs(mapCfg.DollyGroupCamera) do
        self:AddTimelinePreloadObj(tmName, TimelineType.PATH_BATTLE_SCENE)
    end

    for _, tmName in ipairs(mapCfg.strGoCameraPath0) do
        self:AddTimelinePreloadObj(tmName, mapCfg.timelinePath)
    end
    
    return self.m_preloadList
end

function ShenShouCopyLogicHelper:GetMapID(...)
    local copyID = ...
    local copyCfg = ConfigUtil.GetShenshouCopyCfgByID(copyID)
    if copyCfg then
        return copyCfg.mapID
    end
    return 5
end

return ShenShouCopyLogicHelper