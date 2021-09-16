local Fmt = require(script.Parent.Parent.Utility.Fmt)

local function InspectorMiddleware()
	return function(NextMiddleware)
		return function(Action)
			print(Fmt("{:#?}", Action))
			NextMiddleware(Action)
		end
	end
end

return InspectorMiddleware
