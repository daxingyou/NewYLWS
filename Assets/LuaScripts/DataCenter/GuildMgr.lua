
local table_sort = table.sort
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format
local copyNumList = table.copyNumList
local table_findIndex = table.findIndex

local PBUtil = PBUtil
local CommonDefine = CommonDefine

local GuildMgr = BaseClass("GuildMgr")

function GuildMgr:__init()
   
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_APPLY, Bind(self, self.RspApplyGuild))         --申请军团
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_NTF_JOIN_GUILD, Bind(self, self.NtfJoinGuild))     --通知加入军团
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_GUILD_LIST, Bind(self, self.RspGuildList))     --军团概要列表（排行榜）
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_CREATE_GUILD, Bind(self, self.RspCreateGuild)) --创建军团
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_FIND_GUILD, Bind(self, self.RspFindGuild))     --查找军团

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_EXAMINE, Bind(self, self.RspExamine))          --军团审批
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_EXIT, Bind(self, self.RspExit))                --军团退出
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_SETTING, Bind(self, self.RspSetting))          --军团设置
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_POST_RENAME, Bind(self, self.RspPostRename))   --军团职务名称修改
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_POST_DEPLOY, Bind(self, self.RspPostDseploy))  --军团职务安排
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_MEMBER_KICK, Bind(self, self.RspMemberKick))   --踢人
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_ABDICATE, Bind(self, self.RspAbdicate))        --让贤
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_DISMISS, Bind(self, self.RspDisMissGuild))     --解散军团

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_LEVELUP, Bind(self, self.RspLevelUp))          --军团升级
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_INVITE, Bind(self, self.RspInvite))            --邀请别人加入军团
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_WORSHIP, Bind(self, self.RspWorship))          --膜拜

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_AWARD_INFO, Bind(self, self.RspAwardInfo))       --请求宝箱奖励
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_TAKE_ALL_AWARD, Bind(self, self.RspTakeAllAward))--领取宝箱奖励
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_NTF_NEW_AWARD, Bind(self, self.NtfNewAward))         --宝箱红点

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_DONATE_GUILD, Bind(self, self.RspDonate))         --捐献
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_GUILD_TASK_LIST, Bind(self, self.RspGuildTask))   --任务列表
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_COMPLETE_GUILD_TASK, Bind(self, self.RspCompleteTask)) --任务完成
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_GUILD_DAILY, Bind(self, self.RspGuildDaily))      --日志
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_GUILD_RANK_LIST, Bind(self, self.RspGuildRankList))--军团排名
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_GUILD_SKILL_LIST, Bind(self, self.RspGuildSkill)) --军团技能列表
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_UNLOCK_SKILL, Bind(self, self.RspUnlockSkill))    --解锁军团技能
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_LEARN_SKILL, Bind(self, self.RspLearnSkill))      --学习军团技能

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_APPLY_LIST, Bind(self, self.RspApplyList))         --申请列表
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_GUILD_MEMBER_LIST, Bind(self, self.RspMemberList)) --军团成员列表
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_GUILD_DETAIL, Bind(self, self.RspGuildDetail))     --军团详情
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_NTF_GUILD_CHG, Bind(self, self.NtfGuildChg))           --军团变更(军团解散, 被踢出)

    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_RSP_SET_JOIN_TYPE, Bind(self, self.RspSetJionType))    --设置加入军团是否需要验证
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_NTF_GUILD_RESOUCE, Bind(self, self.NtfGuildResource))   
    HallConnector:GetInstance():RegisterHandler(MsgIDDefine.GUILD_NTF_NOTIFY_BAR, Bind(self, self.NtfNotifyBar))         --军团任务和技能提醒

    self.m_guild_brief_list = {}
    self.MyGuildData = {}
    self.m_postTempData = {}
    self.JoinGuildCondition = CommonDefine.Not_Apply
    self.m_openType = 1
end

function GuildMgr:Dispose()

    self.m_guild_brief_list = {}
end

function GuildMgr:OpenGuild()
    --todo 
   --[[  local isOpen = Utils.SysIsOpenById(TheSysIds.GUILD)
    if (!isOpen)
    {
        return;
    } ]]

    self:ReqOpenGuild()
end

