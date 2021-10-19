---
sidebar_position: 3
---

# Why use Helium?

I know there's a few libraries that you could use instead of Helium, such as Fusion and Roact, but here's why I believe you should use Helium instead of either of those.

### Performance

This is easily Helium's strength, as it's been proven time and time again that the only faster way to do UI is to not use any library. It consistently was the top performer in the three UI Stress Test places I have.

- [UI Stress Test 1](https://www.roblox.com/games/7314076747/A)
- [UI Stress Test 2](https://www.roblox.com/games/7404177795/B)
- [UI Stress Test 3](https://www.roblox.com/games/7539397131/C)

As a matter of fact, the framerate counter in UI Stress Test 3 was done with Helium, and Helium still performed better than either Fusion or Roact.

### Lifecycle

Helium does support lifecycle events, but not in the same way or as nicely as Roact, but it's significantly better than Fusion's lack of lifecycle. The main "lifecycle" parts of Helium Components are four signals called `Destroying`, `Destroyed`, `WillRedraw`, and `DidRedraw`.

- `Destroyed` is called when the component is destroyed completely.
- `Destroying` is called when the component is being destroyed.
- `DidRedraw` is called right after `Component:Redraw` is called.
- `WillRedraw` is called right before `Component:Redraw` is called.

I've tested the performance cost of the Redraw signals, and they're not as big of a loss. It still performs at the top. If you wish to use these, you must add them to the `Helium.Component.Extend` function's second parameter.

### Native Janitor Support

Janitor is a top tier way to manage your Instances, connections, and whatnot. You can read more about it on my documentation for [Janitor](https://howmanysmall.github.io/Janitor/).

### Store Class

Helium has a Store class similar to [Redux](https://redux.js.org/) and [Rodux](https://github.com/Roblox/rodux/ "Rodux by Roblox") made just for it. It's incredibly fast and fairly simple to use. You can check out the [documentation](/api/Store) for more.
