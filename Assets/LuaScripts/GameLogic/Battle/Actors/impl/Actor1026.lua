local StatusGiver = StatusGiver
local BattleEnum = BattleEnum
local FixIntMul = FixMath.muli
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local FixDiv = FixMath.div
local FixMul = FixMath.mul
local FixSub = FixMath.sub
local table_remove = table.remove
local table_insert = table.insert
local FixNormalize = FixMath.Vector3Normalize
local FixNewVector3 = FixMath.NewFixVector3
local MediumManagerInst = MediumManagerInst
local SkillPoolInst = SkillPoolInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local ACTOR_ATTR = ACTOR_ATTR

local Actor = require "GameLogic.Battle.Actors.Actor"
local Actor1026 = BaseClass("Actor1026", Actor)

local ChordState = {
    Protect = 1, -- 保护和弦
    Grief = 2, -- 悲愤和弦
    Inspire = 3, -- 振奋和弦
}

function Actor1026:__init()
    self.m_10263A = 0
    self.m_10263B = 0
    self.m_10263X = 0
    self.m_10263Y = 0
    self.m_10263Z = 0
    self.m_10263Level = 0
    self.m_10263SkillBase = nil
    self.m_10263SkillCfg = nil
    self.m_10262Level = 0

    self.m_chordState = ChordState.Protect
    self.m_chordIDList = {}
    self.m_swithChord = false
end

function Actor1026:SwithChordState()
    self.m_swithChord = true
    if self.m_chordState == ChordState.Protect then
        self.m_chordState = ChordState.Grief
        self:ShowSkillMaskMsg(0, BattleEnum.SKILL_MASK_CAIWENJI_ANG, TheGameIds.BattleBuffMaskRed)

    elseif self.m_chordState == ChordState.Grief then
        self.m_chordState = ChordState.Inspire
        self:ShowSkillMaskMsg(0, BattleEnum.SKILL_MASK_CAIWENJI_POS, TheGameIds.BattleBuffMaskYellow)

    elseif self.m_chordState == ChordState.Inspire then
        self.m_chordState = ChordState.Protect
        self:ShowSkillMaskMsg(0, BattleEnum.SKILL_MASK_CAIWENJI_PRO, TheGameIds.BattleBuffMaskGreen)
    end
end

function Actor1026:LogicOnFightStart(currWave)
    self.m_chordState = ChordState.Protect
    self:ShowSkillMaskMsg(0, BattleEnum.SKILL_MASK_CAIWENJI_PRO, TheGameIds.BattleBuffMaskGreen)
end

function Actor1026:OnBorn(create_param)
    Actor.OnBorn(self, create_param)

    local skillItem1 = self.m_skillContainer:GetActiveByID(10262)
    if skillItem1  then
        self.m_10262Level = skillItem1:GetLevel()
    end
    
    local skillItem = self.m_skillContainer:GetPassiveByID(10263)
    if skillItem  then
        local level = skillItem:GetLevel()
        self.m_10263Level = level
        local skillCfg = ConfigUtil.GetSkillCfgByID(10263)
        self.m_10263SkillCfg = skillCfg
        if skillCfg then
            self.m_10263A = SkillUtil.A(skillCfg, level)
            self.m_10263B = SkillUtil.B(skillCfg, level)
            self.m_10263X = SkillUtil.X(skillCfg, level)
            self.m_10263Y = SkillUtil.Y(skillCfg, level)
            self.m_10263Z = SkillUtil.Y(skillCfg, level)

            self.m_10263SkillBase = SkillPoolInst:GetSkill(skillCfg, level)
        end
    end
end


function Actor1026:OnHurtOther(other, skillCfg, keyFrame, chgVal, hurtType, judge)
    Actor.OnHurtOther(self, other, skillCfg, keyFrame, chgVal, hurtType, judge)
    if SkillUtil.IsAtk(skillCfg) and other and other:IsLive() then
        self:ChordPassiveSkill(other)
    end
end

function Actor1026:ChordPassiveSkill(other)
    if self.m_10263SkillCfg and self.m_10263SkillBase then
        local count = 0
        if self.m_10263Level <= 4 then
            count = self.m_10263A
        else
            count = self.m_10263B
        end
        local mul = 1
        if self.m_10262Level >= 4 and self.m_swithChord then
            mul = 2
            self.m_swithChord = false
        end

        local pos = other:GetPosition()
        local forward = other:GetForward()

        local otherRight = other:GetRight() * -0.01
        local mulForward = forward * 1.13

        for i=1, count do
            local friendActor = self:RandActor()
            if friendActor and friendActor:IsLive() then            
                local p = FixNewVector3(pos.x, FixAdd(pos.y, 1.3), pos.z)
                p:Add(mulForward)
                p:Add(otherRight)

                local giver = StatusGiver.New(self:GetActorID(), 10263)
                local mediaParam = {
                    targetActorID = friendActor:GetActorID(),
                    keyFrame = 0,
                    speed = 17,
                    state = self.m_chordState,
                    chordMul = mul
                }
                
                MediumManagerInst:CreateMedium(MediumEnum.MEDIUMTYPE_CHORD, 40, giver, self.m_10263SkillBase, p, forward, mediaParam)
            end
        end

        self.m_chordIDList = {}
    end
