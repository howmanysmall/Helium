local Enums = require(script.Parent.Parent.Enums)
local Janitor = require(script.Parent.Parent.Janitor)
local _Store = require(script.Parent.Parent.Store)

type Store = _Store.Store
local RedrawBinding: Enums.RedrawBinding = Enums.RedrawBinding :: Enums.RedrawBinding

--[=[
	@class BaseComponent
]=]
local BaseComponent = {}
BaseComponent.ClassName = "BaseComponent"
BaseComponent.__index = BaseComponent

--[=[
	@prop Janitor Janitor
	@within BaseComponent
	The component's Janitor. You can add whatever you want cleaned up on `:Destroy()` to this.

	```lua
	local PrintOnDestroy = Helium.Component.Extend("PrintOnDestroy")
	function PrintOnDestroy:Constructor(Message: string)
		self.Janitor:Add(function()
			print(Message)
		end, true)
	end

	PrintOnDestroy.new("I was destroyed!"):Destroy() -- Prints "I was destroyed!"
	```
]=]

--[=[
	@prop GetReducedState () -> {[string]: string}
	@within BaseComponent
	This function returns the reduced state of the component's store.
]=]

--[=[
	@prop QueueRedraw () -> ()
	@within BaseComponent
	This function queues a redraw of the component.

	```lua
	local CoinsDisplay = Helium.Component.Extend("CoinsDisplay")
	function CoinsDisplay:Constructor(Parent: Instance)
		self.Coins = 0
		self.Gui = self.Janitor:Add(Helium.Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.fromScale(0.5, 0.5);
			Size = UDim2.fromScale(0.5, 0.5);

			Font = Enum.Font.Gotham;
			Text = "Coins: 0";
			TextColor3 = Color3.new(1, 1, 1);
			TextSize = 24;

			Parent = Parent;
		}), "Destroy")
	end

	function CoinsDisplay:AddCoin()
		self.Coins += 1
		self.QueueRedraw() -- Queues the Component to be redrawn.
	end

	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw()
		self.Gui.Text = "Coins: " .. self.Coins
	end

	local MyCoinsDisplay = CoinsDisplay.new(Parent) -- Shows a TextLabel with the Text == "Coins: 0".
	MyCoinsDisplay:AddCoin() -- Now it says "Coins: 1"
	```
]=]

--[=[
	@prop ClassName string
	@within BaseComponent
	The Component's ClassName, which is assigned from the first argument of `Component.Extend`.
]=]

--[=[
	@prop RedrawBinding RedrawBinding
	@within BaseComponent
	The Component's RedrawBinding. This is used to determine when the Component's `:Redraw()` function is called.
]=]

--[=[
	@prop Reduction {[string]: string}?
	@within BaseComponent
	The reduction of the store. If this exists, it'll be passed as the first argument of `:Redraw()`.
]=]

--[=[
	The Component's Constructor function. This version is for store-less components. This should be overwritten.

	```lua
	local CoinsDisplay = Helium.Component.Extend("CoinsDisplay")
	function CoinsDisplay:Constructor(Parent: Instance)
		self.Gui = self.Janitor:Add(Helium.Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.fromScale(0.5, 0.5);
			Size = UDim2.fromScale(0.5, 0.5);

			Font = Enum.Font.Gotham;
			Text = "Coins: 1";
			TextColor3 = Color3.new(1, 1, 1);
			TextSize = 24;

			Parent = Parent;
		}), "Destroy")
	end

	CoinsDisplay.new(Parent) -- Shows a TextLabel with the Text == "Coins: 1".
	```

	@param ... any? -- The arguments you are creating the Component with.
]=]

