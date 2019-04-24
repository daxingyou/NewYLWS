local table_insert = table.insert
local table_remove = table.remove

local BagItemPrefabPath = TheGameIds.CommonBagItemPrefab
local BagItemClass = require("UI.UIBag.View.BagItem")
local ItemIconParam = require "DataCenter.ItemData.ItemIconParam"

local ConfigUtil = ConfigUtil

local UIInscriptionCaseItem = BaseClass("UIInscriptionCaseItem", UIBaseItem)
local base = UIBaseItem

function UIInscriptionCaseItem:OnCreate()

    base.OnCreate(self)

    self.m_inscriptionItemParent, self.m_delBtn, self.m_useBtn = 
    UIUtil.GetChildRectTrans(self.transform, {
        "InscriptionList",
        "DelBtn",
        "UseBtn"
    })

    local useBtnText
    self.m_caseNameText, useBtnText = UIUtil.GetChildTexts(self.transform, {
        "CaseNameText",
        "UseBtn/UseBtnText"
    })

    useBtnText.text = Language.GetString(675)

    
    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_delBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_useBtn.gameObject, onClick)

    self.m_inscriptionItemList = {}
    self.m_seq = 0
end

function UIInscriptionCaseItem:OnClick(go)
    if go.name == "DelBtn" then
        Player:GetInstance().InscriptionMgr:ReqDeleteInscriptionCase(self.m_caseIndex)
    elseif go.name == "UseBtn" then
        Player:GetInstance().InscriptionMgr:ReqUseInscriptionCase(self.m_wujiangIndex, self.m_caseIndex)
    end
end

function UIInscriptionCaseItem:UpdateData(caseData, wujiangIndex)

    if not caseData then
        return
    end

    self.m_caseIndex = caseData.inscription_case_index
    self.m_wujiangIndex = wujiangIndex

    if not caseData.inscriptions_info then
        return
    end

    local inscription_id_list = caseData.inscriptions_info.inscription_id_list
    if not inscription_id_list then
        return
    end
   
    self.m_caseNameText.text = caseData.case_name

    local delCount = #self.m_inscriptionItemList - #inscription_id_list
    if delCount > 0 then
        for i = #self.m_inscriptionItemList, #inscription_id_list, -1 do
            self.m_inscriptionItemList[i]:Delete()
            table_remove(self.m_inscriptionItemList, i)
        end
    end

    local function loadCallBack()
        for i, v in ipairs(self.m_inscriptionItemList) do
            self:UpdateInscriptionItem(v, inscription_id_list[i])
        end
    end

    local count = #inscription_id_list - #self.m_inscriptionItemList
    if count > 0 then
        if self.m_seq == 0 then
            self.m_seq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObjects(self.m_seq, BagItemPrefabPath, count, function(objs)
                self.m_seq = 0
                if objs then
                    for i = 1, #objs do
                        local inscriptionItem = BagItemClass.New(objs[i], self.m_inscriptionItemParent, BagItemPrefabPath)
                        table_insert(self.m_inscriptionItemList, inscriptionItem)
                    end

                    loadCallBack()
                end
            end)
        end
    else
        loadCallBack()
    end
end

function UIInscriptionCaseItem:UpdateInscriptionItem(inscriptionItem, itemID, count)
    count = count or 0
    local itemCfg = ConfigUtil.GetItemCfgByID(itemID)
    if inscriptionItem and itemCfg then
        local itemIconParam = ItemIconParam.New(itemCfg, count)
        itemIconParam.onClickShowDetail = true
        inscriptionItem:UpdateData(itemIconParam)
    end
end

function UIInscriptionCaseItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_delBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_useBtn.gameObject)
    for i, v in ipairs(self.m_inscriptionItemList) do
        v:Delete()
    end
    self.m_inscriptionItemList = {}

    UIGameObjectLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0
    
    base.OnDestroy(self)
end

return UIInscriptionCaseItem