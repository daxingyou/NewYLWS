-- require("GameLogic.Battle.Status.StatusDef")
local StatusBase = require("GameLogic.Battle.Status.StatusBase")

local table_insert = table.insert
local table_remove = table.remove
local StatusEnum = StatusEnum
local LogError = Logger.LogError

local StatusFactory = BaseClass("StatusFactory", Singleton )

function StatusFactory:__init()
    self.m_statusPool = {}
end

function StatusFactory:_GetStatusFromPool(statusType)
    local list = self.m_statusPool[statusType]
    if not list then
        return nil
    end
    if not next(list) then
        return nil
    end
    local status = table_remove(list)
    StatusBase.Init(status)
    return status
end

function StatusFactory:ReleaseStatus(status)
    if not status then
        LogError("ReleaseStatus nil")
        return
    end
    local statusType = status:GetStatusType()

    status:Release()
    local list = self.m_statusPool[statusType]
    if not list then
        list = {}
        self.m_statusPool[statusType] = list
    end
    table_insert(list, status)
end

function StatusFactory:Clear()
    for statusType, list in pairs(self.m_statusPool) do
        for _, status in pairs(list) do
            status:Delete()
        end
    end
    self.m_statusPool = {}
end

function StatusFactory:NewStatusHP(giver, deltaHP, hurtType, reason, judge, keyframe)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_HP)
    if not status then
        local StatusHP = require("GameLogic.Battle.Status.impl.StatusHP")
        status = StatusHP.New()
    end
    status:Init(giver, deltaHP, hurtType, reason, judge, keyframe)
    return status
end

function StatusFactory:NewStatusStun(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_STUN)
    if not status then
        local StatusStun = require("GameLogic.Battle.Status.impl.StatusStun")
        status = StatusStun.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusBuff(giver, attrReason, leftMS, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_ATTRBUFF)
    if not status then
        local StatusBuff = require("GameLogic.Battle.Status.impl.StatusBuff")
        status = StatusBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_ATTRBUFF)
    return status
end

function StatusFactory:NewStatusXiliangWeek(giver, leftMS, phyAtkAdd, magicAtkAdd)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_XILIANGWEAK)
    if not status then
        local StatusXiliangWeak = require("GameLogic.Battle.Status.impl.StatusXiliangWeak")
        status = StatusXiliangWeak.New()
    end
    status:Init(giver, leftMS, phyAtkAdd, magicAtkAdd)
    return status
end

function StatusFactory:NewStatusDiaoChanMark(giver, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_DIAOCHANMARK)
    if not status then
        local StatusDiaoChanMark = require("GameLogic.Battle.Status.impl.StatusDiaoChanMark")
        status = StatusDiaoChanMark.New()
    end
    status:Init(giver, effect)
    return status
end

function StatusFactory:NewStatusQingLongMark(giver, leftMS, targetID, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_QINGLONGMARK)
    if not status then
        local StatusQingLongMark = require("GameLogic.Battle.Status.impl.StatusQingLongMark")
        status = StatusQingLongMark.New()
    end
    status:Init(giver, leftMS, targetID, effect)
    return status
end

function StatusFactory:NewStatusXuanWuCurse(giver, leftMS, targetID, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_XUANWUCURSE)
    if not status then
        local StatusXuanWuCurse = require("GameLogic.Battle.Status.impl.StatusXuanWuCurse")
        status = StatusXuanWuCurse.New()
    end
    status:Init(giver, leftMS, targetID, effect)
    return status
end

function StatusFactory:NewStatusIntervalHP(giver, deltaHP, interval, chgCount, effect, maxOverlayCount, hurtType)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_INTERVAL_HP)
    if not status then
        local StatusIntervalHP = require("GameLogic.Battle.Status.impl.StatusIntervalHP")
        status = StatusIntervalHP.New()
    end
    status:Init(giver, deltaHP, interval, chgCount, effect, maxOverlayCount, hurtType)
    return status
end

function StatusFactory:NewStatusIntervalNuQi(giver, deltaNuQi, interval, chgCount, chgReason, skillCfg, effect, maxOverlayCount)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_INTERVAL_NUQI)
    if not status then
        local StatusIntervalNuQi = require("GameLogic.Battle.Status.impl.StatusIntervalNuQi")
        status = StatusIntervalNuQi.New()
    end
    status:Init(giver, deltaNuQi, interval, chgCount, chgReason, skillCfg, effect, maxOverlayCount)
    return status
end

function StatusFactory:NewStatusImmune(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_IMMUNE)
    if not status then
        local StatusImmune = require("GameLogic.Battle.Status.impl.StatusImmune")
        status = StatusImmune.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusChaoFeng(giver, targetID, leftMS)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_CHAOFENG)
    if not status then
        local StatusChaoFeng = require("GameLogic.Battle.Status.impl.StatusChaoFeng")
        status = StatusChaoFeng.New()
    end
    status:Init(giver, targetID, leftMS)
    return status
