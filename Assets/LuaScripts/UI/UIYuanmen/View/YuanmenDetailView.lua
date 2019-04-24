local table_insert = table.insert
local UIGameObjectLoaderInst = UIGameObjectLoader:GetInstance()
local YuanmenWujiangItemPrefab = "UI/Prefabs/Yuanmen/YuanmenWujiangItem.prefab"
local YuanmenWujiangItemClass = require("UI.UIYuanmen.View.YuanmenWujiangItem")
local yuanmenMgr = Player:GetInstance():GetYuanmenMgr()
local ConfigUtil = ConfigUtil

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam" 

local YuanmenDetailView = BaseClass("YuanmenDetailView", UIBaseView)
local base = UIBaseView 

function YuanmenDetailView:OnCreate()
    base.OnCreate(self)
    self.m_leftDesTextList = {} 
    self.m_rightDesTextList = {} 
    self.m_wujiangItemSeq = 0
    self.m_yuanmenWujiangItemList = {}

    self.m_rightWujiangInfoList = {}
    self.m_yuanmenID = -1 

    self.m_dropItemLoadSeq = 0
    self.m_dropItemList = {}
    self.m_dropItemDataList = nil
 
    self:InitView()
    self:HandleClick()
end

function YuanmenDetailView:InitView()
    self.m_blackBgTrans,
    self.m_firstWujiangItemPosTrans,
    -- self.m_leftDesContainerTrans,
    -- self.m_rightDesContainerTrans,
    self.m_gridContainerTrans,
    self.m_itemContentTrans,
    self.m_buzhenBtnTr
    = UIUtil.GetChildTransforms(self.transform, {
        "blackBg",
        "Container/topPanel/firstWujiangItemPos",
        -- "Container/middlePanel/leftContainer/additionDesContainer",
        -- "Container/middlePanel/rightContainer/additionDesContainer",
        "Container/topPanel/gridContainer",
        "Container/bottomPanel/itemScrollView/viewport/itemContent",
        "Container/bottomPanel/buzhenBtn",
    })
 
    local leftDesText_1, leftDesText_2, leftDesText_3, leftDesText_4, leftDesText_5, rightDesText_1, rightDesText_2, rightDesText_3, rightDesText_4, rightDesText_5

    leftDesText_1,
    leftDesText_2,
    leftDesText_3,
    leftDesText_4,
    leftDesText_5,
    rightDesText_1,
    rightDesText_2,
    rightDesText_3,
    rightDesText_4,
    rightDesText_5,
    self.m_enemyDesText,
    self.m_desLeftText,
    self.m_desRightText,
    self.m_mayDesText,
    self.m_buzhenBtnText = UIUtil.GetChildTexts(self.transform, {
         "Container/middlePanel/leftContainer/additionDesContainer/des1",
         "Container/middlePanel/leftContainer/additionDesContainer/des2",
         "Container/middlePanel/leftContainer/additionDesContainer/des3",
         "Container/middlePanel/leftContainer/additionDesContainer/des4",
         "Container/middlePanel/leftContainer/additionDesContainer/des5",
         "Container/middlePanel/rightContainer/additionDesContainer/des1",
         "Container/middlePanel/rightContainer/additionDesContainer/des2",
         "Container/middlePanel/rightContainer/additionDesContainer/des3",
         "Container/middlePanel/rightContainer/additionDesContainer/des4",
         "Container/middlePanel/rightContainer/additionDesContainer/des5", 
         "Container/topPanel/enemyDesText",
         "Container/middlePanel/leftContainer/desTitleText",
         "Container/middlePanel/rightContainer/desTitleText",
         "Container/bottomPanel/mayDesText",
         "Container/bottomPanel/buzhenBtn/Text",
    })

    self.m_leftDesTextList = {leftDesText_1, leftDesText_2, leftDesText_3, leftDesText_4, leftDesText_5}
    self.m_rightDesTextList = {rightDesText_1, rightDesText_2, rightDesText_3, rightDesText_4, rightDesText_5}

    self.m_enemyDesText.text = Language.GetString(3310)
    self.m_desLeftText.text = Language.GetString(3311)
    self.m_desRightText.text = Language.GetString(3312)
    self.m_mayDesText.text = Language.GetString(3313)
    self.m_buzhenBtnText.text = Language.GetString(3316)

    self.m_dropItemScrollView = self:AddComponent(LoopScrowView, "Container/bottomPanel/itemScrollView/viewport/itemContent", Bind(self, self.UpdateDropItem))

