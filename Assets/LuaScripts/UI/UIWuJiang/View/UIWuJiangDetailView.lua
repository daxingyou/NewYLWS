local GameObject = CS.UnityEngine.GameObject
local Type_GameObject = typeof(GameObject)
local RectTransform = CS.UnityEngine.RectTransform
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local Type_GridLayoutGroup = typeof(CS.UnityEngine.UI.GridLayoutGroup)
local Quaternion = Quaternion
local ConfigUtil = ConfigUtil
local UILogicUtil = UILogicUtil
local AtlasConfig = AtlasConfig
local shenbingMgr = Player:GetInstance():GetShenBingMgr()

local string_format = string.format
local tonumber = tonumber
local math_ceil = math.ceil
local table_insert = table.insert
local table_remove = table.remove
local table_choose = table.choose
local BattleEnum = BattleEnum
local string_sub = string.sub
local Vector3 = Vector3
local Vector2 = Vector2
local MotionBlurEffect = CS.MotionBlurEffect
local SkillUtil = SkillUtil
local SequenceEventType = SequenceEventType

local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings
local DOTween = CS.DOTween.DOTween
local BgBlurEffect = CS.BgBlurEffect
local Layers = Layers
local Type_Material = typeof(CS.UnityEngine.Material)

local UIWuJiangDetailFirstAttrItem = require "UI.UIWuJiang.View.UIWuJiangDetailFirstAttrItem"
local UIWuJiangDetailIconItem = require "UI.UIWuJiang.View.UIWuJiangDetailIconItem"
local UIWuJiangSkillDetailView = require("UI.UIWuJiang.View.UIWuJiangSkillDetailView")
local UIWuJiangQingYuanView = require("UI.UIWuJiang.View.UIWuJiangQingYuanView")
local WuJiangMgr = Player:GetInstance():GetWujiangMgr()

local UIWuJiangDetailView = BaseClass("UIWuJiangDetailView", UIBaseView)
local base = UIBaseView

local Tab_Attr = 1
local Tab_MingQian = 2
local Tab_ShenBing = 3
local Tab_Mounts = 4
local Tab_QingYuan = 5
local Tab_Max = 6
local CamOffset = Vector3.New(0, 0.5, 0)  

function UIWuJiangDetailView:OnCreate()
    base.OnCreate(self)

    self.m_posX = 0
    self.m_draging = false
    self.m_startDraging = false

    self.m_wujiangIndex = 1
    self.m_seq = 0
    self.m_wujiangCfg = nil
    self.m_curWuJiangData = nil
    self.m_actorShow = nil

    self.m_wujiangFirstAttrItemList = nil
    self.m_skill_qingyuan_iconList = {}

    self.m_roleCamChgTime = 0
    self.m_camMovePos = Vector3.zero

    self.m_skillDetailItem = nil
    self.m_qingyuanView = nil

    self.m_isShowOffPlayed = false
  
    self:InitView()
end

