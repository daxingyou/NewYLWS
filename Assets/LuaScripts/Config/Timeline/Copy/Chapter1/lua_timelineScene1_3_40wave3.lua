-- Demo关卡第一波
local config = {

    path = 'Timeline/Copy/Chapter1/Scene1_3_40/Scene1_3_40wave3.prefab',
    assetPath = 'Timeline/Copy/Chapter1/Scene1_3_40/Scene1_3_40wave3.playable',
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
            bindingPath = 'CM vcam13',
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clip_list = {},
        },
        {
		   name = 'Cinemachine Track',
            bindingType = 3,
            bindingPath = false,
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clipingType = 2,
            clip_list = {},
		}
	},	
	
}

return config
