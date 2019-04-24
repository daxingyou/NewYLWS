local UITipsHelper = BaseClass("UITipsHelper", UIBaseContainer)
local base = UIBaseContainer

local Vector2 = Vector2
local Mathf_Clamp = Mathf.Clamp
local DoTween = CS.DOTween.DOTween
local Input = CS.UnityEngine.Input
local Screen = CS.UnityEngine.Screen
local Type_Canvas = typeof(CS.UnityEngine.Canvas)
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local Type_CanvasGroup = typeof(CS.UnityEngine.CanvasGroup)
local DOTweenSettings = CS.DOTween.DOTweenSettings
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local CalculateRelativeRectTransformBounds = CS.UnityEngine.RectTransformUtility.CalculateRelativeRectTransformBounds
local ScreenPointToLocalPointInRectangle = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle

local TweenTime = 0.3
local ScaleSize = Vector3.New(1.3, 1.3, 1.3)

function UITipsHelper:OnCreate()
    base.OnCreate(self)

    local canvas = self.transform:GetComponentInParent(Type_Canvas)
    self.m_canvasTran = canvas.transform
    self.m_canvasRectTran = self.m_canvasTran:GetComponent(Type_RectTransform)
    self.m_canvasGroup = self.transform:GetComponent(Type_CanvasGroup)
    self.m_needShowTip = false
end

function UITipsHelper:OnDestroy()
    self.m_canvasTran = nil
    self.m_canvasRectTran = nil
    self.m_canvasGroup = nil
    self.m_showEndCallBack = nil

	base.OnDestroy(self)
end

function UITipsHelper:Init(offset, clickPos, showEndCallBack)
    self.m_offset = offset or Vector3.zero
    self.m_clickPos = clickPos
    self.m_needShowTip = true
    self.m_size = false
    self.m_delayFrameCount = 1
    self.m_canvasGroup.alpha = 0.1
    self.m_showEndCallBack = showEndCallBack
end

function UITipsHelper:GetInputPos()
    --[[ if Input.touchSupported then
        print("Input.touchCount ", Input.touchCount)
        if Input.touchCount > 0 then
            local touch = Input.GetTouch(0)
            print("touch.position ", touch.position)
            return touch.position
        end
    else
        return Input.mousePosition 
    end

    Logger.LogError("GetInputPos nil") ]]

    return Input.mousePosition 
end

function UITipsHelper:LateUpdate()
    
    if not self.m_needShowTip then
        return
    end

    if  self.m_delayFrameCount > 0 then
        self.m_delayFrameCount =  self.m_delayFrameCount - 1
        return
    end

    local inputPos = self.m_clickPos or self:GetInputPos()
    --inputPos = inputPos + self.m_offset

    local screenPos = Vector2.New(inputPos.x + self.m_offset.x, inputPos.y + self.m_offset.y)
    local ok, localPos = ScreenPointToLocalPointInRectangle(self.m_canvasRectTran, screenPos, UIManagerInst.UICamera)
    
    if ok then
        local scaleRate = UIManagerInst:GetScaleRate()
        local height = Screen.height * scaleRate
        local width = Screen.width * scaleRate
        local half_height = height / 2 - 4
        local half_width = width / 2 - 4

        local bounds = CalculateRelativeRectTransformBounds(self.m_canvasTran, self.transform)
        local containerSize = bounds.size
        self.m_size = containerSize
        local max_x = half_width - containerSize.x / 2
        local max_y = half_height - containerSize.y / 2

        localPos.x = Mathf_Clamp(localPos.x, -max_x, max_x)
        localPos.y = Mathf_Clamp(localPos.y, -max_y, max_y)
        self.transform.anchoredPosition = Vector3.New(localPos.x, localPos.y, 0)
    end

    self.m_needShowTip = false

    self:TweenShow()
end

function UITipsHelper:TweenShow()
   --缩放
   self.transform.localScale = ScaleSize
   DOTweenShortcut.DOScale(self.transform, 1, TweenTime)

   --移动
   if self.m_size then
        local offsetY = self.m_size.y * 0.1
        local oldPos = self.transform.localPosition
        self.transform.localPosition = oldPos + Vector3.New(0, offsetY, 0)
        DOTweenShortcut.DOLocalMoveY(self.transform, oldPos.y, TweenTime)
    end

    --渐变
    local function setterFunc(alpha)
        self.m_canvasGroup.alpha = alpha
    end
    local tweener = DoTween.To(setterFunc, 0.1, 1, TweenTime)

    DOTweenSettings.OnComplete(tweener, function()
        if self.m_showEndCallBack then
            self.m_showEndCallBack()
            self.m_showEndCallBack = nil
        end
    end)
end

return UITipsHelper