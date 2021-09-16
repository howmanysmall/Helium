-- Spunk stands for "Spawned Thunk", which asynchronously spawns thunks rather than calling them synchronously.

local function SpunkMiddleware(Store)
	return function(NextMiddleware)
		return function(Action)
			if type(Action) == "function" then
				return task.spawn(Action, Store.Dispatch, Store.GetState)
			end

			NextMiddleware(Action)
		end
	end
end

return SpunkMiddleware