--请求打开军团
function GuildMgr:ReqOpenGuild()
    local msg_id = MsgIDDefine.GUILD_REQ_OPEN_GUILD
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:ReqApplyGuild(gid)
    local msg_id = MsgIDDefine.GUILD_REQ_APPLY
    local msg = (MsgIDMap[msg_id])()
    msg.gid = gid
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspApplyGuild(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        if msg_obj.apply_result == 1 then -- 0成功申请，1正式加入
            --todo 关闭当前界面  弹出军团主界面 
            self:OpenGuild()
        else 
           UILogicUtil.FloatAlert(Language.GetString(1301))
        end
	end
end

function GuildMgr:NtfJoinGuild(ntf_join_guild)

    --不在军团界面 在主城 上浮提示

end


function GuildMgr:ReqCreateGuild(name, icon, declaration)
    local msg_id = MsgIDDefine.GUILD_REQ_CREATE_GUILD
    local msg = (MsgIDMap[msg_id])()
  
    msg.name = name
    msg.icon = icon
    msg.declaration = declaration
    
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspCreateGuild(msg_obj)
    local result = msg_obj.result
    if result == 0 then
        if msg_obj.gid > 0 then
            UILogicUtil.FloatAlert(Language.GetString(1300))
            UIManagerInst:CloseWindow(UIWindowNames.UIGuildCreate)
            UIManagerInst:CloseWindow(UIWindowNames.UIGuildJoin)

            self:OpenGuild()
        end
	end
end

function GuildMgr:ReqGuildList(open_param)
    open_param = open_param or 0

    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_LIST
    local msg = (MsgIDMap[msg_id])()
    msg.open_param = open_param -- 1, 随机列表
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspGuildList(msg_obj)
    local result = msg_obj.result
    if result == 0 then

        self.GuildBriefList = PBUtil.ToParseList(msg_obj.guild_list, Bind(self, self.ToGuildBriefData))
        self.GuildRankList = PBUtil.ToParseList(msg_obj.guild_rank_list, Bind(self, self.ToGuildBriefData))

        if self.GuildRankList or self.GuildBriefList then

            local target = UIManagerInst:GetWindow(UIWindowNames.UIGuildJoin, true, true)
            if target then
                UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_BRIEF_LIST)
            else
                UIManagerInst:OpenWindow(UIWindowNames.UIGuildJoin)
            end
        end
	end
end

function GuildMgr:ReqGuildRankList()
    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_RANK_LIST
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspGuildRankList(msg_obj)

    if msg_obj.result == 0 then
        self.GuildRankList = PBUtil.ToParseList(msg_obj.guild_rank_list, Bind(self, self.ToGuildBriefData))

        if self.GuildRankList then
            UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_GUILD_RANK_LIST)
        end
    end
end

function GuildMgr:ReqFindGuild(guild_key)
    local msg_id = MsgIDDefine.GUILD_REQ_FIND_GUILD
    local msg = (MsgIDMap[msg_id])()
    msg.guild_key = guild_key
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspFindGuild(msg_obj)

    local result = msg_obj.result
    if result == 0 then
        self.GuildFindList = PBUtil.ToParseList(msg_obj.guild_info_list, Bind(self, self.ToGuildBriefData))
        if self.GuildFindList then
            -- todo 发消息
            UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_FIND_GUILD)
        end
	end
end

function GuildMgr:ReqExamine(uid, examine_result)
    examine_result = examine_result or 1
    local msg_id = MsgIDDefine.GUILD_REQ_EXAMINE
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.examine_result = examine_result --0表示不同意，1表示同意
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspExamine(msg_obj)    
    if msg_obj.result == 0 then
        local isSucc = msg_obj.examine_result == 0 --//0表示正常，-1表示玩家已经加入军团了,-2表示军团已经满了
        if isSucc then
            if self.MyGuildData then
                self.MyGuildData.member_list = PBUtil.ToParseList(msg_obj.member_list, Bind(self, self.ToGuildMemberData))
                --UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_GUILD_DETAIL)
                self:ReqGuildDetail()
            end
        end
        --self:ReqApplyList()
        UIManagerInst:Broadcast(UIMessageNames.MN_EXAMINE_GUILD, msg_obj.uid, msg_obj.examine_result)
	end
end

