local BattleEnum = BattleEnum
local PreloadHelper = PreloadHelper
local ConfigUtil = ConfigUtil
local GameUtility = CS.GameUtility
local GameObject = CS.UnityEngine.GameObject
local table_insert = table.insert
local table_remove = table.remove
local ActorManagerInst = ActorManagerInst

local BaseCompMgr = require "GameLogic.Battle.Component.BaseCompMgr"
local ClientCompMgr = BaseClass("ClientCompMgr", BaseCompMgr)

local ACTOR_COMP_MAP = {
    [2031] = "GameLogic.Battle.Component.impl.Actor2031Component",
    [2032] = "GameLogic.Battle.Component.impl.Actor2031HandComponent",
    [2033] = "GameLogic.Battle.Component.impl.Actor2031HandComponent",
    [1004] = "GameLogic.Battle.Component.impl.Actor1004Component",
    [2040] = "GameLogic.Battle.Component.impl.Actor2040Component",
    [2034] = "GameLogic.Battle.Component.impl.Actor2034Component",
    [1076] = "GameLogic.Battle.Component.impl.Actor1076Component",
    [2091] = "GameLogic.Battle.Component.impl.Actor2091Component",
    [3501] = "GameLogic.Battle.Component.impl.Actor3501Component",
    [3502] = "GameLogic.Battle.Component.impl.Actor3501Component",
    [3503] = "GameLogic.Battle.Component.impl.Actor3501Component",
    [3506] = "GameLogic.Battle.Component.impl.Actor3501Component",
    [9999] = "GameLogic.Battle.Component.impl.HorseRaceActorComponent",
    [6015] = "GameLogic.Battle.Component.impl.Actor1015Component",
    [6001] = "GameLogic.Battle.Component.impl.Actor6001Component",
    [6002] = "GameLogic.Battle.Component.impl.Actor6001Component",
    [6003] = "GameLogic.Battle.Component.impl.Actor6001Component",
}

local BATTLE_COMP_MAP = {
    [BattleEnum.BattleType_COPY] = "GameLogic.Battle.Component.impl.CopyLogicComponent",
    [BattleEnum.BattleType_ARENA] = "GameLogic.Battle.Component.impl.ArenaLogicComponent",
    [BattleEnum.BattleType_FRIEND_CHALLENGE] = "GameLogic.Battle.Component.impl.FriendChallengeLogicComponent",
    [BattleEnum.BattleType_TEST] = "GameLogic.Battle.Component.impl.TestLogicComponent",
    [BattleEnum.BattleType_BOSS1] = "GameLogic.Battle.Component.impl.Boss1LogicComponent",
    [BattleEnum.BattleType_BOSS2] = "GameLogic.Battle.Component.impl.Boss2LogicComponent",
    [BattleEnum.BattleType_SHENSHOU] = "GameLogic.Battle.Component.impl.ShenShouCopyLogicComponent",
    [BattleEnum.BattleType_PLOT] = "GameLogic.Battle.Component.impl.PlotLogicComponent",
    [BattleEnum.BattleType_CAMPSRUSH] = "GameLogic.Battle.Component.impl.CampsRushLogicComponent",
    [BattleEnum.BattleType_SHENBING] = "GameLogic.Battle.Component.impl.ShenbingLogicComponent",
    [BattleEnum.BattleType_YUANMEN] = "GameLogic.Battle.Component.impl.YuanmenLogicComponent",
    [BattleEnum.BattleType_INSCRIPTION] = "GameLogic.Battle.Component.impl.InscriptionCopyLogicComponent",
    [BattleEnum.BattleType_GUILD_BOSS] = "GameLogic.Battle.Component.impl.GuildBossLogicComponent",
    [BattleEnum.BattleType_GRAVE] = "GameLogic.Battle.Component.impl.GraveLogicComponent",
    [BattleEnum.BattleType_GUILD_WARCRAFT] = "GameLogic.Battle.Component.impl.GuildWarLogicComponent",
    [BattleEnum.BattleType_ROB_GUILD_HUSONG] = "GameLogic.Battle.Component.impl.GuildWarRobLogicComponent",
    [BattleEnum.BattleType_LIEZHUAN] = "GameLogic.Battle.Component.impl.LieZhuanLogicComponent",
    [BattleEnum.BattleType_QUNXIONGZHULU] = "GameLogic.Battle.Component.impl.GroupHerosLogicComponent", 
    [BattleEnum.BattleType_LIEZHUAN_TEAM] = "GameLogic.Battle.Component.impl.LieZhuanTeamLogicComponent",
    [BattleEnum.BattleType_HORSERACE] = "GameLogic.Battle.Component.impl.HorseRaceLogicComponent",
}

