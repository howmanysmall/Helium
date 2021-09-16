local function CombineReducers(ReducersMap)
	local Gets = {}
	local Sets = {}
	local Reducers = {}

	for Key, Reducer in pairs(ReducersMap) do
		local Index = #Reducers + 1
		Reducers[Index] = Reducer
		Gets[Index] = function(Get)
			return function(...)
				return Get(Key, ...)
			end
		end

		Sets[Index] = function(Set)
			return function(...)
				Set(Key, ...)
			end
		end
	end

	return function(Action, Get, Set)
		for Index, Reducer in ipairs(Reducers) do
			Reducer(Action, Gets[Index](Get), Sets[Index](Set))
		end
	end
end

return CombineReducers
