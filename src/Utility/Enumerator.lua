-- enumerations in pure Luau
-- @docs https://roblox.github.io/enumerate/
-- documented changed functions

local t = require(script.Parent.t)

local ALREADY_USED_NAME_ERROR = "Already used %q as a value name in enum %q."
local ALREADY_USED_VALUE_ERROR = "Already used %q as a value in enum %q."
local CANNOT_USE_ERROR = "Cannot use '%s' as a value"
local INVALID_MEMBER_ERROR = "%q (%s) is not a valid member of %s"
local INVALID_VALUE_ERROR = "Couldn't cast value %q (%s) to enumerator %q"

local BLACKLISTED_VALUES = {
	Cast = true;
	FromRawValue = true;
	GetEnumeratorItems = true;
	IsEnumValue = true;
}

-- stylua: ignore
local EnumeratorTuple = t.tuple(
	t.string,
	t.union(
		t.array(t.string),
		t.keys(t.string)
	)
)

local function LockTable(Table, Name)
	Name = Name or tostring(Table)
	local function ProtectedFunction(_, Index)
		error(string.format(INVALID_MEMBER_ERROR, tostring(Index), typeof(Index), tostring(Name)))
	end

	return setmetatable(Table, {
		__index = ProtectedFunction;
		__newindex = ProtectedFunction;
	})
end

type EnumValues = {string} | {[string]: any}

--[[**
	Creates a new enumeration.
	@param [t:string] enumName The unique name of the enumeration.
	@param [t:{string}|{string:any}] enumValues The values of the enumeration.
	@returns [t:userdata] a new enumeration
**--]]
local function Enumerator(EnumName: string, EnumValues: EnumValues)
	assert(EnumeratorTuple(EnumName, EnumValues))

	local Enumeration = newproxy(true)
	local Internal = {}
	local RawValues = {}
	local TotalEnums = 0

	--[[**
		Returns an `EnumerationValue` from the calling `Enumeration` or `nil` if the raw value does not exist.
		@param [t:any] RawValue The raw value of the enum.
		@returns [t:EnumerationValue?] The `EnumerationValue` if it was found.
	**--]]
	function Internal.FromRawValue(RawValue)
		return RawValues[RawValue]
	end

	--[[**
		Returns `true` only if the provided value is an `EnumerationValue` that is a member of the calling `Enumeration`.
		@param [t:any] Value The value to check for.
		@returns [t:boolean] True iff it is an `EnumerationValue`.
	**--]]
	function Internal.IsEnumValue(Value)
		if typeof(Value) ~= "userdata" then
			return false
		end

		for _, EnumValue in pairs(Internal) do
			if EnumValue == Value then
				return true
			end
		end

		return false
	end

	--[[**
		This function will cast values to the appropriate enumerator. This behaves like a type checker from t, except it returns the value if it was found.
		@param [t:any] Value The value you want to cast.
		@returns [t:false|enumerator,string?] Either returns the appropriate enumeration if found or false and an error message if it couldn't find it.
	**--]]
	function Internal.Cast(Value)
		if Internal.IsEnumValue(Value) then
			return Value
		end

		local FoundEnumerator = RawValues[Value]
		if FoundEnumerator ~= nil then
			return FoundEnumerator
		else
			return false, string.format(INVALID_VALUE_ERROR, tostring(Value), typeof(Value), tostring(Enumeration))
		end
	end

	--[[**
		Returns an array of the enumerator items.
		@returns [t:array] An array of the items.
	**--]]
	function Internal.GetEnumeratorItems()
		local EnumItems = table.create(TotalEnums)
		local Length = 0

		for _, Value in pairs(RawValues) do
			Length += 1
			EnumItems[Length] = Value
		end

		return EnumItems
	end

	local NextIndex = next(EnumValues)
	if type(NextIndex) == "number" then
		for _, ValueName in ipairs(EnumValues :: {string}) do
			assert(not BLACKLISTED_VALUES[ValueName], string.format(CANNOT_USE_ERROR, tostring(ValueName)))
			assert(Internal[ValueName] == nil, string.format(ALREADY_USED_NAME_ERROR, ValueName, EnumName))
			assert(RawValues[ValueName] == nil, string.format(ALREADY_USED_VALUE_ERROR, ValueName, EnumName))

			local Value = newproxy(true)
			local Metatable = getmetatable(Value)
			local ValueString = string.format("%s.%s", EnumName, ValueName)

			function Metatable:__tostring()
				return ValueString
			end

			Metatable.__index = LockTable({
				Name = ValueName;
				Type = Enumeration;
				Value = ValueName;
			})

			Internal[ValueName] = Value
			RawValues[ValueName] = Value
			TotalEnums += 1
		end
	else
		for ValueName, RawValue in pairs(EnumValues) do
			assert(not BLACKLISTED_VALUES[ValueName], string.format(CANNOT_USE_ERROR, tostring(ValueName)))
			assert(Internal[ValueName] == nil, string.format(ALREADY_USED_NAME_ERROR, ValueName, EnumName))
			assert(RawValues[ValueName] == nil, string.format(ALREADY_USED_VALUE_ERROR, ValueName, EnumName))

			local Value = newproxy(true)
			local Metatable = getmetatable(Value)
			local ValueString = string.format("%s.%s", EnumName, ValueName)

			function Metatable:__tostring()
				return ValueString
			end

			Metatable.__index = LockTable({
				Name = ValueName;
				Type = Enumeration;
				Value = RawValue;
			})

			Internal[ValueName] = Value
			RawValues[RawValue] = Value
			TotalEnums += 1
		end
	end

	local Metatable = getmetatable(Enumeration)
	Metatable.__index = LockTable(Internal, EnumName)
	function Metatable:__tostring()
		return EnumName
	end

	return Enumeration
end

export type EnumeratorItem<Value> = {
	Name: string,
	Type: EnumeratorObject<Value>,
	Value: Value,
}

export type EnumeratorObject<Value> = {
	Cast: (Value: any) -> (EnumeratorItem<Value> | boolean, string?),
	FromRawValue: (RawValue: Value) -> EnumeratorItem<Value>?,
	GetEnumeratorItems: () -> {EnumeratorItem<Value>},
	IsEnumValue: (Value: any) -> boolean,
}

-- If you wish to use the above types to define an enum, you can do it as such:
--[[

local enumerator = require("enumerator")
type EnumeratorItem<Value> = enumerator.EnumeratorItem<Value>

export type RunServiceEvent = {
	Heartbeat: EnumeratorItem<string>,
	RenderStepped: EnumeratorItem<string>,
	Stepped: EnumeratorItem<string>,
} & enumerator.EnumeratorObject<string>

local RunServiceEvent: RunServiceEvent = enumerator("RunServiceEvent", {"Heartbeat", "RenderStepped", "Stepped"}) :: RunServiceEvent
return RunServiceEvent

--]]

return Enumerator
