--!nonstrict
--- Services
local RunService = game:GetService("RunService")

--- Types
export type Predicate = (ModuleScript) -> boolean

export type StartOptions = {
	Path: Instance,
	DeepLoad: boolean?,

	Priorities: { string }?,
	Predicate: ((ModuleScript) -> boolean)?,

	MethodName: string?,

	PrintMessage: string?,
	StartMessage: string?,
	EndMessage: string?,
}

--- Constants
local LOG_IDENTIFIER = RunService:IsServer() and "[S]" or "[C]"

--- Functions
local function xprint(...)
	print(LOG_IDENTIFIER, ...)
end

local function xwarn(...)
	warn(LOG_IDENTIFIER, ...)
end

--- Functions
local function FinalizeDeepLoadOption(DeepLoadOption: boolean?)
	if typeof(DeepLoadOption) == "boolean" then
		return DeepLoadOption 
	end

	return true
end

--- Module
local Loader = {}

--- Module Functions
function Loader.MatchesName(Pattern: string)
	return function(ModuleScript: ModuleScript)
		if ModuleScript.Name:match(Pattern) then
			return true
		end

		return false
	end
end

function Loader.Start(StartOptions: StartOptions)
	local Path = StartOptions.Path
	local DeepLoad = FinalizeDeepLoadOption(StartOptions.DeepLoad)
	local Priorities = StartOptions.Priorities
	local Predicate = StartOptions.Predicate
	local MethodName = StartOptions.MethodName
	local StartMessage = StartOptions.StartMessage
	local PrintMessage = StartOptions.PrintMessage
	local EndMessage = StartOptions.EndMessage

	if StartMessage then
		xprint(StartMessage)
	end

	local PathContent = DeepLoad and Path:GetDescendants() or Path:GetChildren()

	local PriorityMap = {}
	local PrioritizedScripts = {}
	local RemainingScripts = {}

	if StartOptions.Priorities then
		for Index, Name in StartOptions.Priorities do
			PriorityMap[Name] = Index
		end
	end

	for _, ModuleScript in PathContent :: { Instance } do
		if not ModuleScript:IsA("ModuleScript") then
			continue
		end

		if Predicate and not (Predicate(ModuleScript)) then
			continue
		end

		local PriorityIndex = PriorityMap[ModuleScript.Name]
		if PriorityIndex then
			PrioritizedScripts[PriorityIndex] = ModuleScript
		else
			table.insert(RemainingScripts, ModuleScript)
		end
	end

	local FinalOrder = {}

	if Priorities then
		for Index = 1, #PrioritizedScripts do
			local ModuleScript = PrioritizedScripts[Index]
			FinalOrder[Index] = ModuleScript
		end
	end

	for _, ModuleScript in RemainingScripts do
		table.insert(FinalOrder, ModuleScript)
	end

	for Index = 1, #FinalOrder do
		local ModuleScript = FinalOrder[Index]
		local Module = require(ModuleScript)

		if type(Module) == "table" and type(Module[MethodName]) == "function" then
			if PrintMessage then
				xprint(string.format(PrintMessage, ModuleScript.Name))
			end

			if Priorities and Priorities[Index] then
				Module[MethodName](Module)
			else
				task.spawn(Module[MethodName], Module)
			end
		end
	end

	if EndMessage then
		xwarn(EndMessage)
	end
end

--- Export
return Loader
