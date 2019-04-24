local table_insert = table.insert
local ConfigUtil = ConfigUtil
local PreloadHelper = PreloadHelper
local PreloadData = PreloadData
local BaseLogicHelper = BaseClass("BaseLogicHelper")

function BaseLogicHelper:__init()
    self.m_preloadList = {}
end

function BaseLogicHelper:AddPreloadObj(path, type, inst_count, pool_noactive)
    table_insert(self.m_preloadList, PreloadData.New(path, type, inst_count, pool_noactive))
end

function BaseLogicHelper:AddWujiangPreloadObj(wujiangID, wuqiLevel, mountID, mountLevel)
    local path, type = PreloadHelper.GetWujiangPath(wujiangID, wuqiLevel)
    self:AddPreloadObj(path, type, 1)

    local callWujiangID = PreloadHelper.GetPreloadWujiang(wujiangID)
    if callWujiangID then
        local path, type = PreloadHelper.GetWujiangPath(callWujiangID, 1)
        self:AddPreloadObj(path, type, 1)
        
        local soundPath = PreloadHelper.GetRoleSoundPath(callWujiangID)    
        if soundPath then
            local path, type = PreloadHelper.GetAssetbundlePath(soundPath)
            self:AddPreloadObj(path, type, 1)
        end
    end

    if mountID > 0 and mountLevel > 0 then
        local path, type = PreloadHelper.GetHorsePath(mountID, mountLevel)
        self:AddPreloadObj(path, type, 1)
    end
  
    local soundPath = PreloadHelper.GetRoleSoundPath(wujiangID)         
    if soundPath then
        local path, type = PreloadHelper.GetAssetbundlePath(soundPath)
        self:AddPreloadObj(path, type, 1)
    end
end

function BaseLogicHelper:AddTimelinePreloadObj(timelineName, timelinePath)
    local timelineConfig = ConfigUtil.GetTimelineCfgByID(timelineName, timelinePath)
    local wavePath, waveType = PreloadHelper.GetTimelinePath(timelineConfig.path)
    self:AddPreloadObj(wavePath, waveType, 1)
    if timelineConfig.load_list then
        for i,loadData in pairs(timelineConfig.load_list) do
            self:AddPreloadObj(loadData.path, PreloadHelper.TYPE_GAMEOBJECT, 1)
        end
    end
end

function BaseLogicHelper:AddDragonTimelinePreloadObj(dragonID)
    local dragonCfg = ConfigUtil.GetGodBeastCfgByID(dragonID)
    if dragonCfg then
        self:AddTimelinePreloadObj(dragonCfg.timelineName, TimelineType.PATH_BATTLE_SCENE)
    end
end

function BaseLogicHelper:GetPreloadList(...)
    self.m_preloadList = {}

    ConfigUtil.GetConfigTbl("Config.Data.lua_skill")
    ConfigUtil.GetConfigTbl("Config.Data.lua_action")
    ConfigUtil.GetConfigTbl("Config.Data.lua_animation")
    require("GameLogic.Battle.Input.ActorSkillInputMgr")
    require("GameLogic.Battle.Input.SkillSelector")
    require("GameLogic.Battle.Camera.fx.ClientSkillCameraFX")
    
    local path, type = PreloadHelper.GetAssetbundlePath('effectcommonmat/materials')
    self:AddPreloadObj(path, type, 1)

    local path, type = PreloadHelper.GetAssetbundlePath('effect/common')
    self:AddPreloadObj(path, type, 1)

    local path, type = PreloadHelper.GetAssetbundlePath('ui/atlas/battledynamicload')
    self:AddPreloadObj(path, type, 1)

    local path, type = PreloadHelper.GetAssetbundlePath('sound/atk')
    self:AddPreloadObj(path, type, 1)

    self:PreloadSelector()

    local effectCfg = ConfigUtil.GetActorEffectCfgByID(29009)
    if effectCfg then
        local path, type = PreloadHelper.GetEffectPath(effectCfg.path)
        self:AddPreloadObj(path, type, 1)
    end

    effectCfg = ConfigUtil.GetActorEffectCfgByID(29010)
    if effectCfg then
        local path, type = PreloadHelper.GetEffectPath(effectCfg.path)
        self:AddPreloadObj(path, type, 1)
    end

    effectCfg = ConfigUtil.GetActorEffectCfgByID(20012)
    if effectCfg then
        local path, type = PreloadHelper.GetEffectPath(effectCfg.path)
        self:AddPreloadObj(path, type, self:PreloadDieFXCount())
    end

    local TheGameIds = TheGameIds

    self:AddPreloadObj(TheGameIds.WorldArtFont, PreloadHelper.TYPE_GAMEOBJECT, self:PreloadWorldArtCount(), true)
    self:AddPreloadObj(TheGameIds.FontPrefabPath, PreloadHelper.TYPE_GAMEOBJECT, self:PreloadFontCount(), true)
    self:AddPreloadObj(TheGameIds.AttrMsgPrefab, PreloadHelper.TYPE_GAMEOBJECT, 2, true)
    self:AddPreloadObj(TheGameIds.BuffMaskPrefab, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskBloodRed, PreloadHelper.TYPE_GAMEOBJECT, 1, true)

    self:AddPreloadObj(TheGameIds.BattleBuffMaskRed, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskPurple, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskGreen, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskYellow, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskBlue, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskGrey, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskGold, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.BattleBuffMaskBlack, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.WaveMsgPrefab, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.FloatSkillMsgLeftPrefab, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.FloatSkillMsgRightPrefab, PreloadHelper.TYPE_GAMEOBJECT, 1, true)
    self:AddPreloadObj(TheGameIds.FloatMsgPrefab, PreloadHelper.TYPE_GAMEOBJECT, 1, true)

    self:AddPreloadObj("UI/Effect/Prefabs/nuqi.prefab", PreloadHelper.TYPE_GAMEOBJECT, 5)
    self:AddPreloadObj("UI/Prefabs/Battle/BloodBarItemPlayer.prefab", PreloadHelper.TYPE_GAMEOBJECT, 5)
    self:AddPreloadObj("UI/Prefabs/Battle/BloodBarItemMonster.prefab", PreloadHelper.TYPE_GAMEOBJECT, 5)
    self:AddPreloadObj("UI/Prefabs/Battle/BattleWujiangItem.prefab", PreloadHelper.TYPE_GAMEOBJECT, 5)

    return self.m_preloadList
end

function BaseLogicHelper:GetMapID(...)
    return 1
end

function BaseLogicHelper:PreloadWorldArtCount()
    return 10
end

function BaseLogicHelper:PreloadFontCount()
    return 30
end

function BaseLogicHelper:PreloadDieFXCount()
    return 1
end

function BaseLogicHelper:PreloadSelector()
    local path, type = PreloadHelper.GetSingleEffectPath('Actor_Select')
    self:AddPreloadObj(path, type, 5)
end

return BaseLogicHelper