local Debug = require(script.Parent.Debug)

local DEFAULT_CONFIGURATION = {
	-- Enables `debug.profilebegin` in the component redraw function.
	ProfileRedraw = false;

	-- Enables type checking internally.
	RunTypeChecking = false;

	-- Runs an assert check when QueueRedraw is called to validate that a component's RedrawBinding is correct.
	SafeRedrawCheck = false;

	-- Enables using the V2 version of CombineReducers.
	UseCombineReducersV2 = true;

	-- Enables using a switch statement for QueueRedraw. This won't be checked every QueueRedraw since performance is the goal here, only once when `Component:Constructor` is called.
	UseSwitchStatementForQueueRedraw = true;
}

local DefaultConfigurationKeys = {}
for Key in next, DEFAULT_CONFIGURATION do
	table.insert(DefaultConfigurationKeys, Key)
end

export type ConfigurationValues = {
	ProfileRedraw: boolean?,
	RunTypeChecking: boolean?,
	SafeRedrawCheck: boolean?,
	UseCombineReducersV2: boolean?,
	UseSwitchStatementForQueueRedraw: boolean?,
}

local Configuration = {}

function Configuration.new()
	local self = {}

	self.CurrentConfiguration = setmetatable({}, {
		__index = function(_, Index)
			Debug.Error("Invalid configuration key %q - valid configuration keys are: %q", Index, DefaultConfigurationKeys)
		end;
	})

	self.Get = function()
		return Configuration.SuperGet(self)
	end

	self.Set = function(ConfigurationValues: ConfigurationValues)
		return Configuration.SuperSet(self, ConfigurationValues)
	end

	self.Scoped = function(ConfigurationValues: ConfigurationValues, Function: () -> any)
		return Configuration.SuperScoped(self, ConfigurationValues, Function)
	end

	return self
end

function Configuration:SuperGet(): ConfigurationValues
	return self.CurrentConfiguration
end

function Configuration:SuperSet(ConfigurationValues: ConfigurationValues)
	for Key, Value in next, ConfigurationValues do
		if DEFAULT_CONFIGURATION[Key] == nil then
			Debug.Error("Invalid global configuration key %q - valid configuration keys are: %q", Key, DefaultConfigurationKeys)
		end

		if type(Value) ~= "boolean" then
			Debug.Error("Invalid value %q for global configuration key %q - expected a boolean.", Value, Key)
		end

		self.CurrentConfiguration[Key] = Value
	end
end

function Configuration:SuperScoped(ConfigurationValues: ConfigurationValues, Function: () -> any)
	local PreviousValues = {}
	for Key, Value in next, self.CurrentConfiguration do
		PreviousValues[Key] = Value
	end

	self.Set(ConfigurationValues)
	local Success, Value = pcall(Function)
	self.Set(PreviousValues)

	Debug.Assert(Success, Value)
end

export type HeliumConfiguration = typeof(Configuration.new())
return Configuration
