local WM = GetWindowManager()
local running = false

HT_effectSettingsVisible = false

local function hideUI()
    HT_EffectSettings:SetHidden(true)
    HT_effectSettingsVisible = false
    HT_unregisterEffectViewer()
end

local function showUI()
    HT_EffectSettings:SetHidden(false)
    HT_effectSettingsVisible = true
    HT_registerEffectViewer()
end


function HT_toggleUI()
    if HT_effectSettingsVisible then
        hideUI()
    else
        showUI()
    end
end

SLASH_COMMANDS["/hteffect"] = HT_toggleUI



function HT_InitializeEffectViewerSettings()
    local HT_EffectSettings = WM:CreateTopLevelWindow("HT_EffectSettings")
    HT_EffectSettings:SetResizeToFitDescendents(true)
    HT_EffectSettings:SetMovable(true)
    HT_EffectSettings:SetMouseEnabled(true)
    HT_EffectSettings:SetHidden(true)
    HT_EffectSettings:SetDrawLevel(DT_HIGH)

    local background = createBackground(HT_EffectSettings,"background",500,825,0,0,TOPLEFT,TOPLEFT)
    createLabel(background,'versionLabel',100,30,0,0,BOTTOMLEFT,BOTTOMLEFT,'Hyper Tools '..HT.version)
    createButton(background,"exitButton",25,25,0,0,TOPRIGHT,TOPRIGHT,function() hideUI() end,nil,"/esoui/art/buttons/decline_up.dds",true)



    local mainLabel = createLabel(background,"mainLabel",250,30,20,20,TOPLEFT,TOPLEFT,"EFFECT VIEWER",0,0,"BOLD_FONT",26)

    createLabel(background,"effectTarget",450,30,20,70,TOPLEFT,TOPLEFT,"Target: ",0,0,"BOLD_FONT",24)
    for i=1, 20 do
        createLabel(background,"effectLabel"..i,450,30,20,100+(i*30),TOPLEFT,TOPLEFT,"",0,0,"BOLD_FONT",20)
    end



    HT_EffectSettings:ClearAnchors()
    HT_EffectSettings:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT,0,0)
end

function HT_registerEffectViewer()
    local background = HT_EffectSettings:GetNamedChild("background")
    EVENT_MANAGER:UnregisterForUpdate("HT_effectViewer")
    EVENT_MANAGER:RegisterForUpdate("HT_effectViewer", 250, function()
        local target = 'player'
        if DoesUnitExist('reticleover') then target = 'reticleover' end
        background:GetNamedChild("effectTarget"):SetText(GetUnitName(target))
        for i = 1, 20 do
            if i <= GetNumBuffs(target) then
                local _, startedAt, expireTime, _, stackCount, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(target, i)
                background:GetNamedChild("effectLabel"..i):SetText(GetAbilityName(abilityId).." - "..abilityId)
            else
                background:GetNamedChild("effectLabel"..i):SetText("...")
            end
        end
    end)
end

function HT_unregisterEffectViewer()
    EVENT_MANAGER:UnregisterForUpdate("HT_effectViewer")
end