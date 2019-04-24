local table_insert = table.insert
local table_remove = table.remove
local QingYuanHeadItem = require "UI.UIWuJiang.View.QingYuanHeadItem"
local QingYuanGiftItemPrefab = "UI/Prefabs/WuJiang/QingYuan/QingYuanGiftItem.prefab"
local QingYuanGiftItemClass = require "UI.UIWuJiang.View.QingYuanGiftItem"
local wujiangMgr = Player:GetInstance().WujiangMgr
local itemMgr = Player:GetInstance():GetItemMgr()
local GameObject = CS.UnityEngine.GameObject  
local Vector2 = Vector2
local DOTweenShortcut = CS.DOTween.DOTweenShortcut 

local MeshRenderer = CS.UnityEngine.MeshRenderer
local Type_MeshRenderer = typeof(MeshRenderer)
local Shader = CS.UnityEngine.Shader

local UIQingYuanGiftView = BaseClass("UIQingYuanGiftView", UIBaseView)
local base = UIBaseView
 

function UIQingYuanGiftView:OnCreate()
    base.OnCreate(self)
    self.m_iconItemList = {}
    self.m_localIntimacyCfg = nil
    self.m_curSrcID = 0
    self.m_curDstID = 0

    self.m_giftItemLoaderSeq = 0
    self.m_giftItemList = {}

    self.m_panelXPos = nil

    self.m_shaderValueID = Shader.PropertyToID("_Value")
    
    self:InitView() 
    self:HandleClick()
end

function UIQingYuanGiftView:OnDestroy()
    self:RemoveClick()
    UIUtil.RemoveEvent(self.m_closeBtnTr.gameObject)

    self.m_shaderValueID = 0	
    
    base.OnDestroy(self)
end

function UIQingYuanGiftView:InitView()
    self.m_panelTr,
    self.m_maskBgTr,
    self.m_closeBtnTr,
    self.m_iconItemContentTr,
    self.m_giftContentTr,
    self.m_headPrefab,
    self.m_groupOneTr,
    self.m_groupTwoTr = UIUtil.GetChildTransforms(self.transform, {  
        "Panel",
        "MaskBg",
        "Panel/closeBtn",
        "Panel/IconItemContent",
        "Panel/GiftContent",  
        "HeadPrefab",
        "Panel/LevelPropertyContainer/GroupOne",
        "Panel/LevelPropertyContainer/GroupTwo", 
   })  

   self.m_titleTxt,
   self.m_pro2TitleTxt,
   self.m_leftPro1Txt,
   self.m_leftPro2Txt,
   self.m_rightPro1Txt,
   self.m_rightPro2Txt,
   self.m_finalTitleValueTxt,
   self.m_finalPro1Txt, 
   self.m_intimacyTxt = UIUtil.GetChildTexts(self.transform, {  
        "Panel/TitleBg/TitleTxt",
        "Panel/LevelPropertyContainer/GroupOne/Pro2Title",
        "Panel/LevelPropertyContainer/GroupOne/Left/LeftPro1",
        "Panel/LevelPropertyContainer/GroupOne/Left/LeftPro2Value",
        "Panel/LevelPropertyContainer/GroupOne/Right/RightPro1",
        "Panel/LevelPropertyContainer/GroupOne/Right/RightPro2Value",
        "Panel/LevelPropertyContainer/GroupTwo/MaxPro1/FinalTitleValue",
        "Panel/LevelPropertyContainer/GroupTwo/MaxPro1", 
        "Panel/Boilder/ValueBg/ValueTxt", 
   }) 
 
   self.m_headPrefab = self.m_headPrefab.gameObject

   local imgComponent = UIUtil.AddComponent(UIImage, self, "Panel/Boilder/ValueBg/ValueFillImg", AtlasConfig.DynamicLoad)
   self.m_intimacyFillImg = imgComponent:GetImage()  

   self.m_titleTxt.text = Language.GetString(3650)  
   self:SetClickScaleChg()
end

