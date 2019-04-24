CommonDefine = {
    -- 1猛将2近卫3豪杰4神射5仙法    坦克：2  后场角色：4 5  前场：1 3
    PROF_1 = 1,
    PROF_2 = 2,
    PROF_3 = 3,
    PROF_4 = 4,
    PROF_5 = 5,

    -- 0全部1魏2蜀3吴4群
    COUNTRY_5 = 0,
    COUNTRY_1 = 1,
    COUNTRY_2 = 2,
    COUNTRY_3 = 3,
    COUNTRY_4 = 4,

    -- 性别
    SEX_1 = 1,
    SEX_2 = 2,

    -- 1~4, N R SR SSR
    WuJiangRareType_1 = 1,
    WuJiangRareType_2 = 2,
    WuJiangRareType_3 = 3,
    WuJiangRareType_4 = 4,

    --一级属性上限
    FIRST_ATTR_MAX = 600,

    --武将等级上限
    WUJIANG_LEVEL_MAX = 80,

    --开发分辨率
    MANUAL_WIDTH = 1600,
    MANUAL_HEIGHT = 960,

    SCREEN_WIDTH = 0,    --游戏中的屏幕逻辑像素宽度
    SCREEN_HEIGHT = 0,   --游戏中的屏幕逻辑像素高度

    --刘海模式
    IS_HAIR_MODEL = false, --true  
    --ORIENTATION_DID_CHANGE = 3, --屏幕朝向: 3 - 向左, 流海在左边 4 - 向右, 流海在右边
    IPHONE_X_OFFSET_LEFT = 0,	--iphonex模式下左边缩进距离
    --IPHONE_X_OFFSET_RIGHT = 0,	--iphonex模式下右边缩进距离
    
    SMALLTHING_CULL_DIS = 50, --小东西层 剔除的距离

    UI_OPEN_MODE_NONE = 0,
    UI_OPEN_MODE_CLEAR = 1, --清除已经有的记录，再把自己加入记录中
    UI_OPEN_MODE_APPEND = 2,--加入
    UI_OPEN_MODE_IGNORE = 3,--忽视

    --1星级 2等级 3突破次数 4稀有度
    WUJIANG_SORT_PRIORITY_1 = 1,
    WUJIANG_SORT_PRIORITY_2 = 2,
    WUJIANG_SORT_PRIORITY_3 = 3,
    WUJIANG_SORT_PRIORITY_4 = 4,

    first_attr_name_list = {
        "tongshuai", "wuli", "zhili", "fangyu"
    },

    second_attr_name_list = {
        "max_hp", "mingzhong", "shanbi", "phy_atk", "magic_atk", "phy_baoji", "magic_baoji", "baoji_hurt", "phy_def", "magic_def",
        "atk_speed", "move_speed", "hp_recover", "nuqi_recover", "init_nuqi", "phy_suckblood", "magic_suckblood", "reduce_cd" },

    mingwen_second_attr_name_list = {
        "max_hp", "mingzhong", "shanbi", "phy_atk", "magic_atk", "phy_baoji", "magic_baoji", "baoji_hurt", "phy_def", "magic_def",
        "atk_speed", "move_speed", "hp_recover", "nuqi_recover", "init_nuqi", "phy_suckblood", "magic_suckblood", "reduce_cd",
        "phy_baoji_rate", "magic_baoji_rate", "shanbi_rate", "mingzhong_rate" },

    qingyuan_second_attr_name_list = {"max_hp", "phy_atk", "phy_def", "magic_atk","magic_def", "phy_baoji", "magic_baoji", "shanbi", "mingzhong",
     "move_speed", "atk_speed", "hp_recover", "nuqi_recover", "init_nuqi", "baoji_hurt", "phy_suckblood", "magic_suckblood", "reduce_cd" },

    colorList = { "ffffff","32b0e4", "e041e6", "e8c04c", "d24643"},
    

    tongshuai = 1,                     --统率
    wuli = 2,                          --武力
    zhili = 3,                         --智力
    fangyu = 4,                        --防御
    battle_attr_min = 5,
    max_hp = 6,	-- 最大血量
	phy_atk = 7,                       -- 物攻
	phy_def = 8,                      -- 物防
	magic_atk = 9,                     -- 魔攻
    magic_def = 10,                    -- 魔防
	phy_baoji = 11,                    -- 物理暴击
	magic_baoji = 12,                  -- 魔法暴击
	shanbi = 13,                       -- 闪避
	mingzhong = 14,                    -- 命中
	move_speed = 15,                    -- 移动速度
	atk_speed = 16,                     -- 攻击速度
	hp_recover = 17,                   -- 生命回复
	nuqi_recover = 18,                 -- 怒气回复
	init_nuqi = 19,                    -- 初始怒气
	baoji_hurt = 20,                   -- 暴伤
	phy_suckblood = 21,                -- 物理吸血
	magic_suckblood = 22,              -- 魔法吸血
    reduce_cd = 23,                    -- 冷却缩减
    phy_baoji_rate = 24,               --物理暴击率
    magic_baoji_rate = 25,             --法术暴击率
    shanbi_rate = 26,                  --闪避率
    mingzhong_rate = 27,               --命中率
    battle_attr_max = 28,

    WUJIANG_STAR_LIMIT = 6, -- 最高星级
    WUJIANG_TOPU_LIMIT = 15, -- 最高突破

    LINEUP_MANAGER_SAVE_COUNT = 5, --阵容管理可以保存的阵容数量
    LINEUP_WUJIANG_COUNT = 5, -- 每个阵容可以上阵的武将数量
    LINEUP_BENCH_COUNT = 2, -- 两个替补
    LINEUP_DRAGON_COUNT = 4, -- 神兽数量
    DRAGON_TELENT_COUNT = 5, -- 神兽天赋数量

    --物品品阶
    ItemStageType_1 = 1,     --1阶(灰)
    ItemStageType_2 = 2,     --2阶(蓝)
    ItemStageType_3 = 3,     --3阶(紫)
    ItemStageType_4 = 4,     --4阶(金)
    ItemStageType_5 = 5,     --5阶(红)


    --铭文类型
    QuanBu = 0,
    GongJi = 1,
    ShengMing = 2,
    FangYu = 3,
    GongNeng = 4,
    XiXie = 5,
    BaoJi = 6,
    GongSu = 7,

    --猎苑状态
    Hunt_AlreadyMaintain = 0,           --已维护
    Hunt_Lock = 1,                      --未解锁
    Hunt_NeedMaintain = 2,              --需维护
    Hunt_Updating_AlreadyMaintain = 3,  --在升级已维护
    Hunt_Updating_NeedMaintain = 4,     --在升级需维护
    Hunt_CanUpdate_AlreadyMaintain = 10,--已维护可升级
    Hunt_CanUpdate_NeedMaintain = 12,   --需维护可升级

    --福利类型 数字需与服务器相同
    FuliType_Qiandao = 1,
    FuliType_Online = 2,
    FuliType_GetStamain = 3,
    FuliType_Regist = 4,
    FuliType_LevelUp = 5,
    FuliType_CDKey = 6,
    FuliType_Fund = 7,

    --活动类型 数字需与服务器相同
    Act_Type_Sngle_Charge = 602,            --单笔充值
    Act_Type_Accumulation_charge = 603,     --累计充值
    Act_Type_Time_Count_Limit_Exchange = 608,-- 限时限量兑换
    Act_Type_Double_Reward = 609,           --双倍奖励
    Act_Type_Stamain_Consume_Return = 610,  --消耗体力返利
    Act_Type_Gold_Consume_Return = 611,     --消耗元宝返利
    Act_Type_Turntable = 620,               --转盘
    Act_Type_Item_Collection = 624,         -- 道具收集 
    Act_Type_Accumulation_Login = 625,      --累计登录天数
    Act_Type_Kth_Day_Login = 633,           --第几天登录
    Act_Type_Duobao = 635,                  --夺宝奇兵
    Act_Type_Wujiang_Levelup = 636,         -- 武将升级 
    Act_Type_Wujiang_Break = 637,           -- 武将突破
    ACT_Type_Group_Charge = 638,            -- 全民首充
    Act_Type_ZheKouShangCheng = 639,        --折扣商城
    Act_Type_JiXingGaoZhao = 701,           --吉星高照

    --活动按钮领取状态
    ACT_BTN_STATUS_UNREACH = 0,             --未达成
    ACT_BTN_STATUS_REACH = 1,               --达成
    ACT_BTN_STATUS_CHARGE = 2,              --前往充值
    ACT_BTN_STATUS_BUY = 3,                 --购买
    ACT_BTN_STATUS_TAKEN = 4,               --已经领取
    ACT_BTN_STATUS_SELLOUT = 5,             --已经售罄
    ACT_BTN_STATUS_BUYYUEKA = 6,            --购买月卡
    ACT_BTN_STATUS_CANSHARE = 7,            --可以分享
    ACT_BTN_STATUS_CANNOTSHARE = 8,         --不可以分享
    ACT_BTN_STATUS_CANEXCHANGE = 9,         --可兑换
    ACT_BTN_STATUS_CANNOTEXCHANGE = 10,     --不可兑换
    ACT_BTN_STATUS_EXPIRED = 11,            --已过期
    ACT_BTN_STATUS_NOTTHETIME = 12,         --未开始
    ACT_BTN_STATUS_EXPIREDANDNOTBUY = 13,   --未购买已过期
    ACT_BTN_STATUS_HASBUY =14,              --已购买
    ACT_BTN_STATUS_HIDE = 15,               --隐藏
    ACT_BTN_STATUS_EXCHANGED = 16,          --已兑换
    ACT_BTN_STATUS_CAN_TRY = 17,            --试试手气
    ACT_BTN_STATUS_GOTO_SHOP = 18,          --前往商城
    ACT_BTN_STATUS_USED = 19,               --已使用
    
    --物品主类型
    ItemMainType_MingQian = 1,       --命签
    ItemMainType_ShenBing = 2,       --神兵
    ItemMainType_Mount = 3,          --坐骑
    ItemMainType_XinWu = 4,          --信物
    ItemMainType_OtherItem = 5,      --杂物
    ItemMainType_LiBao = 6,          --礼包
    ItemMainType_Max = 7,

    --命签子类型
    MingQian_SubType_Tiao = 1,      --命签[条]
    MingQian_SubType_Tong = 2,      --命签[筒]
    MingQian_SubType_Wan = 3,       --命签[万]
    MingQian_SubType_Dong = 4,      --命签[东]
    MingQian_SubType_Nan = 5,       --命签[南]
    MingQian_SubType_Xi = 6,        --命签[西]
    MingQian_SubType_Bei = 7,       --命签[北]
    MingQian_SubType_Zhong = 8,     --命签[中]
    MingQian_SubType_Fa = 9,        --命签[发]
    MingQian_SubType_Bai = 10,      --命签[白]

    OtherItem_SubType_Mingqin = 1,   --随机命签

    --竹 木 铁 金 玉
    MingQian_Stage_1 = 1,
    MingQian_Stage_2 = 2,
    MingQian_Stage_3 = 3,
    MingQian_Stage_4 = 4,
    MingQian_Stage_5 = 5,

    --加入军团是否需要审批
    Need_Apply = 0,
    Not_Apply = 1,

    --坐骑子类型
    Mount_SubType_WhiteHorse = 1,      --坐骑[白马]
    Mount_SubType_RedHorse = 2,         --坐骑[红马]
    Mount_SubType_YeollowHorse = 3,     --坐骑[黄马]
    Mount_SubType_Bear = 4,             --坐骑[熊]
    Mount_SubType_Wolf = 5,             --坐骑[狼]
    Mount_SubType_deer = 6,             --坐骑[鹿]
    Mount_SubType_rhino = 7,            --坐骑[犀牛]

    --信物子类型
    XinWu_SubType_N = 1,        --信物[N]阶
    XinWu_SubType_R = 2,        --信物[R]阶
    XinWu_SubType_SR = 3,       --信物[SR]阶
    XinWu_SubType_SSR = 4,      --信物[SSR]阶

    --物品排序方式
    SortByCountDecrease = 1,    --数量降序
    SortByCountIncrease = 2,    --数量升序
    SortByStageDecrease = 3,    --品阶降序
    SortByStageIncrease = 4,    --品阶升序
    SortByLevelDecrease = 5,    --等级降序
    SortByLevelIncrease = 6,    --等级升序

    --物品变化的原因
    ItemChgReason_Count = 1,     --物品数量发生变化（包括物品从无到有和从有到无）
    ItemChgReason_Lock = 2,      --物品锁的状态发生变化
    ItemChgReason_Vip_Charge = 3, --商城购买

    --闯连营
    CAMPSRUSH_COPY_ID_OFFSET = 66001,

    AWARD_TYPE_ITEM = 0,				--道具
    AWARD_TYPE_HERO = 1,				--武将1
    AWARD_TYPE_SHENBING = 2,            --神兵
    AWARD_TYPE_ZUOQI = 3,               --坐骑

    --4普通，3长老 2副团，1团长
    GUILD_POST_COLONEL = 1,
    GUILD_POST_DEPUTY = 2,
    GUILD_POST_MILITARY = 3,
    GUILD_POST_NORMAL = 4,

    --军团等级上限
    GUILD_LEVEL_LIMIT = 9,

    --1累计贡献降序 2累计贡献升序 3本周贡献降序 4本周贡献升序
    GUILD_TOTAL_DONATION_DESCENDING_ORDER = 1,
    GUILD_TOTAL_DONATION_ASCENDING_ORDER = 2,
    GUILD_WEEKLY_DONATION_DESCENDING_ORDER = 3,
    GUILD_WEEKLY_DONATION_ASCENDING_ORDER = 4,


     --1免费，2铜钱，3元宝
     GUILD_WORSHIP_FREE = 1,
     GUILD_WORSHIP_TONGQIAN = 2,
     GUILD_WORSHIP_YUANBAO = 3,

    ELITE_SWEEP_COUNT_BASE = 3,     -- 精英关卡扫荡次数
    NORMAL_SWEEP_COUNT_BASE = 10,   -- 普通关卡扫荡次数

    SECTION_TYPE_NORMAL = 1,
    SECTION_TYPE_ELITE = 2,

    --坐骑排序
    MOUNT_TYPE_ALL = 23000,
    MOUNT_TYPE_YELLOWHORSE = 23001,
    MOUNT_TYPE_WHITEHORSE = 23002,
    MOUNT_TYPE_REDHORSE = 23003,
    MOUNT_TYPE_RHINO = 23004,
    MOUNT_TYPE_DEER = 23005,
    MOUNT_TYPE_BEAR = 23006,

    --神兵排序 1专属,2全部
    SHENBING_OENPERSONSORT = 1,
    SHENBING_ALLSORT = 2,
    
    --神兵排序 1等级降序, 2等级降序
    SHENBING_LEVEL_DOWN = 1,
    SHENBING_LEVEL_UP = 2,
   
    --神兵铭文品质
    SHENBING_MINGWEN_QUALITY_1 = 1,
    SHENBING_MINGWEN_QUALITY_2 = 2,
    SHENBING_MINGWEN_QUALITY_3 = 3,

    --到达100000转为10万
    CountLimitToText = 100000,

    PROMPT_TYPE_LEVEL_UP = 1, --主公升级
    ARENA_RANK_LEVEL_UP = 2,   --竞技场段位升级
    GUILD_BOSS_BACK_SETTLE = 3,   -- 军团boss
    ENTER_SHENSHOU_COPY = 4,    --进入神兽界面
    GUILD_WAR_OFFENCE_RESULT = 5,  --军团争霸 攻城结果
    LIEZHUAN_INVITE_TEAM = 6,    --三国列传组队邀请
    LIEZHUAN_TEAM_FIGHT_END = 7, --三国列传组队战斗结束

    COMMONRANK_WORLDBOSS_YESTODAY = 1000,
    COMMONRANK_WORLDBOSS_TODAY = 1001,
    COMMONRANK_ARENA = 1005,
    COMMONRANK_CAMPS = 1011,
    COMMONRANK_INSCRIPTIONCOPY = 1012,
    COMMONRANK_GRAVECOPY = 1013,
    COMMONRANK_YUANMEN = 1014,
    COMMONRANK_WUJIANG = 1015,
    COMMONRANK_QUNXIONGZHULU_CROSS = 1015, --群雄逐鹿 世界排名
    COMMONRANK_QUNXIONGZHULU = 1016,       --群雄逐鹿 本服排名

    --聊天类型
    CHAT_TYPE_SYS = 1,      --系统聊天
    CHAT_TYPE_WORLD = 2,    --世界聊天
    CHAT_TYPE_GUILD = 3,    --军团聊天 
    CHAT_TYPE_MAX = 4,

    --聊天信息间隔时间
    CHAT_MSG_INTERVAL_TIME = 30,

    --怪物巢穴章节ID最小值
    MAINLINE_SECTION_MONSTER_HOME = 80001,

    --界面id
    GUILD_VIEW = 1,
    CHAT_VIEW = 2,

    --点将类型
    RT_N_CALL_1 = 1,         
    RT_N_CALL_10 = 2,
    RT_S_CALL_1  = 3,
    RT_S_CALL_10 = 4,
    RT_S_CALL_ITEM = 5,
    
    SHOP_SPECIAL = 1,
    SHOP_ARENA = 2,
    SHOP_GUILD = 3,
    SHOP_QINGYI = 4,
    SHOP_MYSTERY = 5,
    SHOP_QUNXIONGZHULU = 6,
    SHOP_DIANJIANG = 10,

    -- 元宝商店
    VIP_SHOP_YUEKA = 1,
    VIP_SHOP_YUANBAO = 2,
    VIP_SHOP_GIFT = 3,
    VIP_GOODS_TYPE_XINWU = 3,

    --军团争霸战斗状态
    GUILDWAR_STATUS_PREPARE = 1,
    GUILDWAR_STATUS_BATTLE = 2,
    GUILDWAR_STATUS_TRUCE = 3,

    -- 对应 C# enum TextAnchor
    UpperLeft = 0,
    UpperCenter = 1,
    UpperRight = 2,
    MiddleLeft = 3,
    MiddleCenter = 4,
    MiddleRight = 5,
    LowerLeft = 6,
    LowerCenter = 7,
    LowerRight = 8,
 
    -- 服务器状态
    SERVER_WAIT_OPEN = -2,
    SERVER_WEIHU = -1,
    SERVER_LIUCHANG = 0,
    SERVER_BAOMAN = 1, -- 默认爆满
    SERVER_NEW = 2,

    YUANMEN_TASK_TAPE_10 = 10,
    YUANMEN_TASK_TAPE_55 = 55,
    YUANMEN_TASK_TAPE_56 = 56,
    YUANMEN_TASK_TAPE_58 = 58,


    ITEM_TYPE_GRAVECOPY_ID = 28101,               --摸金次数
    ITEM_TYPE_INSCRIPTIONCOPY_ID = 28102,         --铜雀台次数
    ITEM_TYPE_GUILDBOSS_ID = 28103,               --家族boss次数
    ITEM_TYPE_SHENBINGCOPY_ID = 28104,            --神兵次数
    ITEM_TYPE_HORSESHOW_ID = 28105,               --选秀次数
}