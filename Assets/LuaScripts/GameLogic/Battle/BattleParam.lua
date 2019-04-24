local table_insert = table.insert
local math_ceil = math.ceil
local Utils = Utils

OneBattleWujiang = BaseClass("OneBattleWujiang")
function OneBattleWujiang:__init()
    self.wujiangSEQ = 0
    self.wujiangID = 0
    self.fromUID = 0
    self.level = 0
    self.star = 1
    self.wuqiLevel = 1
    self.lineUpPos = 0
    self.mountID = 0
    self.mountLevel = 0
    self.bossType = 0
    self.backSkillID = 0
    self.hp = 0
    self.max_hp = 0
    self.phy_atk = 0
    self.phy_def = 0
    self.magic_atk = 0
    self.magic_def = 0
    self.phy_baoji = 0
    self.magic_baoji = 0
    self.shanbi = 0
    self.mingzhong = 0
    self.move_speed = 0
    self.atk_speed = 0
    self.hp_recover = 0
    self.nuqi_recover = 0
    self.init_nuqi = 0
    self.baoji_hurt = 1
    self.phy_suckblood = 0
    self.magic_suckblood = 0
    self.reduce_cd = 0
    self.phy_baoji_rate = 0
	self.magic_baoji_rate = 0
	self.shanbi_rate = 0
	self.mingzhong_rate = 0
    self.skillList = {}  -- { {id,lvl} }
    self.inscriptionSkillList = {}  -- { {id,lvl} }
    self.horseSkillList = {}  -- { {id,lvl} }
end

OneBattleDragon = BaseClass("OneBattleDragon")
function OneBattleDragon:__init()
    self.dragonID = 0
    self.dragonLevel = 0
    self.talentList = {}     -- { talentID , talentLevel }[]
end

OneBattleCamp = BaseClass("OneBattleCamp")
function OneBattleCamp:__init()
    self.uid = 0
    self.name = ""
    self.icon = 0
    self.vip_level = 0
    self.level = 0
    self.wujiangList = {}
    self.user_icon = nil
    self.benchWujiangList = {}
    self.oneDragon = nil
end

BattleParam = BaseClass("BattleParam")
function BattleParam:__init()
    self.leftCamp = OneBattleCamp.New()
end

function BattleParam:AddLeftWujiang(one_battle_wujiang)
    table_insert(self.leftCamp.wujiangList, one_battle_wujiang)
end

function BattleParam:AddLeftBenchWujiang(one_battle_wujiang)
    table_insert(self.leftCamp.benchWujiangList, one_battle_wujiang)
end

--------------------------------------------------------------------
EnterCopyParam = BaseClass("EnterCopyParam", BattleParam)
function EnterCopyParam:__init()
    -- todo  drop list
    self.copyID = 0
    self.autoFight = false
    self.param1 = false
end

--------------------------------------------------------------------
EnterArenaParam = BaseClass("EnterArenaParam", BattleParam)
function EnterArenaParam:__init()
    self.rightCampList = {}
end

function EnterArenaParam:AddRightWujiang(rightCamp, one_battle_wujiang)
    table_insert(rightCamp.wujiangList, one_battle_wujiang)
end

--------------------------------------------------------------------
EnterFriendChallengeParam = BaseClass("EnterFriendChallengeParam", BattleParam)
function EnterFriendChallengeParam:__init()
    self.rightCampList = {}
end

function EnterFriendChallengeParam:AddRightWujiang(rightCamp, one_battle_wujiang)
    table_insert(rightCamp.wujiangList, one_battle_wujiang)
end

--------------------------------------------------------------------
EnterBossParam = BaseClass("EnterBossParam", BattleParam)
function EnterBossParam:__init()
    self.bossLevel = 0
    self.autoFight = false
end

--------------------------------------------------------------------
EnterShenShouParam = BaseClass("EnterShenShouParam", BattleParam)
function EnterShenShouParam:__init()
    self.copyID = 0
    self.challengeCount = 0
    self.bossLevel = 0
end

--------------------------------------------------------------------
EnterLieZhuanParam = BaseClass("EnterLieZhuanParam", BattleParam)
function EnterLieZhuanParam:__init()
    self.copyID = 0
end

