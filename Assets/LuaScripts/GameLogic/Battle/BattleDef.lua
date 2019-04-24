
local FixNewVector3 = FixMath.NewFixVector3

FixVecConst = {
    forward = function() return FixNewVector3(0, 0, 1) end,
    right = function() return FixNewVector3(1, 0, 0) end,
    left = function() return FixNewVector3(-1, 0, 0) end,
    zero = function() return FixNewVector3(0, 0, 0) end,
    one = function() return FixNewVector3(1, 1, 1) end,
    back = function() return FixNewVector3(0, 0, -1) end,
    up = function() return FixNewVector3(0, 1, 0) end,
    down = function() return FixNewVector3(0, -1, 0) end,
    impossible = function() return FixNewVector3(-1000, -1000, -1000) end,
}

BattleEnum = {
    BATTLE_VERSION = 2,

    BattleType_COPY = 1,
    BattleType_ARENA = 2,
    BattleType_BOSS1 = 3,
    BattleType_PLOT = 4,
    BattleType_CAMPSRUSH = 5,
    BattleType_ARENA_DEF = 6,
    BattleType_BOSS2 = 7,
    BattleType_INSCRIPTION = 8,  -- 铜雀台
    BattleType_GRAVE = 9,
    BattleType_GUILD_BOSS = 10,
    BattleType_SHENBING = 11,    
    BattleType_YUANMEN = 12,   --辕门
    BattleType_SHENSHOU = 13,  --神兽
    BattleType_HUARONG_ROAD = 14, --华容道
    BattleType_THOUSAND_MILES = 15, --千里走单骑
    BattleType_FRIEND_CHALLENGE = 16,    --好友切磋
    BattleType_ROB_GUILD_HUSONG = 17, --拦截护送
    BattleType_GUILD_WARCRAFT = 18, --争霸
    BattleType_LIEZHUAN = 19, --三国列传 单人
    BattleType_LIEZHUAN_TEAM = 20, --三国列传 组队
    BattleType_QUNXIONGZHULU = 21, --群雄逐鹿
    BattleType_HORSERACE = 22, --赛马

    BattleType_TEST = 999,

    BattleStatus_NULL = 0,
    BattleStatus_INITED = 1,
    BattleStatus_WAVE_INTERVAL = 2,
    BattleStatus_WAVE_FIGHTING = 3,    
    BattleStatus_FINISH_SHOW = 4, 
    BattleStatus_REQ_SETTLING = 5,
    BattleStatus_CLOSE = 6,

    ActorCamp_LEFT = 1,
    ActorCamp_RIGHT = 2,

    ActorSource_ORIGIN = 0,
    ActorSource_CALLED = 1,
    ActorSource_PLOT = 2,

    BOSSTYPE_INVALID = 0,
    BOSSTYPE_SMALL = 1,
    BOSSTYPE_BIG = 2,

    EventHandle_CONTINUE = 1,
    EventHandle_END = 2,

    ActorState_IDLE = 0,
    ActorState_MOVE = 1,
    ActorState_ATTACK = 2,
    ActorState_DEAD = 3,
    ActorState_HURT = 4,
    ActorState_FILM_MOVE = 5,
    ActorState_RACE_MOVE = 6,
    ActorState_RACE_IDLE = 7,
    ActorState_MAX = 8,

    StateParam_MOVE_POS = 1,
    StateParam_JUMP = 2,
    StateParam_RIDE = 3,
    StateParam_HURT_ACTION = 4,
    StateParam_KEY_INFO = 5,
    StateParam_SKILLID = 6,
    StateParam_EX_NONE = 10,
    StateParam_EX_DAZHAO = 11,
    StateParam_EX_PATH_MOVE = 12,

    PausableReason_EVERY = 0,
    PausableReason_SKILL_PREPARE = 1,
    PausableReason_FREEZE = 2,
    PausableReason_WANT_EXIT = 3,
    PausableReason_SUMMON = 4,
    PausableReason_COMBO = 5,
    PausableReason_BENCH_CREATE = 6,
    PausableReason_FROZEN = 7,

    IdleType_STAND = 0,
    IdleType_STUN = 1,
    IdleType_SLEEP = 2,
    IdleType_WIN = 3,
    IdleType_DOWNJUMP = 4,
    IdleType_FROZEN = 5,

    IdleReason_NORMAL = 1,
    IdleReason_STATUS = 2,

    NuqiReason_ATTACK = 1,
    NuqiReason_ATTACKED = 2,
    NuqiReason_KILL = 3,
    NuqiReason_ROUTINE_RECOVER = 4,
    NuqiReason_STEAL = 5,
    NuqiReason_SKILL_RECOVER = 6,
    NuqiReason_STOLEN = 7,
    NuqiReason_DAZHAO = 8,
    NuqiReason_SKILL = 9,
    NuqiReason_REDUCED = 10,
    -- NuqiReason_STIMULATE = 11,
    -- NuqiReason_STIMULATE_BAOJI = 12,
    NuqiReason_OTHER = 13,

    HPCHGREASON_NONE = 0,
    HPCHGREASON_BY_SKILL = 1,                       -- 技能
    HPCHGREASON_BIND = 2,                           --分担伤害
    HPCHGREASON_GEDANG = 3,                         --格挡
    HPCHGREASON_ROUTINE_RECOVER = 4,                --回合结束恢复
    HPCHGREASON_INTERVAL_BUFF = 5,                  --dot
    HPCHGREASON_BY_ATTACK = 6,                      --普攻
    HPCHGREASON_APPEND = 7,                         --追加
    HPCHGREASON_SELF_HURT = 8,                      --自残
    HPCHGREASON_ABSORB = 9,                         --吸收
    HPCHGREASON_REBOUND = 10,                       --反弹
    HPCHGREASON_KILLSELF = 11,                      --自杀

    HURTTYPE_NONE = 0,
    HURTTYPE_PHY_HURT = 1,                          --物理伤害
    HURTTYPE_MAGIC_HURT = 2,                        --魔法伤害
    HURTTYPE_REAL_HURT = 3,                         --真实伤害
    
    PositionReason_BEATBACK = 1,
    PositionReason_FIX = 2,
    PositionReason_SKILL = 3,
    PositionReason_BORN = 4,
    PositionReason_DEAD = 5,
    PositionReason_HURT_FLY = 6,
    PositionReason_AT_DESTINATION = 7,
    PositionReason_MOVE = 8,

    RotationReason_FIX = 1,
    RotationReason_SKILL = 2,

    AttrReason_NONE = 0,
    AttrReason_SKILL= 1,
    AttrReason_ZHENFA = 2,
    AttrReason_STATUS = 3,
    
    RelationReason_SELECT_TARGET = 1,
    RelationReason_SKILL_RANGE = 2,
    RelationReason_SKILL_OTHER = 3,
    RelationReason_RECOVER = 4,

    RelationType_NORMAL = 1,                   --普通
    RelationType_ENV_INTERACTIVE = 2,          --环境交互
    RelationType_MECHANICAL = 3,               --机械
    RelationType_SON_NONINTERACTIVE = 4,       --不可交互召唤物
    RelationType_PARTNER = 5,                  --助战角色

    ActorConfig_MOVESPEED = 600,
    ActorConfig_ATKSPEED = 100,
    ActorConfig_MAX_NUQI = 1000,

    ROUNDJUDGE_NORMAL = 0,
    ROUNDJUDGE_NON_MINGZHONG = 1,
    ROUNDJUDGE_SHANBI = 2,
    ROUNDJUDGE_BAOJI = 3,
    ROUNDJUDGE_WUDI = 4,
    ROUNDJUDGE_XISHOU = 5,
    ROUNDJUDGE_GEDANG = 6,
    ROUNDJUDGE_IMMUNE = 7,

    FOREVER = 99999999,

    ANIM_IDLE = "idle",
    ANIM_MOVE = "walk",
	ANIM_ATTACK = "atk",
	ANIM_SKILL = "skill",
    ANIM_PREPARE = "prepare",
    ANIM_DAZHAO = "dazhao",
    ANIM_DIE_NONE = "none",
	ANIM_DIE_NORMAL = "die_normal",
	ANIM_DIE_FACEDOWN = "die_facedown",
	ANIM_DIE_FACEUP = "die_faceup",
	ANIM_DIE_FLYBACK = "die_flyback",
	ANIM_DIE_FACELEFT = "die_faceleft",
	ANIM_DIE_FACERIGHT = "die_faceright",
	ANIM_DIE_ROLLUP = "die_rollup",
	ANIM_WIN = "win",
	ANIM_STUN = "stun",                                  
	ANIM_HURT_NORMAL = "hurt",
	ANIM_ACTION = "action",
	ANIM_HURT_UP = "hurt_up",
	ANIM_HURT_DOWN = "hurt_down",
	ANIM_HURT_IN_SKY = "hurt_in_sky",
	ANIM_HURT_DOWN_STAND = "hurt_down_end",
    ANIM_RIDE_WALK = "ride_walk",
    ANIM_RIDE_WALK_EX = "ride_walk_x",
    ANIM_RIDE_IDLE = "ride_idle",
    ANIM_RIDE_IDLE_EX = "ride_idle_x",
    ANIM_SHOWOFF = "showoff",
    ANIM_DAZHAOEND = "dazhaoend",
    ANIM_DIANWEIDAZHAO2 = "skl10171_2",
    -- ANIM_SHOW_IDLE = "showidle",

    DEADMODE_DEFAULT = 0,
    DEADMODE_KEEPBODY = 1,
    DEADMODE_STUN = 2,
    DEADMODE_IDLE = 3,
    DEADMODE_ESCAPE = 4,
    DEADMODE_NODIESHOW = 5,
    DEADMODE_BYEBYE = 6,
    DEADMODE_DISAPPEAR = 7,
    DEADMODE_ZHANGJIAOHUFA = 8,
    DEADMODE_DEPARTURE = 9, -- 离场死亡
    
    ATTACK_WAY_NONE = 0,
    ATTACK_WAY_NORMAL = 1,
    ATTACK_WAY_IN_SKY = 2,
    ATTACK_WAY_FLY_AWAY = 3,
    ATTACK_WAY_BACK = 4,

    AITYPE_MANUAL = 1,
    AITYPE_INITIATE = 2,
    AITYPE_WAIT_ORDER = 3,
    AITYPE_STUPID = 4,
    AITYPE_STAND_BY_DEAD_COUNT = 5,
    AITYPE_DONT_MOVE = 6,
    
    AITYPE_XILIANGEAGLE = 100, -- 西凉训鹰师的鹰
    AITYPE_XILIANGBEAR = 101,  -- 西凉训熊师的熊
    AITYPE_XILIANGWOLF = 102,  -- 西凉将领的狼
    AITYPE_DIAOCHAN = 103,  -- 
    AITYPE_HUNDUN = 104,  -- 
    AITYPE_YUANSHAO = 105,  -- 

    AITYPE_TUKUILEI = 107,  -- 
    AITYPE_LEIDI = 108,  -- 
    AITYPE_GRAVE_THIEF = 109, --盗墓贼
    AITYPE_SUNSHANGXIANG_PET = 110, --
    AITYPE_ZHANGJIAO_HUFA = 111, --
    AITYPE_YUJIN = 112, --
    AITYPE_WENCHOU = 113, --
    AITYPE_YUANSHU = 114, --
    AITYPE_XIAHOUYUANFENSHEN = 115, --夏侯渊分身
    AITYPE_QUESHEN = 116,
    AITYPE_WEIYANWUZU = 117, --魏延武卒
    AITYPE_BAIMAYICONG = 118, --公孙瓒 白马义从
    AITYPE_SHUIXINGYAO = 119, -- 水行妖
    AITYPE_FAZHENG = 120, -- 法正
    AITYPE_GONGSUNZAN = 121, -- 公孙瓒
    AITYPE_LVBU = 122, -- 吕布

    STANDBY_CHECKREASON_MONSTER_DIE = 1,
    STANDBY_CHECKREASON_BOSS_HP = 2,
    STANDBY_CHECKREASON_ENTER_ZONE = 3,

    BLOOD_REASON_ALL = 0,
    BLOOD_REASON_HP_CHG = 1,
    BLOOD_REASON_DAZHAO_PREPARE = 2,
    BLOOD_REASON_DAZHAO = 3,

    PAUSEREASON_EVERY = 1,
    PAUSEREASON_SKILL_PREPARE = 2,
    PAUSEREASON_FREEZE = 3,
    PAUSEREASON_WANT_EXIT = 4,
    PAUSEREASON_SUMMON = 5,
    PAUSEREASON_BENCH_CREATE = 6,
    PAUSEREASON_QUESHEN_SHOW = 7,

    CAMERA_MODE_NORMAL = 1,
    CAMERA_MODE_WIN = 2,
    CAMERA_MODE_LOSE = 3,
    CAMERA_MODE_DOLLY_GROUP = 4, -- dolly group(移动拍摄一组目标,官方demo命名)，用于战斗时看到所有的目标
    CAMERA_MODE_DAZHAO_KILL = 5,
    CAMERA_MODE_BOSS1_NORMAL = 6,
    CAMERA_MODE_DAZHAO_PERFORM = 7, -- 大招执行
    CAMERA_MODE_WUJIANG_REPLACE = 8, -- 替补武将上阵
    CAMERA_MODE_BOSS2_NORMAL = 9, -- 
    CAMERA_MODE_PLOT = 10, -- 剧情
    CAMERA_MODE_WAVE_GO = 11, -- 走过道
    CAMERA_MODE_QUESHEN = 12, -- 走过道

    PLAY_STATE_PAUSED = 0,
    PLAY_STATE_PLAYING = 1,
    PLAY_STATE_DELAYED = 2,

    MASK_MAP_TERRAIN = "Map_terrain",
    MASK_MAP_UNIT = "Map_unit",

    LAYER_STATE_NORMAL = 0,
    LAYER_STATE_FOCUS = 1,
    LAYER_STATE_SECONDARY = 2,
    LAYER_STATE_HIDE = 3,
    LAYER_STATE_BOSSBRIEF = 4,

    ACTOR_BLOOD_REASON_ALL = 0,
    ACTOR_BLOOD_REASON_HP_CHG = 1,
    ACTOR_BLOOD_REASON_DAZHAO_PREPARE = 2,
    ACTOR_BLOOD_REASON_DAZHAO = 3,


    SKILL_INPUT_DEACTIVE_CANCEL = 1,
    SKILL_INPUT_DEACTIVE_RELEASE = 2,

    BATTLE_LOSE_REASON_DEAD = 1,
    BATTLE_LOSE_REASON_TIMEOUT = 2,

    FRAME_CMD_TYPE_SKILL_INPUT_START = 1,
    FRAME_CMD_TYPE_SKILL_INPUT_END = 2,
    FRAME_CMD_TYPE_SUMMON_PERFORM = 3,
    FRAME_CMD_TYPE_AUTO_FIGHT = 4,
    FRAME_CMD_TYPE_CREATE_BENCH = 5,
    FRAME_CMD_TYPE_SELECT_SHENBING = 6,
    FRAME_CMD_TYPE_GUILDBOSS_SYNC_HP = 7,

    CAMERA_ANGLE_NONE = 0,
    CAMERA_ANGLE_20 = 1,
    CAMERA_ANGLE_30 = 2,
    CAMERA_ANGLE_40 = 3,

    
    HURTSTATE_PHASE_NORMAL = 0,
    HURTSTATE_PHASE_INSKY = 1,
    HURTSTATE_PHASE_ONGROUND = 2,
    HURTSTATE_PHASE_ONGROUND_STAND = 3,

    BATTLE_WAVE_COUNT = 3,

    SKILL_MASK_ZHOUYU = 1,
    SKILL_MASK_DIAOCHAN = 2,
    SKILL_MASK_ZHANGLIAO = 3,
    SKILL_MASK_CAIWENJI_PRO = 4,-- 守护
    SKILL_MASK_CAIWENJI_ANG = 5,-- 悲愤
    SKILL_MASK_CAIWENJI_POS = 6,-- 振奋
    SKILL_MASK_HUANGZHONG = 7,-- 黄忠 百中
    SKILL_MASK_DIANWEI = 8,-- 典韦 藩篱
    SKILL_MASK_ZHAOYUN = 9,-- 赵云 断筋
    SKILL_MASK_YUANSHAO = 10,-- 袁绍 三公
    SKILL_MASK_YUANSHU = 11,-- 袁绍 三公
    SKILL_MASK_NANMANJIANGLING = 12,-- 南蛮将领 魂殿
    SKILL_MASK_ZHANGFEI = 13,-- 张飞 死战
    SKILL_MASK_HUANGXIONG = 14,-- 华雄 撕裂
    SKILL_MASK_PANGTONG = 15,-- 庞统 癫狂
    SKILL_MASK_LVBU = 16,-- 吕布

    DRAGON_ACTOR_ID_OFFSET = 6000,

    DRAGON_TALENT_SKILL_YINGKE = 1,
    DRAGON_TALENT_SKILL_ZENGSHANG = 2,
    DRAGON_TALENT_SKILL_ZHINU = 3,
    DRAGON_TALENT_SKILL_BAONU = 4,
    DRAGON_TALENT_SKILL_ZHENGFEN = 5,
    DRAGON_TALENT_SKILL_XUNJIE = 6,
    DRAGON_TALENT_SKILL_JINDUN = 7,
    DRAGON_TALENT_SKILL_CHIHUAN = 8,
    DRAGON_TALENT_SKILL_FANZHEN = 9,
    DRAGON_TALENT_SKILL_DAIZHI = 10,
    DRAGON_TALENT_SKILL_YUWEI = 11,
    DRAGON_TALENT_SKILL_YURE = 12,
    DRAGON_TALENT_SKILL_QINJIN = 13,
    DRAGON_TALENT_SKILL_ZHONGLIAO = 14,
    DRAGON_TALENT_SKILL_SHOUXUE = 15,
    DRAGON_TALENT_SKILL_HAOJIAO = 16,
    DRAGON_TALENT_SKILL_LIEYAN = 17,
    DRAGON_TALENT_SKILL_PIAOYU = 18,
    DRAGON_TALENT_SKILL_FEIYI = 19,
    DRAGON_TALENT_SKILL_LINJIA = 20,

    QUE_SHEN_SHOW_SKILL_TIME = 1600,
    QUE_SHEN_SHOW_TIME = 3000,

    MAXHP_INJURE_PRO_LOSTHP = 1,
    MAXHP_INJURE_PRO_LEFTHP = 2,
    MAXHP_INJURE_PRO_MAXHP = 3,
}

VIDEO_TYPE = 
{
    NORMAL = 0,
    CROSS_SERVER_KINGDOMWAR = 1,    --跨服国战
}