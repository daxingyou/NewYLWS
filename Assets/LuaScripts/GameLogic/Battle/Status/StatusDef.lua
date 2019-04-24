
StatusEnum = {
    STATUSTYPE_HP = 1,            -- 一次性改血效果
    STATUSTYPE_CHAOFENG = 2,          -- 嘲讽
    STATUSTYPE_STUN = 3,              -- 眩晕
    STATUSTYPE_DINGSHEN = 4,          -- 定身
    STATUSTYPE_ATTRBUFF = 5,          -- 修改属性
    STATUSTYPE_WEAK = 6,              -- 修改属性
    STATUSTYPE_FROZEN = 7,            -- 冰冻
    STATUSTYPE_WUDI = 8,              -- 无敌
    STATUSTYPE_IMMUNE = 9,            -- 免疫
    STAUTSTYPE_INTERVAL_HP = 10,      -- 定时修改HP
    STAUTSTYPE_BEHURTCHGPERCENT = 12,
    STAUTSTYPE_HURTOTHERCHGPERCENT = 13,
    STAUTSTYPE_NEXT_N_BEHURTCHGPERCENT = 14,
    STAUTSTYPE_NEXT_N_HURTOTHERCHGPERCENT = 15,
    STATUSTYPE_ONCE = 16,
    STATUSTYPE_DELAY_HURT = 17,
    STATUSTYPE_SILENT = 18,
    STATUSTYPE_SLEEP = 19,
    STATUSTYPE_FEAR = 20,              --恐惧
    
    STATUSTYPE_ALLSHIELD = 21,          -- 不带时间的全效护盾
    STATUSTYPE_ALLTIMESHIELD = 22,     -- 带时间的全效护盾
    STATUSTYPE_MAGICSHIELD = 23,     -- 不带时间的魔法护盾
    STATUSTYPE_MAGICTIMESHIELD = 24,     -- 带时间的魔法护盾
    STATUSTYPE_DONGZHUOFIREBUFF = 25,     -- 董卓
    STATUSTYPE_INSCRIPTIONBUFF = 26,     -- 命签 50038
    STAUTSTYPE_DAQIAO_INTERVAL_HP = 27,
    STAUTSTYPE_ZHOUYUBUFF = 28,      
    STATUSTYPE_CAOCAOBUFF = 29,
    STATUSTYPE_FANTAN = 30, --反弹
    STATUSTYPE_TAISHICISHIELD = 31, --反弹
    STATUSTYPE_TAISHICIIMMUNE = 32,            -- 免疫
    STAUTSTYPE_INTERVAL_HP_20111 = 33,        --青州弓箭兵 间隔流血
    STATUSTYPE_BEATFLY = 34,              --击飞

    STATUSTYPE_XILIANGWEAK = 100,      --西凉弱化
    STATUSTYPE_XILIANGDOT = 101,       --西凉诅咒
    STAUTSTYPE_NEXT_N_HURTOTHERMUL = 102,--西凉祝福(调整下次伤害百分比)
    STATUSTYPE_HUANGJINDAODUN_DEFENSIVESTATE = 103,--黄巾刀盾兵 防御姿态 (调整下次伤害百分比)
    STATUSTYPE_IMMUNENEXTCONTROL = 104,-- 免疫下次控制
    STATUSTYPE_IMMUNEINTERVALCONTROL = 105,-- 间隔免疫控制
    STATUSTYPE_DIAOCHANMARK = 106,-- 貂蝉印记
    STATUSTYPE_ZHANGFEIDEF = 107,-- 张飞减伤
    STATUSTYPE_YUANSHAOHAOLING = 108,-- 袁绍号令
    STAUTSTYPE_NEXT_NTIME_BEHURTMUL = 109, -- 时间 n 内，受到伤害调整
    STAUTSTYPE_YUANSHAOIMMUNEPOSITIVE = 110, -- 袁绍 使敌方无法加增益buff
    STATUSTYPE_ZHAOYUNWUDI = 111,              -- 赵云无敌
    STAUTSTYPE_INTERVAL_NUQI = 112,      -- 定时修改怒气   -- 未完成
    STATUSTYPE_LANGSHEMARK = 113,-- 黄巾弓箭手浪射计次标记
    STATUSTYPE_PALSY = 114,-- 麻痹状态
    STATUSTYPE_HURXIONG_DEBUFF = 115,-- 华雄debuff 回复血量减少
    STATUSTYPE_JIAXU_DEBUFF = 116,-- 贾诩debuff 毒雾
    STATUSTYPE_JIAXU_BUFF = 117,-- 贾诩buff 提升法攻
    STATUSTYPE_LIDIAN_DEBUFF = 118,-- 李典debuff
    STATUSTYPE_HORSE_BUFF = 119,-- 坐骑 60001
    STATUSTYPE_QINGLONGMARK = 120,  -- 青龙反弹伤害印记
    STATUSTYPE_XUANWUALLTIMESHIELD = 121,   --玄武全效护盾
    STATUSTYPE_XUANWUCURSE = 122,   --玄武诅咒
    STATUSTYPE_XIAHOUDUN_SHIELD = 123,-- 夏侯惇护盾
    STATUSTYPE_YANGLIANG_CANREN = 124,-- 颜良残暴之刃
    STATUSTYPE_DIANWEITIELI = 126,   --典韦 铁之藩篱
    STATUSTYPE_YUJINMARK = 127,-- 于禁印记
    STATUSTYPE_YANGLIANG_FENJIA = 128,-- 颜良焚甲
    STATUSTYPE_WENCHOUMARK   = 129,-- 文丑印记
    STATUSTYPE_WENCHOUCHOUXUE = 130,-- 文丑抽血
    STATUSTYPE_SLOW = 131,-- 迟缓
    STATUSTYPE_YUANSHUSHIBINGCURSE = 125,   --袁术蚀兵诅咒
    STATUSTYPE_YUANSHUSHIJIACURSE = 132,   --袁术蚀甲诅咒
    STATUSTYPE_YUANSHUSHIHUNCURSE = 133,   --袁术蚀魂诅咒
    STATUSTYPE_YUANSHUSHILONG = 134,   --袁术蚀龙护体
    STATUSTYPE_LUSUALLSHIELDJIANGDONG = 135,   --鲁肃全效护盾江东之壁
    STATUSTYPE_LUSUALLSHIELDLESHAN = 136,   --鲁肃全效护盾乐善好施
    STATUSTYPE_XIAHOUYUANDEBUFF = 137,   --夏侯渊 失神状态
    STATUSTYPE_GONGSUNZANBUFF = 138,   --公孙瓒buff
    STATUSTYPE_MANWANGBUFF = 139,   --南蛮藤甲兵buff
    STAUTSTYPE_NEXT_NTIME_HURTOTHERMUL = 140, --时间n内，造成伤害调整
    STAUTSTYPE_NEXT_N_BEHURTCHG = 141,  --下N次受伤结果修正为特定值
    STAUTSTYPE_XUEDIJUDUN_SHIELD = 142, --雪地巨盾 护盾
    STAUTSTYPE_NANMANBUFF = 143, --南蛮弯刀手 武器精通 buff
    STATUSTYPE_MAXHP_SHIELD = 144,   --抵挡自身最大生命值 x% 的护盾
    STATUSTYPE_PANGTONGTIESUOMARK = 145,    -- 庞统 横铁锁
    STATUSTYPE_RECOVER_PERCENT = 146,      -- 治疗倍数
    STAUTSTYPE_XUNYU_INTERVAL_HP = 147,
    STATUSTYPE_XUNYUIMMUNE = 148,            -- 荀彧免疫
    STATUSTYPE_FROZEN_END = 149,            --冰凍結束時
    STATUSTYPE_BINGSHUANGBOMB = 150,       -- 雪地诡术师 冰霜炸弹
    STATUSTYPE_GUISHU = 151,       -- 雪地诡术师 奇诡之术
    STATUSTYPE_FENGLEICHI = 152,       -- 郭嘉 风雷翅
    STATUSTYPE_SAMANBUFF = 153,       -- 南蛮萨满 嗜血神咒buff
    STATUSTYPE_FAZHENGBUFF = 154,      
    STATUSTYPE_GONGSUNZANMARK = 155,-- 公孙瓒标记  眩晕
    STATUSTYPE_GANNINGDEBUFF = 156,
    STATUSTYPE_BAIHU_DEBUFF = 157,  --白虎标记，弱疗
    STATUSTYPE_BAIHUALLTIMESHIELD = 158, --白虎护盾
    STATUSTYPE_GUANHAIBUFF = 159, 
    STATUSTYPE_CHENGYUDEBUFF = 160, 
    STATUSTYPE_CHENGYUINTERVALDEBUFF = 161, 
    STATUSTYPE_BINDTARGETS = 162, 
    STATUSTYPE_SUNQUANBUFF = 163, 
    STATUSTYPE_SUNQUANDEBUFF = 164, 
    STATUSTYPE_BINDONETARGET = 165, 
    STATUSTYPE_SUNSHANGXIANGDEBUFF = 166,   
    STATUSTYPE_REDUCECONTROLBUFF = 167,   
    STATUSTYPE_HUAXIONGBUFF = 168,   


    STATUSEFFECT_NONE = 0,
    STATUSEFFECT_STUN = 1,             -- 晕
    STATUSEFFECT_FROZEN = 2,           -- 冰冻
    STATUSEFFECT_STAND = 3,            -- 定身
    STATUSEFFECT_SILENT = 4,           -- 沉默
    STATUSEFFECT_ENLACE = 5,           -- 缠绕

    STATUSEFFECT_POISON = 6,           -- 中毒
    STATUSEFFECT_FIRE   = 7,             -- 灼烧
    STATUSEFFECT_WUDI   = 8,             -- 无敌
    STATUSEFFECT_ATKSPEED_INC = 9,     -- 提升攻速
    STATUSEFFECT_ATKSPEED_DEC = 10,     -- 下降攻速
    STATUSEFFECT_MOVESPEED_INC = 11,    -- 提升攻速
    STATUSEFFECT_HOT     = 12,          -- 持续恢复
    STATUSEFFECT_ATK_INC = 13,          -- 攻击提升
    STATUSEFFECT_ATK_DEC = 14,          -- 攻击下降
    STATUSEFFECT_RECOER_HP_BUFF = 15,   --回血buff
    STATUSEFFECT_BE_HURT_DEC = 16,      --受到伤害降低
    STATUSEFFECT_RECOVER_HP = 17,       --回血
    STATUSEFFECT_FEAR = 18,             --恐惧

    MERGERULE_NEW_LEFT = 0,           -- 保留新的
    MERGERULE_LONGER_LEFT = 1,        -- 保留剩余时间长的
    MERGERULE_TOGATHER = 2,           -- 共存 
    MERGERULE_MERGE = 3,              -- 合并

    EXISTTYPE_REPLACE = 0,			-- 替换
    EXISTTYPE_NOTHING = 1,        	-- 共存
    EXISTTYPE_IGNORE = 2,				-- 忽略
    EXISTTYPE_MERGE = 3,              -- 合并

    CLEARREASON_DIE = 0,
    CLEARREASON_POSITIVE = 1,
    CLEARREASON_NEGATIVE = 2,
    CLEARREASON_FIGHT_END = 3,

    STATUSCONDITION_END = 0,
    STATUSCONDITION_CONTINUE = 1,


    HURTDIR_BE_HURT = 0,
    HURTDIR_HURT_OTHER = 1,

    IMMUNEFLAG_STUN = 1,
    IMMUNEFLAG_CONTROL = 2,
    IMMUNEFLAG_NEGATIVE = 3,
    IMMUNEFLAG_INTERRUPT = 4,
    IMMUNEFLAG_HURTFLY = 5,
    IMMUNEFLAG_HURTBACK = 6,
    IMMUNEFLAG_ALL_BUT_DOT = 7,
    IMMUNEFLAG_PHY_HURT = 8,
    IMMUNEFLAG_MAGIC_HURT = 9,
}

