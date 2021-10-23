local RunService = game:GetService("RunService")
local Debug = require(script.Parent.Utility.Debug)
local Enums = require(script.Parent.Enums)
local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local Janitor = require(script.Parent.Janitor)
local Signal = require(script.Parent.Utility.Signal)
local Store = require(script.Parent.Store)

local _BaseComponent = require(script.BaseComponent)

local RedrawBinding: Enums.RedrawBinding = Enums.RedrawBinding :: Enums.RedrawBinding

-- The queue could probably be optimized by making it a heap.
local BindingHandlerActive = {}

local RedrawComponent
local function UpdateRedrawComponent()
	if GlobalConfiguration.Get("ProfileRedraw") then
		function RedrawComponent(Component, ...)
			local ComponentName = tostring(Component)

			debug.profilebegin("WillRedraw-" .. ComponentName)
			local WillRedraw = Component.WillRedraw
			if WillRedraw then
				WillRedraw:Fire(Component, ...)
			end

			debug.profileend()

			debug.profilebegin("Redraw-" .. ComponentName)
			Component:Redraw(Component.GetReducedState(), ...)
			debug.profileend()

			debug.profilebegin("DidRedraw-" .. ComponentName)
			local DidRedraw = Component.DidRedraw
			if DidRedraw then
				DidRedraw:Fire(Component, ...)
			end

			debug.profileend()
		end
	else
		function RedrawComponent(Component, ...)
			local WillRedraw = Component.WillRedraw
			if WillRedraw then
				WillRedraw:Fire(Component, ...)
			end

			Component:Redraw(Component.GetReducedState(), ...)
			local DidRedraw = Component.DidRedraw
			if DidRedraw then
				DidRedraw:Fire(Component, ...)
			end
		end
	end
end

UpdateRedrawComponent()

local function GetBindingHandler(Queue)
	return function(...)
		local Component = next(Queue)
		if Component then
			BindingHandlerActive[Queue] = true
			local RequeueNextFrame = {}
			local Handled = {}

			while Component do
				Queue[Component] = nil
				if Handled[Component] then
					RequeueNextFrame[Component] = true
				else
					Handled[Component] = true
					task.spawn(RedrawComponent, Component, ...)
				end

				Component = next(Queue)
			end

			BindingHandlerActive[Queue] = false
			for RequeueComponent in next, RequeueNextFrame do
				Queue[RequeueComponent] = true
			end
		end
	end
end

local RenderStepQueue = setmetatable({}, {__mode = "k"})
local RenderStepTwiceQueue = setmetatable({}, {__mode = "k"})

if RunService:IsClient() then
	RunService:BindToRenderStep("HeliumRedraw", Enum.RenderPriority.Last.Value + 1, GetBindingHandler(RenderStepQueue))
	RunService:BindToRenderStep("HeliumSecondRedraw", Enum.RenderPriority.Last.Value + 2, GetBindingHandler(RenderStepTwiceQueue))
end

local HeartbeatQueue = setmetatable({}, {__mode = "k"})
RunService.Heartbeat:Connect(GetBindingHandler(HeartbeatQueue))

local SteppedQueue = setmetatable({}, {__mode = "k"})
if RunService:IsRunning() then
	RunService.Stepped:Connect(GetBindingHandler(SteppedQueue))
end