--------------------------------------------------------------------
EnterLieZhuanTeamParam = BaseClass("EnterLieZhuanTeamParam", BattleParam)
function EnterLieZhuanTeamParam:__init()
    self.copyID = 0
end

--------------------------------------------------------------------
EnterHorseRaceTeamParam = BaseClass("EnterHorseRaceTeamParam", BattleParam)
function EnterHorseRaceTeamParam:__init()
    self.selfUid = 0
    self.rightCampList = {}
    self.horseRacingMapList = {}
end

function EnterHorseRaceTeamParam:AddRightWujiang(rightCamp, one_battle_wujiang)
    table_insert(rightCamp.wujiangList, one_battle_wujiang)
end

--------------------------------------------------------------------
EnterGuildBossParam = BaseClass("EnterGuildBossParam", BattleParam)
function EnterGuildBossParam:__init()
    self.bossLevel = 0
    self.bossIndex = 0
    self.bossCurrHp = 0
    self.bossMaxHp = 0
    self.rightCampInfo = {}
    self.bossInfo = {}
    self.autoFight = false
    self.copyID = 0
end

function EnterGuildBossParam:AddBoss(boss)
    table_insert(self.bossInfo, boss)
end

function EnterGuildBossParam:AddRightWujiang(rightCamp, one_battle_wujiang)
    table_insert(rightCamp.wujiangList, one_battle_wujiang)
end

--------------------------------------------------------------------
EnterYuanmenParam = BaseClass("EnterYuanmenParam", BattleParam)
function EnterYuanmenParam:__init()
    self.yuanmenID = 0
    self.leftBuffList = {}
    self.rightBuffList = {}
    self.monsterList = {}   -- {monsterID={hp=,nuqi=}, }
    self.monsterLevel = 0
    self.score = 0
end

function EnterYuanmenParam:AddBuff(side, buffID)
    if side == 1 then
        table_insert(self.leftBuffList, buffID)
    else
        table_insert(self.rightBuffList, buffID)
    end
end

function EnterYuanmenParam:AddMonster(monsterID, hp, nuqi)
    self.monsterList[monsterID] = {hp = hp, nuqi = nuqi}
end

--------------------------------------------------------------------
EnterShenbingParam = BaseClass("EnterShenbingParam", BattleParam)
function EnterShenbingParam:__init()
    self.copyID = 0
    self.random_award_list = {}
    self.seq_random_list = {}
end
function EnterShenbingParam:AddAward(v)
    local pShenbing = v.shenbing_award

    local award = {
        award_type = v.award_type,
        award_index = v.award_index,
        award_id = v.award_id,
        award_count = v.award_count,
        award_owner_wj = v.award_owner_wj,
        shenbing_award = {
            stage = v.shenbing_award.stage,
            second_attr = {
                max_hp      = pShenbing.attr_list.max_hp or 0,
                phy_atk     = pShenbing.attr_list.phy_atk or 0,
                magic_atk   = pShenbing.attr_list.magic_atk or 0,
                phy_def     = pShenbing.attr_list.phy_def or 0,
                magic_def   = pShenbing.attr_list.magic_def or 0,
                phy_baoji   = pShenbing.attr_list.phy_baoji or 0,
                magic_baoji = pShenbing.attr_list.magic_baoji or 0,
                mingzhong   = pShenbing.attr_list.mingzhong or 0,
                shanbi      = pShenbing.attr_list.shanbi or 0,
            },
            mingwen_list = {},
        }
    }
    for _, mw in Utils.IterPbRepeated(pShenbing.mingwen_list) do
        table_insert(award.shenbing_award.mingwen_list, mw.mingwen_id)
    end

    table_insert(self.random_award_list, award)
end

--------------------------------------------------------------------
EnterGuildWarParam = BaseClass("EnterGuildWarParam", BattleParam)
function EnterGuildWarParam:__init()
    self.rightCampList = {}
end

function EnterGuildWarParam:AddRightWujiang(rightCamp, one_battle_wujiang)
    table_insert(rightCamp.wujiangList, one_battle_wujiang)
end
--------------------------------------------------------------------