end

function StatusFactory:NewStatusFear(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_FEAR)
    if not status then
        local StatusFear = require("GameLogic.Battle.Status.impl.StatusFear")
        status = StatusFear.New()
    end
    status:Init(giver,leftMS,effect)
    return status
end

function StatusFactory:NewStatusFrozen(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_FROZEN)
    if not status then
        local StatusFrozen = require("GameLogic.Battle.Status.impl.StatusFrozen")
        status = StatusFrozen.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusFrozenEnd(giver, leftMS, continueTime, yPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_FROZEN_END)
    if not status then
        local StatusFrozenEnd = require("GameLogic.Battle.Status.impl.StatusFrozenEnd")
        status = StatusFrozenEnd.New()
    end
    status:Init(giver, leftMS, continueTime, yPercent, effect)
    return status
end

function StatusFactory:NewStatusDingShen(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_DINGSHEN)
    if not status then
        local StatusDingShen = require("GameLogic.Battle.Status.impl.StatusDingShen")
        status = StatusDingShen.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusNextNHurtOtherMul(giver, skillTypeList, isOnce)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_NEXT_N_HURTOTHERMUL)
    if not status then
        local StatusNextNHurtOtherMul = require("GameLogic.Battle.Status.impl.StatusNextNHurtOtherMul")
        status = StatusNextNHurtOtherMul.New()
    end
    status:Init(giver, skillTypeList, isOnce)
    return status
end

function StatusFactory:NewStatusXiliangDot(giver, leftMS, hpChgPercent)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_XILIANGDOT)
    if not status then
        local StatusXiliangDot = require("GameLogic.Battle.Status.impl.StatusXiliangDot")
        status = StatusXiliangDot.New()
    end
    status:Init(giver, leftMS, hpChgPercent)
    return status
end

function StatusFactory:NewStatusDelayHurt(giver, deltaHP, hurtType, delayS, reason, hurtFrame, judge)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_DELAY_HURT)
    if not status then
        local StatusDelayHurt = require("GameLogic.Battle.Status.impl.StatusDelayHurt")
        status = StatusDelayHurt.New()
    end
    status:Init(giver, deltaHP, hurtType, delayS, reason, hurtFrame, judge)
    return status
end

function StatusFactory:NewStatusFanTan(giver, leftMS, fantanPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_FANTAN)
    if not status then
        local StatusFanTan = require("GameLogic.Battle.Status.impl.StatusFanTan")
        status = StatusFanTan.New()
    end
    status:Init(giver, leftMS, fantanPercent, effect)
    return status
end

function StatusFactory:NewStatusWudi(giver, leftTime, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_WUDI)
    if not status then
        local StatusWudi = require("GameLogic.Battle.Status.impl.StatusWudi")
        status = StatusWudi.New()
    end
    status:Init(giver, leftTime, effect)
    return status
end

function StatusFactory:NewStatusZhaoYunWudi(giver, leftTime, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_ZHAOYUNWUDI)
    if not status then
        local StatusZhaoYunWudi = require("GameLogic.Battle.Status.impl.StatusZhaoYunWudi")
        status = StatusZhaoYunWudi.New()
    end
    status:Init(giver, leftTime, effect)
    return status
end

function StatusFactory:NewStatusHuangjinDaodunDef(giver, leftMS, hurtDefPercent, maxHurtPercent, atkHurtMul, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_HUANGJINDAODUN_DEFENSIVESTATE)
    if not status then
        local StatusHuangjinDaodunDef = require("GameLogic.Battle.Status.impl.StatusHuangjinDaodunDef")
        status = StatusHuangjinDaodunDef.New()
    end
    status:Init(giver, leftMS, hurtDefPercent, maxHurtPercent, atkHurtMul, effect)
    return status
end

function StatusFactory:NewStatusImmuneNextControl(giver, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_IMMUNENEXTCONTROL)
    if not status then
        local StatusImmuneNextControl = require("GameLogic.Battle.Status.impl.StatusImmuneNextControl")
        status = StatusImmuneNextControl.New()
    end
    status:Init(giver, effect)
    return status
end

function StatusFactory:NewStatusImmuneIntervalControl(giver, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_IMMUNEINTERVALCONTROL)
    if not status then
        local StatusImmuneIntervalControl = require("GameLogic.Battle.Status.impl.StatusImmuneIntervalControl")
        status = StatusImmuneIntervalControl.New()
    end
    status:Init(giver, effect)
    return status
end

