local MountData = BaseClass("MountData")

function MountData:__init(_index, _id, _stage, _max_stage, _base_first_attr, _equiped_wujiang_index, _isLocked, _extra_first_attr)
    self.m_index = _index or 0
    self.m_id = _id or 0
    self.m_stage = _stage or 0
    self.m_max_stage = _max_stage or 0
    self.m_base_first_attr = _base_first_attr or {}
    self.m_equiped_wujiang_index = _equiped_wujiang_index or 0
    self.m_isLocked = _isLocked or false
    self.m_extra_first_attr = _extra_first_attr or {}
end

function MountData:GetIndex()
    return self.m_index or 0
end

function MountData:GetItemID()
    return self.m_id or 0
end

function MountData:GetItemCfg()
    return ConfigUtil.GetItemCfgByID(self.m_id)
end

function MountData:GetStage()
    return self.m_stage or 1
end

function MountData:GetMaxStage()
    return self.m_max_stage or 1
end

function MountData:GetLockState()
    return self.m_isLocked or false
end

--用于区别物品的字段
function MountData:GetUniqueID()
    return self.m_index or 0
end

function MountData:GetItemCount()
    return 1
end

function MountData:GetBaseFirstAttr()
    return self.m_base_first_attr
end

return MountData