BattleProtoConvert = {
    ConvertDragonProto = function(one_battle_dragon)
        if one_battle_dragon.dragon_id > 0 then
            local dragonParam = OneBattleDragon.New()
            dragonParam.dragonID = one_battle_dragon.dragon_id
            dragonParam.dragonLevel = one_battle_dragon.dragon_level

            local talent_list = one_battle_dragon.talent_list
            for _, one_talent in Utils.IterPbRepeated(talent_list) do
                local o = {
                    talentID = one_talent.talent_id,
                    talentLevel = one_talent.talent_level,
                }
                table_insert(dragonParam.talentList, o)
            end
            return dragonParam
        end
        return nil
    end,

    -- 客户端本地测试用
    ConvertCopyProtoForTest = function(proto)
        local enterParam = EnterCopyParam.New()
        enterParam.copyID = proto.copyID

        local pb_wujiang_list = proto.wujiang_info_list
        for _, pb_wujiang in Utils.IterPbRepeated(pb_wujiang_list) do
            local oneWujiang = BattleProtoConvert.ConvertPbOneWujiang(pb_wujiang)
            enterParam:AddLeftWujiang(oneWujiang)
        end
        return enterParam
    end,

    ConvertCopyProto = function(copy_id, leftFormation, rightFormation, autoFight)
        local copyParam = EnterCopyParam.New()
        copyParam.copyID = copy_id
        copyParam.autoFight = autoFight == 1 and true or false
        BattleProtoConvert.ConvertProtoToLeftCamp(copyParam, leftFormation)
        return copyParam
    end,

    ConvertGraveProto = function(copy_id, leftFormation, autoFight, isFirstIn)
        local copyParam = EnterCopyParam.New()
        copyParam.copyID = copy_id
        copyParam.autoFight = autoFight == 1 and true or false
        BattleProtoConvert.ConvertProtoToLeftCamp(copyParam, leftFormation)
        copyParam.param1 = isFirstIn
        return copyParam
    end,

    ConvertShenbingProto = function(copy_id, leftFormation, random_award_list, seq_random_list)
        local shenbingParam = EnterShenbingParam.New()
        shenbingParam.copyID = copy_id
        for _, v in Utils.IterPbRepeated(random_award_list) do
            shenbingParam:AddAward(v)
        end
        for _, v in Utils.IterPbRepeated(seq_random_list) do
            table_insert(shenbingParam.seq_random_list, v)
        end
        BattleProtoConvert.ConvertProtoToLeftCamp(shenbingParam, leftFormation)
        return shenbingParam
    end,

    ConvertShenShouProto = function(copyID, leftFormation, challengeCount, bossLevel)
        local shenshouParam = EnterShenShouParam.New()
        shenshouParam.copyID = copyID
        shenshouParam.challengeCount = challengeCount
        shenshouParam.bossLevel = bossLevel
        BattleProtoConvert.ConvertProtoToLeftCamp(shenshouParam, leftFormation)
        return shenshouParam
    end,

    ConvertArenaProto = function(leftFormation, rightFormationList, battleResultData, resultInfo)
        local arenaParam = EnterArenaParam.New()
        BattleProtoConvert.ConvertProtoToLeftCamp(arenaParam, leftFormation)
        BattleProtoConvert.ConvertProtoToRightCamp(arenaParam, rightFormationList)
        arenaParam.battleResultData = battleResultData
        arenaParam.resultInfo = resultInfo
        return arenaParam
    end,

    ConvertGroupHerosWarProto = function(leftFormation, rightFormationList, battleResultData, resultInfo)
        local arenaParam = EnterArenaParam.New()
        BattleProtoConvert.ConvertProtoToLeftCamp(arenaParam, leftFormation)
        BattleProtoConvert.ConvertProtoToRightCamp(arenaParam, rightFormationList)
        arenaParam.battleResultData = battleResultData
        arenaParam.resultInfo = resultInfo
        return arenaParam
    end,

    ConvertFriendChallengeProto = function(leftFormation, rightFormationList)
        local friendChallengeParam = EnterFriendChallengeParam.New()
        BattleProtoConvert.ConvertProtoToLeftCamp(friendChallengeParam, leftFormation)
        BattleProtoConvert.ConvertProtoToRightCamp(friendChallengeParam, rightFormationList)
        return friendChallengeParam
    end,

    ConvertYuanmenProto = function(yuanmenID, monsterLevel, score, leftFormation, yuanmen_battle)
        local yuanmenParam = EnterYuanmenParam.New()
        yuanmenParam.yuanmenID = yuanmenID
        BattleProtoConvert.ConvertProtoToLeftCamp(yuanmenParam, leftFormation)

        local l_b_l = yuanmen_battle.left_buff_list
        for _, v in Utils.IterPbRepeated(l_b_l) do
            yuanmenParam:AddBuff(1, v)
        end
        local r_b_l = yuanmen_battle.right_buff_list
        for _, v in Utils.IterPbRepeated(r_b_l) do
            yuanmenParam:AddBuff(2, v)
        end

        local m_b_l = yuanmen_battle.monster_base_info
        for _, v in Utils.IterPbRepeated(m_b_l) do
            yuanmenParam:AddMonster(v.monster_id, v.hp, v.nuqi)
        end

        yuanmenParam.monsterLevel = monsterLevel
        yuanmenParam.score = score
        
        return yuanmenParam
    end,

    ConvertBossProto = function(bossLevel, leftFormation, rightFormation, autoFight)
        local bossParam = EnterBossParam.New()
        bossParam.bossLevel = bossLevel
        bossParam.autoFight = autoFight == 1 and true or false
        BattleProtoConvert.ConvertProtoToLeftCamp(bossParam, leftFormation)
        return bossParam
    end,

    ConvertGuildBossProto = function(bossIndex, bossLevel, bossCurrHp, bossMaxHp, copy_id, leftFormation, rightFormation, autoFight)
        local guildBossParam = EnterGuildBossParam.New()
        guildBossParam.copyID = copy_id
        guildBossParam.autoFight = autoFight == 1 and true or false
        guildBossParam.bossIndex = bossIndex
        guildBossParam.bossLevel = bossLevel
        guildBossParam.bossCurrHp = bossCurrHp
        guildBossParam.bossMaxHp = bossMaxHp
        guildBossParam.rightCampInfo = rightFormation
        BattleProtoConvert.ConvertProtoToLeftCamp(guildBossParam, leftFormation)
        BattleProtoConvert.ConvertProtoToBoss(guildBossParam, rightFormation)
        
        return guildBossParam
    end,

    ConvertProtoToBoss = function (param, formation)
        local boss = Utils.GetPbRepeated(formation, 1).wujiang_info_list
        for _, pb_wujiang in Utils.IterPbRepeated(boss) do
            local oneWujiang = BattleProtoConvert.ConvertPbOneWujiang(pb_wujiang)
            param:AddBoss(oneWujiang)
        end
    end,

    ConvertGuildWarProto = function(leftFormation, rightFormationList, rival_guild_brief, rival_info, offence_left_time, rival_guild_left_member_num, copyID)
        local guildWarParam = EnterGuildWarParam.New()
        BattleProtoConvert.ConvertProtoToLeftCamp(guildWarParam, leftFormation)
        BattleProtoConvert.ConvertProtoToRightCamp(guildWarParam, rightFormationList)

        local rivalGuildBriefData = rival_guild_brief and {} or false
        if rival_guild_brief then
            rivalGuildBriefData.gid = rival_guild_brief.gid	--军团ID
            rivalGuildBriefData.name = rival_guild_brief.name
            rivalGuildBriefData.icon = rival_guild_brief.icon --旗帜
            rivalGuildBriefData.level = rival_guild_brief.level
            rivalGuildBriefData.doyen_name = rival_guild_brief.doyen_name --军团长姓名
            rivalGuildBriefData.doyen = rival_guild_brief.doyen  --军团长uid
            rivalGuildBriefData.dist_id = rival_guild_brief.dist_id  --服ID
            rivalGuildBriefData.warcraftscore = rival_guild_brief.warcraftscore  --分数
        end
        
        local rivalUserBriefData = rival_info and {} or false
        if rival_info then
            rivalUserBriefData.uid = rival_info.uid
            rivalUserBriefData.user_name = rival_info.user_name --玩家名字
            rivalUserBriefData.level = rival_info.level
            rivalUserBriefData.level = rival_info.level
            rivalUserBriefData.dist_id = rival_info.dist_id
            rivalUserBriefData.guild_name = rival_info.guild_name
            rivalUserBriefData.user_title = rival_info.user_title --称号
            rivalUserBriefData.post = rival_info.post 
            rivalUserBriefData.post_name = rival_info.post_name
        end

        guildWarParam.rivalInfo = {
            rival_guild_left_member_num = rival_guild_left_member_num,
            rivalGuildBriefData = rivalGuildBriefData,
            rivalUserBriefData = rivalUserBriefData
        }
        guildWarParam.offence_left_time = offence_left_time
        guildWarParam.copyID = copyID
        return guildWarParam
    end,

    ConvertGuildWarRobProto = function(leftFormation, rightFormationList)
        local robParam = EnterGuildWarParam.New()
        BattleProtoConvert.ConvertProtoToLeftCamp(robParam, leftFormation)
        BattleProtoConvert.ConvertProtoToRightCamp(robParam, rightFormationList)

        return robParam
    end,

    ConvertLieZhuanProto = function(copy_id, leftFormation, rightFormation)
        local lieZhuanParam = EnterLieZhuanParam.New()
        lieZhuanParam.copyID = copy_id
        BattleProtoConvert.ConvertProtoToLeftCamp(lieZhuanParam, leftFormation)
        return lieZhuanParam
    end,

    ConvertLieZhuanTeamProto = function(copy_id, leftFormation, battleResultData)
        local lieZhuanTeamParam = EnterLieZhuanTeamParam.New()
        lieZhuanTeamParam.copyID = copy_id
        lieZhuanTeamParam.battleResultData = battleResultData
        BattleProtoConvert.ConvertProtoToLeftCamp(lieZhuanTeamParam, leftFormation)
        return lieZhuanTeamParam
    end,

    ConvertHorseRaceProto = function(leftFormation, rightFormationList, battleResultData, racingBattleMapList, selfUid)
        local horseRaceParam = EnterHorseRaceTeamParam.New()
        horseRaceParam.battleResultData = battleResultData
        horseRaceParam.selfUid = selfUid
        BattleProtoConvert.ConvertProtoToLeftCamp(horseRaceParam, leftFormation)
        BattleProtoConvert.ConvertProtoToRightCamp(horseRaceParam, rightFormationList)
        BattleProtoConvert.ConvertProtoToHorseRaceMap(horseRaceParam, racingBattleMapList)
        return horseRaceParam
    end,

    ConvertProtoToHorseRaceMap = function (param, racingBattleMapList)
        for _, map in Utils.IterPbRepeated(racingBattleMapList) do
            table_insert(param.horseRacingMapList, map)
        end
    end,

    ConvertProtoToLeftCamp = function (param, leftFormation)
        param.leftCamp.uid = leftFormation.uid
        param.leftCamp.name = leftFormation.name
        param.leftCamp.vip_level = leftFormation.vip_level
        param.leftCamp.level = leftFormation.level
        param.leftCamp.user_icon = leftFormation.user_icon
        local pb_left_wujiang_list = leftFormation.wujiang_info_list
        for _, pb_wujiang in Utils.IterPbRepeated(pb_left_wujiang_list) do
            local oneWujiang = BattleProtoConvert.ConvertPbOneWujiang(pb_wujiang)
            param:AddLeftWujiang(oneWujiang)
        end

        local pb_backupwujiang_info_list = leftFormation.backupwujiang_info_list
        for _, pb_wujiang in Utils.IterPbRepeated(pb_backupwujiang_info_list) do
            local oneWujiang = BattleProtoConvert.ConvertPbOneWujiang(pb_wujiang)
            param:AddLeftBenchWujiang(oneWujiang)
        end

        param.leftCamp.oneDragon = BattleProtoConvert.ConvertDragonProto(leftFormation.dragon_info)
    end,

    ConvertProtoToRightCamp = function (param, rightFormationList)
        for _, rightFormation in Utils.IterPbRepeated(rightFormationList) do
            local rightCamp = OneBattleCamp.New()
            rightCamp.uid = rightFormation.uid
            rightCamp.name = rightFormation.name
            rightCamp.vip_level = rightFormation.vip_level
            rightCamp.level = rightFormation.level
            rightCamp.user_icon = rightFormation.user_icon
            local pb_right_wujiang_list = rightFormation.wujiang_info_list
            for _, pb_wujiang in Utils.IterPbRepeated(pb_right_wujiang_list) do
                local oneWujiang = BattleProtoConvert.ConvertPbOneWujiang(pb_wujiang)
                param:AddRightWujiang(rightCamp, oneWujiang)
            end
            rightCamp.oneDragon = BattleProtoConvert.ConvertDragonProto(rightFormation.dragon_info)

            table_insert(param.rightCampList, rightCamp)
        end
    end,

    ConvertPbOneWujiang = function(pb_one_wujiang)
        local oneWujiang = OneBattleWujiang.New()
        oneWujiang.wujiangSEQ = pb_one_wujiang.seq
        oneWujiang.wujiangID = math_ceil(pb_one_wujiang.wujiang_id)
        oneWujiang.fromUID = pb_one_wujiang.uid or 0
        oneWujiang.level = pb_one_wujiang.level or 1
        oneWujiang.star = pb_one_wujiang.star or 1
        oneWujiang.wuqiLevel = pb_one_wujiang.wuqiLevel or 1
        oneWujiang.lineUpPos = pb_one_wujiang.lineUpPos or 1
        oneWujiang.mountID = pb_one_wujiang.mountID or 0
        oneWujiang.mountLevel = pb_one_wujiang.mountLevel or 0
        oneWujiang.hp = pb_one_wujiang.hp or 0
        oneWujiang.max_hp = pb_one_wujiang.max_hp or 0
        oneWujiang.phy_atk = pb_one_wujiang.phy_atk or 0
        oneWujiang.phy_def = pb_one_wujiang.phy_def or 0
        oneWujiang.magic_atk = pb_one_wujiang.magic_atk or 0
        oneWujiang.magic_def = pb_one_wujiang.magic_def or 0
        oneWujiang.phy_baoji = pb_one_wujiang.phy_baoji or 0
        oneWujiang.magic_baoji = pb_one_wujiang.magic_baoji or 0
        oneWujiang.shanbi = pb_one_wujiang.shanbi or 0
        oneWujiang.mingzhong = pb_one_wujiang.mingzhong or 0
        oneWujiang.move_speed = pb_one_wujiang.move_speed or 600
        oneWujiang.atk_speed = pb_one_wujiang.atk_speed or 100
        oneWujiang.hp_recover = pb_one_wujiang.hp_recover or 0
        oneWujiang.nuqi_recover = pb_one_wujiang.nuqi_recover or 0
        oneWujiang.init_nuqi = pb_one_wujiang.init_nuqi or 0
        oneWujiang.baoji_hurt = pb_one_wujiang.baoji_hurt
        oneWujiang.phy_suckblood = pb_one_wujiang.phy_suckblood
        oneWujiang.magic_suckblood = pb_one_wujiang.magic_suckblood
        oneWujiang.reduce_cd = pb_one_wujiang.reduce_cd or 0
        oneWujiang.phy_baoji_rate = pb_one_wujiang.phy_baoji_rate or 0
        oneWujiang.magic_baoji_rate = pb_one_wujiang.magic_baoji_rate or 0
        oneWujiang.shanbi_rate = pb_one_wujiang.shanbi_rate or 0
        oneWujiang.mingzhong_rate = pb_one_wujiang.mingzhong_rate or 0

        local pb_skill_list = pb_one_wujiang.skill_list
        for _, pb_skill in Utils.IterPbRepeated(pb_skill_list) do
            table_insert(oneWujiang.skillList, 
                {skill_id = pb_skill.skill_id, skill_level = pb_skill.skill_level})
        end

        local pb_inscriptions_skill_list = pb_one_wujiang.inscriptions_skill_list
        if pb_inscriptions_skill_list then
            for _, pb_inscription_skill in Utils.IterPbRepeated(pb_inscriptions_skill_list) do
                table_insert(oneWujiang.inscriptionSkillList, 
                    {skill_id = pb_inscription_skill.skill_id, skill_level = pb_inscription_skill.skill_level})
            end
        end

        local pb_horse_skill = pb_one_wujiang.horse_skill
        if pb_horse_skill then
            table_insert(oneWujiang.horseSkillList, {skill_id = pb_horse_skill.skill_id, skill_level = pb_horse_skill.skill_level})
        end
        
        return oneWujiang
    end,
}

