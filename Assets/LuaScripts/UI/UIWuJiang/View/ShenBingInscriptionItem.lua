local ShenBingInscriptionItem = BaseClass("ShenBingInscriptionItem", UIBaseItem)
local base = UIBaseItem

local string_format = string.format
local ImageConfig = ImageConfig

function ShenBingInscriptionItem:OnCreate()
    base.OnCreate(self)

    self.m_attrNameText, self.m_attributeText = UIUtil.GetChildTexts(self.transform, {
        "InscriptionImg/InscriptionNameText",
        "bg/attributeText"
    })
    self.m_itemIconSpt = UIUtil.AddComponent(UIImage, self, "InscriptionImg", ImageConfig.MingWen)
end

function ShenBingInscriptionItem:SetData(index, mingwenData)
    if not mingwenData then
        self.m_attrNameText.text = ""
        self.m_attributeText.text = string_format(Language.GetString(2914), index * 5)
        self.m_itemIconSpt:SetAtlasSprite("default.png")
        return
    end

    local mingwenCfg = ConfigUtil.GetShenbingInscriptionCfgByID(mingwenData.mingwen_id)
    if mingwenCfg then
        self.m_attrNameText.text = mingwenCfg.name
        local nameList = CommonDefine.mingwen_second_attr_name_list
        local attrStr = ''
        for _, name in ipairs(nameList) do
            local hasPercent = true
            local val = mingwenCfg[name]
            if val and val > 0 then
                if name == "init_nuqi" then
                    hasPercent = false
                end
                local attrType = CommonDefine[name]
                if attrType then
                    local tempStr = nil
                    if hasPercent then
                        tempStr = Language.GetString(2910)
                        if i == 2 then
                            tempStr = Language.GetString(2911)
                        elseif i == 3 then
                            tempStr = Language.GetString(2912)
                        end
                    else
                        tempStr = Language.GetString(2942)
                        if i == 2 then
                            tempStr = Language.GetString(2943)
                        elseif i == 3 then
                            tempStr = Language.GetString(2944)
                        end
                    end
                    attrStr = attrStr..string_format(tempStr, Language.GetString(attrType + 10), val)
                end
            end
        end

        attrStr = attrStr..string_format(Language.GetString(2913), mingwenData.wash_times)
        self.m_attributeText.text = attrStr
        
        self.m_itemIconSpt:SetAtlasSprite(string_format(Language.GetString(84), mingwenData.mingwen_id))
    end
end

return ShenBingInscriptionItem