function GuildMgr:ReqExit()
    local msg_id = MsgIDDefine.GUILD_REQ_EXIT
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspExit(msg_obj)
    if msg_obj.result == 0 then
        self:ClearGuildData()
        UILogicUtil.FloatAlert(Language.GetString(1404))
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_EXIT)
    end
    
end

function GuildMgr:ReqSetting(chg_type, name, declaration, icon)
    local msg_id = MsgIDDefine.GUILD_REQ_SETTING
    local msg = (MsgIDMap[msg_id])()
    msg.chg_type = chg_type
    msg.name = name
    msg.declaration = declaration
    msg.icon = icon

    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspSetting(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(Language.GetString(1303))
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_SETTING)
        self:ReqGuildDetail()
	end
end

function GuildMgr:ReqPostRename(chgType, newName)
    if self.MyGuildData then
        local post_name_map = self.MyGuildData.post_name_map
        if post_name_map then
            for i, v in ipairs(post_name_map) do
                if v.post_type == chgType and v.post_name == newName then
                    UILogicUtil.FloatAlert(Language.GetString(1305))
                    return 
                end
            end
        end
    end

    --1军机 2副团，3团长
    local msg_id = MsgIDDefine.GUILD_REQ_POST_RENAME
    local msg = (MsgIDMap[msg_id])()
   
    if chgType == CommonDefine.GUILD_POST_MILITARY then
        msg.elder_name = newName
    elseif chgType == CommonDefine.GUILD_POST_DEPUTY then
        msg.vice_doyen_name = newName
    elseif chgType == CommonDefine.GUILD_POST_COLONEL then
        msg.doyen_name = newName
    end

    msg.chg_type = chgType

    self.m_postTempData.chg_type = chgType
    self.m_postTempData.name = newName
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspPostRename(msg_obj)    
    if msg_obj.result == 0 then
        if self.MyGuildData then
            local post_name_map = self.MyGuildData.post_name_map
            if post_name_map then
                for i, v in ipairs(post_name_map) do
                    if v.post_type == self.m_postTempData.chg_type then
                        v.post_name = self.m_postTempData.name
                        UILogicUtil.FloatAlert(Language.GetString(1304))
                        self:ReqGuildDetail()
                        --刷新界面 名称 todo
                        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_POST_RENAME)
                        return 
                    end
                end
            end
        end
	end
end

