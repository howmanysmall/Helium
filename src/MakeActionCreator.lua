--!strict
local Debug = require(script.Parent.Utility.Debug)
local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local t = require(script.Parent.Utility.t)

export type ActionCreatorFunction = (...any) -> {[any]: any}

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
