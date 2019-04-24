local tostring = tostring
local string_format = string.format
local math_floor = math.floor
local table_insert = table.insert

local UIImage = UIImage
local UIUtil = UIUtil
local Vector3 = Vector3
local GameObjectPoolNoActiveInst = GameObjectPoolNoActiveInst
local GameUtility = CS.GameUtility
local Type_Animator = typeof(CS.UnityEngine.Animator)

local WorldArtFont = BaseClass("WorldArtFont", UIBaseItem)
local base = UIBaseItem

local fontPrefabPath = TheGameIds.FontPrefabPath

function WorldArtFont:__init(go, parent, resPath, uiPos, anim, length)
    self.m_anim = anim
    self.m_leftS = length or 0    
    self.m_uiPos = uiPos
    self.m_itemGroupTrans = self.transform:Find("itemGroup")
    self.m_owner = 0
end

function WorldArtFont:SetOwner(owner)
    self.m_owner = owner
end

function WorldArtFont:GetOwner()
    return self.m_owner
end

function WorldArtFont:OnCreate()
    self.m_sprite_list = {}
    self.m_sprite_width_list = {}
    self.m_total_width = 0
    self.m_need_load_count = 0
    self.m_has_load_count = 0
    self.m_curr_sprite_count = 0
    self.m_lineSpace = 0
end

function WorldArtFont:OnDestroy()
    self.m_deleteMe = true

    self.m_animator = nil
    
    if self.m_sprite_list then
        for i, v in ipairs(self.m_sprite_list) do
            GameObjectPoolNoActiveInst:RecycleGameObject(fontPrefabPath, self.m_sprite_list[i].gameObject)
            v:Delete()
        end
        self.m_sprite_list = nil
    end

    self.m_itemGroupTrans = nil

    GameObjectPoolNoActiveInst:RecycleGameObject(TheGameIds.WorldArtFont, self.m_gameObject)
    self.m_gameObject = nil

    base.OnDestroy(self)
end

function WorldArtFont:Start()
    if not self.m_gameObject then
        return
    end

    self.m_animator = self.m_gameObject:GetComponentInChildren(Type_Animator)
    if not self.m_animator then
        return
    end

    GameUtility.SetLocalPosition(self.transform, self.m_uiPos.x, self.m_uiPos.y, self.m_uiPos.z)

    self.m_animator:Play(self.m_anim, 0, 0)
end

function WorldArtFont:MoveUp(y)
    local oldy = self.m_uiPos.y

    self.m_uiPos.y = self.m_uiPos.y + y
    GameUtility.SetLocalPosition(self.transform, self.m_uiPos.x, self.m_uiPos.y, self.m_uiPos.z)
end

function WorldArtFont:AddArtFontImg(img_str, width)
    self.m_need_load_count = self.m_need_load_count + 1

    GameObjectPoolNoActiveInst:GetGameObjectAsync(fontPrefabPath, function(obj)
        if IsNull(obj) then
            return
        end

        if not self.m_deleteMe then
            self.m_curr_sprite_count = self.m_curr_sprite_count + 1
            self.m_total_width = self.m_total_width + width
            self.m_sprite_width_list[self.m_curr_sprite_count] = width
            self.m_has_load_count = self.m_has_load_count + 1
            local str = "Img"..self.m_curr_sprite_count
            obj.name = str
            local trans = obj.transform
            trans:SetParent(self.m_itemGroupTrans)
            GameUtility.SetLocalScale(trans, 0.8, 0.8, 0.8)

            local image = UIUtil.AddComponent(UIImage, self, "itemGroup/"..str, AtlasConfig.BattleDynamicLoad)
            image:SetAtlasSprite(img_str, true)
            self.m_sprite_list[self.m_curr_sprite_count] = image

            self:Layout()
        else
            GameObjectPoolNoActiveInst:RecycleGameObject(fontPrefabPath, obj)
        end
    end)
end

function WorldArtFont:AddArtFontNumber(number, name_part, width)

    if number <= 0 then
        return
    end

    width = width or 18

    local num_list = {}
    local num

    repeat
        num = number % 10
        number = math_floor(number / 10)
        table_insert(num_list, num)
    until number == 0

    local curr_number_count = #num_list
    self.m_need_load_count = self.m_need_load_count + curr_number_count

    local str = ""
    self.m_load_font_list = {}

    local index = 1
    for i = curr_number_count, 1, -1 do
        str = string_format("%s%s.png", name_part, num_list[i])
        self.m_load_font_list[index] = str
        index = index + 1
    end

    GameObjectPoolNoActiveInst:GetGameObjectAsync2(fontPrefabPath, curr_number_count, function(objs)
        if not objs then
            return
        end

        if not self.m_deleteMe then
            for i = 1, #objs do
                self.m_curr_sprite_count = self.m_curr_sprite_count + 1
                self.m_total_width = self.m_total_width + width
                self.m_sprite_width_list[self.m_curr_sprite_count] = width
                self.m_has_load_count = self.m_has_load_count + 1

                local name = tostring(i)
                objs[i].name = name
                local trans = objs[i].transform
                trans:SetParent(self.m_itemGroupTrans)
                GameUtility.SetLocalScale(trans, 0.8, 0.8, 0.8)

                self.m_sprite_list[self.m_curr_sprite_count] = UIUtil.AddComponent(UIImage, self, "itemGroup/"..name, AtlasConfig.BattleDynamicLoad)

                if i <= #self.m_load_font_list then
                    self.m_sprite_list[self.m_curr_sprite_count]:SetAtlasSprite(self.m_load_font_list[i], true)
                end
            end

            if self.m_has_load_count == self.m_need_load_count then
                if self.m_lineSpace > 0 then
                    self:TwoLineLayout()
                else
                    self:Layout()
                end
            end
        else
            for i = 1, #objs do
                GameObjectPoolNoActiveInst:RecycleGameObject(fontPrefabPath, objs[i])
            end
        end
    end)
end

function WorldArtFont:Layout()
    local pos_x = -self.m_total_width / 2
    for i = 1, #self.m_sprite_list do        
        GameUtility.SetLocalPosition(self.m_sprite_list[i].transform, pos_x, 0, 0)
        pos_x = pos_x + self.m_sprite_width_list[i]
    end
end

function WorldArtFont:TwoLineLayout()
    local count = #self.m_sprite_list
    if count > 1 then
        local posY = self.m_lineSpace / 2
        
        GameUtility.SetLocalPosition(self.m_sprite_list[1].transform, -self.m_sprite_width_list[1] / 2 , posY, 0)

        local pos_x = -(self.m_total_width - self.m_sprite_width_list[1]) / 2 
        for i = 2, count do
            GameUtility.SetLocalPosition(self.m_sprite_list[i].transform, pos_x, -posY, 0)
            pos_x = pos_x + self.m_sprite_width_list[i]
        end
    end
end

function WorldArtFont:SetLineSpace(lineSpace)
    self.m_lineSpace = lineSpace or 40
end


function WorldArtFont:Update(deltaS)
    self.m_leftS = self.m_leftS - deltaS
    if self.m_leftS <= 0 then
        return true
    end

    return false
end

return WorldArtFont