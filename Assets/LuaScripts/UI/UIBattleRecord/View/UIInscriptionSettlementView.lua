local base = require "UI.UIBattleRecord.View.BattleSettlementView"
local UIInscriptionSettlementView = BaseClass("UIInscriptionSettlementView", base)

local math_floor = math.floor
local table_insert = table.insert
local string_format = string.format

function UIInscriptionSettlementView:OnEnable(...)
    base.OnEnable(self, ...)
    
    local _, msgObj = ...
    if msgObj then

        coroutine.start(self.UpdateSorceNum, self, msgObj.score)
    end
end

function UIInscriptionSettlementView:UpdateSorceNum(score)
    coroutine.waitforseconds(2)

    local score2 = score
    if not score then
        return
    end

    if score == 0 then
		return
    end

    self.m_scoreImageTran.gameObject:SetActive(true)

	local num_list = {}
	local num
    repeat
        num = score % 10
        score = math_floor(score / 10)
        table_insert(num_list, num)
    until score == 0

	local curr_number_count = #num_list
	local index = 1
	local str = ""
    for i = curr_number_count, 1, -1 do
		str = string_format("number5%s.png", math_floor(num_list[i]))
		self.m_scoreNumList[index].gameObject:SetActive(true)
        self.m_scoreNumList[index]:SetAtlasSprite(str)
        index = index + 1
	end

	for i = index, 5 do 
		self.m_scoreNumList[index].gameObject:SetActive(false)
	end

	local scoreAwardCfgList	= ConfigUtil.GetInscriptionCopyScoreAwardCfgList()
	for i, v in ipairs(scoreAwardCfgList) do
		if v then
			if score2 <= v.max and score2 >= v.min then
				self.m_scoreImage:SetAtlasSprite(v.image)
			end
		end
    end
    
    self:ScoreChgShow()
end

local SCORE_SCALE = Vector3.New(0.02, 0.02, 0.02)
local DOTweenShortcut = CS.DOTween.DOTweenShortcut
local DOTweenSettings = CS.DOTween.DOTweenSettings

function UIInscriptionSettlementView:ScoreChgShow()
	self.m_scoreImageTran.localScale = SCORE_SCALE
	local tweener = DOTweenShortcut.DOScale(self.m_scoreImage.transform, 1, 0.2)
	DOTweenSettings.SetEase(tweener, DoTweenEaseType.InBack)
end

function UIInscriptionSettlementView:ShowTimeout(show)
    self.m_timeoutText.gameObject:SetActive(false)
end

function UIInscriptionSettlementView:UpdateTimeout()
    self.m_timeoutText.gameObject:SetActive(false)
end

return UIInscriptionSettlementView