function UIWuJiangDetailView:InitView()
    self.m_wujiangRareImage = self:AddComponent(UIImage, "WuJiangNameText/WuJiangRareImage", AtlasConfig.DynamicLoad)
    self.m_wujiangJobImage = self:AddComponent(UIImage, "JobTypeImage", AtlasConfig.DynamicLoad)
    self.m_starList = {}
    for i = 1, 6 do
        local starImage = self:AddComponent(UIImage, "JobTypeImage/startList/star"..i, AtlasConfig.DynamicLoad)
        table_insert(self.m_starList, starImage)
    end
    self.m_lockImage = self:AddComponent(UIImage, "BgCanvas/lockBtn/lockImg", AtlasConfig.DynamicLoad)

    self.leftBtnRectTrans,
    self.rightBtnRectTrans, 
    self.m_actorAnchor, 
    self.m_BgLeftContainer,
    self.m_qingyuanPrefabTr = UIUtil.GetChildRectTrans(self.transform, {
        "Panel/dynamicCanvas/actorBtn/leftBtn",
        "Panel/dynamicCanvas/actorBtn/rightBtn",
        "Panel/dynamicCanvas/actorBtn/actorAnchor",
        "BgCanvas/leftContainer",
        "QingYuanPrefab",
    })

    self.m_DevBtnTrans,
    self.m_MingQianBtn,
    self.m_ShenBingBtn, 
    self.m_shenBingRedPointTr,
    self.m_MountBtn,
    self.actorBtn, 
    self.backBtn, 
    self.m_firstAttrTrans, 
    self.m_skillItemPrefab,
    self.m_skillAndQingYuanRoot,
    self.m_skillDetailTrans, 
    self.m_qingyuanPrefabTrans,
    self.m_rankBtn,
    self.m_attrBtn,
    self.m_xiaozhuanBtn,
    self.m_lockBtn = UIUtil.GetChildTransforms(self.transform, {
        "rightContainer/wujiangDevList/DevBtn",
        "rightContainer/wujiangDevList/MingQianBtn",
        "rightContainer/wujiangDevList/ShenBingBtn",
        "rightContainer/wujiangDevList/ShenBingBtn/RedPointImg",
        "rightContainer/wujiangDevList/MountBtn",
        "Panel/dynamicCanvas/actorBtn",
        "Panel/backBtn",
        "rightContainer/firstAttr", 
        "skillItemPrefab",
        "rightContainer/SkillAndQingYuanRoot",
        "SkillDetail/Container",
        "QingYuanPrefab/Panel",
        "BgCanvas/leftContainer/RankBtn",
        "BgCanvas/leftContainer/AttrBtn",
        "BgCanvas/leftContainer/XiaoZhuanBtn",
        "BgCanvas/lockBtn",
    })

    self.m_skillItemPrefab = self.m_skillItemPrefab.gameObject

    local wujiangDevText, skillText, rankBtnText, xiaoZhuanBtnTex, attrBtnText
    wujiangDevText, skillText, rankBtnText, xiaoZhuanBtnTex, attrBtnText, self.m_wujiangNameText, self.m_wujiangTupoText, 
    self.m_wuJiangLevelText, self.m_wuJiangCountryText , self.m_powerText = UIUtil.GetChildTexts(self.transform, {
        "rightContainer/wujiangDevText",
        "rightContainer/skillText",
        "BgCanvas/leftContainer/RankBtn/RankBtnText",
        "BgCanvas/leftContainer/XiaoZhuanBtn/XiaoZhuanBtnText",
        "BgCanvas/leftContainer/AttrBtn/AttrBtnText",
        "WuJiangNameText",
        "WuJiangNameText/WuJiangTupoText",
        "JobTypeImage/WuJiangLevelText",
        "JobTypeImage/CountryTypeText",
        "WuJiangNameText/PowerBg/powerText",
    })

    skillText.text = Language.GetString(619)
    wujiangDevText.text = Language.GetString(620)
    attrBtnText.text = Language.GetString(606)
    xiaoZhuanBtnTex.text = Language.GetString(607)
    rankBtnText.text = Language.GetString(608)

    self.m_shenBingRedPointTr.gameObject:SetActive(false)

    self:HandleClick()
    self:HandleDrag()
end

function UIWuJiangDetailView:GetSortWuJiangList()
    return WuJiangMgr:GetSortWuJiangList(WuJiangMgr.CurSortPriority, function(data, wujiangCfg)
        if wujiangCfg.country == WuJiangMgr.CurrCountrySortType or WuJiangMgr.CurrCountrySortType == CommonDefine.COUNTRY_5 then
            return true
        end
    end)
end

function UIWuJiangDetailView:OnEnable(...)
    base.OnEnable(self, ...)
    
    self.m_skillDetailTrans.localPosition = self.actorBtn.localPosition
    local x = self.actorBtn.localPosition.x 
    self.m_qingyuanPrefabTrans.localPosition = Vector2.New(x + 250, 0) 
    local newX = self.m_qingyuanPrefabTrans.localPosition.x 
    Player:GetInstance():GetWujiangMgr():SetGiftViewPanelPosX(newX)

    
    local _, wujiangIndex, isPlayShowOff = ...  --wujiangIndex是sortList Index
    self.m_isLoadDone = true

    if wujiangIndex then
        if isPlayShowOff ~= nil then
            self.m_isShowOffPlayed = isPlayShowOff
        else
            self.m_isShowOffPlayed = true
        end
        
        --WujiangMgr.CurrWuJiangIndex 其他界面 操作的武将
        if WuJiangMgr.CurrWuJiangIndex > 0 then 
            self.m_wujiangSortList =  self:GetSortWuJiangList()
            if self.m_wujiangSortList then
                local index = table.findIndex(self.m_wujiangSortList, function(v)
                    return v.index == WuJiangMgr.CurrWuJiangIndex
                end)
                if index > 0 then
                    wujiangIndex = index
                end
            end
        end
    end
   
    self.m_wujiangIndex = wujiangIndex and wujiangIndex or 1
    
    self:LoadRoleBg()
   
    self:UpdateData()

    TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
end

function UIWuJiangDetailView:OnDisable()

    self:ResetRoleCamPos()

    self:RecycleObj()
    self:UnLoadRoleBg()
    self:DestroyRoleContainer()
    self:KillTween()

    if self.m_wujiangFirstAttrItemList then
        for i,v in ipairs(self.m_wujiangFirstAttrItemList) do
            v:Delete()
        end
        self.m_wujiangFirstAttrItemList = nil
    end
    
    if self.m_skill_qingyuan_iconList then
        for i, v in ipairs(self.m_skill_qingyuan_iconList) do
            v:Delete()
        end
        self.m_skill_qingyuan_iconList = nil
    end

    self:ShowSkillDetail(false)

    if self.m_skillDetailItem then
        self.m_skillDetailItem:Release()
    end

    self.m_isShowOffPlayed = false

    WuJiangMgr.CurrWuJiangIndex = 0 --清空

    base.OnDisable(self)
