local Enumerator = require(script.Parent.Utility.Enumerator)

type EnumeratorItem<Value> = Enumerator.EnumeratorItem<Value>
export type RedrawBinding = {
	Heartbeat: EnumeratorItem<string>,
	RenderStep: EnumeratorItem<string>,
	RenderStepTwice: EnumeratorItem<string>,
	Stepped: EnumeratorItem<string>,
} & Enumerator.EnumeratorObject<string>

local RedrawBinding: RedrawBinding = Enumerator("RedrawBinding", {"Heartbeat", "RenderStep", "RenderStepTwice", "Stepped"}) :: RedrawBinding

local Enums = {}
Enums.RedrawBinding = RedrawBinding
return Enums
