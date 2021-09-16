local Debug = require(script.Parent.Debug)

local function Strict(Table, __call, ModuleName)
	ModuleName = ModuleName or tostring(Table)
	local Userdata = newproxy(true)
	local Metatable = getmetatable(Userdata)

	function Metatable:__index(Index)
		local Value = Table[Index]
		return Value == nil and Debug.Error("!%q does not exist in read-only table.", ModuleName, Index) or Value
	end

	function Metatable:__newindex(Index, Value)
		Debug.Error("!Cannot write %s to index [%q] of read-only table", ModuleName, Value, Index)
	end

	function Metatable:__tostring(): string
		return ModuleName
	end

	Metatable.__call = __call
	Metatable.__metatable = "[" .. ModuleName .. "] Requested metatable of read-only table is locked"
	return Userdata
end

return Strict