--[=[
	Components are classes that can be extended and built upon. Like [Roact](https://github.com/Roblox/roact/ "Roact by Roblox") components, they represent a reusable object that you can create using constructors.

	You can create and destroy Components using standard Luau class methods.

	```lua
	local AwesomeComponent = require("AwesomeComponent")
	local Object = AwesomeComponent.new()
	Object:Destroy()
	```

	To declare our first Component class, Helium provides the following API:

	```lua
	local Helium = require(ReplicatedStorage.Helium)
	local MyComponent = Helium.Component.Extend("MyComponent")
	```

	When a new Component object is created using `MyComponent.new()`, the `Constructor` function is called with the same arguments passed through `new`. Here is a simple printer component:

	```lua
	local Printer = Helium.Component.Extend("Printer")

	function Printer:Constructor(Message: string)
		self.Message = Message
	end

	function Printer:Print()
		print(self.Message)
	end

	local MyPrinter = Printer.new("Hello, World!")
	MyPrinter:Print() -- Hello, World!
	MyPrinter:Destroy() -- ( Currently has no effect, but is still a thing we can do )
	```

	While this has nothing to do with UI, it is a good example of the object-oriented structure we will be using for the rest of the tutorial.

	### UI components

	Helium gives total control over what a component does when it is constructed. You can create as many Gui objects as you like, and update them however you like.
	The information we actually display to the user can be controlled using the Component class' `:Redraw()` method.

	:::warning
	Never ever call `:Redraw()` directly. This method is automatically called next `RenderStepped`, `Heartbeat` or `Stepped` event depending on what was set as the `RedrawBinding`.
	:::

	To queue a redraw on the next frame, use `self.QueueRedraw()` instead. This is an anonymous, idempotent function that tells Helium to call `:Redraw()` automatically on the next `RedrawBinding` step.
	It should be noted that when a component is constructed, Helium automatically calls `self.QueueRedraw()` once.

	We can control whether `:Redraw()` is called on by using the static `RedrawBinding` property of components. This is an Enum which you can access by doing `Helium.RedrawBinding.`.

	Let's say we wanted to create a `CoinsDisplay` component, which draws some representation of how many coins a player has.

	```lua
	local Helium = require(ReplicatedStorage.Helium)
	local CoinsDisplay = Helium.Component.Extend("CoinsDisplay")

	function CoinsDisplay:Constructor()
		self.Coins = 0

		self.Gui = Instance.new("ScreenGui")
		self.CoinsLabel = Instance.new("TextLabel")
		self.CoinsLabel.Size = UDim2.fromOffset(100, 100)
		self.CoinsLabel.Parent = self.Gui

		self.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	function CoinsDisplay:AddCoin()
		self.Coins += 1
		self.QueueRedraw()
	end

	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw()
		self.CoinsLabel.Text = self.Coins
	end

	-- Add 1 coin every second
	local MyCoinsDisplay = CoinsDisplay.new()
	while true do
		task.wait(1)
		MyCoinsDisplay:AddCoin()
	end
	```

	![ComponentExample](https://i.imgur.com/QqGKiJs.gif)

	As you can see this component functions as intended. However, there is one small problem: What would happen if we were to destroy the CoinDisplay component?

	```lua
	local MyCoinsDisplay = CoinsDisplay.new()
	MyCoinsDisplay:AddCoin()
	MyCoinsDisplay:Destroy()
	```

	![Bad](https://github.com/headjoe3/Rocrastinate/blob/master/docs/introduction_coins_example2.png?raw=true)

	Now, wait a minute... why is the Gui still appearing? Furthermore, why are we seeing the text "Label" instead of the number 1 or 0?
	While it's true that the state of `self.Coins` should have been set to 1 after calling `:AddCoin()`, the `MyCoinsDisplay` object was destroyed before the next `Heartbeat` frame started.

	Thus, even though `self.QueueRedraw()` was called, this line of code never ran, as Helium automatically unbinds queued redraws once a component is destroyed:

	```lua
	function CoinsDisplay:Redraw()
		self.CoinsLabel.Text = self.Coins
	end
	```

	Since the Text property was never set, it was left with the default value of all TextLabel objects: "Label".

	We also have one other problem: the `Gui` and `coinsLabel` objects are still parented to PlayerGui when `CoinsDisplay:Destroy()` is called. While we could define a destructor and remove them there:

	```lua
	function CoinsDisplay:Destroy() -- Note: Do not do this
		self.Gui:Destroy()
	end
	```

	:::warning
	**Never** overwrite the `:Destroy` method, doing so all but guarantees you'll have a major problem down the line.
	:::

	The problem is that keeping track of every every object that is created can become unmanageable, especially after creating a large number of components

	```lua
	function MyApp:Constructor()
		self.MyComponentA = ComponentA.new(...)
		self.MyComponentB = ComponentB.new(...)
		self.MyComponentC = ComponentC.new(...)
		self.MyFrame = Instance.new("Frame")
	end

	function MyApp:Destroy() -- Note: Do not do this
		self.MyComponentA:Destroy()
		self.MyComponentB:Destroy()
		self.MyComponentC:Destroy()
		self.MyFrame:Destroy()
	end
	```

	Seems like a lot of work, right? Now, if you want to add or remove elements from your UI Component, you have to also add or remove it from the Destructor. If you forget to do this, bad things can happen.
	Furthermore, what if components/Gui Objects are created during `MyApp:Redraw()` rather than `MyComponent:Constructor()`? Now you have to use an if statement to conditionally check if the object even
	exists, and if it does, destroy it in the destructor.

	Helium utilizes the Janitor object for Component destructors. You can read more about it on the [Janitor documentation site](https://howmanysmall.github.io/Janitor/).

	Going back to the CoinsDisplay example, our `Janitor` object can be utilized in the constructor as follows:

	```lua
	function CoinsDisplay:Constructor()
		self.Coins = 0

		self.Gui = self.Janitor:Add(Instance.new("ScreenGui"), "Destroy")
		self.CoinsLabel = self.Janitor:Add(Instance.new("TextLabel"), "Destroy")
		self.CoinsLabel.Size = UDim2.fromOffset(100, 100)
		self.CoinsLabel.Parent = self.Gui

		self.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	```

	`:Add()` is a special function that takes in an object that can be called. If the Janitor is given an Instance, then that instance will automatically be destroyed when the Component is destroyed.
	The first argument is meant for the object you are passing. The second argument is the either `true` for functions or a string for the name of the function to call. You can see the API for [Janitor:Add](https://howmanysmall.github.io/Janitor/api/Janitor#Add) for more information.
	When the Component is destroyed, the `:Destroy()` method of the Janitor will be called which in turn cleans up everything in the Janitor.

	----

	### Improving our Component class

	Now, I will attempt to explain some improvements that can be made to our `CoinDisplay` code.
	First of all, we don't actually need to create our gui objects until `:Redraw()` is called. For the sake of separation of concerns, it would be better to move that into the `:Redraw()` function.

	```lua
	function CoinsDisplay:Constructor()
		self.Coins = 0

		-- Note: self.QueueRedraw() is automatically called after the CoinsDisplay object is created
	end

	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw()
		-- This will run once on the first frame that our CoinsDisplay element is rendered (if it is rendered)
		if not self.Gui then
			self.Gui = self.Janitor:Add(Instance.new("ScreenGui"), "Destroy")
			self.CoinsLabel = self.Janitor:Add(Instance.new("TextLabel"), "Destroy")
			self.CoinsLabel.Size = UDim2.fromOffset(100, 100)
			self.CoinsLabel.Parent = self.Gui

			self.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		end

		self.CoinsLabel.Text = self.Coins
	end
	```

	See how much cleaner the constructor is? Now, when we want to locate the portion of code that draws what is displayed to the user, we need only look at the `:Redraw()` function.
	Secondly, we do not need to keep track of our CoinsLabel frame, as it is already parented to our Gui (we also do not need to give it to the Component's Janitor for that matter).

	```lua
	function CoinsDisplay:Redraw()
		if not self.Gui then
			self.Gui = self.Janitor:Add(Instance.new("ScreenGui"), "Destroy") -- Only the gui needs to be given to the janitor.

			local CoinsLabel = Instance.new("TextLabel")
			CoinsLabel.Name = "CoinsLabel"
			CoinsLabel.Size = UDim2.fromOffset(100, 100)
			CoinsLabel.Parent = self.Gui

			self.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		end

		self.Gui.CoinsLabel.Text = self.Coins -- Here we index gui instead of coinsLabel, I don't personally recommend this because it's extra indexing for no reason.
	end
	```

	---

	We deferred creation of our `self.Gui` object until `:Redraw()` is called by Helium. However, there is one small problem with our code:

	```lua
	self.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	```

	This `:WaitForChild()` is a yielding function. Yielding on a Redraw means our code could be subject to race conditions. In general, you should avoid yielding within `:Redraw()` wherever possible.
	Furthermore, it is not ideal to hardcode the parent in which our component's UI is placed. What if, for example, we wanted to nest a `CoinsDisplay` object inside of another menu? Let's define the
	parent in which we want to place the component as a parameter of the `CoinsDisplay` constructor:

	```lua
	function CoinsDisplay:Constructor(Parent: Instance)
		self.Coins = 0
		self.Parent = Parent
	end

	function CoinsDisplay:Redraw()
		if not self.Gui then
			...
			self.Gui.Parent = self.Parent
		end

		self.Gui.CoinsLabel.Text = self.Coins
	end
	```

	Now, when we create our component, we should provide it with a parent argument:

	```lua
	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Add 1 coin every second
	local MyCoinsDisplay = CoinsDisplay.new(PlayerGui)
	while true do
		task.wait(1)
		MyCoinsDisplay:AddCoin()
	end
	```

	There is one other thing that will make the code simpler: UI Templates. Because Helium gives us full control over how our GUI elements are created, we can place a template inside of our component's module:

	![example](https://github.com/headjoe3/Rocrastinate/blob/master/docs/introduction_coins_example3.png?raw=true)

	## Final Code

	Here is the final code for the CoinsDisplay module:

	```lua
	local Helium = require(ReplicatedStorage.Helium)
	local CoinsDisplay = Helium.Component.Extend("CoinsDisplay")

	function CoinsDisplay:Constructor(Parent: Instance)
		self.Coins = 0
		self.Parent = Parent
	end

	function CoinsDisplay:AddCoin()
		self.Coins += 1
		self.QueueRedraw()
	end

	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw()
		if not self.Gui then
			self.Gui = self.Janitor:Add(script.CoinsDisplayTemplate:Clone(), "Destroy")
			self.Gui.Parent = self.Parent
		end

		self.Gui.CoinsLabel.Text = "Coins: " .. self.Coins
	end

	return CoinsDisplay
	```

	And here is a LocalScript that utilizes the module:

	```lua
	local CoinsDisplay = require(ReplicatedStorage.CoinsDisplay)
	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Add 1 coin every second
	local MyCoinsDisplay = CoinsDisplay.new(PlayerGui)
	while true do
		task.wait(1)
		MyCoinsDisplay:AddCoin()
	end
	```

	![example](https://github.com/headjoe3/Rocrastinate/blob/master/docs/introduction_coins_example4.gif?raw=true)

	------

	# 1.2 Component State Reduction

	## The Observer Pattern

	In order to understand how we can re-draw our components based on store updates, we must first look at the way in which the Helium Store propogates updates

	As we saw in the last tutorial, reducers are given a special function `SetState()`, which mutates a value in the store.

	Technically, for the root reducer, the actual function `GetState()` passed to the reducer is `Store:GetState()`, and the actual function `SetState()` is `Store:SetState()`.

	What `Store:GetState(...KeyPath)` does is parse a provided series of string keys until a value is found in the store. If a key does not exist at a given path, the store will return `nil`. For the sake of mutation safety, the store will NOT directly return tables in the store when calling `Store:GetState(...)`; instead, tables will be deeply cloned, then returned.

	If you want to keep a table in the store that is directly mutable when it is retrieved using `get()`, you can create a pointer to it by wrapping it in a function:

	```lua
	local function CreateFenv(Value: any)
		return function()
			return Value
		end
	end

	local Table = {}
	Store:SetState("Table", CreateFenv(Table))

	---...

	local PointsToTable = Store:GetState("Table")
	print(Table == PointsToTable()) -- true
	```

	```cpp
	RbxInstance CreateFenv(void) : (RbxInstance Value)
	{
		return Value;
	}

	GenericDictionary Table = table();
	Store::SetState(L"Table", CreateFenv:(Table));

	// ...

	void PointsToTable = Store::GetState @ Table;
	print(Table == PointsToTable()); // true
	```

	Whereas `GetState()` does more than directly returning the value in the store, the function `SetState()` also does more than just mutating the value in the store. When `store:SetState()` is called, it keeps track of each key that was changed, and notifies any observers of the change.

	We can observe store changes using the `Store:Connect("Path.To.Key", Function)` function. Unlike `GetState` and `SetState`, the key path is denoted using the dot notation. Subscribing to the empty string `""` will observe all store changes.

	Example:

	```lua
	local Store = Helium.Store.new(function()
	end, {PlayerStats = {Coins = 0}})

	local Disconnect = Store:Connect("PlayerStats.Coins", function()
		local Coins = Store:GetState("PlayerStats.Coins")
		print("You have", coins, "Coins")
	end)

	Store:SetState("PlayerStats", "Coins", 10) -- You have 10 Coins
	Disconnect()
	Store:SetState("PlayerStats", "Coins", 20) -- No output.
	```

	## Observing with Components

	Our Components can listen to changes in a store and automatically queue updates when a value in the store has changed. In order to do this, some preconditions need to be set:
	1. The component needs to know what store to observe changes from
	2. The component needs to know what key paths to subscribe to, and how to display them.

	The first precondition is simple: We can simply pass the store in as an argument in the Component's constructor. **In fact, Helium Components must receive a store as the first argument in their constructor in order to observe changes from that store**.

	While passing the same first argument through every single component down the tree of components may seem verbose, this actually makes it easy to differentiate "Container Components" (which are generally coupled with a particular segment of the application) from "Presentational Components" (which can generally be re-used throughout the application). More on that in a later tutorial.

	```lua
	function CoinsDisplay:Constructor(Store, Parent: Instance)
		self.Parent = Parent
		self.Store = Store
	end
	```

	In this instance, we set `self.Store = Store` so that we can keep track of the store in case we need to give it to a nested component in our redraw function (similar to how we keep track of `Parent` in order to know where we should inevitably place the copy of our component's template).
	Now what we want is to subscribe to a value in the store (say, 'Coins'), and automatically call `self.QueueRedraw()` whenever this state changes. Helium provides an easy way of doing this for Components using a property called `Reduction`:

	```lua
	CoinsDisplay.Reduction = {Coins = "Store.Path.To.Coins"}
	```

	This will automatically subscribe new CoinsDisplay components from the keypath on the right-hand side (`"Store.Path.To.Coins"`), and map it to the value on the left-hand side (`"Coins"`). The reduced state will then be passed in as a table, as the first argument to `CoinsDisplay:Redraw()`

	```lua
	CoinsDisplay.Reduction = {Coins = "Store.Path.To.Coins"}
	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw(ReducedState)
		local Gui = self.Gui
		if not Gui then
			Gui = self.Janitor:Add(script.CoinsDisplayTemplate:Clone(), "Destroy")
			Gui.Parent = self.Parent
			self.Gui = Gui
		end

		-- Now we can display from ReducedState.Coins instead of self.Coins.
		-- In fact, we can get rid of self.Coins now that all our data is coming from the store.
		Gui.CoinsLabel.Text = "Coins: " .. ReducedState.Coins
	end
	```

	We can now get rid of the `self.coins` property initialized in the constructor. In fact, we can also get rid of the `CoinsDisplay:AddCoin()` method we defined earlier, and replace it with actions such as `ADD_COINS` that we created in the last tutorial. Putting it all together:

	## Final Code

	### ReplicatedStorage.CoinsDisplay ModuleScript
	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Helium = require(ReplicatedStorage.Helium)
	local CoinsDisplay = Helium.Component.Extend("CoinsDisplay")

	function CoinsDisplay:Constructor(Store, Parent: Instance)
		self.Store = Store
		self.Parent = Parent
	end

	type ReducedState = {Coins: number}

	CoinsDisplay.Reduction = {Coins = ""} -- In this example, our store state is equivalent to coins
	CoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat
	function CoinsDisplay:Redraw(ReducedState: ReducedState)
		local Gui = self.Gui
		if not Gui then
			Gui = self.Janitor:Add(script.CoinsDisplayTemplate:Clone(), "Destroy")
			Gui.Parent = self.Parent
			self.Gui = Gui
		end

		Gui.CoinsLabel.Text = "Coins: " .. ReducedState.Coins
	end

	return CoinsDisplay
	```

	### A LocalScript:
	```lua
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local CoinsDisplay = require(ReplicatedStorage.CoinsDisplay)
	local Helium = require(ReplicatedStorage.Helium)

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local AddCoins = Helium.MakeActionCreator("AddCoins", function(Amount: number)
		return {Amount = Amount}
	end)

	type BaseAction = {Type: string}

	local function Reducer(Action: BaseAction, GetState, SetState)
		if Action.Type == AddCoins.ActionName then
			SetState(GetState() + Action.Amount)
		end
	end

	local InitialState = 0

	-- Create the store
	local CoinsStore = Helium.Store.new(Reducer, InitialState)

	-- Mount the root component; notice how CoinsStore is given as the first argument
	CoinsDisplay.new(CoinsStore, PlayerGui)

	-- Add 1 coin every second (hopefully)
	while true do
		local DeltaTime = task.wait(1)
		CoinsStore:Fire(AddCoins(math.floor(DeltaTime)))
	end
	```

	This should function exactly the same as before, but this time our coins are pulling directly from the store, and listening to action dispatches. We also don't need to store our `CoinsDisplay` instance as a variable in this case, nor do we need to directly tell the CoinsDisplay component to increment the state of 'coins'.

	---

	:::info
	All of this documentation is from the original [Rocrastinate docs](https://github.com/headjoe3/Rocrastinate/tree/master/docs) and was written by DataBrain, so 100% of the credit should go to him.
	All I did was modify it to fit Helium's API.
	:::

	@class Component
]=]
local Component = {}

--[=[
	The base constructor function.
	@ignore
]=]
function Component:Constructor(StoreObject)
	UpdateRedrawComponent()
	local UseStore = true
	local Reduction = self.Reduction
	if not Store.Is(StoreObject) then
		UseStore = false
		if Reduction then
			Debug.Warn("!Components with a state reduction must have a store as the first argument of their constructor " .. debug.traceback(), script.Name)
		end
	end

	-- a dub
	self.Janitor = Janitor.new()

	local MappedStateKeys = {}
	local MappedStringKeyPaths = {}
	local MappedKeyPaths = {}
	if Reduction then
		for Key, StringKeyPath in next, Reduction do
			table.insert(MappedStateKeys, Key)
			table.insert(MappedStringKeyPaths, StringKeyPath)
			table.insert(MappedKeyPaths, string.split(StringKeyPath, "."))
		end
	end

	local ReadOnlyCache = {}

	if UseStore then
		self.GetReducedState = function()
			local ReducedState = {}
			for Index, StateKey in ipairs(MappedStateKeys) do
				local KeyPath = MappedKeyPaths[Index]
				local StringKeyPath = MappedStringKeyPaths[Index]

				local Cached = ReadOnlyCache[StringKeyPath]
				if Cached ~= nil then
					ReducedState[StateKey] = Cached
				else
					Cached = StoreObject:GetState(table.unpack(KeyPath))
					ReducedState[StateKey] = Cached
					ReadOnlyCache[StringKeyPath] = Cached
				end
			end

			return ReducedState
		end
	else
		self.GetReducedState = function()
			return {}
		end
	end

	if GlobalConfiguration.Get("UseSwitchStatementForQueueRedraw") then
		self.QueueRedraw = function()
			local CurrentRedrawBinding
			if GlobalConfiguration.Get("SafeRedrawCheck") then
				CurrentRedrawBinding = Debug.Assert(RedrawBinding.Cast(self.RedrawBinding))
			else
				CurrentRedrawBinding = self.RedrawBinding
			end

			repeat
				if CurrentRedrawBinding == RedrawBinding.RenderStep then
					RenderStepQueue[self] = true
					break
				end

				if CurrentRedrawBinding == RedrawBinding.RenderStepTwice then
					if BindingHandlerActive[RenderStepQueue] then
						RenderStepTwiceQueue[self] = true
					else
						RenderStepQueue[self] = true
					end

					break
				end

				if CurrentRedrawBinding == RedrawBinding.Heartbeat then
					HeartbeatQueue[self] = true
					break
				end

				if CurrentRedrawBinding == RedrawBinding.Stepped then
					SteppedQueue[self] = true
					break
				end

				Debug.Error("Invalid RedrawBinding %q", CurrentRedrawBinding)
			until true
		end
	else
		self.QueueRedraw = function()
			local CurrentRedrawBinding
			if GlobalConfiguration.Get("SafeRedrawCheck") then
				CurrentRedrawBinding = Debug.Assert(RedrawBinding.Cast(self.RedrawBinding))
			else
				CurrentRedrawBinding = self.RedrawBinding
			end

			if CurrentRedrawBinding == RedrawBinding.RenderStep then
				RenderStepQueue[self] = true
			elseif CurrentRedrawBinding == RedrawBinding.RenderStepTwice then
				if BindingHandlerActive[RenderStepQueue] then
					RenderStepTwiceQueue[self] = true
				else
					RenderStepQueue[self] = true
				end
			elseif CurrentRedrawBinding == RedrawBinding.Heartbeat then
				HeartbeatQueue[self] = true
			elseif CurrentRedrawBinding == RedrawBinding.Stepped then
				SteppedQueue[self] = true
			else
				Debug.Error("Invalid RedrawBinding %q", CurrentRedrawBinding)
			end
		end
	end

	if UseStore and Reduction then
		for _, StringKeyPath in next, Reduction do
			self.Janitor:Add(StoreObject:Connect(StringKeyPath, function()
				ReadOnlyCache[StringKeyPath] = nil
				self.QueueRedraw()
			end), true)
		end
	end
end

local ReservedStatics = {
	new = true;
	Destroy = true;
}

local ComponentStaticMetatable = {}
function ComponentStaticMetatable:__newindex(Index, Value)
	if ReservedStatics[Index] then
		Debug.Error("Cannot override Component member %q; key is reserved", Index)
	else
		rawset(self, Index, Value)
	end
end

local DEFAULT_LIFECYCLE_EVENTS = {
	Destroyed = false;
	Destroying = false;
	DidRedraw = false;
	WillRedraw = false;
}

--[=[
	@interface PossibleLifecycleEvents
	@within Component
	.Destroyed boolean? -- Whether or not you want to create the `Destroyed` event.
	.Destroying boolean? -- Whether or not you want to create the `Destroying` event.
	.DidRedraw boolean? -- Whether or not you want to create the `DidRedraw` event.
	.WillRedraw boolean? -- Whether or not you want to create the `WillRedraw` event.
]=]

export type PossibleLifecycleEvents = {
	Destroyed: boolean?,
	Destroying: boolean?,
	DidRedraw: boolean?,
	WillRedraw: boolean?,
}

-- {"Destroyed" | "Destroying" | "DidRedraw" | "WillRedraw"}

--[=[
	Creates a new Component object.

	@param ClassName string -- The ClassName of the component. This is used for `__tostring` debug stuff.
	@param LifecycleEventsToCreate PossibleLifecycleEvents? -- The lifecycle events you want to create.
	@return BaseComponent
]=]
function Component.Extend(ClassName: string, PossibleLifecycleEventsToCreate: PossibleLifecycleEvents?)
	local ComponentStatics = {}
	ComponentStatics.ClassName = ClassName
	ComponentStatics.Constructor = nil
	ComponentStatics.RedrawBinding = RedrawBinding.Heartbeat
	ComponentStatics.Reduction = nil

	local ComponentMetatable = {}
	ComponentMetatable.__index = ComponentStatics
	function ComponentMetatable:__tostring()
		return ClassName
	end

	local LifecycleEventsToCreate = PossibleLifecycleEventsToCreate or DEFAULT_LIFECYCLE_EVENTS

	function ComponentStatics.new(ComponentStore, ...)
		local self = setmetatable({}, ComponentMetatable)
		Component.Constructor(self, ComponentStore)

		local Constructor = ComponentStatics.Constructor
		if Constructor then
			Constructor(self, ComponentStore, ...)
		end

		if LifecycleEventsToCreate.Destroyed then
			self.Destroyed = Signal.new()
		end

		if LifecycleEventsToCreate.Destroying then
			self.Destroying = Signal.new(self.Janitor)
		end

		if LifecycleEventsToCreate.DidRedraw then
			self.DidRedraw = Signal.new(self.Janitor)
		end

		if LifecycleEventsToCreate.WillRedraw then
			self.WillRedraw = Signal.new(self.Janitor)
		end

		self.QueueRedraw()
		return self
	end

	function ComponentStatics:Redraw()
		-- Called when QueueRedraw is called.
	end

	function ComponentStatics:Destroy()
		local Destroying = self.Destroying
		if Destroying then
			Destroying:Fire(Component)
		end

		self.Janitor:Destroy()

		RenderStepQueue[self] = nil
		RenderStepTwiceQueue[self] = nil
		HeartbeatQueue[self] = nil
		SteppedQueue[self] = nil

		local Destroyed = self.Destroyed
		if Destroyed then
			Destroyed:Fire(Component)
			Destroyed:Destroy()
		end

		setmetatable(self, nil)
	end

	return setmetatable(ComponentStatics, ComponentStaticMetatable)
end

export type BaseComponent = _BaseComponent.BaseComponent
return Component
