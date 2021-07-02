function HT_getDecimals(time, number)
    time = math.floor(time * (10 ^ number)) / (10 ^ number)
    local counter = 0
    for i = 1, number do
        if time % (10 ^ (-number + 1)) == 0 then
            counter = i
        end
    end
    for n = 1, counter do
        if n == 1 then
            time = time .. "."
        end
        time = time .. "0"
    end
    return time
end

function HT_removeElementFromTable(table, element)
    for k,v in pairs(table) do
        if v==element then
            table[k] = nil
            return
        end
    end
end


function HT_getTrackerFromName(name, table)
    if name == "HT_Trackers" then
        return HTSV.trackers
    end
    for k, v in pairs(table) do
        if k == name then
            return v
        end
        if HT_getTrackerFromName(name, v.children) then
            return HT_getTrackerFromName(name, v.children)
        end
    end
end

function HT_findContainer(tracker, i)
    if tracker.name == 'none' then
        return nil
    end
    if tracker == HTSV.trackers then
        return HT_Trackers
    end
    if tracker.type == "Group Member" and i then
        return HT_findContainer(HT_getTrackerFromName(tracker.parent, HTSV.trackers), i):GetNamedChild(tracker.name .. "_Group" .. i)
    else
        return HT_findContainer(HT_getTrackerFromName(tracker.parent, HTSV.trackers), i):GetNamedChild(tracker.name .. "_" .. tracker.type)
    end
end

function HT_changeLock(t, setTo)
    if t.name ~= 'none' then
        if t.parent ~= "HT_Trackers" and HT_getTrackerFromName(t.parent, HTSV.trackers).type == "Group Member" then
            for i = 1, 12 do
                HT_findContainer(t, i):SetMovable(setTo)
            end
        else
            HT_findContainer(t):SetMovable(setTo)
        end
    end
    for _, v in pairs(t.children) do
        HT_changeLock(v, setTo)
    end
end

function HT_removeGender(name)
    b = string.find(name, "%^")
    if b then
        name = string.sub(name, 1, b - 1)
    end
    return name
end

function HT_checkIfSkillSlotted(skillIDTable)
    if next(skillIDTable) == nil then
        return true, 0
    end
    for _, skillID in pairs(skillIDTable) do
        for i = 3, 8 do
            local slot1 = GetSlotBoundId(i, HOTBAR_CATEGORY_PRIMARY)
            local slot2 = GetSlotBoundId(i, HOTBAR_CATEGORY_BACKUP)
            if skillID == slot1 or skillID == slot2 then
                return true, skillID
            end
        end
    end
    return false, 0
end

--INPUT: Table of itemLinks
--OUTPUT: True if any of the item sets in the table is active, False if none of them is active
function HT_checkIfItemSetsEquipped(itemSetTable)
    if next(itemSetTable) == nil then
        --If input table is empty return true
        return true
    end
    for _, itemSet in pairs(itemSetTable) do
        local numOfItems = 0
        local setName
        _, setName, _, numOfItems, maxEquipped = GetItemLinkSetInfo(itemSet, true) --This function instantly gets number of pieces worn but it ignores offbar

        --Check other bar's gear and add them if the set matches
        local additonalBarToCheck = { EQUIP_SLOT_BACKUP_MAIN, EQUIP_SLOT_BACKUP_OFF } --By default check backbar
        if GetActiveWeaponPairInfo() == ACTIVE_WEAPON_PAIR_BACKUP then
            --If currently on backbar, check frontbar instead
            additonalBarToCheck = { EQUIP_SLOT_MAIN_HAND, EQUIP_SLOT_OFF_HAND }
        end
        for _, v in pairs(additonalBarToCheck) do
            local currentlyCheckedItemSetName
            local incrementBy = 1
            _, currentlyCheckedItemSetName = GetItemLinkSetInfo(GetItemLink(BAG_WORN, v), true)
            if GetItemEquipType(BAG_WORN, additonalBarToCheck[1]) == EQUIP_TYPE_TWO_HAND then
                incrementBy = 2
            end --If item is a two-handed weapon count it twice
            if currentlyCheckedItemSetName == setName then
                numOfItems = numOfItems + incrementBy
            end
        end
        if numOfItems >= maxEquipped then
            return true
        end
    end
    return false
end

function HT_checkIfZone(zonesTable)
    if next(zonesTable) == nil then
        return true
    end
    for _, zone in pairs(zonesTable) do
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
    for _, boss in pairs(bossesTable) do
        if GetUnitName("boss1") == boss then
            return true
        end
    end
    return false
end

function HT_pickAnyKey(array)
    for k, _ in pairs(array) do
        return k
    end
    return "none"
end

function HT_pickAnyElement(array, noneOverride)
    for _, v in pairs(array) do
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
    else
        -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function HT_generateNewName(name, number)
    local newName = name .. "(" .. number .. ")"
    if HT_getTrackerFromName(newName, HTSV.trackers) then
        return HT_generateNewName(name, number + 1)
    end
    return newName
end

function HT_getIdsFromAllEvents(tracker)
    local holder = {}
    for _, event in pairs(tracker.events) do
        for _, id in pairs(event.arguments.Ids) do
            if not HT_checkIfElementIsInsideTable(holder, id) then
                holder[#holder + 1] = id
            end
        end
    end
    return holder
end

function HT_checkIfElementIsInsideTable(table, element)
    for _, v in pairs(table) do
        if element == v then
            return true
        end
    end
    return false
end

function HT_nullify(t)

    t.stacks = {}
    t.expiresAt = {}
    t.duration = {}
    t.max = 0
    t.current = 0

    for i = 1, GetNumBuffs("player") do
        local _, startedAt, expireTime, _, stackCount, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo("player", i)
        if HT_checkIfElementIsInsideTable(HT_getIdsFromAllEvents(t), abilityId) then
            t.expiresAt[GetUnitName('player')] = expireTime
            t.duration[GetUnitName('player')] = expireTime - startedAt
            t.stacks[GetUnitName('player')] = stackCount
        end
    end

    for _, v in pairs(t.children) do
        HT_nullify(v)
    end
end

function HT_GetDistance(unit1, unit2)
    if not DoesUnitExist(unit1) or not DoesUnitExist(unit2) then
        return -1
    end
    local zone1, x1, _, z1 = GetUnitWorldPosition(unit1)
    local zone2, x2, _, z2 = GetUnitWorldPosition(unit2)
    if zone1 ~= zone2 then
        return -1
    else
        return (zo_sqrt((x1 - x2) ^ 2 + (z1 - z2) ^ 2) / 100)
    end
end