local MainCityModel = BaseClass("MainCityModel")

local math_ceil = math.ceil
local table_insert = table.insert
local table_remove = table.remove
local BattleEnum = BattleEnum
local string_format = string.format
local Vector3 = Vector3
local GameObject = CS.UnityEngine.GameObject
local Type_BoxCollider = typeof(CS.UnityEngine.BoxCollider)
local GameUtility = CS.GameUtility
local CommonDefine = CommonDefine
local UILogicUtil = UILogicUtil
local LineupMgr = Player:GetInstance():GetLineupMgr()
local WuJiangMgr = Player:GetInstance():GetWujiangMgr()

local StandPosList = {
        Vector3.New(0, 0, 5.64), Vector3.New(-2.35, 0, 6.41), 
        Vector3.New(2.35, 0, 6.41), Vector3.New(-1.19, 0, 7.68),  Vector3.New(1.19, 0, 7.68)
    }

local StandRotList = {
        Vector3.New(0, 180, 0), Vector3.New(0, 180, 0),  Vector3.New(0, 180, 0),  Vector3.New(0, 180, 0),  Vector3.New(0, 180, 0)
    }

local ColliderCenter = Vector3.New(0, 1, 0)
local ColliderSize = Vector3.New(1, 2.5, 1)

function MainCityModel:__init()
    self.m_loadWuJiangList = {}
    self.m_wujiangShowList = {}
    self.m_colliderList = {}

    self:CreateRoleContainer()
end

function MainCityModel:Clear()
    --回收
    for _, wujiangShow in pairs(self.m_wujiangShowList) do
        if wujiangShow then
            wujiangShow:Delete()
        end
    end
    self.m_wujiangShowList = {}

    --取消加载
    self.m_loadWuJiangList = {}
    
    ActorShowLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0
   
end

function MainCityModel:__delete()
    self:Clear()
    self:DestroyRoleContainer()
end

function MainCityModel:CreateRoleContainer()
    if IsNull(self.m_roleContainerGo) then
        self.m_roleContainerGo = GameObject("MainCityRoleContainer")
        self.m_roleContainerTran = self.m_roleContainerGo.transform

        for i = 1, #StandPosList do
            local go = GameObject()
             local p = StandPosList[i]
             go.transform.parent = self.m_roleContainerTran
            GameUtility.SetLocalPosition(go.transform, p.x, p.y, p.z)
             local col = go:AddComponent(Type_BoxCollider)
             col.center = ColliderCenter
            col.size = ColliderSize
             table_insert(self.m_colliderList, col)
         end
    end
end

function MainCityModel:DestroyRoleContainer()
     for i = 1, #self.m_colliderList do
         if not IsNull(self.m_colliderList[i].gameObject) then
             GameObject.DestroyImmediate(self.m_colliderList[i].gameObject)
         end
     end
     self.m_colliderList = nil

    if not IsNull(self.m_roleContainerGo) then
        GameObject.DestroyImmediate(self.m_roleContainerGo)
    end
    self.m_roleContainerGo = nil
    self.m_roleContainerTran = nil
end

function MainCityModel:CreateWuJiang(wujiangBriefData)
    if not wujiangBriefData then
        return
    end

    if not self.m_roleContainerTran then
        return
    end

    local wujiangID = math_ceil(wujiangBriefData.id)
    local weaponLevel = wujiangBriefData.weaponLevel
    local standPos = wujiangBriefData.pos

    self.m_seq = ActorShowLoader:GetInstance():PrepareOneSeq()
    ActorShowLoader:GetInstance():CreateShowOffWuJiang(self.m_seq, ActorShowLoader.MakeParam(wujiangID, weaponLevel), self.m_roleContainerTran, function(actorShow, standPos)
        self.m_seq = 0
        table_insert(self.m_wujiangShowList, actorShow)

        actorShow:PlayAnim(BattleEnum.ANIM_IDLE)
        actorShow:SetPosition(StandPosList[standPos])
        actorShow:SetEulerAngles(StandRotList[standPos])

        self.m_colliderList[standPos].gameObject.name = string_format('%d', wujiangBriefData.index) 

        self:CheckShowWuJiang()
    end, standPos)
end

function MainCityModel:ShowWuJiangList()
    --展示主线关卡保存阵容的武将列表
    Player:GetInstance():GetLineupMgr():Walk(Utils.GetBuZhenIDByBattleType(BattleEnum.BattleType_COPY), function(wujiangBriefData, isMain, isEmploy)
        if not isEmploy then
            table_insert(self.m_loadWuJiangList, wujiangBriefData)
        end
    end)

    for i = 1, #self.m_colliderList do
         self.m_colliderList[i].gameObject.name = 'g'
    end

    self:CheckShowWuJiang()
end

function MainCityModel:CheckShowWuJiang()
    if #self.m_loadWuJiangList > 0 then
        local loadData = self.m_loadWuJiangList[1]
        table_remove(self.m_loadWuJiangList, 1)
        self:CreateWuJiang(loadData)
    end
end

return MainCityModel