--!strict
local GlobalConfiguration = require(script.GlobalConfiguration)
local CombineReducers = require(script.CombineReducers)
local MakeActionCreator = require(script.MakeActionCreator)
local Store = require(script.Store)

local Component = require(script.Component)
local Enums = require(script.Enums)
local Make = require(script.Make)
local Janitor = require(script.Janitor)

local Middleware = require(script.Middleware)

local Strict = require(script.Utility.Strict)
local _Types = require(script.Types)

export type BaseAction = _Types.BaseAction
export type BaseComponent = Component.BaseComponent
export type RedrawBinding = Enums.RedrawBinding
export type Reducer = _Types.Reducer
export type Store = Store.Store

local RedrawBinding: RedrawBinding = Enums.RedrawBinding :: RedrawBinding
local SHOULD_LOCK_HELIUM = true

--[=[
	This is a function for reducing actions in the store.

	@type ReducerFunction (Action: BaseAction, GetState: (...any) -> any, SetState: (...any) -> ()) -> ()
	@within Helium
]=]

--[=[
	This is the interface used for configuring how Helium behaves internally.

	@interface HeliumConfiguration
	@within Helium
	.ProfileRedraw boolean? -- Enables `debug.profilebegin` in the component redraw function.
	.RunTypeChecking boolean? -- Enables type checking internally.
	.SafeRedrawCheck boolean? -- Runs an `assert` check when `QueueRedraw` is called to validate that a component's RedrawBinding is correct.
	.UseCombineReducersV2 boolean? -- Enables using the V2 version of `CombineReducers`.
	.UseSwitchStatementForQueueRedraw boolean? -- Enables using a switch statement for `QueueRedraw`. This won't be checked every `QueueRedraw` since performance is the goal here, only when `Component:Constructor` is called.
]=]

--[=[
	This is a shorthand for `Helium.Store.new`.

	@within Helium
	@function CreateStore
	@tag Shorthand
	@tag Utility

	@param Reducer ReducerFunction -- The reducer function.
	@param InitialState NonNil -- The initial state.
	@return Store
]=]

--[=[
	This function is used to set the configuration of how Helium behaves.

	@within Helium
	@function SetGlobalConfiguration
	@tag Configuration
	@tag Utility
	@param ConfigurationValues HeliumConfiguration -- The new configuration.
]=]
--[=[
	This is a shorthand for `Helium.SetGlobalConfiguration`.

	@within Helium
	@function SetGlobalConfig
	@tag Configuration
	@tag Shorthand
	@tag Utility
	@param ConfigurationValues HeliumConfiguration -- The new configuration.
]=]
--[=[
	This is a shorthand for `Helium.SetGlobalConfiguration`.

	@within Helium
	@function SetConfiguration
	@tag Configuration
	@tag Shorthand
	@tag Utility
	@param ConfigurationValues HeliumConfiguration -- The new configuration.
]=]
--[=[
	This is a shorthand for `Helium.SetGlobalConfiguration`.

	@within Helium
	@function SetConfig
	@tag Configuration
	@tag Shorthand
	@tag Utility
	@param ConfigurationValues HeliumConfiguration -- The new configuration.
]=]

