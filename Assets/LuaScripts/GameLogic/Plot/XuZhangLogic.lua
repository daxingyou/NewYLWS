local Vector4 = Vector4
local isEditor = CS.GameUtility.IsEditor()
local XuZhangLogic = BaseClass("XuZhangLogic", Updatable)
local BattleEnum = BattleEnum

function XuZhangLogic:__init()
    self.m_isAlreadyEnd = false
end

function XuZhangLogic:Start()
    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_PLOT, "Xuzhang", TimelineType.PATH_HOME_SCENE)
end

function XuZhangLogic:Update()
    if BattleCameraMgr:IsCurCameraModeEnd() then
        if not self.m_isAlreadyEnd then
            self.m_isAlreadyEnd = true
            self:StartFight()
        end
	end
	if isEditor then
		if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.F1) then
			SceneManagerInst:SwitchScene(SceneConfig.HomeScene)
		end
	end
end

function XuZhangLogic:StartFight()
	local proto = { wujiang_info_list = {}, copyID = 61001 }
	local wujiangList = {1003, 1001, 1013, 1043, 1111}

	for i = 1,#wujiangList do 
		local wujiangID = wujiangList[i]
		local roleCfg = ConfigUtil.GetWujiangCfgByID(wujiangID)
		local lv = 80
		local pb_wujiang = {
			seq = 1 + i,
			wujiang_id = wujiangID,
			level = lv,
			wuqiLevel = 4,
			lineUpPos = i,
			mountID = 0,
			max_hp = 50000,
			phy_atk = roleCfg.phyAtk * lv,
			phy_def = roleCfg.phyDef,
			magic_atk = roleCfg.magicAtk * lv,
			magic_def = roleCfg.magic_def,
			phy_baoji = roleCfg.phyBaoji,
			magic_baoji = roleCfg.magicBaoji,
			shanbi = roleCfg.shanbi,
			mingzhong = 5000,
			move_speed = roleCfg.moveSpeed,
			atk_speed = roleCfg.atkSpeed,
			hp_recover = roleCfg.hpRecover,
			nuqi_recover = roleCfg.nuqiRecover,
			init_nuqi = 950,
			baoji_hurt = roleCfg.crtihurt,
			phy_baoji_rate = 0,
			magic_baoji_rate = 0,
			shanbi_rate = 0,
			mingzhong_rate = 0,

			skill_list = {},
			atkList = {}
		}

		if roleCfg then
			for i=1,#roleCfg.atkList do
				table.insert(pb_wujiang.skill_list, { skill_id = roleCfg.atkList[i], skill_level = 1 })
			end

			for i=1,#roleCfg.skillList do
				table.insert(pb_wujiang.skill_list, { skill_id = roleCfg.skillList[i], skill_level = 5 })
			end
		end

		table.insert(proto.wujiang_info_list, pb_wujiang)
	end
	
	CtlBattleInst:EnterPlot(proto)
end

return XuZhangLogic