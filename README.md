# Loader
A simple loader module that supports script priorities.

## Types
```luau
export type StartOptions = {
	Path: Instance,
	DeepLoad: boolean? -- defaults to true,

	Priorities: { string }?,
	Predicate: ((ModuleScript) -> boolean)?,

	MethodName: string? -- defaults to 'Initialize',

	PrintMessage: string?,
	StartMessage: string?,
	EndMessage: string?,
}
```

## Code sample:
```luau
local Loader = require(path.to.Loader)

local Path = path.to.scripts

local Priorities = {
    "PlayerDataService",
}

Loader.Start({
    Path = Path,
    DeepLoad = true,

    Priorities = Priorities,
    Predicate = Loader.MatchesName("Service$"),
    
    MethodName = "Initialize",

    StartMessage = ".:: INITIALIZING SERVER ::.",
    PrintMessage = "> Initializing %s",
    EndMessage = ".:: FINISHED INITIALIZING SERVER ::.",
})
```