end

function UIWuJiangDetailView:OnDestroy()
    self:RemoveClick()

    base.OnDestroy(self)
end

function UIWuJiangDetailView:OnAddListener()
	base.OnAddListener(self)
	
    self:AddUIListener(UIMessageNames.MN_WUJIANG_SKILL_DETAIL_SHOW, self.ShowSkillDetail)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_LOCK_CHG, self.ChangeLock)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_NTF_INTIMACY_CHG, self.OnNtfIntimacyChg)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange)
    self:AddUIListener(UIMessageNames.MN_WUJIANG_NTF_SHENBING_RED_POINT, self.UpdateShenBingRedPoint)
    self:AddUIListener(UIMessageNames.UIFRAME_ON_WINDOW_OPEN, self.OnWindowOpen)
    self:AddUIListener(UIMessageNames.UIFRAME_ON_WINDOW_CLOSE, self.OnWindowClose)
end

function UIWuJiangDetailView:OnRemoveListener()
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_SKILL_DETAIL_SHOW, self.ShowSkillDetail)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_LOCK_CHG, self.ChangeLock)
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_NTF_INTIMACY_CHG, self.OnNtfIntimacyChg) 
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_POWER_CHG, self.PowerChange) 
    self:RemoveUIListener(UIMessageNames.MN_WUJIANG_NTF_SHENBING_RED_POINT, self.UpdateShenBingRedPoint)
    self:RemoveUIListener(UIMessageNames.UIFRAME_ON_WINDOW_OPEN, self.OnWindowOpen)
    self:RemoveUIListener(UIMessageNames.UIFRAME_ON_WINDOW_CLOSE, self.OnWindowClose)

	base.OnRemoveListener(self)
end

function UIWuJiangDetailView:PowerChange(power, wujiangIndex)
    if self.m_curWuJiangData.index == wujiangIndex then
        self.m_powerText.text = math_ceil(self.m_curWuJiangData.power + power)
        UILogicUtil.PowerChange(power)
    end
end

function UIWuJiangDetailView:CreateRoleContainer()
    if IsNull(self.m_roleContainerGo) then
        self.m_roleContainerGo = GameObject("RoleContainer")
        self.mRoleContainerTrans = self.m_roleContainerGo.transform
    end
end

function UIWuJiangDetailView:DestroyRoleContainer()
    if not IsNull(self.m_roleContainerGo) then
        GameObject.DestroyImmediate(self.m_roleContainerGo)
    end

    self.m_roleContainerGo = nil
    self.mRoleContainerTrans = nil
end

function UIWuJiangDetailView:CreateWuJiang()

    self:CreateRoleContainer()

    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end

    if self.m_curWuJiangData then
        local wujiangID = math_ceil(self.m_curWuJiangData.id)
        local weaponLevel = self.m_curWuJiangData.weaponLevel

        self:ResetRoleCamPos()

        self.m_seq = ActorShowLoader:GetInstance():PrepareOneSeq()

        local lastIsShowOffPlayed = self.m_isShowOffPlayed 
        local showParam = ActorShowLoader.MakeParam(wujiangID, weaponLevel)
        showParam.stageSound = not lastIsShowOffPlayed

        self.m_isLoadDone = false

        ActorShowLoader:GetInstance():CreateShowOffWuJiang(self.m_seq, showParam, self.mRoleContainerTrans, function(actorShow)
            self.m_seq = 0
            self.m_actorShow = actorShow
           
            self.m_actorShow:SetPosition(Vector3.New(100000, 100000, 100000))

            local function loadCallBack()
                local screenPos = UIManagerInst.UICamera:WorldToScreenPoint(self.m_actorAnchor.position)
                local wPos = Vector3.New(screenPos.x , screenPos.y, 5.037)
                wPos = self.m_roleCam:ScreenToWorldPoint(wPos)

                --有宠物偏移位置
                if self.m_actorShow:GetPetID() > 0 then
                    wPos.x = wPos.x - 0.24
                end
                self.m_actorShow:SetPosition(Vector3.New(wPos.x, 0.01, wPos.z))
                self.m_actorShow:SetEulerAngles(Vector3.New(0, self.m_wujiangCfg.showRotate, 0))

                --拉近摄像机的位置换算
                local actorPos = self.m_actorShow:GetPosition()
                if actorPos then
                    local dir = Vector3.Normalize(actorPos - self.m_roleCamOriginPos)
                    self.m_camMovePos =  self.m_roleCamOriginPos + dir * 2
                    self.m_camMovePos.x = tonumber(string_format("%0.2f", self.m_camMovePos.x))
                    self.m_camMovePos.y = tonumber(string_format("%0.2f", self.m_camMovePos.y))
                    self.m_camMovePos.z = tonumber(string_format("%0.2f", self.m_camMovePos.z))
                    self.m_camMovePos = self.m_camMovePos + CamOffset

                    --策划偏移值
                    local camPos = self.m_wujiangCfg.camMovePos
                    if #camPos > 0 then
                       self.m_camMovePos = self.m_camMovePos + Vector3.New(camPos[1], camPos[2], camPos[3])
                    end
                else
                    self.m_camMovePos = self.m_roleCamOriginPos
                end

                --正在播showOff,则播放出场音效
                if not lastIsShowOffPlayed then
                    self.m_actorShow:PlayStageAudio()
                end

                self.m_isLoadDone = true
                TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.SHOW_UI_END, self.winName)
            end

            --N卡判断
            if self.m_wujiangCfg.rare == CommonDefine.WuJiangRareType_1 then
                loadCallBack()
                return
            end

            if self.m_isShowOffPlayed then
                self.m_isShowOffPlayed = false
                self.m_actorShow:PlayAnim(BattleEnum.ANIM_IDLE)

                loadCallBack()
            else
                self.m_actorShow:ShowShowoffEffect(loadCallBack)
            end
        end)
    end
