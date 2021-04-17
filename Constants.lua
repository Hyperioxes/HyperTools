HT_targets = {
	["Yourself"] = function()
		return GetUnitName("player")
	end,
	["Boss"] = function(i)
		return GetUnitName("boss"..i)
	end,
	["Current Target"] = function()
		return GetUnitName("reticleover")
	end,
	["Group"] = function(i)
		return GetUnitName("group"..i)
	end,
}

operators = {
	["<="] = function(arg1,arg2)
		if arg1 <= arg2 then
			return true
		end
		return false
	end,
	["=="] = function(arg1,arg2)
		if arg1 == arg2 then
			return true
		end
		return false
	end,
	[">="] = function(arg1,arg2)
		if arg1 >= arg2 then
			return true
		end
		return false
	end,
	["<"] = function(arg1,arg2)
		if arg1 < arg2 then
			return true
		end
		return false
	end,
	[">"] = function(arg1,arg2)
		if arg1 > arg2 then
			return true
		end
		return false
	end,
	["~="] = function(arg1,arg2)
		if arg1 ~= arg2 then
			return true
		end
		return false
	end
}

conditionResults = {
	["Set Color"] = function(tracker,color)
		tracker.color = color
	end,
	["Hide Tracker"] = function(tracker)
		tracker.show = false
	end
}

conditionArgs1 = {
	["Remaining Time"] = function(tracker)
		if (tracker.expiresAt[HT_targets[tracker.target](tracker.targetNumber)] or 0) - GetGameTimeSeconds() > 0 then
			return tracker.expiresAt[HT_targets[tracker.target](tracker.targetNumber)] - GetGameTimeSeconds()
		end
		return 0
	end,
	["Stacks"] = function(tracker)
		if (tracker.stacks[HT_targets[tracker.target](tracker.targetNumber)] or 0) > 0 and (tracker.expiresAt[HT_targets[tracker.target](tracker.targetNumber)] or 0) - GetGameTimeSeconds() > 0 then
			return tracker.stacks[HT_targets[tracker.target](tracker.targetNumber)]
		end
		return 0
	end,
}