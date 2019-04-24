local rawset = rawset
local PBUtil = PBUtil
local Vector3 = Vector3
local table_sort = table.sort
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format
local GodBeastDataClass = require "DataCenter.GodBeastData.GodBeastData"
local GodBeastTalentDataClass = require "DataCenter.GodBeastData.GodBeastTalentData"
local GodBeastMgr = BaseClass("GodBeastMgr")

function GodBeastMgr:__init()
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGON_RSP_IMPROVE_DRAGON, Bind(self, self.RspImproveGodBeast))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGON_RSP_AWAKENING_DRAGON, Bind(self, self.RspAwakening))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGON_RSP_ACTIVE_TALENT, Bind(self, self.RspActiveTalent))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGON_RSP_FORGOT_TALENT, Bind(self, self.RspForgetTalent))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGON_NTF_DRAGON_CHG, Bind(self, self.NtfGodBeastDataChg))

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGONCOPY_RSP_COPY_INFO, Bind(self, self.RspCopyInfo))         --神兽副本界面
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.DRAGONCOPY_NTF_NOTIFY_DRAGONCOPY_CHG, Bind(self, self.NtfCopyInfo))  
    
    self.m_GodBeastList = {}
    self.CurrentEnterCopyID = 0
end

function GodBeastMgr:Dispose()
    self.m_GodBeastList = {}
end

function GodBeastMgr:GetGodBeastByID(id)
    return self.m_GodBeastList[id]
end

function GodBeastMgr:GetGodBeastTalentByID(godBeastId,talentSeq)
    local godBeastData = self:GetGodBeastByID(godBeastId)
    if godBeastData and godBeastData.dragon_talent_list then 
        for k,v in pairs(godBeastData.dragon_talent_list) do
            if v.talent_seq == talentSeq then
                return v
            end
        end
    end
end

function GodBeastMgr:GetGodBeastVector3ById(id)
    if id == 3601 then
        return Vector3.New(-6,-5.6,-14.57),Vector3.New(0.9,0.9,0.9),Vector3.New(0,40,0)
    elseif id == 3603 then
        return Vector3.New(-7.3,-5.6,-14.57),Vector3.New(0.9,0.9,0.9),Vector3.New(0,46.36,0)
    elseif id == 3602 then
        return Vector3.New(-6.9,-6.7,-14.57),Vector3.New(0.9,0.9,0.9),Vector3.New(0,57.32,0)
    elseif id == 3606 then
        return Vector3.New(-6.9,-5.8,-14.57),Vector3.New(0.8,0.8,0.8),Vector3.New(0,54.8,0)
    end
end

function GodBeastMgr:InitGodBeastInfo(dragon_list)
    if not dragon_list then
        return
    end

    for k,v in ipairs(dragon_list) do
        if v.dragon_id then
            self.m_GodBeastList[v.dragon_id] = self:ConvertToGodBeastData(v)
        end
    end
end

