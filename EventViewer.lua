local WM = GetWindowManager()
local running = false

HT_eventSettingsVisible = false

local function hideUI()
    HT_EventSettings:SetHidden(true)
    HT_eventSettingsVisible = false
end

local function showUI()
    HT_EventSettings:SetHidden(false)
    HT_eventSettingsVisible = true
end


function HT_toggleEventUI()
    if HT_eventSettingsVisible then
        hideUI()
    else
        showUI()
    end
end

SLASH_COMMANDS["/htevent"] = HT_toggleEventUI

local defaultFilterOptions = {
    sourceName = nil,
    targetName = nil,
    abilityId = nil,
    abilityName = nil,
    result = nil,
    hitValue = nil,
    powerType = nil,
    damageType = nil,
    sourceNameVisible = true,
    targetNameVisible = true,
    abilityIdVisible = true,
    abilityNameVisible = true,
    resultVisible = true,
    hitValueVisible = true,
    powerTypeVisible = false,
    damageTypeVisible = false,
}

function HT_InitializeEventViewerSettings()
    local HT_EventSettings = WM:CreateTopLevelWindow("HT_EventSettings")
    HT_EventSettings:SetResizeToFitDescendents(true)
    HT_EventSettings:SetMovable(true)
    HT_EventSettings:SetMouseEnabled(true)
    HT_EventSettings:SetHidden(true)
    HT_EventSettings:SetDrawLevel(DT_HIGH)

    local background = createBackground(HT_EventSettings,"background",600,425,0,0,TOPLEFT,TOPLEFT)
    createLabel(background,'versionLabel',100,30,0,0,BOTTOMLEFT,BOTTOMLEFT,'Hyper Tools '..HT.version)
    createButton(background,"exitButton",25,25,0,0,TOPRIGHT,TOPRIGHT,function() hideUI() end,nil,"/esoui/art/buttons/decline_up.dds",true)



    local mainLabel = createLabel(background,"mainLabel",250,30,20,20,TOPLEFT,TOPLEFT,"EVENT VIEWER",0,0,"BOLD_FONT",26)

    local sourceNameEditbox = createEditbox(background,"sourceNameEditbox",200,30,20,90,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.sourceName = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end, HTSV.filterOptions.sourceName,nil,"Source Name:")

    local sourceNameCheckbox = createCheckbox(sourceNameEditbox,"sourceNameCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.sourceNameVisible,function(arg)
        HTSV.filterOptions.sourceNameVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local targetNameEditbox = createEditbox(background,"targetNameEditbox",200,30,20,150,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.targetName = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end,HTSV.filterOptions.targetName,nil,"Target Name:")

    local targetNameCheckbox = createCheckbox(targetNameEditbox,"targetNameCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.targetNameVisible,function(arg)
        HTSV.filterOptions.targetNameVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local abilityIdEditbox = createEditbox(background,"abilityIdEditbox",200,30,20,210,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.abilityId = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end,HTSV.filterOptions.abilityId,nil,"Ability Id:")

    local abilityIdCheckbox = createCheckbox(abilityIdEditbox,"abilityIdCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.abilityIdVisible,function(arg)
        HTSV.filterOptions.abilityIdVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local abilityNameEditbox = createEditbox(background,"abilityNameEditbox",200,30,20,270,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.abilityName = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end,HTSV.filterOptions.abilityName,nil,"Ability Name:")

    local abilityNameCheckbox = createCheckbox(abilityNameEditbox,"abilityNameCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.abilityNameVisible,function(arg)
        HTSV.filterOptions.abilityNameVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local resultEditbox = createEditbox(background,"resultEditbox",200,30,300,90,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.result = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end,HTSV.filterOptions.result,nil,"Result:")

    local resultCheckbox = createCheckbox(resultEditbox,"resultCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.resultVisible,function(arg)
        HTSV.filterOptions.resultVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local hitValueEditbox = createEditbox(background,"hitValueEditbox",200,30,300,150,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.hitValue = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end,HTSV.filterOptions.hitValue,nil,"Hit Value:")

    local hitValueCheckbox = createCheckbox(hitValueEditbox,"hitValueCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.hitValueVisible,function(arg)
        HTSV.filterOptions.hitValueVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local powerTypeEditbox = createEditbox(background,"powerTypeEditbox",200,30,300,210,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.powerType = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end,HTSV.filterOptions.powerType,nil,"Power Type:")

    local powerTypeCheckbox = createCheckbox(powerTypeEditbox,"powerTypeCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.powerTypeVisible,function(arg)
        HTSV.filterOptions.hitValueVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local damageTypeEditbox = createEditbox(background,"damageTypeEditbox",200,30,300,270,TOPLEFT,TOPLEFT,function(thisEditbox)
        HTSV.filterOptions.damageType = thisEditbox:GetText()
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end,HTSV.filterOptions.damageType,nil,"Damage Type:")

    local damageTypeCheckbox = createCheckbox(damageTypeEditbox,"damageTypeCheckbox", 30,30,15,0,LEFT,RIGHT,HTSV.filterOptions.damageTypeVisible,function(arg)
        HTSV.filterOptions.damageTypeVisible = arg
        if running then HT_registerEventViewer(HTSV.filterOptions) end
    end)

    local updateEventViewerButton = createButton(background,"updateEventViewerButton",200,25,0,-35,BOTTOM,BOTTOM,function(_,_,_,thisButton)
        if running then
            HT_unregisterEventViewer()
            running = false
            thisButton:SetText("Start")
        else
            HT_registerEventViewer(HTSV.filterOptions)
            running = true
            thisButton:SetText("Stop")
        end
    end,"Start",nil,true)

    createButton(background,"defaultButton",25,25,-25,0,TOPRIGHT,TOPRIGHT,function()
        HTSV.filterOptions = HT_deepcopy(defaultFilterOptions)
        if running then HT_registerEventViewer(HTSV.filterOptions) end
        sourceNameEditbox:SetText(HTSV.filterOptions.sourceName)
        sourceNameCheckbox:Update(HTSV.filterOptions.sourceNameVisible)
        targetNameEditbox:SetText(HTSV.filterOptions.targetName)
        targetNameCheckbox:Update(HTSV.filterOptions.targetNameVisible)
        abilityIdEditbox:SetText(HTSV.filterOptions.abilityId)
        abilityIdCheckbox:Update(HTSV.filterOptions.abilityIdVisible)
        abilityNameEditbox:SetText(HTSV.filterOptions.abilityName)
        abilityNameCheckbox:Update(HTSV.filterOptions.abilityNameVisible)
        resultEditbox:SetText(HTSV.filterOptions.result)
        resultCheckbox:Update(HTSV.filterOptions.resultVisible)
        hitValueEditbox:SetText(HTSV.filterOptions.hitValue)
        hitValueCheckbox:Update(HTSV.filterOptions.hitValueVisible)
        powerTypeEditbox:SetText(HTSV.filterOptions.powerType)
        powerTypeCheckbox:Update(HTSV.filterOptions.powerTypeVisible)
        damageTypeEditbox:SetText(HTSV.filterOptions.damageType)
        damageTypeCheckbox:Update(HTSV.filterOptions.damageTypeVisible)
    end,nil,"/esoui/art/buttons/switch_up.dds",true)


    HT_EventSettings:ClearAnchors()
    HT_EventSettings:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,0,0)
end

function HT_registerEventViewer(filter)
    EVENT_MANAGER:UnregisterForEvent("HT_eventViewer",EVENT_COMBAT_EVENT)
    EVENT_MANAGER:RegisterForEvent("HT_eventViewer", EVENT_COMBAT_EVENT, function(
            eventCode, result, isError, abilityName, abilityGraphic,
            abilityActionSlotType, sourceName, sourceType, targetName,
            targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
        local textToDisplay = ""
        if HTSV.filterOptions.sourceNameVisible then textToDisplay = textToDisplay.."SourceName:"..sourceName.."   " end
        if HTSV.filterOptions.targetNameVisible then textToDisplay = textToDisplay.."TargetName:"..targetName.."   " end
        if HTSV.filterOptions.abilityIdVisible then textToDisplay = textToDisplay.."AbilityId:"..abilityId.."   " end
        if HTSV.filterOptions.abilityNameVisible then textToDisplay = textToDisplay.."AbilityName:"..GetAbilityName(abilityId).."   " end
        if HTSV.filterOptions.resultVisible then textToDisplay = textToDisplay.."Result:"..result.."   " end
        if HTSV.filterOptions.hitValueVisible then textToDisplay = textToDisplay.."HitValue:"..hitValue.."   " end
        if HTSV.filterOptions.powerTypeVisible then textToDisplay = textToDisplay.."PowerType:"..powerType.."   " end
        if HTSV.filterOptions.damageTypeVisible then textToDisplay = textToDisplay.."DamageType:"..damageType.."   " end
        if (HTSV.filterOptions.sourceName == nil or sourceName == HTSV.filterOptions.sourceName) and (HTSV.filterOptions.targetName == nil or targetName == HTSV.filterOptions.targetName) and
                (HTSV.filterOptions.abilityId == nil or abilityId == HTSV.filterOptions.abilityId) and (HTSV.filterOptions.abilityName == nil or GetAbilityName(abilityId) == HTSV.filterOptions.abilityName) and
                (HTSV.filterOptions.result == nil or result == HTSV.filterOptions.result) and (HTSV.filterOptions.hitValue == nil or hitValue == HTSV.filterOptions.hitValue) and
                (HTSV.filterOptions.powerType == nil or powerType == HTSV.filterOptions.powerType) and (HTSV.filterOptions.damageType == nil or damageType == HTSV.filterOptions.damageType) then
            d(textToDisplay)
        end
    end)
end

function HT_unregisterEventViewer()
    EVENT_MANAGER:UnregisterForEvent("HT_eventViewer",EVENT_COMBAT_EVENT)
end