local _Types = require(script.Parent.Parent.Types)

type ReducersMap = _Types.Map<string, _Types.Reducer>

local function CombineReducers(ReducersMap: ReducersMap)
	local ReducersArray = {}
	local Length = 0

	for Key, Reducer in next, ReducersMap do
		local ReducerData = {}
		ReducerData.Reducer = Reducer
		function ReducerData.GetState(GetState)
			return function(...)
				return GetState(Key, ...)
			end
		end

		function ReducerData.SetState(SetState)
			return function(...)
				SetState(Key, ...)
			end
		end

		Length += 1
		ReducersArray[Length] = ReducerData
	end

	return function(Action, GetState, SetState)
		for _, ReducerData in ipairs(ReducersArray) do
			ReducerData.Reducer(Action, ReducerData.GetState(GetState), ReducerData.SetState(SetState))
		end
	end
end

return CombineReducers
