local WriteFmt = require(script.Parent.WriteFmt)

local Formatter = {}
Formatter.ClassName = "Formatter"
Formatter.__index = Formatter

function Formatter.new()
	return setmetatable({
		_Buffer = {};
		_Display = "";
		_Indentation = "";
		_IndentLevel = 0;
		_IsLocked = false;
		_StartOfLine = true;
	}, Formatter)
end

function Formatter:AsString()
	return self._Display
end

function Formatter:AsTuple()
	return table.unpack(self._Buffer)
end

function Formatter:AddTable(Table)
	table.insert(self._Buffer, Table)
	return self
end

function Formatter:Lock()
	self._IsLocked = true
	return self
end

function Formatter:Unlock()
	self._IsLocked = false
	return self
end

function Formatter:AddToBuffer(Value)
	if self._IsLocked == false then
		if type(Value) == "string" and type(self._Buffer[#self._Buffer]) == "string" then
			self._Buffer[#self._Buffer] ..= Value
		else
			table.insert(self._Buffer, Value)
		end
	end

	return self
end

function Formatter:Indent()
	self._IndentLevel += 1
	self._Indentation = string.rep("    ", self._IndentLevel)
	return self
end

function Formatter:Unindent()
	self._IndentLevel = math.max(0, self._IndentLevel - 1)
	self._Indentation = string.rep("    ", self._IndentLevel)
	return self
end

function Formatter:Write(Template, ...)
	WriteFmt(self, Template, ...)
	return self
end

function Formatter:WriteLine(Template, ...)
	WriteFmt(self, Template, ...)
	self:AddToBuffer("\n")
	self._Display ..= "\n"
	self._StartOfLine = true
	return self
end

function Formatter:WriteLineRaw(Value)
	self:WriteRaw(Value):AddToBuffer("\n")
	self._Display ..= "\n"
	self._StartOfLine = true
	return self
end

function Formatter:WriteRaw(Value)
	if #Value > 0 then
		if self._StartOfLine and #self._Indentation > 0 then
			self._StartOfLine = false

			self:AddToBuffer(self._Indentation)
			self._Display ..= self._Indentation
		end

		self._StartOfLine = false

		self:AddToBuffer(Value)
		self._Display ..= Value
	end

	return self
end

return Formatter
