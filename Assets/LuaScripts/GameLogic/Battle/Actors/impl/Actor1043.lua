local FixSub = FixMath.sub
local FixDiv = FixMath.div
local FixIntMul = FixMath.muli
local FixMul = FixMath.mul
local FixAdd = FixMath.add
local BattleEnum = BattleEnum
local SkillUtil = SkillUtil
local StatusGiver = StatusGiver
local StatusEnum = StatusEnum
local ACTOR_ATTR = ACTOR_ATTR
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local ConfigUtil = ConfigUtil
local GetSkillCfgByID = ConfigUtil.GetSkillCfgByID
local StatusFactoryInst = StatusFactoryInst

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1043 = BaseClass("Actor1043", Actor)

function Actor1043:__init()
    self.m_changeAtkWay = false
    self.m_changeAtkWayTime = 0
    self.m_10431X = 0
    self.m_10431YPercent = 0

    self.m_10433Cfg = nil
    self.m_10433XPercent = 0
    self.m_10433A = 0
    self.m_10433B = 0
    self.m_10433CPercent = 0
    self.m_10433DPercent = 0
    self.m_10433Count = 0
    self.m_10433Time = 0
    self.m_10433Level = 0

    self.m_isBaojiHurtChg = false

    self.m_phyAtkChg = 0
    self.m_magicAtkChg = 0

    -- 普攻3提升双攻属性列表 actorID : chgAttrValue
    self.m_phyAtkChgList = {}
    self.m_magicAtkChgList = {}

    self.m_baojiHurtChgList = {}
end

function Actor1043:Get10431X()
    return self.m_10431X
end

function Actor1043:ChangeAtkWay()
    self.m_changeAtkWay = true
end

function Actor1043:IsChangeAtkWay()
    return self.m_changeAtkWay
end

function Actor1043:Get10433JianqiHurtMul()
    return FixMul(self.m_10433Count, self.m_10433DPercent)
end

function Actor1043:LogicUpdate(deltaMS)
    if self.m_changeAtkWay then
        self.m_changeAtkWayTime = FixAdd(self.m_changeAtkWayTime, deltaMS)
        if self.m_changeAtkWayTime >= self.m_10431X then
            self.m_changeAtkWay = false
            self.m_changeAtkWayTime = 0

            self:ReduceAttr()
        end
    end

    if self.m_10433Cfg and self.m_10433Count > 0 then
        self.m_10433Time = FixAdd(self.m_10433Time, deltaMS)
        if self.m_10433Time >= self.m_10433B then
            self.m_10433Count = 0
            self.m_10433Time = 0
        end
    end

    if self.m_10433Cfg and self.m_10433Count < self.m_10433A and self.m_isBaojiHurtChg then
        local battleLogic = CtlBattleInst:GetLogic()
        ActorManagerInst:Walk(
            function(tmpTarget)
                if not battleLogic:IsFriend(self, tmpTarget, true) then
                    return
                end

                local targetChgBJ = self.m_baojiHurtChgList[tmpTarget:GetActorID()]
                if not targetChgBJ then
                    return
                end

                tmpTarget:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_BAOJI_HURT, FixMul(targetChgBJ, -1))
                self.m_baojiHurtChgList[tmpTarget:GetActorID()] = nil
            end
        )
    
        self.m_isBaojiHurtChg = false
    end
end

function Actor1043:AddAttr()
    local battleLogic = CtlBattleInst:GetLogic()
    ActorManagerInst:Walk(
        function(tmpTarget)
            if not battleLogic:IsFriend(self, tmpTarget, true) then
                return
            end

            local curPhyAtk = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_PHY_ATK)
            local chgPhyAtk = FixIntMul(curPhyAtk, self.m_10431YPercent)
            tmpTarget:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, chgPhyAtk)
            if self.m_phyAtkChgList[tmpTarget:GetActorID()] then
                self.m_phyAtkChgList[tmpTarget:GetActorID()] = FixAdd(self.m_phyAtkChgList[tmpTarget:GetActorID()], chgPhyAtk)
            else
                self.m_phyAtkChgList[tmpTarget:GetActorID()] = chgPhyAtk
            end
            
            local curMagicAtk = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK)
            local chgMagicAtk = FixIntMul(curMagicAtk, self.m_10431YPercent)
            tmpTarget:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, chgMagicAtk, false)
            if self.m_magicAtkChgList[tmpTarget:GetActorID()] then
                self.m_magicAtkChgList[tmpTarget:GetActorID()] = FixAdd(self.m_magicAtkChgList[tmpTarget:GetActorID()], chgMagicAtk)
            else
                self.m_magicAtkChgList[tmpTarget:GetActorID()] = chgMagicAtk
            end
        end
    )