end

function UIWuJiangDetailView:RecycleObj()
    if self.m_actorShow then
        self.m_actorShow:Delete()
        self.m_actorShow = nil
    end
    ActorShowLoader:GetInstance():CancelLoad(self.m_seq)
    self.m_seq = 0
    
end

function UIWuJiangDetailView:LoadRoleBg()
    GameObjectPoolInst:GetGameObjectAsync(PreloadHelper.RoleBgPath, 
        function(go)
            if not IsNull(go) then
                self.roleBgGo = go
                self.m_roleCamTrans = UIUtil.FindTrans(self.roleBgGo.transform, "RoleCamera")
                self.m_roleCam = UIUtil.FindComponent(self.m_roleCamTrans, typeof(CS.UnityEngine.Camera))

                self.m_roleCamOriginPos = self.m_roleCamTrans.localPosition
                self.m_roleCamOriginFOV = self.m_roleCam.fieldOfView
                self.m_roleCamOriginRot = self.m_roleCamTrans.localEulerAngles
            end
        end)
end

function UIWuJiangDetailView:UnLoadRoleBg()

    if not IsNull(self.roleBgGo) then
        GameObjectPoolInst:RecycleGameObject(PreloadHelper.RoleBgPath, self.roleBgGo)
    end

    self.roleBgGo = nil
    self.m_roleCam = nil
    self.m_roleCamTrans = nil
end

function UIWuJiangDetailView:HandleDrag()
    local function DragBegin(go, x, y)
        self.m_startDraging = false
        self.m_draging = false
    end

    local function DragEnd(go, x, y)
        self.m_startDraging = false
        self.m_draging = false
    end

    local function Drag(go, x, y)
        if not self.m_startDraging then
            self.m_startDraging = true

            if x then
                self.m_posX = x
            end
            return
        end

        self.m_draging = true

        if x and self.m_posX then
            if self.m_actorShow then
                local deltaX = x - self.m_posX
                if deltaX > 0 then
                    self.m_actorShow:RolateUp(-12)
                else 
                    self.m_actorShow:RolateUp(12)
                end
            end

            self.m_posX = x
           
        else
            -- print("error pos, ", x, self.m_posX)
        end
    end
   
    UIUtil.AddDragBeginEvent(self.actorBtn.gameObject, DragBegin)
    UIUtil.AddDragEndEvent(self.actorBtn.gameObject, DragEnd)
    UIUtil.AddDragEvent(self.actorBtn.gameObject, Drag)
end

function UIWuJiangDetailView:HandleClick()
    local onClick = UILogicUtil.BindClick(self, self.OnClick, 0)
    local onClick2 = UILogicUtil.BindClick(self, self.OnClick, 101)

    UIUtil.AddClickEvent(self.m_DevBtnTrans.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_MingQianBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_ShenBingBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_MountBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.leftBtnRectTrans.gameObject, UILogicUtil.BindClick(self, self.OnClick, 116))
    UIUtil.AddClickEvent(self.rightBtnRectTrans.gameObject, UILogicUtil.BindClick(self, self.OnClick, 116))
    UIUtil.AddClickEvent(self.backBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.actorBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_rankBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_attrBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_xiaozhuanBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_lockBtn.gameObject, onClick2)
end

function UIWuJiangDetailView:RemoveClick()
    UIUtil.RemoveClickEvent(self.m_DevBtnTrans.gameObject)
    UIUtil.RemoveClickEvent(self.m_MingQianBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_ShenBingBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_MountBtn.gameObject)
    UIUtil.RemoveClickEvent(self.leftBtnRectTrans.gameObject)
    UIUtil.RemoveClickEvent(self.rightBtnRectTrans.gameObject)
    UIUtil.RemoveClickEvent(self.backBtn.gameObject)
    UIUtil.RemoveClickEvent(self.actorBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_rankBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_attrBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_xiaozhuanBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_lockBtn.gameObject)

    UIUtil.RemoveDragEvent(self.actorBtn.gameObject)
