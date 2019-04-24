local string_format = string.format
local table_insert = table.insert
local math_floor = math.floor
local ConfigUtil = ConfigUtil
local UIUtil = UIUtil
local UILogicUtil = UILogicUtil
local Language = Language
local CommonDefine = CommonDefine
local UIGameObjectLoaderInstance = UIGameObjectLoader:GetInstance()

local DetailWelfareHelper = BaseClass("DetailWelfareHelper")

function DetailWelfareHelper:__init(fuliTr, fuliView)
    self.m_fuliView = fuliView

    self.m_titleText, self.m_totalText = UIUtil.GetChildTexts(fuliTr, {
        "Container/Fuli/bg/RightContainer/Welfare/Title/Text",
        "Container/Fuli/bg/RightContainer/Welfare/total",
    })

    self.m_welfareTr, self.m_contentTr = UIUtil.GetChildRectTrans(fuliTr, {
        "Container/Fuli/bg/RightContainer/Welfare",
        "Container/Fuli/bg/RightContainer/Welfare/ItemScrollView/Viewport/ItemContent",
    })
    
    self.m_welfareGo = self.m_welfareTr.gameObject

end

function DetailWelfareHelper:__delete()
    self.m_fuliView = nil
    self:Close()
end

function DetailWelfareHelper:Close()
    self.m_welfareGo:SetActive(false)

end
 
function DetailWelfareHelper:UpdateInfo(isReset)
    local oneFuli = self.m_fuliView:GetOneFuli()
    if not oneFuli then
        return
    end

    if isReset then
        self.m_contentTr.localPosition = Vector2.zero
        self.m_fuliView:UpdateScrollView()
    end
    self.m_welfareGo:SetActive(true)
    self.m_titleText.text = self.m_fuliView:GetTitleName()
    if oneFuli.fuli_id == 2 then
        self.m_totalText.text = string_format(Language.GetString(3442), self:GetTotal(oneFuli.f_param1))
    elseif oneFuli.fuli_id == 4 then
        self.m_totalText.text = string_format(Language.GetString(3443), math_floor(oneFuli.f_param1))
    else
        self.m_totalText.text = ""
    end

end

function DetailWelfareHelper:GetTotal(second)
    local hour = math_floor(second / 3600)
    local min = math_floor((second % 3600) / 60)
    if hour > 0 then
        return string_format("%d小时%d分钟", hour, min)
    else
        return string_format("%d分钟", min)
    end
end


return DetailWelfareHelper