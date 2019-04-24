local ACTOR_ATTR = ACTOR_ATTR
local Vector3 = Vector3
local CameraModeBase = require("GameLogic.Battle.Camera.CameraModeBase")
local CameraBoss1NormalMode = BaseClass("CameraBoss1NormalMode", CameraModeBase)
local GameUtility = CS.GameUtility
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local BattleEnum = BattleEnum

function CameraBoss1NormalMode:Start(...)
    local handType = ...
    local rotaDir = Vector3.left * 10

    local mainCamera = BattleCameraMgr:GetMainCamera()
    local rotation = mainCamera.transform.rotation.eulerAngles + rotaDir
    
    local tweener = DOTweenShortcut.DORotate(mainCamera.transform, rotation, 1.2)
    DOTweenSettings.SetDelay(tweener,0.1)
    DOTweenSettings.OnComplete(tweener, function()
        local rotation1 = mainCamera.transform.rotation.eulerAngles - rotaDir
        local tweener1 = DOTweenShortcut.DORotate(mainCamera.transform, rotation1, 0.1)
        DOTweenSettings.SetDelay(tweener1,0.1)

        DOTweenSettings.OnComplete(tweener1, function()
            local tweener2 = DOTweenShortcut.DOShakeRotation(mainCamera.transform, 0.5, 5)
            DOTweenSettings.SetDelay(tweener2,0.1)

            DOTweenSettings.OnComplete(tweener2, function()
                if CtlBattleInst:IsInFight() then
                    BattleCameraMgr:SwitchCameraMode(BattleEnum.CAMERA_MODE_DOLLY_GROUP, "Boss20", true)
                end
            end)
        end)
    end)
end


function CameraBoss1NormalMode:GetMode()
    return BattleEnum.CAMERA_MODE_BOSS1_NORMAL
end

return CameraBoss1NormalMode