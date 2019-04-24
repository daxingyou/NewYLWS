local PlayerPrefs = CS.UnityEngine.PlayerPrefs
local UILoginView = BaseClass("UILoginView", UIBaseView)
local base = UIBaseView

function UILoginView:OnCreate()
	base.OnCreate(self)
	-- 初始化各个组件
	self.server_text = self:AddComponent(UIText, "ContentRoot/SvrRoot/SvrIDInput/SvrText")
	self.account_input = self:AddComponent(UIInput, "ContentRoot/AccountRoot/AccountInput")
	self.login_btn = self:AddComponent(UIButton, "ContentRoot/LoginBtn")
	self.svr_id_input = self:AddComponent(UIInput, "ContentRoot/SvrRoot/SvrIDInput")
	self.svr_port_input = self:AddComponent(UIInput, "ContentRoot/SvrPortRoot/SvrPortInput")
	self.serverIPInput = self:AddComponent(UIInput, "ContentRoot/IPRoot/IPInput")

	self:HandleClick()
end

function UILoginView:OnEnable(...)
	base.OnEnable(self, ...)
	self:UpdateView()

	print(string.format(Language.GetString(4100), PlatformMgr:GetInstance():GetTotalVersion()))
end

function UILoginView:UpdateView()
	local serverid, account, port, ip = self:GetServerInfo()
	self.svr_id_input:SetText(serverid)
	self.svr_port_input:SetText(port)
	self.account_input:SetText(account)
	self.serverIPInput:SetText(ip)
end

function UILoginView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.login_btn.gameObject, onClick)
end

function UILoginView:RemoveEvent()
    UIUtil.RemoveClickEvent(self.login_btn.gameObject)
end

function UILoginView:OnDisable()
    self:RemoveEvent()

    base.OnDisable(self)
end

function UILoginView:OnClick(go, x, y)
    local name = go.name
	if name == "LoginBtn" then
		local LoginMgr = Player:GetInstance():GetLoginMgr()
		local serverid = tonumber(self.svr_id_input:GetText())
		local serverPort = tonumber(self.svr_port_input:GetText())
		local name = self.account_input:GetText()
		local serverIP = self.serverIPInput:GetText()
		self:SaveServerInfo(serverid, name, serverPort, serverIP)
		LoginMgr:StartLogin(serverid, name, serverPort, serverIP)
    end
end

function UILoginView:OnDestroy()
	self.server_text = nil
	self.account_input = nil
	self.server_select_btn = nil
	self.login_btn = nil
	
	base.OnDestroy(self)
end

function UILoginView:SaveServerInfo(id, account, port, serverIP)
	PlayerPrefs.SetInt("login_serverId", id)
	PlayerPrefs.SetString("login_account", account)
	PlayerPrefs.SetInt("login_port", port)
	PlayerPrefs.SetString("login_serverIP", serverIP)
end

function UILoginView:GetServerInfo()
	return PlayerPrefs.GetInt("login_serverId"), PlayerPrefs.GetString("login_account"), PlayerPrefs.GetInt("login_port"), PlayerPrefs.GetString("login_serverIP")
end

return UILoginView