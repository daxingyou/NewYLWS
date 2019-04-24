-- /// <summary>
-- /// added by wsh @ 2017.12.23
-- /// 功能：Manifest管理：提供对AssetBundleManifest类的封装
-- /// 注意：关于Manifest，Unity有个2个Bug：不记得在哪个版本修复了，这里使用manifest相关接口一律自行过滤掉
-- /// 1、可能会给空的ab名字，具体情况未知
-- /// 2、可能会包含自身，具体情况未知
-- /// </summary>
local AssetBundleHelper = CS.AssetBundles.AssetBundleHelper
local AssetBundleUtility = CS.AssetBundles.AssetBundleUtility
local GameUtility = CS.GameUtility
local table_insert = table.insert
local Manifest = BaseClass("Manifest")
local ASSET_NAME = "AssetBundleManifest"

function Manifest:__init()
    self.m_manifest = nil -- Unity的AssetBundleManifest类
    self.m_manifestABName = AssetBundleMgrInst:GetManifestABName()
    self.m_allABList = nil
end

function Manifest:GetABManifest()
    return self.m_manifest
end

function Manifest:GetABName()
    return self.m_manifestABName
end

function Manifest:GetLength()
    if self.m_manifest then
        return self.m_manifest:GetAllAssetBundles().Length
    end

    return 0
end

function Manifest:LoadFromAssetbundle(assetbundle)
    self.m_manifest = AssetBundleHelper.LoadManifestFromAssetbundle(assetbundle, ASSET_NAME)
end

function Manifest:SaveToDiskCahce(www)
    local path = AssetBundleUtility.GetPersistentDataPath(self:GetABName())
    GameUtility.SafeWriteWWWBytes(path, www)
end

function Manifest:GetAssetBundleHash(abName)
    if self.m_manifest then
        return self.m_manifest:GetAssetBundleHash(abName)
    end
end

function Manifest:IsAssetBundleExist(abName)
    if not self.m_allABList then
        self.m_allABList = {}
        local abList = self:GetAllAssetBundleNames()
        for i = 0, abList.Length-1 do
            local name = abList[i]
            if name and name ~= '' then
                self.m_allABList[name] = true
            end
        end
    end
    return self.m_allABList[abName]
end

function Manifest:GetAllAssetBundleNames()
    if self.m_manifest then
        return self.m_manifest:GetAllAssetBundles()
    end
end

function Manifest:GetAllAssetBundlesWithVariant()
    if self.m_manifest then
        return self.m_manifest:GetAllAssetBundlesWithVariant()
    end
end

function Manifest:GetAllDependencies(assetbundleName)
    if self.m_manifest then
        return self.m_manifest:GetAllDependencies(assetbundleName)
    end
end

function Manifest:GetDirectDependencies(assetbundleName)
    if self.m_manifest then
        return self.m_manifest:GetDirectDependencies(assetbundleName)
    end
end

function Manifest:CompareTo(manifest)
    local ret_list = {}
    if not manifest or not manifest:GetABManifest() then
        return ret_list
    end

    local other_name_list = manifest:GetAllAssetBundleNames()
    local self_name_list = self:GetAllAssetBundleNames()
    for i = 0, other_name_list.Length-1 do
        local abName = other_name_list[i]
        if abName and abName ~= '' then
            local ret = self:FindIndex(self_name_list, abName)
            if ret then
                if self:GetAssetBundleHash(abName) ~= manifest:GetAssetBundleHash(abName) then
                    -- 对方有，自己有，但是hash不同
                    table_insert(ret_list,abName)
                else
                    -- 对方有，自己有，且hash相同：什么也不做
                end
            else
                -- 对方有、自己无
                table_insert(ret_list,abName)
            end
        end
    end
    return ret_list
end

function Manifest:FindIndex(list, abName)
    for i = 0, list.Length - 1 do
        if list[i] == abName then
            return true
        end
    end
    return false
end

return Manifest