-- 笼罩相机
local config = {

    path = 'Timeline/Copy/plot2/plot2-1wave1start.prefab',
    assetPath = 'Timeline/Copy/plot2/plot2-1wave1start.playable',
	plotLanguage = 'SectionLanguage2',
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
			bindingZhuZhanParam = {1001004, 5, 7, 200, 5},
            clip_list = {},
		},
    },
}

return config