end

function UIWuJiangDetailView:UpdateData() 
     --todo 数据变化时更新
     self.m_wujiangSortList = self:GetSortWuJiangList()
     if not self.m_wujiangSortList then
         Logger.LogError("GetSortWuJiangList error")
         return
     end

     --考虑删除武将的情况
     local count = #self.m_wujiangSortList
     if self.m_wujiangIndex > count and count ~= 0 then
         self.m_wujiangIndex = count
     end

     if self.m_wujiangIndex <= #self.m_wujiangSortList then
         self.m_curWuJiangData = self.m_wujiangSortList[self.m_wujiangIndex]
         self.m_wujiangCfg = ConfigUtil.GetWujiangCfgByID(self.m_curWuJiangData.id)
         if self.m_wujiangCfg then
            --创建武将
            self:CreateWuJiang()
            --刷新面板数据
            self:UpdatePanelView()
         end
     end

    self:UpdateShenBingRedPoint()

    self:CheckBtnMove()
end

function UIWuJiangDetailView:UpdateShenBingRedPoint() 
    if self.m_curWuJiangData then
        if self.m_curWuJiangData.shenbing_idx > 0 then 
            self.m_shenBingRedPointTr.gameObject:SetActive(false)
        else  
            local status = false 
            local curWujiangId = self.m_curWuJiangData.id 
            local IdDic = shenbingMgr:GetShenBingWuJiangIdDic()
            if IdDic then
                if IdDic[curWujiangId] and IdDic[curWujiangId] > 0 then
                    status = true
                end
            end
            self.m_shenBingRedPointTr.gameObject:SetActive(status)
        end
    end
end

function UIWuJiangDetailView:UpdatePanelView()
    self:UpdateFirstAttr()
    self:UpdateSkillAndQingYuan()
    self:UpdateWuJiangBaseInfo()

    local isShow = self.m_wujiangCfg.rare == CommonDefine.WuJiangRareType_1 or self.m_wujiangCfg.rare == CommonDefine.WuJiangRareType_2
    self.m_ShenBingBtn.gameObject:SetActive(not isShow)
    self.m_MountBtn.gameObject:SetActive(not isShow)
end

function UIWuJiangDetailView:CanClick()
     --判断武将是否已加载好了
    if not self.m_actorShow then
        return false
    end
    return true
end

function UIWuJiangDetailView:Update()
   
    if self.m_roleCamChgTime > 0 then
        self.m_roleCamChgTime = self.m_roleCamChgTime - Time.deltaTime
    end
end

function UIWuJiangDetailView:UpdateFirstAttr()
    
    if not self.m_wujiangCfg then
        return
    end

    local loadCallBack = function() 
        for i = 1, #self.m_wujiangFirstAttrItemList do
            if self.m_wujiangFirstAttrItemList[i] then
                self.m_wujiangFirstAttrItemList[i]:SetData(self.m_curWuJiangData, i)
            end
        end
    end

    if not self.m_wujiangFirstAttrItemList then
        self.m_wujiangFirstAttrItemList = {}

        local grid = self.m_firstAttrTrans:GetComponent(Type_GridLayoutGroup)

        local prefab = ResourcesManagerInst:LoadSync(TheGameIds.FirstAttrItemPrefab, Type_GameObject)
        if IsNull(prefab) then
            return
        end
        
        for i = 1, 4 do
            local go = GameObject.Instantiate(prefab)
            if not IsNull(go) then
                local attrItem  = UIWuJiangDetailFirstAttrItem.New(go, self.m_firstAttrTrans)
                table_insert(self.m_wujiangFirstAttrItemList, attrItem)
            end
        end

        grid.enabled = true
        self.m_grid_enabled = true

        if #self.m_wujiangFirstAttrItemList == 4 then
            loadCallBack()
        end
       
    else
        loadCallBack()
    end
end

