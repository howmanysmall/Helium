local Fmt = require(script.Parent.Utility.Fmt)

--[=[
	## Enhancing the store

	Middlewares are a [common way to enhance stores in Redux applications](https://www.codementor.io/vkarpov/beginner-s-guide-to-redux-middleware-du107uyud).
	Up until this point, the actions we've created are fairly dumb—all they can really do is get and set data. What if we want our dispatched actions to do
	more complex things like request data from the server?

	Helium supports middlewares, which are simply functions that intercept actions upon being dispatched, and allow custom logic to be applied to them.
	The way middlewares intercept actions is by providing a bridge in between `Store:Fire` or `Store:Dispatch` being called and the root reducer
	receiving those actions that were dispatched.

	Middlewares take the form of three nested functions:

	```lua
	local function Middleware(Store)
		return function(NextDispatch)
			return function(Action)
				...
			end
		end
	end
	```

	The first function takes in the current store that the middleware is being used on. We can call normal store functions on this object such as `SetState`, `GetState`, `Fire`, and `Connect`.
	The second nested function takes in `NextDispatch`. In a store with a single middleware applied, calling `NextDispatch(Action)` will forward the the action directly to the store's reducer.

	The third nested function is the actual function that decides what to do with actions when they are dispatched. To keep the actions moving through to the reducer without consuming it,
	you can call `NextDispatch(Action)`.

	```lua
	local function RedundantMiddleware(Store)
		return function(NextDispatch)
			return function(Action)
				NextDispatch(Action)
			end
		end
	end

	-- Some code

	Store:ApplyMiddleware(RedundantMiddleware)
	```

	In the above code, `RedundantMiddleware` is a middleware that listens to actions when `Store:Fire` is called, and immediately forwards them to the store's reducer with no side effects.
	Let's look at the source code of `LoggerMiddleware`, one of the middlewares bundled with Helium:

	```lua
	local function LoggerMiddleware()
		return function(NextMiddleware)
			return function(Action)
				print(Action.Type)
				NextMiddleware(Action)
			end
		end
	end

	return LoggerMiddleware
	```

	This middleware is nearly equivalent to our `RedundantMiddleware`, with the one difference that the type of the action being dispatched is printed to the output console.
	In effect, this will "log" every action that is dispatached in our store. This can be useful for debugging actions that are dispatched through our application:

	```lua
	local DEBUGGING_ENABLED = true
	local Reducer, InitialState = ...

	local Store = Helium.Store.new(Reducer, InitialState)

	if DEBUGGING_ENABLED then
		Store:ApplyMiddleware(Helium.LoggerMiddleware)
	end
	```

	Helium offers a few built-in middlewares:

	* `Helium.InspectorMiddleware` - Prints out the whole action being dispatched.
	* `Helium.LoggerMiddleware` - Prints out the action types of every action dispatched.
	* `Helium.SpunkMiddleware` - Like `ThunkMiddleware`, allows functions to be dispatched. The only difference is that the functions being dispatched will be spawned immediately in a separate thread. This could be more ideal for Roblox development as opposed to JavaScript do to the lack of Promise objects.
	* `Helium.ThunkMiddleware` - Like its Redux counterpart, thunk middleware allows functions to be dispatched as regular actions. When a function is encountered by the middleware in place of an action, that function will be intercepted and called with the arguments `MyThunk(Dispatch, GetState)`.

	A usage example for `SpunkMiddleware` would be an action that needs to fetch data from the server:

	_____

	### Entry point:

	```lua
	local Store = Helium.Store.new(RootReducer, InitialState)
	Store:ApplyMiddleware(Helium.SpunkMiddleware)
	```

	### Actions module:

	```lua
	local Actions = {}
	function Actions.FetchCoins()
		return function(Dispatch, GetState)
			-- Where we would normally return an action here, we instead return a spawned thunk that defers our change in state.
			local Coins = ReplicatedStorage.GetCoins:InvokeServer()
			Dispatch({
				Type = "SetCoins";
				Value = Coins;
			})
		end
	end

	return Actions
	```

	### Some component in our application:

	```lua
	self.Janitor:Add(self.Gui.FetchCoinsButton.Activated:Connect(function()
		self.Store:Fire(Actions.FetchCoins())
	end), "Disconnect")
	```

	Your use case for middlewares may vary. You might not need it at all for your application; alternatively, you may find a need to write your own middlewares for debugging or managing state.
	Middleware-facilitated operations such as thunks are generally the best place to put logic that affect state after yielding calls, such as when retrieving data from the server.

	@class Middleware
]=]
local Middleware = {}

--[=[
	@type MiddlewareHandler (NextMiddleware: (Action: BaseAction) -> ()) -> (Action: BaseAction) -> ()
	@within Middleware
]=]

--[=[
	Prints out the whole action being dispatched.

	```lua
	local AwesomeAction = Helium.MakeActionCreator("AwesomeAction", function(ObjectName: string, IsAwesome: boolean)
		return {
			ObjectName = ObjectName;
			IsAwesome = IsAwesome;
		}
	end)

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == AwesomeAction.ActionName then
			SetState(Action.ObjectName, Action.IsAwesome)
		end
	end, {
		LPlus = false;
		LPlusLight = false;
		Helium = false;
	}):ApplyMiddleware(Helium.InspectorMiddleware)

	Store:Fire(AwesomeAction("LPlus", true))
	--[[
		Prints:
			{
				Type = "AwesomeAction";
				ObjectName = "LPlus";
				IsAwesome = true;
			}
	]]
	```

	@within Middleware
	@function InspectorMiddleware
	@tag Middleware
	@return MiddlewareHandler -- The handler code for the middleware.
]=]
local function InspectorMiddleware()
	return function(NextMiddleware)
		return function(Action)
			print(Fmt("{:#?}", Action))
			NextMiddleware(Action)
		end
	end
end

--[=[
	Prints out the action types of every action dispatched.

	```lua
	local AwesomeAction = Helium.MakeActionCreator("AwesomeAction", function(ObjectName: string, IsAwesome: boolean)
		return {
			ObjectName = ObjectName;
			IsAwesome = IsAwesome;
		}
	end)

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == AwesomeAction.ActionName then
			SetState(Action.ObjectName, Action.IsAwesome)
		end
	end, {
		LPlus = false;
		LPlusLight = false;
		Helium = false;
	}):ApplyMiddleware(Helium.InspectorMiddleware)

	Store:Fire(AwesomeAction("LPlus", true)) -- Prints: "AwesomeAction"
	```

	@within Middleware
	@function LoggerMiddleware
	@tag Middleware
	@return MiddlewareHandler -- The handler code for the middleware.
]=]
local function LoggerMiddleware()
	return function(NextMiddleware)
		return function(Action)
			print(Action.Type)
			NextMiddleware(Action)
		end
	end
end

--[=[
	Like `ThunkMiddleware`, allows functions to be dispatched. The only difference is that the functions being dispatched will be spawned
	immediately in a separate thread. This could be more ideal for Roblox development as opposed to JavaScript do to the lack of Promise objects.

	```lua
	local function FetchCoins()
		return function(Dispatch, GetState)
			-- Where we would normally return an action here, we instead return a spawned thunk that defers our change in state.
			local Coins = ReplicatedStorage.GetCoins:InvokeServer()
			Dispatch({
				Type = "SetCoins";
				Value = Coins;
			})
		end
	end

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == "SetCoins" then
			SetState("Coins", Action.Value)
		end
	end, InitialState):ApplyMiddleware(Helium.SpunkMiddleware)

	Store:Fire(FetchCoins())
	```

	@within Middleware
	@function SpunkMiddleware
	@tag Middleware
	@param Store Store -- The Store of the middleware.
	@return MiddlewareHandler -- The handler code for the middleware.
]=]
local function SpunkMiddleware(Store)
	return function(NextMiddleware)
		return function(Action)
			if type(Action) == "function" then
				task.spawn(Action, Store.Dispatch, Store.GetState)
			else
				NextMiddleware(Action)
			end
		end
	end
end

--[=[
	Like its Redux counterpart, thunk middleware allows functions to be dispatched as regular actions. When a function is encountered
	by the middleware in place of an action, that function will be intercepted and called with the arguments `MyThunk(Dispatch, GetState)`.

	```lua
	local function AddCoins()
		return function(Dispatch, GetState)
			Dispatch({
				Type = "SetCoins";
				Value = math.random(100);
			})
		end
	end

	local Store = Helium.Store.new(function(Action, _, SetState)
		if Action.Type == "SetCoins" then
			SetState("Coins", Action.Value)
		end
	end, InitialState):ApplyMiddleware(Helium.ThunkMiddleware)

	Store:Fire(AddCoins())
	```

	@within Middleware
	@function ThunkMiddleware
	@tag Middleware
	@param Store Store -- The Store of the middleware.
	@return MiddlewareHandler -- The handler code for the middleware.
]=]
local function ThunkMiddleware(Store)
	return function(NextMiddleware)
		return function(Action)
			if type(Action) == "function" then
				Action(Store.Dispatch, Store.GetState)
			else
				NextMiddleware(Action)
			end
		end
	end
end

Middleware.InspectorMiddleware = InspectorMiddleware
Middleware.LoggerMiddleware = LoggerMiddleware
Middleware.SpunkMiddleware = SpunkMiddleware
Middleware.ThunkMiddleware = ThunkMiddleware
return Middleware
