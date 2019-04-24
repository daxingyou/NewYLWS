local ConfigUtil = ConfigUtil
local string_format = string.format

PreloadData = BaseClass("PreloadData")
function PreloadData:__init(path, type, instcount, pool_noactive)
    self.path = path
    self.type = type
    self.instCount = instcount or 1
    self.pool_noactive = pool_noactive
end

local PreloadWujiang = {
    [2043] = 4007,
    [2044] = 4008,
    [2004] = 2046,
    [1038] = 3208,
    [1044] = 2097,
    [1009] = 4015,
    [1205] = 3207,
    [2010] = 4009,
    [1044] = 2097,
    [2004] = 2046,
    [2070] = 2061,
    [2089] = 2061,
}

local PetWujiang = {
    [1038] = 3208,
}

local WujiangIDPrefabMap = {
    [2032] = "Models/2031/Prefabs/2031_lefthand.prefab", 
    [2033] = "Models/2031/Prefabs/2031_righthand.prefab", 
    [4014] = "Models/2034/Effect/2034_skl9012_hexin02.prefab", 
    [4013] = "Models/2034/Effect/2034_skl9012_hexin01.prefab", 
    [3501] = "Models/3501/Prefabs/3501.prefab", 
    [3502] = "Models/3502/Prefabs/3502.prefab", 
    [3503] = "Models/3503/Prefabs/3503.prefab", 
    [3506] = "Models/3506/Prefabs/3506.prefab", 
    [6002] = "Models/6001/6002_1.prefab", 
    [6003] = "Models/6001/6003_1.prefab", 
    [6015] = "Models/1015/1015_fenshen_",  
    [6010] = "Models/6011/6010_1.prefab", 
}

local WujiangIDReplaceMap = {
    [2093] = 2005,
    [1203] = 2001,
    [2095] = 2027,
    [2096] = 2028,
    [2092] = 2010,
    [2085] = 2069,
    [2086] = 2012,
    [2087] = 2013,
    [2088] = 2057,
    [2089] = 2070,
    [2090] = 2014,
    [2091] = 2040,
    [2201] = 2200,
}