function UIWuJiangDetailView:UpdateSkillAndQingYuan()
    local skill_list = self.m_curWuJiangData.skill_list
    if not skill_list then
        return
    end

    local list = table_choose(skill_list, function(k, v)
        local skillCfg = ConfigUtil.GetSkillCfgByID(v.id)
        if skillCfg then
            if not SkillUtil.IsAtk(skillCfg) then
                return true
            end
        end
    end) 
    
    skill_list = list

    local hasIntimacy = true
    local intimacyCfg = ConfigUtil.GetIntimacyCfgByID(self.m_curWuJiangData.id)
    if not intimacyCfg then
        hasIntimacy = false
    end

    local count = #skill_list + (hasIntimacy and 1 or 0)
    if not self.m_skill_qingyuan_iconList then
        self.m_skill_qingyuan_iconList = {}
    end
    
    for i = 1, 4 do
        local iconItem = self.m_skill_qingyuan_iconList[i]
        if i <= count then
            if not iconItem then
                local go = GameObject.Instantiate(self.m_skillItemPrefab)
                if not IsNull(go) then
                   local iconItem  = UIWuJiangDetailIconItem.New(go, self.m_skillAndQingYuanRoot)
                   table_insert(self.m_skill_qingyuan_iconList, iconItem)
                end
            end
        else
            if iconItem then
                table_remove(self.m_skill_qingyuan_iconList, i)
                iconItem:Delete()
            end
        end
    end

    local function ClickSkillItem(iconItem)
        if iconItem then 
            local iconIndex = iconItem:GetIconIndex() 
            self:ShowSkillDetail(true, iconItem:GetSkillID(), iconIndex, iconIndex == 4)

            AudioMgr:PlayUIAudio(103)
        end
    end

    for i = 1, #self.m_skill_qingyuan_iconList do
        if self.m_skill_qingyuan_iconList[i] then
            if i <= #skill_list then
                self.m_skill_qingyuan_iconList[i]:SetData(skill_list[i], nil, self.m_curWuJiangData.index, i, ClickSkillItem)
            else
                self.m_skill_qingyuan_iconList[i]:SetData(nil, true, self.m_curWuJiangData.index, i, ClickSkillItem)
            end

            self.m_skill_qingyuan_iconList[i]:SetSelect(false)
        end
    end
end

function UIWuJiangDetailView:UpdateWuJiangBaseInfo()
    if not self.m_curWuJiangData then
        return
    end

    if not self.m_wujiangCfg then
        return
    end

    self.m_wujiangNameText.text = self.m_wujiangCfg.sName
    if self.m_curWuJiangData.tupo > 0 then
        self.m_wujiangTupoText.text = string.format("%+d", self.m_curWuJiangData.tupo)
    else
        self.m_wujiangTupoText.text = ""
    end

    local wujiangStarCfg = ConfigUtil.GetWuJiangStarCfgByID(self.m_curWuJiangData.star)
    if wujiangStarCfg then
        self.m_wuJiangLevelText.text = Language.GetString(609)..string.format("%d", self.m_curWuJiangData.level).."/"..wujiangStarCfg.level_limit
    end

    self.m_wuJiangCountryText.text = UILogicUtil.GetWuJiangCountryName(self.m_wujiangCfg.country).." • "..UILogicUtil.GetWuJiangJobName(self.m_wujiangCfg.nTypeJob)
    UILogicUtil.SetWuJiangRareImage(self.m_wujiangRareImage, self.m_wujiangCfg.rare)
    UILogicUtil.SetWuJiangJobImage(self.m_wujiangJobImage, self.m_wujiangCfg.nTypeJob)

    local star = self.m_curWuJiangData.star
    for i = 1, #self.m_starList do
        if self.m_starList[i] then
            if i <= star then
                self.m_starList[i]:SetAtlasSprite("ty11.png")
            else
                self.m_starList[i]:SetAtlasSprite("peiyang23.png")
            end
        end
    end
    
    UILogicUtil.SetLockImage(self.m_lockImage, self.m_curWuJiangData.locked == 1)
    self.m_powerText.text = math_ceil(self.m_curWuJiangData.power)
end

function UIWuJiangDetailView:CheckBtnMove()

    self:KillTween()
    
    local isShowBtn = self.m_wujiangIndex > 1
    self.leftBtnRectTrans.gameObject:SetActive(isShowBtn)
    self.leftBtnRectTrans.anchoredPosition = Vector2.New(-30, self.leftBtnRectTrans.anchoredPosition.y)
    
    if isShowBtn then
        self.m_tweener = UIUtil.LoopMoveLocalX(self.leftBtnRectTrans, -30, -59.95, 0.6)
    end

    isShowBtn = self.m_wujiangSortList and self.m_wujiangIndex < #self.m_wujiangSortList
    self.rightBtnRectTrans.gameObject:SetActive(isShowBtn)
    self.rightBtnRectTrans.anchoredPosition = Vector2.New(34.95, self.rightBtnRectTrans.anchoredPosition.y)

    if isShowBtn then
        self.m_tweener2 = UIUtil.LoopMoveLocalX(self.rightBtnRectTrans, 34.95, 64.95, 0.6)
    end
end

function UIWuJiangDetailView:KillTween()
    UIUtil.KillTween(self.m_tweener)
    UIUtil.KillTween(self.m_tweener2)
end