function StatusFactory:NewStatusNTimeBeHurtMul(giver, leftMS, beHurtMul, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_NEXT_NTIME_BEHURTMUL)
    if not status then
        local StatusNTimeBeHurtMul = require("GameLogic.Battle.Status.impl.StatusNTimeBeHurtMul")
        status = StatusNTimeBeHurtMul.New()
    end
    status:Init(giver, leftMS, beHurtMul, effect)
    return status
end

function StatusFactory:NewStatusNTimeHurtOtherMul(giver, leftMS, hurtTypeList, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_NEXT_NTIME_HURTOTHERMUL)
    if not status then
        local StatusNTimeHurtOtherMul = require("GameLogic.Battle.Status.impl.StatusNTimeHurtOtherMul")
        status = StatusNTimeHurtOtherMul.New()
    end
    status:Init(giver, leftMS, hurtTypeList, effect)
    return status
end

function StatusFactory:NewStatusZhangFeiDef(giver, leftMS, hurtDefPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_ZHANGFEIDEF)
    if not status then
        local StatusZhangfeiDef = require("GameLogic.Battle.Status.impl.StatusZhangfeiDef")
        status = StatusZhangfeiDef.New()
    end
    status:Init(giver, leftMS, hurtDefPercent, effect)
    return status
end

function StatusFactory:NewStatusAllShield(giver, hpStore, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_ALLSHIELD)
    if not status then
        local StatusAllShield = require("GameLogic.Battle.Status.impl.StatusAllShield")
        status = StatusAllShield.New()
    end
    status:Init(giver, hpStore, effect)
    return status
end

function StatusFactory:NewStatusAllTimeShield(giver, hpStore, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_ALLTIMESHIELD)
    if not status then
        local StatusAllTimeShield = require("GameLogic.Battle.Status.impl.StatusAllTimeShield")
        status = StatusAllTimeShield.New()
    end
    status:Init(giver, hpStore, leftMS, effect)
    return status
end

function StatusFactory:NewStatusXuanWuAllTimeShield(giver, hpStore, leftMS, frozenList, frozenTime, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_XUANWUALLTIMESHIELD)
    if not status then
        local StatusXuanWuAllTimeShield = require("GameLogic.Battle.Status.impl.StatusXuanWuAllTimeShield")
        status = StatusXuanWuAllTimeShield.New()
    end
    status:Init(giver, hpStore, leftMS, frozenList, frozenTime,  effect)
    return status
end

function StatusFactory:NewStatusBaiHuAllTimeShield(giver, hpStore, leftMS, percent, area, hurt, skillCfg, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_BAIHUALLTIMESHIELD)
    if not status then
        local StatusBaiHuAllTimeShield = require("GameLogic.Battle.Status.impl.StatusBaiHuAllTimeShield")
        status = StatusBaiHuAllTimeShield.New()
    end
    status:Init(giver, hpStore, leftMS, percent, area, hurt, skillCfg, effect)
    return status
end

function StatusFactory:NewStatusYuanShaoHaoLing(giver, targetID, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YUANSHAOHAOLING)
    if not status then
        local StatusYuanShaoHaoling = require("GameLogic.Battle.Status.impl.StatusYuanShaoHaoling")
        status = StatusYuanShaoHaoling.New()
    end
    status:Init(giver, targetID, leftMS, effect)
    return status
end

function StatusFactory:NewStatusYuanShaoImmunePositive(giver, leftMS, hurtHP, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_YUANSHAOIMMUNEPOSITIVE)
    if not status then
        local StatusYuanShaoImmunePositive = require("GameLogic.Battle.Status.impl.StatusYuanShaoImmunePositive")
        status = StatusYuanShaoImmunePositive.New()
    end
    status:Init(giver, leftMS, hurtHP, effect)
    return status
end

function StatusFactory:NewStatusLangsheMark(giver, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_LANGSHEMARK)
    if not status then
        local StatusLangsheMark = require("GameLogic.Battle.Status.impl.StatusLangsheMark")
        status = StatusLangsheMark.New()
    end
    status:Init(giver, effect)
    return status
end

function StatusFactory:NewStatusPalsy(giver, leftTime, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_PALSY)
    if not status then
        local StatusPalsy = require("GameLogic.Battle.Status.impl.StatusPalsy")
        status = StatusPalsy.New()
    end
    status:Init(giver, leftTime, effect)
    return status
end

function StatusFactory:NewStatusMagicShield(giver, hpStore, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_MAGICSHIELD)
    if not status then
        local StatusMagicShield = require("GameLogic.Battle.Status.impl.StatusMagicShield")
        status = StatusMagicShield.New()
    end
    status:Init(giver, hpStore, effect)
    return status
end

function StatusFactory:NewStatusMagicTimeShield(giver, hpStore, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_MAGICTIMESHIELD)
    if not status then
        local StatusMagicTimeShield = require("GameLogic.Battle.Status.impl.StatusMagicTimeShield")
        status = StatusMagicTimeShield.New()
    end
    status:Init(giver, hpStore, leftMS, effect)
    return status
