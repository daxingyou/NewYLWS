local ConfigUtil = ConfigUtil
local wujiangMgr = Player:GetInstance().WujiangMgr
local GameUtility = CS.GameUtility


local QingYuanHeadItem = BaseClass("QingYuanHeadItem", UIBaseItem)
local base = UIBaseItem

function QingYuanHeadItem:OnCreate()
    base.OnCreate(self)
    self.m_curSrcID = 0
    self.m_curDstID = 0
    self:InitView()
end

function QingYuanHeadItem:InitView()
    self.m_iconBtnTr,
    self.m_frameImgTr, 
    self.m_hlImgTr = UIUtil.GetChildTransforms(self.transform, {  
        "IconClickBtn",
        "IconClickBtn/HeadIcon/Frame",
        "IconClickBtn/HeadIcon/HighLightImg",
    })   
    self.m_iconImage = UIUtil.AddComponent(UIImage, self, "IconClickBtn/HeadIcon", AtlasConfig.RoleIcon)
    self.m_frameImage = UIUtil.AddComponent(UIImage, self, "IconClickBtn/HeadIcon/Frame", AtlasConfig.DynamicLoad)
    self.m_highLightImg = UIUtil.AddComponent(UIImage, self, "IconClickBtn/HeadIcon/HighLightImg", AtlasConfig.DynamicLoad)
    
end

function QingYuanHeadItem:UpdateData(one_wujiang_info,src_id)
    if not one_wujiang_info then
        return
    end 
    
    self.m_curSrcID = src_id
    self.m_curDstID = one_wujiang_info.wujiang_id
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_curDstID)
    if not wujiangCfg then
        return
    end
    UILogicUtil.SetWuJiangFrame(self.m_frameImage, wujiangCfg.rare)
    self.m_iconImage:SetAtlasSprite(wujiangCfg.sIcon)
    local highLightImg = self:GetHighLightImg(wujiangCfg.rare) 
    self.m_highLightImg:SetAtlasSprite(highLightImg)  

    local isActive, _ = wujiangMgr:IsWuJiangActive(self.m_curSrcID, self.m_curDstID)  
    if isActive then
        GameUtility.SetUIGray(self.m_iconBtnTr.gameObject, false) 
        GameUtility.SetUIGray(self.m_frameImgTr.gameObject, false) 
        GameUtility.SetUIGray(self.m_hlImgTr.gameObject, false) 

        local onClick = UILogicUtil.BindClick(self, self.OnClick)
        UIUtil.AddClickEvent(self.m_iconBtnTr.gameObject, onClick)        
    else 
        GameUtility.SetUIGray(self.m_iconBtnTr.gameObject, true) 
        GameUtility.SetUIGray(self.m_frameImgTr.gameObject, true) 
        GameUtility.SetUIGray(self.m_hlImgTr.gameObject, true) 

        UIUtil.RemoveClickEvent(self.m_iconBtnTr.gameObject)  
    end  
end

function QingYuanHeadItem:OnClick(go, x, y)
    if go.name == "IconClickBtn" then 
        local giftView = UIManagerInst:GetWindow(UIWindowNames.UIQingYuanGiftView)
        if giftView then   
            UIManagerInst:Broadcast(UIMessageNames.MN_WUJIANG_INTIMACY_FLUSH, self.m_curSrcID, self.m_curDstID)
        else
            UIManagerInst:OpenWindow(UIWindowNames.UIQingYuanGiftView,self.m_curSrcID, self.m_curDstID) 
        end  
    end 
end

function QingYuanHeadItem:SetHighLightImgActive(isShow)
    self.m_highLightImg.gameObject:SetActive(isShow)
end

function QingYuanHeadItem:GetCurDstID()
    return self.m_curDstID
end

function QingYuanHeadItem:GetHighLightImg(rare)
    if rare == 1 then
        return "beibao18.png"
    elseif rare == 2 then
        return "beibao14.png"
    elseif rare == 3 then
        return "beibao16.png"
    else 
        return "beibao12.png"
    end
end

function QingYuanHeadItem:OnDestroy() 
    GameUtility.SetUIGray(self.m_iconBtnTr.gameObject, false) 
    GameUtility.SetUIGray(self.m_frameImgTr.gameObject, false) 
    GameUtility.SetUIGray(self.m_hlImgTr.gameObject, false) 

    if self.m_iconBtnTr then
        UIUtil.RemoveClickEvent(self.m_iconBtnTr.gameObject) 
    end 

    base.OnDestroy(self)
end

return QingYuanHeadItem
