local ConfigUtil = ConfigUtil
local TimeUtil = TimeUtil
local GuildWarMgr = Player:GetInstance():GetGuildWarMgr()

local base = UIBaseItem
local GuildWarHuSongHorse = BaseClass("GuildWarHuSongHorse", UIBaseItem)

function GuildWarHuSongHorse:OnCreate()
    base.OnCreate(self)

    self.m_uID = 0
    self.m_horseLeftTime = 0
    
    self.m_userIcon = UIUtil.AddComponent(UIImage, self, "Mask/UserIcon", AtlasConfig.RoleIcon)

    self.m_leftTimeText = UIUtil.GetChildTexts(self.transform, {
        "Time/TimeText"
    })

    self.m_timeGo = UIUtil.GetChildTransforms(self.transform, {
        "Time"
    })

    self.m_timeGo = self.m_timeGo.gameObject

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_gameObject, onClick)
end

function GuildWarHuSongHorse:OnClick(go) 
    if go == self.m_gameObject then 
        if self.m_uID and self.m_uID > 0 and self.m_uID ~= Player:GetInstance():GetUserMgr():GetUserData().uid then
            local husongInfo = GuildWarMgr:GetHuSongInfo() 
            local curSearchedHuSongInfo = GuildWarMgr:GetCurSearchedHuSongMission()
            if husongInfo then
                UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarRob, husongInfo)
            else
                if curSearchedHuSongInfo then
                    UIManagerInst:OpenWindow(UIWindowNames.UIGuildWarRob, curSearchedHuSongInfo)
                end
            end
        end
    end
end

function GuildWarHuSongHorse:UpdateData(headIconId, uid, leftTime)
    self.m_uID = uid
    local headIconCfg = ConfigUtil.GetHeadIconCfgByID(headIconId)
    if headIconCfg then
        local wujiangCfg = ConfigUtil.GetWujiangCfgByID(headIconCfg.icon)
        if wujiangCfg then
            self.m_userIcon:SetAtlasSprite(wujiangCfg.sIcon, false, AtlasConfig.RoleIcon)
        end
    end

    self.m_timeGo:SetActive(leftTime ~= nil)

    if leftTime then
        self.m_leftTimeText.text = TimeUtil.ToHourMinSecStr(leftTime)
        self.m_horseLeftTime = leftTime
    end
end

function GuildWarHuSongHorse:Update(deltaTime)
    if self.m_horseLeftTime > 0 then
        self.m_horseLeftTime = self.m_horseLeftTime - deltaTime
        
        if self.m_horseLeftTime <= 0 then
            self:SetActive(false)
        else
            self.m_leftTimeText.text = TimeUtil.ToHourMinSecStr(self.m_horseLeftTime)
        end
    end
end

function GuildWarHuSongHorse:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_gameObject)
    if self.m_userIcon then
        self.m_userIcon:Delete()
        self.m_userIcon = nil
    end

    base.OnDestroy(self)
end

return GuildWarHuSongHorse