function UIWuJiangDetailView:OnClick(go, x, y)

    if go.name == "DevBtn" then
        if self.m_curWuJiangData then
            UIManagerInst:OpenWindow(UIWindowNames.UIWuJiangDevelop, self.m_curWuJiangData.index)
        end
       
    elseif go.name == "MingQianBtn" then
        if self.m_curWuJiangData then
            UILogicUtil.SysShowUI(SysIDs.INSCRIPTION, self.m_curWuJiangData.index)
        end
    elseif go.name == "ShenBingBtn" then
        if self.m_curWuJiangData then
            TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, "ShenBingBtn")
            UIManagerInst:OpenWindow(UIWindowNames.UIShenBing, self.m_curWuJiangData.id, self.m_curWuJiangData.index)
        end
    elseif go.name == "MountBtn" then
        if self.m_curWuJiangData then
            TimelineMgr:GetInstance():TriggerEvent(SequenceEventType.CLICK_UI, self.winName)
            UIManagerInst:OpenWindow(UIWindowNames.UIZuoQi, self.m_curWuJiangData.index)
        end
    elseif go.name == "lockBtn" then
        WuJiangMgr:ReqLock(self.m_curWuJiangData.index)

    elseif go.name == "leftBtn" then
        if self:CanClick() then
            if self.m_wujiangSortList and self.m_wujiangIndex > 1 then
                self.m_wujiangIndex = self.m_wujiangIndex - 1
                self:UpdateData()
            end
        end
    elseif go.name == "rightBtn" then
        if self:CanClick() then
            if self.m_wujiangSortList and self.m_wujiangIndex < #self.m_wujiangSortList then
                self.m_wujiangIndex = self.m_wujiangIndex + 1
                self:UpdateData()
            end
        end
    elseif go.name == "backBtn" then
        -- UIManagerInst:CloseWindow(UIWindowNames.UIWuJiangDetail)
        -- UIManagerInst:OpenWindow(UIWindowNames.UIWuJiangList)

        self:CloseSelf()

    elseif go.name == "actorBtn" then

        if not self:CanClick() then
            return
        end

        if self.m_draging then
            return
        end

        if not self.m_isLoadDone then
            return
        end

        local fov = self.m_roleCam.fieldOfView
        if self.m_roleCam then
            if self.m_roleCamChgTime > 0 then
                -- print("can not roleCamChg wait, ", self.m_roleCamChgTime)
                return
            end

            self.m_roleCamChgTime = 2
            if not self.m_roleCamChg then
                self.m_roleCamChg = true
                self:MoveCam(fov, 28, self.m_roleCamOriginRot.x, 2, self.m_camMovePos, 0.3)
            else
                self.m_roleCamChg = false
                self:MoveCam(fov, self.m_roleCamOriginFOV, 2, self.m_roleCamOriginRot.x, self.m_roleCamOriginPos, 0.3)
            end
        end
    elseif go.name == "RankBtn" then
        UIManagerInst:OpenWindow(UIWindowNames.UIWuJiangRank, self.actorBtn.localPosition, self.m_curWuJiangData)
    elseif go.name == "AttrBtn" then
        WuJiangMgr:ReqWuJiangSecondAttrInfo(self.m_curWuJiangData.index)
    elseif go.name == "XiaoZhuanBtn" then
        self:ShowWuJiangZhanLiXiaoZhuan(true)
    end
end

function UIWuJiangDetailView:ResetRoleCamPos(isTween)
    if self.m_roleCam then
        self.m_roleCam.fieldOfView = self.m_roleCamOriginFOV
        self.m_roleCamTrans.localPosition = self.m_roleCamOriginPos
        self.m_roleCamTrans.localEulerAngles = self.m_roleCamOriginRot
        self.m_roleCamChg = false
        self.m_roleCamChgTime = 0

        MotionBlurEffect.StopEffect()
    end
end

function UIWuJiangDetailView:MoveCam(fov1, fov2, camRotX, camRotX2, targetPos, duration, isTween)

    if isTween == nil then
        isTween = true
    end
    
    
    local camEulerAngles = self.m_roleCamTrans.localEulerAngles

    if isTween then
        local tweener = DOTweenShortcut.DOLocalMove(self.m_roleCamTrans, targetPos, duration)

        local function setterFunc(v)
            self.m_roleCam.fieldOfView = fov1 + v * (fov2 - fov1)
            local rotX = camRotX + v * (camRotX2 - camRotX)
            self.m_roleCamTrans.localEulerAngles = Vector3.New(rotX, camEulerAngles.y, camEulerAngles.y)
        end

       --[[  local tweener = DOTween.ToFloatValue(getterFunc, setterFunc, fov2, duration)
        DOTweenSettings.OnUpdate(tweener, tweenUpdate)
 ]]

        local tweener = DOTween.To(setterFunc, 0, 1, duration)
        DOTweenSettings.OnUpdate(tweener, tweenUpdate)


        local mat = ResourcesManagerInst:LoadSync("EffectCommonMat/DynamicMaterials/SE_MotionBlur.mat", typeof(CS.UnityEngine.Material))
        MotionBlurEffect.ApplyEffect(self.m_roleCamTrans.gameObject, mat, -1, 0.8)

        CS.DOTween.DOTweenSettings.OnComplete(tweener, function()
            coroutine.start(function()
                coroutine.waitforseconds(0.2)

                MotionBlurEffect.StopEffect()
                self.m_roleCamChgTime = 0
            end)
        end)
    else
        self.m_roleCam.fieldOfView = fov
        self.m_roleCamTrans.localPosition = targetPos
    end
