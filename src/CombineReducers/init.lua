local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local Version1 = require(script.Version1)
local Version2 = require(script.Version2)
local _Types = require(script.Parent.Types)

export type ReducersMap = _Types.Map<string, _Types.Reducer>

--[=[
	@within Helium
	@function CombineReducers
	@tag Utility

	@param ReducersMap {[Key: string]: ReducerFunction} -- The reducers map
	@return ReducerFunction -- A function that iterates through all the reducers and calls their respect GetState and SetState functions.
]=]
local function CombineReducers(ReducersMap: ReducersMap)
	if GlobalConfiguration.Get("UseCombineReducersV2") then
		return Version2(ReducersMap)
	else
		return Version1(ReducersMap)
	end
end

return CombineReducers