end

function YuanmenDetailView:CreateWujiangItem()  
    if #self.m_yuanmenWujiangItemList > 0 then 
        for i = 1, #self.m_yuanmenWujiangItemList do
            self.m_yuanmenWujiangItemList[i]:UpdateData(self.m_rightWujiangInfoList[i], i)
        end
    else
        self.m_wujiangItemSeq = UIGameObjectLoaderInst:PrepareOneSeq()
        UIGameObjectLoaderInst:GetGameObjects(self.m_wujiangItemSeq, YuanmenWujiangItemPrefab,  5, function(objs)
            self.m_wujiangItemSeq = 0
            if not objs then 
                return 
            end
            for i = 1, #objs do  
                local parentTrans = i == 1 and self.m_firstWujiangItemPosTrans or self.m_gridContainerTrans
                local yuanmenWujiangItem = YuanmenWujiangItemClass.New(objs[i], parentTrans, YuanmenWujiangItemPrefab)
                yuanmenWujiangItem:UpdateData(self.m_rightWujiangInfoList[i], i)
                table_insert(self.m_yuanmenWujiangItemList, yuanmenWujiangItem)
            end
        end)   
    end   
end

function YuanmenDetailView:UpdateViewCallBack(yuanmen_id) 
    self.m_yuanmenID = yuanmen_id
    local one_yuanmen = yuanmenMgr:GetOneYuanmenInfo(self.m_yuanmenID)
    if not one_yuanmen then
        return
    end 
    
    self.m_rightWujiangInfoList = one_yuanmen.right_wujiang_info_list 

    ---------------------服务端暂时有个bug，这里需要改成当打赢的时候，hp设置为0 -----------------------
    if one_yuanmen.passed then
        for i = 1, #self.m_rightWujiangInfoList do
            self.m_rightWujiangInfoList[i].hp = 0
        end
    end
    ------------------------------------------------------------------------------------------------

    self:CreateWujiangItem()
    self:SetDesText(one_yuanmen.left_buff_list,one_yuanmen.right_buff_list)
    self:SetDropItemData()

    coroutine.start(YuanmenDetailView.UpdateDropItemList,self)
end 

function YuanmenDetailView:SetDesText(left_buff_list, right_buff_list)
    for i = 1, 5 do 
        self.m_leftDesTextList[i].text = ""
        self.m_rightDesTextList[i].text = ""
    end

    local leftCount = #left_buff_list
    local rightCount = #right_buff_list
    
    for i = 1, leftCount do 
        local leftBuffCfg = ConfigUtil.GetYuanmenBuffCfgByID(left_buff_list[i])
        self.m_leftDesTextList[i].text = leftBuffCfg.desc
    end
    for i = 1, rightCount do
        local rightBuffCfg = ConfigUtil.GetYuanmenBuffCfgByID(right_buff_list[i])
        self.m_rightDesTextList[i].text = rightBuffCfg.desc
    end 
end

function YuanmenDetailView:SetDropItemData()
      local buzhenCfg = ConfigUtil.GetYuanmenBuZhenCfgByID(self.m_yuanmenID)
      local tempDropList = {}
      for i = 1, 6 do
            if buzhenCfg["item_id"..i] > 0 then
                local tempID = buzhenCfg["item_id"..i]
                local tempCount = buzhenCfg["item_count"..i]
                local data = {
                    item_id = tempID,
                    count = tempCount,
                }
                table_insert(tempDropList, data) 
            end
      end
      self.m_dropItemDataList = {
          dropList = tempDropList,
      }
