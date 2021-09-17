local Debug = require(script.Parent.Utility.Debug)
local DeepCopyTable = require(script.Parent.Utility.DeepCopyTable)
local Fmt = require(script.Parent.Utility.Fmt)
local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local t = require(script.Parent.Utility.t)
local _Types = require(script.Parent.Types)

--- @class Store
local Store = {}
Store.ClassName = "Store"
Store.__index = Store

export type BaseAction = _Types.BaseAction
export type Reducer = _Types.Reducer

type GenericFunction = _Types.GenericFunction
type GenericTable = _Types.GenericTable

local StoreEnhancedDispatchChainIndex = newproxy(false)
local StoreObserversIndex = newproxy(false)
local StoreStateIndex = newproxy(false)

-- local function BaseMiddlewareFunction(_Store: Store)
-- 	return function(_NextDispatch: (Action: BaseAction) -> ())
-- 		return function(_Action: BaseAction) end
-- 	end
-- end

export type MiddlewareFunction = typeof(function(_Store: Store)
	return function(_NextDispatch: (Action: BaseAction) -> ())
		return function(_Action: BaseAction) end
	end
end)

-- export type MiddlewareFunction = (Store: Store) -> ((Action: BaseAction) -> ()) -> (Action: BaseAction) -> ()

local BaseActionDefinition = t.interface({Type = t.any})

--[[**
	Applies a Middleware to the Store. Middlware are simply functions that intercept actions upon being dispatched, and allow custom logic to be applied to them. The way middlewares intercept actions is by providing a bridge in between store.dispatch being called and the root reducer receiving those actions that were dispatched.
	@param [t:MiddlewareFunction] Middleware The middleware function to apply.
	@returns [t:Store]
**--]]
function Store:ApplyMiddleware(Middleware: MiddlewareFunction): Store
	local RunTypeChecking = GlobalConfiguration.Get("RunTypeChecking")
	if RunTypeChecking then
		Debug.Assert(t.callback(Middleware))
	end

	local NextHandler = Middleware(self)
	if RunTypeChecking then
		Debug.Assert(t.callback(NextHandler))
	end

	local StoreEnhancedDispatchChain = NextHandler(self[StoreEnhancedDispatchChainIndex])
	if RunTypeChecking then
		Debug.Assert(t.callback(StoreEnhancedDispatchChain))
	end

	self[StoreEnhancedDispatchChainIndex] = StoreEnhancedDispatchChain
	return self
end

--[[**
	Dispatches an Action to the Store.
	@param [t:BaseAction] Action The Action you are dispatching.
	@returns [t:void]
**--]]
function Store:Fire(Action: BaseAction)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(BaseActionDefinition(Action))
	end

	self[StoreEnhancedDispatchChainIndex](Action)
end

--[[**
	Dispatches an Action to the Store. An alias to `Store:Fire`.
	@param [t:BaseAction] Action The Action you are dispatching.
	@returns [t:void]
**--]]
function Store:Dispatch(Action: BaseAction)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(BaseActionDefinition(Action))
	end

	self[StoreEnhancedDispatchChainIndex](Action)
end

--[[**
	Gets the current Store state.
	@param [t:...string?] ... The string paths, if necessary.
	@returns [t:any] The current Store state.
**--]]
function Store:GetState(...): any
	local Base = self[StoreStateIndex]
	for Index = 1, select("#", ...) do
		if type(Base) ~= "table" then
			return nil
		end

		Base = Base[select(Index, ...)]
	end

	if type(Base) == "table" then
		return DeepCopyTable(Base)
	else
		return Base
	end
end

