local EffectEnum = EffectEnum
local BattleEnum = BattleEnum
local ConfigUtil = ConfigUtil
local Layers = Layers
local Animal_ROLE_ID = { 
    [4007] = true,
    [4008] = true,
    [4009] = true,
    [3208] = true,
}

ActorUtil = {
    GetDefaultBonePath = function(effectPoint, resID)
        local path = ""
        if effectPoint == EffectEnum.ATTACH_POINT_LHAND then
            path = "Dummy/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 Spine1/Bip001 Neck/Bip001 L Clavicle/Bip001 L UpperArm/Bip001 L Forearm/Bip001 L Hand"
        elseif effectPoint == EffectEnum.ATTACH_POINT_RHAND then
            path = "Dummy/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 Spine1/Bip001 Neck/Bip001 R Clavicle/Bip001 R UpperArm/Bip001 R Forearm/Bip001 R Hand"
        elseif effectPoint == EffectEnum.ATTACH_POINT_BODY then
            path = "hp_middle"
        elseif effectPoint == EffectEnum.ATTACH_POINT_RIGHT_WEAPON then
            path = "Dummy/Wuqi/Bip001 Prop1/Dummy001"

            -- local roleCfg = ConfigUtil.GetWujiangCfgByID(resID)
            -- if roleCfg and roleCfg.rightWeaponPath ~= "" then
            --     path = roleCfg.rightWeaponPath
            -- else
            --     path = "Dummy/Wuqi/Bip001 Prop1/Dummy001"
            -- end
        elseif effectPoint == EffectEnum.ATTACH_POINT_LEFT_WEAPON then
            path = "Dummy/Wuqi/Bip001 Prop2/Dummy001"

            -- local roleCfg = ConfigUtil.GetWujiangCfgByID(resID)
            -- if roleCfg and roleCfg.leftWeaponPath ~= "" then
            --     path = roleCfg.leftWeaponPath
            -- else
            --     path = "Dummy/Wuqi/Bip001 Prop2/Dummy001"
            -- end
        elseif effectPoint == EffectEnum.ATTACH_POINT_SPINE then
            path = "Dummy/Bip001"
        elseif effectPoint == EffectEnum.ATTACH_POINT_PELVIS then
            path = "Dummy/Bip001/Bip001 Pelvis"
        end
        return path
    end,

    GetLayer = function(layerState)
        local layer = Layers.DISAPPEAR

        if layerState == BattleEnum.LAYER_STATE_NORMAL then
            layer = Layers.DISAPPEAR
        elseif layerState == BattleEnum.LAYER_STATE_FOCUS then
            layer = Layers.Skill_Fx_2
        elseif layerState == BattleEnum.LAYER_STATE_SECONDARY then
            layer = Layers.Skill_Fx_1
        elseif layerState == BattleEnum.LAYER_STATE_HIDE then
            layer = Layers.HIDE
        elseif layerState == BattleEnum.LAYER_STATE_BOSSBRIEF then
            layer = Layers.BOSS_BRIEF
        end

        return layer
    end,

    IsAnimal = function(actor)
        if actor then
            local wujiangID = actor:GetWujiangID()
            return Animal_ROLE_ID[wujiangID]
        end
    
        return false
    end,
}