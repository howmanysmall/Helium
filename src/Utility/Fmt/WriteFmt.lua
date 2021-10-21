local Debug = require(script.Parent.Parent.Debug)

local KEYWORDS = {
	["and"] = true;
	["break"] = true;
	["do"] = true;
	["else"] = true;
	["elseif"] = true;
	["end"] = true;
	["false"] = true;
	["for"] = true;
	["function"] = true;
	["if"] = true;
	["in"] = true;
	["local"] = true;
	["nil"] = true;
	["not"] = true;
	["or"] = true;
	["repeat"] = true;
	["return"] = true;
	["then"] = true;
	["true"] = true;
	["until"] = true;
	["while"] = true;
}

local function IsValidVariable(Variable)
	return Variable ~= "" and KEYWORDS[Variable] == nil and string.find(Variable, "^[_%a]+[_%w]+$") ~= nil
end

local function Amountify(Amount)
	return Amount == 1 and "is " .. Amount or "are " .. Amount
end

local function Pluralize(Amount, String)
	return Amount == 1 and String or String .. "s"
end

local function LeadingZeros(Formatter, Argument, ArgumentLeadingZeros)
	if type(Argument) ~= "number" then
		Formatter:WriteRaw(tostring(Argument))
	else
		local StringArgument = tostring(Argument)
		Formatter:WriteRaw(string.rep("0", ArgumentLeadingZeros - #StringArgument) .. StringArgument)
	end
end

local function Width(Formatter, Argument, ArgumentWidth)
	Argument = tostring(Argument)
	Formatter:WriteRaw(Argument .. string.rep(" ", ArgumentWidth - #Argument))
end

local function DebugTable(Formatter, Table)
	Formatter:WriteRaw("{")

	for Key, Value in next, Table do
		Formatter:Write("[{:?}] = {:?}", Key, Value)

		if next(Table, Key) ~= nil then
			Formatter:WriteRaw(", ")
		end
	end

	Formatter:WriteRaw("}")
end

local function DebugTableExtended(Formatter, Table)
	-- Special case for empty tables.
	if next(Table) == nil then
		return Formatter:WriteRaw("{}")
	end

	Formatter:WriteLineRaw("{"):Indent()

	for Key, Value in next, Table do
		Formatter:Write("[{:?}] = {:#?}", Key, Value)
		if next(Table, Key) ~= nil then
			Formatter:WriteRaw(",")
		end

		Formatter:WriteLine("")
	end

	Formatter:Unindent():WriteRaw("}")
end

local function DebugImpl(Formatter, Argument, IsExtendedForm)
	local ArgumentType = typeof(Argument)

	if ArgumentType == "string" then
		Formatter:WriteRaw(string.format("%q", Argument))
	elseif ArgumentType == "table" then
		local ArgumentMetatable = getmetatable(Argument)

		if ArgumentMetatable ~= nil and ArgumentMetatable.__FmtDebug ~= nil then
			ArgumentMetatable.__FmtDebug(Argument, Formatter, IsExtendedForm)
		else
			Formatter:AddTable(Argument):Lock()

			if IsExtendedForm then
				DebugTableExtended(Formatter, Argument)
			else
				DebugTable(Formatter, Argument)
			end

			Formatter:Unlock()
		end
	elseif ArgumentType == "Instance" then
		Formatter:WriteRaw(Debug.DirectoryToString(Argument))
	else
		Formatter:WriteRaw(tostring(Argument))
	end
end

local function Precision(Formatter, Argument, ArgumentPrecision)
	if type(Argument) ~= "number" then
		Formatter:WriteRaw(tostring(Argument))
	else
		Formatter:WriteRaw(string.format("%." .. ArgumentPrecision .. "f", tostring(Argument)))
	end
end

local function Sign(Formatter, Argument)
	if type(Argument) ~= "number" then
		Formatter:WriteRaw(tostring(Argument))
	else
		Formatter:WriteRaw(Argument >= 0 and "+" .. tostring(Argument) or tostring(Argument))
	end
end

local function Interpolate(Formatter, Parameter, Writer)
	local FormatParameterStart = string.find(Parameter, ":")
	local LeftSide = string.sub(Parameter, 1, FormatParameterStart and FormatParameterStart - 1 or -1)
	local RightSide = FormatParameterStart ~= nil and string.sub(Parameter, FormatParameterStart + 1 or -1) or nil

	local PositionalParameter = tonumber(LeftSide)
	local IsRegularParameter = LeftSide == ""

	local Argument
	if PositionalParameter ~= nil then
		if PositionalParameter < 0 or PositionalParameter % 1 ~= 0 then
			error("Invalid positional parameter `" .. PositionalParameter .. "`.", 4)
		end

		if PositionalParameter + 1 > #Writer.Arguments then
			error("Invalid positional argument " .. PositionalParameter .. " (there " .. Amountify(#Writer.Arguments) .. " " .. Pluralize(#Writer.Arguments, "argument") .. "). Note: Positional arguments are zero-based.", 4)
		end

		Writer.BiggestPositionalParameter = math.max(Writer.BiggestPositionalParameter, PositionalParameter + 1)
		Argument = Writer.Arguments[PositionalParameter + 1]
	elseif IsRegularParameter then
		local CurrentArgument = Writer.CurrentArgument + 1
		Writer.CurrentArgument = CurrentArgument
		Argument = Writer.Arguments[CurrentArgument]
	else
		if not IsValidVariable(LeftSide) then
			error("Invalid named parameter `" .. LeftSide .. "`.", 4)
		end

		if Writer.NamedParameters == nil or Writer.NamedParameters[LeftSide] == nil then
			error("There is no named argument `" .. LeftSide .. "`.", 4)
		end

		Writer.HadNamedParameter = true
		Argument = Writer.NamedParameters[LeftSide]
	end

	if RightSide ~= nil then
		local Number = tonumber(RightSide)
		local FirstCharacter = string.sub(RightSide, 1, 1)
		local NumberAfterFirstCharacter = tonumber(string.sub(RightSide, 2))

		if RightSide == "?" then
			DebugImpl(Formatter, Argument, false)
		elseif RightSide == "#?" then
			DebugImpl(Formatter, Argument, true)
		elseif RightSide == "+" then
			Sign(Formatter, Argument)
		elseif FirstCharacter == "." and NumberAfterFirstCharacter ~= nil then
			Precision(Formatter, Argument, NumberAfterFirstCharacter)
		elseif FirstCharacter == "0" and NumberAfterFirstCharacter ~= nil then
			LeadingZeros(Formatter, Argument, NumberAfterFirstCharacter)
		elseif Number ~= nil and Number > 0 then
			Width(Formatter, Argument, Number)
		else
			error("Unsupported format parameter `" .. RightSide .. "`.", 4)
		end
	else
		Formatter:WriteRaw(tostring(Argument))
	end
end

local function ComposeWriter(Arguments)
	local LastArgument = Arguments[#Arguments]

	return {
		Arguments = Arguments;
		BiggestPositionalParameter = 0;
		CurrentArgument = 0;
		HadNamedParameter = false;
		NamedParameters = type(LastArgument) == "table" and LastArgument or nil;
	}
end

local function WriteFmt(Formatter, Template, ...)
	local Index = 1
	local Writer = ComposeWriter({...})

	while Index <= #Template do
		local Brace = string.find(Template, "[{}]", Index)

		-- There are no remaining braces in the string, so we can write the
		-- rest of the string to the formatter.
		if Brace == nil then
			Formatter:WriteRaw(string.sub(Template, Index))
			break
		end

		local BraceCharacter = string.sub(Template, Brace, Brace)
		local CharacterAfterBrace = string.sub(Template, Brace + 1, Brace + 1)

		if CharacterAfterBrace == BraceCharacter then
			-- This brace starts a literal '{', written as '{{'.

			Formatter:WriteRaw(BraceCharacter)
			Index = Brace + 2
		else
			if BraceCharacter == "}" then
				error("Unmatched '}'. If you intended to write '}', you can escape it using '}}'.", 3)
			else
				local CloseBrace = string.find(Template, "}", Index + 1)

				if CloseBrace == nil then
					error("Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.", 3)
				else
					-- If there are any unwritten characters before this
					-- parameter, write them to the formatter.
					if Brace - Index > 0 then
						Formatter:WriteRaw(string.sub(Template, Index, Brace - 1))
					end

					local FormatSpecifier = string.sub(Template, Brace + 1, CloseBrace - 1)
					Interpolate(Formatter, FormatSpecifier, Writer)
					Index = CloseBrace + 1
				end
			end
		end
	end

	local Length = #Writer.Arguments
	local NumberOfArguments = Writer.HadNamedParameter and Length - 1 or Length

	if Writer.CurrentArgument > NumberOfArguments then
		error(Writer.CurrentArgument .. " " .. Pluralize(Writer.CurrentArgument, "parameter") .. " found in template string, but there " .. Amountify(NumberOfArguments) .. " " .. Pluralize(NumberOfArguments, "argument") .. ".", 3)
	end

	if NumberOfArguments > Writer.CurrentArgument and Writer.BiggestPositionalParameter < NumberOfArguments then
		error(Writer.CurrentArgument .. " " .. Pluralize(Writer.CurrentArgument, "parameter") .. " found in template string, but there " .. Amountify(NumberOfArguments) .. " " .. Pluralize(NumberOfArguments, "argument") .. ".", 3)
	end
end

return WriteFmt
