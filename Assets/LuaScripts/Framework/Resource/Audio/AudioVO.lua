local IsNull = IsNull

local CSObject = CS.UnityEngine.Object
local AudioVO = BaseClass("AudioVO")

function AudioVO:__init(key, audioCfg, pausable)
    self.m_key = key
    self.m_elapsedTime = 0
    self.m_finished = false
    self.m_pausable = pausable
    self.m_audioCfg = audioCfg
    
    self.m_isLoop = audioCfg.loop > 0 and true or false
    self.m_loopInterval = audioCfg.loopInterval
    self.m_interval = 0
    self.m_length = 0
end

function AudioVO:__delete()
    if not IsNull(self.m_audioSource) then
       
        -- CSObject.Destroy(self.m_audioSource.gameObject)

        AudioMgr:RecycleAudioSource(self.m_audioSource, self.m_audioCfg)
        self.m_audioSource = nil
    end
end

function AudioVO:InitAudioSource(audioSource)
    self.m_length = audioSource.clip.length + 0.5

    self.m_audioSource = audioSource
    self.m_audioSource.loop = self.m_isLoop and self.m_loopInterval <= 0
    -- self.m_audioSource.playOnAwake = false
end

-- return : is_end (true, false)
function AudioVO:Update(deltaS, isPaused)
    if IsNull(self.m_audioSource) then
        
        return false
    end

    if isPaused and self.m_pausable then 
        return false
    end

    self.m_elapsedTime = self.m_elapsedTime + deltaS

    if not self.m_isLoop then
        if self.m_elapsedTime >= self.m_length then
            return true
        end
        return false
    end

    if self.m_loopInterval > 0 then
        if self.m_elapsedTime >= self.m_length then
            self.m_interval = self.m_interval + self.m_loopInterval
        end
        
        if self.m_interval >= self.m_loopInterval then
            self.m_audioSource:Stop()
            self.m_audioSource:Play()
            self.m_interval = 0
            self.m_elapsedTime = 0
        end
    end
    return false
end

function AudioVO:Pause()
    if IsNull(self.m_audioSource) then
        return
    end
    
    if self.m_pausable then
        self.m_audioSource:Pause()
    end
end

function AudioVO:Play()
    if IsNull(self.m_audioSource) then
        return
    end

    if self.m_audioSource.isPlaying then
        return
    end

    self.m_audioSource:Play()
end

function AudioVO:IsPausable()
    return self.m_pausable
end

function AudioVO:GetAudioSource()
    return self.m_audioSource
end

function AudioVO:SetVolume(vol)
    if IsNull(self.m_audioSource) then
        return
    end
    self.m_audioSource.volume = vol
end

function AudioVO:Key()
    return self.m_key
end

return AudioVO