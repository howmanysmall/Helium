local _Types = require(script.Parent.Parent.Types)

type ReducersMap = _Types.Map<string, _Types.Reducer>

local function CombineReducers(ReducersMap: ReducersMap)
	local Gets = {}
	local Reducers = {}
	local Sets = {}
	local Length = 0

	for Key, Reducer in next, ReducersMap do
		Length += 1
		Reducers[Length] = Reducer
		Gets[Length] = function(GetState)
			return function(...)
				return GetState(Key, ...)
			end
		end

		Sets[Length] = function(SetState)
			return function(...)
				SetState(Key, ...)
			end
		end
	end

	return function(Action, GetState, SetState)
		for Index, Reducer in ipairs(Reducers) do
			Reducer(Action, Gets[Index](GetState), Sets[Index](SetState))
		end
	end
end

return CombineReducers
