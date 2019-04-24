local table_insert = table.insert
local table_remove = table.remove
local FixAdd = FixMath.add
local CtlBattleInst = CtlBattleInst
local ActorManager = BaseClass("ActorManager", Singleton)


local ID_CLASS_MAP = {
    [1001] = "GameLogic.Battle.Actors.impl.Actor1001",
    [1002] = "GameLogic.Battle.Actors.impl.Actor1002",
    [1003] = "GameLogic.Battle.Actors.impl.Actor1003",
    [1004] = "GameLogic.Battle.Actors.impl.Actor1004",
    [1006] = "GameLogic.Battle.Actors.impl.Actor1006",
    [1013] = "GameLogic.Battle.Actors.impl.Actor1013",
    [1014] = "GameLogic.Battle.Actors.impl.Actor1014",
    [1015] = "GameLogic.Battle.Actors.impl.Actor1015",
    [1017] = "GameLogic.Battle.Actors.impl.Actor1017",
    [1018] = "GameLogic.Battle.Actors.impl.Actor1018",
    [1026] = "GameLogic.Battle.Actors.impl.Actor1026",
    [1029] = "GameLogic.Battle.Actors.impl.Actor1029",
    [1034] = "GameLogic.Battle.Actors.impl.Actor1034",
    [1035] = "GameLogic.Battle.Actors.impl.Actor1035",
    [1038] = "GameLogic.Battle.Actors.impl.Actor1038",
    [1040] = "GameLogic.Battle.Actors.impl.Actor1040",
    [1041] = "GameLogic.Battle.Actors.impl.Actor1041",
    [1042] = "GameLogic.Battle.Actors.impl.Actor1042",
    [1043] = "GameLogic.Battle.Actors.impl.Actor1043",
    [1044] = "GameLogic.Battle.Actors.impl.Actor1044",
    [1046] = "GameLogic.Battle.Actors.impl.Actor1046",
    [1047] = "GameLogic.Battle.Actors.impl.Actor1047",
    [1048] = "GameLogic.Battle.Actors.impl.Actor1048",
    [1061] = "GameLogic.Battle.Actors.impl.Actor1061",
    [1062] = "GameLogic.Battle.Actors.impl.Actor1062",
    [1075] = "GameLogic.Battle.Actors.impl.Actor1075",
    [1076] = "GameLogic.Battle.Actors.impl.Actor1076",
    [1082] = "GameLogic.Battle.Actors.impl.Actor1082",
    [1111] = "GameLogic.Battle.Actors.impl.Actor1111",
    [1201] = "GameLogic.Battle.Actors.impl.Actor1201",
    [1214] = "GameLogic.Battle.Actors.impl.Actor1214",    
    [1217] = "GameLogic.Battle.Actors.impl.Actor1217",
    [2008] = "GameLogic.Battle.Actors.impl.Actor2008",
    [2002] = "GameLogic.Battle.Actors.impl.Actor2002",
    [2005] = "GameLogic.Battle.Actors.impl.Actor2005",
    [2010] = "GameLogic.Battle.Actors.impl.Actor2010",
    [2030] = "GameLogic.Battle.Actors.impl.Actor2030",
    [2031] = "GameLogic.Battle.Actors.impl.Actor2031",
    [2032] = "GameLogic.Battle.Actors.impl.Actor2031Hand",
    [2033] = "GameLogic.Battle.Actors.impl.Actor2031Hand",
    [2034] = "GameLogic.Battle.Actors.impl.Actor2034",
    [2037] = "GameLogic.Battle.Actors.impl.Actor2037",
    [2040] = "GameLogic.Battle.Actors.impl.Actor2040",
    [2043] = "GameLogic.Battle.Actors.impl.Actor2043",
    [2044] = "GameLogic.Battle.Actors.impl.Actor2044",
    [2046] = "GameLogic.Battle.Actors.impl.Actor2046",
    [2048] = "GameLogic.Battle.Actors.impl.Actor2048",
    [2091] = "GameLogic.Battle.Actors.impl.Actor2091",
    [2092] = "GameLogic.Battle.Actors.impl.Actor2092",
    [2093] = "GameLogic.Battle.Actors.impl.Actor2093",
    [2097] = "GameLogic.Battle.Actors.impl.Actor2097",
    [3208] = "GameLogic.Battle.Actors.impl.Actor3208",
    [3501] = "GameLogic.Battle.Actors.impl.Actor3501",
    [3502] = "GameLogic.Battle.Actors.impl.Actor3502",
    [3503] = "GameLogic.Battle.Actors.impl.Actor3503",
    [3506] = "GameLogic.Battle.Actors.impl.Actor3506",
    [4007] = "GameLogic.Battle.Actors.impl.Actor4007",
    [4008] = "GameLogic.Battle.Actors.impl.Actor4008",
    [4009] = "GameLogic.Battle.Actors.impl.Actor4009",
    [4013] = "GameLogic.Battle.Actors.impl.Actor2034HeXin",
    [4014] = "GameLogic.Battle.Actors.impl.Actor2034HeXin",
    [6001] = "GameLogic.Battle.Actors.impl.Actor6001",
    [6002] = "GameLogic.Battle.Actors.impl.Actor6001",
    [6003] = "GameLogic.Battle.Actors.impl.Actor6001",
    [1009] = "GameLogic.Battle.Actors.impl.Actor1009",
    [4015] = "GameLogic.Battle.Actors.impl.Actor4015",
    [1205] = "GameLogic.Battle.Actors.impl.Actor1205",
    [3207] = "GameLogic.Battle.Actors.impl.Actor3207",
    [2070] = "GameLogic.Battle.Actors.impl.Actor2070",
    [2061] = "GameLogic.Battle.Actors.impl.Actor2061",
    [2015] = "GameLogic.Battle.Actors.impl.Actor2015",
    [2012] = "GameLogic.Battle.Actors.impl.Actor2012",
    [2026] = "GameLogic.Battle.Actors.impl.Actor2026",
    [2014] = "GameLogic.Battle.Actors.impl.Actor2014",
    [1011] = "GameLogic.Battle.Actors.impl.Actor1011",
    [2088] = "GameLogic.Battle.Actors.impl.Actor2088",
    [1008] = "GameLogic.Battle.Actors.impl.Actor1008",
    [1021] = "GameLogic.Battle.Actors.impl.Actor1021",
    [2086] = "GameLogic.Battle.Actors.impl.Actor2086",
    [2087] = "GameLogic.Battle.Actors.impl.Actor2087",
    [2089] = "GameLogic.Battle.Actors.impl.Actor2089",
    [2090] = "GameLogic.Battle.Actors.impl.Actor2090",
    [1021] = "GameLogic.Battle.Actors.impl.Actor1021",
    [2068] = "GameLogic.Battle.Actors.impl.Actor2068",
    [2057] = "GameLogic.Battle.Actors.impl.Actor2057",
    [2056] = "GameLogic.Battle.Actors.impl.Actor2056",
    [2054] = "GameLogic.Battle.Actors.impl.Actor2054",
    [1022] = "GameLogic.Battle.Actors.impl.Actor1022",
    [2029] = "GameLogic.Battle.Actors.impl.Actor2029",
    [6015] = "GameLogic.Battle.Actors.impl.Actor1015",
    [4050] = "GameLogic.Battle.Actors.impl.Actor4050",
    [9999] = "GameLogic.Battle.Actors.impl.HorseRaceActor",
    [1039] = "GameLogic.Battle.Actors.impl.Actor1039",
    [2200] = "GameLogic.Battle.Actors.impl.Actor2200",
    [1028] = "GameLogic.Battle.Actors.impl.Actor1028",
    [2201] = "GameLogic.Battle.Actors.impl.Actor2201",
    [1203] = "GameLogic.Battle.Actors.impl.Actor1203",
    [2001] = "GameLogic.Battle.Actors.impl.Actor2001",
    [2067] = "GameLogic.Battle.Actors.impl.Actor2067",
}


