function HT_processLoad(trackerLoad)
    if trackerLoad.always then
        return true
    end
    if trackerLoad.never then
        return false
    end
    if trackerLoad.inCombat and not IsUnitInCombat("player") then
        return false
    end
    if trackerLoad.role ~= GetGroupMemberSelectedRole("player") and trackerLoad.role ~= 0 and GetGroupMemberSelectedRole("player") ~= 0 then
        return false
    end
    if trackerLoad.class ~= GetUnitClass("player") and trackerLoad.class ~= "Any" then
        return false
    end
    if not HT_checkIfSkillSlotted(trackerLoad.skills) then
        return false
    end
    if not HT_checkIfItemSetsEquipped(trackerLoad.itemSets) then
        return false
    end
    if not HT_checkIfZone(trackerLoad.zones) then
        return false
    end
    if not HT_checkIfBoss(trackerLoad.bosses) then
        return false
    end
    return true
end

function processTracker(parentControl, originalValues)
    local container = parentControl:GetNamedChild(originalValues.name)
    if not container then
        initializeTrackerFunctions[originalValues.type](parentControl, originalValues)
    end
    if processLoad(originalValues.load) then
        local tracker = {
            text = originalValues.text,
            color = originalValues.barColor,
            show = true,
            targetNumber = originalValues.targetNumber
        }
        for _, condition in pairs(originalValues.conditions) do
            if operators[condition.operator](conditionArgs1[condition.arg1](originalValues), condition.arg2) then
                conditionResults[condition.result](tracker, condition.resultArguments)
            end
        end
        if tracker.show then
            container:SetHidden(false)
            trackerUpdateFunctions[originalValues.type](container, tracker, originalValues)
        else
            container:SetHidden(true)
        end
    else
        container:SetHidden(true)
    end
end

trackerUpdateFunctions = {
    ["Icon Tracker"] = function(container, tracker, v)
        container:SetHidden(false)
        local icon = container:GetNamedChild("icon")
        local timer = icon:GetNamedChild("timer")
        local stacks = icon:GetNamedChild("stacks")
        local remainingTime = math.max((v.expiresAt[HT_targets[v.target]()] or 0) - GetGameTimeSeconds(), 0)
        local stacksCount = v.stacks[HT_targets[v.target]()] or 0
        if remainingTime == 0 then
            stacksCount = 0
        end
        timer:SetColor(unpack(tracker.color))
        timer:SetText(HT_getDecimals(remainingTime, v.decimals))
        stacks:SetColor(unpack(tracker.color))
        stacks:SetText(stacksCount)
    end,
    ["Progress Bar"] = function(container, tracker, v)
        container:SetHidden(false)
        local icon = container:GetNamedChild("icon")
        local bar = icon:GetNamedChild("bar")
        local label = container:GetNamedChild("label")
        local timer = container:GetNamedChild("timer")
        local stacks = icon:GetNamedChild("stacks")
        local barX = v.sizeX - v.sizeY
        local barY = v.sizeY
        local remainingTime = math.max((v.expiresAt[HT_targets[v.target](v.targetNumber)] or 0) - GetGameTimeSeconds(), 0)
        local duration = math.max((v.duration[HT_targets[v.target](v.targetNumber)] or 0), 0)
        local stacksCount = v.stacks[HT_targets[v.target](v.targetNumber)] or 0
        if remainingTime == 0 then
            bar:SetDimensions(0, barY)
            stacksCount = 0
        else
            bar:SetDimensions(barX * (remainingTime / duration), barY)
        end
        bar:SetColor(unpack(tracker.color))
        timer:SetText(HT_getDecimals(remainingTime, v.decimals))
        label:SetText(tracker.text)
        stacks:SetText(stacksCount)
    end,
    ["Group"] = function(container, tracker, v)
        container:SetHidden(false)
        for _, childName in pairs(v.children) do
            processTracker(container, HTSV.trackers[childName])

        end
    end,
    ["Resource Bar"] = function(container, tracker, v)
        container:SetHidden(false)
        local bar = container:GetNamedChild("bar")
        local label = bar:GetNamedChild("label")
        bar:SetDimensions(v.sizeX * (v.current / v.max), v.sizeY)
        bar:SetColor(unpack(tracker.color))
        label:SetText(resourceTexts[v.text](v))
    end,
}

function HT_updateEvery100()
    for k, v in pairs(HTSV.trackers) do
        if v.parent == "HT_Trackers" then
            processTracker(HT_Trackers, v)
        end
    end
end

function HT_InitializeGlobalControl()
    local WM = GetWindowManager()
    local HT_Trackers = WM:CreateTopLevelWindow("HT_Trackers")
    HT_Trackers:SetResizeToFitDescendents(false)
    HT_Trackers:SetMovable(false)
    HT_Trackers:SetMouseEnabled(false)
    HT_Trackers:SetHidden(false)

    for k, v in pairs(HTSV.trackers) do
        if v.parent == "HT_Trackers" then
            initializeTrackerFunctions[v.type](HT_Trackers, v)
        end
    end

    for k, v in pairs(HTSV.trackers) do
        HT_changeLock(v, false)
    end

    HT_Trackers:ClearAnchors()
    HT_Trackers:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)

end


