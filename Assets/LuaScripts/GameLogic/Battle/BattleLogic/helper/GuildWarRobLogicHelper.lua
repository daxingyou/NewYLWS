local BaseLogicHelper = require("GameLogic.Battle.BattleLogic.helper.BaseLogicHelper")
local GuildWarRobLogicHelper = BaseClass("GuildWarRobLogicHelper", BaseLogicHelper)
local base = BaseLogicHelper

function GuildWarRobLogicHelper:GetPreloadList(...)
    base.GetPreloadList(self, ...)
    local battleParam = CtlBattleInst:GetLogic():GetBattleParam()

    -- print("battleParam ", table.dump(battleParam))

    local leftWujiangList = battleParam.leftCamp.wujiangList
    for _, oneWujiang in ipairs(leftWujiangList) do
        
        self:AddWujiangPreloadObj(oneWujiang.wujiangID, oneWujiang.wuqiLevel or 1, oneWujiang.mountID, oneWujiang.mountLevel)
    end

    for i = 1, #battleParam.rightCampList do
        local rightCamp = battleParam.rightCampList[i]
        local rightWujiangList = rightCamp.wujiangList
        for _, oneWujiang in ipairs(rightWujiangList) do
            self:AddWujiangPreloadObj(oneWujiang.wujiangID, oneWujiang.wuqiLevel or 1, oneWujiang.mountID, oneWujiang.mountLevel)
        end
    end

    --  timeline预加载 todo
    self:AddTimelinePreloadObj("DollyGroup20", TimelineType.PATH_BATTLE_SCENE)
    self:AddTimelinePreloadObj("DollyGroup30", TimelineType.PATH_BATTLE_SCENE)
    self:AddTimelinePreloadObj("DollyGroup40", TimelineType.PATH_BATTLE_SCENE)

    self:AddTimelinePreloadObj("tongquetai_20", TimelineType.PATH_BATTLE_SCENE)
    self:AddTimelinePreloadObj("tongquetai_30", TimelineType.PATH_BATTLE_SCENE)
    self:AddTimelinePreloadObj("tongquetai_40", TimelineType.PATH_BATTLE_SCENE)

    return self.m_preloadList
end

function GuildWarRobLogicHelper:GetMapID(...)
    return 2003
end

return GuildWarRobLogicHelper