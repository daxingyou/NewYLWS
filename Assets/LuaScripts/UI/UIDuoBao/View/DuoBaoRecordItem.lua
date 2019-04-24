local DuoBaoRecordItem = BaseClass("DuoBaoRecordItem", UIBaseItem)
local base = UIBaseItem

function DuoBaoRecordItem:OnCreate()
    base.OnCreate(self)

    self.m_desTxt = UIUtil.GetChildTexts(self.transform, {  
        "DesTxt",
    })
end

function DuoBaoRecordItem:UpdateData(record_data)
    if not record_data then
        return
    end 
    local time = os.date("%Y.%m.%d %H:%M", record_data.time) 
     
    local itemName = UILogicUtil.GetNameByItemID(record_data.item_id)
     
    self.m_desTxt.text = string.format(Language.GetString(3854), time, record_data.user_name, itemName, record_data.count)
end


return DuoBaoRecordItem