end

function StatusFactory:NewStatusDongzhuoFireBuff(giver, attrReason, leftMS, rand, radius, copyMaxCount, effect, maxCount, subStatusType)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_DONGZHUOFIREBUFF)
    if not status then
        local StatusDongzhuoFireBuff = require("GameLogic.Battle.Status.impl.StatusDongzhuoFireBuff")
        status = StatusDongzhuoFireBuff.New()
    end
    status:Init(giver, attrReason, leftMS, rand, radius, copyMaxCount, effect, maxCount, subStatusType)
    return status
end

function StatusFactory:NewStatusInscriptionBuff(giver, attrReason, leftMS, count, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_INSCRIPTIONBUFF)
    if not status then
        local Status50038Buff = require("GameLogic.Battle.Status.impl.Status50038Buff")
        status = Status50038Buff.New()
    end
    status:Init(giver, attrReason, leftMS, count, effect, maxCount, StatusEnum.STATUSTYPE_INSCRIPTIONBUFF)
    return status
end

function StatusFactory:NewStatusDaqiaoIntervalHP(giver, deltaHP, interval, chgCount, effect, maxOverlayCount)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_DAQIAO_INTERVAL_HP)
    if not status then
        local StatusDaqiaoIntervalHP = require("GameLogic.Battle.Status.impl.StatusDaqiaoIntervalHP")
        status = StatusDaqiaoIntervalHP.New()
    end
    status:Init(giver, deltaHP, interval, chgCount, effect, maxOverlayCount)
    return status
end

function StatusFactory:NewStatusZhouyuBuff(giver, attrReason, leftMS, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_ZHOUYUBUFF)
    if not status then
        local StatusZhouyuBuff = require("GameLogic.Battle.Status.impl.StatusZhouyuBuff")
        status = StatusZhouyuBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount)
    return status
end

function StatusFactory:NewStatusCaocaoBuff(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_CAOCAOBUFF)
    if not status then
        local StatusCaocaoBuff = require("GameLogic.Battle.Status.impl.StatusCaocaoBuff")
        status = StatusCaocaoBuff.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusHuaxiongDebuff(giver, leftMS, reducePercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_HURXIONG_DEBUFF)
    if not status then
        local StatusHuaxiongDebuff = require("GameLogic.Battle.Status.impl.StatusHuaxiongDebuff")
        status = StatusHuaxiongDebuff.New()
    end
    status:Init(giver, leftMS, reducePercent, effect)
    return status
end

function StatusFactory:NewStatusBaihuDebuff(giver, leftMS, reducePercent)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_BAIHU_DEBUFF)
    if not status then
        local StatusBaihuDebuff = require("GameLogic.Battle.Status.impl.StatusBaihuDebuff")
        status = StatusBaihuDebuff.New()
    end
    status:Init(giver, leftMS, reducePercent)
    return status
end

function StatusFactory:NewStatusRecoverPercent(giver, leftMS, reducePercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_RECOVER_PERCENT)
    if not status then
        local StatusRecoverPercent = require("GameLogic.Battle.Status.impl.StatusRecoverPercent")
        status = StatusRecoverPercent.New()
    end
    status:Init(giver, leftMS, reducePercent, effect)
    return status
end

function StatusFactory:NewStatusJiaxuDebuff(giver, leftMS, maxHurt, hurtRadius, intervalHurt, skillLevel, copyRadius, hurtPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_JIAXU_DEBUFF)
    if not status then
        local StatusJiaxuDebuff = require("GameLogic.Battle.Status.impl.StatusJiaxuDebuff")
        status = StatusJiaxuDebuff.New()
    end
    status:Init(giver, leftMS, maxHurt, hurtRadius, intervalHurt, skillLevel, copyRadius, hurtPercent, effect)
    return status
end

function StatusFactory:NewStatusJiaxuBuff(giver, chgPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_JIAXU_BUFF)
    if not status then
        local StatusJiaxuBuff = require("GameLogic.Battle.Status.impl.StatusJiaxuBuff")
        status = StatusJiaxuBuff.New()
    end
    status:Init(giver, chgPercent, effect)
    return status
end

function StatusFactory:NewStatusLidianDeBuff(giver, attrReason, leftMS, hurtMul, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_LIDIAN_DEBUFF)
    if not status then
        local StatusLidianDeBuff = require("GameLogic.Battle.Status.impl.StatusLidianDeBuff")
        status = StatusLidianDeBuff.New()
    end
    status:Init(giver, attrReason, leftMS, hurtMul, effect, maxCount, StatusEnum.STATUSTYPE_LIDIAN_DEBUFF)
    return status
end

