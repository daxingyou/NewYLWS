local BattleEnum = BattleEnum
local SequenceEventType = SequenceEventType
local ConfigUtil = ConfigUtil
local ScreenSummonEffect = CS.ScreenSummonEffect
local TimelineType = TimelineType
local GameObject = CS.UnityEngine.GameObject
local ScreenColorEffect = CS.ScreenColorEffect
local Vector3 = Vector3
local Quaternion = Quaternion
local VirtualCameraType = typeof(CS.Cinemachine.CinemachineVirtualCamera)
local SplitString = CUtil.SplitString
local Playables = CS.UnityEngine.Playables
local table_insert = table.insert
local table_remove = table.remove
local GameUtility = CS.GameUtility

local TimelineBase = BaseClass("TimelineBase")

function TimelineBase:__init()
    self.m_timeline = false
    self.m_timelineGO = false
    self.m_waitWhatEvent = false
    self.m_paramForEvent = false
    self.m_isPaused = false
    self.m_id = 0
    self.m_loadGOList = {}
    self.m_totalLoadCount = 0
    self.m_curLoadCount = 0
    self.m_timelineCfg = false
    self.m_isLoading = true
    self.m_startTime = 0
    self.m_recoverDict = {}
    self.m_duration = 0
    self.m_dialogClipList = {}
    self.m_commandClipList = {}
    self.m_curClipTime = 0 -- 并不等于当前timeline的执行时间
    self.m_timescale = 0
    self.m_timescaleMultiple = 0
end

function TimelineBase:Play(timelineGO, timelineName, timelinePath, startTime, isUpdateByGameTime)
    self.m_startTime = startTime
    self.m_timelineCfg = ConfigUtil.GetTimelineCfgByID(timelineName, timelinePath)
    if not self.m_timelineCfg then
        return
    end

    self.m_timelineGO = timelineGO
    self.m_timeline = self.m_timelineGO:GetComponent(typeof(CS.Timeline))
    GameObjectPoolInst:LoadAssetAsync(self.m_timelineCfg.assetPath, typeof(Playables.PlayableAsset), function(timelineAsset)
        if not IsNull(timelineAsset) then
            local playableDirector = self:AddComponent(typeof(Playables.PlayableDirector))
            if not IsNull(playableDirector) then
                playableDirector.playOnAwake = false
                playableDirector.playableAsset = timelineAsset
                playableDirector.extrapolationMode = Playables.DirectorWrapMode.Hold
                -- if isUpdateByGameTime then
                    playableDirector.timeUpdateMode = Playables.DirectorUpdateMode.GameTime
                -- else
                    -- playableDirector.timeUpdateMode = Playables.DirectorUpdateMode.UnscaledGameTime
                -- end
                self.m_duration = playableDirector.duration
                self.m_timeline:Init(playableDirector)
                self:InitCameraPos()
                self:PreLoad()
            end
        end
    end)
end

function TimelineBase:PreLoad()
    if not self.m_timelineCfg.load_list then
        self:CheckPreloadFinished()
        return
    end
    self.m_totalLoadCount = #self.m_timelineCfg.load_list
    if self.m_totalLoadCount == 0 then
        self:CheckPreloadFinished()
        return
    end

    local gameObjectPool = GameObjectPoolInst
    for i,loadData in ipairs(self.m_timelineCfg.load_list) do
        if loadData then
            if loadData.createInstance then
                gameObjectPool:GetGameObjectAsync(loadData.path, function(go)
                    if not IsNull(go) then
                        local trans = go.transform
                        trans:SetParent(self.m_timelineGO.transform)
                        trans.localScale = Vector3.one
                        trans.localPosition = Vector3.New(loadData.instancePos[1],loadData.instancePos[2],loadData.instancePos[3])
                        trans.localEulerAngles = Vector3.New(loadData.instanceRotation[1],loadData.instanceRotation[2],loadData.instanceRotation[3])
                        go.name = loadData.name
                        self.m_loadGOList[loadData.name] = go
                    end
                    self:CheckPreloadFinished()
                end)
            else
                self:CheckPreloadFinished()
            end
        end
    end
