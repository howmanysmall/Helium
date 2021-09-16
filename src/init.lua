--!strict
local GlobalConfiguration = require(script.GlobalConfiguration)
local CombineReducers = require(script.CombineReducers)
local MakeActionCreator = require(script.MakeActionCreator)
local Store = require(script.Store)

local Component = require(script.Component)
local Enums = require(script.Enums)
local Make = require(script.Make)
local Janitor = require(script.Janitor)

local InspectorMiddleware = require(script.Middlewares.InspectorMiddleware)
local LoggerMiddleware = require(script.Middlewares.LoggerMiddleware)
local SpunkMiddleware = require(script.Middlewares.SpunkMiddleware)
local ThunkMiddleware = require(script.Middlewares.ThunkMiddleware)

local Strict = require(script.Utility.Strict)
local _Types = require(script.Types)

export type BaseAction = _Types.BaseAction
export type BaseComponent = Component.BaseComponent
export type RedrawBinding = Enums.RedrawBinding
export type Reducer = _Types.Reducer
export type Store = Store.Store

local RedrawBinding: RedrawBinding = Enums.RedrawBinding :: RedrawBinding
local SHOULD_LOCK_HELIUM = true

local Helium = {
	SetGlobalConfiguration = GlobalConfiguration.Set;
	SetGlobalConfig = GlobalConfiguration.Set;
	SetConfiguration = GlobalConfiguration.Set;
	SetConfig = GlobalConfiguration.Set;

	CreateStore = Store.new;
	CombineReducers = CombineReducers;
	MakeActionCreator = MakeActionCreator;
	Store = Store;

	Component = Component;
	RedrawBinding = RedrawBinding;
	Make = Make;
	Janitor = Janitor;

	InspectorMiddleware = InspectorMiddleware;
	LoggerMiddleware = LoggerMiddleware;
	SpunkMiddleware = SpunkMiddleware;
	ThunkMiddleware = ThunkMiddleware;
}

if not SHOULD_LOCK_HELIUM then
	return Helium
else
	return Strict(Helium, false, "Helium")
end