function StatusFactory:NewStatusHorse60001Buff(giver, nuqi, count, skillCfg)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_HORSE_BUFF)
    if not status then
        local StatusHorse60001Buff = require("GameLogic.Battle.Status.impl.StatusHorse60001Buff")
        status = StatusHorse60001Buff.New()
    end
    status:Init(giver, nuqi, count, skillCfg)
    return status
end

function StatusFactory:NewStatusXiahoudunShield(giver, hpStore, leftMS, baoji, recoverPercent, isImmuneControle, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_XIAHOUDUN_SHIELD)
    if not status then
        local StatusXiahoudunShield = require("GameLogic.Battle.Status.impl.StatusXiahoudunShield")
        status = StatusXiahoudunShield.New()
    end
    status:Init(giver, hpStore, leftMS, baoji, recoverPercent, isImmuneControle, effect)
    return status
end

function StatusFactory:NewStatusSilent(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_SILENT)
    if not status then
        local StatusSilent = require("GameLogic.Battle.Status.impl.StatusSilent")
        status = StatusSilent.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusWeak(giver, leftMS, hurtMul, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_WEAK)
    if not status then
        local StatusWeak = require("GameLogic.Battle.Status.impl.StatusWeak")
        status = StatusWeak.New()
    end
    status:Init(giver, leftMS, hurtMul, effect)
    return status
end

function StatusFactory:NewStatusYanliangCanren(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YANGLIANG_CANREN)
    if not status then
        local StatusYanliangCanren = require("GameLogic.Battle.Status.impl.StatusYanliangCanren")
        status = StatusYanliangCanren.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusYanliangFenjia(giver, attrReason, intervalTime, chgPercent, chgMagicPercent, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YANGLIANG_FENJIA)
    if not status then
        local StatusYanliangFenjia = require("GameLogic.Battle.Status.impl.StatusYanliangFenjia")
        status = StatusYanliangFenjia.New()
    end
    status:Init(giver, attrReason, intervalTime, chgPercent, chgMagicPercent, effect, maxCount)
    return status
end

function StatusFactory:NewStatusDianweiBuff(giver, attrReason, leftMS, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_DIANWEITIELI)
    if not status then
        local StatusDianweiBuff = require("GameLogic.Battle.Status.impl.StatusDianweiBuff")
        status = StatusDianweiBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_DIANWEITIELI)
    return status
end

function StatusFactory:NewStatusYujinMark(giver, leftMS, hurtMul, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YUJINMARK)
    if not status then
        local StatusYujinMark = require("GameLogic.Battle.Status.impl.StatusYujinMark")
        status = StatusYujinMark.New()
    end
    status:Init(giver, leftMS, hurtMul, effect)
    return status
end

function StatusFactory:NewStatusWenchouMark(giver, leftMS, addPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_WENCHOUMARK)
    if not status then
        local StatusWenchouMark = require("GameLogic.Battle.Status.impl.StatusWenchouMark")
        status = StatusWenchouMark.New()
    end
    status:Init(giver, leftMS, addPercent, effect)
    return status
end

function StatusFactory:NewStatusWenchouChouxue(giver, leftMS, hp, phyDef, targetID, radius, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_WENCHOUCHOUXUE)
    if not status then
        local StatusWenchouChouxue = require("GameLogic.Battle.Status.impl.StatusWenchouChouxue")
        status = StatusWenchouChouxue.New()
    end
    status:Init(giver, leftMS, hp, phyDef, targetID, radius, effect)
    return status
end

function StatusFactory:NewStatusSlow(giver, leftMS, chgMoveSpeed, chgAnimSpeed, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_SLOW)
    if not status then
        local StatusSlow = require("GameLogic.Battle.Status.impl.StatusSlow")
        status = StatusSlow.New()
    end
    status:Init(giver, leftMS, chgMoveSpeed, chgAnimSpeed, effect)
    return status
end


function StatusFactory:NewStatusYuanshuShibingCurse(giver, attrReason, leftMS, effect, maxCount, subStatusType)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YUANSHUSHIBINGCURSE)
    if not status then
        local StatusYuanshuShibingCurse = require("GameLogic.Battle.Status.impl.StatusYuanshuShibingCurse")
        status = StatusYuanshuShibingCurse.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_YUANSHUSHIBINGCURSE)
    return status
end


function StatusFactory:NewStatusYuanshuShijiaCurse(giver, attrReason, leftMS, effect, maxCount, subStatusType)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YUANSHUSHIJIACURSE)
    if not status then
        local StatusYuanshuShijiaCurse = require("GameLogic.Battle.Status.impl.StatusYuanshuShijiaCurse")
        status = StatusYuanshuShijiaCurse.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_YUANSHUSHIJIACURSE)
    return status
end


