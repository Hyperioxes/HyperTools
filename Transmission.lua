local function boolToString(value)
	if value then
		return "true"
	end
	return "false"
end

local function stringToBool(text)
	if text == "true" then
		return true
	end
	return false

end



function importProfileFromString(profileName)
	local profile = {}
	local previous = nil                  
    local current = nil
    while true do
		current = string.find(string, "#", i+1)    
		if i == nil then break end
		if previous then

		end
		previous = current
    end


end

local types = {
	["number"] = "N",
	["boolean"] = "B",
	["string"] = "S",
}

function convertToString(exportTable)
	local exportString = "$"
	if type(exportTable) == "table" then
		for k,v in pairs(exportTable) do
			exportString = exportString..convertToString(k)..convertToString(v)
		end
	else
		if type(exportTable) == "boolean" then
			exportString = exportString.."B"..boolToString(exportTable)
		else
			exportString = exportString..types[type(exportTable)]..exportTable
		end
	end
	return exportString.."&"
end



function importFromString(importString)
	local result = {}
    local lefts = {}                   
    local n = 0
	local key = nil
	for i=0, #importString do
		local c = string.sub(importString,i,i)
		if c == "$" then
			n=n+1
			table.insert(lefts,i)
		elseif c == "&" then
			if n==1 then
				if key then
					if #lefts > 1 then
						result[key] = importFromString(string.sub(importString,lefts[1]+1,i-1))
						key = nil
					else
						local type = string.sub(importString,lefts[1]+1,lefts[1]+1)
						if type == "N" then
							result[key] = tonumber(string.sub(importString,lefts[1]+2,i-1))
						elseif type == "B" then
							result[key] = stringToBool(string.sub(importString,lefts[1]+2,i-1))
						elseif type == "S" then
							result[key] = string.sub(importString,lefts[1]+2,i-1)
						else
							result[key] = {}
						end
					end
					key = nil
				else
					local type = string.sub(importString,lefts[1]+1,lefts[1]+1)
					if type == "N" then
						key = tonumber(string.sub(importString,lefts[1]+2,i-1))
					elseif type == "B" then
						key = stringToBool(string.sub(importString,lefts[1]+2,i-1))
					else
						key = string.sub(importString,lefts[1]+2,i-1)
					end
				end
				lefts = {}
				n = 0
			else
				n=n-1
			end
		end
	end
	return result
end

