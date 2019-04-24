local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"
local Vector3 = Vector3

local DuoBaoItem = BaseClass("DuoBaoItem", UIBaseItem)
local base = UIBaseItem

function DuoBaoItem:OnCreate()
    base.OnCreate(self)
    self.m_awardItem = nil
    self.m_tagIndex = 0
    self.m_hasCount = false

    self.m_itemPosTr,
    self.m_maskImgTr = UIUtil.GetChildTransforms(self.transform, {
        "ItemPos",
        "MaskImg",
    })

    self.m_itemCountTxt,
    self.m_notItemTxt = UIUtil.GetChildTexts(self.transform, { 
        "BaseImg/ItemCount",
        "BaseImg/NotItemTxt",
    })
    self.m_itemCountTxt.text = ""
    self.m_notItemTxt.text = ""
    self.m_maskImgTr.gameObject:SetActive(false)
end

function DuoBaoItem:UpdateData(item_data)
    if not item_data then
        return
    end
    self.m_tagIndex = item_data.tag_index

    local seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
    UIGameObjectLoader:GetInstance():GetGameObject(seq, CommonAwardItemPrefab, function(go)
        seq = 0
        if not IsNull(go) then
            local awardItem = CommonAwardItem.New(go, self.m_itemPosTr, CommonAwardItemPrefab)
            awardItem:SetLocalScale(Vector3.New(0.85, 0.85, 0.85))
            local awardIconParam = PBUtil.CreateAwardParamFromPbAward(item_data.one_award)
            awardItem:UpdateData(awardIconParam)

            self.m_awardItem = awardItem
        end
    end)

    local leftTimes = item_data.left_times
    if leftTimes <= 0 then
        self.m_hasCount = false
        self.m_itemCountTxt.text = ""
        self.m_notItemTxt.text = Language.GetString(3852)
        self.m_awardItem:SetMaskImgActive(true)
    else
        self.m_hasCount = true
        self.m_itemCountTxt.text = string.format(Language.GetString(3853), leftTimes, item_data.total_times)
        self.m_notItemTxt.text = ""
        self.m_awardItem:SetMaskImgActive(false)
    end
end 

function DuoBaoItem:SetMaskImgActive(isShow)
    isShow = isShow or false
    self.m_maskImgTr.gameObject:SetActive(isShow)
end

function DuoBaoItem:GetTagIndex()
    return self.m_tagIndex
end

function DuoBaoItem:GetHasCount()
    return self.m_hasCount
end

function DuoBaoItem:OnDestroy()
    if self.m_awardItem then
        self.m_awardItem:Delete()
    end
    self.m_awardItem = nil

    base.OnDestroy(self)
end

return DuoBaoItem