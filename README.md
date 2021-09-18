# Helium

Based on the fantastic [Rocrastinate](https://github.com/headjoe3/Rocrastinate/).

## Differences from Rocrastinate

- Replaced Maid with [Janitor](https://github.com/howmanysmall/Janitor).
- Removed the FastSpawn library with the task library.
- PascalCase is superior to camelCase.
- The Store is now using traditional OOP instead of a function that returns a table.
- RedrawBindings are now Enums instead of just strings. This allows autofill if you're using the "Luau-Powered Autocomplete & Language Features" beta in Studio.
- You can now redraw on Stepped.
- The Store object now has two different names for dispatching and subscribing, being `Connect` and `Dispatch` for dispatching and `Connect` and `Subscribe` for subscribing.
- Added the `MakeActionCreator` function to easily make functions.
- Typed Luau support.
- Added `Make` if you want to use that syntax for some reason.
- Added a GlobalConfiguration which can be used to configure some internal behavior like typechecking.

## Building

If you want to build the project and you have LuaJIT installed, you can use the following command in the root directory. Note that this still requires Rojo to build: `luajit Build.lua`

If you don't have LuaJIT installed, you can use the following command in the root directory. This again, still requires Rojo. `rojo build -o Helium.rbxm build.project.json`

## Usage

```Lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Helium = require(ReplicatedStorage.Helium)

local TextLabel = Helium.Component.Extend("TextLabel")

export type Properties = {
    Font: Enum.Font,
    Text: string,
    TextSize: number,
}

function TextLabel:Constructor(Parent: Instance, Properties: Properties)
    self.Font = Properties.Font
    self.Text = Properties.Text
    self.TextSize = Properties.TextSize

    self.Parent = Parent
    self.ParentChanged = false

    self.LabelSize = TextService:GetTextSize(self.Text, self.TextSize, self.Font, Vector2.new(math.huge, math.huge))

    local TextLabel: TextLabel = self.Janitor:Add(Instance.new("TextLabel"), "Destroy")
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextSize = self.TextSize
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Text = self.Text
    TextLabel.Font = self.Font
    TextLabel.Size = UDim2.fromOffset(self.LabelSize.X + 30, self.LabelSize.Y + 10)
    TextLabel.Parent = Parent

    self.Gui = TextLabel
end

function TextLabel:SetFont(Font: Enum.Font)
    self.Font = Font
    self.LabelSize = TextService:GetTextSize(self.Text, self.TextSize, self.Font, Vector2.new(math.huge, math.huge))
    self.QueueRedraw()
    return self
end

function TextLabel:SetText(Text: string)
    self.Text = Text
    self.LabelSize = TextService:GetTextSize(self.Text, self.TextSize, self.Font, Vector2.new(math.huge, math.huge))
    self.QueueRedraw()
    return self
end

function TextLabel:SetTextSize(TextSize: number)
    self.TextSize = TextSize
    self.LabelSize = TextService:GetTextSize(self.Text, self.TextSize, self.Font, Vector2.new(math.huge, math.huge))
    self.QueueRedraw()
    return self
end

function TextLabel:SetParent(Parent: Instance)
    self.Parent = Parent
    self.ParentChanged = true
    self.QueueRedraw()
    return self
end

TextLabel.RedrawBinding = Helium.RedrawBinding.Heartbeat
function TextLabel:Redraw()
    local TextLabel: TextLabel = self.Gui

    TextLabel.TextSize = self.TextSize
    TextLabel.Text = self.Text
    TextLabel.Font = self.Font
    TextLabel.Size = UDim2.fromOffset(self.LabelSize.X + 30, self.LabelSize.Y + 10)

    if self.ParentChanged then
        self.ParentChanged = false
        TextLabel.Parent = self.Parent
    end
end

return TextLabel
```

### Credits / External Dependencies

- [Debug](https://github.com/RoStrap/Debugging/blob/master/Debug.lua) by Validark, which is used for the `Debug.DirectoryToString` and the `Debug.Assert` / `Debug.Error` / `Debug.Warn` functions.
- [Enumerator](https://github.com/howmanysmall/enumerator) by HowManySmall, which is used for the RedrawBinding.
- [Fmt](https://github.com/Nezuo/fmt) by Nezuo, which is used for printing out tables.
- [Janitor](https://github.com/howmanysmall/Janitor) by Validark and HowManySmall, which is used for cleanup up in Helium.
- [Rocrastinate](https://github.com/headjoe3/Rocrastinate) by Databrain, which was used as the basis of Helium.
- [t](https://github.com/osyrisrblx/t) by Osyris, which is used for type checking internally.
