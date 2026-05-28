--!nonstrict
local RunService = game:GetService("RunService")

export type Predicate = (ModuleScript) -> boolean

export type StartOptions = {
	path: Instance,
	deep_load: boolean?,

	priorities: { string }?,
	predicate: ((ModuleScript) -> boolean)?,

	method_name: string?,

	start_message: string?,
	print_message: string?,
	end_message: string?,
}

const LOG_IDENTIFIER = RunService:IsServer() and "[S]" or "[C]"

local function xprint(...)
	print(LOG_IDENTIFIER, ...)
end

local function xwarn(...)
	warn(LOG_IDENTIFIER, ...)
end

local loader = {}

function loader.matches_name(Pattern: string)
	return function(ModuleScript: ModuleScript)
		if ModuleScript.Name:match(Pattern) then
			return true
		end

		return false
	end
end

function loader.start(start_options: StartOptions)
	local path = start_options.path
	local deep_load = if type(start_options.deep_load) == "boolean" then start_options.deep_load else true
	local priorities = start_options.priorities
	local predicate = start_options.predicate
	local method_name = start_options.method_name or "init"

	local start_message = start_options.start_message
	local print_message = start_options.print_message
	local end_message = start_options.end_message

	if start_message then
		xwarn(start_message)
	end

	local path_content = deep_load and path:GetDescendants() or path:GetChildren()

	local priority_map = {}
	local prioritized_scripts = {}
	local remaining_scripts = {}

	if start_options.priorities then
		for index, name in start_options.priorities do
			priority_map[name] = index
		end
	end

	for _, module_script in path_content :: { Instance } do
		if not module_script:IsA("ModuleScript") then
			continue
		end

		if predicate and not (predicate(module_script)) then
			continue
		end

		local priority_index = priority_map[module_script.Name]
		if priority_index then
			prioritized_scripts[priority_index] = module_script
		else
			table.insert(remaining_scripts, module_script)
		end
	end

	local final_order = {}

	if priorities then
		for index = 1, #prioritized_scripts do
			local module_script = prioritized_scripts[index]
			final_order[index] = module_script
		end
	end

	for _, module_script in remaining_scripts do
		table.insert(final_order, module_script)
	end

	for index = 1, #final_order do
		local module_script = final_order[index]
		local module = require(module_script)

		if type(module) == "table" and type(module[method_name]) == "function" then
			if print_message then
				xprint(string.format(print_message, module_script.Name))
			end
			
			if priorities and priorities[index] then
				module[method_name](module)
			else
				task.spawn(module[method_name], module)
			end
		end
	end

	if end_message then
		xwarn(end_message)
	end
end

return loader
