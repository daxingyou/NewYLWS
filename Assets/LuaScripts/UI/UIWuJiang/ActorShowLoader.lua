--各种UI界面创建武将

local IsNull = IsNull
local ConfigUtil = ConfigUtil
local Vector3 = Vector3
local PreloadHelper = PreloadHelper

local ActorShowLoader = BaseClass("ActorShowLoader", Singleton)

function ActorShowLoader:__init()
    self.m_seq = 0
    self.m_reqDic = {}
end

function ActorShowLoader:PrepareOneSeq()
    self.m_seq = self.m_seq + 1
    return self.m_seq
end

function ActorShowLoader.MakeParam(wujiangID, wuqiLevel, createPet, horseID, horseLevel, stageSound)
    if createPet == nil then
        createPet = true
    end

    local p = {
        wujiangID = wujiangID,
        wuqiLevel = wuqiLevel or 1,
        createPet = createPet,
        horseID = horseID or 0,
        horseLevel = horseLevel or 1,
        stageSound = stageSound,
    }
    return p
end

function ActorShowLoader:CreateShowOffWuJiang(loadingSeq, param, parent, loadCallback, ...)
    local wujiangID = param.wujiangID
    local wuqiLevel = param.wuqiLevel
    
    local wujiangCfg = ConfigUtil.GetWujiangCfgByID(wujiangID)
    if not wujiangCfg then
        Logger.LogError("No Wujiang cfg ".. wujiangID)
        return
    end

    local loadingData = {
        wujiangID = wujiangID,
        wuqiLevel = wuqiLevel,
        horseID = param.horseID,
        horseLevel = param.horseLevel,
        petID = param.createPet and PreloadHelper.GetPet(wujiangID) or nil,
        stageSound = param.stageSound,
        parent = parent,
        loadCallback = loadCallback, 
        tmp = {wjObj = false, wqObj = false, wqObj2 = false, petObj = false, horseObj = false, exWuqi1 = false, stageAudio = false, stageAsk = false},
        params = SafePack(...)
    } 
    self.m_reqDic[loadingSeq] = loadingData

    local resPath = PreloadHelper.GetShowOffWuJiangPath(wujiangID)
    local resPath2, resPath3, exPath1 = PreloadHelper.GetWeaponPath(wujiangID, wuqiLevel)
    local petPath = PreloadHelper.GetShowOffWuJiangPath(loadingData.petID)

    local pool = GameObjectPoolInst

    pool:GetGameObjectAsync(resPath,
        function(inst, seq)

            if IsNull(inst) then
                self:CancelLoad(seq)
                return
            end

            local loadingData = self.m_reqDic[seq]
            if loadingData then
                loadingData.tmp.wjObj = inst
                if self:CheckDone(loadingData, wujiangCfg) then
                    
                    self:LoadDone(seq, wujiangCfg, parent)
                else
                    inst:SetActive(false)
                end
            else
                pool:RecycleGameObject(resPath, inst)
            end
        end, loadingSeq)
    
    if wujiangCfg.rightWeaponPath ~= "" then
        pool:GetGameObjectAsync(resPath2,
            function(inst, seq)
                if IsNull(inst) then
                    self:CancelLoad(seq)
                    return
                end

                local loadingData = self.m_reqDic[seq]
                if loadingData then
                    loadingData.tmp.wqObj = inst
                    inst.name = math.ceil(loadingData.wujiangID).."_wuqi"
                    
                    if self:CheckDone(loadingData, wujiangCfg) then
                       
                        self:LoadDone(seq, wujiangCfg, parent)
                    else
                        inst:SetActive(false)
                    end
                else
                    pool:RecycleGameObject(resPath2, inst)
                end
            end, loadingSeq)
    end
    
    if wujiangCfg.leftWeaponPath ~= "" then
        pool:GetGameObjectAsync(resPath3,
            function(inst, seq)
                if IsNull(inst) then
                    self:CancelLoad(seq)
                    return
                end

                local loadingData = self.m_reqDic[seq]
                if loadingData then
                    loadingData.tmp.wqObj2 = inst
                    inst.name = loadingData.wujiangID.."_wuqi"
                    
                    if self:CheckDone(loadingData, wujiangCfg) then
                       
                        self:LoadDone(seq, wujiangCfg, parent)
                    else
                        inst:SetActive(false)
                    end
                else
                    pool:RecycleGameObject(resPath3, inst)
                end
            end, loadingSeq)
    end

    if petPath then
        pool:GetGameObjectAsync(petPath,
            function(inst, seq)
                if IsNull(inst) then
                    self:CancelLoad(seq)
                    return
                end

                local loadingData = self.m_reqDic[seq]
                if loadingData then
                    loadingData.tmp.petObj = inst
                    if self:CheckDone(loadingData, wujiangCfg) then
                       
                        self:LoadDone(seq, wujiangCfg, parent)
                    else
                        inst:SetActive(false)
                    end
                else
                    pool:RecycleGameObject(petPath, inst)
                end
            end, loadingSeq)
    end

    if param.horseID > 0 then
        local horsePath = PreloadHelper.GetShowoffHorsePath(param.horseID, param.horseLevel)
        pool:GetGameObjectAsync(horsePath,
            function(inst, seq)
                if IsNull(inst) then
                    self:CancelLoad(seq)
                    return
                end

                local loadingData = self.m_reqDic[seq]
                if loadingData then
                    loadingData.tmp.horseObj = inst
                    inst.name = loadingData.wujiangID.."_horse"
                    
                    if self:CheckDone(loadingData, wujiangCfg) then
                        
                        self:LoadDone(seq, wujiangCfg, parent)
                    else
                        inst:SetActive(false)
                    end
                else
                    pool:RecycleGameObject(horsePath, inst)
                end
            end, loadingSeq)
    end

    if exPath1 and exPath1 ~= '' then
        pool:GetGameObjectAsync(exPath1,
            function(inst, seq)
                if IsNull(inst) then
                    self:CancelLoad(seq)
                    return
                end

                local loadingData = self.m_reqDic[seq]
                if loadingData then
                    loadingData.tmp.exWuqi1 = inst
                    inst.name = loadingData.wujiangID.."_exwuqi"
                    
                    if self:CheckDone(loadingData, wujiangCfg) then                        
                        self:LoadDone(seq, wujiangCfg, parent)
                    else
                        inst:SetActive(false)
                    end
                else
                    pool:RecycleGameObject(exPath1, inst)
                end
            end, loadingSeq)
    end

    if loadingData.stageSound and wujiangCfg.stageAudio > 0 then
        local audioCfg = ConfigUtil.GetAudioCfgByID(wujiangCfg.stageAudio)        
        if not audioCfg then
            loadingData.tmp.stageAudio = true
            if self:CheckDone(loadingData, wujiangCfg) then                
                self:LoadDone(loadingSeq, wujiangCfg, parent)
            end  
        else
            local path, type = PreloadHelper.GetAudioPath(audioCfg) 
            GameObjectPoolInst:LoadAssetAsync(path, type, function(clip, seq)
                GameObjectPoolInst:RecycleAsset(path, clip) --只是预加载 没有用

                loadingData.tmp.stageAudio = true
                if self:CheckDone(loadingData, wujiangCfg) then                
                    self:LoadDone(seq, wujiangCfg, parent)
                end   
            end, loadingSeq)  
        end            
    end

    if loadingData.stageSound and wujiangCfg.stageask > 0 then
        local audioCfg = ConfigUtil.GetAudioCfgByID(wujiangCfg.stageask)        
        if not audioCfg then
            loadingData.tmp.stageAsk = true
            if self:CheckDone(loadingData, wujiangCfg) then                
                self:LoadDone(loadingSeq, wujiangCfg, parent)
            end  
        else
            local path, type = PreloadHelper.GetAudioPath(audioCfg) 
            GameObjectPoolInst:LoadAssetAsync(path, type, function(clip, seq)
                GameObjectPoolInst:RecycleAsset(path, clip) --只是预加载 没有用

                loadingData.tmp.stageAsk = true

                if self:CheckDone(loadingData, wujiangCfg) then           
                    self:LoadDone(seq, wujiangCfg, parent)
                end   
            end, loadingSeq)    
        end
    end
