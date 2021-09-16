local RunService = game:GetService("RunService")
local Debug = require(script.Parent.Utility.Debug)
local Enums = require(script.Parent.Enums)
local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local Janitor = require(script.Parent.Janitor)
local Store = require(script.Parent.Store)

local _BaseComponent = require(script.BaseComponent)

local RedrawBinding: Enums.RedrawBinding = Enums.RedrawBinding :: Enums.RedrawBinding

-- The queue could probably be optimized by making it a heap.
local BindingHandlerActive = {}

local RedrawComponent
if GlobalConfiguration.Get("ProfileRedraw") then
	function RedrawComponent(Component, ...)
		debug.profilebegin("Redraw" .. tostring(Component))
		Component:Redraw(Component.GetReducedState(), ...)
		debug.profileend()
	end
else
	function RedrawComponent(Component, ...)
		Component:Redraw(Component.GetReducedState(), ...)
	end
end

local function GetBindingHandler(Queue)
	return function(...)
		BindingHandlerActive[Queue] = true
		local RequeueNextFrame = {}
		local Handled = {}

		local Component = next(Queue)
		while Component do
			Queue[Component] = nil
			if Handled[Component] then
				RequeueNextFrame[Component] = true
			else
				Handled[Component] = true
				task.spawn(RedrawComponent, Component, ...)
			end

			Component = next(Queue)
		end

		BindingHandlerActive[Queue] = false
		for RequeueComponent in pairs(RequeueNextFrame) do
			Queue[RequeueComponent] = true
		end
	end
end

local RenderStepQueue = setmetatable({}, {__mode = "k"})
local RenderStepTwiceQueue = setmetatable({}, {__mode = "k"})

if RunService:IsClient() then
	RunService:BindToRenderStep("HeliumRedraw", Enum.RenderPriority.Last.Value + 1, GetBindingHandler(RenderStepQueue))
	RunService:BindToRenderStep("HeliumSecondRedraw", Enum.RenderPriority.Last.Value + 2, GetBindingHandler(RenderStepTwiceQueue))
end

local HeartbeatQueue = setmetatable({}, {__mode = "k"})
RunService.Heartbeat:Connect(GetBindingHandler(HeartbeatQueue))

local SteppedQueue = setmetatable({}, {__mode = "k"})
if RunService:IsRunning() then
	RunService.Stepped:Connect(GetBindingHandler(SteppedQueue))
end

local Component = {}