end

function TimelineBase:CheckPreloadFinished()
    self.m_curLoadCount = self.m_curLoadCount + 1
    if self.m_curLoadCount < self.m_totalLoadCount then
        return
    end

    coroutine.start(self.OnPreloadFinished, self)
end

function TimelineBase:OnPreloadFinished()
    -- 延时2帧来让startCamera的位置生效，配合下面的SetCinemachineBrainActive一起
    coroutine.waitforframes(2)
    
    if not self.m_timelineCfg then
        return
    end

    self:InitTrack()

    -- 防止timeline加载出来后startCamera里面把相机拉过去，造成闪一下的问题。
    BattleCameraMgr:SetCinemachineBrainActive(true)
    
    -- 这里这么写是因为把参数都设置成功后，特效并没有创建在节点下面，不清楚原因，这样设置下就正常了
    self.m_timelineGO:SetActive(false)
    self.m_timelineGO:SetActive(true)
    self.m_isLoading = false
    self.m_timeline:Play(
        function (dialogClipList, commandClipList)
            self:DirectorInited(dialogClipList, commandClipList)
        end,
        function (index, startTime)
            self:DialogClipStart(index, startTime)
        end,
        function (waitWhatEvent,  sParam1, iParam1, fParam1)
            self:PauseClipStart(waitWhatEvent, sParam1, iParam1, fParam1)
        end,
        function (timeSkipTo)
            self:SkipClipStart(timeSkipTo)
        end,
        function (commandID, sParam1, iParam1, fParam1)
            self:CommandClipStart(commandID, sParam1, iParam1, fParam1)
        end
    )
    if self.m_startTime and self.m_startTime > 0 then
        self.m_timeline:SkipTo(self.m_startTime)
    end

    if self.m_isPaused then
        self.m_timeline:Pause()
    end
end

function TimelineBase:InitCameraPos()
    local mainCamera = BattleCameraMgr:GetMainCamera()
    if not IsNull(mainCamera) then
        local mainCameraTrans = mainCamera.transform
        local startCamera = self.m_timelineGO.transform:Find("StartCamera")

        if not IsNull(startCamera) then
            startCamera:SetPositionAndRotation(mainCameraTrans.position, mainCameraTrans.rotation)
        end

        local endCamera = self.m_timelineGO.transform:Find("EndCamera")
        if not IsNull(endCamera) then
            endCamera:SetPositionAndRotation(mainCameraTrans.position, mainCameraTrans.rotation)
        end
    end
end

function TimelineBase:InitTrack()
    for _,track in ipairs(self.m_timelineCfg.track_list) do
        if track then
            local bindingObj = self:GetTrackBindingObject(track)
            local trackObject = nil
            if bindingObj then
                trackObject = self.m_timeline:SetTimelineBinding(track.name, bindingObj)
            else
                trackObject = self.m_timeline:GetTimelineTrack(track.name)
            end
            self:InitTrackClip(track, trackObject)
        end
    end
end

function TimelineBase:GetTrackBindingObject(track)
    local bindingObj = nil
    if track.bindingType == TimelineType.BINDING_TYPE_PREFAB then
        local bindingPrefab = ResourcesManagerInst:LoadSync(track.bindingPath, typeof(GameObject))
        if not IsNull(bindingPrefab) then
            local go = GameObject.Instantiate(bindingPrefab, self.m_timelineGO.transform)
            if not IsNull(go) then
                go.transform.localPosition = Vector3.New(track.bindingPos[1],track.bindingPos[2],track.bindingPos[3])
                go.transform.localRotation = Quaternion.Euler(track.bindingRotation[1],track.bindingRotation[2],track.bindingRotation[3])
                self.m_loadGOList[track.name] = go
                bindingObj = go
            end
        end
    elseif track.bindingType == TimelineType.BINDING_TYPE_ROLE then
        ActorManagerInst:Walk(
            function(tmpTarget)
                if tmpTarget:IsLive() and tmpTarget:GetCamp() == track.bindingWujiangCamp  and tmpTarget:GetWujiangID() == track.bindingWujiangID then
                    bindingObj = tmpTarget:GetGameObject()
                end
            end
        )
    elseif track.bindingType == TimelineType.BINDING_TYPE_CAMERA then
        bindingObj = BattleCameraMgr:GetMainCamera().gameObject
    elseif track.bindingType == TimelineType.BINDING_TYPE_CHILD then
        bindingObj = self.m_timelineGO.transform:Find(track.bindingPath).gameObject
    end

    return bindingObj
