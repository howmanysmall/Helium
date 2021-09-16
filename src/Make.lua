local Symbol = require(script.Parent.Utility.Symbol)
local MakeChildren = Symbol("Children")

local Make = {}
Make.Children = MakeChildren

type GenericTable = {[any]: any}
type Properties = {[string]: any}

function Make.Make(ClassName: string, Properties: Properties)
	local Children = Properties[MakeChildren]
	local Parent = Properties.Parent

	local Object = Instance.new(ClassName)
	for Property, Value in pairs(Properties :: GenericTable) do
		if Property ~= MakeChildren and Property ~= "Parent" then
			local InstanceProperty = Object[Property]
			if typeof(InstanceProperty) == "RBXScriptSignal" then
				InstanceProperty:Connect(Value)
			else
				Object[Property] = Value
			end
		end
	end

	if Children then
		for _, Child in ipairs(Children) do
			Child.Parent = Object
		end
	end

	Object.Parent = Parent
	return Object
end

return setmetatable(Make, {
	__call = function(_, ClassName: string, Properties: Properties)
		return Make.Make(ClassName, Properties)
	end;
})
