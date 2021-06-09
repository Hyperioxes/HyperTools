function getDecimals(time,number)
	time = math.floor(time*(10^number))/(10^number)
	local counter = 0
	for i=1, number do
		if time%(10^(-number+1)) == 0 then
			counter = i
		end
	end
	for n=1, counter do
		if n == 1 then
			time = time.."."
		end
		time = time.."0"
	end
	return time
end

function getTrackerFromName(name,table)
	if name == "HT_Trackers" then return HTSV.trackers end
	for k,v in pairs(table) do
		if k == name then return v end
		if getTrackerFromName(name,v.children) then return getTrackerFromName(name,v.children) end
	end
end


function HT_findContainer(tracker,i)
	
	if tracker == HTSV.trackers then
		return HT_Trackers
	end
	if tracker.type == "Group Member" and i then
		return HT_findContainer(getTrackerFromName(tracker.parent,HTSV.trackers),i):GetNamedChild(tracker.name.."_Group"..i)
	else
		return HT_findContainer(getTrackerFromName(tracker.parent,HTSV.trackers),i):GetNamedChild(tracker.name.."_"..tracker.type)
	end
end

function HT_changeLock(t,setTo)
	if t.name ~= 'none' then
		if t.parent ~= "HT_Trackers" and getTrackerFromName(t.parent,HTSV.trackers).type == "Group Member" then 
			for i=1,12 do
				HT_findContainer(t,i):SetMovable(setTo)
			end
		else 
			HT_findContainer(t):SetMovable(setTo)
		end
	end
	for k,v in pairs(t.children) do
		HT_changeLock(v,setTo)
	end
end

function HT_removeGender(name)
	b = string.find(name,"%^")
	if b then
		name = string.sub(name,1,b-1)
	end
	return name
end


function HT_checkIfSkillSlotted(skillIDTable)
		if next(skillIDTable) == nil then
			return true,0
		end
		for _,skillID in pairs(skillIDTable) do
			for i = 3, 8 do
				local slot1 = GetSlotBoundId(i, HOTBAR_CATEGORY_PRIMARY)
				local slot2 = GetSlotBoundId(i, HOTBAR_CATEGORY_BACKUP)
				if skillID == slot1 or skillID == slot2 then
					return true,skillID
				end
			end
		end
		return false,0
end


function HT_checkIfItemSetsEquipped(requiredNumberOfPieces,itemSetTable)
	if next(itemSetTable) == nil then
		return true
	end
	for _,itemSet in pairs(itemSetTable) do
		local numOfItems = 0
		_,_,_,numOfItems = GetItemLinkSetInfo(itemSet,true)
		if numOfItems>=requiredNumberOfPieces then
			return true
		end
	end
	return false
end


function HT_checkIfZone(zonesTable)
	if next(zonesTable) == nil then
		return true
	end
	for _,zone in pairs(zonesTable) do
		if GetUnitZone("player") == zone then
			return true
		end
	end
	return false
end

function HT_checkIfBoss(bossesTable)
	if next(bossesTable) == nil then
		return true
	end
	for _,boss in pairs(bossesTable) do
		if GetUnitName("boss1") == boss then
			return true
		end
	end
	return false
end


function HT_pickAnyKey(array)
	for k,_ in pairs(array) do
		return k
	end
	return "none"
end


function HT_pickAnyElement(array,noneOverride)
	for _,v in pairs(array) do
		return v
	end
	return noneOverride or "none"
end

function HT_deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[HT_deepcopy(orig_key)] = HT_deepcopy(orig_value)
        end
        setmetatable(copy, HT_deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function HT_generateNewName(name,number)
	local newName = name.."("..number..")"
	if getTrackerFromName(newName,HTSV.trackers) then
		return HT_generateNewName(name,number+1)
	end
	return newName
end

function HT_nullify(t)
	t.stacks = {}
	t.expiresAt = {}
	t.duration = {}
	t.max = 0
	t.current = 0
	for k,v in pairs(t.children) do
		HT_nullify(v)
	end
end