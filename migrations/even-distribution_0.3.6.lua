
-- Update helper metatables
local function refreshHelpers(obj)
	if type(obj) == "table" and not obj.__self then 
		for key,val in pairs(obj) do
			refreshHelpers(val)
		end

		if rawget(obj, "__on") ~= nil then
			rawset(obj, "__mt", "helpers")
		end
	end
end

refreshHelpers(global)



-- Update player cache metatables
for __,cache in pairs(global.cache) do
	rawset(cache.markers, "__mt", "entityAsIndex")
	rawset(cache.entities, "__mt", "entityAsIndex")
end


log("Even Distribution: Global metatables have been updated")