HT = {
    name            = "HyperTools",          
    author          = "Hyperioxes",
    color           = "DDFFEE",            
    menuName        = "HyperTools",      
    
}



function OnAddOnLoaded(event, addonName)
    if addonName ~= HT.name then return end
    EVENT_MANAGER:UnregisterForEvent(HT.name, EVENT_ADD_ON_LOADED)
    
    HTSV = ZO_SavedVars:NewAccountWide("HyperToolsSV",5, nil, HT_trackers)
    for _,t in pairs(HTSV.trackers) do
        HT_nullify(t)
    end
    HT_Settings_initializeUI()
    HT_Initialize3D()
    HT_InitializeGlobalControl()
    HT_registerEvents()
	
end

EVENT_MANAGER:RegisterForEvent(HT.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)