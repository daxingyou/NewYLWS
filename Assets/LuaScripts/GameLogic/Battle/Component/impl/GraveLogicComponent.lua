local table_insert = table.insert
local table_remove = table.remove
local Vector3 = Vector3
local Utils = Utils
local Quaternion = Quaternion
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local TheGameIds = TheGameIds

local BaseBattleLogicComponent = require "GameLogic.Battle.Component.BaseBattleLogicComponent"
local GraveLogicComponent = BaseClass("GraveLogicComponent", BaseBattleLogicComponent)
  
local MonsterWuJiangID2 = 6002
local MonsterWuJiangID3 = 6003
local PickTongQianCount = 10

function GraveLogicComponent:__init(graveLogic)
    self.m_tongqianList = {}   
    self.m_boxList = {}

    self.m_logic = graveLogic

    self:InitVariable()

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GRAVECOPY_RSP_FINISH_GRAVECOPY, Bind(self, self.RspBattleFinish))
end

function GraveLogicComponent:__delete()

    HallConnector:GetInstance():ClearHandler(MsgIDDefine.GRAVECOPY_RSP_FINISH_GRAVECOPY)

    for _, v in ipairs(self.m_tongqianList) do
        local go =  v[1]
        GameObjectPoolInst:RecycleGameObject(TheGameIds.TongQianPrefab, go)        
    end
    self.m_tongqianList = nil

    for _, v in ipairs(self.m_boxList) do
        local go = v[1]
        GameObjectPoolInst:RecycleGameObject(TheGameIds.BaoxiangPrefab, go)        
    end
    self.m_boxList = nil
end

function GraveLogicComponent:OnBattleStart(wave)
    BaseBattleLogicComponent.OnBattleStart(self, wave)

    self:InitVariable()
    if wave == 1 then
        self:CheckGuideGraveStean()
    end
end

function GraveLogicComponent:InitVariable()
    self.m_tongqianAutoPick = false
end

function GraveLogicComponent:Update(deltaTime)
    BaseBattleLogicComponent.Update(self, deltaTime)

    local uimanagerInst = UIManagerInst
    if self.m_tongqianAutoPick then
        if self.m_tongqianList and #self.m_tongqianList > 0 then
            local index = 1
            for i = #self.m_tongqianList, 1, -1 do
                local tongqianData = self.m_tongqianList[#self.m_tongqianList]
                local go =  tongqianData[1]
                GameObjectPoolInst:RecycleGameObject(TheGameIds.TongQianPrefab, go)  
                table_remove(self.m_tongqianList, #self.m_tongqianList)

                uimanagerInst:Broadcast(UIMessageNames.UIBATTLE_PICK_MONEY, tongqianData)

                index = index + 1
                if index > PickTongQianCount then
                    break
                end
            end

        end
    end
end

function GraveLogicComponent:ShowBattleUI()
    UIManagerInst:OpenWindow(UIWindowNames.UIBattleMain)
    BaseBattleLogicComponent.ShowBloodUI(self)
end  

function GraveLogicComponent:DropMoney(actor, dropMoney)
    local wujiangID = actor:GetWujiangID()
    local actorID = actor:GetActorID()
    local count = 1
    if wujiangID == MonsterWuJiangID2 then
        count = 3
    elseif wujiangID == MonsterWuJiangID3 then
        count = 5
    end

    GameObjectPoolInst:GetGameObjectAsync2(TheGameIds.TongQianPrefab, count, function(objs)
        if not objs then
            return
        end

        local randPos = Utils.RandPos

        local x, y, z = actor:GetPosition():GetXYZ()
        local dropPos = Vector3.New(x, y, z) 
        for i = 1, #objs do
            local targetPos = randPos(dropPos, -1, 1)
            objs[i].transform:SetPositionAndRotation(targetPos, Quaternion.identity)
            objs[i].transform.localScale = Vector3.one
            table_insert(self.m_tongqianList, { objs[i], targetPos, actorID, dropMoney })
        end
    end)
end

function GraveLogicComponent:DropBox(actor)

    local x, y, z = actor:GetPosition():GetXYZ()
    local diePos = Vector3.New(x, y, z)

    GameObjectPoolInst:GetGameObjectAsync(TheGameIds.BaoxiangPrefab,
        function(inst)
            inst.transform:SetPositionAndRotation(diePos, Quaternion.identity)                 
            table_insert(self.m_boxList, { inst, diePos })   
        end)
end


function GraveLogicComponent:MonsterDrop(actor)
end

function GraveLogicComponent:AutoPick()
    self.m_tongqianAutoPick = true

    for _, v in ipairs(self.m_boxList) do
        local go = v[1]
        GameObjectPoolInst:RecycleGameObject(TheGameIds.BaoxiangPrefab, go)        
        UIManagerInst:Broadcast(UIMessageNames.UIBATTLE_PICK_GRAVE_BOX, v)
    end

    self.m_boxList = {}
end

function GraveLogicComponent:ReqBattleFinish(copyID)
    local msg_id = MsgIDDefine.GRAVECOPY_REQ_FINISH_GRAVECOPY
    local msg = (MsgIDMap[msg_id])()
    msg.copy_id = copyID

    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
    self:GenerateResultInfoProto(msg.battle_result)
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end


function GraveLogicComponent:RspBattleFinish(msg_obj)
	-- Logger.Log('GraveLogicComponent msg_obj: ' .. tostring(msg_obj))

	local result = msg_obj.result
	if result ~= 0 then
		Logger.LogError('GraveLogicComponent failed: '.. result)
		return
    end
    
    local finish_result = msg_obj.finish_result

    UIManagerInst:CloseWindow(UIWindowNames.UIBattleMain)
    UIManagerInst:OpenWindow(UIWindowNames.UIGraveCopySettlement, msg_obj)
end

function GraveLogicComponent:CheckGuideGraveStean()
    if not self.m_logic:IsFirstIn() then
        return
    end
    if GuideMgr:GetInstance():IsPlayingGuide(GuideEnum.GUIDE_GRAVE) then
        return
    end
    CtlBattleInst:FramePause()
    CtlBattleInst:Pause(BattleEnum.PAUSEREASON_EVERY, 0)
    BattleCameraMgr:Pause()
    GuideMgr:GetInstance():Play(GuideEnum.GUIDE_GRAVE, function()
        CtlBattleInst:FrameResume()
        CtlBattleInst:Resume(BattleEnum.PAUSEREASON_EVERY)
        BattleCameraMgr:Resume()
    end)
end

return GraveLogicComponent