function GodBeastMgr:ReqImproveGodBeast(godBeastId, expItem)
    local msg_id = MsgIDDefine.DRAGON_REQ_IMPROVE_DRAGON
    local msg = (MsgIDMap[msg_id])()
    msg.dragon_id = godBeastId 
    msg.need_item.item_id = expItem.item_id
    msg.need_item.count = expItem.count
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GodBeastMgr:RspImproveGodBeast(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function GodBeastMgr:ReqAwakening(godBeastId)
    local msg_id = MsgIDDefine.DRAGON_REQ_AWAKENING_DRAGON
    local msg = (MsgIDMap[msg_id])()
    msg.dragon_id = godBeastId

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GodBeastMgr:RspAwakening(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function GodBeastMgr:ReqActiveTalent(godBeastId, horseIndex, talentSeq)
    local msg_id = MsgIDDefine.DRAGON_REQ_ACTIVE_TALENT
    local msg = (MsgIDMap[msg_id])()
    msg.dragon_id = godBeastId
    msg.horse_index = horseIndex
    msg.talent_seq = talentSeq
    
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GodBeastMgr:RspActiveTalent(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end
end

function GodBeastMgr:ReqForgetTalent(godBeastId, talentSeq, itemList)
    local msg_id = MsgIDDefine.DRAGON_REQ_FORGOT_TALENT
    local msg = (MsgIDMap[msg_id])()
    msg.dragon_id = godBeastId
    msg.talent_seq = talentSeq
    if itemList then
        for k,v in pairs(itemList) do
            local one_item = msg.forgot_talent_item_list:add()
            one_item.item_id = v.item_id
            one_item.count = v.count
        end
    end
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GodBeastMgr:RspForgetTalent(msg_obj)
    if not msg_obj or msg_obj.result ~= 0 then
        return
    end

    UILogicUtil.FloatAlert(Language.GetString(3633))
end

function GodBeastMgr:NtfGodBeastDataChg(msg_obj)
    if not msg_obj then
        return
    end
    local oneGodBeastInfo = self:ConvertToGodBeastData(msg_obj.dragon_info)
    if oneGodBeastInfo and self.m_GodBeastList then
        local oldCfg = self.m_GodBeastList[oneGodBeastInfo.dragon_id]
        self.m_GodBeastList[oneGodBeastInfo.dragon_id] = oneGodBeastInfo
        --升级
        if oldCfg then
            if oldCfg.level < oneGodBeastInfo.level then
                UILogicUtil.FloatAlert(string_format(Language.GetString(642), oneGodBeastInfo.level))
            end
        end
        UIManagerInst:Broadcast(UIMessageNames.MN_GODBEAST_DATA_CHG, oneGodBeastInfo, msg_obj.reason)
    end
end

function GodBeastMgr:ReqCopyInfo()
    local msg_id = MsgIDDefine.DRAGONCOPY_REQ_COPY_INFO
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GodBeastMgr:RspCopyInfo(msg_obj)
    if msg_obj.result == 0 then
        local infoList = PBUtil.ToParseList(msg_obj.dragoncopy_info_list, Bind(self, self.ToDragonCopyInfo))  
        self.m_dragonCopyInfo = {
            dragoncopy_info_list = infoList,
            today_challenge_time = msg_obj.today_challenge_time,
            dragoncopy_max_challenge_times = msg_obj.dragoncopy_max_challenge_times
        }

        UIManagerInst:Broadcast(UIMessageNames.MN_RSP_DRAGON_COPY_INFO)
    end
end

function GodBeastMgr:NtfCopyInfo(msg_obj)
    local infoList = PBUtil.ToParseList(msg_obj.dragoncopy_info_list, Bind(self, self.ToDragonCopyInfo))  
    self.m_dragonCopyInfo = {
        dragoncopy_info_list = infoList,
        today_challenge_time = msg_obj.today_challenge_time,
        dragoncopy_max_challenge_times = msg_obj.dragoncopy_max_challenge_times
    }

    UIManagerInst:Broadcast(UIMessageNames.MN_RSP_DRAGON_COPY_INFO)
end

function GodBeastMgr:GetCopyInfo()
    return self.m_dragonCopyInfo 
end

function GodBeastMgr:ToDragonCopyInfo(dragoncopy_info, data)
    if dragoncopy_info then
        local data = data or {}
        data.copy_id = dragoncopy_info.copy_id 
        data.today_count = dragoncopy_info.today_count
        data.dragon_copy_level = dragoncopy_info.dragon_copy_level
        return data
    end
end

function GodBeastMgr:ConvertToGodBeastData(one_dragonInfo)
    local data = GodBeastDataClass.New()
    data.dragon_id = one_dragonInfo.dragon_id
    data.level = one_dragonInfo.level
    data.dragon_exp = one_dragonInfo.dragon_exp
    data.dragon_talent_list = self:ConvertToGodBeastTalentList(one_dragonInfo.dragon_talent_list)
    return data
end

function GodBeastMgr:ConvertToGodBeastTalentList(dragon_talent_list)
    if dragon_talent_list then
        local dataList = {}   
        for k,v in ipairs(dragon_talent_list) do
            local data = GodBeastTalentDataClass.New()
            data.talent_id = v.talent_id or 0
            data.talent_level = v.talent_level or 0
            data.talent_seq = v.talent_seq
            if data.talent_seq then
                dataList[v.talent_seq] = data
            end
        end
        return dataList
    end
end

return GodBeastMgr