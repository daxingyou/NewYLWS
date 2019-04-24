local math_ceil = math.ceil
local Vector3 = Vector3
local ConfigUtil = ConfigUtil
local UIUtil = UIUtil
local CommonDefine = CommonDefine

local PreloadHelper = PreloadHelper
local GameObject = CS.UnityEngine.GameObject
local Type_Camera = typeof(CS.UnityEngine.Camera)
local ActorShowLoaderInst = ActorShowLoader:GetInstance()

local FarPos = Vector3.New(100000, 100000, 100000)

local Role3DCamPath = TheGameIds.Role3DCameraPrefab

local CreateWuJiangHelper = BaseClass("CreateWuJiangHelper")
function CreateWuJiangHelper:__init(createParam)
    self.m_actorAnchor = createParam.actorAnchor
    self.m_bgPath = createParam.bgPath                    --3D背景资源路径
    self.m_callBack = createParam.callBack

    --2D背景需要创建3D摄像机
    if createParam.needCreate3DCam == nil then
        self.m_needCreate3DCam = false
    else
        self.m_needCreate3DCam = createParam.needCreate3DCam
    end
end

function CreateWuJiangHelper:__delete()
    
    self:RecycleObj()

    self:UnLoadBg()

    self:UnLoadRole3DCam()

    self:DestroyRoleContainer()

    self:InitVariable()
end

function CreateWuJiangHelper:InitVariable()
    self.m_actorAnchor = false
    self.m_bgPath = false
    self.m_wujiangCfg = false
    self.m_callBack = false
end

function CreateWuJiangHelper:CreateWuJiang(wuJiangData)
    if not wuJiangData then
        return
    end

    self:LoadBg()

    self:LoadRole3DCam()

    self:CreateRoleContainer()

    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end

    local wujiangID = math_ceil(wuJiangData.id)
    local weaponLevel = wuJiangData.weaponLevel
    self.m_wujiangCfg = ConfigUtil.GetWujiangCfgByID(wujiangID)
    if not self.m_wujiangCfg then
        Logger.LogError("CreateWuJiangHelper wujiangCfg error"..wujiangID)
        return
    end  

    self.m_seq = ActorShowLoaderInst:PrepareOneSeq()
    
    local showParam = ActorShowLoader.MakeParam(wujiangID, weaponLevel)
    showParam.stageSound = not lastIsShowOffPlayed

    ActorShowLoaderInst:CreateShowOffWuJiang(self.m_seq, showParam, self.m_roleContainerTran, function(actorShow)
        self.m_seq = 0
        self.m_actorShow = actorShow

        UIManagerInst:EnableMainCamera(false)

        self.m_actorShow:SetPosition(FarPos)
        self.m_actorShow:PlayStageAudio()
        
        if self.m_wujiangCfg.rare == CommonDefine.WuJiangRareType_1 then
            if self.m_callBack then
                self.m_callBack(actorShow)
            end
        else
            self.m_actorShow:ShowShowoffEffect(function()
                if self.m_callBack then
                    self.m_callBack(actorShow)
                end
            end)
        end
    end)
end


function CreateWuJiangHelper:CreateRoleContainer()
    if IsNull(self.m_roleContainerGo) then
        self.m_roleContainerGo = GameObject.Find("RoleContainer6")
        if IsNull(self.m_roleContainerGo) then
            self.m_roleContainerGo = GameObject("RoleContainer6")
            self.m_roleContainerTran = self.m_roleContainerGo.transform
        end
    end
end

function CreateWuJiangHelper:DestroyRoleContainer()
    if not IsNull(self.m_roleContainerGo) then
        GameObject.DestroyImmediate(self.m_roleContainerGo)
    end

    self.m_roleContainerGo = nil
    self.m_roleContainerTran = nil
end

--创建3D背景，可选
function CreateWuJiangHelper:LoadBg()
    if self.m_bgPath then
        if IsNull(self.roleBgGo) then
            GameObjectPoolInst:GetGameObjectAsync(self.m_bgPath, 
            function(go)
                if not IsNull(go) then
                    self.roleBgGo = go
                    self.m_roleCamTran = UIUtil.FindTrans(self.roleBgGo.transform, "RoleCamera")
                    self.m_roleCam = UIUtil.FindComponent(self.m_roleCamTran, Type_Camera)
                end
            end)
        end
    end
end

function CreateWuJiangHelper:UnLoadBg()
    if not IsNull(self.roleBgGo) then
        GameObjectPoolInst:RecycleGameObject(self.m_bgPath, self.roleBgGo)
    end

    self.roleBgGo = nil
    self.m_roleCamTran = nil
    self.m_roleCam = nil
end

function CreateWuJiangHelper:LoadRole3DCam()
    if self.m_needCreate3DCam then
        if IsNull(self.m_role3DCamGo) then
            GameObjectPoolInst:GetGameObjectAsync(Role3DCamPath, 
            function(go)
                if not IsNull(go) then
                    self.m_role3DCamGo = go
                    self.m_roleCam = UIUtil.FindComponent(go.transform, Type_Camera)
                end
            end)
        end
    end
end

function CreateWuJiangHelper:UnLoadRole3DCam()
    if not IsNull(self.m_role3DCamGo) then
        GameObjectPoolInst:RecycleGameObject(Role3DCamPath, self.m_role3DCamGo)
    end

    self.m_role3DCamGo = nil
    self.m_roleCam = nil
end

--设置根据锚点的坐标 可选
function CreateWuJiangHelper:SetAnchorPos()
    assert(self.m_roleCam ~= nil)
    assert(self.m_actorAnchor ~= nil)
    
    local screenPos = UIManagerInst.UICamera:WorldToScreenPoint(self.m_actorAnchor.position)
    local wPos = Vector3.New(screenPos.x , screenPos.y, 3.8)
    wPos = self.m_roleCam:ScreenToWorldPoint(wPos)

     --有宠物偏移位置
    if self.m_actorShow:GetPetID() > 0 then
        wPos.x = wPos.x - 0.24
    end
    self.m_actorShow:SetPosition(wPos)
end

function CreateWuJiangHelper:RecycleObj()

    UIManagerInst:EnableMainCamera(true)

    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end

    self.m_seq = 0
    ActorShowLoaderInst:Clear()
end

return CreateWuJiangHelper