function Component:Constructor(StoreObject)
	local UseStore = true
	--if type(Store) ~= "table" or type(Store.GetState) ~= "function" or type(Store.SetState) ~= "function" then
	--	UseStore = false
	--	if self.Reduction then
	--		Debug.Warn("!Components with a state reduction must have a store as the first argument of their constructor " .. debug.traceback(), script.Name)
	--	end
	--end

	local Reduction = self.Reduction
	if not Store.Is(StoreObject) then
		UseStore = false
		if Reduction then
			Debug.Warn("!Components with a state reduction must have a store as the first argument of their constructor " .. debug.traceback(), script.Name)
		end
	end

	-- a dub
	self.Janitor = Janitor.new()

	local MappedStateKeys = {}
	local MappedStringKeyPaths = {}
	local MappedKeyPaths = {}
	if Reduction then
		for Key, StringKeyPath in pairs(Reduction) do
			table.insert(MappedStateKeys, Key)
			table.insert(MappedStringKeyPaths, StringKeyPath)
			table.insert(MappedKeyPaths, string.split(StringKeyPath, "."))
		end
	end

	local ReadOnlyCache = {}

	if UseStore then
		function self.GetReducedState()
			local ReducedState = {}
			for Index, StateKey in ipairs(MappedStateKeys) do
				local KeyPath = MappedKeyPaths[Index]
				local StringKeyPath = MappedStringKeyPaths[Index]

				local Cached = ReadOnlyCache[StringKeyPath]
				if Cached ~= nil then
					ReducedState[StateKey] = Cached
				else
					Cached = StoreObject:GetState(table.unpack(KeyPath))
					ReducedState[StateKey] = Cached
					ReadOnlyCache[StringKeyPath] = Cached
				end
			end

			return ReducedState
		end
	else
		function self.GetReducedState()
			return {}
		end
	end

	if GlobalConfiguration.Get("UseSwitchStatementForQueueRedraw") then
		function self.QueueRedraw()
			local CurrentRedrawBinding
			if GlobalConfiguration.Get("SafeRedrawCheck") then
				CurrentRedrawBinding = Debug.Assert(RedrawBinding.Cast(self.RedrawBinding))
			else
				CurrentRedrawBinding = self.RedrawBinding
			end

			repeat
				if CurrentRedrawBinding == RedrawBinding.RenderStep then
					RenderStepQueue[self] = true
					break
				end

				if CurrentRedrawBinding == RedrawBinding.RenderStepTwice then
					if BindingHandlerActive[RenderStepQueue] then
						RenderStepTwiceQueue[self] = true
					else
						RenderStepQueue[self] = true
					end

					break
				end

				if CurrentRedrawBinding == RedrawBinding.Heartbeat then
					HeartbeatQueue[self] = true
					break
				end

				if CurrentRedrawBinding == RedrawBinding.Stepped then
					SteppedQueue[self] = true
					break
				end

				Debug.Error("Invalid RedrawBinding %q", CurrentRedrawBinding)
			until true
		end
	else
		function self.QueueRedraw()
			local CurrentRedrawBinding
			if GlobalConfiguration.Get("SafeRedrawCheck") then
				CurrentRedrawBinding = Debug.Assert(RedrawBinding.Cast(self.RedrawBinding))
			else
				CurrentRedrawBinding = self.RedrawBinding
			end

			if CurrentRedrawBinding == RedrawBinding.RenderStep then
				RenderStepQueue[self] = true
			elseif CurrentRedrawBinding == RedrawBinding.RenderStepTwice then
				if BindingHandlerActive[RenderStepQueue] then
					RenderStepTwiceQueue[self] = true
				else
					RenderStepQueue[self] = true
				end
			elseif CurrentRedrawBinding == RedrawBinding.Heartbeat then
				HeartbeatQueue[self] = true
			elseif CurrentRedrawBinding == RedrawBinding.Stepped then
				SteppedQueue[self] = true
			else
				Debug.Error("Invalid RedrawBinding %q", CurrentRedrawBinding)
			end
		end
	end

	if UseStore and Reduction then
		for _, StringKeyPath in pairs(Reduction) do
			self.Janitor:Add(StoreObject:Connect(StringKeyPath, function()
				ReadOnlyCache[StringKeyPath] = nil
				self.QueueRedraw()
			end), true)
		end
	end
end

local ReservedStatics = {
	new = true;
	Destroy = true;
}

local ComponentStaticMetatable = {}
function ComponentStaticMetatable:__newindex(Index, Value)
	if ReservedStatics[Index] then
		Debug.Error("Cannot override Component member %q; key is reserved", Index)
	else
		rawset(self, Index, Value)
	end
end

-- what if we enabled a way to predeclare all the variables that would be in the table? could that be beneficial?

function Component.Extend(ClassName: string)
	local ComponentStatics = {}
	ComponentStatics.ClassName = ClassName
	ComponentStatics.RedrawBinding = RedrawBinding.Heartbeat
	ComponentStatics.Constructor = nil
	ComponentStatics.Reduction = nil

	local ComponentMetatable = {}
	ComponentMetatable.__index = ComponentStatics
	function ComponentMetatable:__tostring()
		return ClassName
	end

	function ComponentStatics.new(ComponentStore, ...)
		local self = setmetatable({}, ComponentMetatable)
		Component.Constructor(self, ComponentStore)

		local Constructor = ComponentStatics.Constructor
		if Constructor then
			Constructor(self, ComponentStore, ...)
		end

		self.QueueRedraw()
		return self
	end

	function ComponentStatics:Redraw()
		-- Called when QueueRedraw is called.
	end

	function ComponentStatics:Destroy()
		self.Janitor:Destroy()

		RenderStepQueue[self] = nil
		RenderStepTwiceQueue[self] = nil
		HeartbeatQueue[self] = nil
		SteppedQueue[self] = nil

		setmetatable(self, nil :: any)
	end

	return setmetatable(ComponentStatics, ComponentStaticMetatable)
end

export type BaseComponent = _BaseComponent.BaseComponent
return Component
