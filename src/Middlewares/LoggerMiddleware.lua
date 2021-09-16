local function LoggerMiddleware()
	return function(NextMiddleware)
		return function(Action)
			print(Action.Type)
			NextMiddleware(Action)
		end
	end
end

return LoggerMiddleware