end

function ActorShowLoader:CancelLoad(seq)
    local loadingData = self.m_reqDic[seq]
    if loadingData then
        local tmp = loadingData.tmp --立马回收
        if tmp then
            local wujiangID = loadingData.wujiangID
            local wuqiLevel = loadingData.wuqiLevel
            local resPath = PreloadHelper.GetShowOffWuJiangPath(wujiangID)
            local resPath2, resPath3, exPath1 = PreloadHelper.GetWeaponPath(wujiangID, wuqiLevel)

            if tmp.wjObj then
                GameObjectPoolInst:RecycleGameObject(resPath, tmp.wjObj)
            end
            if tmp.wqObj then
                GameObjectPoolInst:RecycleGameObject(resPath2, tmp.wqObj)
            end
            if tmp.wqObj2 then
                GameObjectPoolInst:RecycleGameObject(resPath3, tmp.wqObj2)
            end
            if tmp.horseObj then
                local horsePath = PreloadHelper.GetShowoffHorsePath(loadingData.horseID, loadingData.horseLevel)
                GameObjectPoolInst:RecycleGameObject(horsePath, tmp.horseObj)
            end
            if tmp.petObj then
                local petPath = PreloadHelper.GetShowOffWuJiangPath(loadingData.petID)
                GameObjectPoolInst:RecycleGameObject(petPath, tmp.petObj)
            end
            if tmp.exWuqi1 then
                GameObjectPoolInst:RecycleGameObject(exPath1, tmp.exWuqi1)
            end
            tmp = nil
        end 

        self.m_reqDic[seq] = nil
    end