function UIQingYuanGiftView:SetClickScaleChg()
    local touchBegin = function(go,x,y)
        DOTweenShortcut.DOScale(self.m_closeBtnTr, 1.2, 0.3)
    end
    local touchEnd = function(go,x,y)
        DOTweenShortcut.DOScale(self.m_closeBtnTr, 1, 0.3)
    end

    UIUtil.AddDownEvent(self.m_closeBtnTr.gameObject, touchBegin)
    UIUtil.AddUpEvent(self.m_closeBtnTr.gameObject, touchEnd)
end

function UIQingYuanGiftView:OnEnable(...)
    base.OnEnable(self, ...)

    local _, curSrcID, curDstID = ...
    if not curSrcID then
        return
    end
    
    self.m_panelXPos = wujiangMgr:GetGiftViewPanelPosX()
    if self.m_panelXPos then  
        self.m_panelTr.localPosition = Vector2(self.m_panelXPos, 0)
    end

    self:LoadSummonEffect()

    self.m_curSrcID = curSrcID
    self.m_curDstID = curDstID
    self.m_lastLevel = 0
    self:UpdateData()
end

function UIQingYuanGiftView:FlushPanel(curSrcID, curDstID)
    if curSrcID == self.m_curSrcID and curDstID == self.m_curDstID then
        return
    end

    self.m_curSrcID = curSrcID
    self.m_curDstID = curDstID
    self.m_lastLevel = 0
    self:UpdateData()
end

function UIQingYuanGiftView:OnNtfIntimacyChg()
    self:UpdateData()
end

function UIQingYuanGiftView:UpdateData()   
    self.m_localIntimacyCfg = wujiangMgr:GetLocalIntimacyCfg(self.m_curSrcID) 

    local isActive, oneIntimacyInfo = wujiangMgr:IsWuJiangActive(self.m_curSrcID,self.m_curDstID)

    self.m_groupOneTr.gameObject:SetActive(true)
    self.m_groupTwoTr.gameObject:SetActive(false)

    local fillValue = 0
    if oneIntimacyInfo then
        local curLevel = oneIntimacyInfo.intimacy_level  
        local dstId = oneIntimacyInfo.dst_wujiang_id
        local curComcatId = math.floor(self.m_curSrcID * 1000000 + dstId * 100 + curLevel) 
        local curIntimacyLevelCfg = ConfigUtil.GetIntimacyLevelCfgByComcatID(curComcatId)
        if curIntimacyLevelCfg then  
            local cAttrName, cAttrValue = wujiangMgr:GetAttr(curIntimacyLevelCfg)
            self.m_pro2TitleTxt.text = string.format(Language.GetString(3655), cAttrName) 
            self.m_leftPro1Txt.text = string.format(Language.GetString(3652), curLevel)
            self.m_leftPro2Txt.text = string.format(Language.GetString(3662), cAttrValue) 

            self.m_finalTitleValueTxt.text = string.format(Language.GetString(3656), cAttrName, cAttrValue) 
            self.m_finalPro1Txt.text = string.format(Language.GetString(3652), curLevel)  

            self.m_intimacyTxt.text = string.format(Language.GetString(3658), oneIntimacyInfo.intimacy, curIntimacyLevelCfg.need_intimacy) 
            local amount = oneIntimacyInfo.intimacy/curIntimacyLevelCfg.need_intimacy
            
            if amount >= 1 then
                amount = 1
            end
            fillValue = amount
        end  
        local nextLevel = curLevel + 1
        local nextComcatId = math.floor(self.m_curSrcID * 1000000 + dstId * 100 + nextLevel)
        local nextIntimacyLevelCfg = ConfigUtil.GetIntimacyLevelCfgByComcatID(nextComcatId)
        if nextIntimacyLevelCfg then
            local nAttrName, nAttrValue = wujiangMgr:GetAttr(nextIntimacyLevelCfg) 
            self.m_pro2TitleTxt.text = string.format(Language.GetString(3655), nAttrName) 
            self.m_rightPro1Txt.text = string.format(Language.GetString(3652), nextLevel)
            self.m_rightPro2Txt.text = string.format(Language.GetString(3662), nAttrValue)  

            if self.m_showAttr and self.m_lastLevel ~= 0 and self.m_lastLevel ~= curLevel then
                self.m_showAttr = false
                UIUtil.OnceTweenTextScale(self.m_intimacyTxt, Vector3.one, 1.5)      
                UIUtil.OnceTweenTextScale(self.m_pro2TitleTxt, Vector3.one, 1.5)   
                UIUtil.OnceTweenTextScale(self.m_leftPro1Txt, Vector3.one, 1.5)   
                UIUtil.OnceTweenTextScale(self.m_leftPro2Txt, Vector3.one, 1.5)  
                UIUtil.OnceTweenTextScale(self.m_rightPro1Txt, Vector3.one, 1.5)   
                UIUtil.OnceTweenTextScale(self.m_rightPro2Txt, Vector3.one, 1.5)  
            end
        else
            -- 满级
            self.m_rightPro1Txt.text = ""
            self.m_rightPro2Txt.text = ""
            self.m_intimacyTxt.text = Language.GetString(3663)
            fillValue = 1
            self.m_groupOneTr.gameObject:SetActive(false)
            self.m_groupTwoTr.gameObject:SetActive(true) 
        end 

        self.m_lastLevel = curLevel

        if self.effectCircleMaterial then  
            self.effectCircleMaterial:SetFloat(self.m_shaderValueID, fillValue)
        end
    else
        self:UpdateUnActiveInfo()
    end   
    self:CreateIconItems()
    self:CreateGiftItems()
