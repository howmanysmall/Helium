local function DeepCopyTable(Table)
	local NewTable = table.create(#Table)
	for Index, Value in next, Table do
		if type(Value) == "table" then
			NewTable[Index] = DeepCopyTable(Value)
		else
			NewTable[Index] = Value
		end
	end

	return NewTable
end

return DeepCopyTable