StatusUtil = {
    IsInterruptType = function(statusType)
        return statusType == StatusEnum.STATUSTYPE_STUN or 
               statusType == StatusEnum.STATUSTYPE_FROZEN or 
               statusType == StatusEnum.STATUSTYPE_SILENT
    end,

    IsControlType = function(statusType)
        return statusType == StatusEnum.STATUSTYPE_STUN 
            or statusType == StatusEnum.STATUSTYPE_FROZEN
            or statusType == StatusEnum.STATUSTYPE_SILENT
            or statusType == StatusEnum.STATUSTYPE_SLEEP
            or statusType == StatusEnum.STATUSTYPE_DINGSHEN
            or statusType == StatusEnum.STATUSTYPE_FEAR
            or statusType == StatusEnum.STATUSTYPE_BEATFLY
    end,

    IsHorseImmuneControlType = function(statusType)
        return statusType == StatusEnum.STATUSTYPE_STUN 
            or statusType == StatusEnum.STATUSTYPE_FROZEN
            or statusType == StatusEnum.STATUSTYPE_SLEEP
            or statusType == StatusEnum.STATUSTYPE_FEAR
            or statusType == StatusEnum.STATUSTYPE_CHAOFENG
    end,
}


StatusGiver = BaseClass("StatusGiver")
function StatusGiver:__init(actorID, skillID)
    self.actorID = actorID or 0
    self.skillID = skillID or 0

    local mt = getmetatable(self)
    mt.__tostring = function(t) return "[".. t.actorID .. ", " .. t.skillID  .. "]" end 
end

function StatusGiver:Clear()
    self.actorID = 0
    self.skillID = 0
end

