HT = {
    name = "HyperTools",
    author = "Hyperioxes",
    color = "DDFFEE",
    menuName = "HyperTools",
    expiresAt = {},
    duration = {},
    stacks = {},
}

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

        for k, v in pairs(t.children) do
            searchThroughTable(v)
        end
    end

    for _, t in pairs(data) do
        searchThroughTable(t)
    end


end

function OnAddOnLoaded(event, addonName)
    if addonName ~= HT.name then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(HT.name, EVENT_ADD_ON_LOADED)

    HTSV = ZO_SavedVars:NewAccountWide("HyperToolsSV", 32, nil, HT_trackers)

    HT_adjustDataForNewestVersion(HTSV.trackers) --Adjust data for newest version, fill gaps in null data with default values

    for _, t in pairs(HTSV.trackers) do
        HT_nullify(t)
    end

    HT_Settings_initializeUI()
    HT_Initialize3D()
    HT_InitializeGlobalControl()
    --HT_registerEvents()

end

EVENT_MANAGER:RegisterForEvent(HT.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)