PreloadHelper = {
    TYPE_GAMEOBJECT = typeof(CS.UnityEngine.GameObject),
    TYPE_TEXTURE2D = typeof(CS.UnityEngine.Texture2D),
    TYPE_MATERIAL = typeof(CS.UnityEngine.Material),
    TYPE_ASSETBUNDLE = typeof(CS.UnityEngine.AssetBundle),
    TYPE_AudioClip = typeof(CS.UnityEngine.AudioClip),

    WuqiLevelToResLevel = function(wuqiLevel)
        if wuqiLevel <= 4 then
            return 1
        elseif wuqiLevel >= 5 and wuqiLevel <= 9 then
            return 2
        elseif wuqiLevel >= 10 and wuqiLevel <= 14 then
            return 3
        else
            return 4
        end
    end,
    
    GetPreloadWujiang = function(wujiangID)
        return PreloadWujiang[wujiangID]
    end,

    GetPet = function(wujiangID)
        return PetWujiang[wujiangID]
    end,

    -- return : path, type 
    GetWujiangPath = function(wujiangID, wuqiLevel)
        if not wuqiLevel or wuqiLevel <= 0 then 
            wuqiLevel = 1
        end

        wuqiLevel = PreloadHelper.WuqiLevelToResLevel(wuqiLevel)

        local path = WujiangIDPrefabMap[wujiangID]
        if path then
            if wujiangID == 6015 then
                path = string_format('%s%d.prefab',path, wuqiLevel)
            end
            return path, PreloadHelper.TYPE_GAMEOBJECT
        else
            local realWujiangID = WujiangIDReplaceMap[wujiangID]
            if not realWujiangID then
                realWujiangID = wujiangID
            end

            return string_format("Models/%d/%d_%d.prefab", realWujiangID, realWujiangID, wuqiLevel), PreloadHelper.TYPE_GAMEOBJECT
        end
    end,

    GetScenePath = function(mapcfg)
        return mapcfg.scenepath..mapcfg.scenename..".unity"
    end,

    GetLightmapPath = function(path)
        return path, PreloadHelper.TYPE_TEXTURE2D
    end,

    GetSkyboxPath = function(path)
        return path, PreloadHelper.TYPE_MATERIAL
    end,

    GetAssetbundlePath = function(path)
        return path, PreloadHelper.TYPE_ASSETBUNDLE
    end,

    GetRoleSoundPath = function(wujiangID)
        if wujiangID == 9999 then
            return nil
        end
        
        local realWujiangID = WujiangIDReplaceMap[wujiangID]
        if not realWujiangID then
            realWujiangID = wujiangID
        end
        return string_format("Sound/Role/%d", realWujiangID)
    end,

    GetSingleEffectPath = function(effectName)
        return "Effect/Prefab/"..effectName..".prefab", PreloadHelper.TYPE_GAMEOBJECT
    end,

    GetObjectPath = function(objectCfg)
        return objectCfg.path..".prefab", PreloadHelper.TYPE_GAMEOBJECT
    end,

    GetTimelinePath = function(path)
        return path, PreloadHelper.TYPE_GAMEOBJECT
    end,

    GetAudioPath = function(audioCfg)
        return audioCfg.path..'.'..audioCfg.suffix, PreloadHelper.TYPE_AudioClip
    end,

    GetEffectPath = function(path)
        return path..".prefab", PreloadHelper.TYPE_GAMEOBJECT
    end,

    GetHorsePath = function(horseID, horseLevel)  --这是真实的坐骑等级,
        local mountCfg = ConfigUtil.GetZuoQiCfgByID(horseID)
        if not mountCfg then
            Logger.LogError("not find mountCfg")
            return
        end
        return string_format("Horses/%d/Prefabs/%d.prefab", mountCfg.res_id, mountCfg.res_id*10+horseLevel), PreloadHelper.TYPE_GAMEOBJECT
    end,

    GetShowoffHorsePath = function(horseID, horseLevel)  --这是真实的坐骑等级,  todo
        local mountCfg = ConfigUtil.GetZuoQiCfgByID(horseID)
        if not mountCfg then
            Logger.LogError("not find mountCfg")
            return
        end
        return string_format("Horses/%d/Prefabs/%d_showoff.prefab", mountCfg.res_id, mountCfg.res_id*10+horseLevel), PreloadHelper.TYPE_GAMEOBJECT
    end,

    GetWeaponPath = function(wujiangID, wuqiLevel)  --这是真实的神兵等级, 0 - 15
        local resPath = ""   --右武器
        local resPath2 = ""  --左武器
        local exPath = ''

        local isMutiWeapon = false

        wuqiLevel = PreloadHelper.WuqiLevelToResLevel(wuqiLevel)
        
        --特殊逻辑

        if wujiangID == 1001 and wuqiLevel == 4 then
            resPath = string_format("Models/%d/%d_wuqi_%d_1.prefab", wujiangID, wujiangID, wuqiLevel)
            resPath2 = string_format("Models/%d/%d_wuqi_%d_2.prefab", wujiangID, wujiangID, wuqiLevel)

        elseif wujiangID == 1076 then
            resPath = string_format("Models/%d/%d_wuqi_%d.prefab", wujiangID, wujiangID, wuqiLevel)
            resPath2 = string_format("Models/%d/%d_dun_%d.prefab", wujiangID, wujiangID, wuqiLevel)

        else
            resPath = string_format("Models/%d/%d_wuqi_%d.prefab", wujiangID, wujiangID, wuqiLevel)
            resPath2 = string_format("Models/%d/%d_wuqi_%d.prefab", wujiangID, wujiangID, wuqiLevel)
        end

        if wujiangID == 1038 then
            exPath = string_format("Models/%d/%d_guajian_%d.prefab", wujiangID, wujiangID, wuqiLevel)
        end

        return resPath, resPath2, exPath, PreloadHelper.TYPE_GAMEOBJECT
    end,

    GetShowOffWuJiangPath = function(wujiangID)
        if wujiangID then
            local realWujiangID = WujiangIDReplaceMap[wujiangID]
            if not realWujiangID then
                realWujiangID = wujiangID
            end

            return string_format("Models/%d/%d_showoff.prefab", realWujiangID, realWujiangID)
        end
        return nil
    end,

    GetExWeaponPoint = function(wujiangID)
        if wujiangID == 1038 then
            return 'Dummy/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 L Thigh/point_guajian'
        end
        return nil
    end,

    GetWuJiangResID = function(wujiangID)
        local realWujiangID = WujiangIDReplaceMap[wujiangID]
        if not realWujiangID then
            realWujiangID = wujiangID
        end

        return realWujiangID
    end,

    GetRideIdleAnim = function(horseID)
        if horseID == CommonDefine.MOUNT_TYPE_BEAR or horseID == CommonDefine.MOUNT_TYPE_RHINO then
            return BattleEnum.ANIM_RIDE_IDLE_EX
        else
            return BattleEnum.ANIM_RIDE_IDLE
        end
    end,

    GetRideWalkAnim = function(horseID)
        if horseID == CommonDefine.MOUNT_TYPE_BEAR or horseID == CommonDefine.MOUNT_TYPE_RHINO then
            return BattleEnum.ANIM_RIDE_WALK_EX
        else
            return BattleEnum.ANIM_RIDE_WALK
        end
    end,

    RoleBgPath = "Maps/CharScn/CharScn.prefab",
}