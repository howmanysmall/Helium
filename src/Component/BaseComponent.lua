local Enums = require(script.Parent.Parent.Enums)
local Janitor = require(script.Parent.Parent.Janitor)
local _Store = require(script.Parent.Parent.Store)

type Store = _Store.Store
local RedrawBinding: Enums.RedrawBinding = Enums.RedrawBinding :: Enums.RedrawBinding

local BaseComponent = {}
BaseComponent.ClassName = "BaseComponent"
BaseComponent.__index = BaseComponent

function BaseComponent:Constructor(__Store: Store?, ...)
	local _ = {...}
end

function BaseComponent:Redraw(__Store: Store?, __DeltaTime: number?, __DeltaTime2: number?) end
function BaseComponent:Destroy()
	self.Janitor:Destroy()
	setmetatable(self, nil :: any)
end

function BaseComponent:__tostring()
	return "BaseComponent"
end

function BaseComponent.new()
	local self = setmetatable({}, BaseComponent)
	self.RedrawBinding = RedrawBinding.Heartbeat
	self.Janitor = Janitor.new()
	self.Reduction = {Key = "Value"}

	self.GetReducedState = function()
		return {}
	end

	self.QueueRedraw = function() end
	return self
end

export type BaseComponent = typeof(BaseComponent.new())
return BaseComponent