function StatusFactory:NewStatusYuanshuShihunCurse(giver, leftMS, addSkillCDTimePercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YUANSHUSHIHUNCURSE)
    if not status then
        local StatusYuanshuShihunCurse = require("GameLogic.Battle.Status.impl.StatusYuanshuShihunCurse")
        status = StatusYuanshuShihunCurse.New()
    end
    status:Init(giver, leftMS, addSkillCDTimePercent, effect)
    return status
end


function StatusFactory:NewStatusYuanshuShilongBuff(giver, attrReason, leftMS, effect, maxCount, subStatusType)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_YUANSHUSHILONG)
    if not status then
        local StatusYuanshuShilongBuff = require("GameLogic.Battle.Status.impl.StatusYuanshuShilongBuff")
        status = StatusYuanshuShilongBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_YUANSHUSHILONG)
    return status
end


function StatusFactory:NewStatusLusuAllShieldJiangdong(giver, hpStore, leftMS, chgPhySuck, chgMagicSuck, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_LUSUALLSHIELDJIANGDONG)
    if not status then
        local StatusLuSuAllShieldJiangdong = require("GameLogic.Battle.Status.impl.StatusLuSuAllShieldJiangdong")
        status = StatusLuSuAllShieldJiangdong.New()
    end
    status:Init(giver, hpStore, leftMS, chgPhySuck, chgMagicSuck, effect)
    return status
end


function StatusFactory:NewStatusLusuAllShieldLeshan(giver, hpStore, leftMS, chgPhySuck, chgMagicSuck, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_LUSUALLSHIELDJIANGDONG)
    if not status then
        local StatusLuSuAllShieldLeshan = require("GameLogic.Battle.Status.impl.StatusLuSuAllShieldLeshan")
        status = StatusLuSuAllShieldLeshan.New()
    end
    status:Init(giver, hpStore, leftMS, chgPhySuck, chgMagicSuck, effect)
    return status
end

function StatusFactory:NewStatusXiahouyuanDebuff(giver, attrReason, leftMS, effect, maxCount, subStatusType)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_XIAHOUYUANDEBUFF)
    if not status then
        local StatusXiahouyuanDeBuff = require("GameLogic.Battle.Status.impl.StatusXiahouyuanDeBuff")
        status = StatusXiahouyuanDeBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, subStatusType)
    return status
end

function StatusFactory:NewStatusTaishiciShield(giver, hpStore, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_TAISHICISHIELD)
    if not status then
        local StatusTaishiciShield = require("GameLogic.Battle.Status.impl.StatusTaishiciShield")
        status = StatusTaishiciShield.New()
    end
    status:Init(giver, hpStore, effect)
    return status
end

function StatusFactory:NewStatusTaishiciImmune(giver, leftMS)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_TAISHICIIMMUNE)
    if not status then
        local StatusTaishiciImmune = require("GameLogic.Battle.Status.impl.StatusTaishiciImmune")
        status = StatusTaishiciImmune.New()
    end
    status:Init(giver, leftMS)
    return status
end


function StatusFactory:NewStatusIntervalHP20111(giver, deltaHP, interval, chgCount, phyDef, effect, maxOverlayCount)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_INTERVAL_HP_20111)
    if not status then
        local StatusIntervalHP20111 = require("GameLogic.Battle.Status.impl.StatusIntervalHP20111")
        status = StatusIntervalHP20111.New()
    end
    status:Init(giver, deltaHP, interval, chgCount, phyDef, effect, maxOverlayCount)
    return status
end

function StatusFactory:NewStatusNextNBeHurtChg(giver, effectCount, hurtType, fixedHurt, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_NEXT_N_BEHURTCHG)
    if not status then
        local StatusNextNBeHurtChg = require("GameLogic.Battle.Status.impl.StatusNextNBeHurtChg")
        status = StatusNextNBeHurtChg.New()
    end
    status:Init(giver, effectCount, hurtType, fixedHurt, effect)
    return status
end

function StatusFactory:NewStatusXueDiJnDunShield(giver, hpStore)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_XUEDIJUDUN_SHIELD)
    if not status then
        local StatusXueDiJnDunShield = require("GameLogic.Battle.Status.impl.StatusXueDiJnDunShield")
        status = StatusXueDiJnDunShield.New()
    end
    status:Init(giver, hpStore)
    return status
end


function StatusFactory:NewStatusManwangBuff(giver, leftMS, beHurtMul, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_MANWANGBUFF)
    if not status then
        local StatusManwangBuff = require("GameLogic.Battle.Status.impl.StatusManwangBuff")
        status = StatusManwangBuff.New()
    end
    status:Init(giver, leftMS, beHurtMul, effect)
    return status
end

