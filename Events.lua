HT_eventFunctions = {
	["Update Effect Duration from Event"] = function(name,ID,tracker)
		EVENT_MANAGER:RegisterForEvent(name,EVENT_EFFECT_CHANGED,function(_,_,_,_,_,_,expireTime,stackCount,_,_,_,_,_,targetName) 
			targetName = HT_removeGender(targetName)
			if expireTime > (tracker.expiresAt[targetName] or 0) then
				tracker.expiresAt[targetName] = expireTime
				tracker.duration[targetName] = expireTime-GetGameTimeSeconds()
				tracker.stacks[targetName] = stackCount
			end
		end) 
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID,ID)
		--EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE,unitType)
	end,
	["Effect only yours"] = function(name,ID,tracker)
		EVENT_MANAGER:RegisterForEvent(name,EVENT_EFFECT_CHANGED,function(_,_,_,_,_,_,expireTime,stackCount,_,_,_,_,_,targetName) 
			targetName = HT_removeGender(targetName)
			if expireTime > (tracker.expiresAt[targetName] or 0) then
				tracker.expiresAt[targetName] = expireTime
				tracker.duration[targetName] = expireTime-GetGameTimeSeconds()
				tracker.stacks[targetName] = stackCount
			end
		end) 
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID,ID)
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE,1)
	end,
	["Update Resource"] = function(name,ID,tracker)
		EVENT_MANAGER:RegisterForEvent(name, EVENT_POWER_UPDATE, function(_,player,type,_,current,max,idk)
			tracker.current = current
			tracker.max = max
		end)
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG ,"player")
		EVENT_MANAGER:AddFilterForEvent(name, EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE,ID)
	end,


}

HT_unregisterEventFunctions = {
	["Update Effect Duration from Event"] = function(name)
		EVENT_MANAGER:UnregisterForEvent(name,EVENT_EFFECT_CHANGED)
	end,
	["Effect only yours"] = function(name)
		EVENT_MANAGER:UnregisterForEvent(name,EVENT_EFFECT_CHANGED)
	end,
	["Update Resource"] = function(name)
		EVENT_MANAGER:UnregisterForEvent(name,EVENT_POWER_UPDATE)
	end
}

function HT_registerEvents()
	for _,v in pairs(HTSV.trackers) do
		for key,event in pairs(v.events) do
			for _,ID in pairs(v.IDs) do
				HT_eventFunctions[event.type]("HT"..key..v.name..ID,ID,v)
			end
		end
	end
end

function HT_unregisterEvents()
	for _,v in pairs(HTSV.trackers) do
		for key,event in pairs(v.events) do
			for _,ID in pairs(v.IDs) do
				HT_unregisterEventFunctions[event.type]("HT"..key..v.name..ID)
			end
		end
	end
end