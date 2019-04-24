--[[
-- added by wsh @ 2018-01-08
-- 特效基类：提供特效组件的基础功能
--]]

local table_insert = table.insert
local IsNull = IsNull
local GameUtility = CS.GameUtility
local Type_Animator = typeof(CS.UnityEngine.Animator)
local Type_Renderer = typeof(CS.UnityEngine.Renderer)
local Type_Trail = typeof(CS.MeleeWeaponTrail)
local BaseEffect = BaseClass("BaseEffect")

-- 构造函数：无特殊情况不要重写，子类销毁逻辑放OnCreate

function BaseEffect:__init(go, parent_trans, effectPath)

	self.gameObject = go
	self.transform = go.transform
	self.effectPath = effectPath
	self.renderers = {}
	self.m_weaponTrails = false
	self.m_animator = false
	self.sortingLayerName = nil
	self.sortingOrder = nil
	self.m_renderQueue = nil
	
	if not IsNull(parent_trans) then
		self.transform:SetParent(parent_trans)
	end
	-- self.transform.localPosition = Vector3.zero
	self.transform.localEulerAngles = Vector3.zero
	-- self.transform.localScale = Vector3.one
	
	GameUtility.SetLocalPosition(self.transform, 0, 0, 0)
	GameUtility.SetLocalScale(self.transform, 1, 1, 1)
	
	self:GetComp()
end

function BaseEffect:GetComp()	
	local tmp = self.gameObject:GetComponentsInChildren(Type_Renderer, true)
	for i = 0, tmp.Length - 1 do
		table_insert(self.renderers, tmp[i])
	end

    self.m_animator = self.gameObject:GetComponentInChildren(Type_Animator)
	-- assert(table.count(self.renderers) > 0)
end

-- 析构函数：无特殊情况不要重写，子类销毁逻辑放OnDestroy
function BaseEffect:__delete()
	
	-- 回收资源
	if self.effectPath ~= nil and not IsNull(self.gameObject) then
		local res_path = PreloadHelper.GetEffectPath(self.effectPath)
		GameObjectPoolInst:RecycleGameObject(res_path, self.gameObject)
	end
	-- 释放引用
	self.effectPath = nil
	self.gameObject = nil
	self.transform = nil
	self.renderers = nil
	self.m_animator = nil
	self.sortingLayerName = nil
	self.sortingOrder = nil
	self.m_renderQueue = nil
	self.timer = nil
	self.timer_action = nil
end


-- 获取sortingLayerName
function BaseEffect:GetSortingLayerName()
	return self.sortingLayerName
end

-- 设置sortingLayerName
function BaseEffect:SetSortingLayerName(sorting_layer_name)
	assert(sorting_layer_name ~= nil and type(sorting_layer_name) == "string")
	self.sortingLayerName = sorting_layer_name
	for _,renderer in pairs(self.renderers) do
		renderer.sortingLayerName = sorting_layer_name
	end
end

-- 获取sortingOrder
function BaseEffect:GetSortingOrder()
	return self.sortingOrder
end

-- 设置sortingOrder
function BaseEffect:SetSortingOrder(sorting_order)
	assert(sorting_order ~= nil and type(sorting_order) == "number")
	self.sortingOrder = sorting_order
	for _,renderer in pairs(self.renderers) do
		renderer.sortingOrder = sorting_order
	end
end

--设置renderQueue
function BaseEffect:SetRenderQueue(render_queue)
	assert(render_queue ~= nil and type(render_queue) == "number")
	self.m_renderQueue = render_queue
	for _,renderer in pairs(self.renderers) do
		renderer.material.renderQueue = render_queue
	end
end

function BaseEffect:GetGameObject()
	return self.gameObject
end

function BaseEffect:GetTransform()
	return self.transform
end

function BaseEffect:SetLayer(layer)
	if self.renderers then
		for i, renderer in pairs(self.renderers) do
			if renderer then
				renderer.gameObject.layer = layer
			end
		end
	end
end

function BaseEffect:ChangePlaySpeed(speed)
	-- if speed <= 0 then
	-- 	return
	-- end

	GameUtility.SetParticleSystemSpeed(self.gameObject, speed)

	if not IsNull(self.m_animator) then
		self.m_animator.speed = speed
	end
end

-- function BaseEffect:OpenOrCloseTrail(isOpen)

-- 	if self.m_weaponTrails then
-- 		for k, v in pairs(self.m_weaponTrails) do
-- 			if v then
-- 				v.Use = isOpen
-- 			end
-- 		end
-- 	end
-- end

function BaseEffect:Show(isShow)
	if not IsNull(self.gameObject) then
		if isShow then
			self.gameObject:SetActive(false)
			self.gameObject:SetActive(true)

		else 
			self.gameObject:SetActive(false)
		end
	end
end

function BaseEffect:Play()
	if not IsNull(self.gameObject) then
		GameUtility.PlayEffectGo(self.gameObject)
	end
end

return BaseEffect