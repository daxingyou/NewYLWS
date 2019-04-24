local StatusFactoryInst = StatusFactoryInst
local ACTOR_ATTR = ACTOR_ATTR
local Formular = Formular
local StatusGiver = StatusGiver
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local FixDiv = FixMath.div
local FixAdd = FixMath.add 

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill20572 = BaseClass("Skill20572", SkillBase)

function Skill20572:Perform(performer, target, performPos, special_param)
    if not performer then
        return
    end
      --1-2
    --使所有队友的攻击速度和移动速度增加{x1}%，持续{A}秒
    --3-4
    --并令其下次造成伤害时可使目标定身{B}秒
    ActorManagerInst:Walk(
        function(tmpTarget)       
            if not CtlBattleInst:GetLogic():IsFriend(performer, tmpTarget, true) then
                return
            end
           
            if not self:InRange(performer, tmpTarget, performPos, performer:GetPosition()) then
                return
            end
          
            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
              return  
            end

            local giver = StatusGiver.New(performer:GetActorID(), 20572) 
            local buffStatus = StatusFactoryInst:NewStatusBuff(giver, BattleEnum.AttrReason_SKILL, FixIntMul(self:A(), 1000),{205704})  
            local decMul = FixDiv(self:X(), 100)
            local curMoveSpeed = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_MOVESPEED)
            local chgMoveSpeed = FixIntMul(curMoveSpeed, decMul)
            local curAtkSpeed = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.BASE_ATKSPEED)
            local chgAtkSpeed = FixIntMul(curAtkSpeed, decMul)

            buffStatus:AddAttrPair(ACTOR_ATTR.FIGHT_MOVESPEED, FixMul(chgMoveSpeed, 1))
            buffStatus:AddAttrPair(ACTOR_ATTR.FIGHT_ATKSPEED, FixMul(chgAtkSpeed, 1))
            self:AddStatus(performer, tmpTarget, buffStatus) 

             --1技能的定身效果
            performer:Perform20572AtkEffect(tmpTarget) 
        end
    )
    if self.m_level >= 3 then
        performer:Add20572AtkCount()
    end
end



return Skill20572