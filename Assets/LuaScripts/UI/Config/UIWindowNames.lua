--[[
-- added by wsh @ 2017-11-30
-- UI窗口名字定义，手动添加
--]]

local UIWindowNames = {
	-- 登陆模块
	UILogin = "UILogin",
	UIServerList = "UIServerList",
	UIPlatLogin = "UIPlatLogin",
	UIUpdateNotice = "UIUpdateNotice",
	-- 场景加载模块
	UILoading = "UILoading",
	UIDownloadTips = "UIDownloadTips",
	-- Tip窗口
	UINoticeTip = "UINoticeTip",
	UIIconTips = "UIIconTips",
	UIPreviewShow = "UIPreviewShow",
	UITips = "UITips",
	UIQuestionsMarkTips = "UIQuestionsMarkTips",
	UIServerNotice = "UIServerNotice",

	--Common
	UIAwardDetail = "UIAwardDetail",
	UIGetWuJiang = "UIGetWuJiang",

	UIMain = "UIMain",
	UIVip = "UIVip",
	UIVipShop = "UIVipShop",
	UIVipBuyDialog = "UIVipBuyDialog",
	UIInviteTips = "UIInviteTips",
	UIAwardTips = "UIAwardTips",
	
	-- BattleMain
	UIBattleMain = "UIBattleMain",
	UIPlotBattleMain = "UIPlotBattleMain",
	UIBattleFloat = "UIBattleFloat",
	UIBattleBloodBar = "UIBattleBloodBar",
	UIGMView = "UIGMView",
	UIBattleContinueGuide = "UIBattleContinueGuide",
	UIBattleInscriptionMain = "UIBattleInscriptionMain",
	UIBattleShenbingMain = "UIBattleShenbingMain",
	UIBattleYuanmenMain = "UIBattleYuanmenMain",
	UIBattleLieZhuanMain = "UIBattleLieZhuanMain",
	UIBattleHorseRaceMain = "UIBattleHorseRaceMain",
	UIBattleHorseRaceSettlement = "UIBattleHorseRaceSettlement",
	
	-- plot
	UIPlotDialog = "UIPlotDialog",
	UIPlotTextDialog = "UIPlotTextDialog",
	UIPlotTopBottomHeidi = "UIPlotTopBottomHeidi",
	UIPlotBubbleDialog = "UIPlotBubbleDialog",
	UIPlotWujiangDialog = "UIPlotWujiangDialog",
	UIGuideWujiangDialog = "UIGuideWujiangDialog",
	UIFingerGuideDialog = "UIFingerGuideDialog",
	UIInscriptionFingerGuideDialog = "UIInscriptionFingerGuideDialog",

	--战斗结算
	UIBattleWinView = "UIBattleWinView",
	UIBattleLoseView = "UIBattleLoseView",
	UIBattleTimeOutView = "UIBattleTimeOutView",

	--武将界面
	UIWuJiangDetail = "UIWuJiangDetail",
	UIWuJiangSkillDetail = "UIWuJiangSkillDetail",
	UIWuJiangDevelop = "UIWuJiangDevelop",
	UIWuJiangTupoSucc = "UIWuJiangTupoSucc",
	UIWuJiangRank = "UIWuJiangRank",
	UIWuJiangInscription = "UIWuJiangInscription",
	UIInscriptionCaseList = "UIInscriptionCaseList",
	UIAddInscriptionCase = "UIAddInscriptionCase",
	UIInscriptionAutoMergeView = "UIInscriptionAutoMergeView",
	UIWuJiangSkillTipsView = "UIWuJiangSkillTipsView",
	UIWuJiangInscriptionMergeSucc = "UIWuJiangInscriptionMergeSucc",
	UIWuJiangList = "UIWuJiangList",
	UIWuJiangAttr = "UIWuJiangAttr",
	UIShenBingItemTips = "UIShenBingItemTips",
	UIWuJiangXiaoZhuan = "UIWuJiangXiaoZhuan",
	UIQingYuanGiftView = "UIQingYuanGiftView",
	
	--神兵副本
	UIShenbingCopy = "UIShenbingCopy",
	UIShenbingSelect = "UIShenbingSelect",
	UIShenBing = "UIShenBing",
	UIShenBingImprove = "UIShenBingImprove",
	UIShenbingDetailSelect = "UIShenbingDetailSelect",
	UIShenBingStageUp = "UIShenBingStageUp",
	UIShenbingCopyWujiangDialog = "UIShenbingCopyWujiangDialog",
	UIShenBingRebuild = "UIShenBingRebuild",
	UIShenBingRebuildSuccess = "UIShenBingRebuildSuccess",
	UIShenBingMingWenRandShow = "UIShenBingMingWenRandShow",
	UIMingwenSurvey = "UIMingwenSurvey",

	--坐骑
	UIZuoQi = "UIZuoQi",
	UIZuoQiImprove = "UIZuoQiImprove",
	UIHunt = "UIHunt",
	UIHuntTips = "UIHuntTips",
	UIHuntMaintain = "UIHuntMaintain",
	UIHuntLevelUp = "UIHuntLevelUp",
	UIMyMount = "UIMyMount",
	UIMountItemTips = "UIMountItemTips",
	UIMountShow = "UIMountShow",
	UIMountChoice = "UIMountChoice",
	UIMountAttribute = "UIMountAttribute",
	UIMountAttrImprove = "UIMountAttrImprove",
	UIMountChoiceSucc = "UIMountChoiceSucc",

	--军团
	UIGuildJoin = "UIGuildJoin",
	UIMyGuild = "UIMyGuild",
	UIGuildCreate = "UIGuildCreate",
	UIGuildDonation = "UIGuildDonation",
	UIGuildLevelUp = "UIGuildLevelUp",
	UIGuildWorship = "UIGuildWorship",
	UIGuildApplyList = "UIGuildApplyList",
	UIGuildManage = "UIGuildManage",
	UIGuildGetAward = "UIGuildGetAward",
	UIGuildLog = "UIGuildLog",
	UIGuildTask = "UIGuildTask",
	UIGuildMenu = "UIGuildMenu",
	UIGuildPost = "UIGuildPost",
	UIGuildRank = "UIGuildRank",
	UIGuildSkill = "UIGuildSkill",
	UIGuildSkillActive = "UIGuildSkillActive",
	UIGuildResourceDetail = "UIGuildResourceDetail",

	-- 军团争霸
	UIGuildWarMain = "UIGuildWarMain",
	UIGuildWarAchievement = "UIGuildWarAchievement",
	UIBattleGuildWarMain = "UIBattleGuildWarMain",
	UIGuildWarEscortTask = "UIGuildWarEscortTask",
	UIGuildWarInviteCustodian = "UIGuildWarInviteCustodian",
	UIGuildWarRob = "UIGuildWarRob",
	UIGuildWarEscortFail = "UIGuildWarEscortFail",
	UIGuildWarUserTitle = "UIGuildWarUserTitle",
	UIGuildWarCityDetail = "UIGuildWarCityDetail",
	UIGuildWarMemberList = "UIGuildWarMemberList",
	UIGuildWarGuildDetail = "UIGuildWarGuildDetail",
	UIGuildWarDefLineup = "UIGuildWarDefLineup",
	UIGuildWarBuffShop = "UIGuildWarBuffShop",
	UIBattleGuildWarRobMain = "UIBattleGuildWarRobMain",
	UIGuildWarRobSettlement = "UIGuildWarRobSettlement",
	UIGuildWarRank = "UIGuildWarRank",
	UIGuildWarOffenceCityResult = "UIGuildWarOffenceCityResult",
	UIGuildWarLineupSelect = "UIGuildWarLineupSelect",
	UIGuildWarCityLineupSelect = "UIGuildWarCityLineupSelect",
	
	-- Boss
	UIBattleBossMain = "UIBattleBossMain",
	UIWorldBoss = "UIWorldBoss",
	UIWorldBossTip = "UIWorldBossTip",

	--福利
	UIFuli = "UIFuli",

	--活动
	UIActivity = "UIActivity",
	UIActTurntable = "UIActTurntable",
	UIActJiXingGaoZhao = "UIActJiXingGaoZhao",
	
	--群雄逐鹿
	UIGroupHerosWar = "UIGroupHerosWar",
	UIGroupHerosLineUp = "UIGroupHerosLineUp",
	UIGroupHerosLineupSelect = "UIGroupHerosLineupSelect",
	UIGroupHerosJoinRecord = "UIGroupHerosJoinRecord",
	UIGroupHerosJunxian = "UIGroupHerosJunxian",
	UIGroupHerosWarRecord = "UIGroupHerosWarRecord",
	UIGroupHerosWarRank = "UIGroupHerosWarRank",
	UIGroupHerosSaiChangBrief = "UIGroupHerosSaiChangBrief",
	UIGroupHerosWuJiangList = "UIGroupHerosWuJiangList",

	--主公
	UIZhuGong = "UIZhuGong",
	UIChangeName = "UIChangeName",
	UINotificationSetting = "UINotificationSetting",
	UIZhuGongLevelUp = "UIZhuGongLevelUp",
	UICreateRole = "UICreateRole",
	UINotificationSetting = "UINotificationSetting",

	--主界面
	UIMainMenu = "UIMainMenu",
	UIUserDetail = "UIUserDetail",

	-- 竞技场
	UIBattleArenaMain = "UIBattleArenaMain",

	--布阵
	UILineupMain = "UILineupMain",
	UIWuJiangSelect = "UIWuJiangSelect",
	UILineupSelect = "UILineupSelect",
	UILineupManager = "UILineupManager",
	UILineupEdit = "UILineupEdit",
	UILineupEditRoleSelect = "UILineupEditRoleSelect",
	UILineupArenaEdit = "UILineupArenaEdit",
	UICheckLineup = "UICheckLineup",
	UIArenaEditRoleSelect = "UIArenaEditRoleSelect",
	UIShenbingCopyLineupMainView = "UIShenbingCopyLineupMainView",
	UIYuanmenLineupMain = "UIYuanmenLineupMain",

	--飘字
	UIPromptMsg = "UIPromptMsg",
	UIPowerChange = "UIPowerChange",

	--通用
	UITipsDialog = "UITipsDialog",
	UITopTipsDialog = "UITopTipsDialog",
	UINormalTipsDialog = "UINormalTipsDialog",
	UIBuyTipsDialog = "UIBuyTipsDialog",
	UIGetAwardPanel = "UIGetAwardPanel",
	UILineupWujiangBrief = "UILineupWujiangBrief",
	UIMutiLinpup = "UIMutiLinpup",
	UITipsCompound = "UITipsCompound",

	--背包
	UIBag = "UIBagView",
	UIBagUse = "UIBagUseView",

	--闯连营
	UICampsRush = "UICampsRush",
	UICampsRushSelect = "UICampsRushSelect",
	UICampsRushAward = "UICampsRushAward",
	UICampsRushSweepAward = "UICampsRushSweepAward",
	UICampsRushLineup = "UICampsRushLineup",

	--竞技场
	UIArenaMain = "UIArenaMainView",
	UIArenaLevelUp = "UIArenaLevelView",
	UIArenaGradingAward = "UIArenaGradingAwardView",
	UIArenaBattleRecord = "UIArenaBattleRecordView",

	--主线
	UIMainline = "UIMainline",
	UICopyDetail = "UICopyDetail",
	UIMonsterHomeDetail = "UIMonsterHomeDetail",

	--星盘
	UIStarPanel = "UIStarPanelView",
	
	-- Email
	UIEmail = "UIEmail",

	-- BattleRecord
	BattleSettlement = "BattleSettlement",
	BattleRecord = "BattleRecord",
	BattleRecordFromSever = "BattleRecordFromSever",
	UIItemDetail = "UIItemDetail",
	UIBossSettlement = "UIBossSettlement",
	UIBossRecord = "UIBossRecord",
	UIArenaSettlement = "UIArenaSettlement",
	UIArenaRecord = "UIArenaRecord",
	UIShenbingCopySettlement = "UIShenbingCopySettlement",
	UIGuildBossSettlement = "UIGuildBossSettlement",
	UIGuildBossBackSettlement = "UIGuildBossBackSettlement",
	UIGuildBossRecord = "UIGuildBossRecord",
	UIInscriptionSettlement = "UIInscriptionSettlement",
	UIYuanmenSettlement = "UIYuanmenSettlement",
	UIGuildWarSettlement = "UIGuildWarSettlement",
	UIGroupHerosSettlement = "UIGroupHerosSettlement",
	UILieZhuanSettlement = "UILieZhuanSettlement",

	-- guild boss
	UIGuildBoss = "UIGuildBoss",

	--好友
	UIFriendMain = "UIFriendMain",
	UIFriendRequest = "UIFriendRequest",
	UIFriendDetail = "UIFriendDetail",
	UIFriendTask = "UIFriendTask",
	UIFriendGift = "UIFriendGift",
	UIFriendRentOutSelect = "UIFriendRentOutSelect",
	UIFriendTaskInvite = "UIFriendTaskInvite",

	--聊天
	UIChatMain = "UIChatMain",

	UIFightWar = "UIFightWar",

	UIBaoxiang = "UIBaoxiang",

	UICommonRank = "UICommonRank",
	UIWorldbossRank = "UIWorldbossRank",

	--墓穴
	UIGraveCopy = "UIGraveCopy",
	UIGraveCopySettlement = "UIGraveCopySettlement",

	-- 任务
	UITaskMain = "UITaskMain",

	-- 点将
	UIDianJiang = "UIDianJiang",
	UIDianJiangMain = "UIDianJiangMain",
	UIDianjiangAwardOne = "UIDianjiangAwardOne",
	UIDianjiangAwardTen = "UIDianjiangAwardTen",
	UIXiejiaView = "UIXiejiaView",
	UIDrum = "UIDrum",

	--命签
	UIInscriptionCopy = "UIInscriptionCopy",

	UIYuanmen = "UIYuanmen",
	UIYuanmenDetail = "UIYuanmenDetail",

	--首充
	UIShouChong = "UIShouChong",
	UISevenDays = "UISevenDays",
	UIYueKa = "UIYueKa",
	UIDuoBao = "UIDuoBao",
	UIDuoBaoRecord = "UIDuoBaoRecord",

	-- 商店
	UIShop = "UIShop",
	UIBuyGoods = "UIBuyGoods",
	UIRebateShop = "UIRebateShop",

	--神兽副本  
	UIDragonCopyMain = "UIDragonCopyMain",
	UIDragonCopyDetail = "UIDragonCopyDetail",

	--神兽
	UIGodBeast = "UIGodBeast",
	UIGodBeastMain = "UIGodBeastMain",
	UIGodBeastTipsDialog = "UIGodBeastTipsDialog",
	UIGodBeastAllTalent = "UIGodBeastAllTalent",
	UIGodBeastSkillDetail = "UIGodBeastSkillDetail",

	--三国列传
	UILieZhuan = "UILieZhuan",
	UILieZhuanChoose = "UILieZhuanChoose",
	UILieZhuanTeam = "UILieZhuanTeam",
	UILieZhuanFightTroop = "UILieZhuanFightTroop",
	UILieZhuanInvitation = "UILieZhuanInvitation",
	UILieZhuanCreateTeam = "UILieZhuanCreateTeam",
	UILieZhuanLineup = "UILieZhuanLineup",
	UILieZhuanTeamLineupSelect = "UILieZhuanTeamLineupSelect",
	UILieZhuanLineupSelect = "UILieZhuanLineupSelect",
	UILieZhuanSoloLineupMain = "UILieZhuanSoloLineupMain",

	--賽馬
	UIHorseRaceMain = "UIHorseRaceMain",
	UIHorseRaceSelect = "UIHorseRaceSelect",

	--下载
	UIDownloadTipsDialog = "UIDownloadTipsDialog",
	UIDownloadDialog = "UIDownloadDialog",
}

return UIWindowNames