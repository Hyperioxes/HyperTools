HT_eventFunctions = {
	["Get Effect Duration"] = function(name,ID,tracker,arguments)
		EVENT_MANAGER:RegisterForEvent(name,EVENT_EFFECT_CHANGED,function(_,_,_,_,_,_,expireTime,stackCount,_,_,_,_,_,targetName) 
			targetName = HT_removeGender(targetName)
			if not arguments.dontUpdateFromThisEvent then
				targetName = HT_removeGender(targetName)
				if expireTime > (tracker.expiresAt[targetName] or 0) or (not arguments.overwriteShorterDuration) then
					tracker.expiresAt[targetName] = expireTime
					tracker.duration[targetName] = expireTime-GetGameTimeSeconds()
					tracker.stacks[targetName] = stackCount
				end
			end
			if arguments.luaCodeToExecute then
				zo_loadstring(arguments.luaCodeToExecute)()
			end
		end) 
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID,ID)
		if arguments.onlyYourCast then
			EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE,1)
		end
	end,
	["Get Effect Cooldown"] = function(name,ID,tracker,arguments)
		EVENT_MANAGER:RegisterForEvent(name,EVENT_COMBAT_EVENT,function(eventCode, result, isError, abilityName, abilityGraphic, 
	abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)  
			if not arguments.dontUpdateFromThisEvent then
				tracker.duration[GetUnitName("player")] = arguments.cooldown
				tracker.expiresAt[GetUnitName("player")] = arguments.cooldown + GetGameTimeSeconds()
			end

			if arguments.luaCodeToExecute then
				zo_loadstring(arguments.luaCodeToExecute)()
			end

		end) 
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID,ID)
		if arguments.onlyYourCast then
			EVENT_MANAGER:AddFilterForEvent(name, EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE,1)
		end
	end,
	--[[["Get Resource Value"] = function(name,ID,tracker)
		EVENT_MANAGER:RegisterForEvent(name, EVENT_POWER_UPDATE, function(_,player,type,_,current,max,idk)
			tracker.current = current
			tracker.max = max
		end)
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG ,"player")
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE,ID)
	end,]]


}

HT_unregisterEventFunctions = {
	["Get Effect Duration"] = function(name)
		EVENT_MANAGER:UnregisterForEvent(name,EVENT_EFFECT_CHANGED)
	end,
	--[[["Get Resource Value"] = function(name)
		EVENT_MANAGER:UnregisterForEvent(name,EVENT_POWER_UPDATE)
	end,]]
	["Get Effect Cooldown"] = function(name)
		EVENT_MANAGER:UnregisterForEvent(name,EVENT_COMBAT_EVENT)
	end,
}

