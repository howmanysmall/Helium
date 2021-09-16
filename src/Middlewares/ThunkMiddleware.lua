local function ThunkMiddleware(Store)
	return function(NextMiddleware)
		return function(Action)
			if type(Action) == "function" then
				return Action(Store.Dispatch, Store.GetState)
			end

			NextMiddleware(Action)
		end
	end
end

return ThunkMiddleware