function GuildMgr:ReqPostDseploy(uid, post)
    local msg_id = MsgIDDefine.GUILD_REQ_POST_DEPLOY
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.post = post
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspPostDseploy(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(Language.GetString(1306))
        --todo 重新请求数据
        self:ReqGuildDetail()
	end
end

function GuildMgr:ReqMemberKick(uid)
    local msg_id = MsgIDDefine.GUILD_REQ_MEMBER_KICK
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspMemberKick(msg_obj)
    if msg_obj.result == 0 then
       --todo Item 移除、
        self:ReqGuildDetail()
	end
end

function GuildMgr:ReqAbdicate(uid)
    local msg_id = MsgIDDefine.GUILD_REQ_ABDICATE
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspAbdicate(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(Language.GetString(1307))
        self:ReqGuildDetail()
	end
end

function GuildMgr:ReqDismiss()
    local msg_id = MsgIDDefine.GUILD_REQ_DISMISS
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspDisMissGuild(msg_obj)
    if msg_obj.result == 0 then
       self:ClearGuildData()
       -- todo 广播关闭所有军团界面 
	end
end


function GuildMgr:ReqApplyList()
    local msg_id = MsgIDDefine.GUILD_REQ_APPLY_LIST
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspApplyList(msg_obj)
    if msg_obj.result == 0 then
        local apply_list = PBUtil.ToParseList(msg_obj.apply_list, Bind(self, self.ToGuildApplyDetailData))
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_APPLY_LIST, apply_list)

        self:SetGuildApplyRedPointStatus(apply_list)
	end 
end

function GuildMgr:SetGuildApplyRedPointStatus(apply_list)
    local status = false
    if apply_list and #apply_list > 0 then
        status = true
    end

    local userMgr = Player:GetInstance():GetUserMgr()
    if not status then 
        userMgr:DeleteRedPointID(SysIDs.GUILD)
	else
        userMgr:AddRedPointId(SysIDs.GUILD)
    end
    UIManagerInst:Broadcast(UIMessageNames.MN_MAIN_ICON_REFRESH_RED_POINT)
end

function GuildMgr:ReqMemberList()
    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_MEMBER_LIST
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspMemberList(msg_obj)
    if msg_obj.result == 0 then
        if self.MyGuildData then
            self.MyGuildData.member_list = PBUtil.ToParseList(msg_obj.member_list, Bind(self, self.ToGuildMemberData))
        end
	end
end

function GuildMgr:ReqInvite(uid)
    local msg_id = MsgIDDefine.GUILD_REQ_INVITE
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end


function GuildMgr:RspInvite(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(Language.GetString(1308))
	end
end
    
function GuildMgr:ReqWorship(uid, worshiptype)
    local msg_id = MsgIDDefine.GUILD_REQ_WORSHIP
    local msg = (MsgIDMap[msg_id])()
    msg.uid = uid
    msg.worship_type = worshiptype
    
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspWorship(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(string_format(Language.GetString(1370), msg_obj.get_stamina))

        local myGuildData = self.MyGuildData
        if myGuildData then
            myGuildData.worship_record_list = PBUtil.ToParseList(msg_obj.worship_record_list, Bind(self, self.ToWorshipData))
            UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_GUILD_DETAIL)
        end
    end
end

function GuildMgr:ReqLevelUp()
    local msg_id = MsgIDDefine.GUILD_REQ_LEVELUP
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspLevelUp(msg_obj)
    if msg_obj.result == 0 then
        UILogicUtil.FloatAlert(string_format(Language.GetString(1456), msg_obj.guild_level))
        local myGuildData = self.MyGuildData
        if myGuildData then
            myGuildData.level = msg_obj.guild_level

            self:ReqGuildDetail()
            UIManagerInst:Broadcast(UIMessageNames.MN_MYGUILD_BASEINFO_CHG)
        end
    end
end

function GuildMgr:ReqAwardInfo()
    local msg_id = MsgIDDefine.GUILD_REQ_AWARD_INFO
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspAwardInfo(msg_obj)
    if msg_obj.result == 0 then
        local award_list = PBUtil.ToParseList(msg_obj.award_list, Bind(self, self.ToAwardInfo))
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildGetAward, award_list, msg_obj.be_worshiped_count)
    end
end

function GuildMgr:ReqTakeAllAward()
    local msg_id = MsgIDDefine.GUILD_REQ_TAKE_ALL_AWARD
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspTakeAllAward(msg_obj)
    if msg_obj.result == 0 then

        local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
        local uiData = {
            openType = 1,
            awardDataList = awardList,
        }
        UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_TAKE_ALL_AWARD)
    end
end

function GuildMgr:NtfNewAward(ntf_new_award)
   
end

function GuildMgr:ReqDonate(donate_id)
    local msg_id = MsgIDDefine.GUILD_REQ_DONATE_GUILD
    local msg = (MsgIDMap[msg_id])()
    msg.donate_id = donate_id
    self.m_donate_id = donate_id
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end


function GuildMgr:RspDonate(msg_obj)
    if msg_obj.result == 0 then

        local myGuildData = self.MyGuildData
        if myGuildData then
             --军团成员捐献的金币/元宝中的80%转化为军团金币/军团元宝
            myGuildData.level = msg_obj.guild_level
            myGuildData.huoyue = msg_obj.guild_huoyue
            myGuildData.guild_yuanbao = msg_obj.guild_yuanbao
            myGuildData.guild_coin = msg_obj.guild_coin
            if self.m_donate_id then
                local findIndex = table_findIndex(myGuildData.donate_record_list, function(v)
                    return v.donate_id == self.m_donate_id
                end)
        
                if findIndex > 0 then
                    local donate_record =  myGuildData.donate_record_list[findIndex]
                    donate_record.left_count = donate_record.left_count - 1
                end
            end

            UILogicUtil.FloatAlert(Language.GetString(1354))
        end
        local awardList = PBUtil.ParseAwardList(msg_obj.award_list)

        self:ReqGuildDetail()
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_DONATION_UPDATE, awardList)
        UIManagerInst:Broadcast(UIMessageNames.MN_MYGUILD_BASEINFO_CHG)
    end
end