end

function ActorShowLoader:CheckDone(loadingData, wujiangCfg)
    if loadingData then
        local tmp = loadingData.tmp
       
        if not tmp.wjObj then
            return false
        end

        if wujiangCfg.rightWeaponPath ~= "" then
            if not tmp.wqObj then
                return false
            end
        end

        if wujiangCfg.leftWeaponPath ~= "" then
            if not tmp.wqObj2 then
                return false
            end
        end

        if loadingData.petID then
            if not tmp.petObj then
                return false
            end
        end

        if loadingData.horseID > 0 then
            if not tmp.horseObj then
                return false
            end
        end

        local resPath2, resPath3, exPath1 = PreloadHelper.GetWeaponPath(loadingData.wujiangID, loadingData.wuqiLevel)
        if exPath1 and exPath1 ~= '' then
            if not tmp.exWuqi1 then
                return false
            end
        end

        if loadingData.stageSound then
            if wujiangCfg.stageAudio > 0 then
                if not tmp.stageAudio then
                    return false
                end
            end

            if wujiangCfg.stageask > 0 then
                if not tmp.stageAsk then
                    return false
                end
            end
        end
    end

    return true
end

function ActorShowLoader:LoadDone(seq, wujiangCfg, parent)
    local loadingData = self.m_reqDic[seq]
    if loadingData then
        local tmp = loadingData.tmp
        if tmp and tmp.wjObj then
            for _, obj in pairs(tmp) do
                if obj and obj ~= true then
                    obj:SetActive(true)
                end
            end

            local wjTrans = tmp.wjObj.transform
            wjTrans.localPosition = Vector3.zero
            wjTrans.localEulerAngles = Vector3.zero
            wjTrans.localScale = Vector3.one

            --setParent pos rot scale
            wjTrans:SetParent(parent)
            if tmp.wqObj then
                if wujiangCfg.rightWeaponPath ~= "" then
                    local t = wjTrans:Find(wujiangCfg.rightWeaponPath)
                    if t then
                        local wqTrans = tmp.wqObj.transform
                        wqTrans:SetParent(t)
                        wqTrans.localPosition = Vector3.zero
                        wqTrans.localEulerAngles = Vector3.zero
                        wqTrans.localScale = Vector3.one
                    end
                end
            end

            if tmp.wqObj2 then
                if wujiangCfg.leftWeaponPath ~= "" then
                    local t = wjTrans:Find(wujiangCfg.leftWeaponPath)
                    if t then
                        local wqTrans = tmp.wqObj2.transform
                        wqTrans:SetParent(t)
                        wqTrans.localPosition = Vector3.zero
                        wqTrans.localEulerAngles = Vector3.zero
                        wqTrans.localScale = Vector3.one
                    end
                end
            end

            if tmp.petObj then
                local petTrans = tmp.petObj.transform
                petTrans.localPosition = Vector3.zero
                petTrans.localEulerAngles = Vector3.zero
                petTrans.localScale = Vector3.one
                petTrans:SetParent(parent)
            end

            if tmp.horseObj then
                local horseTrans = tmp.horseObj.transform
                horseTrans.localPosition = Vector3.zero
                horseTrans.localEulerAngles = Vector3.zero
                horseTrans.localScale = Vector3.one
                horseTrans:SetParent(parent)
            end

            if tmp.exWuqi1 then
                local point = PreloadHelper.GetExWeaponPoint(loadingData.wujiangID)
                local t = wjTrans:Find(point)
                if t then
                    local wqTrans = tmp.exWuqi1.transform
                    wqTrans:SetParent(t)
                    wqTrans.localPosition = Vector3.zero
                    wqTrans.localEulerAngles = Vector3.zero
                    wqTrans.localScale = Vector3.one
                end
            end

            local ActorShowClass = require "UI.UIWuJiang.ActorShow"
            local actorShow = ActorShowClass.New(tmp.wjObj, tmp.wqObj, tmp.wqObj2, loadingData.wujiangID, loadingData.wuqiLevel)
            if tmp.petObj then
                actorShow:SetPetGo(tmp.petObj, loadingData.petID)
            end
            if tmp.horseObj then
                actorShow:Mount(tmp.horseObj, loadingData.horseID, loadingData.horseLevel)
            end
            if tmp.exWuqi1 then
                actorShow:SetExWuqi(tmp.exWuqi1)
            end

            actorShow:SetActive(false)
            actorShow:SetActive(true)

            local callback = loadingData.loadCallback
            if callback then
                callback(actorShow, SafeUnpack(loadingData.params))
            end
        end

        self.m_reqDic[seq] = nil   
        -- Logger.LogError("LoadDone, "..seq)
    end
end

function ActorShowLoader:Clear()
    self.m_seq = 0
    self.m_reqDic = {}
end

return ActorShowLoader