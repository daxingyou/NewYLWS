local table_insert = table.insert
local math_floor = math.floor
local CommonDefine = CommonDefine
local DianjiangMgr = BaseClass("DianjiangMgr") 

function DianjiangMgr:__init() 
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOTTERY_RSP_LOTTERY_INFO, Bind(self, self.RspPanel)) 
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOTTERY_RSP_RECRUIT, Bind(self, self.RspRecuit))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOTTERY_RSP_XIEJIA, Bind(self, self.RspXiejia))
    -- HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOTTERY_RSP_EXCHANGE_INFO, Bind(self, self.RspExchangeInfo))
    -- HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOTTERY_RSP_EXCHANGE, Bind(self, self.RspExchange))
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.LOTTERY_RSP_GET_DAILY_FULI, Bind(self, self.RspGetTodayFuli))
     
    self.m_rtCfg = {}
end

function DianjiangMgr:GetCallPrice(recruit_type)
    local cfg = self.m_rtCfg[recruit_type]
    if cfg then
        return cfg.price
    end

    return 0
end

function DianjiangMgr:ReqPanel()
    local msg_id = MsgIDDefine.LOTTERY_REQ_LOTTERY_INFO
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id,msg)
end

function DianjiangMgr:RspPanel(msg_obj) 
    if not msg_obj then 
        return 
    end 

    local panelData = {
        take_daily_fuli_count = msg_obj.take_daily_fuli_count,
        take_daily_fuli_count_limit = msg_obj.take_daily_fuli_count_limit,
        curr_activity_wujiang_id = msg_obj.curr_activity_wujiang_id,     
        curr_got_activity_xinwu_num =  msg_obj.curr_got_activity_xinwu_num,
	    activity_xinwu_num_limit = msg_obj.activity_xinwu_num_limit,
        curr_activity_bar_info = {
            fuli_type = msg_obj.curr_activity_bar_info.fuli_type,
            icon = msg_obj.curr_activity_bar_info.icon,
            title = msg_obj.curr_activity_bar_info.title,
        }
    }

    local rsp_cfg = msg_obj.recruit_type_cfg_list
    for _, v in ipairs(rsp_cfg) do
        self.m_rtCfg[v.recruit_type] = {price = v.price, item_id = v.price_item_id}
    end

    local canTakeIt = panelData.take_daily_fuli_count <= 0
    self:SetDianJiangRedPointStatus(canTakeIt) 
    UIManagerInst:Broadcast(UIMessageNames.MN_DIANJIANG_RSP_PANEL, panelData)
end 

function DianjiangMgr:ReqRecuit(recruit_type)
    local msg_id = MsgIDDefine.LOTTERY_REQ_RECRUIT
    local msg = (MsgIDMap[msg_id])()
    msg.recruit_type = recruit_type
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function DianjiangMgr:RspRecuit(msg_obj)
    if not msg_obj then
        return 
    end 

    local rsp_cfg = msg_obj.recruit_type_cfg_list
    for _, v in ipairs(rsp_cfg) do
        self.m_rtCfg[v.recruit_type] = {price = v.price, item_id = v.price_item_id}
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_DIANJIANG_UPDATE_PRICE)
    
    local normal_award_list = PBUtil.ParseAwardList(msg_obj.normal_award_list)
    local addition_award_list = PBUtil.ParseAwardList(msg_obj.addition_award_list)

    local o = {
        recruit_type = msg_obj.recruit_type,
        normal_award_list = normal_award_list,
        addition_award_list = addition_award_list,
    }

    local uiName = UIWindowNames.UIDianjiangAwardTen
    if msg_obj.recruit_type == CommonDefine.RT_N_CALL_1 then
        uiName = UIWindowNames.UIDianjiangAwardOne
    elseif msg_obj.recruit_type == CommonDefine.RT_S_CALL_10 or 
            msg_obj.recruit_type == CommonDefine.RT_S_CALL_1 or msg_obj.recruit_type == CommonDefine.RT_S_CALL_ITEM then
        uiName = UIWindowNames.UIDianJiang
    end

    if UIManagerInst:IsWindowOpen(uiName) then
        UIManagerInst:Broadcast(UIMessageNames.MN_DIANJIANG_ON_RECURIT, msg_obj.recruit_type, o)
    else
        UIManagerInst:OpenWindow(uiName, msg_obj.recruit_type, o)
    end

    local p = {  
        curr_got_activity_xinwu_num =  msg_obj.curr_got_activity_xinwu_num,
	    activity_xinwu_num_limit = msg_obj.activity_xinwu_num_limit,
    }
    UIManagerInst:Broadcast(UIMessageNames.MN_DIANJIANG_XINWU_CHG, p)
end

function DianjiangMgr:ReqGetTodayFuli()
    local msg_id = MsgIDDefine.LOTTERY_REQ_GET_DAILY_FULI
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function DianjiangMgr:RspGetTodayFuli(msg_obj)
    if not msg_obj then
        return 
    end 
    local normal_award_list = PBUtil.ParseAwardList(msg_obj.award_list)

    -- local data = {
    --     recruit_type = msg_obj.recruit_type,
    --     normal_award_list = normal_award_list,
    --     addition_award_list = {},
    -- }

    -- local uiName = UIWindowNames.UIDianjiangAwardOne
    -- UIManagerInst:OpenWindow(uiName, 0, data)

    local uiData = 
    {
        openType = 1,
        awardDataList = normal_award_list,
    }

    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)

    self:SetDianJiangRedPointStatus(false) 
    UIManagerInst:Broadcast(UIMessageNames.MN_DIANJIANG_TAKEN_TODAY_FULI)
end

function DianjiangMgr:ReqXiejia(wujiangSeqList)
    local msg_id = MsgIDDefine.LOTTERY_REQ_XIEJIA
    local msg = (MsgIDMap[msg_id])()
    local req_wujiang_seq_list = msg.wujiang_seq_list

    for k, v in pairs(wujiangSeqList) do
        req_wujiang_seq_list:append(k)
    end
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function DianjiangMgr:RspXiejia(msg_obj)
    if not msg_obj then
        return 
    end 

    UIManagerInst:Broadcast(UIMessageNames.MN_DIANJIANG_ON_XIEJIA)
    
    local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
    
    local uiData = {
        openType = 1,
        awardDataList = awardList
    }
    UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
end

function DianjiangMgr:SetDianJiangRedPointStatus(status)
    local userMgr = Player:GetInstance():GetUserMgr()
    if not status then 
        userMgr:DeleteRedPointID(SysIDs.DIANJIANGTAI)
    else
        userMgr:AddRedPointId(SysIDs.DIANJIANGTAI)
    end 
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_ICON_REFRESH_RED_POINT)
end

return DianjiangMgr