end

function TimelineBase:InitTrackClip(track, trackObject)
    if track.clipingType == TimelineType.CLIPING_TYPE_EFFECT then
        self:InitEffectClip(track.clip_list, trackObject)
    elseif track.clipingType == TimelineType.CLIPING_TYPE_CAMERA then
        self.m_timeline:InitCameraTrack(trackObject)
    end
end

function TimelineBase:InitEffectClip(clipList, trackObject)
    for clipName,clip in pairs(clipList) do
        if clip then
            local clipPrefab = ResourcesManagerInst:LoadSync(clip.prefabPath, typeof(GameObject))
            if clip.parentType == TimelineType.CLIP_PARENT_TYPE_TRACK then
                self.m_timeline:InitEffectTrack(trackObject, clipName, self.m_loadGOList[clip.trackName], clipPrefab)
            elseif clip.parentType == TimelineType.CLIP_PARENT_TYPE_CAMERA then
                if not IsNull(clipPrefab) then
                    local go = GameObject.Instantiate(clipPrefab, BattleCameraMgr:GetMainCamera().transform)
                    if not IsNull(go) then
                        go.transform.localPosition = Vector3.New(clip.instancePos[1],clip.instancePos[2],clip.instancePos[3])
                        go.transform.localRotation = Quaternion.Euler(clip.instanceRotation[1],clip.instanceRotation[2],clip.instanceRotation[3])
                        self.m_loadGOList[clipName] = go
                    end
                end
            elseif clip.parentType == TimelineType.CLIP_PARENT_TYPE_SELF then
                local transParent = self.m_timelineGO.transform:Find(clip.relativePath)
                self.m_timeline:InitEffectTrack(trackObject, clipName, transParent.gameObject, clipPrefab)
            elseif clip.parentType == TimelineType.CLIP_PARENT_TYPE_BATTLE_WUJIANG then
                local transParent = nil
                ActorManagerInst:Walk(
                    function(tmpTarget)
                        if tmpTarget:IsLive() and tmpTarget:GetCamp() == clip.camp  and tmpTarget:GetWujiangID() == clip.wujiangID then
                            transParent = tmpTarget:GetGameObject()
                        end
                    end
                )
                if transParent then
                    self.m_timeline:InitEffectTrack(trackObject, clipName, transParent, clipPrefab)
                end
            end
        end
    end
end

function TimelineBase:Dispose()
    self:ClosePlotUI()
    self:RecoverCommand()
    ScreenSummonEffect.StopScreenColorEffect(-1)
    if not IsNull(self.m_timelineGO) then
        GameObject.Destroy(self.m_timelineGO)
    end
    for _,go in pairs(self.m_loadGOList) do
        if not IsNull(go) then
            GameObject.Destroy(go)
        end
    end

    self.m_loadGOList = {}

    self.m_timeline = false
    self.m_timelineGO = false
    self.m_waitWhatEvent = false
    self.m_paramForEvent = false
    self.m_isPaused = false
    self.m_timelineCfg = false
    self.m_totalLoadCount = 0
    self.m_curLoadCount = 0
    self.m_id = 0
    self.m_duration = 0
    self.m_dialogClipList = {}
    self.m_commandClipList = {}
    self.m_curClipTime = 0
end

function TimelineBase:IsOver()
    if self.m_isLoading then
        return false
    end

    return self.m_timeline and self.m_timeline:IsTimelineEnd()
