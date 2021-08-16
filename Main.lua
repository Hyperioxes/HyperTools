HT = {
    name = "HyperTools",
    author = "Hyperioxes, Shadowwolf136",
    color = "DDFFEE",
    menuName = "HyperTools",
    version = "0.12",
    expiresAt = {},
    duration = {},
    stacks = {},
    loadCheckOnCooldown = false,
    groupDistance = {},
}

_G["HyperTools"] = {}

function HT_adjustDataForNewestVersion(data)
    local function searchThroughTable(t)
        for _, event in pairs(t.events) do
            if not event.arguments then
                event.arguments = {
                    cooldown = event.argument1 or 0,
                    onlyYourCast = false,
                    overwriteShorterDuration = false,
                }
            end
            if not event.arguments.luaCodeToExecute then
                event.arguments.luaCodeToExecute = ""
            end
            if not event.arguments.dontUpdateFromThisEvent then
                event.arguments.dontUpdateFromThisEvent = false
            end
            if not event.arguments.Ids then
                event.arguments.Ids = t.IDs or {}
            end
        end

        if not t.drawLevel then
            t.drawLevel = 0
        end

        if not t.load.bosses then
            t.load.bosses = {}
        end

        if not t.cooldownColor then
            t.cooldownColor = { 0, 0, 0, 0.7 }
        end

        if not t.load.always then
            t.load.always = false
        end

        if not t.vertical then
            t.vertical = false
        end

        for _, v in pairs(t.children) do
            searchThroughTable(v)
        end
    end

    for _, t in pairs(data) do
        searchThroughTable(t)
    end


end
function OnAddOnLoaded(_, addonName)
    if addonName ~= HT.name then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(HT.name, EVENT_ADD_ON_LOADED)

    HTSV = ZO_SavedVars:NewAccountWide("HyperToolsSV", 32, nil, HT_trackers)

    HT_adjustDataForNewestVersion(HTSV.trackers) --Adjust data for newest version, fill gaps in null data with default values

    for _, t in pairs(HTSV.trackers) do --Nullify all expire dates and durations
        HT_nullify(t)
    end

    HT_Settings_initializeUI()
    HT_InitializeEventViewerSettings()
    HT_InitializeEffectViewerSettings()
    HT_Initialize3D()
    HT_InitializeGlobalControl()

    --To improve performance, the "check" if tracker should be turned on happens on certain events (skill changed,
    --equipment changed, zone changed, boss changed) instead of every 100ms
    EVENT_MANAGER:RegisterForEvent(name, EVENT_SKILL_RESPEC_RESULT, function() --Check when skill changed
        if not HT.loadCheckOnCooldown then
            HT.loadCheckOnCooldown = true
            zo_callLater(function()
                for _, v in pairs(HTSV.trackers) do
                    if v.name ~= 'none' then
                        HT_findContainer(v):Update(v)
                    end
                end
                HT.loadCheckOnCooldown = false end, 100)
        end
    end)
    EVENT_MANAGER:RegisterForEvent(name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(eventCode,badId,slotIndex,isNewItem,itemSoundCategory,inventoryUpdateReason,stackCountChange) --Check when skill changed
        if not HT.loadCheckOnCooldown then
            HT.loadCheckOnCooldown = true
            zo_callLater(function()
                for _, v in pairs(HTSV.trackers) do
                    if v.name ~= 'none' then
                        HT_findContainer(v):Update(v)
                    end
                end
                HT.loadCheckOnCooldown = false end, 100)
        end
    end)
    EVENT_MANAGER:AddFilterForEvent(name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT) --Update only on equipment change, not on durability change, glyph usage, poison usage etc

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function() -- Check when map changed
        if not HT.loadCheckOnCooldown then
            HT.loadCheckOnCooldown = true
            zo_callLater(function()
                for _, v in pairs(HTSV.trackers) do
                    if v.name ~= 'none' then
                        HT_findContainer(v):Update(v)
                    end
                end
                HT.loadCheckOnCooldown = false end, 100)
        end
    end)
    EVENT_MANAGER:RegisterForEvent(name, EVENT_BOSSES_CHANGED, function() --Check when boss changed
        if not HT.loadCheckOnCooldown then
            HT.loadCheckOnCooldown = true
            zo_callLater(function()
                for _, v in pairs(HTSV.trackers) do
                    if v.name ~= 'none' then
                        HT_findContainer(v):Update(v)
                    end
                end
                HT.loadCheckOnCooldown = false end, 100)
        end
    end)

    ZO_ActiveSkillProgressionData["SetKeyboardTooltip"] = function(self,tooltip, showSkillPointCost, showUpgradeText, showAdvised, showBadMorph, overrideRank, overrideAbilityId)
        local skillType, skillLineIndex, skillIndex = self:GetIndices()
        local isPurchased = self:GetSkillData():GetPointAllocator():IsPurchased()
        local numAvailableSkillPoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
        tooltip:SetActiveSkill(skillType, skillLineIndex, skillIndex, self:GetMorphSlot(), isPurchased, self:IsAdvised(), self:IsBadMorph(), numAvailableSkillPoints, showSkillPointCost, showUpgradeText, showAdvised, showBadMorph, overrideRank, overrideAbilityId)
        local abilityId = GetSpecificSkillAbilityInfo(skillType, skillLineIndex, skillIndex, self:GetMorphSlot(), 4)
        SetTooltipText(tooltip, "Ability Id: "..abilityId,1,1,1) --FIXME shows only rank 4
    end


    EVENT_MANAGER:RegisterForEvent(name, EVENT_ACTION_SLOT_ABILITY_USED, function() --Check when boss changed
        --zo_callLater(CancelCast,300)
        --CancelCast()
    end)


end

EVENT_MANAGER:RegisterForEvent(HT.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)