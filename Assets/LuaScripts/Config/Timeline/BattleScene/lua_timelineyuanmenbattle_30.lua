-- Demo关卡第一波
local config = {

    path = 'Timeline/BattleScene/yuanmenbattle_30/yuanmenbattle_30.prefab',
    assetPath = 'Timeline/BattleScene/yuanmenbattle_30/yuanmenbattle_30.playable',
    track_list = {
        {
            name = 'Animation Track',
            bindingType = 4,
            bindingPath = 'sphere',
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clip_list = {},
        },
		{
            name = 'Animation Track (1)',
            bindingType = 4,
            bindingPath = 'CM vcam11',
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clip_list = {},
        }
    },

}

return config
