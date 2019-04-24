-- 笼罩相机
local config = {

    path = 'Timeline/Copy/plot3/plot3-4wave3end.prefab',
    assetPath = 'Timeline/Copy/plot3/plot3-4wave3end.playable',
	plotLanguage = 'SectionLanguage3',
    track_list = {
        {
		    name = 'Cinemachine Track',
            bindingType = 3,
            bindingPath = false,
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clipingType = 2,
            clip_list = {},
		},
		{	
		    name = 'Animation Track',
			bindingType = 4,
            bindingPath = '1044',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{
            name = 'Animation Track (1)',
			bindingType = 4,
            bindingPath = '1041',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{
            name = 'Animation Track (2)',
			bindingType = 4,
            bindingPath = '1046',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{
		    name = 'Custom Anim Track',
			bindingType = 4,
            bindingPath = '1044',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{
		    name = 'Custom Anim Track (1)',
			bindingType = 4,
            bindingPath = '1041',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{	
		    name = 'EffectTrack',
			bindingType = 0,
            clipingType = 1,
            clip_list = {
                ["1044_skl10442_hit"] = {
                    parentType = 1,
                    prefabPath = 'Models/1044/Effect/1044_skl10442_hit.prefab',
                    trackName = "1041",
                },
            },
        },
		{	
		    name = 'EffectTrack',
			bindingType = 0,
            clipingType = 1,
            clip_list = {
                ["1044_showoff"] = {
                    parentType = 1,
                    prefabPath = 'Models/1044/Effect/1044_showoff.prefab',
                    trackName = "1044",
                },
            },
        },
	},
	load_list = {
        {
            path = "Models/1044/1044_3.prefab",
            createInstance = true,
            name = "1044",
            instancePos = {0, 0, 0},
            instanceRotation = {0, 0, 0},
        },
		{
            path = "Models/1041/1041_3.prefab",
            createInstance = true,
            name = "1041",
            instancePos = {0, 0, 0},
            instanceRotation = {0, 0, 0},
        },
		{
		    path = "Models/1046/1046_3.prefab",
            createInstance = true,
            name = "1046",
            instancePos = {0, 0, 0},
            instanceRotation = {0, 0, 0},
		},
    },
}

return config