function GuildMgr:ReqGuildTask()
    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_TASK_LIST
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspGuildTask(msg_obj)

    if msg_obj.result == 0 then
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_GUILD_TASK_LIST, msg_obj)
    end
end

function GuildMgr:ReqCompleteTask(taskId)
    local msg_id = MsgIDDefine.GUILD_REQ_COMPLETE_GUILD_TASK
    local msg = (MsgIDMap[msg_id])()
    msg.task_id = taskId
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspCompleteTask(msg_obj)

    if msg_obj.result == 0 then
        local awardList = PBUtil.ParseAwardList(msg_obj.award_list)
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_COMPLETE_TASK, msg_obj, awardList)
    end
end

function GuildMgr:ReqGuildDaily()
    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_DAILY
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspGuildDaily(msg_obj)
    if msg_obj.result == 0 then
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_GUILD_DAILY, msg_obj)
    end
end

function GuildMgr:ReqGuildSkill()
    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_SKILL_LIST
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspGuildSkill(msg_obj)
    if msg_obj.result == 0 then
        local skillList = PBUtil.ToParseList(msg_obj.guild_skill_list, Bind(self, self.ToSkillData))
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_GUILD_SKILL_LIST, skillList)
    end
end

function GuildMgr:ReqUnlockSkill(skill_id)
    local msg_id = MsgIDDefine.GUILD_REQ_UNLOCK_SKILL
    local msg = (MsgIDMap[msg_id])()
    msg.skill_id = skill_id
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspUnlockSkill(msg_obj)
    if msg_obj.result == 0 then
        self:ReqGuildSkill()
    end
end

function GuildMgr:ReqLearnSkill(skill_id)
    local msg_id = MsgIDDefine.GUILD_REQ_LEARN_SKILL
    local msg = (MsgIDMap[msg_id])()
    msg.skill_id = skill_id
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspLearnSkill(msg_obj)
    if msg_obj.result == 0 then
        self:ReqGuildSkill()
        
        local uiData = {}
        uiData.openType = 4
        uiData.guildSkillID = msg_obj.skill_id
        UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
    end
end



--openType 1打开军团，2先请求军团数据后再请求争霸
function GuildMgr:ReqGuildDetail(openType)
    local msg_id = MsgIDDefine.GUILD_REQ_GUILD_DETAIL
    local msg = (MsgIDMap[msg_id])()
    HallConnector:GetInstance():SendMessage(msg_id, msg)
   
    self.m_openType = openType or 1
end


function GuildMgr:RspGuildDetail(msg_obj)
    if msg_obj.result == 0 then
        self.MyGuildData = self:ToMyGuildDdata(msg_obj, self.MyGuildData)
        if self.MyGuildData then

            local userData =  Player:GetInstance():GetUserMgr():GetUserData()
            userData.guild_id = self.MyGuildData.gid
            userData.guild_level = self.MyGuildData.level

            local oldOpenType = self.m_openType
            self.m_openType = 1

            if oldOpenType == 1 then
                local target = UIManagerInst:GetWindow(UIWindowNames.UIMyGuild, true, true)
                if target then
                    UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_GUILD_DETAIL)
                else
                    UIManagerInst:OpenWindow(UIWindowNames.UIMyGuild)
                end
            elseif oldOpenType == 2 then
                Player:GetInstance():GetGuildWarMgr():ReqPanelInfo()
            end
        end
	end
end

function GuildMgr:ReqSetJionType(join_type)
    local msg_id = MsgIDDefine.GUILD_REQ_SET_JOIN_TYPE
    local msg = (MsgIDMap[msg_id])()
    msg.join_type = join_type
    HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function GuildMgr:RspSetJionType(msg_obj)
    if msg_obj.result == 0 then
        self.JoinGuildCondition = msg_obj.join_type
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_RSP_SET_JOIN_TYPE)
    end
end

function GuildMgr:NtfGuildChg(ntf_guild_chg)
    --todo 加个reason GUILD_NTF_LEAVE_GUILD

    local userData = Player:GetInstance():GetUserMgr():GetUserData()
    if ntf_guild_chg.gid > 0 then
        userData.guild_id = ntf_guild_chg.gid
    else
        if userData.guild_id > 0 then
            UILogicUtil.FloatAlert(Language.GetString(1302))
        end

        self:ClearGuildData()
    end
