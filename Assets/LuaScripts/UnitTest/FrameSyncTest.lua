local PBUtil = PBUtil
local BattleEnum = BattleEnum

local FrameSyncTest = BaseClass("FrameSyncTest")

function FrameSyncTest:__init()
    FrameDebuggerInst:SetFrameRecord(true)
    self.m_curTest = nil
end

function FrameSyncTest:Start()
    local battleType = BattleEnum.BattleType_ARENA
    self.m_curTest = self:GetCurTest(battleType)
    self.m_curTest:Start(battleType)
end

function FrameSyncTest:End()
    self.timer_action = function(self)
        self:Start()
    end
    self.timer = TimerManager:GetInstance():GetTimer(1, self.timer_action, self, true)
    self.timer:Start()
end

function FrameSyncTest:Update()
    if self.m_curTest and self.m_curTest:IsOver() then
        self:End()
        self.m_curTest = nil
    end
end

function FrameSyncTest:GetCurTest(battleType)
    if battleType == BattleEnum.BattleType_CAMPSRUSH then
        if not self.m_campsrushTest then
            local class = require("UnitTest.CampsRushTest")
            self.m_campsrushTest = class.New()
        end
        return self.m_campsrushTest
    elseif battleType == BattleEnum.BattleType_BOSS1 or battleType == BattleEnum.BattleType_BOSS2 then
        if not self.m_bossTest then
            local class = require("UnitTest.BOSSTest")
            self.m_bossTest = class.New()
        end
        return self.m_bossTest
    elseif battleType == BattleEnum.BattleType_SHENBING then
        if not self.m_shenbingTest then
            local class = require("UnitTest.ShenBingTest")
            self.m_shenbingTest = class.New()
        end
        return self.m_shenbingTest
    elseif battleType == BattleEnum.BattleType_YUANMEN then
        if not self.m_yuanmenTest then
            local class = require("UnitTest.YuanMenTest")
            self.m_yuanmenTest = class.New()
        end
        return self.m_yuanmenTest
    elseif battleType == BattleEnum.BattleType_INSCRIPTION then
        if not self.m_inscriptionTest then
            local class = require("UnitTest.InscriptionTest")
            self.m_inscriptionTest = class.New()
        end
        return self.m_inscriptionTest
    elseif battleType == BattleEnum.BattleType_GUILD_BOSS then
        if not self.m_guildBossTest then
            local class = require("UnitTest.GuildBossTest")
            self.m_guildBossTest = class.New()
        end
        return self.m_guildBossTest
    elseif battleType == BattleEnum.BattleType_GRAVE then
        if not self.m_graveTest then
            local class = require("UnitTest.GraveTest")
            self.m_graveTest = class.New()
        end
        return self.m_graveTest
    elseif battleType == BattleEnum.BattleType_SHENSHOU then
        if not self.m_dragonCopyTest then
            local class = require("UnitTest.DragonCopyTest")
            self.m_dragonCopyTest = class.New()
        end
        return self.m_dragonCopyTest
    elseif battleType == BattleEnum.BattleType_ARENA then
        if not self.m_arenaTest then
            local class = require("UnitTest.ArenaTest")
            self.m_arenaTest = class.New()
        end
        return self.m_arenaTest
    end
end

return FrameSyncTest