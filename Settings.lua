local WM = GetWindowManager()


local importEditboxUpdated = false

local roleToId = {
	["Damage Dealer"] = 1,
	["Tank"] = 2,
	["Healer"] = 4,
	["Any"] = 0,
}

local IdToRole = {
	[1] = "Damage Dealer",
	[2] = "Tank",
	[4] = "Healer",
	[0] = "Any",
}

local fonts = {
	"BOLD_FONT","MEDIUM_FONT","ANTIQUE_FONT","HANDWRITTEN_FONT","STONE_TABLET_FONT","GAMEPAD_MEDIUM_FONT","GAMEPAD_LIGHT_FONT","GAMEPAD_BOLD_FONT"
}

local fontWeights = {
	"","soft-shadow-thick","soft-shadow-thin","thick-outline","shadow",
}

local fontSizes = {
	8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,30,32,34,36,40,48,54
}

local resourceTexts = {
	["current/max"] = function(t)
		return t.current.."/"..t.max
	end
}


local alignments = {
	["LEFT"] = 0,
	["CENTER"] = 1,
	["RIGHT"] = 2,
}

local resources = {
	["Health"] = -2,
	["Stamina"] = 6,
	["Magicka"] = 0,
	["Werewolf"] = 1,
}
local resourcesReverse = {
	[-2] = "Health",
	[0] = "Magicka",
	[6] = "Stamina",
	[1] = "Werewolf",
}

local settingsVisible = false


local function findFreeSlotInTable(table)
	for i=1, 1000 do
		if table[i] == nil then
			return i
		end
	end
end




local getTargetNumberChoices = {
	["Group"] = {1,2,3,4,5,6,7,8,9,10,11,12},
	["Boss"] = {1,2,3,4,5,6}
}



local function GetAbilityIdFromName(name)
	for i=1,200000 do
		if GetAbilityName(i) == name then
			return i
		end
	end
	d("Couldn't find any ability with that name")
	return 0
end

local function removeElementFromTable(table,element)
	for k,v in pairs(table) do
		if v==element then
			table[k] = nil
			return
		end
	end
end

local function getChildrenFromName(name,table)
	if name == "HT_Trackers" then return HTSV.trackers end
	for k,v in pairs(table) do
		if k == name then return v.children end
		if getChildrenFromName(name,v.children) then return getChildrenFromName(name,v.children) end
	end
end