end

function GuildMgr:NtfGuildResource(ntf_guild_resouce)
   
    if self.MyGuildData then
        self.MyGuildData.guild_yuanbao = ntf_guild_resouce.guild_yuanbao
        self.MyGuildData.guild_coin = ntf_guild_resouce.guild_coin
    end
end

function GuildMgr:NtfNotifyBar(msg_obj)
    if msg_obj then
        self.typeList = msg_obj.type_list
        UIManagerInst:Broadcast(UIMessageNames.MN_GUILD_NTF_NOTIFY_BAR)
    end
end

function GuildMgr:GetTypeListLength()
    return self.typeList
end

-- GetData

function GuildMgr:GetPostName(postType)
    if self.MyGuildData  then

        local findIndex = table_findIndex(self.MyGuildData.post_name_map, function(v)
			return v.post_type == postType
        end)
        
        if findIndex > 0 then
            return self.MyGuildData.post_name_map[findIndex].post_name
        end
    end

    return Language.GetString(1347)
end

function GuildMgr:ClearGuildData()
    local userData =  Player:GetInstance():GetUserMgr():GetUserData()
    userData.guild_id = 0
end

-- return 1, 已捐献 0未捐献
function GuildMgr:GetDonationStatus(id)
    if self.MyGuildData then
        local findIndex = table_findIndex(self.MyGuildData.donate_record_list, function(v)
			return v.donate_id == id and v.left_count == 0
        end)

        if findIndex > 0 then
            return 1
        end
        return 0
    end

    return -1
end

function GuildMgr:CanWorship(uid, level)
    local userData = Player:GetInstance():GetUserMgr():GetUserData()
    if uid ~= userData.uid then
        
        if self.MyGuildData then
            local worship_record_list = self.MyGuildData.worship_record_list
            if worship_record_list and #worship_record_list < 3 then
                local findIndex = table_findIndex(worship_record_list, function(v)
                    return v.target_uid == uid
                end)

                if findIndex > 0 then
                    return false
                end

                if level > userData.level and level - userData.level <= 10 then
                    return true
                end
            end
        end
    end

    return false
end


--Proto Parse Data
function GuildMgr:ToGuildBriefData(one_guild_brief, data)
    if one_guild_brief then
        data = data or {}
        data.gid = one_guild_brief.gid	--军团ID
        data.name = one_guild_brief.name
        data.flag_icon = one_guild_brief.flag_icon --旗帜
        data.level = one_guild_brief.level 
        data.member_count = one_guild_brief.member_count --人数
        data.need_level = one_guild_brief.need_level --加入所需主公等级
        data.declaration = one_guild_brief.declaration --宣言
        data.join_type = one_guild_brief.join_type	--验证类型，0需要验证，1不需要验证,2不允许加入
        data.huoyue = one_guild_brief.huoyue --军团活跃
        data.member_limit = one_guild_brief.member_limit --人数限制
        data.icon = one_guild_brief.icon --旗帜
        data.rank = one_guild_brief.rank --全服排行
        data.warcraft_score = one_guild_brief.warcraft_score --争霸积分
        data.doyen_name = one_guild_brief.doyen_name --军团长姓名
        data.doyen = one_guild_brief.doyen  --军团长uid
        
        return data
    end
end

