"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[561],{64349:function(e){e.exports=JSON.parse('{"functions":[{"name":"InspectorMiddleware","desc":"Prints out the whole action being dispatched.\\n\\n```lua\\nlocal AwesomeAction = Helium.MakeActionCreator(\\"AwesomeAction\\", function(ObjectName: string, IsAwesome: boolean)\\n\\treturn {\\n\\t\\tObjectName = ObjectName;\\n\\t\\tIsAwesome = IsAwesome;\\n\\t}\\nend)\\n\\nlocal Store = Helium.Store.new(function(Action, _, SetState)\\n\\tif Action.Type == AwesomeAction.ActionName then\\n\\t\\tSetState(Action.ObjectName, Action.IsAwesome)\\n\\tend\\nend, {\\n\\tLPlus = false;\\n\\tLPlusLight = false;\\n\\tHelium = false;\\n}):ApplyMiddleware(Helium.InspectorMiddleware)\\n\\nStore:Fire(AwesomeAction(\\"LPlus\\", true))\\n--[[\\n\\tPrints:\\n\\t\\t{\\n\\t\\t\\tType = \\"AwesomeAction\\";\\n\\t\\t\\tObjectName = \\"LPlus\\";\\n\\t\\t\\tIsAwesome = true;\\n\\t\\t}\\n]]\\n```","params":[],"returns":[{"desc":"The handler code for the middleware.","lua_type":"MiddlewareHandler"}],"function_type":"static","tags":["Middleware"],"source":{"line":169,"path":"src/Middleware.lua"}},{"name":"LoggerMiddleware","desc":"Prints out the action types of every action dispatched.\\n\\n```lua\\nlocal AwesomeAction = Helium.MakeActionCreator(\\"AwesomeAction\\", function(ObjectName: string, IsAwesome: boolean)\\n\\treturn {\\n\\t\\tObjectName = ObjectName;\\n\\t\\tIsAwesome = IsAwesome;\\n\\t}\\nend)\\n\\nlocal Store = Helium.Store.new(function(Action, _, SetState)\\n\\tif Action.Type == AwesomeAction.ActionName then\\n\\t\\tSetState(Action.ObjectName, Action.IsAwesome)\\n\\tend\\nend, {\\n\\tLPlus = false;\\n\\tLPlusLight = false;\\n\\tHelium = false;\\n}):ApplyMiddleware(Helium.InspectorMiddleware)\\n\\nStore:Fire(AwesomeAction(\\"LPlus\\", true)) -- Prints: \\"AwesomeAction\\"\\n```","params":[],"returns":[{"desc":"The handler code for the middleware.","lua_type":"MiddlewareHandler"}],"function_type":"static","tags":["Middleware"],"source":{"line":207,"path":"src/Middleware.lua"}},{"name":"SpunkMiddleware","desc":"Like `ThunkMiddleware`, allows functions to be dispatched. The only difference is that the functions being dispatched will be spawned\\nimmediately in a separate thread. This could be more ideal for Roblox development as opposed to JavaScript do to the lack of Promise objects.\\n\\n```lua\\nlocal function FetchCoins()\\n\\treturn function(Dispatch, GetState)\\n\\t\\t-- Where we would normally return an action here, we instead return a spawned thunk that defers our change in state.\\n\\t\\tlocal Coins = ReplicatedStorage.GetCoins:InvokeServer()\\n\\t\\tDispatch({\\n\\t\\t\\tType = \\"SetCoins\\";\\n\\t\\t\\tValue = Coins;\\n\\t\\t})\\n\\tend\\nend\\n\\nlocal Store = Helium.Store.new(function(Action, _, SetState)\\n\\tif Action.Type == \\"SetCoins\\" then\\n\\t\\tSetState(\\"Coins\\", Action.Value)\\n\\tend\\nend, InitialState):ApplyMiddleware(Helium.SpunkMiddleware)\\n\\nStore:Fire(FetchCoins())\\n```","params":[{"name":"Store","desc":"The Store of the middleware.","lua_type":"Store"}],"returns":[{"desc":"The handler code for the middleware.","lua_type":"MiddlewareHandler"}],"function_type":"static","tags":["Middleware"],"source":{"line":247,"path":"src/Middleware.lua"}},{"name":"ThunkMiddleware","desc":"Like its Redux counterpart, thunk middleware allows functions to be dispatched as regular actions. When a function is encountered\\nby the middleware in place of an action, that function will be intercepted and called with the arguments `MyThunk(Dispatch, GetState)`.\\n\\n```lua\\nlocal function AddCoins()\\n\\treturn function(Dispatch, GetState)\\n\\t\\tDispatch({\\n\\t\\t\\tType = \\"SetCoins\\";\\n\\t\\t\\tValue = math.random(100);\\n\\t\\t})\\n\\tend\\nend\\n\\nlocal Store = Helium.Store.new(function(Action, _, SetState)\\n\\tif Action.Type == \\"SetCoins\\" then\\n\\t\\tSetState(\\"Coins\\", Action.Value)\\n\\tend\\nend, InitialState):ApplyMiddleware(Helium.ThunkMiddleware)\\n\\nStore:Fire(AddCoins())\\n```","params":[{"name":"Store","desc":"The Store of the middleware.","lua_type":"Store"}],"returns":[{"desc":"The handler code for the middleware.","lua_type":"MiddlewareHandler"}],"function_type":"static","tags":["Middleware"],"source":{"line":288,"path":"src/Middleware.lua"}}],"properties":[],"types":[{"name":"MiddlewareHandler","desc":"","lua_type":"(NextMiddleware: (Action: BaseAction) -> ()) -> (Action: BaseAction) -> ()","source":{"line":131,"path":"src/Middleware.lua"}}],"name":"Middleware","desc":"## Enhancing the store\\n\\nMiddlewares are a [common way to enhance stores in Redux applications](https://www.codementor.io/vkarpov/beginner-s-guide-to-redux-middleware-du107uyud).\\nUp until this point, the actions we\'ve created are fairly dumb\u2014all they can really do is get and set data. What if we want our dispatched actions to do\\nmore complex things like request data from the server?\\n\\nHelium supports middlewares, which are simply functions that intercept actions upon being dispatched, and allow custom logic to be applied to them.\\nThe way middlewares intercept actions is by providing a bridge in between `Store:Fire` or `Store:Dispatch` being called and the root reducer\\nreceiving those actions that were dispatched.\\n\\nMiddlewares take the form of three nested functions:\\n\\n```lua\\nlocal function Middleware(Store)\\n\\treturn function(NextDispatch)\\n\\t\\treturn function(Action)\\n\\t\\t\\t...\\n\\t\\tend\\n\\tend\\nend\\n```\\n\\nThe first function takes in the current store that the middleware is being used on. We can call normal store functions on this object such as `SetState`, `GetState`, `Fire`, and `Connect`.\\nThe second nested function takes in `NextDispatch`. In a store with a single middleware applied, calling `NextDispatch(Action)` will forward the the action directly to the store\'s reducer.\\n\\nThe third nested function is the actual function that decides what to do with actions when they are dispatched. To keep the actions moving through to the reducer without consuming it,\\nyou can call `NextDispatch(Action)`.\\n\\n```lua\\nlocal function RedundantMiddleware(Store)\\n\\treturn function(NextDispatch)\\n\\t\\treturn function(Action)\\n\\t\\t\\tNextDispatch(Action)\\n\\t\\tend\\n\\tend\\nend\\n\\n-- Some code\\n\\nStore:ApplyMiddleware(RedundantMiddleware)\\n```\\n\\nIn the above code, `RedundantMiddleware` is a middleware that listens to actions when `Store:Fire` is called, and immediately forwards them to the store\'s reducer with no side effects.\\nLet\'s look at the source code of `LoggerMiddleware`, one of the middlewares bundled with Helium:\\n\\n```lua\\nlocal function LoggerMiddleware()\\n\\treturn function(NextMiddleware)\\n\\t\\treturn function(Action)\\n\\t\\t\\tprint(Action.Type)\\n\\t\\t\\tNextMiddleware(Action)\\n\\t\\tend\\n\\tend\\nend\\n\\nreturn LoggerMiddleware\\n```\\n\\nThis middleware is nearly equivalent to our `RedundantMiddleware`, with the one difference that the type of the action being dispatched is printed to the output console.\\nIn effect, this will \\"log\\" every action that is dispatached in our store. This can be useful for debugging actions that are dispatched through our application:\\n\\n```lua\\nlocal DEBUGGING_ENABLED = true\\nlocal Reducer, InitialState = ...\\n\\nlocal Store = Helium.Store.new(Reducer, InitialState)\\n\\nif DEBUGGING_ENABLED then\\n\\tStore:ApplyMiddleware(Helium.LoggerMiddleware)\\nend\\n```\\n\\nHelium offers a few built-in middlewares:\\n\\n* `Helium.InspectorMiddleware` - Prints out the whole action being dispatched.\\n* `Helium.LoggerMiddleware` - Prints out the action types of every action dispatched.\\n* `Helium.SpunkMiddleware` - Like `ThunkMiddleware`, allows functions to be dispatched. The only difference is that the functions being dispatched will be spawned immediately in a separate thread. This could be more ideal for Roblox development as opposed to JavaScript do to the lack of Promise objects.\\n* `Helium.ThunkMiddleware` - Like its Redux counterpart, thunk middleware allows functions to be dispatched as regular actions. When a function is encountered by the middleware in place of an action, that function will be intercepted and called with the arguments `MyThunk(Dispatch, GetState)`.\\n\\nA usage example for `SpunkMiddleware` would be an action that needs to fetch data from the server:\\n\\n_____\\n\\n### Entry point:\\n\\n```lua\\nlocal Store = Helium.Store.new(RootReducer, InitialState)\\nStore:ApplyMiddleware(Helium.SpunkMiddleware)\\n```\\n\\n### Actions module:\\n\\n```lua\\nlocal Actions = {}\\nfunction Actions.FetchCoins()\\n\\treturn function(Dispatch, GetState)\\n\\t\\t-- Where we would normally return an action here, we instead return a spawned thunk that defers our change in state.\\n\\t\\tlocal Coins = ReplicatedStorage.GetCoins:InvokeServer()\\n\\t\\tDispatch({\\n\\t\\t\\tType = \\"SetCoins\\";\\n\\t\\t\\tValue = Coins;\\n\\t\\t})\\n\\tend\\nend\\n\\nreturn Actions\\n```\\n\\n### Some component in our application:\\n\\n```lua\\nself.Janitor:Add(self.Gui.FetchCoinsButton.Activated:Connect(function()\\n\\tself.Store:Fire(Actions.FetchCoins())\\nend), \\"Disconnect\\")\\n```\\n\\nYour use case for middlewares may vary. You might not need it at all for your application; alternatively, you may find a need to write your own middlewares for debugging or managing state.\\nMiddleware-facilitated operations such as thunks are generally the best place to put logic that affect state after yielding calls, such as when retrieving data from the server.","source":{"line":125,"path":"src/Middleware.lua"}}')}}]);