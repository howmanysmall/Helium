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