function GuildMgr:ToMyGuildDdata(rsp_guild_detail, data)
    if rsp_guild_detail then
        data = data or {}

        data.gid = rsp_guild_detail.gid	   --军团ID
        data.name = rsp_guild_detail.name
        data.flag_icon = rsp_guild_detail.flag_icon
        data.icon = rsp_guild_detail.icon
        data.self_post = rsp_guild_detail.self_post -- 自己的职位
        data.level = rsp_guild_detail.level
        data.member_limit = rsp_guild_detail.member_limit
        data.huoyue = rsp_guild_detail.huoyue   --贡献
        data.need_huoyue = rsp_guild_detail.need_huoyue 
        data.declaration = rsp_guild_detail.declaration
        data.member_list = PBUtil.ToParseList(rsp_guild_detail.member_list, Bind(self, self.ToGuildMemberData))
        data.post_name_map = PBUtil.ToParseList(rsp_guild_detail.post_name_map, Bind(self, self.ToGuildPostData))
        data.vice_doyen_count_limit = rsp_guild_detail.vice_doyen_count_limit --副团长人数上限
        data.guild_yuanbao = rsp_guild_detail.guild_yuanbao --	//军团资源元宝
        data.guild_coin = rsp_guild_detail.guild_coin       --  //军团资源铜钱
        data.donate_record_list = PBUtil.ToParseList(rsp_guild_detail.donate_record_list, Bind(self, self.ToDonateData))
        
       
        data.worship_record_list = PBUtil.ToParseList(rsp_guild_detail.worship_record_list, Bind(self, self.ToWorshipData))
       
        
        data.red_point_list = rsp_guild_detail.red_point_list
        data.rank = rsp_guild_detail.rank
        data.warcraft_score = rsp_guild_detail.warcraft_score
        self.JoinGuildCondition = rsp_guild_detail.join_type 	--//验证类型，0需要验证，1不需要验证,2不允许加入
--optional string recruit_declaration = 8[default = ''];	//宣言标题
--optional int32 resource = 10[default = 0];	//军团资源
--optional int32 need_level = 15[default = 1];	//需要的主公等级
--optional int32 day_award_list = 17[default = 2];	//
--optional int32 today_day_gain = 22[default = 0]; //今天是否领取军团签到奖励 1.未领取  2.已领取

        return data
    end
end

function GuildMgr:ToGuildMemberData(one_member_brief, data)
    if one_member_brief then
        data = data or {}

        data.uid = one_member_brief.uid
        data.user_name = one_member_brief.user_name
        data.level = one_member_brief.level
        data.icon = one_member_brief.icon
        if one_member_brief.use_icon then
            data.icon = one_member_brief.use_icon.icon
            data.icon_box = one_member_brief.use_icon.icon_box
        end
        data.post = one_member_brief.post  --职位，0普通，1长老 2副团，3团长
        data.off_online_time = one_member_brief.off_online_time --//0.在线 ,  > 0 下线时间
        data.sum_huoyue = one_member_brief.sum_huoyue
        data.week_huoyue = one_member_brief.week_huoyue
        return data
    end
end

function GuildMgr:ToGuildPostData(one_post_name_map, data)
    if one_post_name_map then
        data = data or {}
        data.post_type = one_post_name_map.post_type
        data.post_name = one_post_name_map.post_name
        return data
    end
end

function GuildMgr:ToGuildApplyDetailData(one_apply_detail, data)
    if one_apply_detail then
        data = data or {}
        data.user_brief = PBUtil.ConvertUserBriefProtoToData(one_apply_detail.user_brief)
        data.apply_time = one_apply_detail.apply_time
        return data
    end
end

function GuildMgr:ToDonateData(one_donate_record, data)
    if one_donate_record then
        data = data or {}
        data.donate_id = one_donate_record.donate_id
        data.left_count = one_donate_record.left_count
        return data
    end
end

function GuildMgr:ToAwardInfo(one_award_info, data)
    if one_award_info then
        data = data or {}
        data.type = one_award_info.type  -- type 1膜拜、2争霸
        data.award_yuanbao = one_award_info.award_yuanbao
        data.item_list = PBUtil.ToParseList(one_award_info.item_list, PBUtil.ConvertOneItemToData)
        data.from_user_name = one_award_info.from_user_name
        return data
    end
end

function GuildMgr:ToSkillData(one_guild_skill, data)
    if one_guild_skill then
        data = data or {}
        data.skill_id = one_guild_skill.skill_id
        data.is_unlocked = one_guild_skill.is_unlocked
        data.is_new = one_guild_skill.is_new
        data.is_learned = one_guild_skill.is_learned
        return data
    end
end

function GuildMgr:ToWorshipData(one_worship_record, data)
    if one_worship_record then
        data = data or {}
        data.target_uid = one_worship_record.target_uid
        data.type = one_worship_record.type
        return data
    end
end 

function GuildMgr:IsInGuild(my_gid,check_gid)
    if my_gid and check_gid then
        if my_gid == check_gid then
            return true
        end
    end
    return false
end

function GuildMgr:GetGuildLevel()
    if self.MyGuildData then
        return self.MyGuildData.level
    end
    return 0
end

return GuildMgr