function changeTrackerName(fromName,toName)
	local tracker = getTrackerFromName(fromName,HTSV.trackers)
	if tracker.parent ~= "HT_Trackers" and getTrackerFromName(tracker.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(tracker.parent,HTSV.trackers)):Delete() else HT_findContainer(tracker):Delete() end

	--if tracker.parent ~= "HT_Trackers" and getTrackerFromName(tracker.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(tracker.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(tracker):UnregisterEvents() end
	local parentName = tracker.parent
	local holdCopy = HT_deepcopy(tracker)
	for k,v in pairs(holdCopy.children) do
		v.parent = toName
	end
	holdCopy.name = toName
	getChildrenFromName(parentName,HTSV.trackers)[toName] = holdCopy
	HT_Settings:GetNamedChild("background"):GetNamedChild("eTB"):GetNamedChild("button"..tracker.parent..tracker.name):SetHidden(true)
	getChildrenFromName(parentName,HTSV.trackers)[tracker.name] = nil
		
	tracker = getTrackerFromName(toName,HTSV.trackers)

	initializeTrackerFunctions[tracker.type](HT_findContainer(getTrackerFromName(tracker.parent,HTSV.trackers)),holdCopy)
	
end

function removeDuplicateNamesFromImportedTable(importTable,parentTable)
	if getTrackerFromName(importTable.name,HTSV.trackers) then
		changeUninitializedTrackerName(HT_generateNewName(importTable.name,1),importTable,parentTable)
	end
	for k,v in pairs(importTable.children) do
		removeDuplicateNamesFromImportedTable(v,importTable)
	end

end

function changeUninitializedTrackerName(toName,tracker,parent)
	local oldName =  tracker.name
	local parentName = tracker.parent
	for k,v in pairs(tracker.children) do
		v.parent = toName
	end
	tracker.name = toName
	if parent ~= HTSV.trackers then
		parent.children[toName] = tracker
		parent.children[oldName] = nil
	end
			
end

local function deleteTrackerFromName(name,table)
	for k,v in pairs(table) do
		if v.name == name then table[k] = nil end
		for k1,v1 in pairs(v.children) do
			deleteTrackerFromName(name,v1)
		end
	end
end


local function getKeysFromTable(varTable)
	local holder = {}
	for k,v in pairs(varTable) do
		table.insert(holder,k)
	end
	return holder
end



local function hideUI()
	HT_Settings:SetHidden(true)
	settingsVisible = false

	for k,v in pairs(HTSV.trackers) do
		HT_changeLock(v,false)
	end

end

local function showUI()
	HT_Settings:SetHidden(false)
	settingsVisible = true

	for k,v in pairs(HTSV.trackers) do
		HT_changeLock(v,true)
	end
end
SLASH_COMMANDS["/hthide"] = hideUI
SLASH_COMMANDS["/htshow"] = showUI



local CST -- Currently Selected Tracker
local CSE = 1 -- Currently Selected Event
local CSC = 1 -- Currently Selected Condition
local CTC = "HT_Trackers"-- Current Top Control
local CMT = nil -- Currently Moved Tracker
local page = 1
local maxPage = 1

function deleteTracker(t)

	if t.parent ~= "HT_Trackers" and getTrackerFromName(t.parent,HTSV.trackers).type == "Group Member" then 
		for i=1,12 do
			HT_findContainer(t,i):Delete() 
		end
	else 
		HT_findContainer(t):Delete() 
	end
	getChildrenFromName(CTC,HTSV.trackers)[t.name] = nil
	CST = HTSV.trackers["none"]
	CSC = HT_pickAnyKey(CST.conditions)	


end



local rightSideBackground = {
	[0] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("newTrackersBackdrop"):SetHidden(false) end,
	[1] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):SetHidden(false) end,
	[2] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newProgressBarBackdrop"):SetHidden(false) end,
	[3] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newIconTrackerBackdrop"):SetHidden(false) end,
	[4] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newGroupTrackerBackdrop"):SetHidden(false) end,
	[5] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newGroupMemberTrackerBackdrop"):SetHidden(false) end,
	[6] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newImportBackdrop"):SetHidden(false) end,
}

local function selectRightSideBackground(number)
	local background = HT_Settings:GetNamedChild("background")
	local newTrackersBackdrop = background:GetNamedChild("newTrackersBackdrop")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local newIconTrackerBackdrop = background:GetNamedChild("newIconTrackerBackdrop")
	local newProgressBarBackdrop = background:GetNamedChild("newProgressBarBackdrop")
	local newGroupTrackerBackdrop = background:GetNamedChild("newGroupTrackerBackdrop")
	local newGroupMemberTrackerBackdrop = background:GetNamedChild("newGroupMemberTrackerBackdrop")
	local newImportBackdrop = background:GetNamedChild("newImportBackdrop")
	newTrackersBackdrop:SetHidden(true)
	selectedTrackerSettingsBackdrop:SetHidden(true)
	newProgressBarBackdrop:SetHidden(true)
	newIconTrackerBackdrop:SetHidden(true)
	newGroupTrackerBackdrop:SetHidden(true)
	newGroupMemberTrackerBackdrop:SetHidden(true)
	newImportBackdrop:SetHidden(true)
	rightSideBackground[number]()
end

local function selectCurrentlyEditedBackground(number)
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local display = selectedTrackerSettingsBackdrop:GetNamedChild("displayBackground")
	local displayResource = selectedTrackerSettingsBackdrop:GetNamedChild("displayBackgroundResource")
	local displayButton = selectedTrackerSettingsBackdrop:GetNamedChild("button11")
	local condition = selectedTrackerSettingsBackdrop:GetNamedChild("conditionBackground")
	local conditionButton = selectedTrackerSettingsBackdrop:GetNamedChild("button22")
	local event = selectedTrackerSettingsBackdrop:GetNamedChild("eventBackground")
	local eventButton = selectedTrackerSettingsBackdrop:GetNamedChild("button12")
	local general = selectedTrackerSettingsBackdrop:GetNamedChild("generalBackground")
	local generalResource = selectedTrackerSettingsBackdrop:GetNamedChild("generalBackgroundResource")
	local generalButton = selectedTrackerSettingsBackdrop:GetNamedChild("button21")
	display:SetHidden(true)
	displayResource:SetHidden(true)
	displayButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
	condition:SetHidden(true)
	conditionButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
	event:SetHidden(true)
	eventButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
	general:SetHidden(true)
	generalResource:SetHidden(true)
	generalButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
	if number == 11 then
		if CST.type == "Resource Bar" then
			displayResource:SetHidden(false)
			display:SetHidden(true)
		else
			displayResource:SetHidden(true)
			display:SetHidden(false)
		end
		displayButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
	elseif number == 22 then
		condition:SetHidden(false)
		conditionButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
	elseif number == 12 then
		event:SetHidden(false)
		eventButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
	elseif number == 21 then
		if CST.type == "Resource Bar" then
			general:SetHidden(true)
			generalResource:SetHidden(false)
		else
			general:SetHidden(false)
			generalResource:SetHidden(true)
		end
		generalButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
	end
end

local function checkIfElementIsInsideTable(table,element)
	for k,v in pairs(table) do
		if element == v then
			return true
		end
	end
	return false
end








local function updateDisplayBackground()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local displayBackground = selectedTrackerSettingsBackdrop:GetNamedChild("displayBackground")
	local TextPosXEditbox = displayBackground:GetNamedChild("TextPosXEditbox")
	local cstYposEditbox = displayBackground:GetNamedChild("cstYposEditbox")
	local texturePath = displayBackground:GetNamedChild("editbox")
	local dropdownIDs = displayBackground:GetNamedChild("autoTextureDropdown")
	local dropdownFonts = displayBackground:GetNamedChild("fontDropdown")
	local fontWeightDropdown = displayBackground:GetNamedChild("fontWeightDropdown")
	local dropdownFontsSize = displayBackground:GetNamedChild("fontSizeDropdown")
	local decimalsDropdown = displayBackground:GetNamedChild("decimalsDropdown")
	local text = displayBackground:GetNamedChild("textEditbox")
	local height = displayBackground:GetNamedChild("cstXsizeEditbox")
	local width = displayBackground:GetNamedChild("cstYsizeEditbox")
	local outlineThicknessDropdown = displayBackground:GetNamedChild("outlineThicknessDropdown")
	local colorpicker = displayBackground:GetNamedChild("colorpickerRegular")
	local colorpicker2 = displayBackground:GetNamedChild("colorpicker2")
	local colorpicker3 = displayBackground:GetNamedChild("colorpicker3")
	local inverseCheckbox = displayBackground:GetNamedChild("inverseCheckbox")
	local remainingTimeCheckbox = displayBackground:GetNamedChild("remainingTimeCheckbox")
	local stacksCheckbox = displayBackground:GetNamedChild("stacksCheckbox")
	local drawLevelDropdown = displayBackground:GetNamedChild("drawLevelDropdown")
	local colorpickerLabelColorpicker = displayBackground:GetNamedChild("colorpickerLabelColorpicker")
	local colorpickerStacksolorpicker = displayBackground:GetNamedChild("colorpickerStacksolorpicker")
	local colorpickerTimeColorpicker = displayBackground:GetNamedChild("colorpickerTimeColorpicker")
	texturePath:SetText(CST.icon)
	dropdownIDs.choices = CST.IDs
	dropdownIDs.selection = HT_pickAnyElement(CST.IDs,0)
	dropdownIDs:updateDropdown()
	dropdownFonts.selection = CST.font
	dropdownFonts:updateDropdown()
	fontWeightDropdown.selection = CST.fontWeight
	fontWeightDropdown:updateDropdown()
	dropdownFontsSize.selection = CST.fontSize
	dropdownFontsSize:updateDropdown()
	decimalsDropdown.selection = CST.decimals
	decimalsDropdown:updateDropdown()
	text:SetText(CST.text)
	height:SetText(math.floor(CST.sizeX))
	width:SetText(math.floor(CST.sizeY))
	colorpicker:SetColor(unpack(CST.barColor))
	colorpicker2:SetColor(unpack(CST.outlineColor))
	colorpicker3:SetColor(unpack(CST.backgroundColor))
	TextPosXEditbox:SetText(math.floor(CST.xOffset))
	cstYposEditbox:SetText(math.floor(CST.yOffset))
	if CST.type == "Icon Tracker" then
		outlineThicknessDropdown:SetHidden(true)
	else
		outlineThicknessDropdown:SetHidden(false)
		outlineThicknessDropdown.selection = CST.outlineThickness
		outlineThicknessDropdown:updateDropdown()
	end
	inverseCheckbox:Update(CST.inverse)
	remainingTimeCheckbox:Update(CST.timer1)
	stacksCheckbox:Update(CST.timer2)
	colorpickerLabelColorpicker:SetColor(unpack(CST.textColor))
	colorpickerStacksolorpicker:SetColor(unpack(CST.stacksColor))
	colorpickerTimeColorpicker:SetColor(unpack(CST.timeColor))
	drawLevelDropdown.selection = CST.drawLevel
	drawLevelDropdown:updateDropdown()
end

local function updateDisplayBackgroundResource()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local displayBackgroundResource = selectedTrackerSettingsBackdrop:GetNamedChild("displayBackgroundResource")
	local TextPosXEditbox = displayBackgroundResource:GetNamedChild("TextPosXEditbox")
	local cstYposEditbox = displayBackgroundResource:GetNamedChild("cstYposEditbox")
	local dropdownFonts = displayBackgroundResource:GetNamedChild("fontDropdown")
	local dropdownFontsSize = displayBackgroundResource:GetNamedChild("fontSizeDropdown")
	local text = displayBackgroundResource:GetNamedChild("textDropdown")
	local textAlignmentDropdown = displayBackgroundResource:GetNamedChild("textAlignmentDropdown")
	local height = displayBackgroundResource:GetNamedChild("cstXsizeEditbox")
	local width = displayBackgroundResource:GetNamedChild("cstYsizeEditbox")
	local colorpicker = displayBackgroundResource:GetNamedChild("colorpicker")
	local colorpicker2 = displayBackgroundResource:GetNamedChild("colorpicker2")
	local colorpicker3 = displayBackgroundResource:GetNamedChild("colorpicker3")
	dropdownFonts.selection = CST.font
	dropdownFonts:updateDropdown()
	dropdownFontsSize.selection = CST.fontSize
	dropdownFontsSize:updateDropdown()
	text.selection = CST.text
	text:updateDropdown()
	textAlignmentDropdown.selection = CST.textAlignment
	textAlignmentDropdown:updateDropdown()
	height:SetText(math.floor(CST.sizeX))
	width:SetText(math.floor(CST.sizeY))
	colorpicker:SetColor(unpack(CST.barColor))
	colorpicker2:SetColor(unpack(CST.outlineColor))
	colorpicker3:SetColor(unpack(CST.backgroundColor))
	TextPosXEditbox:SetText(math.floor(CST.xOffset))
	cstYposEditbox:SetText(math.floor(CST.yOffset))
end



local function updateGeneralBackground()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local generalBackground = selectedTrackerSettingsBackdrop:GetNamedChild("generalBackground")
	local name = generalBackground:GetNamedChild("NameEditbox")
	local targetDropdown = generalBackground:GetNamedChild("TargetDropdown")
	local IDsDropdown = generalBackground:GetNamedChild("IDs dropdown")
	local TargetNumberDropdown = generalBackground:GetNamedChild("TargetNumberDropdown")
	local neverCheckbox = generalBackground:GetNamedChild("neverCheckbox")
	local combatCheckbox = generalBackground:GetNamedChild("combatCheckbox")
	local classDropdown = generalBackground:GetNamedChild("classDropdown")
	local roleDropdown = generalBackground:GetNamedChild("roleDropdown")
	local itemSetDropdown = generalBackground:GetNamedChild("itemSetDropdown")
	local skillDropdown = generalBackground:GetNamedChild("skillDropdown")
	local zoneDropdown = generalBackground:GetNamedChild("zoneDropdown")
	local bossDropdown = generalBackground:GetNamedChild("bossDropdown")
	
	neverCheckbox:Update(CST.load.never)
	combatCheckbox:Update(CST.load.inCombat)

	classDropdown.selection = CST.load.class
	classDropdown:updateDropdown()

	roleDropdown.selection = IdToRole[CST.load.role]
	roleDropdown:updateDropdown()

	itemSetDropdown.choices = CST.load.itemSets
	itemSetDropdown.selection = HT_pickAnyElement(CST.load.itemSets)
	itemSetDropdown:updateDropdown()

	skillDropdown.choices = CST.load.skills
	skillDropdown.selection = HT_pickAnyElement(CST.load.skills)
	skillDropdown:updateDropdown()

	zoneDropdown.choices = CST.load.zones
	zoneDropdown.selection = HT_pickAnyElement(CST.load.zones)
	zoneDropdown:updateDropdown()

	bossDropdown.choices = CST.load.bosses
	bossDropdown.selection = HT_pickAnyElement(CST.load.bosses)
	bossDropdown:updateDropdown()

	name:SetText(CST.name)

	if CST.type == "Group Member" or (CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member") then
		targetDropdown:SetHidden(true)
		TargetNumberDropdown:SetHidden(true)
	else
		targetDropdown:SetHidden(false)
		targetDropdown.selection = CST.target
		targetDropdown:updateDropdown()
		if CST.target == "Yourself" or CST.target == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[CST.target] or {1}
			TargetNumberDropdown.selection = CST.targetNumber
			TargetNumberDropdown:updateDropdown()
		end
	end

	



	IDsDropdown.choices = CST.IDs
	IDsDropdown.selection = HT_pickAnyElement(CST.IDs)
	IDsDropdown:updateDropdown()
	
end

local function updateGeneralBackgroundResources()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local generalBackgroundResource = selectedTrackerSettingsBackdrop:GetNamedChild("generalBackgroundResource")
	local name = generalBackgroundResource:GetNamedChild("NameEditbox")
	local IDsDropdown = generalBackgroundResource:GetNamedChild("IDs dropdown")

	name:SetText(CST.name)
	IDsDropdown.selection = resourcesReverse[CST.IDs[1]]
	IDsDropdown:updateDropdown()
end

local function updateConditionBackground()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local conditionBackground = selectedTrackerSettingsBackdrop:GetNamedChild("conditionBackground")
	local topDropdown = conditionBackground:GetNamedChild("dropdown")
	local arg1Dropdown = conditionBackground:GetNamedChild("dropdownArg1")
	local operatorDropdown = conditionBackground:GetNamedChild("dropdownOperator")
	local arg2Editbox = conditionBackground:GetNamedChild("editboxArg2")
	local resultDropdown = conditionBackground:GetNamedChild("dropdownResult")
	local resultColorpicker = conditionBackground:GetNamedChild("resultColorpicker")
	topDropdown.choices = getKeysFromTable(CST.conditions)
	topDropdown.selection = HT_pickAnyKey(CST.conditions)
	topDropdown:updateDropdown()
	if CSC == "none" then
		arg1Dropdown.selection = "none"
		arg1Dropdown:updateDropdown()
		operatorDropdown.selection = "none"
		operatorDropdown:updateDropdown()
		arg2Editbox:SetText("")
		resultDropdown.selection = "none"
		resultDropdown:updateDropdown()
		resultColorpicker:SetHidden(true)
	else
		arg1Dropdown.selection = CST.conditions[CSC].arg1
		arg1Dropdown:updateDropdown()
		operatorDropdown.selection = CST.conditions[CSC].operator
		operatorDropdown:updateDropdown()
		arg2Editbox:SetText(CST.conditions[CSC].arg2)
		resultDropdown.selection = CST.conditions[CSC].result
		resultDropdown:updateDropdown()
		resultColorpicker:SetColor(unpack(CST.conditions[CSC].resultArguments))
	end
	HT_processResultControlType()
end

local function updateEventBackground()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local eventBackground = selectedTrackerSettingsBackdrop:GetNamedChild("eventBackground")
	local eventDropdown = eventBackground:GetNamedChild("dropdown")
	local eventTypeDropdown = eventBackground:GetNamedChild("dropdown2")
	local arg1Editbox =  eventBackground:GetNamedChild("arg1Editbox")
	local onlyYourCastCheckbox =  eventBackground:GetNamedChild("onlyYourCastCheckbox")
	local overwriteShortedDurationCheckbox =  eventBackground:GetNamedChild("overwriteShortedDurationCheckbox")
	eventDropdown.choices = getKeysFromTable(CST.events)
	eventDropdown.selection = HT_pickAnyKey(CST.events)
	eventDropdown:updateDropdown()
	eventTypeDropdown.selection = CST.events[CSE].type
	eventTypeDropdown:updateDropdown()
	if CST.events[CSE].type == "Get Effect Cooldown" then
		arg1Editbox:SetHidden(false)
		arg1Editbox:SetText(CST.events[CSE].arguments.cooldown)
		overwriteShortedDurationCheckbox:SetHidden(true)
	elseif CST.events[CSE].type == "Get Effect Duration" then
		onlyYourCastCheckbox:Update(CST.events[CSE].arguments.onlyYourCast)
		overwriteShortedDurationCheckbox:SetHidden(false)
		overwriteShortedDurationCheckbox:Update(CST.events[CSE].arguments.overwriteShorterDuration)
		arg1Editbox:SetHidden(true)
	end
	
end


local function createLeftSidePanelButton(parent,counter,t)
	if t.name ~= "none" then
		local tracker = getTrackerFromName(t.name,HTSV.trackers)
		local button = createButton(parent,"button"..tracker.parent..tracker.name,200,50,0,50*counter,TOPLEFT,TOPLEFT,function(ctrl,alt,shift) 
			if (tracker.type == "Group" or tracker.type == "Group Member") and ctrl and tracker ~= CST then
				local holdCopy = HT_deepcopy(CST)
				local buttonToRemove = parent:GetNamedChild("button"..CST.parent..CST.name)
				buttonToRemove:SetHidden(true)
				holdCopy.parent = tracker.name
				
				
				deleteTracker(CST)
				


				holdCopy.xOffset = holdCopy.xOffset - tracker.xOffset
				holdCopy.yOffset = holdCopy.yOffset - tracker.yOffset
				

				tracker.children[holdCopy.name] = holdCopy
				if tracker.type ~= "Group Member" then
					initializeTrackerFunctions[holdCopy.type](HT_findContainer(tracker),holdCopy)
				end
			elseif tracker.type ~= "Group" and tracker.type ~= "Group Member" and shift then
				local newName = HT_generateNewName(tracker.name,1)
				local holdCopy = HT_deepcopy(tracker)
				holdCopy.name = newName
				getChildrenFromName(tracker.parent,HTSV.trackers)[newName] = holdCopy

				initializeTrackerFunctions[holdCopy.type](HT_findContainer(getTrackerFromName(tracker.parent,HTSV.trackers)),holdCopy)
				
			end
			
			selectRightSideBackground(1)
			CST = getTrackerFromName(t.name,HTSV.trackers)
			CSC = HT_pickAnyKey(tracker.conditions)
			selectCurrentlyEditedBackground(11)
			relocateLeftSide()
			updateDisplayBackground()
			updateDisplayBackgroundResource()
			updateGeneralBackground()
			updateGeneralBackgroundResources()
			updateConditionBackground()
			updateEventBackground()
		end,nil,nil,true)
		local deleteButton = createButton(button,"deleteButton",23,23,-2,2,TOPRIGHT,TOPRIGHT,function()
			
			deleteTracker(tracker)

			relocateLeftSide()
			updateDisplayBackground()
			updateDisplayBackgroundResource()
			updateGeneralBackground()
			updateGeneralBackgroundResources()
			updateConditionBackground()
			updateEventBackground()
			button:SetHidden(true)
		end,nil,"/esoui/art/buttons/decline_up.dds",true)
		
		local moveButton = createButton(button,"moveButton",23,23,-23,2,TOPRIGHT,TOPRIGHT,function()
			local holdCopy = HT_deepcopy(tracker)
			holdCopy.parent = getTrackerFromName(getTrackerFromName(t.name,HTSV.trackers).parent,HTSV.trackers).parent
			
			
			
			

			deleteTracker(tracker)
			--holdCopy.xOffset = holdCopy.xOffset - getTrackerFromName(holdCopy.parent,HTSV.trackers).xOffset
			--holdCopy.yOffset = holdCopy.yOffset - getTrackerFromName(holdCopy.parent,HTSV.trackers).yOffset
			getChildrenFromName(holdCopy.parent,HTSV.trackers)[holdCopy.name] = holdCopy
			initializeTrackerFunctions[holdCopy.type](HT_findContainer(getTrackerFromName(holdCopy.parent,HTSV.trackers)),holdCopy)

			button:SetHidden(true)
			relocateLeftSide()
			updateDisplayBackground()
			updateDisplayBackgroundResource()
			updateGeneralBackground()
			updateGeneralBackgroundResources()
			updateConditionBackground()
			updateEventBackground()

		end,nil,"/esoui/art/buttons/scrollbox_uparrow_up.dds",true)
		if tracker.parent == "HT_Trackers" then
			moveButton:SetHidden(true)
		end
		if tracker.type == "Group" or tracker.type == "Group Member" then
			local goInsideButton = createButton(button,"goInsideButton",23,23,-2,-2,BOTTOMRIGHT,BOTTOMRIGHT,function()
				CTC = tracker.name
				relocateLeftSide()
				updateDisplayBackground()
				updateDisplayBackgroundResource()
				updateGeneralBackground()
				updateGeneralBackgroundResources()
				updateConditionBackground()
				updateEventBackground()
			end,nil,"/esoui/art/buttons/scrollbox_downarrow_up.dds",true)
		end
		local icon = createTexture(button,"icon",50,50,1,1,TOPLEFT,TOPLEFT,tracker.icon,4)
		local text = createLabel(icon,"text",125,25,0,0,TOPLEFT,TOPRIGHT,tracker.name,1,1)
		local type = createLabel(icon,"type",125,25,0,0,BOTTOMLEFT,BOTTOMRIGHT,tracker.type,1,1)
	end
end





function relocateLeftSide()
	local background = HT_Settings:GetNamedChild("background")
	local eTB = background:GetNamedChild("eTB")
	local counter = 0
	local returnButton = eTB:GetNamedChild("returnButton")
	local offset = counter+2
	local pageCounter = eTB:GetNamedChild("pageCounter")
	if CTC == "HT_Trackers" then -- if tracker is anchored to HT_Trackers dont show Return button
		returnButton:SetHidden(true)
	else
		returnButton:SetHidden(false)
	end

	local tableOfChildren = getChildrenFromName(CTC,HTSV.trackers) or {}


	local function hideAllButtons(tracker)
		if eTB:GetNamedChild("button"..tracker.parent..tracker.name) then
			eTB:GetNamedChild("button"..tracker.parent..tracker.name):SetHidden(true)
		end
		for k1,v1 in pairs(tracker.children) do
			hideAllButtons(v1)
		end
	end

	for k,v in pairs(HTSV.trackers) do -- hide all buttons
		hideAllButtons(v)
	end
	--local page = pageNumber or 1
	local moreThan =12*(page-1)
	local lessThan = moreThan + 11

	for k,v in pairs(tableOfChildren) do -- show buttons of current top control
		if not eTB:GetNamedChild("button"..v.parent..k) then
			createLeftSidePanelButton(eTB,offset,v)
		else
			local button = eTB:GetNamedChild("button"..v.parent..k)
			local moveButton = button:GetNamedChild("moveButton")
			button:ClearAnchors()
			button:SetAnchor(TOPLEFT,eTB,TOPLEFT,0,50*offset)
			local icon = button:GetNamedChild("icon")
			local text = icon:GetNamedChild("text")
			text:SetText(k)
			icon:SetTexture(v.icon)
			if counter >= moreThan and counter <= lessThan then
				button:SetHidden(false)
			end

			if CST.name == v.name then
				button.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
				icon.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
			else
				button.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
				icon.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
			end
			if v.parent == "HT_Trackers" then
				moveButton:SetHidden(true)
			else
				moveButton:SetHidden(false)
			end
		end
		if k ~= "none" then
			counter = counter + 1
			offset = offset + 1
		end
		if counter%12 == 0 then offset = 2 end
	end
	maxPage = math.floor((counter-1)/12)+1
	if maxPage < page then
		page = maxPage
		relocateLeftSide()
	end
	if page == 0 then page = 1 end
	if maxPage == 0 then maxPage = 1 end
	pageCounter:SetText(page.."/"..maxPage)
end




local function createNewTracker(type,name,text,IDs,sizeX,sizeY,color,target,targetNumber,event)
	if getTrackerFromName(name, HTSV.trackers) then
		name = HT_generateNewName(name,1)
	end
	HTSV.trackers[name] = {
	type = type,
	name = name,
	text = text,
	textAlignment = 1,
	font = "BOLD_FONT",
	fontSize = 16,
	fontWeight = "thick-outline",
	IDs = IDs,
	target = target,
	outlineThickness = 2,
	current = 0,
	decimals = 1,
	max = 0,
	targetNumber = targetNumber,
	drawLevel = 0,
	hideIcon = false,
	icon = GetAbilityIcon(HT_pickAnyElement(IDs,0)),
	anchorToGroupMember = true,
	barColor = color,
	timeColor = {1,1,1,1},
	backgroundColor = {0,0,0,0.4},
	outlineColor = {0,0,0,1},
	textColor= {1,1,1,1},
	stacksColor = {1,1,1,1},
	sizeX = sizeX,
	sizeY = sizeY,
	parent = "HT_Trackers",
	children = {},
	show = true,
	xOffset = 0,
	yOffset = 0,
	timer1 = true,
	timer2 = true,
	inverse = false,
	conditions = {
		
	},
	duration = {},
	expiresAt = {},
	stacks = {},
	events = {
		[1] = {
		type = event,
		arguments = {
			cooldown = 0,
			onlyYourCast = false,
			overwriteShorterDuration = false,
        },
		},
	},
	load = {
		never = false,
		inCombat = false,
		role = 0,
		class = "Any",
		skills = {},
		itemSets = {},
		zones = {},
		bosses = {},
	},
	}
	initializeTrackerFunctions[type](HT_Trackers,HTSV.trackers[name])
end


local function onSceneChange(_,scene)
	if scene == SCENE_SHOWN then
		HT_Settings:SetHidden(not settingsVisible)
		HT_Trackers:SetHidden(false)
		HT_3D:SetHidden(false)
	else
		HT_Settings:SetHidden(true)
		HT_Trackers:SetHidden(true)
		HT_3D:SetHidden(true)
	end
end




function HT_Settings_initializeUI()


	 ESO_Dialogs["HT_Export"] = {
		canQueue = true,
		uniqueIdentifier = "HT_Export",
		title = {text = "Export Tracker"},
		mainText = {text = "Copy this string (Ctrl+A to select all then Ctrl+C to copy)"},
		editBox = {defaultText  = "test"},
		updateFn = function(dialog) 
			if not importEditboxUpdated then 
				dialog:GetNamedChild("EditBox"):SetMaxInputChars(30000)
				dialog:GetNamedChild("EditBox"):SetText(convertToString(CST)) 
				importEditboxUpdated = true 
			end 
		end,
		buttons = {

		  [1] = {
			text = "Close",
			callback = function() end,
		  },
		},
		setup = function()end,
  }





	local HT_Settings = WM:CreateTopLevelWindow("HT_Settings")
	HT_Settings:SetResizeToFitDescendents(true)
    HT_Settings:SetMovable(true)
    HT_Settings:SetMouseEnabled(true)
	HT_Settings:SetHidden(false)
	HT_Settings:SetDrawLevel(DT_HIGH)
	
	CST = HTSV.trackers["none"] -- Currently Selected Tracker

	local background = createBackground(HT_Settings,"background",800,825,0,0,TOPLEFT,TOPLEFT)

	------ BACKGROUND ON THE LEFT WITH ALL EXISTING TRACKERS ----------------
	local eTB = createBackground(background,"eTB",200,775,25,25,TOPLEFT,TOPLEFT) -- existing trackers background
	
	local button = createButton(eTB,"button",200,50,0,0,TOPLEFT,TOPLEFT,function() 
		selectRightSideBackground(0)
		relocateLeftSide() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
	end,nil,nil,true)
	local buttonIcon = createTexture(eTB,"buttonIcon",50,50,0,0,TOPLEFT,TOPLEFT,"HyperTools/icons/plusIcon.dds",2)
	local text = createLabel(buttonIcon,"text",150,50,0,0,LEFT,RIGHT,"Create new",1,1)
	local returnButton = createButton(eTB,"returnButton",200,50,0,50,TOPLEFT,TOPLEFT,function() 
		CTC = getTrackerFromName(CTC,HTSV.trackers).parent
		relocateLeftSide() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
	end,"Return",nil,true)
	returnButton:SetHidden(true)
	local pageCounter = createLabel(eTB,"pageCounter",50,30,0,0,BOTTOM,BOTTOM,"1/1",1,1)
	createButton(pageCounter,"nextPageButton",20,20,0,0,LEFT,RIGHT,function() 
		if page < maxPage then
			page = page + 1
			relocateLeftSide(page)
		end
	end,nil,"/esoui/art/charactercreate/charactercreate_rightarrow_up.dds",nil)
	createButton(pageCounter,"previousPageButton",20,20,0,0,RIGHT,LEFT,function() 
		if page > 1 then
			page = page - 1
			relocateLeftSide(page)
		end
	end,nil,"/esoui/art/charactercreate/charactercreate_leftarrow_up.dds",nil)

	local counter = 2
	for i,v in pairs(HTSV.trackers) do
		if i ~= "none" then
			createLeftSidePanelButton(eTB,counter,v)
			counter = counter + 1
		end
	end
	relocateLeftSide()
	------ BACKGROUND ON THE LEFT WITH ALL EXISTING TRACKERS ----------------




	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS ----------------
	local typesByNumber = {
		[2] = "Progress Bar",
		[3] = "Icon Tracker",
		[4] = "Group",
		[5] = "Group Member",
		[6] = "Import Tracker",
	}
	local iconsByNumber = {
		[2] = "HyperTools/icons/ProgressBarIcon.dds",
		[3] = "HyperTools/icons/IconTrackerIcon.dds",
		[4] = "HyperTools/icons/GroupIcon.dds",
		[5] = "HyperTools/icons/GroupMemberIcon.dds",
		[6] = "HyperTools/icons/ImportIcon.dds",
	}
	local textsByNumber = {
		[2] = "Shows a progress bar with timer, stacks, and text",
		[3] = "Shows an icon with timer and stacks",
		[4] = "Place trackers inside a group to move them together, assign them same hide/show conditions and to export them as one",
		[5] = "Trackers placed inside that group will be repeated 12 times and placed next to each of your group members",
		[6] = "Paste an import string and import a pre-made tracker",
	}
	local newTrackersBackdrop = createBackground(background,"newTrackersBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newTrackersBackdrop:SetHidden(false)
	for i=2, 6 do
		local icon = createTexture(newTrackersBackdrop,"icon"..i,100,100,0,100*(i-2),TOPLEFT,TOPLEFT,iconsByNumber[i],2)
		local button = createButton(icon,"button"..i,425,100,0,0,TOPLEFT,TOPRIGHT,function() selectRightSideBackground(i) relocateLeftSide() updateDisplayBackground() updateDisplayBackgroundResource() end,nil,nil,true)
		local title = createLabel(button,"title"..i,425,50,0,0,TOP,TOP,typesByNumber[i],1,1,"BOLD_FONT",26)
		local text = createLabel(button,"text"..i,425,50,0,0,BOTTOM,BOTTOM,textsByNumber[i],1,1,nil,nil)
	end
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS ----------------




	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (PROGRESS BAR) ----------------

	local newProgressBarBackdrop = createBackground(background,"newProgressBarBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newProgressBarBackdrop:SetHidden(true)
	createTexture(newProgressBarBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newProgressBarBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newProgressBarBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newProgressBarBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)
	local nameEditbox = createEditbox(newProgressBarBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(editbox)

	end)
	createLabel(newProgressBarBackdrop,"IdsLabel",175,30,15,110,TOPLEFT,TOPLEFT,"IDs",0,1)
	local IDsDropdown = createDropdown(newProgressBarBackdrop,"IDs dropdown",175,32,15,165,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)




	local editbox = createEditbox(newProgressBarBackdrop,"addIdEditbox",175,30,15,135,TOPLEFT,TOPLEFT,function(editbox)

	end)
	
	createButton(newProgressBarBackdrop,"buttonDeleteID",30,30,190,165,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(IDsDropdown.choices,IDsDropdown.selection)
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end, nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",nil)
	createButton(newProgressBarBackdrop,"buttonAddID",30,30,188,135,TOPLEFT,TOPLEFT,function() 

		table.insert(IDsDropdown.choices,(tonumber(editbox:GetText()) or GetAbilityIdFromName(editbox:GetText())))
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end,nil,"/esoui/art/buttons/plus_up.dds",nil)




	local TargetNumberDropdown = createDropdown(newProgressBarBackdrop,"TargetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT, {1},1,function(selection)

	end)
	createLabel(TargetNumberDropdown,"TargetNumber",50,30,0,0,BOTTOMLEFT,TOPLEFT,"Number",0,1)
	
	local dropdown = createDropdown(newProgressBarBackdrop,"TargetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),"Yourself",function(selection)
		if selection == "Yourself" or selection == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[selection] or {1}
			TargetNumberDropdown:updateDropdown()
		end
	end)
	createLabel(dropdown,"Target",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Target",0,1)
	
	local dropdown2 = createDropdown(newProgressBarBackdrop,"dropdown2",200,30,245,145,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),"Get Effect Duration",function(selection)

	end)
	createLabel(dropdown2,"a",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Type",0,1)

	
	createLabel(newProgressBarBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newProgressBarBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,CST.barColor,function(color) 
		
	end)
	createTexture(newProgressBarBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	
	createLabel(newProgressBarBackdrop,"TextSizeX",150,30,15,440,TOPLEFT,TOPLEFT,"Width",0)
	local widthEditbox = createEditbox(newProgressBarBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(editbox)

	end,210)
	createLabel(newProgressBarBackdrop,"TextSizeY",150,30,250,440,TOPLEFT,TOPLEFT,"Height",0)
	local heightEditbox = createEditbox(newProgressBarBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(editbox)

	end,30)

	createLabel(newProgressBarBackdrop,"textLabel",150,30,250,500,TOPLEFT,TOPLEFT,"Text",0,1)
	local textEditbox = createEditbox(newProgressBarBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(editbox)
		
	end)

	local buttonCreateTracker = createButton(newProgressBarBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		createNewTracker("Progress Bar",nameEditbox:GetText(),textEditbox:GetText(),IDsDropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color,dropdown.selection,TargetNumberDropdown.selection,dropdown2.selection)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		
		nameEditbox:SetText("")
		textEditbox:SetText("")
		IDsDropdown.choices = {}
		IDsDropdown.selection = nil
		IDsDropdown:updateDropdown()
		widthEditbox:SetText(210)
		heightEditbox:SetText(30)
		colorpicker:SetColor(1,1,1,1)
		dropdown.selection = "Yourself"
		dropdown:updateDropdown()
		TargetNumberDropdown.selection = 1
		TargetNumberDropdown:updateDropdown()
		dropdown2.selection = "Get Effect Duration"
		dropdown2:updateDropdown()
	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (PROGRESS BAR) ----------------
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (ICON TRACKER) ----------------
	local newIconTrackerBackdrop = createBackground(background,"newIconTrackerBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newIconTrackerBackdrop:SetHidden(true)
	createTexture(newIconTrackerBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newIconTrackerBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newIconTrackerBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newIconTrackerBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)
	local nameEditbox = createEditbox(newIconTrackerBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(editbox)

	end)
	createLabel(newIconTrackerBackdrop,"IdsLabel",175,30,15,110,TOPLEFT,TOPLEFT,"IDs",0,1)
	local IDsDropdown = createDropdown(newIconTrackerBackdrop,"IDs dropdown",175,32,15,165,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)




	local editbox = createEditbox(newIconTrackerBackdrop,"addIdEditbox",175,30,15,135,TOPLEFT,TOPLEFT,function(editbox)

	end)
	
	createButton(newIconTrackerBackdrop,"buttonDeleteID",30,30,190,165,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(IDsDropdown.choices,IDsDropdown.selection)
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end, nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",nil)
	createButton(newIconTrackerBackdrop,"buttonAddID",30,30,188,135,TOPLEFT,TOPLEFT,function() 

		table.insert(IDsDropdown.choices,(tonumber(editbox:GetText()) or GetAbilityIdFromName(editbox:GetText())))
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end,nil,"/esoui/art/buttons/plus_up.dds",nil)




	local TargetNumberDropdown = createDropdown(newIconTrackerBackdrop,"TargetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT, {1},1,function(selection)

	end)
	createLabel(TargetNumberDropdown,"TargetNumber",50,30,0,0,BOTTOMLEFT,TOPLEFT,"Number",0,1)
	
	local dropdown = createDropdown(newIconTrackerBackdrop,"TargetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),"Yourself",function(selection)
		if selection == "Yourself" or selection == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[selection] or {1}
			TargetNumberDropdown:updateDropdown()
		end
	end)
	createLabel(dropdown,"Target",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Target",0,1)
	
	local dropdown2 = createDropdown(newIconTrackerBackdrop,"dropdown2",200,30,245,145,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),"Get Effect Duration",function(selection)

	end)
	createLabel(dropdown2,"a",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Type",0,1)

	
	createLabel(newIconTrackerBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newIconTrackerBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,CST.barColor,function(color) 
		
	end)
	createTexture(newIconTrackerBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	
	createLabel(newIconTrackerBackdrop,"TextSizeX",150,30,15,440,TOPLEFT,TOPLEFT,"Width",0)
	local widthEditbox = createEditbox(newIconTrackerBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(editbox)

	end,80)
	createLabel(newIconTrackerBackdrop,"TextSizeY",150,30,250,440,TOPLEFT,TOPLEFT,"Height",0)
	local heightEditbox = createEditbox(newIconTrackerBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(editbox)

	end,80)

	createLabel(newIconTrackerBackdrop,"textLabel",150,30,250,500,TOPLEFT,TOPLEFT,"Text",0,1)
	local textEditbox = createEditbox(newIconTrackerBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(editbox)
		
	end)

	local buttonCreateTracker = createButton(newIconTrackerBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		createNewTracker("Icon Tracker",nameEditbox:GetText(),textEditbox:GetText(),IDsDropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color,dropdown.selection,TargetNumberDropdown.selection,dropdown2.selection)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		
		nameEditbox:SetText("")
		textEditbox:SetText("")
		IDsDropdown.choices = {}
		IDsDropdown.selection = nil
		IDsDropdown:updateDropdown()
		widthEditbox:SetText(80)
		heightEditbox:SetText(80)
		colorpicker:SetColor(1,1,1,1)
		dropdown.selection = "Yourself"
		dropdown:updateDropdown()
		TargetNumberDropdown.selection = 1
		TargetNumberDropdown:updateDropdown()
		dropdown2.selection = "Get Effect Duration"
		dropdown2:updateDropdown()
	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (ICON TRACKER) ----------------

	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP MEMBER) ----------------
	local newGroupTrackerBackdrop = createBackground(background,"newGroupTrackerBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newGroupTrackerBackdrop:SetHidden(true)
	createTexture(newGroupTrackerBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupTrackerBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newGroupTrackerBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupTrackerBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)
	local nameEditbox = createEditbox(newGroupTrackerBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(editbox)

	end)
	createLabel(newGroupTrackerBackdrop,"IdsLabel",175,30,15,110,TOPLEFT,TOPLEFT,"IDs",0,1)
	local IDsDropdown = createDropdown(newGroupTrackerBackdrop,"IDs dropdown",175,32,15,165,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)




	local editbox = createEditbox(newGroupTrackerBackdrop,"addIdEditbox",175,30,15,135,TOPLEFT,TOPLEFT,function(editbox)

	end)
	
	createButton(newGroupTrackerBackdrop,"buttonDeleteID",30,30,190,165,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(IDsDropdown.choices,IDsDropdown.selection)
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end, nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",nil)
	createButton(newGroupTrackerBackdrop,"buttonAddID",30,30,188,135,TOPLEFT,TOPLEFT,function() 

		table.insert(IDsDropdown.choices,(tonumber(editbox:GetText()) or GetAbilityIdFromName(editbox:GetText())))
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end,nil,"/esoui/art/buttons/plus_up.dds",nil)




	local TargetNumberDropdown = createDropdown(newGroupTrackerBackdrop,"TargetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT, {1},1,function(selection)

	end)
	createLabel(TargetNumberDropdown,"TargetNumber",50,30,0,0,BOTTOMLEFT,TOPLEFT,"Number",0,1)
	
	local dropdown = createDropdown(newGroupTrackerBackdrop,"TargetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),"Yourself",function(selection)
		if selection == "Yourself" or selection == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[selection] or {1}
			TargetNumberDropdown:updateDropdown()
		end
	end)
	createLabel(dropdown,"Target",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Target",0,1)
	
	local dropdown2 = createDropdown(newGroupTrackerBackdrop,"dropdown2",200,30,245,145,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),"Get Effect Duration",function(selection)

	end)
	createLabel(dropdown2,"a",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Type",0,1)

	
	createLabel(newGroupTrackerBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newGroupTrackerBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,CST.barColor,function(color) 
		
	end)
	createTexture(newGroupTrackerBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	
	createLabel(newGroupTrackerBackdrop,"TextSizeX",150,30,15,440,TOPLEFT,TOPLEFT,"Width",0)
	local widthEditbox = createEditbox(newGroupTrackerBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(editbox)

	end,100)
	createLabel(newGroupTrackerBackdrop,"TextSizeY",150,30,250,440,TOPLEFT,TOPLEFT,"Height",0)
	local heightEditbox = createEditbox(newGroupTrackerBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(editbox)

	end,100)

	createLabel(newGroupTrackerBackdrop,"textLabel",150,30,250,500,TOPLEFT,TOPLEFT,"Text",0,1)
	local textEditbox = createEditbox(newGroupTrackerBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(editbox)
		
	end)

	local buttonCreateTracker = createButton(newGroupTrackerBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		createNewTracker("Group",nameEditbox:GetText(),textEditbox:GetText(),IDsDropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color,dropdown.selection,TargetNumberDropdown.selection,dropdown2.selection)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		
		nameEditbox:SetText("")
		textEditbox:SetText("")
		IDsDropdown.choices = {}
		IDsDropdown.selection = nil
		IDsDropdown:updateDropdown()
		widthEditbox:SetText(100)
		heightEditbox:SetText(100)
		colorpicker:SetColor(1,1,1,1)
		dropdown.selection = "Yourself"
		dropdown:updateDropdown()
		TargetNumberDropdown.selection = 1
		TargetNumberDropdown:updateDropdown()
		dropdown2.selection = "Get Effect Duration"
		dropdown2:updateDropdown()
	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP) ----------------


	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP MEMBER) ----------------
	local newGroupMemberTrackerBackdrop = createBackground(background,"newGroupMemberTrackerBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newGroupMemberTrackerBackdrop:SetHidden(true)
	createTexture(newGroupMemberTrackerBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupMemberTrackerBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newGroupMemberTrackerBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupMemberTrackerBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)
	local nameEditbox = createEditbox(newGroupMemberTrackerBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(editbox)

	end)
	createLabel(newGroupMemberTrackerBackdrop,"IdsLabel",175,30,15,110,TOPLEFT,TOPLEFT,"IDs",0,1)
	local IDsDropdown = createDropdown(newGroupMemberTrackerBackdrop,"IDs dropdown",175,32,15,165,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)




	local editbox = createEditbox(newGroupMemberTrackerBackdrop,"addIdEditbox",175,30,15,135,TOPLEFT,TOPLEFT,function(editbox)

	end)
	
	createButton(newGroupMemberTrackerBackdrop,"buttonDeleteID",30,30,190,165,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(IDsDropdown.choices,IDsDropdown.selection)
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end, nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",nil)
	createButton(newGroupMemberTrackerBackdrop,"buttonAddID",30,30,188,135,TOPLEFT,TOPLEFT,function() 

		table.insert(IDsDropdown.choices,(tonumber(editbox:GetText()) or GetAbilityIdFromName(editbox:GetText())))
		IDsDropdown.selection = HT_pickAnyElement(IDsDropdown.choices)
		IDsDropdown:updateDropdown()
	end,nil,"/esoui/art/buttons/plus_up.dds",nil)




	local TargetNumberDropdown = createDropdown(newGroupMemberTrackerBackdrop,"TargetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT, {1},1,function(selection)

	end)
	createLabel(TargetNumberDropdown,"TargetNumber",50,30,0,0,BOTTOMLEFT,TOPLEFT,"Number",0,1)
	
	local dropdown = createDropdown(newGroupMemberTrackerBackdrop,"TargetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),"Yourself",function(selection)
		if selection == "Yourself" or selection == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[selection] or {1}
			TargetNumberDropdown:updateDropdown()
		end
	end)
	createLabel(dropdown,"Target",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Target",0,1)
	
	local dropdown2 = createDropdown(newGroupMemberTrackerBackdrop,"dropdown2",200,30,245,145,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),"Get Effect Duration",function(selection)

	end)
	createLabel(dropdown2,"a",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Type",0,1)

	
	createLabel(newGroupMemberTrackerBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newGroupMemberTrackerBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,CST.barColor,function(color) 
		
	end)
	createTexture(newGroupMemberTrackerBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	
	createLabel(newGroupMemberTrackerBackdrop,"TextSizeX",150,30,15,440,TOPLEFT,TOPLEFT,"Width",0)
	local widthEditbox = createEditbox(newGroupMemberTrackerBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(editbox)

	end,100)
	createLabel(newGroupMemberTrackerBackdrop,"TextSizeY",150,30,250,440,TOPLEFT,TOPLEFT,"Height",0)
	local heightEditbox = createEditbox(newGroupMemberTrackerBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(editbox)

	end,100)

	createLabel(newGroupMemberTrackerBackdrop,"textLabel",150,30,250,500,TOPLEFT,TOPLEFT,"Text",0,1)
	local textEditbox = createEditbox(newGroupMemberTrackerBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(editbox)
		
	end)

	local buttonCreateTracker = createButton(newGroupMemberTrackerBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		createNewTracker("Group Member",nameEditbox:GetText(),textEditbox:GetText(),IDsDropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color,dropdown.selection,TargetNumberDropdown.selection,dropdown2.selection)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		
		nameEditbox:SetText("")
		textEditbox:SetText("")
		IDsDropdown.choices = {}
		IDsDropdown.selection = nil
		IDsDropdown:updateDropdown()
		widthEditbox:SetText(100)
		heightEditbox:SetText(100)
		colorpicker:SetColor(1,1,1,1)
		dropdown.selection = "Yourself"
		dropdown:updateDropdown()
		TargetNumberDropdown.selection = 1
		TargetNumberDropdown:updateDropdown()
		dropdown2.selection = "Get Effect Duration"
		dropdown2:updateDropdown()
	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP MEMBER) ----------------


		------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (IMPORT) ----------------
	local newImportBackdrop = createBackground(background,"newImportBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newImportBackdrop:SetHidden(true)
	createTexture(newImportBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newImportBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newImportBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newImportBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Import String",0,1)
	local nameEditbox = createEditbox(newImportBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(editbox)

	end)

	

	local buttonCreateTracker = createButton(newImportBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		local importString = nameEditbox:GetText()
		if importString then
			importString = string.sub(importString,2,#importString-1)
			local importedTable = importFromString(importString)
			importedTable.parent = "HT_Trackers"
			removeDuplicateNamesFromImportedTable(importedTable,HTSV.trackers)
			importedTable.parent = "HT_Trackers"
			HTSV.trackers[importedTable.name] = importedTable
			initializeTrackerFunctions[importedTable.type](HT_Trackers,importedTable)
			relocateLeftSide()   
			updateDisplayBackground()
			updateDisplayBackgroundResource()
			updateGeneralBackground()
			updateGeneralBackgroundResources()
			updateConditionBackground()
			updateEventBackground()
		end
		nameEditbox:SetText("")

	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (IMPORT) ----------------





	------ BACKGROUND ON THE RIGHT WHERE U CHANGE SETTINGS OF SELECTED TRACKERS ----------------
	local selectedTrackerSettingsBackdrop = createBackground(background,"selectedTrackerSettingsBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	selectedTrackerSettingsBackdrop:SetHidden(true)
	local tabs = {
		[1] = {
			[1] = "Display",
			[2] = "Event",
		},
		[2] = {
			[1] = "General",
			[2] = "Condition",
		},
	}

	for n=1,2 do
		for i=1,2 do
			local button = createButton(selectedTrackerSettingsBackdrop,"button"..n..i,525/2,25,(525/2)*(i-1),25*(n-1),TOPLEFT,TOPLEFT,function() 
			selectCurrentlyEditedBackground(i+(n*10))
			end,tabs[n][i],nil,true)
			if n==1 and i==1 then button.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1) end
		end
	end

	--------- DISPLAY -------------
	local displayBackground = createBackground(selectedTrackerSettingsBackdrop,"displayBackground",525,725,0,50,TOPLEFT,TOPLEFT)

	createTexture(displayBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"DISPLAY",1,1,"BOLD_FONT",26)
	createTexture(displayBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackground,"texturePath",150,30,15,60,TOPLEFT,TOPLEFT,"Texture path",0,1)
	local editbox = createEditbox(displayBackground,"editbox",475,30,15,90,TOPLEFT,TOPLEFT,function(editbox)
		CST.icon = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.icon)
	createLabel(displayBackground,"autoTextureDropdownLabel",180,30,15,120,TOPLEFT,TOPLEFT,"Set automatic texture from ID",0,1)
	local autoTextureDropdown = createDropdown(displayBackground,"autoTextureDropdown",200,30,15,145,TOPLEFT,TOPLEFT,CST.IDs,HT_pickAnyElement(CST.IDs,0),function(selection)
		
	end)
	createButton(displayBackground,"button",200,30,250,145,TOPLEFT,TOPLEFT,function() 
		CST.icon = GetAbilityIcon(autoTextureDropdown.selection or 0)
		editbox:SetText(GetAbilityIcon(autoTextureDropdown.selection or 0))
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		relocateLeftSide()
	end,"Auto-set texture",nil,true)
	createLabel(displayBackground,"fontLabel",90,30,15,180,TOPLEFT,TOPLEFT,"Font",0,1)
	createDropdown(displayBackground,"fontDropdown",90,30,15,205,TOPLEFT,TOPLEFT,fonts,CST.font,function(selection)
		if CST.name ~= "none" then
			CST.font = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then
					HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers))
			else
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)
	createLabel(displayBackground,"fontWeightLabel",60,30,105,180,TOPLEFT,TOPLEFT,"Weight",0,1)
	createDropdown(displayBackground,"fontWeightDropdown",60,30,105,205,TOPLEFT,TOPLEFT,fontWeights,CST.fontWeight,function(selection)
		if CST.name ~= "none" then
			CST.fontWeight = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackground,"fontSizeLabel",50,30,160,180,TOPLEFT,TOPLEFT,"Size",0,1)
	createDropdown(displayBackground,"fontSizeDropdown",50,30,160,205,TOPLEFT,TOPLEFT,fontSizes,CST.fontSize,function(selection)
		if CST.name ~= "none" then
			CST.fontSize = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackground,"textLabel",150,30,250,180,TOPLEFT,TOPLEFT,"Text",0,1)
	createEditbox(displayBackground,"textEditbox",200,30,250,205,TOPLEFT,TOPLEFT,function(editbox)
		CST.text = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.text)
	createLabel(displayBackground,"colorpickerText",70,30,15,250,TOPLEFT,TOPLEFT,"Bar",0,1)
	createColorpicker(displayBackground,"colorpickerRegular",70,30,15,275,TOPLEFT,TOPLEFT,CST.barColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.barColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)


	createLabel(displayBackground,"colorpickerText2",70,30,100,250,TOPLEFT,TOPLEFT,"Outline",0,1)
	createColorpicker(displayBackground,"colorpicker2",70,30,100,275,TOPLEFT,TOPLEFT,CST.outlineColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.outlineColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)
	createLabel(displayBackground,"colorpickerText3",70,30,185,250,TOPLEFT,TOPLEFT,"Background",0,1)
	createColorpicker(displayBackground,"colorpicker3",70,30,185,275,TOPLEFT,TOPLEFT,CST.backgroundColor,function(color) 
		if type(color) == "table" then
			CST.backgroundColor = color 
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)

	createLabel(displayBackground,"colorpickerLabelLabel",70,30,15,315,TOPLEFT,TOPLEFT,"Text",0,1)
	createColorpicker(displayBackground,"colorpickerLabelColorpicker",70,30,15,340,TOPLEFT,TOPLEFT,CST.textColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.textColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)

	createLabel(displayBackground,"colorpickerTimeLabel",70,30,100,315,TOPLEFT,TOPLEFT,"Time",0,1)
	createColorpicker(displayBackground,"colorpickerTimeColorpicker",70,30,100,340,TOPLEFT,TOPLEFT,CST.timeColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.timeColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)

	createLabel(displayBackground,"colorpickerStacksLabel",70,30,185,315,TOPLEFT,TOPLEFT,"Stacks",0,1)
	createColorpicker(displayBackground,"colorpickerStacksolorpicker",70,30,185,340,TOPLEFT,TOPLEFT,CST.stacksColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.stacksColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)


	createCheckbox(displayBackground,"inverseCheckbox", 30,30,270,250,TOPLEFT,TOPLEFT,CST.inverse,function(arg) 
		if CST.name ~= "none" then
			CST.inverse = arg
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackground,"inverseCheckboxLabel",150,30,310,250,TOPLEFT,TOPLEFT,"Inverse",0,1)


	createCheckbox(displayBackground,"remainingTimeCheckbox", 30,30,270,290,TOPLEFT,TOPLEFT,CST.timer1,function(arg) 
		if CST.name ~= "none" then
			CST.timer1 = arg
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackground,"RemainingTimeCheckboxLabel",150,30,310,290,TOPLEFT,TOPLEFT,"Remaining Time",0,1)


	createLabel(displayBackground,"decimalsLabel",50,30,400,280,TOPLEFT,TOPLEFT,"Decimals",0,1)
	createDropdown(displayBackground,"decimalsDropdown",50,30,400,305,TOPLEFT,TOPLEFT,{0,1},CST.decimals,function(selection)
		if CST.name ~= "none" then
			CST.decimals = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)


	createCheckbox(displayBackground,"stacksCheckbox", 30,30,270,330,TOPLEFT,TOPLEFT,CST.timer2,function(arg) 
		if CST.name ~= "none" then
			CST.timer2 = arg
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackground,"stacksCheckboxLabel",150,30,310,330,TOPLEFT,TOPLEFT,"Stacks",0,1)


	local drawLevelDropdown = createDropdown(displayBackground,"drawLevelDropdown",50,30,15,400,TOPLEFT,TOPLEFT,{0,1,2,3,4},CST.drawLevel,function(selection)
		if CST.name ~= "none" then
			CST.drawLevel = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(drawLevelDropdown,"drawLevelLabeln",150,30,0,-25,TOPLEFT,TOPLEFT,"Draw Level",0)






	createTexture(displayBackground,"edge3",475,2,15,530,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackground,"TextPosX",150,30,15,540,TOPLEFT,TOPLEFT,"X position",0)
	createEditbox(displayBackground,"TextPosXEditbox",200,30,15,565,TOPLEFT,TOPLEFT,function(editbox)
		CST.xOffset = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.xOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackground,"TextPosY",150,30,250,540,TOPLEFT,TOPLEFT,"Y position",0)
	createEditbox(displayBackground,"cstYposEditbox",200,30,250,565,TOPLEFT,TOPLEFT,function(editbox)
		CST.yOffset = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.yOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackground,"TextSizeX",150,30,15,590,TOPLEFT,TOPLEFT,"Width",0)
	createEditbox(displayBackground,"cstXsizeEditbox",200,30,15,615,TOPLEFT,TOPLEFT,function(editbox)
		CST.sizeX = editbox:GetText()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.sizeX,TEXT_TYPE_NUMERIC)
	createLabel(displayBackground,"TextSizeY",150,30,250,590,TOPLEFT,TOPLEFT,"Height",0)
	createEditbox(displayBackground,"cstYsizeEditbox",200,30,250,615,TOPLEFT,TOPLEFT,function(editbox)
		CST.sizeY = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.sizeY,TEXT_TYPE_NUMERIC)
	
	
	local outlineThicknessDropdown = createDropdown(displayBackground,"outlineThicknessDropdown",200,30,15,665,TOPLEFT,TOPLEFT,{1,2,4,8,16},CST.outlineThickness,function(selection)
		if CST.name ~= "none" then
			CST.outlineThickness = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(outlineThicknessDropdown,"outlineThicknessLabel",150,30,0,-25,TOPLEFT,TOPLEFT,"Outline Thickness",0)






	--[[createDropdown(displayBackground,"anchorToGroupMemberDropdown",50,30,320,405,TOPLEFT,TOPLEFT,{1,2,3,4,5,6,7,8,9,10,11,12},CST.targetNumber,function(selection)
		if CST.name ~= "none" then
			CST.targetNumber = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createCheckbox(displayBackground,"anchorToGroupMemberCheckbox", 30,30,270,370,TOPLEFT,TOPLEFT,CST.anchorToGroupMember,function(arg) 
		CST.anchorToGroupMember = arg
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end)
	createLabel(displayBackground,"anchorToGroupMemberCheckboxLabel",150,30,315,370,TOPLEFT,TOPLEFT,"Anchor to group member",0,1)]]

	--------- DISPLAY -------------


	--------- DISPLAY RESOURCE-------------
	local displayBackgroundResource = createBackground(selectedTrackerSettingsBackdrop,"displayBackgroundResource",525,725,0,50,TOPLEFT,TOPLEFT)

	createTexture(displayBackgroundResource,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackgroundResource,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"DISPLAY",1,1,"BOLD_FONT",26)
	createTexture(displayBackgroundResource,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")


	createLabel(displayBackgroundResource,"fontLabel",150,30,15,180,TOPLEFT,TOPLEFT,"Font",0,1)
	createDropdown(displayBackgroundResource,"fontDropdown",150,30,15,205,TOPLEFT,TOPLEFT,fonts,CST.font,function(selection)
		if CST.name ~= "none" then
			CST.font = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackgroundResource,"fontSizeLabel",50,30,160,180,TOPLEFT,TOPLEFT,"Font Size",0,1)
	createDropdown(displayBackgroundResource,"fontSizeDropdown",50,30,160,205,TOPLEFT,TOPLEFT,fontSizes,CST.fontSize,function(selection)
		if CST.name ~= "none" then
			CST.fontSize = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackgroundResource,"textAlignmentLabel",150,30,250,120,TOPLEFT,TOPLEFT,"Text Alignment",0,1)
	createDropdown(displayBackgroundResource,"textAlignmentDropdown",200,30,250,145,TOPLEFT,TOPLEFT,getKeysFromTable(alignments),CST.textAlignment,function(selection)
		if CST.name ~= "none" then
			CST.textAlignment = alignments[selection]
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	createLabel(displayBackgroundResource,"textLabel",150,30,250,180,TOPLEFT,TOPLEFT,"Text",0,1)
	createDropdown(displayBackgroundResource,"textDropdown",200,30,250,205,TOPLEFT,TOPLEFT,getKeysFromTable(resourceTexts),CST.text,function(selection)
		if CST.name ~= "none" then
			CST.text = selection
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end)
	
	createLabel(displayBackgroundResource,"colorpickerText",70,30,15,250,TOPLEFT,TOPLEFT,"Color",0,1)
	createColorpicker(displayBackgroundResource,"colorpicker",70,30,15,275,TOPLEFT,TOPLEFT,CST.barColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.barColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)


	createLabel(displayBackgroundResource,"colorpickerText2",70,30,100,250,TOPLEFT,TOPLEFT,"Outline",0,1)
	createColorpicker(displayBackgroundResource,"colorpicker2",70,30,100,275,TOPLEFT,TOPLEFT,CST.outlineColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.outlineColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)
	createLabel(displayBackgroundResource,"colorpickerText3",70,30,185,250,TOPLEFT,TOPLEFT,"Background",0,1)
	createColorpicker(displayBackgroundResource,"colorpicker3",70,30,185,275,TOPLEFT,TOPLEFT,CST.backgroundColor,function(color) 
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.backgroundColor = color 
				if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end)


	createTexture(displayBackgroundResource,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackgroundResource,"TextPosX",150,30,15,430,TOPLEFT,TOPLEFT,"X position",0)
	createEditbox(displayBackgroundResource,"TextPosXEditbox",200,30,15,455,TOPLEFT,TOPLEFT,function(editbox)
		if CST.name ~= "none" then
			CST.xOffset = editbox:GetText() 
			updateDisplayBackgroundResource()
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,CST.xOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackgroundResource,"TextPosY",150,30,250,430,TOPLEFT,TOPLEFT,"Y position",0)
	createEditbox(displayBackgroundResource,"cstYposEditbox",200,30,250,455,TOPLEFT,TOPLEFT,function(editbox)
		if CST.name ~= "none" then
			CST.yOffset = editbox:GetText() 
			updateDisplayBackgroundResource()
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,CST.yOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackgroundResource,"TextSizeX",150,30,15,520,TOPLEFT,TOPLEFT,"Width",0)
	createEditbox(displayBackgroundResource,"cstXsizeEditbox",200,30,15,545,TOPLEFT,TOPLEFT,function(editbox)
		if CST.name ~= "none" then
			CST.sizeX = editbox:GetText()
			updateDisplayBackgroundResource()
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,CST.sizeX,TEXT_TYPE_NUMERIC)
	createLabel(displayBackgroundResource,"TextSizeY",150,30,250,520,TOPLEFT,TOPLEFT,"Height",0)
	createEditbox(displayBackgroundResource,"cstYsizeEditbox",200,30,250,545,TOPLEFT,TOPLEFT,function(editbox)
		if CST.name ~= "none" then
			CST.sizeY = editbox:GetText() 
			updateDisplayBackgroundResource()
			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,CST.sizeY,TEXT_TYPE_NUMERIC)
	--------- DISPLAY RESOURCE-------------




	--------- GENERAL -------------
	local generalBackground = createBackground(selectedTrackerSettingsBackdrop,"generalBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	generalBackground:SetHidden(true)
	createTexture(generalBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"GENERAL",1,1,"BOLD_FONT",26)
	createTexture(generalBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"Name",150,30,15,50,TOPLEFT,TOPLEFT,"Name",0,1)
	local editbox = createEditbox(generalBackground,"NameEditbox",200,30,15,75,TOPLEFT,TOPLEFT,function(editbox)
		if not getTrackerFromName(editbox:GetText(),HTSV.trackers) then
			changeTrackerName(CST.name,editbox:GetText())
			CST = getTrackerFromName(editbox:GetText(),HTSV.trackers)

			if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			relocateLeftSide()
		else
			d("Duplicate name")
		end
	end,CST.name)
	
	local TargetNumberDropdown = createDropdown(generalBackground,"TargetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT,getTargetNumberChoices[CST.target] or {1},CST.targetNumber or 1,function(selection)
		CST.targetNumber = selection
	end)
	createLabel(TargetNumberDropdown,"TargetNumber",50,30,0,0,BOTTOMLEFT,TOPLEFT,"Number",0,1)
	
	local dropdown = createDropdown(generalBackground,"TargetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),CST.target,function(selection)
		CST.target = selection
		if CST.target == "Yourself" or CST.target == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[CST.target] or {1}
			TargetNumberDropdown.selection = CST.targetNumber
			TargetNumberDropdown:updateDropdown()
		end
	end)
	createLabel(dropdown,"Target",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Target",0,1)
	
	createLabel(generalBackground,"IdsLabel",175,30,15,110,TOPLEFT,TOPLEFT,"IDs",0,1)
	local dropdown = createDropdown(generalBackground,"IDs dropdown",175,32,15,165,TOPLEFT,TOPLEFT,CST.IDs,HT_pickAnyElement(CST.IDs),function(selection)

	end)




	local editbox = createEditbox(generalBackground,"addIdEditbox",175,30,15,135,TOPLEFT,TOPLEFT,function(editbox)

	end)

	createButton(generalBackground,"buttonDeleteID",30,30,190,165,TOPLEFT,TOPLEFT,function()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		removeElementFromTable(CST.IDs,dropdown.selection)
		
		dropdown.choices = CST.IDs
		dropdown.selection = HT_pickAnyElement(CST.IDs)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end, nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",nil)
	createButton(generalBackground,"buttonAddID",30,30,188,135,TOPLEFT,TOPLEFT,function() 

		table.insert(CST.IDs,(tonumber(editbox:GetText()) or GetAbilityIdFromName(editbox:GetText())))
		
		dropdown.choices = CST.IDs
		dropdown.selection = HT_pickAnyElement(CST.IDs)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,nil,"/esoui/art/buttons/plus_up.dds",nil)

	createButton(generalBackground,"exportButton",200,30,15,250,TOPLEFT,TOPLEFT,function() 
		importEditboxUpdated = false
		ZO_Dialogs_ShowDialog("HT_Export")
	end,"Export Tracker",nil,true)



	createTexture(generalBackground,"edge3",165,2,15,300,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"loadLabel",150,30,180,287.5,TOPLEFT,TOPLEFT,"LOAD",1,1,"BOLD_FONT",26)
	createTexture(generalBackground,"edge4",165,2,330,300,TOPLEFT,TOPLEFT,"")
	
	
	createCheckbox(generalBackground,"neverCheckbox", 30,30,15,340,TOPLEFT,TOPLEFT,CST.load.never,function(arg) 
	CST.load.never = arg
	end)
	createLabel(generalBackground,"neverCheckboxLabel",150,30,55,340,TOPLEFT,TOPLEFT,"Never",0,1)

	createCheckbox(generalBackground,"combatCheckbox", 30,30,235,340,TOPLEFT,TOPLEFT,CST.load.inCombat,function(arg) 
	CST.load.inCombat = arg
	end)
	createLabel(generalBackground,"combatCheckboxLabel",150,30,275,340,TOPLEFT,TOPLEFT,"In Combat",0,1)

	createLabel(generalBackground,"classLabel",150,30,15,540,TOPLEFT,TOPLEFT,"Class",0,1)
	createDropdown(generalBackground,"classDropdown",200,30,15,565,TOPLEFT,TOPLEFT,{"Any","Dragonknight","Nightblade","Sorcerer","Templar","Warden","Necromancer"},CST.load.class,function(selection)
		if CST.name ~= "none" then
			CST.load.class = selection
		end
	end)

	createLabel(generalBackground,"roleLabel",150,30,15,480,TOPLEFT,TOPLEFT,"Role",0,1)
	createDropdown(generalBackground,"roleDropdown",200,30,15,505,TOPLEFT,TOPLEFT,{"Any","Damage Dealer","Tank","Healer"},IdToRole[CST.load.role],function(selection)
		if CST.name ~= "none" then
			CST.load.role = roleToId[selection]
		end
	end)

		createLabel(generalBackground,"bossLabel",175,30,15,380,TOPLEFT,TOPLEFT,"Bosses",0,1)
	local dropdown = createDropdown(generalBackground,"bossDropdown",175,32,15,435,TOPLEFT,TOPLEFT,CST.load.bosses,HT_pickAnyElement(CST.load.bosses),function(selection)

	end)

	local editbox = createEditbox(generalBackground,"addBossEditbox",175,30,15,405,TOPLEFT,TOPLEFT,function(editbox)

	end,nil)

	createButton(generalBackground,"buttonDeleteBoss",30,30,190,435,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(CST.load.bosses,dropdown.selection)
		dropdown.choices = CST.load.bosses
		dropdown.selection = HT_pickAnyElement(CST.load.bosses)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAddBoss",30,30,188,405,TOPLEFT,TOPLEFT,function() 

		table.insert(CST.load.bosses,editbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = CST.load.bosses
		dropdown.selection = HT_pickAnyElement(CST.load.bosses)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,"+",nil,nil)



	createLabel(generalBackground,"skillsLabel",175,30,15,600,TOPLEFT,TOPLEFT,"Skills",0,1)
	local dropdown = createDropdown(generalBackground,"skillDropdown",175,32,15,655,TOPLEFT,TOPLEFT,CST.load.skills,HT_pickAnyElement(CST.load.skills),function(selection)

	end)

	local editbox = createEditbox(generalBackground,"addSkillEditbox",175,30,15,625,TOPLEFT,TOPLEFT,function(editbox)

	end,nil,TEXT_TYPE_NUMERIC)

	createButton(generalBackground,"buttonDeleteSkill",30,30,190,655,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(CST.load.skills,dropdown.selection)
		dropdown.choices = CST.load.skills
		dropdown.selection = HT_pickAnyElement(CST.load.skills)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAddSkill",30,30,188,625,TOPLEFT,TOPLEFT,function() 

		table.insert(CST.load.skills,tonumber(editbox:GetText()))-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = CST.load.skills
		dropdown.selection = HT_pickAnyElement(CST.load.skills)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,"+",nil,nil)



	createLabel(generalBackground,"itemSetsLabel",175,30,235,600,TOPLEFT,TOPLEFT,"Item Sets",0,1)
	local dropdown = createDropdown(generalBackground,"itemSetDropdown",175,32,235,655,TOPLEFT,TOPLEFT,CST.load.itemSets,HT_pickAnyElement(CST.load.itemSets),function(selection)

	end)

	local editbox = createEditbox(generalBackground,"addItemSetEditbox",175,30,235,625,TOPLEFT,TOPLEFT,function(editbox)

	end)

	createButton(generalBackground,"buttonDeleteitemSet",30,30,410,655,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(CST.load.itemSets,dropdown.selection)
		dropdown.choices = CST.load.itemSets
		dropdown.selection = HT_pickAnyElement(CST.load.itemSets)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAdditemSet",30,30,408,625,TOPLEFT,TOPLEFT,function() 

		table.insert(CST.load.itemSets,editbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = CST.load.itemSets
		dropdown.selection = HT_pickAnyElement(CST.load.itemSets)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,"+",nil,nil)


	createLabel(generalBackground,"zonesLabel",175,30,235,480,TOPLEFT,TOPLEFT,"Zones",0,1)
	local dropdown = createDropdown(generalBackground,"zoneDropdown",175,32,235,535,TOPLEFT,TOPLEFT,CST.load.zones,HT_pickAnyElement(CST.load.zones),function(selection)

	end)

	local editbox = createEditbox(generalBackground,"addzoneEditbox",175,30,235,505,TOPLEFT,TOPLEFT,function(editbox)

	end)

	createButton(generalBackground,"buttonDeletezone",30,30,410,535,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(CST.load.zones,dropdown.selection)
		dropdown.choices = CST.load.zones
		dropdown.selection = HT_pickAnyElement(CST.load.zones)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAddzone",30,30,408,505,TOPLEFT,TOPLEFT,function() 

		table.insert(CST.load.zones,editbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = CST.load.zones
		dropdown.selection = HT_pickAnyElement(CST.load.zones)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,"+",nil,nil)




	--------- GENERAL -------------


	--------- GENERAL RESOURCE-------------
	local generalBackgroundResource = createBackground(selectedTrackerSettingsBackdrop,"generalBackgroundResource",525,725,0,50,TOPLEFT,TOPLEFT)
	generalBackgroundResource:SetHidden(true)
	createTexture(generalBackgroundResource,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackgroundResource,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"GENERAL",1,1,"BOLD_FONT",26)
	createTexture(generalBackgroundResource,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackgroundResource,"Name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)
	local editbox = createEditbox(generalBackgroundResource,"NameEditbox",200,30,15,90,TOPLEFT,TOPLEFT,function(editbox)
		  if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.name = editbox:GetText() 
		
		relocateLeftSide()
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.name)


	createLabel(generalBackgroundResource,"IdsLabel",150,30,15,140,TOPLEFT,TOPLEFT,"Resource Types",0,1)
	local dropdown = createDropdown(generalBackgroundResource,"IDs dropdown",200,30,15,165,TOPLEFT,TOPLEFT,getKeysFromTable(resources),resourcesReverse[CST.IDs[1]],function(selection)
		  if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.IDs = {resources[selection]}
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end)





	createTexture(generalBackgroundResource,"edge3",165,2,15,400,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackgroundResource,"loadLabel",150,30,180,387.5,TOPLEFT,TOPLEFT,"LOAD",1,1,"BOLD_FONT",26)
	createTexture(generalBackgroundResource,"edge4",165,2,330,400,TOPLEFT,TOPLEFT,"")


	--createCheckbox(generalBackgroundResource,"combatCheckbox", 30,30,15,450,TOPLEFT,TOPLEFT,CST.load.combat,function(arg) 
	--if CST.name ~= "none" then
	--	CST.load.combat = arg
	--end
	--end)
	createLabel(generalBackgroundResource,"combatCheckboxLabel",150,30,55,450,TOPLEFT,TOPLEFT,"In Combat",0,1)
	--------- GENERAL RESOURCE-------------


	
	--------- CONDITIONS -------------
	local pickProperResultControl = {
		["Set Bar Color"] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(false) end,
		["Set Border Color"] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(false) end,
		["Set Background Color"] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(false) end,
		["Set Text Color"] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(false) end,
		["Set Timer Color"] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(false) end,
		["Set Stacks Color"] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(false) end,
		["Hide Tracker"] = function() end,
		["Show Proc"] = function() end,
	}
	function HT_processResultControlType()
		HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(true)
		HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultCheckbox"):SetHidden(true)
		if CSC ~= "none" then
			pickProperResultControl[CST.conditions[CSC].result]()
		end
	end
	local conditionBackground = createBackground(selectedTrackerSettingsBackdrop,"conditionBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	conditionBackground:SetHidden(true)

	createTexture(conditionBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(conditionBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CONDITIONS",1,1,"BOLD_FONT",26)
	createTexture(conditionBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	local dropdownArg1 = createDropdown(conditionBackground,"dropdownArg1",200,30,45,140,TOPLEFT,TOPLEFT,getKeysFromTable(conditionArgs1),CST.conditions[CSC].arg1 or "",function(selection)
	if CSC ~= "none" then
		CST.conditions[CSC].arg1 = selection
	end
	end)
	local addConditionLabel = createLabel(conditionBackground,"ACLabel",200,20,45,120,TOPLEFT,TOPLEFT,"Set condition",0)
	local dropdownOperator = createDropdown(conditionBackground,"dropdownOperator",50,30,260,140,TOPLEFT,TOPLEFT,getKeysFromTable(operators),CST.conditions[CSC].operator,function(selection)
	if CSC ~= "none" then
		CST.conditions[CSC].operator = selection
	end
	end)
	local editboxArg2 = createEditbox(conditionBackground,"editboxArg2",150,30,320,140,TOPLEFT,TOPLEFT,function(editbox) 
	if CSC ~= "none" then
		CST.conditions[CSC].arg2 = tonumber(editbox:GetText()) 
	end
	end,CST.conditions[CSC].arg2)
	local resultColorpicker = createColorpicker(conditionBackground,"resultColorpicker", 70,30,260,190,TOPLEFT,TOPLEFT,CST.conditions[CSC].resultArguments,function(color) 
	if CSC ~= "none" then
		CST.conditions[CSC].resultArguments = color
	end
	end)
	local resultCheckbox = createCheckbox(conditionBackground,"resultCheckbox", 30,30,280,150,TOPLEFT,TOPLEFT,CST.conditions[CSC].resultArguments,function(arg) 
	if CSC ~= "none" then
		CST.conditions[CSC].resultArguments = arg
	end
	end)
	local dropdownResult = createDropdown(conditionBackground,"dropdownResult",200,30,45,190,TOPLEFT,TOPLEFT,getKeysFromTable(conditionResults),CST.conditions[CSC].result,function(selection)
	if CSC ~= "none" then
		CST.conditions[CSC].result = selection
		HT_processResultControlType()
	end
	end)
	HT_processResultControlType()
	local resultLabel = createLabel(conditionBackground,"RLabel",200,20,45,170,TOPLEFT,TOPLEFT,"Set result",0)
	local dropdown = createDropdown(conditionBackground,"dropdown",200,30,45,80,TOPLEFT,TOPLEFT,getKeysFromTable(CST.conditions),CSC,function(selection)
	CSC = selection
	dropdownArg1.selection = CST.conditions[CSC].arg1
	dropdownArg1:updateDropdown()
	dropdownOperator.selection = CST.conditions[CSC].operator
	dropdownOperator:updateDropdown()
	editboxArg2:SetText(CST.conditions[CSC].arg2)
	resultColorpicker:SetColor(unpack(CST.conditions[CSC].resultArguments))
	dropdownResult.selection = CST.conditions[CSC].result
	dropdownResult:updateDropdown()
	HT_processResultControlType()
	end)
	local selectedConditionLabel = createLabel(conditionBackground,"SCLabel",200,20,45,60,TOPLEFT,TOPLEFT,"Select/Add condition",0)
	createButton(conditionBackground,"button",30,30,15,80,TOPLEFT,TOPLEFT,function() 
		--PlaySound(SOUNDS.DUEL_START)
		table.insert(CST.conditions,{
		arg1 = "Remaining Time",
		arg2 = 0,
		operator = "<",
		result = "Hide Tracker",
		resultArguments = {0,0,1,1},
		})
		dropdown.choices = getKeysFromTable(CST.conditions)
		dropdown.selection = CSC
		dropdown:updateDropdown()
		relocateLeftSide()
	end,nil,"esoui/art/buttons/plus_up.dds",false)

	createButton(dropdown,"deleteButton",30,30,0,0,LEFT,RIGHT,function() 
		--PlaySound(SOUNDS.DUEL_START)
		CST.conditions[CSC] = nil
		dropdown.choices = getKeysFromTable(CST.conditions)
		dropdown.selection = HT_pickAnyKey(CST.conditions)
		dropdown:updateDropdown()
		relocateLeftSide()
	end,nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",false)

	--------- CONDITIONS -------------


	--------- EVENTS -------------
	local eventBackground = createBackground(selectedTrackerSettingsBackdrop,"eventBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	eventBackground:SetHidden(true)

	createTexture(eventBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(eventBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"EVENT",1,1,"BOLD_FONT",26)
	createTexture(eventBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	


	local arg1Editbox = createEditbox(eventBackground,"arg1Editbox",50,30,270,120,TOPLEFT,TOPLEFT,function(editbox)
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.events[CSE].arguments.cooldown = editbox:GetText() 
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end

	end,CST.events[CSE].arguments.cooldown,TEXT_TYPE_NUMERIC)
	createLabel(arg1Editbox,"label",60,30,0,0,BOTTOMLEFT,TOPLEFT,"Cooldown",0)

	local onlyYourCastCheckbox = createCheckbox(eventBackground,"onlyYourCastCheckbox", 30,30,60,170,TOPLEFT,TOPLEFT,CST.events[CSE].arguments.onlyYourCast,function(arg) 
	if CSC ~= "none" then
		CST.events[CSE].arguments.onlyYourCast = arg
	end
	end)
	createLabel(onlyYourCastCheckbox,"label",120,30,0,0,LEFT,RIGHT,"Only your cast",0)

	local overwriteShortedDurationCheckbox = createCheckbox(eventBackground,"overwriteShortedDurationCheckbox", 30,30,60,200,TOPLEFT,TOPLEFT,CST.events[CSE].arguments.overwriteShorterDuration,function(arg) 
	if CSC ~= "none" then
		CST.events[CSE].arguments.overwriteShorterDuration = arg
	end
	end)
	createLabel(overwriteShortedDurationCheckbox,"label",400,30,0,0,LEFT,RIGHT,"Don't overwrite effects when shorter duration is applied",0)

	local dropdown2 = createDropdown(eventBackground,"dropdown2",200,30,50,120,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),CST.events[CSE].type,function(selection)
	if CST.name ~= "none" then
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.events[CSE].type = selection
		if selection == "Get Effect Cooldown" then
			arg1Editbox:SetHidden(false)
			arg1Editbox:SetText(CST.events[CSE].arguments.cooldown)
			overwriteShortedDurationCheckbox:SetHidden(true)
		elseif selection == "Get Effect Duration" then
			onlyYourCastCheckbox:Update(CST.events[CSE].arguments.onlyYourCast)
			overwriteShortedDurationCheckbox:SetHidden(false)
			overwriteShortedDurationCheckbox:Update(CST.events[CSE].arguments.overwriteShorterDuration)
			arg1Editbox:SetHidden(true)
		end
		if CST.parent ~= "HT_Trackers" and getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(getTrackerFromName(CST.parent,HTSV.trackers)):Update(getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end
	
	
	
	
	
	
	end)
	

	local dropdown = createDropdown(eventBackground,"dropdown",200,30,50,70,TOPLEFT,TOPLEFT,getKeysFromTable(CST.events),CSE,function(selection) 
	
	CSE = selection 
	if CST.events[CSE].type == "Get Effect Cooldown" then
		arg1Editbox:SetHidden(false)
		arg1Editbox:SetText(CST.events[CSE].arguments.cooldown)
	else
		arg1Editbox:SetHidden(true)
	end
	dropdown2.selection = CST.events[CSE].type
	dropdown2:updateDropdown()


	
	end)

	--[[
	createButton(eventBackground,"button",30,30,10,70,TOPLEFT,TOPLEFT,function() 
		table.insert(CST.events,{
		type = "Get Effect Duration",
		arguments.cooldown = 0
		})
		dropdown.choices = getKeysFromTable(CST.events)
		dropdown:updateDropdown()
		relocateLeftSide()
	end,nil,"esoui/art/buttons/plus_up.dds",nil)]]
	--------- EVENTS -------------



	------ BACKGROUND ON THE RIGHT WHERE U CHANGE SETTINGS OF SELECTED TRACKERS ----------------


	relocateLeftSide()
	

	HT_Settings:ClearAnchors()
	HT_Settings:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,0,0)
	SCENE_MANAGER:GetScene("hud"):RegisterCallback("StateChange", onSceneChange)
	SCENE_MANAGER:GetScene("hudui"):RegisterCallback("StateChange", onSceneChange)
end