end   

function UIQingYuanGiftView:UpdateUnActiveInfo()
    local curLevel = 1

    local fillValue = 0
    local curComcatId = math.floor(self.m_curSrcID * 1000000 + self.m_curDstID * 100 + curLevel) 
    local curIntimacyLevelCfg = ConfigUtil.GetIntimacyLevelCfgByComcatID(curComcatId)
    if curIntimacyLevelCfg then  
        local cAttrName, cAttrValue = wujiangMgr:GetAttr(curIntimacyLevelCfg)
        self.m_pro2TitleTxt.text = string.format(Language.GetString(3655), cAttrName) 
        self.m_leftPro1Txt.text = string.format(Language.GetString(3652), curLevel)
        self.m_leftPro2Txt.text = string.format(Language.GetString(3662), cAttrValue) 

        self.m_finalTitleValueTxt.text = string.format(Language.GetString(3656), cAttrName, cAttrValue) 
        self.m_finalPro1Txt.text = string.format(Language.GetString(3652), curLevel) 
       
        self.m_intimacyTxt.text = string.format(Language.GetString(3658), 0, curIntimacyLevelCfg.need_intimacy) 
        fillValue = 0
    end 

    local nextLevel = 2
    local nextComcatId = math.floor(self.m_curSrcID * 1000000 + self.m_curDstID * 100 + nextLevel)
    local nextIntimacyLevelCfg = ConfigUtil.GetIntimacyLevelCfgByComcatID(nextComcatId)
    if nextIntimacyLevelCfg then
        local nAttrName, nAttrValue = wujiangMgr:GetAttr(nextIntimacyLevelCfg) 
        self.m_pro2TitleTxt.text = string.format(Language.GetString(3655), nAttrName) 
        self.m_rightPro1Txt.text = string.format(Language.GetString(3652), nextLevel)
        self.m_rightPro2Txt.text = string.format(Language.GetString(3662), nAttrValue)  

        if self.m_showAttr and self.m_lastLevel ~= 0 and self.m_lastLevel ~= curLevel then
            self.m_showAttr = false
            UIUtil.OnceTweenTextScale(self.m_intimacyTxt, Vector3.one, 1.5)    
            UIUtil.OnceTweenTextScale(self.m_pro2TitleTxt, Vector3.one, 1.5)   
            UIUtil.OnceTweenTextScale(self.m_leftPro1Txt, Vector3.one, 1.5)   
            UIUtil.OnceTweenTextScale(self.m_leftPro2Txt, Vector3.one, 1.5)  
            UIUtil.OnceTweenTextScale(self.m_rightPro1Txt, Vector3.one, 1.5)  
            UIUtil.OnceTweenTextScale(self.m_rightPro2Txt, Vector3.one, 1.5)            
        end
    else
        -- 满级
        self.m_rightPro1Txt.text = ""
        self.m_rightPro2Txt.text = ""
        self.m_intimacyTxt.text = Language.GetString(3663)
        fillValue = 1
        self.m_groupOneTr.gameObject:SetActive(false)
        self.m_groupTwoTr.gameObject:SetActive(true) 
    end  

    if self.effectCircleMaterial then  
        self.effectCircleMaterial:SetFloat(self.m_shaderValueID, fillValue)
    end