--[[**
	Sets the current Store state.
	@param [t:...string?] ... The string path to the location you are setting the state of.
	@param [t:any] Value The value you are setting.
	@returns [t:void]
**--]]
function Store:SetState(...)
	local KeyPath = {...}
	local Value = table.remove(KeyPath) :: any

	local VisitedPaths = {""}
	local LastVisitedPath = nil
	for _, Key in ipairs(KeyPath) do
		local NextVisitedPath
		if LastVisitedPath ~= nil then
			NextVisitedPath = LastVisitedPath .. "." .. Key
		else
			NextVisitedPath = Key
		end

		LastVisitedPath = NextVisitedPath
		table.insert(VisitedPaths, NextVisitedPath)
	end

	local Base = self[StoreStateIndex]
	for Index = 1, #KeyPath - 1 do
		if type(Base) ~= "table" then
			Debug.Error("Attempt to set non-table key")
		end

		local Key = KeyPath[Index]
		Base = Base[Key]
	end

	if #KeyPath == 0 then
		self[StoreStateIndex] = Value
	else
		local LastKey = KeyPath[#KeyPath]
		if type(Base) ~= "table" then
			Debug.Error("Attempt to set non-table key")
		end

		Base[LastKey] = Value
	end

	local StoreObservers = self[StoreObserversIndex]
	for _, Path in ipairs(VisitedPaths) do
		local Observers = StoreObservers[Path]
		if Observers then
			local Length = #Observers
			local SaveObservers = (table.move(Observers, 1, Length, 1, table.create(Length)) :: any) :: {any} -- at least robloxts can take a PR to fix this
			for _, SaveObserver in ipairs(SaveObservers) do
				task.spawn(SaveObserver)
			end
		end
	end
end

local ConnectTuple = t.tuple(t.string, t.callback)

--[[**
	Connects a function to the given string keypath.
	@param [t:string] StringKeyPath The string path to run the function at.
	@param [t:function] Function The function you want to run when the state is updated.
	@returns [t:function] A function to disconnect the connection.
**--]]
function Store:Connect(StringKeyPath: string, Function: GenericFunction): () -> ()
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(ConnectTuple(StringKeyPath, Function))
	end

	local StoreObservers = self[StoreObserversIndex]
	local Observers = StoreObservers[StringKeyPath]
	if not Observers then
		Observers = {}
		StoreObservers[StringKeyPath] = Observers
	end

	table.insert(Observers, Function)
	return function()
		local Index = table.find(Observers, Function)
		if Index then
			local Length = #Observers
			Observers[Index] = Observers[Length]
			Observers[Length] = nil
		end

		if #Observers == 0 then
			StoreObservers[StringKeyPath] = nil
		end
	end
end

--[[**
	Connects a function to the given string keypath. An alias to `Store:Connect`.
	@param [t:string] StringKeyPath The string path to run the function at.
	@param [t:function] Function The function you want to run when the state is updated.
	@returns [t:function] A function to disconnect the connection.
**--]]
function Store:Subscribe(StringKeyPath: string, Function: GenericFunction)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(ConnectTuple(StringKeyPath, Function))
	end

	local StoreObservers = self[StoreObserversIndex]
	local Observers = StoreObservers[StringKeyPath]
	if not Observers then
		Observers = {}
		StoreObservers[StringKeyPath] = Observers
	end

	table.insert(Observers, Function)
	return function()
		local Index = table.find(Observers, Function)
		if Index then
			local Length = #Observers
			Observers[Index] = Observers[Length]
			Observers[Length] = nil
		end

		if #Observers == 0 then
			StoreObservers[StringKeyPath] = nil
		end
	end
end

--[[**
	Determines if the passed object is a Store.
	@param [t:any] Object The object to check against.
	@returns [t:boolean] Whether or not the object is a Store.
**--]]
function Store.Is(Object: any): boolean
	return type(Object) == "table" and getmetatable(Object) == Store
end

--[[**
	Creates a new Store object.
	@param [t:function] Reducer The reducer function.
	@param [t:any] InitialState The initial state of the store.
	@returns [t:Store] A new Store object.
**--]]
function Store.new(Reducer: Reducer, InitialState: GenericTable)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(t.callback(Reducer))
	end

	local self = setmetatable({}, Store)
	self[StoreObserversIndex] = {}
	self[StoreStateIndex] = InitialState
	self[StoreEnhancedDispatchChainIndex] = function(Action)
		Reducer(Action, function(...)
			return self:GetState(...)
		end, function(...)
			return self:SetState(...)
		end)
	end

	return self
end

function Store:__tostring()
	return Fmt("Store<{:#?}>", self[StoreStateIndex])
end

export type Store = typeof(Store.new(function(_Action: BaseAction, _GetState, _SetState) end, {}))
return Store