end

function TimelineBase:Pause()
    if not self.m_isPaused then
        self.m_isPaused = true
        if self.m_timeline then
            self.m_timeline:Pause()
        end
    end
end

function TimelineBase:Resume()
    if self.m_isPaused then
        self.m_isPaused = false
        if self.m_timeline then
            self.m_timeline:Resume()
        end
    end
end

function TimelineBase:TriggerEvent(eventType, ...)
    local param = ...
    if eventType == self.m_waitWhatEvent then
        if self.m_paramForEvent == "" or self.m_paramForEvent == param then
            self.m_waitWhatEvent = false
            self.m_paramForEvent = false
            self:CheckTimelinePerform()
        end
    end
end

function TimelineBase:CheckTimelinePerform(isResumeIfPause)
    self:PerformCommandClip()
    self:PerformDialogClip(isResumeIfPause)
end

function TimelineBase:SkipTo(time, skipToEnd)
    self:Resume()
    self:RecoverCommand()

    if self.m_timeline then
        self.m_timeline:SkipTo(time, skipToEnd)
    end
end

function TimelineBase:CheckClipWhenSkip(skipTime)
    while #self.m_dialogClipList > 0 and self.m_dialogClipList[1].startTime < skipTime do
        table_remove(self.m_dialogClipList, 1)
    end

    while #self.m_commandClipList > 0 and self.m_commandClipList[1].startTime < skipTime do
        table_remove(self.m_commandClipList, 1)
    end
end

function TimelineBase:DirectorInited(dialogClipList, commandClipList)
    if dialogClipList then
        for i = 0, dialogClipList.Length - 1 do
            table_insert(self.m_dialogClipList, {
                uiName = dialogClipList[i].uiName,
                sParam1 = dialogClipList[i].sParam1,
                sParam2 = dialogClipList[i].sParam2,
                fParam1 = dialogClipList[i].fParam1,
                fParam2 = dialogClipList[i].fParam2,
                iParam1 = dialogClipList[i].iParam1,
                iParam2 = dialogClipList[i].iParam2,
                startTime = dialogClipList[i].startTime,
                index = dialogClipList[i].index,
            })
        end
    end

    if commandClipList then
        for i = 0, commandClipList.Length - 1 do
            table_insert(self.m_commandClipList, {
                commandID = commandClipList[i].commandID,
                sParam1 = commandClipList[i].sParam1,
                fParam1 = commandClipList[i].fParam1,
                iParam1 = commandClipList[i].iParam1,
                startTime = commandClipList[i].startTime,
                index = commandClipList[i].index,
            })
        end
    end
end

function TimelineBase:DialogClipStart(index, startTime)
    self.m_curClipTime = startTime
    self:CheckTimelinePerform()
end

function TimelineBase:PerformDialogClip(isResumeIfPause)
    if #self.m_dialogClipList > 0 and self.m_dialogClipList[1].startTime <= self.m_curClipTime then
        local dialogClipData = table_remove(self.m_dialogClipList, 1)
        if dialogClipData.uiName == "UIPlotTopBottomHeidi" then
            local param = tonumber(dialogClipData.fParam1)
            if param == 1 then
                UIManagerInst:OpenWindow(dialogClipData.uiName, dialogClipData.fParam2)
            else
                UIManagerInst:CloseWindow(dialogClipData.uiName)
            end
            self:PerformDialogClip()
        elseif dialogClipData.uiName == "UIPlotTextDialog" then
            UIManagerInst:OpenWindow(dialogClipData.uiName, dialogClipData.sParam2, dialogClipData.sParam1, 
                                                dialogClipData.fParam1, dialogClipData.fParam2, dialogClipData.iParam1, 
                                                dialogClipData.iParam2, self.m_timelineCfg.plotLanguage)
            self:PerformDialogClip()
        else
            self:Pause()
            if UIManagerInst:IsWindowOpen(dialogClipData.uiName) then
                UIManagerInst:Broadcast(UIMessageNames.UIPLOT_WUJIANG_OPEN, dialogClipData.sParam2, dialogClipData.sParam1, 
                                                    dialogClipData.fParam1, dialogClipData.fParam2, dialogClipData.iParam1, 
                                                    dialogClipData.iParam2, self.m_timelineCfg.plotLanguage)
            else
                UIManagerInst:OpenWindow(dialogClipData.uiName, dialogClipData.sParam2, dialogClipData.sParam1, dialogClipData.fParam1, 
                                            dialogClipData.fParam2, dialogClipData.iParam1, dialogClipData.iParam2, self.m_timelineCfg.plotLanguage)
            end
        end
    else
        isResumeIfPause = isResumeIfPause == nil and true or isResumeIfPause
        if isResumeIfPause then
            self:Resume()
        end
    end
