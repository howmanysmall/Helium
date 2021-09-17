local t = require(script.t)
local tPlus = {}

function tPlus.Enumeration(Enumeration)
	assert(t.userdata(Enumeration))
	return Enumeration.Cast
end

return setmetatable(tPlus, {__index = t})
