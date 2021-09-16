local t = {}

local function primitive(typeName)
	return function(value)
		local valueType = typeof(value)
		if valueType == typeName then
			return true
		else
			return false, string.format("%s expected, got %s", typeName, valueType)
		end
	end
end

t.callback = primitive("function")
t.number = primitive("number")
t.string = primitive("string")
t.table = primitive("table")

function t.integer(value)
	local success, errMsg = t.number(value)
	if not success then
		return false, errMsg or ""
	end

	if value % 1 == 0 then
		return true
	else
		return false, string.format("integer expected, got %s", value)
	end
end

function t.tuple(...)
	local checks = {...}
	return function(...)
		local args = {...}
		for i, check in ipairs(checks) do
			local success, errMsg = check(args[i])
			if success == false then
				return false, string.format("Bad tuple index #%s:\n\t%s", i, errMsg or "")
			end
		end

		return true
	end
end

function t.keys(check)
	assert(t.callback(check))
	return function(value)
		local tableSuccess, tableErrMsg = t.table(value)
		if tableSuccess == false then
			return false, tableErrMsg or ""
		end

		for key in pairs(value) do
			local success, errMsg = check(key)
			if success == false then
				return false, string.format("bad key %s:\n\t%s", tostring(key), errMsg or "")
			end
		end

		return true
	end
end

function t.values(check)
	assert(t.callback(check))
	return function(value)
		local tableSuccess, tableErrMsg = t.table(value)
		if tableSuccess == false then
			return false, tableErrMsg or ""
		end

		for key, val in pairs(value) do
			local success, errMsg = check(val)
			if success == false then
				return false, string.format("bad value for key %s:\n\t%s", tostring(key), errMsg or "")
			end
		end

		return true
	end
end

local arrayKeysCheck = t.keys(t.integer)

function t.array(check)
	assert(t.callback(check))
	local valuesCheck = t.values(check)

	return function(value)
		local keySuccess, keyErrMsg = arrayKeysCheck(value)
		if keySuccess == false then
			return false, string.format("[array] %s", keyErrMsg or "")
		end

		-- # is unreliable for sparse arrays
		-- Count upwards using ipairs to avoid false positives from the behavior of #
		local arraySize = 0

		for _ in ipairs(value) do
			arraySize = arraySize + 1
		end

		for key in pairs(value) do
			if key < 1 or key > arraySize then
				return false, string.format("[array] key %s must be sequential", tostring(key))
			end
		end

		local valueSuccess, valueErrMsg = valuesCheck(value)
		if not valueSuccess then
			return false, string.format("[array] %s", valueErrMsg or "")
		end

		return true
	end
end

local callbackArray = t.array(t.callback)
function t.union(...)
	local checks = {...}
	assert(callbackArray(checks))

	return function(value)
		for _, check in ipairs(checks) do
			if check(value) then
				return true
			end
		end

		return false, "bad type for union"
	end
end

return t