end

function Actor1043:ReduceAttr()
    local battleLogic = CtlBattleInst:GetLogic()
    ActorManagerInst:Walk(
        function(tmpTarget)

            if not battleLogic:IsFriend(self, tmpTarget, true) then
                return
            end

            if self.m_phyAtkChgList[tmpTarget:GetActorID()] then
                tmpTarget:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_PHY_ATK, FixIntMul(self.m_phyAtkChgList[tmpTarget:GetActorID()], -1))
            end
            self.m_phyAtkChgList[tmpTarget:GetActorID()] = nil

            if self.m_magicAtkChgList[tmpTarget:GetActorID()] then
                tmpTarget:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MAGIC_ATK, FixIntMul(self.m_magicAtkChgList[tmpTarget:GetActorID()], -1), false)
            end
            self.m_magicAtkChgList[tmpTarget:GetActorID()] = nil
        end
    )
end

function Actor1043:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skillItem = self.m_skillContainer:GetActiveByID(10431)
    if skillItem  then
        local skillLevel = skillItem:GetLevel()

        local skillCfg = ConfigUtil.GetSkillCfgByID(10431)
        if skillCfg then
            self.m_10431X = FixIntMul(SkillUtil.X(skillCfg, skillLevel), 1000)
            self.m_10431YPercent = FixDiv(SkillUtil.Y(skillCfg, skillLevel), 100)
        end
    end

    local skill10433Item = self.m_skillContainer:GetPassiveByID(10433)
    if skill10433Item  then
        local skillLevel = skill10433Item:GetLevel()
        self.m_10433Level = skillLevel
        self.m_10433Cfg = ConfigUtil.GetSkillCfgByID(10433)
        if self.m_10433Cfg then
            self.m_10433XPercent = FixDiv(SkillUtil.X(self.m_10433Cfg, skillLevel), 100)
            self.m_10433A = SkillUtil.A(self.m_10433Cfg, skillLevel)
            self.m_10433B = FixIntMul(SkillUtil.B(self.m_10433Cfg, skillLevel), 1000)
            if skillLevel >= 4 then
                self.m_10433CPercent = FixDiv(SkillUtil.C(self.m_10433Cfg, skillLevel), 100)
                if skillLevel == 6 then
                    self.m_10433DPercent = FixDiv(SkillUtil.D(self.m_10433Cfg, skillLevel), 100)
                end
            end
        end
    end
end

function Actor1043:OnSBBaoJi(actor, giver, deltaHP, hpChgReason, hurtType, judge)
    Actor.OnSBBaoJi(self, actor, giver, deltaHP, hpChgReason, hurtType, judge)
    
    if self:IsLive() and giver.actorID ~= self.m_actorID and deltaHP < 0 and hurtType == BattleEnum.HURTTYPE_MAGIC_HURT and judge == BattleEnum.ROUNDJUDGE_BAOJI then
        if self.m_10433Count < self.m_10433A then
            local giver = StatusGiver.New(self.m_actorID, 10433)  
            local buff = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, self.m_10433B)
            buff:SetMergeRule(StatusEnum.MERGERULE_MERGE)

            local baseMagicAtk = self:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAGIC_ATK)
            local chgMagicAtk = FixIntMul(baseMagicAtk, self.m_10433XPercent)
            
            buff:AddAttrPair(ACTOR_ATTR.FIGHT_MAGIC_ATK, chgMagicAtk)
            self:GetStatusContainer():Add(buff, self)
            self.m_10433Time = 0

            self.m_10433Count = FixAdd(self.m_10433Count, 1)
            self:ShowSkillMaskMsg(self.m_10433Count, BattleEnum.SKILL_MASK_YUANSHAO, TheGameIds.BattleBuffMaskGold)

            if self.m_10433Count >= self.m_10433A then
                if self.m_10433Level >= 4 and not self.m_isBaojiHurtChg then
                    ActorManagerInst:Walk(
                        function(tmpTarget)
                            if not CtlBattleInst:GetLogic():IsFriend(self, tmpTarget, true) then
                                return
                            end
                            
                            if self.m_baojiHurtChgList[tmpTarget:GetActorID()] then
                                return
                            end
    
                            tmpTarget:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_BAOJI_HURT, self.m_10433CPercent)
    
                            self.m_baojiHurtChgList[tmpTarget:GetActorID()] = self.m_10433CPercent
                            self.m_isBaojiHurtChg = true
                        end
                    )
                end
            end
        end
    end
end


return Actor1043