end

function TimelineBase:PauseClipStart(waitWhatEvent, sParam1, iParam1, fParam1)
    self.m_waitWhatEvent = waitWhatEvent
    self.m_paramForEvent = sParam1
    assert(self.m_waitWhatEvent ~= SequenceEventType.NONE, "error wait event is none when pause")
    self:Pause()
end

function TimelineBase:SkipClipStart(timeSkipTo)
    UIManagerInst:Broadcast(UIMessageNames.UIPLOT_ON_SKIP_BTN_SHOW, timeSkipTo)
end

--
function TimelineBase:CommandClipStart(index, startTime)
    self.m_curClipTime = startTime
    self:CheckTimelinePerform(false)
end

function TimelineBase:PerformCommandClip()
    if #self.m_commandClipList > 0 and self.m_commandClipList[1].startTime <= self.m_curClipTime then
        local commandClipData = table_remove(self.m_commandClipList, 1)

        local commandID = commandClipData.commandID
        local sParam1 = commandClipData.sParam1
        local iParam1 = commandClipData.iParam1
        local fParam1 = commandClipData.fParam1

        if commandID == TimelineType.COMMAND_ENABLE_UI_CLICK then
            if iParam1 == 1 then
                UIManagerInst:SetUIEnable(true)
                self:RemoveRecoverEvent(TimelineType.COMMAND_ENABLE_UI_CLICK)
            else
                UIManagerInst:SetUIEnable(false)
                self:RecordNeedRecoverEvent(TimelineType.COMMAND_ENABLE_UI_CLICK, 1)
            end
        elseif commandID == TimelineType.COMMAND_SHOW_SUMMON_SCREEN_EFFECT then
            local time = fParam1
            if time then
                local mat = ResourcesManagerInst:LoadSync("EffectCommonMat/DynamicMaterials/SE_ScreenSummon.mat", typeof(CS.UnityEngine.Material))
                ScreenSummonEffect.ApplyScreenColorEffect(mat, time, Color.white)
                self:RecordNeedRecoverEvent(TimelineType.COMMAND_HIDE_SUMMON_SCREEN_EFFECT, 1)
            end
        elseif commandID == TimelineType.COMMAND_HIDE_SUMMON_SCREEN_EFFECT then
            local time = fParam1
            if time then
                ScreenSummonEffect.StopScreenColorEffect(time)
                self:RemoveRecoverEvent(TimelineType.COMMAND_HIDE_SUMMON_SCREEN_EFFECT)
            end
        elseif commandID == TimelineType.COMMAND_SHOW_SCREEN_EFFECT then
            local time = fParam1
            if time then
                local mat = ResourcesManagerInst:LoadSync("EffectCommonMat/DynamicMaterials/SE_ScreenColor.mat", typeof(CS.UnityEngine.Material))
                ScreenColorEffect.ApplyScreenColorEffect(mat, time, Color.black, iParam1 == 1)
                self:RecordNeedRecoverEvent(TimelineType.COMMAND_HIDE_SCREEN_EFFECT, 1)
                UIManagerInst:CloseWindow(UIWindowNames.UIBattleBloodBar)
                UIManagerInst:CloseWindow(UIWindowNames.UIBattleFloat)
            end
        elseif commandID == TimelineType.COMMAND_HIDE_SCREEN_EFFECT then
            local time = fParam1
            if time then
                ScreenColorEffect.StopScreenColorEffect(time)
                self:RemoveRecoverEvent(TimelineType.COMMAND_HIDE_SCREEN_EFFECT)
                UIManagerInst:OpenWindow(UIWindowNames.UIBattleBloodBar)
                UIManagerInst:OpenWindow(UIWindowNames.UIBattleFloat)
            end
        elseif commandID == TimelineType.COMMAND_TWEEN_SCREEN_EFFECT_ALPHA then
            local alphaList = SplitString(sParam1, ',')
            if #alphaList >= 3 then
                ScreenColorEffect.TweenScreenColorAlpha(tonumber(alphaList[1]), tonumber(alphaList[2]), tonumber(alphaList[3]))
            end
        elseif commandID == TimelineType.COMMAND_HIDE_ALL_WUJIANG then
            local camp = (iParam1 == 1) and BattleEnum.ActorCamp_LEFT or BattleEnum.ActorCamp_RIGHT
            self:RecordNeedRecoverEvent(TimelineType.COMMAND_SHOW_ALL_WUJIANG, camp)
            ActorManagerInst:Walk(
                function(tmpTarget)
                    if tmpTarget:GetCamp() == camp then
                        local trans = tmpTarget:GetTransform()
                        if trans then
                            local pos = trans.localPosition
                            trans.localPosition = Vector3.New(pos.x + 3666,pos.y,pos.z)
                        end
                    end
                end
            )
        elseif commandID == TimelineType.COMMAND_SHOW_ALL_WUJIANG then
            local camp = (iParam1 == 1) and BattleEnum.ActorCamp_LEFT or BattleEnum.ActorCamp_RIGHT
            self:RemoveRecoverEvent(TimelineType.COMMAND_SHOW_ALL_WUJIANG)

            ActorManagerInst:Walk(
                function(tmpTarget)
                    if tmpTarget:GetCamp() == camp then
                        local trans = tmpTarget:GetTransform()
                        if trans then
                            local pos = trans.localPosition
                            trans.localPosition = Vector3.New(pos.x - 3666,pos.y,pos.z)
                        end
                    end
                end
            )
        elseif commandID == TimelineType.COMMAND_SET_SHADOW_HEIGHT then
            local wujiangIDList = SplitString(sParam1, ',')
            local isFind = false
            for _, id in ipairs(wujiangIDList) do
                local go = self.m_loadGOList[id]
                if not IsNull(go) then
                    self:SetShadowHeight(go, fParam1)
                    isFind = true
                end
            end
            if not isFind then
                ActorManagerInst:Walk(
                    function(tmpTarget)
                        for _, id in ipairs(wujiangIDList) do
                            if tmpTarget:GetWujiangID() == tonumber(id) then
                                self:SetShadowHeight(tmpTarget:GetGameObject(), fParam1)
                            end
                        end
                    end
                )
            end
        elseif commandID == TimelineType.COMMAND_UI_WUJIANG_ANIM then
            UIManagerInst:Broadcast(UIMessageNames.UIPLOT_WUJIANG_ANIM, iParam1 == 1, sParam1)
        elseif commandID == TimelineType.COMMAND_UI_WUJIANG_ROTATE then
            UIManagerInst:Broadcast(UIMessageNames.UIPLOT_WUJIANG_ROTATE, iParam1 == 1, fParam1)
        elseif commandID == TimelineType.COMMAND_CAMERA_SHAKE then
            BattleCameraMgr:Shake(fParam1, tonumber(sParam1), iParam1)
        elseif commandID == TimelineType.COMMAND_SET_GUIDED then
            Player:GetInstance():GetUserMgr():ReqSetGuided(iParam1)
        elseif commandID == TimelineType.COMMAND_HIDE_DEAD_WUJIANG then
            DieShowMgr:HideDeadActor()
        elseif commandID == TimelineType.COMMAND_CLOSE_UI then
            UIManagerInst:CloseWindow(sParam1)
        elseif commandID == TimelineType.COMMAND_SET_TIME_SCALE then
            self.m_timescale = TimeScaleMgr:GetTimeScale()
            self.m_timescaleMultiple = TimeScaleMgr:GetTimeScaleMultiple()
            TimeScaleMgr:SetTimeScale(fParam1)
            TimeScaleMgr:SetTimeScaleMultiple(1)
            self:RecordNeedRecoverEvent(TimelineType.COMMAND_SET_TIME_SCALE, fParam1)
        end

        self:PerformCommandClip()
    end