end

local InitScale = Vector3.one * 0.01

function UIWuJiangDetailView:DoTweenOpen(trans)
    if not IsNull(trans) then
        DOTweenShortcut.DOKill(trans)
        trans.localScale = InitScale
        local tweener = DOTweenShortcut.DOScale(trans, 1, 0.4)
        DOTweenSettings.SetEase(tweener, DoTweenEaseType.OutBack)
    end
end

function UIWuJiangDetailView:ShowSkillDetail(isShow, skillID, iconIndex, isQingYuan) 
    if isShow then 
        if isQingYuan then
            if not self.m_qingyuanView then
                self.m_qingyuanView = UIWuJiangQingYuanView.New(self.m_qingyuanPrefabTr.gameObject, nil, nil) 
                self.m_qingyuanView:SetData(self.m_curWuJiangData)
            end
        else
            if not self.m_skillDetailItem then
                self.m_skillDetailItem = UIWuJiangSkillDetailView.New(self.gameObject, "SkillDetail")
                self.m_skillDetailItem:OnCreate() 
            end
        end 
        if isQingYuan then  
            if self.m_skillDetailItem then
                self.m_skillDetailItem:SetActive(false)
            end 
            self.m_qingyuanView:SetActive(true) 
            self.m_qingyuanView:SetData(self.m_curWuJiangData)
        else
            if self.m_qingyuanView then
                self.m_qingyuanView:SetActive(false)
            end

            self:DoTweenOpen(self.m_skillDetailItem:GetContainerTran())
            self.m_skillDetailItem:SetActive(true, self.m_curWuJiangData.index, skillID)
        end
       
        self:CheckSelectSkillIcon(true, iconIndex)
        self:PlayScreenEffect()
    else 
        if self.m_skillDetailItem then
            self.m_skillDetailItem:SetActive(false)
        end
        if self.m_qingyuanView then
            self.m_qingyuanView:SetActive(false)
        end

        self:CheckSelectSkillIcon(false)
        self:StopScreenEffect()
    end
end

function UIWuJiangDetailView:OnNtfIntimacyChg()
    if self.m_qingyuanView then
        self.m_qingyuanView:UpdateData()
    end
end

function UIWuJiangDetailView:CheckSelectSkillIcon(isShow, iconIndex) 
    if self.m_skill_qingyuan_iconList then
        for i = 1, #self.m_skill_qingyuan_iconList do
            if self.m_skill_qingyuan_iconList[i] then
                local isSelect = false
                
                if isShow then
                    isSelect = iconIndex == self.m_skill_qingyuan_iconList[i].iconIndex
                end
                self.m_skill_qingyuan_iconList[i]:SetSelect(isSelect)
            end
        end
    end
end 

function UIWuJiangDetailView:ShowWuJiangZhanLiXiaoZhuan(isShow)
    UIManagerInst:OpenWindow(UIWindowNames.UIWuJiangXiaoZhuan, self.m_curWuJiangData.id,self.m_wujiangCfg.sName)
end

function UIWuJiangDetailView:GetRecoverParam()
    return self.m_wujiangIndex
end

function UIWuJiangDetailView:ChangeLock(wujiangIndex, lock)
    if wujiangIndex == self.m_curWuJiangData.index then
        UILogicUtil.SetLockImage(self.m_lockImage, lock == 1)
    end
end

function UIWuJiangDetailView:PlayScreenEffect()
    local blurMat = ResourcesManager:GetInstance():LoadSync("EffectCommonMat/DynamicMaterials/SE_GaussianBlur.mat", Type_Material)
    BgBlurEffect.ApplyEffect(blurMat, self.m_roleCam)
end

function UIWuJiangDetailView:StopScreenEffect()
    BgBlurEffect.StopBgBlurEffect()
end

function UIWuJiangDetailView:OnWindowOpen(target)
    if target.Name == UIWindowNames.UIWuJiangAttr or target.Name == UIWindowNames.UIWuJiangXiaoZhuan or target.Name == UIWindowNames.UIWuJiangRank then
        self:PlayScreenEffect()
    end
end

function UIWuJiangDetailView:OnWindowClose(target)
    if target.Name == UIWindowNames.UIWuJiangAttr or target.Name == UIWindowNames.UIWuJiangXiaoZhuan or target.Name == UIWindowNames.UIWuJiangRank then
        self:StopScreenEffect()
    end
end

return UIWuJiangDetailView