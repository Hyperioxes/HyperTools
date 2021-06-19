HT_targets = {
    ["Yourself"] = function()
        return GetUnitName("player")
    end,
    ["Boss"] = function(i)
        return GetUnitName("boss" .. i)
    end,
    ["Current Target"] = function()
        return GetUnitName("reticleover")
    end,
    ["Group"] = function(i)
        return GetUnitName("group" .. i)
    end,
}

operators = {
    ["<="] = function(arg1, arg2)
        if arg1 <= arg2 then
            return true
        end
        return false
    end,
    ["=="] = function(arg1, arg2)
        if arg1 == arg2 then
            return true
        end
        return false
    end,
    [">="] = function(arg1, arg2)
        if arg1 >= arg2 then
            return true
        end
        return false
    end,
    ["<"] = function(arg1, arg2)
        if arg1 < arg2 then
            return true
        end
        return false
    end,
    [">"] = function(arg1, arg2)
        if arg1 > arg2 then
            return true
        end
        return false
    end,
    ["~="] = function(arg1, arg2)
        if arg1 ~= arg2 then
            return true
        end
        return false
    end
}

conditionResults = {
    ["Set Bar Color"] = function(tracker, color)
        tracker.barColor = color
    end,
    ["Set Text Color"] = function(tracker, color)
        tracker.textColor = color
    end,
    ["Set Timer Color"] = function(tracker, color)
        tracker.timeColor = color
    end,
    ["Set Stacks Color"] = function(tracker, color)
        tracker.stacksColor = color
    end,
    ["Set Background Color"] = function(tracker, color)
        tracker.backgroundColor = color
    end,
    ["Set Border Color"] = function(tracker, color)
        tracker.outlineColor = color
    end,
    ["Hide Tracker"] = function(tracker)
        tracker.show = false
    end,
    ["Show Proc"] = function(tracker)
        tracker.showProc = true
    end,
}

conditionArgs1 = {
    ["Remaining Time"] = function(tracker, override)
        if (tracker.expiresAt[HT_targets[tracker.target](override.targetNumber or tracker.targetNumber)] or 0) - GetGameTimeSeconds() > 0 then
            return tracker.expiresAt[HT_targets[tracker.target](override.targetNumber or tracker.targetNumber)] - GetGameTimeSeconds()
        end
        return 0
    end,
    ["Stacks"] = function(tracker)
        if (tracker.stacks[HT_targets[tracker.target](tracker.targetNumber)] or 0) > 0 and (tracker.expiresAt[HT_targets[tracker.target](tracker.targetNumber)] or 0) - GetGameTimeSeconds() > 0 then
            return tracker.stacks[HT_targets[tracker.target](tracker.targetNumber)]
        end
        return 0
    end,
    ["Group Role"] = function(tracker, override)
        return GetGroupMemberSelectedRole("group" .. override.targetNumber)
    end,
    ["Distance to target"] = function(tracker, override)
        return HT_GetDistance("player", "group" .. override.targetNumber)
    end,

}