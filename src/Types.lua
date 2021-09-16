export type BaseAction = {Type: any}

-- stylua: ignore
export type Reducer = (
	Action: BaseAction,
	Get: (...any) -> any,
	Set: (...any) -> ()
) -> ()

export type GenericFunction = () -> ()
export type GenericTable = {[any]: any}

return false
