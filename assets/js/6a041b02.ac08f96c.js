"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[727],{97188:function(n){n.exports=JSON.parse('{"functions":[{"name":"Constructor","desc":"The Component\'s Constructor function. This version is for store-less components. This should be overwritten.\\n\\n```lua\\nlocal CoinsDisplay = Helium.Component.Extend(\\"CoinsDisplay\\")\\nfunction CoinsDisplay:Constructor(Parent: Instance)\\n\\tself.Gui = self.Janitor:Add(Helium.Make(\\"TextLabel\\", {\\n\\t\\tAnchorPoint = Vector2.new(0.5, 0.5);\\n\\t\\tBackgroundTransparency = 1;\\n\\t\\tPosition = UDim2.fromScale(0.5, 0.5);\\n\\t\\tSize = UDim2.fromScale(0.5, 0.5);\\n\\n\\t\\tFont = Enum.Font.Gotham;\\n\\t\\tText = \\"Coins: 1\\";\\n\\t\\tTextColor3 = Color3.new(1, 1, 1);\\n\\t\\tTextSize = 24;\\n\\n\\t\\tParent = Parent;\\n\\t}), \\"Destroy\\")\\nend\\n\\nCoinsDisplay.new(Parent) -- Shows a TextLabel with the Text == \\"Coins: 1\\".\\n```","params":[{"name":"...","desc":"The arguments you are creating the Component with.","lua_type":"any?"}],"returns":[],"function_type":"method","source":{"line":121,"path":"src/Component/BaseComponent.lua"}},{"name":"Constructor","desc":"The Component\'s Constructor function. This should be overwritten.\\n\\n```lua\\nlocal CoinsDisplay = Helium.Component.Extend(\\"CoinsDisplay\\")\\n\\nfunction CoinsDisplay:Constructor(Store, Parent: Instance)\\n\\tself.Store = Store\\n\\tself.Gui = self.Janitor:Add(Helium.Make(\\"TextLabel\\", {\\n\\t\\tAnchorPoint = Vector2.new(0.5, 0.5);\\n\\t\\tBackgroundTransparency = 1;\\n\\t\\tPosition = UDim2.fromScale(0.5, 0.5);\\n\\t\\tSize = UDim2.fromScale(0.5, 0.5);\\n\\n\\t\\tFont = Enum.Font.Gotham;\\n\\t\\tText = \\"Coins: 0\\";\\n\\t\\tTextColor3 = Color3.new(1, 1, 1);\\n\\t\\tTextSize = 24;\\n\\n\\t\\tParent = Parent;\\n\\t}), \\"Destroy\\")\\nend\\n\\ntype CoinsReduction = {Coins: number}\\n\\nCoinsDisplay.Reduction = {Coins = \\"GuiData.Coins\\"}\\nCoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat\\nfunction CoinsDisplay:Redraw(CoinsReduction: CoinsReduction)\\n\\tself.Gui.Text = \\"Coins: \\" .. CoinsReduction.Coins\\nend\\n\\nlocal CoinsStore = Helium.Store.new(function(Action, GetState, SetState)\\n\\tif Action.Type == \\"AddCoin\\" then\\n\\t\\tlocal Coins = GetState(\\"GuiData\\", \\"Coins\\")\\n\\t\\tSetState(\\"GuiData\\", \\"Coins\\", Coins + 1)\\n\\tend\\nend, {GuiData = {Coins = 0}})\\n\\nlocal MyCoinsDisplay = CoinsDisplay.new(CoinsStore, Parent) -- Shows a TextLabel with the Text == \\"Coins: 0\\".\\nfor _ = 1, 10 do\\n\\ttask.wait(1)\\n\\tCoinsStore:Fire({Type = \\"AddCoin\\"})\\nend\\n\\nMyCoinsDisplay:Destroy()\\n```","params":[{"name":"Store","desc":"The store to use for this component.","lua_type":"Store?"},{"name":"...","desc":"The arguments you are creating the Component with.","lua_type":"any?"}],"returns":[],"function_type":"method","source":{"line":172,"path":"src/Component/BaseComponent.lua"}},{"name":"Redraw","desc":"The Component\'s Redraw function. This can be overwritten if you need it to be.\\n\\n```lua\\nlocal CoinsDisplay = Helium.Component.Extend(\\"CoinsDisplay\\")\\nfunction CoinsDisplay:Constructor(Parent: Instance)\\n\\tself.Coins = 0\\n\\tself.Gui = self.Janitor:Add(Helium.Make(\\"TextLabel\\", {\\n\\t\\tAnchorPoint = Vector2.new(0.5, 0.5);\\n\\t\\tBackgroundTransparency = 1;\\n\\t\\tPosition = UDim2.fromScale(0.5, 0.5);\\n\\t\\tSize = UDim2.fromScale(0.5, 0.5);\\n\\n\\t\\tFont = Enum.Font.Gotham;\\n\\t\\tText = \\"Coins: 0\\";\\n\\t\\tTextColor3 = Color3.new(1, 1, 1);\\n\\t\\tTextSize = 24;\\n\\n\\t\\tParent = Parent;\\n\\t}), \\"Destroy\\")\\nend\\n\\nfunction CoinsDisplay:AddCoin()\\n\\tself.Coins += 1\\n\\tself.QueueRedraw()\\nend\\n\\nCoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat\\nfunction CoinsDisplay:Redraw()\\n\\tself.Gui.Text = \\"Coins: \\" .. self.Coins\\nend\\n\\nlocal MyCoinsDisplay = CoinsDisplay.new(Parent) -- Creates a TextLabel under Parent with the Text saying \\"Coins: 0\\"\\nMyCoinsDisplay:AddCoin() -- Calls :Redraw() and now the TextLabel says \\"Coins: 1\\"\\n```","params":[{"name":"ReducedState","desc":"The reduced state if `BaseComponent.Reduction` exists.","lua_type":"{[any]: any}?"},{"name":"DeltaTime","desc":"The DeltaTime since the last frame.","lua_type":"number"},{"name":"WorldDeltaTime","desc":"The world delta time since the last frame. This only exists when `RedrawBinding` == `Stepped`.","lua_type":"number?"}],"returns":[],"function_type":"method","source":{"line":216,"path":"src/Component/BaseComponent.lua"}},{"name":"Destroy","desc":"Destroys the Component and its Janitor.\\n\\n:::warning\\nThis renders the component completely unusable. You wont\' be able to call any further methods on it.\\n:::","params":[],"returns":[],"function_type":"method","source":{"line":225,"path":"src/Component/BaseComponent.lua"}},{"name":"new","desc":"The constructor of the Component. This version is for store-less components.\\n\\n```lua\\nlocal ValuePrinter = Helium.Component.Extend(\\"ValuePrinter\\")\\nfunction ValuePrinter:Constructor(Value: any)\\n\\tprint(\\"ValuePrinter:Constructor was constructed with:\\", Value)\\nend\\n\\nValuePrinter.new(1):Destroy() -- prints \\"ValuePrinter:Constructor was constructed with: 1\\"\\n```","params":[{"name":"...","desc":"The arguments you want to pass to the Component\'s constructor.","lua_type":"any?"}],"returns":[{"desc":"","lua_type":"Component<T>"}],"function_type":"static","source":{"line":249,"path":"src/Component/BaseComponent.lua"}},{"name":"new","desc":"The constructor of the Component.\\n\\n```lua\\nlocal ValuePrinterWithStore = Helium.Component.Extend(\\"ValuePrinterWithStore\\")\\nfunction ValuePrinterWithStore:Constructor(Store, Value: any)\\n\\tself.Store = Store\\n\\tprint(\\"ValuePrinterWithStore:Constructor was constructed with:\\", Value)\\nend\\n\\nValuePrinterWithStore.new(Helium.Store.new(function() end, {}), 1):Destroy() -- prints \\"ValuePrinterWithStore:Constructor was constructed with: 1\\"\\n```","params":[{"name":"Store","desc":"The store to use for this component.","lua_type":"Store?"},{"name":"...","desc":"The extra arguments you want to pass to the Component\'s constructor.","lua_type":"any?"}],"returns":[{"desc":"","lua_type":"Component<T>"}],"function_type":"static","source":{"line":267,"path":"src/Component/BaseComponent.lua"}}],"properties":[{"name":"Janitor","desc":"The component\'s Janitor. You can add whatever you want cleaned up on `:Destroy()` to this.\\n\\n```lua\\nlocal PrintOnDestroy = Helium.Component.Extend(\\"PrintOnDestroy\\")\\nfunction PrintOnDestroy:Constructor(Message: string)\\n\\tself.Janitor:Add(function()\\n\\t\\tprint(Message)\\n\\tend, true)\\nend\\n\\nPrintOnDestroy.new(\\"I was destroyed!\\"):Destroy() -- Prints \\"I was destroyed!\\"\\n```","lua_type":"Janitor","source":{"line":31,"path":"src/Component/BaseComponent.lua"}},{"name":"GetReducedState","desc":"This function returns the reduced state of the component\'s store.","lua_type":"() -> {[string]: string}","source":{"line":37,"path":"src/Component/BaseComponent.lua"}},{"name":"QueueRedraw","desc":"This function queues a redraw of the component.\\n\\n```lua\\nlocal CoinsDisplay = Helium.Component.Extend(\\"CoinsDisplay\\")\\nfunction CoinsDisplay:Constructor(Parent: Instance)\\n\\tself.Coins = 0\\n\\tself.Gui = self.Janitor:Add(Helium.Make(\\"TextLabel\\", {\\n\\t\\tAnchorPoint = Vector2.new(0.5, 0.5);\\n\\t\\tBackgroundTransparency = 1;\\n\\t\\tPosition = UDim2.fromScale(0.5, 0.5);\\n\\t\\tSize = UDim2.fromScale(0.5, 0.5);\\n\\n\\t\\tFont = Enum.Font.Gotham;\\n\\t\\tText = \\"Coins: 0\\";\\n\\t\\tTextColor3 = Color3.new(1, 1, 1);\\n\\t\\tTextSize = 24;\\n\\n\\t\\tParent = Parent;\\n\\t}), \\"Destroy\\")\\nend\\n\\nfunction CoinsDisplay:AddCoin()\\n\\tself.Coins += 1\\n\\tself.QueueRedraw() -- Queues the Component to be redrawn.\\nend\\n\\nCoinsDisplay.RedrawBinding = Helium.RedrawBinding.Heartbeat\\nfunction CoinsDisplay:Redraw()\\n\\tself.Gui.Text = \\"Coins: \\" .. self.Coins\\nend\\n\\nlocal MyCoinsDisplay = CoinsDisplay.new(Parent) -- Shows a TextLabel with the Text == \\"Coins: 0\\".\\nMyCoinsDisplay:AddCoin() -- Now it says \\"Coins: 1\\"\\n```","lua_type":"() -> ()","source":{"line":76,"path":"src/Component/BaseComponent.lua"}},{"name":"ClassName","desc":"The Component\'s ClassName, which is assigned from the first argument of `Component.Extend`.","lua_type":"string","source":{"line":82,"path":"src/Component/BaseComponent.lua"}},{"name":"RedrawBinding","desc":"The Component\'s RedrawBinding. This is used to determine when the Component\'s `:Redraw()` function is called.","lua_type":"RedrawBinding","source":{"line":88,"path":"src/Component/BaseComponent.lua"}},{"name":"Reduction","desc":"The reduction of the store. If this exists, it\'ll be passed as the first argument of `:Redraw()`.","lua_type":"{[string]: string}?","source":{"line":94,"path":"src/Component/BaseComponent.lua"}}],"types":[],"name":"BaseComponent","desc":"","source":{"line":11,"path":"src/Component/BaseComponent.lua"}}')}}]);