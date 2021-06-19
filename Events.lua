hyperToolsTracker = {}
hyperToolsGlobal = {}

function HT_setDuration(duration)
    hyperToolsTracker.expiresAt[hyperToolsGlobal.targetName] = GetGameTimeSeconds() + duration
end

function HT_setMaxDuration(duration)
    hyperToolsTracker.duration[hyperToolsGlobal.targetName] = duration
end

local eventFunctions = {
    ["Get Effect Duration"] = function(name, ID, tracker, arguments)
        EVENT_MANAGER:RegisterForEvent(name, EVENT_EFFECT_CHANGED, function(_, result, _, _, _, _, expireTime, stackCount, _, _, _, _, _, targetName)
            targetName = HT_removeGender(targetName)
            if not arguments.dontUpdateFromThisEvent then
                if expireTime > (tracker.expiresAt[targetName] or 0) or (not arguments.overwriteShorterDuration) then
                    tracker.expiresAt[targetName] = expireTime
                    tracker.duration[targetName] = expireTime - GetGameTimeSeconds()
                    tracker.stacks[targetName] = stackCount
                end
            end

            if arguments.luaCodeToExecute then
                hyperToolsTracker = tracker
                hyperToolsGlobal.result = result
                hyperToolsGlobal.expireTime = expireTime
                hyperToolsGlobal.stackCount = stackCount
                hyperToolsGlobal.targetName = targetName
                zo_loadstring(arguments.luaCodeToExecute)()
                hyperToolsGlobal = {}
                tracker = hyperToolsTracker
            end
        end)
        EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, ID)
        if arguments.onlyYourCast then
            EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, 1)
        end
    end,
    ["Get Effect Cooldown"] = function(name, ID, tracker, arguments)
        EVENT_MANAGER:RegisterForEvent(name, EVENT_COMBAT_EVENT, function(eventCode, result, isError, abilityName, abilityGraphic,
                                                                          abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
            if not arguments.dontUpdateFromThisEvent then
                tracker.duration[GetUnitName("player")] = arguments.cooldown
                tracker.expiresAt[GetUnitName("player")] = arguments.cooldown + GetGameTimeSeconds()
            end

            if arguments.luaCodeToExecute then
                hyperToolsTracker = tracker
                hyperToolsGlobal.result = result
                hyperToolsGlobal.hitValue = hitValue
                hyperToolsGlobal.targetName = HT_removeGender(sourceName)
                zo_loadstring(arguments.luaCodeToExecute)()
                hyperToolsGlobal = {}
                tracker = hyperToolsTracker
            end

        end)
        EVENT_MANAGER:AddFilterForEvent(name, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, ID)
        if arguments.onlyYourCast then
            EVENT_MANAGER:AddFilterForEvent(name, EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, 1)
        end
    end,
    ["Entering/Exiting Combat"] = function(name, ID, tracker, arguments)
        EVENT_MANAGER:RegisterForEvent(name, EVENT_PLAYER_COMBAT_STATE, function(_, inCombat)
            if arguments.luaCodeToExecute then
                hyperToolsTracker = tracker
                hyperToolsGlobal.inCombat = inCombat
                hyperToolsGlobal.targetName = GetUnitName("player")
                zo_loadstring(arguments.luaCodeToExecute)()
                hyperToolsGlobal = {}
                tracker = hyperToolsTracker
            end
        end)
    end,
}

local unregisterEventFunctions = {
    ["Get Effect Duration"] = function(name)
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_EFFECT_CHANGED)
    end,
    ["Get Effect Cooldown"] = function(name)
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_COMBAT_EVENT)
    end,
    ["Entering/Exiting Combat"] = function(name)
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_PLAYER_COMBAT_STATE)
    end,
}

HT_unregisterEventFunctions = {
    ["Get Effect Duration"] = function(key, localEvent, tracker)
        for _, ID in pairs(localEvent.arguments.Ids) do
            unregisterEventFunctions[localEvent.type]("HT" .. key .. tracker.name .. ID)
        end
    end,
    ["Get Effect Cooldown"] = function(key, localEvent, tracker)
        for _, ID in pairs(localEvent.arguments.Ids) do
            unregisterEventFunctions[localEvent.type]("HT" .. key .. tracker.name .. ID)
        end
    end,
    ["Entering/Exiting Combat"] = function(key, localEvent, tracker)
        unregisterEventFunctions[localEvent.type]("HT" .. key .. tracker.name)
    end,
}

HT_eventFunctions = {
    ["Get Effect Duration"] = function(key, localEvent, tracker)
        for _, ID in pairs(localEvent.arguments.Ids) do
            eventFunctions[localEvent.type]("HT" .. key .. tracker.name .. ID, ID, tracker, localEvent.arguments)
        end
    end,
    ["Get Effect Cooldown"] = function(key, localEvent, tracker)
        for _, ID in pairs(localEvent.arguments.Ids) do
            eventFunctions[localEvent.type]("HT" .. key .. tracker.name .. ID, ID, tracker, localEvent.arguments)
        end
    end,
    ["Entering/Exiting Combat"] = function(key, localEvent, tracker)
        eventFunctions[localEvent.type]("HT" .. key .. tracker.name, nil, tracker, localEvent.arguments)
    end,
}


