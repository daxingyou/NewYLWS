
local UIUtil = UIUtil
local ConfigUtil = ConfigUtil
local string_format = string.format
local Language = Language
local CommonDefine = CommonDefine
local AtlasConfig = AtlasConfig
local ImageConfig = ImageConfig
local GuildMgr = Player:GetInstance().GuildMgr
local UserMgr = Player:GetInstance():GetUserMgr()

local GuildSkillItem = BaseClass("GuildSkillItem", UIBaseItem)
local base = UIBaseItem

function GuildSkillItem:OnCreate()
    base.OnCreate(self)
    
    local activeBtnText, studyBtnText
    self.m_skillNameText, self.m_guildLevelText, self.m_totalDonationText,
    self.m_skillDescText, activeBtnText, studyBtnText, self.m_skillInfoText
    = UIUtil.GetChildTexts(self.transform, {
        "itemBg/skillName",
        "itemBg/guildLevelText",
        "itemBg/totalDonationText",
        "itemBg/skillDescText",
        "ActiveButton/Text",
        "StudyButton/Text",
        "InfoText"
    })

    self.m_activeBtn, self.m_studyBtn, self.m_maskGo, self.m_newGo
    = UIUtil.GetChildTransforms(self.transform, {
        "ActiveButton",
        "StudyButton",
        "itemBg/mask",
        "itemBg/new"
    })

    activeBtnText.text = Language.GetString(1426)
    studyBtnText.text = Language.GetString(1427)
    self.m_maskGo = self.m_maskGo.gameObject
    self.m_newGo = self.m_newGo.gameObject
    self.m_skillData = nil

    self.m_itemBgImg = UIUtil.AddComponent(UIImage, self, "itemBg", AtlasConfig.DynamicLoad)
    self.m_skillImg = UIUtil.AddComponent(UIImage, self, "itemBg/skillBg/skillImg", ImageConfig.SkillIcon)

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_activeBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_studyBtn.gameObject, onClick)
end

function GuildSkillItem:OnClick(go)
    if go.name == "ActiveButton" then
        UIManagerInst:OpenWindow(UIWindowNames.UIGuildSkillActive, self.m_skillData, Bind(self, self.ActiveSkillCallBack))
    elseif go.name == "StudyButton" then
        if self.m_skillData then
            GuildMgr:ReqLearnSkill(self.m_skillData.id)
        end
    end
end

function GuildSkillItem:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_activeBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_studyBtn.gameObject)

    base.OnDestroy(self)
end

function GuildSkillItem:ActiveSkillCallBack()
    GuildMgr:ReqUnlockSkill(self.m_skillData.id)
end

function GuildSkillItem:UpdateData(cfgData, skillDataList)
    local userData = UserMgr:GetUserData()
    local skillData
    for i, v in pairs(skillDataList) do
        if v.skill_id == cfgData.id then
            skillData = v
            break
        end
    end
    if cfgData then
        self.m_skillData = cfgData
        self.m_skillNameText.text = cfgData.name
        self.m_guildLevelText.text = string_format(Language.GetString(1424), cfgData.unlock_guild_level)
        self.m_totalDonationText.text = string_format(Language.GetString(1425), cfgData.need_huoyue)
        self.m_skillDescText.text = cfgData.desc
        self.m_skillImg:SetAtlasSprite(cfgData.img_name)

        if skillData then
            if skillData.is_new == 1 then
                self.m_newGo:SetActive(true)
                self.m_itemBgImg:SetAtlasSprite("jt18.png")
            else
                self.m_newGo:SetActive(false)
                self.m_itemBgImg:SetAtlasSprite("jt01.png")
            end
        else
            self.m_newGo:SetActive(false)
            self.m_itemBgImg:SetAtlasSprite("jt01.png")
        end
        if userData.guild_level >= cfgData.unlock_guild_level then
            self.m_maskGo:SetActive(false)
            if userData.guild_job == CommonDefine.GUILD_POST_COLONEL or userData.guild_job == CommonDefine.GUILD_POST_DEPUTY then
                if skillData then
                    if skillData.is_unlocked == 1 then
                        if skillData.is_learned == 1 then
                            self.m_skillInfoText.text = Language.GetString(1428)
                            self.m_skillInfoText.gameObject:SetActive(true)
                            self.m_studyBtn.gameObject:SetActive(false)
                            self.m_activeBtn.gameObject:SetActive(false)
                            self.m_itemBgImg:SetAtlasSprite("jt19.png")
                        else
                            self.m_skillInfoText.gameObject:SetActive(false)
                            self.m_studyBtn.gameObject:SetActive(true)
                            self.m_activeBtn.gameObject:SetActive(false)
                            self.m_itemBgImg:SetAtlasSprite("jt01.png")
                        end
                    else
                        self.m_skillInfoText.gameObject:SetActive(false)
                        self.m_studyBtn.gameObject:SetActive(false)
                        self.m_activeBtn.gameObject:SetActive(true)
                    end
                else
                    self.m_skillInfoText.gameObject:SetActive(false)
                    self.m_studyBtn.gameObject:SetActive(false)
                    self.m_activeBtn.gameObject:SetActive(true)
                end
            else
                if skillData then
                    if skillData.is_unlocked == 1 then
                        if skillData.is_learned == 1 then
                            self.m_skillInfoText.text = Language.GetString(1428)
                            self.m_skillInfoText.gameObject:SetActive(true)
                            self.m_studyBtn.gameObject:SetActive(false)
                            self.m_activeBtn.gameObject:SetActive(false)
                            self.m_itemBgImg:SetAtlasSprite("jt19.png")
                        else
                            self.m_skillInfoText.gameObject:SetActive(false)
                            self.m_studyBtn.gameObject:SetActive(true)
                            self.m_activeBtn.gameObject:SetActive(false)
                            self.m_itemBgImg:SetAtlasSprite("jt01.png")
                        end
                    else
                        self.m_skillInfoText.text = Language.GetString(1429)
                        self.m_skillInfoText.gameObject:SetActive(true)
                        self.m_studyBtn.gameObject:SetActive(false)
                        self.m_activeBtn.gameObject:SetActive(false)
                        self.m_maskGo:SetActive(true)
                    end
                else
                    self.m_skillInfoText.text = Language.GetString(1429)
                    self.m_skillInfoText.gameObject:SetActive(true)
                    self.m_studyBtn.gameObject:SetActive(false)
                    self.m_activeBtn.gameObject:SetActive(false)
                    self.m_maskGo:SetActive(true)
                end
            end
        else
            self.m_skillInfoText.text = Language.GetString(1429)
            self.m_skillInfoText.gameObject:SetActive(true)
            self.m_studyBtn.gameObject:SetActive(false)
            self.m_activeBtn.gameObject:SetActive(false)
            self.m_maskGo:SetActive(true)
        end
    end

end

return GuildSkillItem