end

function UIQingYuanGiftView:LoadSummonEffect()
	if not self.summonEffect then
		
		local sortOrder = self:PopSortingOrder()
		self:AddComponent(UIEffect, "Panel/Boilder/ValueBg/ValueFillImg", sortOrder, "UI/Effect/Prefabs/qingyuan", function(effect)
			self.summonEffect = effect
			self.summonEffect:SetLocalPosition(Vector3.New(0, -97.6, 0))
			self.summonEffect:SetLocalScale(Vector3.New(1.74, 1.37, 1.74))

			if not self.effectCircleMaterial then
				local effectTrans = self.summonEffect.rectTrans
				if not IsNull(effectTrans) then
					local renderer = UIUtil.FindComponent(effectTrans,Type_MeshRenderer, "zhaohuanshou_qiti/qiti")
					if renderer and renderer.material then 
						self.effectCircleMaterial = renderer.material
						self.effectCircleMaterial:SetFloat(self.m_shaderValueID, 0)
					end
				end
			end
		end)
	end
end

function UIQingYuanGiftView:CreateIconItems()
    if #self.m_iconItemList > 0 then
        for i = 1, #self.m_iconItemList do
            self.m_iconItemList[i]:UpdateData(self.m_localIntimacyCfg[i], self.m_curSrcID)
        end
    else
        for i = 1, #self.m_localIntimacyCfg do
            local go = GameObject.Instantiate(self.m_headPrefab)
            if not IsNull(go) then
                local iconItem  = QingYuanHeadItem.New(go, self.m_iconItemContentTr)
                iconItem:UpdateData(self.m_localIntimacyCfg[i], self.m_curSrcID)
                table_insert(self.m_iconItemList, iconItem)
            end  
        end
    end 

    for k, v in ipairs(self.m_iconItemList) do
        local isShow = false
        isShow = v:GetCurDstID() == self.m_curDstID and true or false
        v:SetHighLightImgActive(isShow)
    end 
end

function UIQingYuanGiftView:CreateGiftItems()
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_curDstID)
    if not wujiangCfg then
        return
    end

    local job_type = wujiangCfg.nTypeJob
    local originGiftItemCfg = wujiangMgr:GetQYGiftItemCfgByJobType(job_type) 
    local giftItemCfg = self:SortGiftItemCfg(originGiftItemCfg) 
    if giftItemCfg then 
        if #self.m_giftItemList > 0 then
            for i = 1, #self.m_giftItemList do
                local itemID = giftItemCfg[i].item_id
                local count = itemMgr:GetItemCountByID(giftItemCfg[i].item_id)
                local callback = nil
                if count > 0 then
                    callback = function() 
                        self.m_showAttr = true
                        wujiangMgr:ReqImproveIntimacy(self.m_curSrcID, self.m_curDstID, itemID)
                    end 
                else
                    callback = function() 
                        UIManagerInst:OpenWindow(UIWindowNames.UIShop, CommonDefine.SHOP_MYSTERY)
                    end
                end  
                self.m_giftItemList[i]:UpdateData(itemID, count, callback)
            end
        else
            local giftItemCount = #giftItemCfg
            self.m_giftItemLoaderSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
            UIGameObjectLoader:GetInstance():GetGameObjects(self.m_giftItemLoaderSeq, QingYuanGiftItemPrefab, giftItemCount, function(objs)
                self.m_giftItemLoaderSeq = 0
                if objs then
                    for i = 1, #objs do
                        local giftItem = QingYuanGiftItemClass.New(objs[i], self.m_giftContentTr, QingYuanGiftItemPrefab)
                        local itemID = giftItemCfg[i].item_id
                        local count = itemMgr:GetItemCountByID(giftItemCfg[i].item_id)
                        local callback = nil
                        if count > 0 then
                            callback = function() 

                                self.m_showAttr = true
                                local isWuJiangActive = wujiangMgr:IsWuJiangActive(self.m_curSrcID, self.m_curDstID)
                                if isWuJiangActive then
                                    wujiangMgr:ReqImproveIntimacy(self.m_curSrcID, self.m_curDstID, itemID)
                                else
                                    UILogicUtil.FloatAlert(Language.GetString(3690))
                                end
                            end 
                        else
                            callback = function() 
                                UIManagerInst:OpenWindow(UIWindowNames.UIShop, CommonDefine.SHOP_MYSTERY)
                            end
                        end  
                        giftItem:UpdateData(itemID, count, callback)  
                        table_insert(self.m_giftItemList, giftItem)
                    end
                end
            end) 
        end
    end
