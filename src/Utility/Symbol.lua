local function Symbol(Name: string)
	local self = newproxy(true)
	local Metatable = getmetatable(self)
	local SymbolName = string.format("Symbol(%s)", Name)

	function Metatable.__tostring()
		return SymbolName
	end

	return self
end

return Symbol
