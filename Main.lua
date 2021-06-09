HT = {
    name            = "HyperTools",          
    author          = "Hyperioxes",
    color           = "DDFFEE",            
    menuName        = "HyperTools",      
    expiresAt       = {},
    duration        = {},
    stacks        = {},
}



function OnAddOnLoaded(event, addonName)
    if addonName ~= HT.name then return end
    EVENT_MANAGER:UnregisterForEvent(HT.name, EVENT_ADD_ON_LOADED)
    
    HTSV = ZO_SavedVars:NewAccountWide("HyperToolsSV",32, nil, HT_trackers)

    -- ADJUSTMENTS FOR OLD SAVED VARIABLES

    local function searchThroughTable(t)
        for _,event in pairs(t.events) do
            if not event.arguments then
            event.arguments = {
                cooldown = event.argument1 or 0,
			    onlyYourCast = false,
			    overwriteShorterDuration = false,
            }
        end
        end

        if not t.drawLevel then
            t.drawLevel = 0
        end

        if not t.load.bosses then
            t.load.bosses = {}
        end

	    for k,v in pairs(t.children) do
		    searchThroughTable(v)
	    end
    end

    for _,t in pairs(HTSV.trackers) do
        searchThroughTable(t)
    end



    -- ADJUSTMENTS FOR OLD SAVED VARIABLES




    for _,t in pairs(HTSV.trackers) do
        HT_nullify(t)
    end

    


    HT_Settings_initializeUI()
    HT_Initialize3D()
    HT_InitializeGlobalControl()
    --HT_registerEvents()
	
end

EVENT_MANAGER:RegisterForEvent(HT.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)