end 
 
function UIQingYuanGiftView:SortGiftItemCfg(item_cfg)
    if not item_cfg then
        return 
    end   
    if #item_cfg <= 1 then
        return item_cfg
    end 
    local deepCopy = {}
    for i = 1, #item_cfg do
        deepCopy[i] = {}
        deepCopy[i] = { 
            item_id = item_cfg[i].item_id,
            add_value = item_cfg[i].add_value,
        }
    end

    local sortItemCfg = {}
    while #deepCopy > 0 do
        local minIndex = 1
        local minValue = deepCopy[1].add_value
        for i = 1, #deepCopy do 
            if deepCopy[i].add_value < minValue then 
                minValue = deepCopy[i].add_value
                minIndex = i
            end
        end
        table_insert(sortItemCfg, deepCopy[minIndex])
        table_remove(deepCopy, minIndex)
    end 
    return sortItemCfg
end

function UIQingYuanGiftView:OnItemChg(chg_item_data_list, itemChgReason)
    self:UpdateData() 
end

function UIQingYuanGiftView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
    UIUtil.AddClickEvent(self.m_closeBtnTr.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_maskBgTr.gameObject, onClick)
end

function UIQingYuanGiftView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_closeBtnTr.gameObject)
    UIUtil.RemoveClickEvent(self.m_maskBgTr.gameObject)
end

function UIQingYuanGiftView:OnClick(go, x, y)
    if go.name == "closeBtn" then
        self:CloseSelf()
    elseif go.name == "MaskBg" then
        self:CloseSelf()
        UIManagerInst:Broadcast(UIMessageNames.MN_WUJIANG_SKILL_DETAIL_SHOW, false)
    end
end

function UIQingYuanGiftView:OnAddListener()
    base.OnAddListener(self)
    
    self:AddUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_NTF_INTIMACY_CHG, self.OnNtfIntimacyChg) 
    self:AddUIListener(UIMessageNames.MN_WUJIANG_INTIMACY_FLUSH, self.FlushPanel) 
end

function UIQingYuanGiftView:OnRemoveListener()
    base.OnRemoveListener(self)
    
    self:RemoveUIListener(UIMessageNames.MN_BAG_ITEM_CHG, self.OnItemChg)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_NTF_INTIMACY_CHG, self.OnNtfIntimacyChg)  
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_INTIMACY_FLUSH, self.FlushPanel)  
end 

function UIQingYuanGiftView:OnDisable() 
    if self.m_iconItemList then
        for _, v in ipairs(self.m_iconItemList) do
            v:Delete()
        end
    end
    self.m_iconItemList = {}
    UIGameObjectLoader:GetInstance():CancelLoad(self.m_giftItemLoaderSeq)
    self.m_giftItemLoaderSeq = 0
    if #self.m_giftItemList > 0 then
        for k,v in ipairs(self.m_giftItemList) do
            v:Delete()    
        end
    end
    self.m_giftItemList = {}

    base.OnDisable(self)
end


return UIQingYuanGiftView