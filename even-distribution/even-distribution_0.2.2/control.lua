local DEBUG = true

scripts = {} -- custom scripts
local funcs = {} -- Functions bound to their respective game event

function dlog(message) -- Print debug message
	local tick = 0
	if game then tick = game.tick end
	local msg = tick.." [ED] "..tostring(message)
	log(msg)
	if DEBUG and game then game.print(msg) end
end

local function addScript(name) -- Add a custom script
	scripts[name] = require("scripts."..name)
end

local function registerFunc(name, id)
	funcs[id or name] = {}
	for _,script in pairs(scripts) do
		if script[name] then table.insert(funcs[id or name], script[name]) end
	end
end

local function handleEvent(event) -- Calls all script-functions with the same name as the game event that was just triggered
	for _,func in pairs(funcs[event.input_name or event.name]) do func(event) end
end

local function registerHandler(name, id) -- Register appropriate handler functions for game events if needed
	registerFunc(name, id)
	if #funcs[id or name] > 0 then 
		if id then
			script.on_event(id, handleEvent)
		else
			script[name](function(data) handleEvent{ name = name, data = data } end)
		end
	end
end

-- Load all custom scripts
addScript("util")
addScript("setup")
addScript("item-lib")
addScript("distribute")
addScript("cleanup")

-- Register every script-function with the same name as a game event to be called when it occurs
registerHandler("on_init")
registerHandler("on_load")
registerHandler("on_configuration_changed")
for name,event in pairs(defines.events) do registerHandler(name, event) end

-- Register custom input events
registerHandler("on_inventory_cleanup", "inventory-cleanup")