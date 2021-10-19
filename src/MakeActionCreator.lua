--!strict
local Debug = require(script.Parent.Utility.Debug)
local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local t = require(script.Parent.Utility.t)

export type ActionCreatorFunction = (...any) -> {[any]: any}

--[=[
	@interface ActionBase
	@within Helium
	.Type string -- The type of action.
]=]

--[=[
	The ActionCreatorTable has a metatable with `__call`, so you can use it as a function. It returns an ActionBase.

	@interface ActionCreatorTable
	@within Helium
	.ActionName string -- The name of the action creator.
	.Name string -- The name of the action creator.
]=]

--[=[
	Action creators are helper objects that will generate actions from provided data and automatically populate the `Type` field.

	Actions are structured in a way that they always have a `Type` field. They will often have some other values as well.

	```lua
	local AwesomeAction = {
		Type = "AwesomeAction";

		ArgumentName = "LPlus";
		IsAwesome = true;
	}
	```

	You can generate an action from a function, but you must provide the `Type` field yourself.

	```lua
	local function CreateAwesomeAction(ArgumentName: string, IsAwesome: boolean)
		return {
			Type = "AwesomeAction";

			ArgumentName = ArgumentName;
			IsAwesome = IsAwesome;
		}
	end
	```

	`MakeActionCreator` is similar, but it will automatically populate the `Type` field using the first argument of the constructor function.

	```lua
	local CreateAwesomeAction = Helium.MakeActionCreator("AwesomeAction", function(ArgumentName: string, IsAwesome: boolean)
		return {
			ArgumentName = ArgumentName;
			IsAwesome = IsAwesome;
		}
	end)
	```

	This can then be used in the Store reducer function.

	```lua
	local CreateAwesomeAction = require("CreateAwesomeAction")

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == CreateAwesomeAction.ActionName then
			SetState(Action.ArgumentName, Action.IsAwesome)
		end
	end, {
		LPlus = false;
		LPlusLight = false;
		Helium = false;
	})

	Store:Fire(CreateAwesomeAction("LPlus", true))
	Store:Fire(CreateAwesomeAction("Helium", true))
	Store:Fire(CreateAwesomeAction("LPlusLight", false))

	print(Store:InspectState())
	--[[
		Prints:
			{
				Helium = true;
				LPlus = true;
				LPlusLight = false;
			}
	]]
	```

	@within Helium
	@function MakeActionCreator
	@tag Utility

	@param ActionName string -- The name of the Action.
	@param Function (...any) -> {[any]: any} -- The function that creates the action.
	@return ActionCreatorTable -- The action creator.
]=]
local function MakeActionCreator(ActionName: string, Function: ActionCreatorFunction)
	local Metatable = {}
	function Metatable:__call(...)
		local ActionTable = Function(...)
		if GlobalConfiguration.Get("RunTypeChecking") then
			Debug.Assert(t.table(ActionTable))
		end

		ActionTable.Type = ActionName
		return ActionTable
	end

	return setmetatable({
		ActionName = ActionName;
		Name = ActionName;
	}, Metatable)
end

return MakeActionCreator