end

function Actor1026:RandActor()
    --  -- 1猛将2近卫3豪杰4神射5仙法  CommonDefine
    --  PROF_1 = 1,
    --  PROF_2 = 2,
    --  PROF_3 = 3,
    --  PROF_4 = 4,
    --  PROF_5 = 5,
    -- （反弹目标的优先级：神射＞猛将＞豪杰＞近卫＞仙法）  4 1 3 2 5
    local prof1List = {}
    local prof2List = {}
    local prof3List = {}
    local prof4List = {}
    local prof5List = {}


    local minHPPercent = 99999999
    local maxNu = 0
    local tmpActor1 = false
    local tmpActor2 = false

    local battleLogic = CtlBattleInst:GetLogic()
    ActorManagerInst:Walk(
        function(tmpTarget)
            local battleLogic = CtlBattleInst:GetLogic()
            if not battleLogic:IsFriend(self, tmpTarget, true) then
                return
            end

            local tmpTargetID = tmpTarget:GetActorID()
            for _,targetID in pairs(self.m_chordIDList) do 
                if tmpTargetID == targetID then
                    return
                end
            end

            if self.m_chordState == ChordState.Grief then
                local prof = tmpTarget:GetProf()
                if prof == CommonDefine.PROF_1 then
                    table_insert(prof1List, tmpTarget)

                elseif prof == CommonDefine.PROF_2 then
                    table_insert(prof2List, tmpTarget)

                elseif prof == CommonDefine.PROF_3 then
                    table_insert(prof3List, tmpTarget)

                elseif prof == CommonDefine.PROF_4 then
                    table_insert(prof4List, tmpTarget)

                elseif prof == CommonDefine.PROF_5 then
                    table_insert(prof5List, tmpTarget)
                end

            elseif self.m_chordState == ChordState.Protect then
                local curHp = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_HP)
                local maxHp = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_MAXHP)
                local curHpPercent = FixDiv(curHp, maxHp)
                if curHpPercent < minHPPercent then
                    minHPPercent = curHpPercent
                    tmpActor1 = tmpTarget
                end

            elseif self.m_chordState == ChordState.Inspire then
                if not tmpTarget:IsNuqiFull() then
                    local curNuqi = tmpTarget:GetData():GetNuqi()
                    if curNuqi > maxNu then
                        maxNu = curNuqi
                        tmpActor2 = tmpTarget
                    end
                end
            end
        end
    )

    local tmpActor = false
    if self.m_chordState == ChordState.Grief then
        local count4 = #prof4List
        if count4 > 0 then
            local index = FixMod(BattleRander.Rand(), count4)
            index = FixAdd(index, 1)
            tmpActor = prof4List[index]
            table_insert(self.m_chordIDList, tmpActor:GetActorID())
            return tmpActor
        end

        local count1 = #prof1List
        if count1 > 0 then
            local index = FixMod(BattleRander.Rand(), count1)
            index = FixAdd(index, 1)
            tmpActor = prof1List[index]
            table_insert(self.m_chordIDList, tmpActor:GetActorID())
            return tmpActor
        end

        local count3 = #prof3List
        if count3 > 0 then
            local index = FixMod(BattleRander.Rand(), count3)
            index = FixAdd(index, 1)
            tmpActor = prof3List[index]
            table_insert(self.m_chordIDList, tmpActor:GetActorID())
            return tmpActor
        end

        local count2 = #prof2List
        if count2 > 0 then
            local index = FixMod(BattleRander.Rand(), count2)
            index = FixAdd(index, 1)
            tmpActor = prof2List[index]
            table_insert(self.m_chordIDList, tmpActor:GetActorID())
            return tmpActor
        end

        local count5 = #prof5List
        if count5 > 0 then
            local index = FixMod(BattleRander.Rand(), count5)
            index = FixAdd(index, 1)
            tmpActor = prof5List[index]
            table_insert(self.m_chordIDList, tmpActor:GetActorID())
            return tmpActor
        end
    
    elseif self.m_chordState == ChordState.Protect then
        tmpActor = tmpActor1

    elseif self.m_chordState == ChordState.Inspire then
        tmpActor = tmpActor2

    end

    if not tmpActor then
        local count = #self.m_chordIDList
        if count > 0 then
            local index = FixMod(BattleRander.Rand(), count)
            index = FixAdd(index, 1)
            tmpActorID = self.m_chordIDList[index]
            if tmpActorID > 0 then
                local actor = ActorManagerInst:GetActor(tmpActorID)
                return actor
            end
        end
    else
        table_insert(self.m_chordIDList, tmpActor:GetActorID())
    end

    return tmpActor
end


return Actor1026