function ActorManager:__init()
    self.m_dic = {}     -- id -> obj
    self.m_actorList = {}   -- id[]

    -- 有可能在遍历的过程中增减
    self.m_delList = {}
    self.m_seq = 0
end

function ActorManager:Clear()
    for id, actor in pairs(self.m_dic) do
        if actor then
            actor:Delete()
        end
    end

    self.m_dic = {}
    self.m_seq = 0
    self.m_actorList = {}
    self.m_delList = {}
end

function ActorManager:ReovkeAll()
    local count = #self.m_delList
    for i = 1, count do
        local actor_id = self.m_delList[i]
        local actor = self.m_dic[actor_id]
        if actor then
            actor:Delete()
        end
        self.m_dic[actor_id] = nil

        for k = 1, #self.m_actorList do
            if actor_id == self.m_actorList[k] then
                table_remove(self.m_actorList, k)
                break
            end
        end
    end

    if count > 0 then
        self.m_delList = {}
    end
end

function ActorManager:Update(deltaTime)
    self:ReovkeAll()

    local count = #self.m_actorList
    for i = 1, count do                 
        local actor_id = self.m_actorList[i]
        local actor = self.m_dic[actor_id]
        if actor and actor:IsValid() then
            actor:Update(deltaTime)
        end
    end
