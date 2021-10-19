export type BaseAction = {Type: any} & {[any]: any}

-- stylua: ignore
export type Reducer = (
	Action: BaseAction,
	Get: (...any) -> any,
	Set: (...any) -> ()
) -> ()

export type GenericFunction = () -> ()
export type GenericTable = {[any]: any}

export type Map<Index, Value> = {[Index]: Value}

return false
