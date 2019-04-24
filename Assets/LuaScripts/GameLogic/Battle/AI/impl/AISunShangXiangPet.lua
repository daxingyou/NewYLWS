
local AIBase = require "GameLogic.Battle.AI.AIBase"
local FixNormalize = FixMath.Vector3Normalize
local FixAdd = FixMath.add
local FixAngle = FixMath.Vector3Angle  --角度
local table_insert = table.insert
local table_remove = table.remove
local SKILL_PERFORM_MODE = SKILL_PERFORM_MODE
local SKILL_CHK_RESULT = SKILL_CHK_RESULT
local FixVetor3RotateAroundY = FixMath.Vector3RotateAroundY
local BattleEnum = BattleEnum
local ConfigUtil = ConfigUtil
local SkillPoolInst = SkillPoolInst
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst
local ACTOR_ATTR = ACTOR_ATTR

local AISunShangXiangPet = BaseClass("AISunShangXiangPet", AIBase)

local PetState = {
    PetState_Normal = 1,
    PetState_Leave = 2,
    PetState_Back = 3,
}

function AISunShangXiangPet:__init(actor)
    self.m_followOwnerInterval = 0
    self.m_targetPos = false
    self.m_targetIDList = {}
    self.m_lastTargetID = 0
    self.m_petState = PetState.PetState_Normal
    self.m_aiType = BattleEnum.AITYPE_SUNSHANGXIANG_PET
    self.m_addMoveSpeed = false
end

function AISunShangXiangPet:AI(deltaMS)
    local owner = ActorManagerInst:GetActor(self.m_selfActor:GetOwnerID())
    if not owner or not owner:IsLive() then
        self.m_selfActor:KillSelf()
        return
    end

    local currState = self.m_selfActor:GetCurrStateID()
    if self.m_petState == PetState.PetState_Normal then
        if #self.m_targetIDList > 0 then
            local firList = self.m_targetIDList[1]
            if firList then
                self.m_lastTargetID = firList.currTargetActorID
                table_remove(self.m_targetIDList, 1)
                self.m_petState = PetState.PetState_Leave
            end
        else            
            if currState == BattleEnum.ActorState_IDLE or currState == BattleEnum.ActorState_MOVE then
                self:FollowOwner(owner, deltaMS)
                
                if currState == BattleEnum.ActorState_IDLE then
                    self.m_selfActor:SetForward(owner:GetForward())
                end
            end           
        end       

    elseif self.m_petState == PetState.PetState_Leave then
        local target = ActorManagerInst:GetActor(self.m_lastTargetID)
        if not target or not target:IsLive() then
            self.m_petState = PetState.PetState_Back
            return
        end
        
        if currState == BattleEnum.ActorState_IDLE or currState == BattleEnum.ActorState_MOVE then
            local skillItem = self.m_selfActor:GetSkillContainer():GetByID(32081)
            if skillItem then
                if not self.m_addMoveSpeed then
                    self.m_addMoveSpeed = true
                    self.m_selfActor:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MOVESPEED, 500, false)
                end
                self:PetPerformSkill(skillItem, target, deltaMS)
            end
        end

    elseif self.m_petState == PetState.PetState_Back then
        self:FollowOwner(owner, deltaMS)

        local dir = self.m_targetPos - self.m_selfActor:GetPosition()
        dir.y = 0
        local leftDistance = dir:SqrMagnitude()
        if leftDistance <= 0.04 then            
            self.m_selfActor:SetForward(owner:GetForward())
            self.m_petState = PetState.PetState_Normal
        end        
    end 
end


function AISunShangXiangPet:Attack(targetID)
    table_insert(self.m_targetIDList, {currTargetActorID = targetID})
end

function AISunShangXiangPet:FollowOwner(owner, deltaMS)   
    if not owner then
        return
    end

    self.m_targetPos = owner:GetPosition():Clone()
    local dir = owner:GetForward()
    local leftDir = FixVetor3RotateAroundY(dir, -89.9)
    self.m_targetPos:Add(FixNormalize(leftDir))

    local pathHandler = CtlBattleInst:GetPathHandler()
    if pathHandler and CtlBattleInst:GetLogic():IsPathHandlerHitTest(self.m_selfActor) then
        local x,y,z = self.m_selfActor:GetPosition():GetXYZ()
        local x2, y2, z2 = self.m_targetPos:GetXYZ()
        local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
        if hitPos then
            self.m_targetPos:SetXYZ(hitPos.x , self.m_selfActor:GetPosition().y, hitPos.z)
        end
    end

    if self.m_followOwnerInterval == 0 or self.m_followOwnerInterval > 100 then
        self.m_followOwnerInterval = 0
        local tmpDir = self.m_selfActor:GetPosition() - self.m_targetPos
        tmpDir.y = 0
        local distance = tmpDir:SqrMagnitude()
        if distance >= 0.4 then
            self.m_selfActor:SimpleMove(self.m_targetPos)
        else
            self.m_selfActor:SetForward(dir)

            if self.m_addMoveSpeed then
                self.m_addMoveSpeed = false
                self.m_selfActor:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MOVESPEED, -500, false)
            end
        end
    end

    self.m_followOwnerInterval = FixAdd(self.m_followOwnerInterval, deltaMS)
end

function AISunShangXiangPet:PetPerformSkill(skillItem, target, deltaMS)
    local tmpRet = SKILL_CHK_RESULT.ERR

    local skillcfg = ConfigUtil.GetSkillCfgByID(32081)
    if skillcfg then    
        if self:InnerCheck(skillItem, skillcfg, true, target) then
            local skillbase = SkillPoolInst:GetSkill(skillcfg, skillItem:GetLevel())
            if skillbase then 
                tmpRet = skillbase:CheckPerform(self.m_selfActor, target)                
            end
        end
    end
    
    if tmpRet == SKILL_CHK_RESULT.OK then
        self:PerformSkill(target, skillItem, target:GetPosition(), SKILL_PERFORM_MODE.AI)
    else
        if self:ShouldFollowEnemy(tmpRet) then
            local targetPos = target:GetPosition()
            if self.m_followInterval == 0 or self.m_followInterval >= 1000 then
                self.m_followInterval = 0
        
                local randPos = targetPos
                local move = true
                local battleLogic = CtlBattleInst:GetLogic()
                if self.m_inFightMS < battleLogic:GetFollowDirectMS() then
                    local myPos = self.m_selfActor:GetPosition()
                    local targetDir = targetPos - myPos
                    targetDir.y = 0
        
                    local degrees = FixAngle(self.m_startForward, targetDir)
                    if degrees <= 30 then
                        if self.m_lastForward == self.m_startForward then
                            move = false
                        else
                            randPos = self.m_startForward * battleLogic:GetFollowDirectDis() 
                            randPos:Add(myPos)
                        end
                        self.m_startForward:CopyTo(self.m_lastForward)
                    else
                        targetDir:CopyTo(self.m_lastForward)
                    end
        
                    self:SetTarget(0)
                end
        
                if move then
                    self.m_selfActor:SimpleMove(randPos)
                    self:IntoFollowSpecial(100)
                end
            end
        
            self.m_followInterval = FixAdd(self.m_followInterval, deltaMS)
        end
    end
end

function AISunShangXiangPet:SelfAttackEnd()
    self.m_petState = PetState.PetState_Normal
end

function AISunShangXiangPet:SelfCheckMoveSpeed()
    if self.m_addMoveSpeed then
        self.m_addMoveSpeed = false
        self.m_selfActor:GetData():AddFightAttr(ACTOR_ATTR.FIGHT_MOVESPEED, -500, false)
    end
end

return AISunShangXiangPet