--[=[
	Prints out the whole action being dispatched.

	```lua
	local AwesomeAction = Helium.MakeActionCreator("AwesomeAction", function(ObjectName: string, IsAwesome: boolean)
		return {
			ObjectName = ObjectName;
			IsAwesome = IsAwesome;
		}
	end)

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == AwesomeAction.ActionName then
			SetState(Action.ObjectName, Action.IsAwesome)
		end
	end, {
		LPlus = false;
		LPlusLight = false;
		Helium = false;
	}):ApplyMiddleware(Helium.InspectorMiddleware)

	Store:Fire(AwesomeAction("LPlus", true))
	--[[
		Prints:
			{
				Type = "AwesomeAction";
				ObjectName = "LPlus";
				IsAwesome = true;
			}
	]]
	```

	@within Helium
	@function InspectorMiddleware
	@tag Middleware
	@return MiddlewareHandler -- The handler code for the middleware.
]=]
--[=[
	Prints out the action types of every action dispatched.

	```lua
	local AwesomeAction = Helium.MakeActionCreator("AwesomeAction", function(ObjectName: string, IsAwesome: boolean)
		return {
			ObjectName = ObjectName;
			IsAwesome = IsAwesome;
		}
	end)

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == AwesomeAction.ActionName then
			SetState(Action.ObjectName, Action.IsAwesome)
		end
	end, {
		LPlus = false;
		LPlusLight = false;
		Helium = false;
	}):ApplyMiddleware(Helium.InspectorMiddleware)

	Store:Fire(AwesomeAction("LPlus", true)) -- Prints: "AwesomeAction"
	```

	@within Helium
	@function LoggerMiddleware
	@tag Middleware
	@return MiddlewareHandler -- The handler code for the middleware.
]=]
--[=[
	Like `ThunkMiddleware`, allows functions to be dispatched. The only difference is that the functions being dispatched will be spawned
	immediately in a separate thread. This could be more ideal for Roblox development as opposed to JavaScript do to the lack of Promise objects.

	```lua
	local function FetchCoins()
		return function(Dispatch, GetState)
			-- Where we would normally return an action here, we instead return a spawned thunk that defers our change in state.
			local Coins = ReplicatedStorage.GetCoins:InvokeServer()
			Dispatch({
				Type = "SetCoins";
				Value = Coins;
			})
		end
	end

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == "SetCoins" then
			SetState("Coins", Action.Value)
		end
	end, InitialState):ApplyMiddleware(Helium.SpunkMiddleware)

	Store:Fire(FetchCoins())
	```

	@within Helium
	@function SpunkMiddleware
	@tag Middleware
	@param Store Store -- The Store of the middleware.
	@return MiddlewareHandler -- The handler code for the middleware.
]=]
--[=[
	Like its Redux counterpart, thunk middleware allows functions to be dispatched as regular actions. When a function is encountered
	by the middleware in place of an action, that function will be intercepted and called with the arguments `MyThunk(Dispatch, GetState)`.

	```lua
	local function AddCoins()
		return function(Dispatch, GetState)
			Dispatch({
				Type = "SetCoins";
				Value = math.random(100);
			})
		end
	end

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == "SetCoins" then
			SetState("Coins", Action.Value)
		end
	end, InitialState):ApplyMiddleware(Helium.ThunkMiddleware)

	Store:Fire(AddCoins())
	```

	@within Helium
	@function ThunkMiddleware
	@tag Middleware
	@param Store Store -- The Store of the middleware.
	@return MiddlewareHandler -- The handler code for the middleware.
]=]

--[=[
	This is the accessor for the `Store` object.

	```lua
	local Store = Helium.Store.new(function() end, {})
	```

	@prop Store Store
	@tag Class
	@within Helium
]=]

--[=[
	This is the accessor for the `Component` object.

	```lua
	local Component = Helium.Component.Extend("ComponentName")
	```

	@prop Component Component
	@tag Class
	@within Helium
]=]

--[=[
	Helium is a library based on Rocrastinate with improvements for Luau as well as added features.

	:::info Rocrastinate
	Rocrastinate is a fantastic library that is unfortunatley not longer worked on. I've taken development of it into my own hands to keep it alive as it does a lot of things extremely well.
	:::

	@class Helium
]=]
local Helium = {
	SetGlobalConfiguration = GlobalConfiguration.Set;
	SetGlobalConfig = GlobalConfiguration.Set;
	SetConfiguration = GlobalConfiguration.Set;
	SetConfig = GlobalConfiguration.Set;

	CreateStore = Store.new;
	CombineReducers = CombineReducers;
	MakeActionCreator = MakeActionCreator;
	Store = Store;

	Component = Component;
	RedrawBinding = RedrawBinding;
	Make = Make;
	Janitor = Janitor;

	InspectorMiddleware = Middleware.InspectorMiddleware;
	LoggerMiddleware = Middleware.LoggerMiddleware;
	SpunkMiddleware = Middleware.SpunkMiddleware;
	ThunkMiddleware = Middleware.ThunkMiddleware;
}

if not SHOULD_LOCK_HELIUM then
	return Helium
else
	return Strict(Helium, false, "Helium")
end