--[=[
	The Component's Constructor function. This should be overwritten.

	```lua
	local CoinsDisplay = Helium.Component.Extend("CoinsDisplay")

	function CoinsDisplay:Constructor(Store, Parent: Instance)
		self.Store = Store
		self.Gui = self.Janitor:Add(Helium.Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.fromScale(0.5, 0.5);
			Size = UDim2.fromScale(0.5, 0.5);

			Font = Enum.Font.Gotham;
			Text = "Coins: 0";
			TextColor3 = Color3.new(1, 1, 1);
			TextSize = 24;

			Parent = Parent;
		}), "Destroy")
	end

	type CoinsReduction = {Coins: number}

	CoinsDisplay.Reduction = {Coins = "GuiData.Coins"}
	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw(CoinsReduction: CoinsReduction)
		self.Gui.Text = "Coins: " .. CoinsReduction.Coins
	end

	local CoinsStore = Helium.Store.new(function(Action, GetState, SetState)
		if Action.Type == "AddCoin" then
			local Coins = GetState("GuiData", "Coins")
			SetState("GuiData", "Coins", Coins + 1)
		end
	end, {GuiData = {Coins = 0}})

	local MyCoinsDisplay = CoinsDisplay.new(CoinsStore, Parent) -- Shows a TextLabel with the Text == "Coins: 0".
	for _ = 1, 10 do
		task.wait(1)
		CoinsStore:Fire({Type = "AddCoin"})
	end

	MyCoinsDisplay:Destroy()
	```

	@param Store Store? -- The store to use for this component.
	@param ... any? -- The arguments you are creating the Component with.
]=]
function BaseComponent:Constructor(__Store: Store?, ...)
	local _ = {...}
end

--[=[
	The Component's Redraw function. This can be overwritten if you need it to be.

	```lua
	local CoinsDisplay = Helium.Component.Extend("CoinsDisplay")
	function CoinsDisplay:Constructor(Parent: Instance)
		self.Coins = 0
		self.Gui = self.Janitor:Add(Helium.Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.fromScale(0.5, 0.5);
			Size = UDim2.fromScale(0.5, 0.5);

			Font = Enum.Font.Gotham;
			Text = "Coins: 0";
			TextColor3 = Color3.new(1, 1, 1);
			TextSize = 24;

			Parent = Parent;
		}), "Destroy")
	end

	function CoinsDisplay:AddCoin()
		self.Coins += 1
		self.QueueRedraw()
	end

	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw()
		self.Gui.Text = "Coins: " .. self.Coins
	end

	local MyCoinsDisplay = CoinsDisplay.new(Parent) -- Creates a TextLabel under Parent with the Text saying "Coins: 0"
	MyCoinsDisplay:AddCoin() -- Calls :Redraw() and now the TextLabel says "Coins: 1"
	```

	@param ReducedState {[any]: any}? -- The reduced state if `BaseComponent.Reduction` exists.
	@param DeltaTime number -- The DeltaTime since the last frame.
	@param WorldDeltaTime number? -- The world delta time since the last frame. This only exists when `RedrawBinding` == `Stepped`.
]=]
function BaseComponent:Redraw(__ReducedState: {[any]: any}?, __DeltaTime: number?, __DeltaTime2: number?) end

--[=[
	Destroys the Component and its Janitor.

	:::warning
	This renders the component completely unusable. You wont' be able to call any further methods on it.
	:::
]=]
function BaseComponent:Destroy()
	self.Janitor:Destroy()
	setmetatable(self, nil :: any)
end

function BaseComponent:__tostring()
	return "BaseComponent"
end

--[=[
	The constructor of the Component. This version is for store-less components.

	```lua
	local ValuePrinter = Helium.Component.Extend("ValuePrinter")
	function ValuePrinter:Constructor(Value: any)
		print("ValuePrinter:Constructor was constructed with:", Value)
	end

	ValuePrinter.new(1):Destroy() -- prints "ValuePrinter:Constructor was constructed with: 1"
	```

	@param ... any? -- The arguments you want to pass to the Component's constructor.
	@return Component<T>
]=]

--[=[
	The constructor of the Component.

	```lua
	local ValuePrinterWithStore = Helium.Component.Extend("ValuePrinterWithStore")
	function ValuePrinterWithStore:Constructor(Store, Value: any)
		self.Store = Store
		print("ValuePrinterWithStore:Constructor was constructed with:", Value)
	end

	ValuePrinterWithStore.new(Helium.Store.new(function() end, {}), 1):Destroy() -- prints "ValuePrinterWithStore:Constructor was constructed with: 1"
	```

	@param Store Store? -- The store to use for this component.
	@param ... any? -- The extra arguments you want to pass to the Component's constructor.
	@return Component<T>
]=]
function BaseComponent.new()
	local self = setmetatable({}, BaseComponent)
	self.RedrawBinding = RedrawBinding.Heartbeat
	self.Janitor = Janitor.new()
	self.Reduction = {Key = "Value"}

	self.GetReducedState = function()
		return {}
	end

	self.QueueRedraw = function() end
	return self
end

export type BaseComponent = typeof(BaseComponent.new())
return BaseComponent
