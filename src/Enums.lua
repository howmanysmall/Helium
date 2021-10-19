local Enumerator = require(script.Parent.Utility.Enumerator)

type EnumeratorItem<Value> = Enumerator.EnumeratorItem<Value>
export type RedrawBinding = {
	Heartbeat: EnumeratorItem<string>,
	RenderStep: EnumeratorItem<string>,
	RenderStepTwice: EnumeratorItem<string>,
	Stepped: EnumeratorItem<string>,
} & Enumerator.EnumeratorObject<string>

--[=[
	An Enum representing on which binding the Component will be redrawn on.
	@interface RedrawBinding
	@tag Enum
	@within Helium
	.Heartbeat "Heartbeat" -- Redraw on the next `Heartbeat` step.
	.RenderStep "RenderStep" -- Redraw on the next `RenderStep` step.
	.RenderStepTwice "RenderStepTwice" -- Redraw on two `RenderStep` steps.
	.Stepped "Stepped" -- Redraw on the next `Stepped` step.
]=]
--[=[
	@prop RedrawBinding RedrawBinding
	@within Helium
	@readonly
	@tag Enums
	An [Enumerator](https://github.com/howmanysmall/enumerator/) Enum containing all of the RedrawBindings.

	:::info Case Change
	To keep consistent with the rest of the style of Helium, all the methods of Enumerator are PascalCase.
	:::
]=]
local RedrawBinding: RedrawBinding = Enumerator("RedrawBinding", {"Heartbeat", "RenderStep", "RenderStepTwice", "Stepped"}) :: RedrawBinding

local Enums = {}
Enums.RedrawBinding = RedrawBinding
return Enums