function ClientCompMgr:__init()
    self.chara_root = false
    self.map_root = false
    self.objects_root = false
    self.m_actorQueue = {}
end

function ClientCompMgr:__delete()
    self.chara_root = nil
    self.map_root = nil
    self.objects_root = nil
    self.m_actorQueue = nil
end

function ClientCompMgr:Clear()
    self.chara_root = nil
    self.map_root = nil
    self.objects_root = nil
    self.m_actorQueue = {}
end

function ClientCompMgr:LateUpdate(deltaTime)
    if not self.m_actorQueue then
        return
    end

    local count = #self.m_actorQueue
    if count > 0 then

        local actorID = self.m_actorQueue[count]
        

        local actor = ActorManagerInst:GetActor(actorID)
        if actor and actor:IsValid() then
            self:LoadActorObj(actor)
        end

        table_remove(self.m_actorQueue, count)
    end
end

function ClientCompMgr:LoadActorObj(actor)
    local resID = actor:GetWujiangID()
    local wuqiLevel = actor:GetWuqiLevel()

    local res_path = PreloadHelper.GetWujiangPath(resID, wuqiLevel)
    GameObjectPoolInst:GetGameObjectAsync(res_path,
        function(inst, actor)
            if not IsNull(inst) then
                if actor and actor:IsValid() then
                    inst.transform:SetParent(self.chara_root)
            
                    local comp = nil

                    local cls = ACTOR_COMP_MAP[resID]
                    if cls then
                        local compCLs = require(cls)
                        comp = compCLs.New()
                    else
                        comp = ActorComponent.New()
                    end
                    comp:OnBorn(inst, actor)
                else
                    GameObjectPoolInst:RecycleGameObject(res_path, inst)
                end
            end
        end,
    actor)
end

function ClientCompMgr:CreateActorComponent(actor, immediately)
    if not (self.chara_root) then
        self.chara_root = GameObject("CharacterRoot").transform
    end

    if immediately then
        self:LoadActorObj(actor)
    else
        table_insert(self.m_actorQueue, actor:GetActorID())
    end
end


function ClientCompMgr:CreateBattleLogicComponent(battleType, battleLogic)
    if not battleLogic then return end

    local cls = BATTLE_COMP_MAP[battleType]
    if cls then
        local BTClass = require(cls)
        local comp = BTClass.New(battleLogic)
        battleLogic:RegisterComponent(comp)
    else
        print('Error no battle type component')
    end
end

function ClientCompMgr:InitMap(mapCfg)
    if not (self.map_root) then
        self.map_root = GameObject.Find(mapCfg.scenename).transform
    end
end

function ClientCompMgr:CreateMediumComponent(medium)
    if not self.objects_root then
        self.objects_root = GameObject("ObjectsRoot").transform
    end

    local mediumID = medium:GetMediumID()
    local objectCfg = ConfigUtil.GetObjectCfgByID(mediumID)
    if objectCfg then
        local res_path = PreloadHelper.GetObjectPath(objectCfg)

        GameObjectPoolInst:GetGameObjectAsync(res_path,
            function(inst, medium)
                if medium and medium:IsValid() then
                    inst.transform:SetParent(self.objects_root)
                    local comp = MediumComponent.New()
                    comp:OnBorn(inst, medium)
                    comp:SetLayerState(BattleEnum.LAYER_STATE_NORMAL)
                else 
                    GameObjectPoolInst:RecycleGameObject(res_path, inst)
                end
            end,
        medium)
    end
end

function ClientCompMgr:GetMapRoot()
    return self.map_root
end

return ClientCompMgr