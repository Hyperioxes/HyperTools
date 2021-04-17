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


function HT_findContainer(tracker,i)
	if tracker.parent == "HT_Trackers" then
		if tracker.type == "Group Member" and i then
			return HT_Trackers:GetNamedChild(tracker.name.."_Group"..i)
		else
			return HT_Trackers:GetNamedChild(tracker.name.."_"..tracker.type)
		end
	end
	return HT_findContainer(HTSV.trackers[tracker.parent],i):GetNamedChild(tracker.name.."_"..tracker.type)
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
		_,_,_,numOfItems = GetItemLinkSetInfo(itemSetitemSet,true)
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

function HT_pickAnyKey(array)
	for k,_ in pairs(array) do
		return k
	end
	return "none"
end

function HT_pickAnyElement(array)
	for _,v in pairs(array) do
		return v
	end
	return "none"
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

function HT_generateNewNate(name,number)
	for k,v in pairs(HTSV.trackers) do
		if k==name..number then
			return HT_generateNewNate(name,number+1)
		end
	end
	return name..number
end

function HT_nullify(t)
	t.stacks = {}
	t.expiresAt = {}
	t.duration = {}
	t.max = 0
	t.current = 0
end