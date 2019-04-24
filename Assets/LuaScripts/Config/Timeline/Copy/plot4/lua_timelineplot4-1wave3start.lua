-- 笼罩相机
local config = {

    path = 'Timeline/Copy/plot4/plot4-1wave3start.prefab',
    assetPath = 'Timeline/Copy/plot4/plot4-1wave3start.playable',
	plotLanguage = 'SectionLanguage4',
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
            bindingPath = '20011',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{
            name = 'Animation Track (1)',
			bindingType = 4,
            bindingPath = '20012',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{
            name = 'Animation Track (2)',
			bindingType = 4,
            bindingPath = '20013',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{
		    name = 'Animation Track (3)',
			bindingType = 4,
            bindingPath = '1111',
            bindingWujiangCamp = false,
			bindingWujiangID = false,
            clip_list = {},
		},
		{	
		    name = 'EffectTrack',
			bindingType = 0,
            clipingType = 1,
            clip_list = {
                ["1111_skl11112_hit1"] = {
                    parentType = 1,
                    prefabPath = 'Models/1111/Effect/1111_skl11112_hit.prefab',
                    trackName = "20013",
                },
				["1111_skl11112_hit2"] = {
                    parentType = 1,
                    prefabPath = 'Models/1111/Effect/1111_skl11112_hit.prefab',
                    trackName = "20012",
                },
				["1111_skl11112_hit3"] = {
                    parentType = 1,
                    prefabPath = 'Models/1111/Effect/1111_skl11112_hit.prefab',
                    trackName = "20011",
                },
            },
        },
	},
	load_list = {
        {
            path = "Models/2001/2001_1.prefab",
            createInstance = true,
            name = "20011",
            instancePos = {0, 0, 0},
            instanceRotation = {0, 0, 0},
        },
		{
            path = "Models/2001/2001_1.prefab",
            createInstance = true,
            name = "20012",
            instancePos = {0, 0, 0},
            instanceRotation = {0, 0, 0},
        },
		{
		    path = "Models/2001/2001_1.prefab",
            createInstance = true,
            name = "20013",
            instancePos = {0, 0, 0},
            instanceRotation = {0, 0, 0},
		},
		{
		    path = "Models/1111/1111_3.prefab",
            createInstance = true,
            name = "1111",
            instancePos = {0, 0, 0},
            instanceRotation = {0, 0, 0},
		},
    },
}

return config
