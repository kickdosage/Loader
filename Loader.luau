--!nonstrict
--- Services
local RunService = game:GetService("RunService")

--- Types
export type StartOptions = {
	Path: Instance,
	DeepLoad: boolean?,

	Priorities: { string }?,
	Predicate: ((ModuleScript) -> boolean)?,

	MethodName: string,

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

--- Module
local Loader = {}

--- Module Functions
function Loader.Start(StartOptions: StartOptions)
	local StartMessage = StartOptions.StartMessage
	if StartMessage then
		xprint(StartMessage)
	end

	local PathContent = StartOptions.DeepLoad and StartOptions.Path:GetDescendants() or StartOptions.Path:GetChildren()

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

		if StartOptions.Predicate and not (StartOptions.Predicate(ModuleScript)) then
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

	if StartOptions.Priorities then
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

		if type(Module) == "table" and type(Module[StartOptions.MethodName]) == "function" then
			local PrintMessage = StartOptions.PrintMessage
			if PrintMessage then
				xprint(string.format(PrintMessage, ModuleScript.Name))
			end

			if StartOptions.Priorities and StartOptions.Priorities[Index] then
				Module[StartOptions.MethodName](Module)
			else
				task.spawn(Module[StartOptions.MethodName], Module)
			end
		end
	end

	local EndMessage = StartOptions.EndMessage
	if EndMessage then
		xwarn(EndMessage)
	end
end

--- Export
return Loader
