-- Demo关卡第一波
local config = {

    path = 'Timeline/BattleScene/Tomb_30/Tomb_30wave1.prefab',
    assetPath = 'Timeline/BattleScene/Tomb_30/Tomb_30wave1.playable',
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
