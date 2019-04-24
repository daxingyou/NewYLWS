-- 笼罩相机
local config = {

    path = 'Timeline/Copy/plot4/plot4-2wave3start.prefab',
    assetPath = 'Timeline/Copy/plot4/plot4-2wave3start.playable',
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
		    bindingType = 5,
			bindingZhuZhanParam = {1001111, 5, 20, 200, 5},
            clip_list = {},
		},
		{   
		    name = 'Custom Anim Track',	
		    bindingType = 2,
			bindingWujiangCamp = 1,
			bindingWujiangID = 1111,
            clip_list = {},
		},
    },
}

return config
