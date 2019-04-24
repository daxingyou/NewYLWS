-- /// <summary>
-- /// added by wsh @ 2017.12.22
-- /// 功能：Assetbundle加载器，给逻辑层使用（预加载），支持协程操作
-- /// 注意：
-- /// 1、加载器AssetBundleMgr只负责调度，创建，不负责回收，逻辑层代码使用完一定要记得回收，否则会产生GC
-- /// 2、尝试加载并缓存所有的asset
-- /// </summary>
local ABAsyncLoaderBase = require("Framework.AssetBundle.ResourceLoader.ABAsyncLoaderBase")
local table_insert = table.insert
local table_remove = table.remove
local ABAsyncLoader = BaseClass("ABAsyncLoader", ABAsyncLoaderBase)

function ABAsyncLoader:__init(sequence)
    self.m_seq = sequence
    self.m_waitingList = {}
    self.m_waitingCount = 0
    self.m_isOver = false
    self.m_delayUnload = 0
    self.m_isFail = false
end

function ABAsyncLoader:Init(abName, dependances)
    self.m_abName = abName
    self.m_isOver = false
    self.m_isFail = false
    self.m_waitingList = {}
    -- 说明：只添加没有被加载过的
    local abInstance = AssetBundleMgrInst
    self.m_assetbundle = abInstance:GetAssetBundleCache(abName)
    if not self.m_assetbundle then
        table_insert(self.m_waitingList, abName)
    end

    if dependances then
        for i = 0, dependances.Length-1 do
            local ab = dependances[i]
            if not abInstance:IsAssetBundleLoaded(ab) then
                table_insert(self.m_waitingList, ab)
            end
        end
    end
    self.m_waitingCount = #self.m_waitingList
    -- ab延时10帧销毁，在iOS和mac editor下加载assetbundle会报错
    self.m_delayUnload = 10
end

function ABAsyncLoader:GetSequence()
    return self.m_seq
end

function ABAsyncLoader:IsDone()
    return self.m_isOver and not self.m_isFail
end

function ABAsyncLoader:IsFail()
    return self.m_isOver and self.m_isFail
end

function ABAsyncLoader:CanUnload()
    if self:IsDone() then
        return self.m_delayUnload <= 0
    else
        return false
    end
end

function ABAsyncLoader:Progress()
    if self:IsDone() then
        return 1
    end

    local abInstance = AssetBundleMgrInst
    local progressSlice = 1 / self.m_waitingCount
    local progressValue = (self.m_waitingCount - #self.m_waitingList) * progressSlice
    for _, wait in ipairs(self.m_waitingList) do
        local creater = abInstance:GetAssetBundleAsyncCreater(wait)
        progressValue = progressValue + (creater and creater:Progress() or 1) * progressSlice
    end
    return progressValue
end

function ABAsyncLoader:Update()
    if self:IsDone() then
        self.m_delayUnload = self.m_delayUnload - 1
        return
    end

    local abInstance = AssetBundleMgrInst
    for i = #self.m_waitingList, 1, -1 do
        local wait = self.m_waitingList[i]
        if abInstance:IsAssetBundleLoaded(wait) then
            -- 发生错误时ab缓存为false,只要有一个错误就需要重新加载，等所有ab加载完成后提示玩家重新加载，
            -- 已经加载的不会被重复加载，先后顺序不影响依赖，因为依赖包在切换场景才卸载
            local ab = abInstance:GetAssetBundleCache(wait)
            if not ab then
                self.m_isFail = true
                abInstance:RemoveAssetBundleCache(wait)
            end
            if wait == self.m_abName then
                self.m_assetbundle = ab
            end

            table_remove(self.m_waitingList, i)
        end
    end

    -- 依赖包在当前场景中常驻，其中的资源不再需要缓存，除非有需要加载
    self.m_isOver = #self.m_waitingList == 0
    if self:IsDone() then
        if abInstance:NeedCacheAsset(self.m_abName) then
            abInstance:AddAssetbundleAssetsCache(self.m_abName)
        end
        self.m_delayUnload = 10
    end
end

function ABAsyncLoader:Dispose()
    self.m_waitingList = {}
    self.m_waitingCount = 0
    self.m_abName = nil
    self.m_assetbundle = nil
    ABLoaderFactory:GetInstance():RecycleLoader(self)
end

return ABAsyncLoader