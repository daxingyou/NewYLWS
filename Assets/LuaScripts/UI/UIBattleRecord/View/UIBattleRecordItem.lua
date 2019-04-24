local UIUtil = UIUtil
local UIBattleRecordItem = BaseClass("UIBattleRecordItem", UIBaseItem)
local base = UIBaseItem
local UILogicUtil = UILogicUtil
local string_format = string.format
local ConfigUtil = ConfigUtil

local UISliderHelper = typeof(CS.UISliderHelper)
local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)

function UIBattleRecordItem:Delete()
    self.m_go = false
    self.m_transform = false

    if self.m_hurtSlider then
        self.m_hurtSlider:Delete()
        self.m_hurtSlider = nil
    end

    if self.m_behurtSlider then
        self.m_behurtSlider:Delete()
        self.m_behurtSlider = nil
    end

    if self.m_recoverSlider then
        self.m_recoverSlider:Delete()
        self.m_recoverSlider = nil
    end

    if self.self.m_levelText then
        self.self.m_levelText:Delete()
        self.self.m_levelText = nil
    end

    if self.m_killCountText then
        self.m_killCountText:Delete()
        self.m_killCountText = nil
    end

    if self.m_hurtText then
        self.m_hurtText:Delete()
        self.m_hurtText = nil
    end

    if self.m_behurtText then
        self.m_behurtText:Delete()
        self.m_behurtText = nil
    end

    if self.m_recoverText then
        self.m_recoverText:Delete()
        self.m_recoverText = nil
    end

    if self.m_wujiangImage then
        self.m_wujiangImage:Delete()
        self.m_wujiangImage = nil
    end

    if self.m_frameImage then
        self.m_frameImage:Delete()
        self.m_frameImage = nil
    end

    if self.m_countryImage then
        self.m_countryImage:Delete()
        self.m_countryImage = nil
    end
    self.m_wujiangID = 0
end

function UIBattleRecordItem:OnCreate()
	base.OnCreate(self)

    self:InitView()
    self.m_actorID = 0
    self.m_wujiangID = 0
end

function UIBattleRecordItem:InitView()
    self.m_hurtSlider = UIUtil.FindComponent(self.transform, UISliderHelper, "rightContainer/hurtSlider")
    self.m_behurtSlider = UIUtil.FindComponent(self.transform, UISliderHelper, "rightContainer/behurtSlider")
    self.m_recoverSlider = UIUtil.FindComponent(self.transform, UISliderHelper, "rightContainer/recoverSlider")
    self.m_levelRoot = UIUtil.FindComponent(self.transform, Type_RectTransform, "leftIcon/Other/Level").gameObject

    self.m_levelText, self.m_killCountText, self.m_hurtText, self.m_behurtText, self.m_recoverText = UIUtil.GetChildTexts(self.transform, {
        "leftIcon/Other/Level/LevelText", "rightContainer/killCountText", "rightContainer/hurtSlider/hurtText", "rightContainer/behurtSlider/hurtText", "rightContainer/recoverSlider/hurtText"
    })

    self.m_wujiangImage = UIUtil.AddComponent(UIImage, self, "leftIcon/icon", AtlasConfig.RoleIcon)
    self.m_frameImage = UIUtil.AddComponent(UIImage, self, "leftIcon/frame", AtlasConfig.DynamicLoad)
    self.m_countryImage = UIUtil.AddComponent(UIImage, self, "leftIcon/Other/CountryImage", AtlasConfig.DynamicLoad)
end


function UIBattleRecordItem:UpdateData(hurt, dropHp, recoverHp, killCount, isBoss, actorID, wujiangID, wujiangLevel, maxDamagedata)
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(wujiangID)
    if wujiangCfg then
       -- local wujiangImage = string_format("%.d.jpg", wujiangID)
        self.m_wujiangImage:SetAtlasSprite(wujiangCfg.sIcon)
        UILogicUtil.SetWuJiangFrame(self.m_frameImage, wujiangCfg.rare)
        UILogicUtil.SetWuJiangCountryImage(self.m_countryImage, wujiangCfg.country)
    end
    local isDragon = Utils.IsDragon(wujiangID)
    self.m_countryImage.gameObject:SetActive(not isDragon)
    self.m_levelRoot:SetActive(not isDragon)

    self.m_actorID = actorID
    self.m_wujiangID = wujiangID
    self.m_levelText.text = string_format("%.d", wujiangLevel)

    if hurt ~= 0 then
        self.m_hurtText.text = string_format("%.d", hurt)
    else
        self.m_hurtText.text = "0"
    end

    if dropHp ~= 0 then
        self.m_behurtText.text = string_format("%.d", dropHp)
    else
        self.m_behurtText.text = "0"
    end

    if recoverHp ~= 0 then
        self.m_recoverText.text = string_format("%.d", recoverHp)
    else
        self.m_recoverText.text = "0"
    end

    if killCount > 0 then
        self.m_killCountText.text = string_format(Language.GetString(2473), killCount)
    else
        self.m_killCountText.text = ""
    end

    local maxDropHp = maxDamagedata:GetDropHP()
    local maxRecoverHp = maxDamagedata:GetAddHP()
    local maxValue = maxDamagedata:GetHurt()
    if maxValue < maxDropHp then
        maxValue = maxDropHp
    end
    if maxValue < maxRecoverHp then
        maxValue = maxRecoverHp
    end

    self.m_hurtSlider:UpdateSliderImmediately(hurt / maxValue)
    self.m_behurtSlider:UpdateSliderImmediately(dropHp / maxValue)
    self.m_recoverSlider:UpdateSliderImmediately(recoverHp / maxValue)
end

function UIBattleRecordItem:GetActorID()
    return self.m_actorID
end

function UIBattleRecordItem:SetSiblingIndex(index)
    self.transform:SetSiblingIndex(index)
end

function UIBattleRecordItem:GetWujiangID()
    return self.m_wujiangID
end

return UIBattleRecordItem