end

function YuanmenDetailView:UpdateDropItemList()
    coroutine.waitforframes(1)
    if self.m_dropItemDataList == nil then
        return
    end
    
    local dropList = self.m_dropItemDataList.dropList
    
    if #self.m_dropItemList <= 0 then
        if self.m_dropItemLoadSeq == 0 then
            self.m_dropItemLoadSeq = UIGameObjectLoaderInst:PrepareOneSeq()
            UIGameObjectLoaderInst:GetGameObjects(self.m_dropItemLoadSeq, CommonAwardItemPrefab, #dropList, function(objs)
                self.m_dropItemLoadSeq = 0
                if objs then 
                    for i = 1, #objs do
                        local bagItem = CommonAwardItem.New(objs[i], self.m_itemContentTrans, CommonAwardItemPrefab)
                        bagItem:SetLocalScale(Vector3.New(0.8, 0.8, 1))
                        table_insert(self.m_dropItemList, bagItem)
                    end
                    self.m_dropItemScrollView:UpdateView(true, self.m_dropItemList, dropList)
                end
            end)
        end
    else
        self.m_dropItemScrollView:UpdateView(true, self.m_dropItemList, dropList) 
    end 
end

function YuanmenDetailView:UpdateDropItem(item,realIndex)
    local dropList = self.m_dropItemDataList.dropList
    if not dropList then
        return
    end
    local data = dropList[realIndex]  
    if data then
        local itemIconParam = AwardIconParamClass.New(data.item_id, data.count)
        item:UpdateData(itemIconParam)
    end  
end

function YuanmenDetailView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick) 

    UIUtil.AddClickEvent(self.m_buzhenBtnTr.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_blackBgTrans.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
end

function YuanmenDetailView:RemoveEvent()
    UIUtil.RemoveClickEvent(self.m_buzhenBtnTr.gameObject)
    UIUtil.RemoveClickEvent(self.m_blackBgTrans.gameObject) 
end

function YuanmenDetailView:OnClick(go,x,y)
   local goName = go.name
   if goName == "blackBg" then
        self:CloseSelf()
   elseif goName == "buzhenBtn" then
        UIManager:GetInstance():OpenWindow(UIWindowNames.UIYuanmenLineupMain, BattleEnum.BattleType_YUANMEN, self.m_yuanmenID)    
   end
end

function YuanmenDetailView:OnEnable(...) 
    base.OnEnable(self, ...) 
    local _, yuanmen_id = ...


    self:UpdateViewCallBack(yuanmen_id)
end 

function YuanmenDetailView:OnDisable()
    base.OnDisable(self)
    UIGameObjectLoaderInst:CancelLoad(self.m_dropItemLoadSeq)
    self.m_dropItemLoadSeq = 0 
    UIGameObjectLoaderInst:CancelLoad(self.m_wujiangItemSeq)
    self.m_wujiangItemSeq = 0 

    if #self.m_yuanmenWujiangItemList > 0 then
        for _,v in ipairs(self.m_yuanmenWujiangItemList) do
            v:Delete()
        end
    end
    self.m_yuanmenWujiangItemList = {} 

    if self.m_dropItemList then
        for _,v in ipairs(self.m_dropItemList) do
            v:Delete()
        end
    end
    self.m_dropItemList = {}
end 

function YuanmenDetailView:OnAddListener()
    base.OnAddListener(self)
    
    self:AddUIListener(UIMessageNames.MN_YUANMEN_REFRESH_CALLBACK, self.UpdateViewCallBack) 
end

function YuanmenDetailView:OnRemoveListener()
    base.OnRemoveListener(self)
    
    self:RemoveUIListener(UIMessageNames.MN_YUANMEN_REFRESH_CALLBACK, self.UpdateViewCallBack) 
    
end

function YuanmenDetailView:OnDestroy()
    self:RemoveEvent()
    base.OnDestroy(self) 
end


return YuanmenDetailView
