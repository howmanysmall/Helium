local Debug = require(script.Parent.Utility.Debug)
local DeepCopyTable = require(script.Parent.Utility.DeepCopyTable)
local Fmt = require(script.Parent.Utility.Fmt)
local GlobalConfiguration = require(script.Parent.GlobalConfiguration)
local t = require(script.Parent.Utility.t)
local _Types = require(script.Parent.Types)

--[=[
	The Store object is one of the API changes going from Rocrastinate to Helium, as it is no longer a function that returns a table and is instead a proper Lua object.
	The Store object is inspired by [Redux](https://redux.js.org/), a state management library that is often used in JavaScript web applications. Like Redux, the Store
	is where we can centralize the state of our application. It uses "Actions" to update the application state, and "Reducers" to control how the state changes with a given action.

	Helium's Store is NOT equivalent to Redux or [Rodux](https://github.com/Roblox/rodux). Some major differences are as follows:
	* Helium stores must be passed as the first argument in the constructors of components that use Store objects. This means that the "store" a component is in is not determined by context, but by explicit argument.
	* Redux reduces actions by re-creating the entire application state. For the sake of optimization, enabled by the coupling of Helium Components with Store, Helium Store reducers are passed the functions `GetState` and `SetState`, which copy/mutate the application's state respectively.
	* With React/Redux (or Roact/Rodux), changes to the store will immediately re-render a component. In contrast, changes in a Helium store will immediately call `QueueUpdate()`, which defers rendering changes to the next frame binding.

	## Actions

	"Actions" are the *only* source of information for our Helium Store. They represent information needed to change some portion of the application state, and are represented as lua objects. They are sent using `Store:Fire(Action)` or `Store:Dispatch(Action)`.

	Actions should typically be represented as tables, and have a `Type` property denoting what kind of action is being sent. For example:

	```lua
	local MyAction = {
		Type = "AddCoins";
		Amount = 1;
	}

	Store:Fire(MyAction)
	```

	```cpp
	typedef GenericDictionary table<LuaString, any>;

	GenericDictionary MyAction = table(
		Type: L"AddCoins",
		Amount: 1,
	);

	Store::Fire(MyAction);
	```

	_________________

	## Action Creators

	Typically, instead of creating actions directly, we can use "Action Creators", which are simply functions that create actions for us with a given set of arguments. Note that these only **create the action**, and **do not dispatch them**:
	```lua
	local function AddCoins(Amount: number)
		return {
			Type = "AddCoins";
			Amount = Amount;
		}
	end

	Store:Fire(AddCoins(1))
	```

	```cpp
	typedef GenericDictionary table<LuaString, any>;

	GenericDictionary AddCoins(int Amount)
	{
		return table(
			Type: L"AddCoins",
			Amount: Amount,
		);
	}

	Store::Fire(AddCoins(1));
	```

	Actions can be dispatched at any time from anywhere in the application, including the middle of a Redraw().

	Helium actually has a built-in function used to creating this, called `MakeActionCreator`. This can be used as seen in the following code:

	```lua
	local AddCoins = Helium.MakeActionCreator("AddCoins", function(Amount: number)
		return {
			Amount = Amount;
		}
	end)

	Store:Fire(AddCoins(1))
	```

	```cpp
	typedef GenericDictionary table<LuaString, any>;

	GenericDictionary AddCoinsAction(int Amount)
	{
		return table(Amount: Amount);
	}

	void AddCoins = Helium.MakeActionCreator(L"AddCoins", AddCoinsAction);

	Store::Fire(AddCoins(1));
	```

	_________________

	## Responding to Actions

	Like Redux, Helium uses "Reducers", which are functions that respond to an action by modifying a certain portion of the store's state.

	Reducers are given three arguments: `(Action, GetState, SetState)`.

	* `Action` is the action that was dispatched.
	* `GetState(...KeyPath)` is a function that gets a value in the store by nested keys.
	* `SetState(...KeyPath, Value)` is a function that sets a value in the store by nested keys.

	If we want to set the value of `Coins` in the store whenever an `AddCoins` action is received, we can use the following code:

	```lua
	local function Reducer(Action, GetState, SetState)
		if Action.Type == "AddCoins" then
			local Coins = GetState("Coins")
			SetState("Coins", Coins + Action.Amount)
		end
	end
	```

	If you're using the `MakeActionCreator` function, you can set it up like so:

	```lua
	local AddCoins = require(ReplicatedStorage.AddCoins)

	local function Reducer(Action, GetState, SetState)
		if Action.Type == AddCoins.ActionName then
			local Coins = GetState("Coins")
			SetState("Coins", Coins + Action.Amount)
		end
	end
	```

	This code makes a few assumptions:

	1. There is already a value in the store named `Coins`, and that it is a number.
	2. That the action has a property named `Type`.
	3. That the action (which we've identified as an `AddCoins` action) has a property named `Amount`, and that it is a number.

	It is generally best to centralize actions or action creators in an `Actions` module, so that these assumptions can be standardized. Additionally, we need to declare the initial state of our store somewhere:

	```lua
	local InitialState = {
		Coins = 0;
	}
	```

	Then, when we call

	```lua
	Store:Fire(AddCoins(1))
	```

	our store state should conceptually be mutated to look something like this table:

	```lua
	{
		Coins = 1;
	}
	```

	Additionally, we can nest tables in our store structure:

	```lua
	local InitialState = {
		PlayerStats = {Coins = 0};
	}

	local function Reducer(Action, GetState, SetState)
		if Action.Type == AddCoins.ActionName then
			local Coins = GetState("PlayerStats", "Coins")
			SetState("PlayerStats", "Coins", Coins + Action.Amount)
		end
	end
	```

	```cpp
	GenericDictionary InitialState = table(PlayerStats: table(Coins: 0));

	void Reducer(GenericDictionary Action, void GetState, SetState)
	{
		if Action.Type == AddCoins.ActionName
		{
			int Coins = GetState(L"PlayerStats", L"Coins");
			SetState(L"PlayerStats", L"Coins", Coins + Action.Amount);
		}
	}
	```

	In the above example, we provide an aditional argument to `GetState` and `SetState`. These are just strings representing the path of nested keys leading to the exact value we want to get/set in our store.

	If we kept this all in the same module, we may run into a problem when our tree becomes more complex:

	```lua
	local function Reducer(Action, GetState, SetState)
		if Action.Type == "DoSomethingInASpecificDomain" then
			SetState("Path", "To", "Specific", "Domain", Value)
		elseif  ...  then
			...
		end
	end
	```

	```cpp
	void Reducer(GenericDictionary Action, void GetState, SetState)
	{
		if Action.Type == L"DoSomethingInASpecificDomain"
		{
			SetState(L"Path", L"To", L"Specific", L"Domain", Action.Value);
		} elseif ...
		{
			...
		}
	}
	```

	This can become very verbose. It would be much simpler if we could create a reducer that just deals with playerStats, and another reducer that just deals with some other domain.

	To do this, you can use the `CombineReducers()` function. Let's say we put our main reducer in a module called "RootReducer", and nested reducers for playerStats underneath the root reducer:

	_________________

	### RootReducer ModuleScript

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Helium = require(ReplicatedStorage.Helium)
	local PlayerStats = require(script.PlayerStats)

	local Reducer = Helium.CombineReducers({
		PlayerStats = PlayerStats.Reducer;
	})

	local InitialState = {
		PlayerStats = PlayerStats.InitialState;
	}

	return {
		Reducer = Reducer;
		InitialState = InitialState;
	}
	```

	### RootReducer.PlayerStats ModuleScript

	```lua
	local function Reducer(Action, GetState, SetState)
		if Action.Type == "AddCoins" then
			local Coins = GetState("Coins")
			SetState("Coins", Coins + Action.Amount)
		end
	end

	local InitialState = {Coins = 0;}
	return {
		Reducer = Reducer;
		InitialState = InitialState;
	}
	```

	If we wanted to, we could subdivide this even further by making a reducer for coins, and use `CombineReducers()` in the PlayerStats module instead. The "coins" module would then look something like this:

	### RootReducer.PlayerStats.Coins ModuleScript

	```lua
	local function Reducer(Action, GetState, SetState)
		if Action.Type == "AddCoins" then
			SetState(GetState() + Action.Amount)
		end
	end

	local InitialState = 0

	return {
		Reducer = Reducer;
		InitialState = InitialState;
	}
	```

	Now that we've separated the concerns of our reducers and actions, how do we actually create the store and have it interact with our application?

	Helium uses the function `Store.new(Reducer, InitialState)` for this.
	Putting it all together, we can create a very simple store that reduces a single value of "Coins"

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Helium = require(ReplicatedStorage.Helium)

	-- Typically this would be put in a separate module called "Actions"
	local AddCoins = Helium.MakeActionCreator("AddCoins", function(Amount: number)
		return {
			Amount = Amount;
		}
	end)

	-- Typically this would be put in a separate module called "Reducer" or "RootReducer"
	local function Reducer(Action, GetState, SetState)
		if Action.Type == AddCoins.ActionName then
			SetState(GetState() + Action.Amount)
		end
	end

	local InitialState = 0
	local CoinsStore = Helium.Store.new(Reducer, InitialState) -- You can also do Helium.CreateStore(Reducer, InitialState)

	print(CoinsStore:GetState()) -- 0

	CoinsStore:Fire(AddCoins(10))
	print(CoinsStore:GetState()) -- 10

	CoinsStore:Dispatch(AddCoins(10)) -- Dispatch is also valid
	print(CoinsStore:GetState()) -- 20
	```

	```cpp
	typedef GenericDictionary table<LuaString, any>;
	RbxInstance ReplicatedStorage = game::GetService @ ReplicatedStorage;
	GenericDictionary Helium = require(ReplicatedStorage.Helium);

	const int INITIAL_STATE = 0;

	// Typically this would be put in a separate module called "Actions"
	GenericDictionary AddCoinsFunction(int Amount)
	{
		return table(Amount: Amount);
	}

	void AddCoins = Helium.MakeActionCreator(L"AddCoins", AddCoinsFunction);

	// Typically this would be put in a separate module called "Reducer" or "RootReducer"
	void Reducer(GenericDictionary Action, void GetState, SetState)
	{
		if Action.Type == AddCoins.ActionName
		{
			SetState(GetState() + Action.Amount);
		}
	}

	entry void Main(void)
	{
		GenericDictionary CoinsStore = Helium.Store.new(Reducer, INITIAL_STATE); // You can also do Helium.CreateStore(Reducer, InitialState)
		print(CoinsStore::GetState()); // 0

		CoinsStore::Fire(AddCoins(10));
		print(CoinsStore::GetState()); // 10

		CoinsStore::Dispatch(AddCoins(10)); // Dispatch is also valid
		print(CoinsStore::GetState()); // 20
	}
	```

	@class Store
]=]
local Store = {}
Store.ClassName = "Store"
Store.__index = Store

export type BaseAction = _Types.BaseAction
export type Reducer = _Types.Reducer

type GenericFunction = _Types.GenericFunction
type GenericTable = _Types.GenericTable

local StoreEnhancedDispatchChainIndex = newproxy(false)
local StoreObserversIndex = newproxy(false)
local StoreStateIndex = newproxy(false)

-- local function BaseMiddlewareFunction(_Store: Store)
-- 	return function(_NextDispatch: (Action: BaseAction) -> ())
-- 		return function(_Action: BaseAction) end
-- 	end
-- end

-- export type MiddlewareFunction = typeof(function(_Store: Store)
-- 	return function(_NextDispatch: (Action: BaseAction) -> ())
-- 		return function(_Action: BaseAction) end
-- 	end
-- end)

type ActionExecutor = (Action: BaseAction) -> ()
type NextDispatchFunction = (NextDispatch: ActionExecutor) -> ActionExecutor
export type MiddlewareFunction = (Store: Store) -> NextDispatchFunction

local BaseActionDefinition = t.interface({Type = t.any})

--[=[
	Applies a Middleware to the Store. Middlware are simply functions that intercept actions upon being dispatched, and allow custom logic to be applied to them.
	The way middlewares intercept actions is by providing a bridge in between store.dispatch being called and the root reducer receiving those actions that were dispatched.

	```lua
	local SetValueA = Helium.MakeActionCreator("SetValueA", function(Value)
		return {Value = Value}
	end)

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == SetValueA.ActionName then
			SetState("ValueA", Action.Value)
		end
	end, {
		ValueA = "A";
		ValueB = {ValueC = "C"};
	})

	Store:ApplyMiddleware(Helium.LoggerMiddleware):ApplyMiddleware(Helium.InspectorMiddleware)
	Store:Fire(SetValueA("ValueA"))
	--[[
		Prints:
			{
				["Value"] = "ValueA",
				["Type"] = "SetValueA"
			}
			SetValueA
	]]
	```

	@param Middleware (Store: Store) -> (NextDispatch: (Action: BaseAction) -> ()) -> (Action: BaseAction) -> () -- The middleware function you are applying.
	@return Store -- The self reference for chaining these calls.
]=]
function Store:ApplyMiddleware(Middleware: MiddlewareFunction)
	local RunTypeChecking = GlobalConfiguration.Get("RunTypeChecking")
	if RunTypeChecking then
		Debug.Assert(t.callback(Middleware))
	end

	local NextHandler = Middleware(self)
	if RunTypeChecking then
		Debug.Assert(t.callback(NextHandler))
	end

	local StoreEnhancedDispatchChain = NextHandler(self[StoreEnhancedDispatchChainIndex])
	if RunTypeChecking then
		Debug.Assert(t.callback(StoreEnhancedDispatchChain))
	end

	self[StoreEnhancedDispatchChainIndex] = StoreEnhancedDispatchChain
	return self
end

--[=[
	Dispatches an Action to the Store.

	```lua
	local DispatchAction = Helium.MakeActionCreator("DispatchAction", function(Value)
		return {
			Value = Value;
		}
	end)

	Store:Fire(DispatchAction("Value"))
	Store:Fire({
		Type = "AwesomeAction";
		AwesomeValue = true;
	})
	```

	@param Action BaseAction -- The Action you are dispatching.
]=]
function Store:Fire(Action: BaseAction)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(BaseActionDefinition(Action))
	end

	self[StoreEnhancedDispatchChainIndex](Action)
end

--[=[
	Dispatches an Action to the Store.

	```lua
	local DispatchAction = Helium.MakeActionCreator("DispatchAction", function(Value)
		return {
			Value = Value;
		}
	end)

	Store:Dispatch(DispatchAction("Value"))
	Store:Dispatch({
		Type = "AwesomeAction";
		AwesomeValue = true;
	})
	```

	@param Action BaseAction -- The Action you are dispatching.
]=]
function Store:Dispatch(Action: BaseAction)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(BaseActionDefinition(Action))
	end

	self[StoreEnhancedDispatchChainIndex](Action)
end

--[=[
	Gets the current Store state. If the value returned is a table, it is deep copied to prevent  You can optionally provide a path.

	```lua
	local Store = Helium.Store.new(function() end, {
		ValueA = "A";
		ValueB = {ValueC = "C"};
	})

	print(Store:GetState()) -- The state.
	print(Store:GetState("ValueA")) -- "A"
	print(Store:GetState("ValueB", "ValueC")) -- "C"
	```

	@param ... string? -- The string path you want to get.
	@return T -- The current Store state.
]=]
function Store:GetState(...): any
	local Base = self[StoreStateIndex]
	for Index = 1, select("#", ...) do
		if type(Base) ~= "table" then
			return nil
		end

		Base = Base[select(Index, ...)]
	end

	if type(Base) == "table" then
		return DeepCopyTable(Base)
	else
		return Base
	end
end

--[=[
	Sets the current Store state. The varargs are the string paths you want to set the state of.

	:::info
	The path is totally optional and skipping it will just result in you editing the root of the state table.
	:::

	:::warning
	`SetState` overwrites the table, so if you want to preserve the original table, you should be using actions and the reducer function.
	:::

	```lua
	local Store = Helium.Store.new(function() end, {
		ValueA = "A";
	})

	print(Store:GetState("ValueA")) -- "A"
	Store:SetState("ValueA", "ValueA")
	print(Store:GetState("ValueA")) -- "ValueA"
	```

	```lua
	local Store = Helium.Store.new(function() end, {
		ValueB = {ValueC = "C"};
	})

	print(Store:GetState("ValueB", "ValueC")) -- "C"
	Store:SetState("ValueB", "ValueC", 3)
	print(Store:GetState("ValueB", "ValueC")) -- "3"
	```

	@param ... string? -- The path of the state to set.
	@param Value any -- The value you are setting. This is always required, think of it as setting a Url -> example.com/path/to/value == "path", "to", "value"
]=]
function Store:SetState(...)
	local KeyPath = {...}
	local Value = table.remove(KeyPath) :: any

	local VisitedPaths = {""}
	local LastVisitedPath = nil
	for _, Key in ipairs(KeyPath) do
		local NextVisitedPath
		if LastVisitedPath ~= nil then
			NextVisitedPath = LastVisitedPath .. "." .. Key
		else
			NextVisitedPath = Key
		end

		LastVisitedPath = NextVisitedPath
		table.insert(VisitedPaths, NextVisitedPath)
	end

	local Base = self[StoreStateIndex]
	for Index = 1, #KeyPath - 1 do
		if type(Base) ~= "table" then
			Debug.Error("Attempt to set non-table key")
		end

		local Key = KeyPath[Index]
		Base = Base[Key]
	end

	if #KeyPath == 0 then
		self[StoreStateIndex] = Value
	else
		local LastKey = KeyPath[#KeyPath]
		if type(Base) ~= "table" then
			Debug.Error("Attempt to set non-table key")
		end

		Base[LastKey] = Value
	end

	local StoreObservers = self[StoreObserversIndex]
	for _, Path in ipairs(VisitedPaths) do
		local Observers = StoreObservers[Path]
		if Observers then
			local Length = #Observers
			local SaveObservers = (table.move(Observers, 1, Length, 1, table.create(Length)) :: any) :: {any} -- at least robloxts can take a PR to fix this
			for _, SaveObserver in ipairs(SaveObservers) do
				task.spawn(SaveObserver)
			end
		end
	end
end

local ConnectTuple = t.tuple(t.string, t.callback)

--[=[
	Connects a function to the given string keypath.

	```lua
	local function SetValue(Value)
		return {Value = Value}
	end

	local SetValueA = Helium.MakeActionCreator("SetValueA", SetValue)
	local SetValueC = Helium.MakeActionCreator("SetValueC", SetValue)
	local SetValueD = Helium.MakeActionCreator("SetValueD", SetValue)

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == SetValueA.ActionName then
			SetState("ValueA", Action.Value)
		elseif Action.Type == SetValueC.ActionName then
			SetState("ValueB", "ValueC", Action.Value)
		elseif Action.Type == SetValueD.ActionName then
			SetState("ValueD", Action.Value)
		end
	end, {
		ValueA = "A";
		ValueB = {ValueC = "C"};
	})

	local Disconnect = Store:Connect("", function()
		print("The store was changed!", Store:GetState())
	end)

	Store:Connect("ValueA", function()
		print("ValueA was changed!", Store:GetState("ValueA"))
	end)

	Store:Connect("ValueB.ValueC", function()
		print("ValueB.ValueC was changed!", Store:GetState("ValueB", "ValueC"))
	end)

	Store:Fire(SetValueD("ValueD"))
	--[[
		Prints:
			The store was changed! {
				["ValueA"] = "A",
				["ValueB"] = {
					["ValueC"] = "C"
				},
				["ValueD"] = "ValueD"
			}
	]]

	Disconnect()
	Store:Fire(SetValueA("ValueA")) -- Prints: ValueA was changed! ValueA
	Store:Fire(SetValueC("ValueC")) -- Prints: ValueB.ValueC was changed! ValueC
	```

	@param StringKeyPath string -- The string path to run the function at. An empty string is equal to any changes made.
	@param Function () -> () -- The function you want to run when the state is updated.
	@return () -> () -- A function that disconnects the connection.
]=]
function Store:Connect(StringKeyPath: string, Function: GenericFunction): () -> ()
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(ConnectTuple(StringKeyPath, Function))
	end

	local StoreObservers = self[StoreObserversIndex]
	local Observers = StoreObservers[StringKeyPath]
	if not Observers then
		Observers = {}
		StoreObservers[StringKeyPath] = Observers
	end

	table.insert(Observers, Function)
	return function()
		local Index = table.find(Observers, Function)
		if Index then
			local Length = #Observers
			Observers[Index] = Observers[Length]
			Observers[Length] = nil
		end

		if #Observers == 0 then
			StoreObservers[StringKeyPath] = nil
		end
	end
end

--[=[
	Connects a function to the given string keypath.

	```lua
	local function SetValue(Value)
		return {Value = Value}
	end

	local SetValueA = Helium.MakeActionCreator("SetValueA", SetValue)
	local SetValueC = Helium.MakeActionCreator("SetValueC", SetValue)
	local SetValueD = Helium.MakeActionCreator("SetValueD", SetValue)

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == SetValueA.ActionName then
			SetState("ValueA", Action.Value)
		elseif Action.Type == SetValueC.ActionName then
			SetState("ValueB", "ValueC", Action.Value)
		elseif Action.Type == SetValueD.ActionName then
			SetState("ValueD", Action.Value)
		end
	end, {
		ValueA = "A";
		ValueB = {ValueC = "C"};
	})

	local Disconnect = Store:Subscribe("", function()
		print("The store was changed!", Store:GetState())
	end)

	Store:Subscribe("ValueA", function()
		print("ValueA was changed!", Store:GetState("ValueA"))
	end)

	Store:Subscribe("ValueB.ValueC", function()
		print("ValueB.ValueC was changed!", Store:GetState("ValueB", "ValueC"))
	end)

	Store:Dispatch(SetValueD("ValueD"))
	--[[
		Prints:
			The store was changed! {
				["ValueA"] = "A",
				["ValueB"] = {
					["ValueC"] = "C"
				},
				["ValueD"] = "ValueD"
			}
	]]

	Disconnect()
	Store:Dispatch(SetValueA("ValueA")) -- Prints: ValueA was changed! ValueA
	Store:Dispatch(SetValueC("ValueC")) -- Prints: ValueB.ValueC was changed! ValueC
	```

	@param StringKeyPath string -- The string path to run the function at. An empty string is equal to any changes made.
	@param Function () -> () -- The function you want to run when the state is updated.
	@return () -> () -- A function that disconnects the connection.
]=]
function Store:Subscribe(StringKeyPath: string, Function: GenericFunction)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(ConnectTuple(StringKeyPath, Function))
	end

	local StoreObservers = self[StoreObserversIndex]
	local Observers = StoreObservers[StringKeyPath]
	if not Observers then
		Observers = {}
		StoreObservers[StringKeyPath] = Observers
	end

	table.insert(Observers, Function)
	return function()
		local Index = table.find(Observers, Function)
		if Index then
			local Length = #Observers
			Observers[Index] = Observers[Length]
			Observers[Length] = nil
		end

		if #Observers == 0 then
			StoreObservers[StringKeyPath] = nil
		end
	end
end

--[=[
	Returns a string representation of the Store's current state. This is useful for debugging things.

	```lua
	local Store = Helium.Store.new(function() end, {
		ValueA = "A";
		ValueB = {ValueC = "C"};
	})

	print(Store:InspectState())
	--[[
		Prints:
			{
				["ValueA"] = "A",
				["ValueB"] = {
					["ValueC"] = "C"
				}
			}
	]]
	```

	@return string -- The string representation of the Store's current state.
]=]
function Store:InspectState(): string
	return Fmt("{:#?}", self[StoreStateIndex])
end

function Store:__tostring()
	return Fmt("Store<{:#?}>", self[StoreStateIndex])
end

--[=[
	Creates a new Store object.

	```lua
	local Store = Helium.Store.new(function()
	end, {ThisIsAStore = true})
	```

	@param Reducer ReducerFunction -- The reducer function.
	@param InitialState NonNil -- The initial state.
	@return Store
]=]
function Store.new(Reducer: Reducer, InitialState: any)
	if GlobalConfiguration.Get("RunTypeChecking") then
		Debug.Assert(t.callback(Reducer))
	end

	local self = setmetatable({}, Store)
	self[StoreObserversIndex] = {}
	self[StoreStateIndex] = InitialState
	self[StoreEnhancedDispatchChainIndex] = function(Action)
		Reducer(Action, function(...)
			return self:GetState(...)
		end, function(...)
			return self:SetState(...)
		end)
	end

	return self
end

--[=[
	Determines if the passed object is a Store.

	```lua
	print(Helium.Store.Is(Helium.Store.new(function() end, {}))) -- true
	print(Helium.Store.Is({})) -- false
	print(Helium.Store.Is(true)) -- false
	```

	@param Object any -- The object to check against.
	@return boolean -- Whether or not the object is a Store.
]=]
function Store.Is(Object: any): boolean
	return type(Object) == "table" and getmetatable(Object) == Store
end

export type Store = typeof(Store.new(function(_Action: BaseAction, _GetState, _SetState) end, {}))
return Store
