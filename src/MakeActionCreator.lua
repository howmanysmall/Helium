--!strict
local Debug = require(script.Parent.Utility.Debug)
local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local Typer = require(script.Parent.Utility.Typer)

export type ActionCreatorFunction = (...any) -> {[any]: any}

local function MakeActionCreator(ActionName: string, Function: ActionCreatorFunction)
	local Metatable = {}
	function Metatable:__call(...)
		local ActionTable = Function(...)
		if GlobalConfiguration.Get("RunTypeChecking") then
			Debug.Assert(Typer.Check(table.create(1, "table"), ActionTable, "ActionTable"))
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