function StatusFactory:NewStatusNanManBuff(giver, leftMS, atkMulPercent, atkSpeedPercent, skillCfg, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_NANMANBUFF)
    if not status then
        local StatusNanManBuff = require("GameLogic.Battle.Status.impl.StatusNanManBuff")
        status = StatusNanManBuff.New()
    end
    status:Init(giver, leftMS, atkMulPercent, atkSpeedPercent, skillCfg, effect)
    return status
end

function StatusFactory:NewStatusPangtongTieSuoMark(giver, leftMS, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_PANGTONGTIESUOMARK)
    if not status then
        local StatusPangTongTiesuoMark = require("GameLogic.Battle.Status.impl.StatusPangTongTiesuoMark")
        status = StatusPangTongTiesuoMark.New()
    end
    status:Init(giver, leftMS, effect)
    return status
end

function StatusFactory:NewStatusXunyuIntervalHP(giver, deltaHP, interval, chgCount, effect, maxOverlayCount, frozenTime, atkPercent, rand)
    local status = self:_GetStatusFromPool(StatusEnum.STAUTSTYPE_XUNYU_INTERVAL_HP)
    if not status then
        local StatusXunyuIntervalHP = require("GameLogic.Battle.Status.impl.StatusXunyuIntervalHP")
        status = StatusXunyuIntervalHP.New()
    end
    status:Init(giver, deltaHP, interval, chgCount, effect, maxOverlayCount, frozenTime, atkPercent, rand)
    return status
end

function StatusFactory:NewStatusXunyuImmune(giver, leftMS)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_XUNYUIMMUNE)
    if not status then
        local StatusXunyuImmune = require("GameLogic.Battle.Status.impl.StatusXunyuImmune")
        status = StatusXunyuImmune.New()
    end
    status:Init(giver, leftMS)
    return status
end

function StatusFactory:NewStatusBingshuangBomb(giver, leftMS, radius, skillX, skillY, skillCfg, hurtMul, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_BINGSHUANGBOMB)
    if not status then
        local StatusBingShuangBomb = require("GameLogic.Battle.Status.impl.StatusBingShuangBomb")
        status = StatusBingShuangBomb.New()
    end
    status:Init(giver, leftMS, radius, skillX, skillY, skillCfg, hurtMul, effect)
    return status
end

function StatusFactory:NewStatusGuishu(giver, leftMS, chgNuqi, magicPercent, maxPercent, skillCfg, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_GUISHU)
    if not status then
        local StatusXuediGuishu = require("GameLogic.Battle.Status.impl.StatusXuediGuishu")
        status = StatusXuediGuishu.New()
    end
    status:Init(giver, leftMS, chgNuqi, magicPercent, maxPercent, skillCfg, effect)
    return status
end

function StatusFactory:NewStatusFengLeiChi(giver, leftMS, atkSpeedPercent, baojiPercent, radius, otherHurtPercent, selfHurtPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_FENGLEICHI)
    if not status then
        local StatusFengLeiChi = require("GameLogic.Battle.Status.impl.StatusFengLeiChi")
        status = StatusFengLeiChi.New()
    end
    status:Init(giver, leftMS, atkSpeedPercent, baojiPercent, radius, otherHurtPercent, selfHurtPercent, effect)
    return status
end

function StatusFactory:NewStatusSaManBuff(giver, maxCount, suckPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_SAMANBUFF)
    if not status then
        local StatusSaManbuff = require("GameLogic.Battle.Status.impl.StatusSaManbuff")
        status = StatusSaManbuff.New()
    end
    status:Init(giver, maxCount, suckPercent, effect)
    return status
end

function StatusFactory:NewStatusGongsunzanBuff(giver, attrReason, leftMS, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_GONGSUNZANBUFF)
    if not status then
        local StatusGongSunZanBuff = require("GameLogic.Battle.Status.impl.StatusGongSunZanBuff")
        status = StatusGongSunZanBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_ATTRBUFF)
    return status
end

function StatusFactory:NewStatusGongsunzanMark(giver, leftMS, stunTime, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_GONGSUNZANMARK)
    if not status then
        local StatusGongsunzanMark = require("GameLogic.Battle.Status.impl.StatusGongsunzanMark")
        status = StatusGongsunzanMark.New()
    end
    status:Init(giver, leftMS, stunTime, effect)
    return status
end


function StatusFactory:NewStatusGanningDeBuff(giver, attrReason, leftMS, mediaID, isStealAtk, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_GANNINGDEBUFF)
    if not status then
        local StatusGanningDeBuff = require("GameLogic.Battle.Status.impl.StatusGanningDeBuff")
        status = StatusGanningDeBuff.New()
    end
    status:Init(giver, attrReason, leftMS, mediaID, isStealAtk, effect, maxCount, StatusEnum.STATUSTYPE_GANNINGDEBUFF)
    return status
end

