# Loader
A simple loader module that supports script priorities.

## Types
```luau
export type StartOptions = {
	path: Instance,
	deep_load: boolean? -- defaults to true,

	priorities: { string }?,
	predicate: ((ModuleScript) -> boolean)?,

	method_name: string? -- defaults to 'init',

	print_message: string?, -- the message to print when the method is being called. %s -> ModuleScript.Name
	start_message: string?,
	end_message: string?,
}
```

## Code sample:
```luau
local loader = require(path.to.loader)

local path = path.to.scripts

local priorities = {
    "player_data_service",
}

loader.start({
    path = path,
    deep_load = true,

    priorities = priorities,
    predicate = loader.matches_name("service$"),
    
    method_name = "init",

    start_message = ".:: INITIALIZING SERVER ::.",
    print_message = "> Initializing %s",
    end_message = ".:: FINISHED INITIALIZING SERVER ::.",
})
```