end

function ActorManager:MakeID()
    self.m_seq = self.m_seq + 1
    return self.m_seq
end

function ActorManager:GetActor(actor_id)
    local actor = self.m_dic[actor_id]
    if actor and actor:IsValid() then
        return actor
    end
    return nil
end

function ActorManager:CreateActor(create_param)
    -- todo switch(actor_type) case ....
    local id = self:MakeID()
    local actor = self:CreateByID(id, create_param.wujiangID)
    self.m_dic[id] = actor
    table_insert(self.m_actorList, id)

    actor:OnCreate(create_param)
    CtlBattleInst:AddPauseListener(actor)
    local battleLogic = CtlBattleInst:GetLogic()
    if battleLogic then
        battleLogic:OnActorCreated(actor)
    end
    
    return actor
end

function ActorManager:RemoveActorByID(actor_id)
    local actor = self.m_dic[actor_id]
    if actor and actor:IsValid() then
        actor:ToBeInvalid()
        CtlBattleInst:RemovePauseListener(actor)
    end

    table_insert(self.m_delList, actor_id)
end

function ActorManager:GetActorList(filter)
    local retList = {}
    local count = #self.m_actorList
    for i = 1, count do
        local actor_id = self.m_actorList[i]
        local actor = self.m_dic[actor_id]
        if actor and actor:IsValid() then
            if filter then
                if filter(actor) then
                    table_insert(retList, actor)
                end
            else
                table_insert(retList, actor)
            end
        end
    end
    return retList
end

function ActorManager:GetOneActor(filter)
    if not filter then return nil end
    
    local count = #self.m_actorList
    for i = 1, count do
        local actor_id = self.m_actorList[i]
        local actor = self.m_dic[actor_id]
        if actor and actor:IsValid() then
            if filter(actor) then
                return actor
            end
        end
    end

    return nil
end

function ActorManager:Walk(filter)
    if not filter then return end

    local count = #self.m_actorList
    for i = 1, count do
        local actor_id = self.m_actorList[i]
        local actor = self.m_dic[actor_id]
        if actor and actor:IsValid() then
            filter(actor)
        end
    end
end

function ActorManager:IsCampAllDie(camp)
    for id, actor in pairs(self.m_dic) do
        if actor and actor:IsValid() and actor:GetCamp() == camp and not actor:IsCalled() then
            if actor:IsLive() then
                return false
            end
        end
    end

    return true
end

function ActorManager:IsAnyCampAllDie()
    local leftAllDie = true
    local rightAllDie = true
    for _, actor in pairs(self.m_dic) do
        if not leftAllDie and not rightAllDie then
            return false
        end

        local nextJudge = true
        if leftAllDie then
            if actor and actor:IsValid() and actor:GetCamp() == BattleEnum.ActorCamp_LEFT and not actor:IsCalled() then
                nextJudge = false
                if actor:IsLive() then
                    leftAllDie = false
                end
            end
        end

        if nextJudge and rightAllDie then
            if actor and actor:IsValid() and actor:GetCamp() == BattleEnum.ActorCamp_RIGHT and not actor:IsCalled() then
                if actor:IsLive() then
                    rightAllDie = false
                end
            end
        end
    end

    return leftAllDie or rightAllDie
end

function ActorManager:CreateByID(actor_id, wujiang_id)
    local cls = ID_CLASS_MAP[wujiang_id]
    if cls then
        local cc = require(cls)
        return cc.New(actor_id)
    else
        return Actor.New(actor_id)
    end
end

return ActorManager