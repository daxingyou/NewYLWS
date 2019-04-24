
local table_insert = table.insert
local GameObject = CS.UnityEngine.GameObject
local UIUtil = UIUtil
local AtlasConfig = AtlasConfig
local ConfigUtil = ConfigUtil
local ImageConfig = ImageConfig
local Language = Language
local PBUtil = PBUtil
local Vector3 = Vector3

local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"

local SaiChangItem = BaseClass("SaiChangItem", UIBaseItem)
local base = UIBaseItem

function SaiChangItem:OnCreate()
    base.OnCreate(self)
    local btnNameText
    self.m_saichangNameText, self.m_scoreText, btnNameText = UIUtil.GetChildTexts(self.transform, {
        "Frame/SaichangBg/Text",
        "ScoreBg/Text",
        "AwardBtn/Text",
    })

    self.m_awardBtn, self.m_awardInfoTr, self.m_closeAwardBtn, self.m_awardGridTr = UIUtil.GetChildTransforms(self.transform, {
        "AwardBtn",
        "AwardInfo",
        "AwardInfo/Close",
        "AwardInfo/Grid",
    })

    btnNameText.text = Language.GetString(3999)
    self.m_awardInfoGo = self.m_awardInfoTr.gameObject
    self.m_awardInfoGo:SetActive(false)
    self.m_saichangImg = UIUtil.AddComponent(UIImage, self, "SaiChangImg", AtlasConfig.DynamicLoad)
    self.m_boxImg = UIUtil.AddComponent(UIImage, self, "AwardInfo/BoxImg", AtlasConfig.DynamicLoad)

    self.m_awardItemList = {}
    self.m_seq = 0


    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_awardBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_closeAwardBtn.gameObject, onClick)
end

function SaiChangItem:OnClick(go)
    if go.name == "AwardBtn" then
        self.m_awardInfoGo:SetActive(true)
    elseif go.name == "Close" then
        self.m_awardInfoGo:SetActive(false)
    end
end

function SaiChangItem:UpdateData(data)
    if not data then
        return
    end
    self.m_saichangNameText.text = data.competition_name
    self.m_scoreText.text = data.score_min
    self.m_saichangImg:SetAtlasSprite(data.image_name..".png", false, ImageConfig.GroupHerosWar)
    local boxCfg = ConfigUtil.GetYuanmenBoxAwardCfgByID(data.box_id)
    if boxCfg then
        self.m_boxImg:SetAtlasSprite(boxCfg.img_name)
        local tempAwardDataList = {} 
        local CreateAwardData = PBUtil.CreateAwardData
        for i = 1, 6 do 
            if boxCfg["award_item_id"..i] > 0 then 
                local item_id = boxCfg["award_item_id"..i]
                local count = boxCfg["award_item_count"..i]
                local oneAward = CreateAwardData(item_id, count)
                table_insert(tempAwardDataList, oneAward) 
            end 
        end

        if #self.m_awardItemList == 0 and self.m_seq == 0 then
            self.m_seq = UIGameObjectLoaderInst:PrepareOneSeq()
            UIGameObjectLoaderInst:GetGameObjects(self.m_seq, CommonAwardItemPrefab, #tempAwardDataList, function(objs)
                self.m_seq = 0 
                if objs then
                    for i = 1, #objs do
                        local awardItem = CommonAwardItem.New(objs[i], self.m_awardGridTr, CommonAwardItemPrefab)
                        awardItem:SetLocalScale(Vector3.New(0.8, 0.8, 0.8))
                        table_insert(self.m_awardItemList, awardItem)
    
                        local awardIconParam = AwardIconParamClass.New(tempAwardDataList[i]:GetItemData():GetItemID(), tempAwardDataList[i]:GetItemData():GetItemCount())
                        awardItem:UpdateData(awardIconParam)
                    end
                end
            end)
        end
        
    end
end

function SaiChangItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_awardBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_closeAwardBtn.gameObject)
    UIGameObjectLoaderInst:CancelLoad(self.m_boxSeq)
    self.m_boxSeq = 0

    for _, v in ipairs(self.m_awardItemList) do
        GameObject.Destroy(v:GetGameObject())
    end
    self.m_awardItemList = {}
    base.OnDestroy(self)
end


return SaiChangItem