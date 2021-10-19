local InstanceProperties = require(script.Parent.Utility.InstanceProperties)
local Symbol = require(script.Parent.Utility.Symbol)

--[=[
	@within Helium
	@prop Children ChildrenSymbol
	@tag Symbol
	This is a Symbol used to indicate the children for an Instance created using `Helium.Make`.
]=]
local MakeChildren = Symbol("Children")

local Make = {}
Make.Children = MakeChildren

export type Children = typeof(MakeChildren)

type GenericTable = {[any]: any}
type Properties = {[string | Children]: any}

--[=[
	This is a function similar to `Fusion.New` for creating Instances. While I don't personally suggest it,
	it is here if you want to use it. The `Parent` property is always set last if it exists in the table.

	```lua
	local Frame: Frame = Helium.Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5);
		Position = UDim2.fromScale(0.5, 0.5);
		Size = UDim2.fromOffset(140, 40);

		[Helium.Children] = {
			Helium.Make("TextButton", {
				Size = UDim2.fromScale(1, 1);
				Text = "Hello World!";
				Activated = function()
					print("Button was activated!")
				end;
			});
		};
	})

	Frame:Destroy()
	```

	@within Helium
	@function Make
	@tag Utility

	@param ClassName T -- The ClassName of the Instance you are creating.
	@param Properties {[string]: any, [Children]?: {Instance}}, -- The properties of the Instance you are creating.
	@return Instance<T> -- The created Instance.
]=]
function Make.Make(ClassName: string, Properties: Properties): Instance
	local Children = Properties[MakeChildren]
	local Parent = Properties.Parent
	local DefaultProperties = InstanceProperties[ClassName]

	if DefaultProperties then
		for PropertyName, PropertyValue in next, DefaultProperties do
			if Properties[PropertyName] == nil then
				Properties[PropertyName] = PropertyValue
			end
		end
	end

	local Object = Instance.new(ClassName)
	for Property, Value in next, Properties :: GenericTable do
		if Property == MakeChildren or Property == "Parent" then
			continue
		end

		local InstanceProperty = Object[Property]
		if typeof(InstanceProperty) == "RBXScriptSignal" then
			InstanceProperty:Connect(Value)
		else
			Object[Property] = Value
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

local Metatable = {}
function Metatable:__call(ClassName: string, Properties: Properties)
	return self.Make(ClassName, Properties)
end

return setmetatable(Make, Metatable)
