---
sidebar_position: 4
---

# Why I modified Rocrastinate

Helium is after all a fork of Rocrastinate. I've always loved the library and I wished it was updated still, so I took the updating into my own hands.

I've added quite a few things to the library over the base version of Rocrastinate, being:

- Janitor over Maid.
- RedrawBinding is an Enum to add autofill support.
- PascalCase for the entire API.
- Lifecycle events for Components.
- Store is now a metatable class instead of a function that returns a table.
- Components can now be redrawn on `Stepped` in addition to `Heartbeat`, `RenderStep`, and `RenderStepTwice`.
- Various small optimizations that can be configured using the GlobalConfiguration object.
- The `Make` function for easy Instance creation.
- `MakeActionCreator` makes it less annoying to create action creators.
- A port of [Flipper](https://github.com/Reselim/Flipper) for Helium Components, called [FlipperHelium](https://github.com/howmanysmall/FlipperHelium), which is used for animation.

The library itself may be old but it's extremely fast, and has basically all you could need for a UI library.
