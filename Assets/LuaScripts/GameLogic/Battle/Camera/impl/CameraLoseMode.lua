
local BattleEnum = BattleEnum
local GrayscaleEffect = CS.GrayscaleEffect
local CameraModeBase = require("GameLogic.Battle.Camera.CameraModeBase")

local CameraLoseMode = BaseClass("CameraLoseMode", CameraModeBase)

function CameraLoseMode:__init()
    self.m_showTime = 0
end

function CameraLoseMode:Start(loseReason)
    BattleCameraMgr:HideLayer(Layers.BATTLE_BLOOD)
    BattleCameraMgr:HideLayer(Layers.BATTLE_INFO)

    if loseReason == BattleEnum.BATTLE_LOSE_REASON_DEAD then
        self.m_showTime = 2
    elseif loseReason == BattleEnum.BATTLE_LOSE_REASON_TIMEOUT then
        self.m_showTime = 0.5
    end
    TimeScaleMgr:SetTimeScale(0.5)
end

function CameraLoseMode:End()
    self.m_showTime = 0
    BattleCameraMgr:ShowLayer(Layers.BATTLE_BLOOD)
    BattleCameraMgr:ShowLayer(Layers.BATTLE_INFO)
end

function CameraLoseMode:Update(deltaTime)
    if self.m_showTime > 0 then
        self.m_showTime = self.m_showTime - deltaTime
        if self.m_showTime <= 0 then
            self:ShowGray()
        end
    end
end

function CameraLoseMode:ShowGray()
    CtlBattleInst:Pause(BattleEnum.PAUSEREASON_EVERY, 100)
    local mat = ResourcesManagerInst:LoadSync("EffectCommonMat/DynamicMaterials/SE_GrayScale.mat", typeof(CS.UnityEngine.Material))
    GrayscaleEffect.ApplyEffect(mat)
    self:Finish()
end

function CameraLoseMode:Finish()
    TimeScaleMgr:SetTimeScale(1)

    local logic = CtlBattleInst:GetLogic()
    if logic then
        logic:ReqSettle(false)
    end
end

return CameraLoseMode