
local table_insert = table.insert
local GameObject = CS.UnityEngine.GameObject
local UIUtil = UIUtil
local AtlasConfig = AtlasConfig
local ConfigUtil = ConfigUtil
local ImageConfig = ImageConfig
local Vector3 = Vector3

local JunxianItem = BaseClass("JunxianItem", UIBaseItem)
local base = UIBaseItem

function JunxianItem:OnCreate()
    base.OnCreate(self)

    self.m_dengjieText, self.m_dengjieNameText = UIUtil.GetChildTexts(self.transform, {
        "DengjieText",
        "DengjiName",
    })

    self.m_layoutTr, self.m_itemTr = UIUtil.GetChildTransforms(self.transform, {
        "Layout",
        "Item",
    })

    self.m_itemPrefab = self.m_itemTr.gameObject

    self.m_itemList = {}
end

function JunxianItem:UpdateData(dengjie, dengjieName, junxianList)
    self.m_dengjieText.text = dengjie
    self.m_dengjieNameText.text = dengjieName

    for i = 1, #junxianList do
        local junxianCfg = ConfigUtil.GetGroupHerosJunxianCfgByID(junxianList[i][1])
        if junxianCfg then
            local item = self.m_itemList[i]
            if not item then
                item = GameObject.Instantiate(self.m_itemPrefab)
                local itemTr = item.transform
                itemTr:SetParent(self.m_layoutTr)
                itemTr.localScale = Vector3.one
                itemTr.localPosition = Vector3.zero
                table_insert(self.m_itemList, item)
                local height = itemTr.sizeDelta.y
                local sizeDelta = self:GetTransform().sizeDelta
                sizeDelta.y = sizeDelta.y + height + 1
                self:GetTransform().sizeDelta = sizeDelta
            end
            local junxianImg = UIUtil.AddComponent(UIImage, item, "JunxianImg")
            local junxianNameText = UIUtil.GetChildTexts(item.transform, {"JunxianImg/Text"})
            local needScoreText = UIUtil.GetChildTexts(item.transform, {"NeedScore"})

            junxianImg:SetAtlasSprite(junxianCfg.image_name..".png", true, ImageConfig.GroupHerosWar)
            junxianNameText.text = junxianCfg.name
            needScoreText.text = junxianCfg.score_min.."+"
        end
    end
    
end

function JunxianItem:OnDestroy()
    for _, v in ipairs(self.m_itemList) do
        GameObject.Destroy(v)
    end
    self.m_itemList = {}
    base.OnDestroy(self)
end


return JunxianItem