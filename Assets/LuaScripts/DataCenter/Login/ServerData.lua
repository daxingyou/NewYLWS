local string_format = string.format
local CommonDefine = CommonDefine
local ServerData = BaseClass("ServerData")

function ServerData:__init()
    self.ip = ''
    self.port = ''
    self.name = ''
    self.status = 0
    self.areaID = 0
    self.serverID = '0'
    self.openTime = 0
    self.serverIndex = 0
    self.recommend = 0
    self.hasRole = 0
    self.loginTime = 0
    self.user_name = ''
    self.level = 0
    self.icon = 0
    self.icon_box = 0
end

function ServerData:GetStatusSpriteName()
    if self.status == CommonDefine.SERVER_WAIT_OPEN then
        return "dr08.png"
    elseif self.status == CommonDefine.SERVER_WEIHU then
        return "dr09.png"
    elseif self.status == CommonDefine.SERVER_LIUCHANG then
        return "dr07.png"
    elseif self.status == CommonDefine.SERVER_BAOMAN then
        return "dr06.png"
    else 
        return "dr06.png"
    end
end

function ServerData:GetServerIndexAndName()
    return string_format(Language.GetString(4101), self.serverIndex, self.name)
end

return ServerData