function StatusFactory:NewStatusGuanhaiBuff(giver, attrReason, leftMS, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_GUANHAIBUFF)
    if not status then
        local StatusGuanhaiBuff = require("GameLogic.Battle.Status.impl.StatusGuanhaiBuff")
        status = StatusGuanhaiBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_GUANHAIBUFF)
    return status
end

function StatusFactory:NewStatusChengyuDeBuff(giver, attrReason, leftMS, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_CHENGYUDEBUFF)
    if not status then
        local StatusChengyuDeBuff = require("GameLogic.Battle.Status.impl.StatusChengyuDeBuff")
        status = StatusChengyuDeBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_CHENGYUDEBUFF)
    return status
end

function StatusFactory:NewStatusChengyuIntervalDeBuff(giver, attrReason, leftMS, chgPercent, skillLevel, maxMul, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_CHENGYUINTERVALDEBUFF)
    if not status then
        local StatusChengyuIntervalDeBuff = require("GameLogic.Battle.Status.impl.StatusChengyuIntervalDeBuff")
        status = StatusChengyuIntervalDeBuff.New()
    end
    status:Init(giver, attrReason, leftMS, chgPercent, skillLevel, maxMul, effect, maxCount, StatusEnum.STATUSTYPE_CHENGYUINTERVALDEBUFF)
    return status
end

function StatusFactory:NewStatusBindTargets(giver, leftMS, reducePercent, hurtPercent, recoverHPPercent, recoverSkillCfg, maxIntervalCount, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_BINDTARGETS)
    if not status then
        local StatusBindTargets = require("GameLogic.Battle.Status.impl.StatusBindTargets")
        status = StatusBindTargets.New()
    end
    status:Init(giver, leftMS, reducePercent, hurtPercent, recoverHPPercent, recoverSkillCfg, maxIntervalCount, effect)
    return status
end

function StatusFactory:NewStatusSunquanBuff(giver, leftMS, reducePercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_SUNQUANBUFF)
    if not status then
        local StatusSunquanBuff = require("GameLogic.Battle.Status.impl.StatusSunquanBuff")
        status = StatusSunquanBuff.New()
    end
    status:Init(giver, leftMS, reducePercent, effect)
    return status
end

function StatusFactory:NewStatusSunquanDebuff(giver, leftMS, beHurtMul, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_SUNQUANDEBUFF)
    if not status then
        local StatusSunquanDebuff = require("GameLogic.Battle.Status.impl.StatusSunquanDebuff")
        status = StatusSunquanDebuff.New()
    end
    status:Init(giver, leftMS, beHurtMul, effect)
    return status
end

function StatusFactory:NewStatusBindOneTarget(giver, leftMS, hurtPercent, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_BINDONETARGET)
    if not status then
        local StatusBindOneTarget = require("GameLogic.Battle.Status.impl.StatusBindOneTarget")
        status = StatusBindOneTarget.New()
    end
    status:Init(giver, leftMS, hurtPercent, effect)
    return status
end

function StatusFactory:NewStatusSunshangxiangDeBuff(giver, attrReason, leftMS, effect, maxCount)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_SUNSHANGXIANGDEBUFF)
    if not status then
        local StatusSunshangxiangDeBuff = require("GameLogic.Battle.Status.impl.StatusSunshangxiangDeBuff")
        status = StatusSunshangxiangDeBuff.New()
    end
    status:Init(giver, attrReason, leftMS, effect, maxCount, StatusEnum.STATUSTYPE_SUNSHANGXIANGDEBUFF)
    return status
end

function StatusFactory:NewStatusReduceControlTimebuff(giver, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_REDUCECONTROLBUFF)
    if not status then
        local StatusReduceControlTimebuff = require("GameLogic.Battle.Status.impl.StatusReduceControlTimebuff")
        status = StatusReduceControlTimebuff.New()
    end
    status:Init(giver, effect)
    return status
end

function StatusFactory:NewStatusFazhengBuff(giver, leftMS, skillAniSpeed, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_FAZHENGBUFF)
    if not status then
        local StatusFazhengBuff = require("GameLogic.Battle.Status.impl.StatusFazhengBuff")
        status = StatusFazhengBuff.New()
    end
    status:Init(giver, leftMS, skillAniSpeed, effect)
    return status
end

function StatusFactory:NewStatusHuaxiongBuff(giver, immuneMinHP, immuneRandValue, effect)
    local status = self:_GetStatusFromPool(StatusEnum.STATUSTYPE_HUAXIONGBUFF )
    if not status then
        local StatusHuaxiongbuff = require("GameLogic.Battle.Status.impl.StatusHuaxiongbuff")
        status = StatusHuaxiongbuff.New()
    end
    status:Init(giver, immuneMinHP, immuneRandValue, effect)
    return status
end

return StatusFactory