end

function TimelineBase:SetID(id)
    self.m_id = id
end

function TimelineBase:GetID()
    return self.m_id
end

function TimelineBase:GetTimelineGO()
    return self.m_timelineGO
end

function TimelineBase:AddComponent(type)
    if IsNull(self.m_timelineGO) then
        return 
    end
    
    local comp = self.m_timelineGO:GetComponent(type)
    if IsNull(comp) then
        comp = self.m_timelineGO:AddComponent(type)
    end
    return comp
end

function TimelineBase:IsLoading()
    return self.m_isLoading
end

function TimelineBase:RecordNeedRecoverEvent(event, param)
    if self.m_recoverDict[event] == param then
        Logger.Log("Cannot record repeat event, key:" .. event)
    end
    self.m_recoverDict[event] = param
end

function TimelineBase:RemoveRecoverEvent(event)
    if self.m_recoverDict[event] then
        self.m_recoverDict[event] = nil
    end
end

function TimelineBase:RecoverCommand()
    for commandID, param in pairs(self.m_recoverDict) do
        if commandID == TimelineType.COMMAND_ENABLE_UI_CLICK then
            UIManagerInst:SetUIEnable(true)
        elseif commandID == TimelineType.COMMAND_HIDE_SUMMON_SCREEN_EFFECT then
            ScreenSummonEffect.StopScreenColorEffect(-1)
        elseif commandID == TimelineType.COMMAND_HIDE_SCREEN_EFFECT then
            ScreenColorEffect.StopScreenColorEffect(1.5)
            UIManagerInst:OpenWindow(UIWindowNames.UIBattleBloodBar)
            UIManagerInst:OpenWindow(UIWindowNames.UIBattleFloat)
        elseif commandID == TimelineType.COMMAND_SHOW_ALL_WUJIANG then
            local camp = param
            ActorManagerInst:Walk(
                function(tmpTarget)
                    if tmpTarget:GetCamp() == camp then
                        local trans = tmpTarget:GetTransform()
                        if trans then
                            local pos = trans.localPosition
                            trans.localPosition = Vector3.New(pos.x - 3666,pos.y,pos.z)
                        end
                    end
                end
            )
        elseif commandID == TimelineType.COMMAND_SET_TIME_SCALE then
            self:ResumeTimeScale()
        end
    end
    self.m_recoverDict = {}
end

function TimelineBase:SetShadowHeight(go, height)
    if height == 0 then
        height = go.transform.localPosition.y + 0.06
    end

    GameUtility.SetShadowHeight(go, height, 0)
end

function TimelineBase:ClosePlotUI()
    local uimanager = UIManagerInst
    uimanager:CloseWindow(UIWindowNames.UIPlotDialog)
    uimanager:CloseWindow(UIWindowNames.UIPlotTextDialog)
    uimanager:CloseWindow(UIWindowNames.UIPlotTopBottomHeidi)
    uimanager:CloseWindow(UIWindowNames.UIPlotBubbleDialog)
end

function TimelineBase:GetCurTime()
    if self.m_timeline then
        return self.m_timeline:GetCurTime()
    end
end

function TimelineBase:GetDuration()
    return self.m_duration
end

function TimelineBase:ResumeTimeScale()
    TimeScaleMgr:SetTimeScale(self.m_timescale)
    TimeScaleMgr:SetTimeScaleMultiple(self.m_timescaleMultiple)
end

return TimelineBase