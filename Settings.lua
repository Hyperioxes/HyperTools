local WM = GetWindowManager()


local roleToId = {
	["Damage Dealer"] = 1,
	["Tank"] = 2,
	["Healer"] = 4,
}

local IdToRole = {
	[1] = "Damage Dealer",
	[2] = "Tank",
	[4] = "Healer",
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







local function getKeysFromTable(varTable)
	local holder = {}
	for k,v in pairs(varTable) do
		table.insert(holder,k)
	end
	return holder
end

local function hideUI()
	HT_Settings:SetHidden(true)
end
local function showUI()
	HT_Settings:SetHidden(false)
end
SLASH_COMMANDS["/hthide"] = hideUI
SLASH_COMMANDS["/htshow"] = showUI



local CST = "none" -- Currently Selected Tracker
local CSE = 1 -- Currently Selected Event
local CSC = 1 -- Currently Selected Condition
local CTC = "HT_Trackers" -- Current Top Control
local CMT = nil -- Currently Moved Tracker


local rightSideBackground = {
	[0] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("newTrackersBackdrop"):SetHidden(false) end,
	[1] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):SetHidden(false) end,
	[2] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newProgressBarBackdrop"):SetHidden(false) end,
	[3] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newIconTrackerBackdrop"):SetHidden(false) end,
	[4] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newGroupTrackerBackdrop"):SetHidden(false) end,
	[5] = function()HT_Settings:GetNamedChild("background"):GetNamedChild("newGroupMemberTrackerBackdrop"):SetHidden(false) end,
}

local function selectRightSideBackground(number)
	local background = HT_Settings:GetNamedChild("background")
	local newTrackersBackdrop = background:GetNamedChild("newTrackersBackdrop")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local newIconTrackerBackdrop = background:GetNamedChild("newIconTrackerBackdrop")
	local newProgressBarBackdrop = background:GetNamedChild("newProgressBarBackdrop")
	local newGroupTrackerBackdrop = background:GetNamedChild("newGroupTrackerBackdrop")
	local newGroupMemberTrackerBackdrop = background:GetNamedChild("newGroupMemberTrackerBackdrop")
	newTrackersBackdrop:SetHidden(true)
	selectedTrackerSettingsBackdrop:SetHidden(true)
	newProgressBarBackdrop:SetHidden(true)
	newIconTrackerBackdrop:SetHidden(true)
	newGroupTrackerBackdrop:SetHidden(true)
	newGroupMemberTrackerBackdrop:SetHidden(true)
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
		if HTSV.trackers[CST].type == "Resource Bar" then
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
		if HTSV.trackers[CST].type == "Resource Bar" then
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
	texturePath:SetText(HTSV.trackers[CST].icon)
	dropdownIDs.choices = HTSV.trackers[CST].IDs
	dropdownIDs.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs,0)
	dropdownIDs:updateDropdown()
	dropdownFonts.selection = HTSV.trackers[CST].font
	dropdownFonts:updateDropdown()
	fontWeightDropdown.selection = HTSV.trackers[CST].fontWeight
	fontWeightDropdown:updateDropdown()
	dropdownFontsSize.selection = HTSV.trackers[CST].fontSize
	dropdownFontsSize:updateDropdown()
	decimalsDropdown.selection = HTSV.trackers[CST].decimals
	decimalsDropdown:updateDropdown()
	text:SetText(HTSV.trackers[CST].text)
	height:SetText(math.floor(HTSV.trackers[CST].sizeX))
	width:SetText(math.floor(HTSV.trackers[CST].sizeY))
	colorpicker:SetColor(unpack(HTSV.trackers[CST].barColor))
	colorpicker2:SetColor(unpack(HTSV.trackers[CST].outlineColor))
	colorpicker3:SetColor(unpack(HTSV.trackers[CST].backgroundColor))
	TextPosXEditbox:SetText(math.floor(HTSV.trackers[CST].xOffset))
	cstYposEditbox:SetText(math.floor(HTSV.trackers[CST].yOffset))
	outlineThicknessDropdown.selection = HTSV.trackers[CST].outlineThickness
	outlineThicknessDropdown:updateDropdown()
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
	dropdownFonts.selection = HTSV.trackers[CST].font
	dropdownFonts:updateDropdown()
	dropdownFontsSize.selection = HTSV.trackers[CST].fontSize
	dropdownFontsSize:updateDropdown()
	text.selection = HTSV.trackers[CST].text
	text:updateDropdown()
	textAlignmentDropdown.selection = HTSV.trackers[CST].textAlignment
	textAlignmentDropdown:updateDropdown()
	height:SetText(math.floor(HTSV.trackers[CST].sizeX))
	width:SetText(math.floor(HTSV.trackers[CST].sizeY))
	colorpicker:SetColor(unpack(HTSV.trackers[CST].barColor))
	colorpicker2:SetColor(unpack(HTSV.trackers[CST].outlineColor))
	colorpicker3:SetColor(unpack(HTSV.trackers[CST].backgroundColor))
	TextPosXEditbox:SetText(math.floor(HTSV.trackers[CST].xOffset))
	cstYposEditbox:SetText(math.floor(HTSV.trackers[CST].yOffset))
end



local function updateGeneralBackground()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local generalBackground = selectedTrackerSettingsBackdrop:GetNamedChild("generalBackground")
	local name = generalBackground:GetNamedChild("NameEditbox")
	local targetDropdown = generalBackground:GetNamedChild("TargetDropdown")
	local IDsDropdown = generalBackground:GetNamedChild("IDs dropdown")
	local TargetNumberDropdown = generalBackground:GetNamedChild("TargetNumberDropdown")
	name:SetText(HTSV.trackers[CST].name)

	if HTSV.trackers[CST].type == "Group Member" or (HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member") then
		targetDropdown:SetHidden(true)
		TargetNumberDropdown:SetHidden(true)
	else
		targetDropdown:SetHidden(false)
		targetDropdown.selection = HTSV.trackers[CST].target
		targetDropdown:updateDropdown()
		if HTSV.trackers[CST].target == "Yourself" or HTSV.trackers[CST].target == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[HTSV.trackers[CST].target] or {1}
			TargetNumberDropdown.selection = HTSV.trackers[CST].targetNumber
			TargetNumberDropdown:updateDropdown()
		end
	end

	



	IDsDropdown.choices = HTSV.trackers[CST].IDs
	IDsDropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs)
	IDsDropdown:updateDropdown()
	
end

local function updateGeneralBackgroundResources()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local generalBackgroundResource = selectedTrackerSettingsBackdrop:GetNamedChild("generalBackgroundResource")
	local name = generalBackgroundResource:GetNamedChild("NameEditbox")
	local IDsDropdown = generalBackgroundResource:GetNamedChild("IDs dropdown")

	name:SetText(HTSV.trackers[CST].name)
	IDsDropdown.selection = resourcesReverse[HTSV.trackers[CST].IDs[1]]
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
	topDropdown.choices = getKeysFromTable(HTSV.trackers[CST].conditions)
	topDropdown.selection = HT_pickAnyKey(HTSV.trackers[CST].conditions)
	topDropdown:updateDropdown()
	if CSC == "none" then
		arg1Dropdown.selection = "none"
		arg1Dropdown:updateDropdown()
		operatorDropdown.selection = "none"
		operatorDropdown:updateDropdown()
		arg2Editbox:SetText("")
		resultDropdown.selection = "none"
		resultDropdown:updateDropdown()
		resultColorpicker:SetColor(1,1,1,1)
	else
		arg1Dropdown.selection = HTSV.trackers[CST].conditions[CSC].arg1
		arg1Dropdown:updateDropdown()
		operatorDropdown.selection = HTSV.trackers[CST].conditions[CSC].operator
		operatorDropdown:updateDropdown()
		arg2Editbox:SetText(HTSV.trackers[CST].conditions[CSC].arg2)
		resultDropdown.selection = HTSV.trackers[CST].conditions[CSC].result
		resultDropdown:updateDropdown()
		resultColorpicker:SetColor(unpack(HTSV.trackers[CST].conditions[CSC].resultArguments))
	end
end

local function updateEventBackground()
	local background = HT_Settings:GetNamedChild("background")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local eventBackground = selectedTrackerSettingsBackdrop:GetNamedChild("eventBackground")
	local eventDropdown = eventBackground:GetNamedChild("dropdown")
	local eventTypeDropdown = eventBackground:GetNamedChild("dropdown2")
	eventDropdown.choices = getKeysFromTable(HTSV.trackers[CST].events)
	eventDropdown.selection = HT_pickAnyKey(HTSV.trackers[CST].events)
	eventDropdown:updateDropdown()
	eventTypeDropdown.selection = HTSV.trackers[CST].events[CSE].type
	eventTypeDropdown:updateDropdown()
	
end


local function createLeftSidePanelButton(parent,counter,t)
	if t.name ~= "none" then
		local button = createButton(parent,"button"..t.name,200,50,0,50*counter,TOPLEFT,TOPLEFT,function(ctrl,alt,shift) 
			if (t.type == "Group" or t.type == "Group Member") and ctrl and t.name ~= CST then
				HT_findContainer(HTSV.trackers[CST]):Delete()
				HTSV.trackers[CST].xOffset = HTSV.trackers[CST].xOffset - t.xOffset
				HTSV.trackers[CST].yOffset = HTSV.trackers[CST].yOffset - t.yOffset
				if HTSV.trackers[CST].parent ~= "HT_Trackers" then
					removeElementFromTable(HTSV.trackers[HTSV.trackers[CST].parent].children,HTSV.trackers[CST].name)
				end
				HTSV.trackers[CST].parent = t.name
				table.insert(t.children,HTSV.trackers[CST].name) 
				--if not HT_findContainer(HTSV.trackers[CST]) then 
					--initializeTrackerFunctions[HTSV.trackers[CST].type](HT_findContainer(t),HTSV.trackers[CST])
				--end
			elseif t.type ~= "Group" and shift then
				local newName = HT_generateNewNate(t.name,1)
				HTSV.trackers[newName] = HT_deepcopy(t)
				HTSV.trackers[newName].name = newName
				HTSV.trackers[newName].children = {}
				if HTSV.trackers[newName].parent ~= "HT_Trackers" then
					table.insert(HTSV.trackers[t.parent].children,newName)
					initializeTrackerFunctions[HTSV.trackers[newName].type](HT_findContainer(HTSV.trackers[newName].parent),HTSV.trackers[newName])
				else
					initializeTrackerFunctions[HTSV.trackers[newName].type](HT_Trackers,HTSV.trackers[newName])
				end
				HT_registerEvents()
			end
			
			selectRightSideBackground(1)
			CST = t.name 
			CSC = HT_pickAnyKey(t.conditions)
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
			
			HTSV.trackers[t.name] = nil
			if not HTSV.trackers[CST] then
				CST = HT_pickAnyKey(HTSV.trackers)
				CSC = HT_pickAnyKey(HTSV.trackers[CST].conditions)
			end
			if t.parent ~= "HT_Trackers" then
				removeElementFromTable(HTSV.trackers[t.parent].children,t.name)
			end

			if t.parent ~= "HT_Trackers" and HTSV.trackers[t.parent].type == "Group Member" then 
				for i=1,12 do
					HT_findContainer(t,i):Delete() 
				end
			else 
				HT_findContainer(t):Delete() 
			end
			button:SetHidden(true)
			if CST == t.name then
				CST = HT_pickAnyKey(HTSV.trackers)
				CSC = HT_pickAnyKey(HTSV.trackers[CST].conditions)
			end
			relocateLeftSide()
			updateDisplayBackground()
			updateDisplayBackgroundResource()
			updateGeneralBackground()
			updateGeneralBackgroundResources()
			updateConditionBackground()
			updateEventBackground()
		end,nil,"/esoui/art/buttons/decline_up.dds",true)
		
		local moveButton = createButton(button,"moveButton",23,23,-23,2,TOPRIGHT,TOPRIGHT,function()
			removeElementFromTable(HTSV.trackers[t.parent].children,t.name)
			t.parent = HTSV.trackers[t.parent].parent
			if t.parent ~= "HT_Trackers" then
				table.insert(HTSV.trackers[HTSV.trackers[t.parent].parent].children,t.name)
			end
			if HT_findContainer(t) then HT_findContainer(t):SetHidden(true) end
			button:SetHidden(true)
			relocateLeftSide()
			updateDisplayBackground()
			updateDisplayBackgroundResource()
			updateGeneralBackground()
			updateGeneralBackgroundResources()
			updateConditionBackground()
			updateEventBackground()
		end,nil,"/esoui/art/buttons/scrollbox_uparrow_up.dds",true)
		if t.parent == "HT_Trackers" then
			moveButton:SetHidden(true)
		end
		if t.type == "Group" or t.type == "Group Member" then
			local goInsideButton = createButton(button,"goInsideButton",23,23,-2,-2,BOTTOMRIGHT,BOTTOMRIGHT,function()
				CTC = t.name
				relocateLeftSide()
				updateDisplayBackground()
				updateDisplayBackgroundResource()
				updateGeneralBackground()
				updateGeneralBackgroundResources()
				updateConditionBackground()
				updateEventBackground()
			end,nil,"/esoui/art/buttons/scrollbox_downarrow_up.dds",true)
		end
		local icon = createTexture(button,"icon",50,50,1,1,TOPLEFT,TOPLEFT,t.icon,4)
		local text = createLabel(icon,"text",125,25,0,0,TOPLEFT,TOPRIGHT,t.name,1,1)
		local type = createLabel(icon,"type",125,25,0,0,BOTTOMLEFT,BOTTOMRIGHT,t.type,1,1)
	end
end



function updateLeftSide()
	local background = HT_Settings:GetNamedChild("background")
	local eTB = background:GetNamedChild("eTB")
	local counter = 2
	for i,v in pairs(HTSV.trackers) do
		if not eTB:GetNamedChild("button"..v.name) then
			createLeftSidePanelButton(eTB,counter,v)
		else
			local button = eTB:GetNamedChild("button"..v.name)
			local icon = button:GetNamedChild("icon")
			local text = icon:GetNamedChild("text")
			text:SetText(i)
			icon:SetTexture(v.icon)
		end
		counter = counter + 1
	end
end

function relocateLeftSide()
	local background = HT_Settings:GetNamedChild("background")
	local eTB = background:GetNamedChild("eTB")
	local counter = 2
	local button2 = eTB:GetNamedChild("button2")

	if CTC == "HT_Trackers" then
		button2:SetHidden(true)
	else
		button2:SetHidden(false)
	end
	for i,v in pairs(HTSV.trackers) do
		if i ~= "none" then
			local button = eTB:GetNamedChild("button"..v.name)
			if button then
				button:SetHidden(true)
			end
		end
	end
	for i,v in pairs(HTSV.trackers) do
		if v.parent == CTC then
			if not eTB:GetNamedChild("button"..v.name) then
				createLeftSidePanelButton(eTB,counter,v)
			else
				local button = eTB:GetNamedChild("button"..v.name)
				local moveButton = button:GetNamedChild("moveButton")
				button:ClearAnchors()
				button:SetAnchor(TOPLEFT,eTB,TOPLEFT,0,50*counter)
				local icon = button:GetNamedChild("icon")
				local text = icon:GetNamedChild("text")
				text:SetText(i)
				icon:SetTexture(v.icon)
				button:SetHidden(false)
				if CST == v.name then
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
			counter = counter + 1
		end
	end
end




local function createNewTracker(type,name,text,IDs,sizeX,sizeY,color)
	HTSV.trackers[name] = {
	type = type,
	name = name,
	text = text,
	textAlignment = 1,
	font = "BOLD_FONT",
	fontSize = 30,
	fontWeight = "thick-outline",
	IDs = IDs,
	target = "Yourself",
	outlineThickness = 4,
	current = 0,
	decimals = 1,
	max = 0,
	targetNumber = 1,
	hideIcon = false,
	icon = GetAbilityIcon(HT_pickAnyElement(IDs) or 0) or "",
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
	xOffset = 500,
	yOffset = 500,
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
		type = "Update Effect Duration from Event"
		},
	},
	load = {
		never = false,
		inCombat = false,
		role = 2,
		class = "Dragonknight",
		skills = {},
		itemSets = {},
		zones = {},
	},
	}
	initializeTrackerFunctions[type](HT_Trackers,HTSV.trackers[name])
end







function HT_Settings_initializeUI()

	local HT_Settings = WM:CreateTopLevelWindow("HT_Settings")
	HT_Settings:SetResizeToFitDescendents(true)
    HT_Settings:SetMovable(true)
    HT_Settings:SetMouseEnabled(true)
	HT_Settings:SetHidden(false)

	

	local background = createBackground(HT_Settings,"background",800,825,0,0,TOPLEFT,TOPLEFT)

	------ BACKGROUND ON THE LEFT WITH ALL EXISTING TRACKERS ----------------
	local eTB = createBackground(background,"eTB",200,775,25,25,TOPLEFT,TOPLEFT) -- existing trackers background
	
	local button = createButton(eTB,"button",200,50,0,0,TOPLEFT,TOPLEFT,function() 
		selectRightSideBackground(0)
		updateLeftSide() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
	end,nil,nil,true)
	local buttonIcon = createTexture(eTB,"buttonIcon",50,50,0,0,TOPLEFT,TOPLEFT,"HyperTankingTools/icons/plusIcon.dds",2)
	local text = createLabel(buttonIcon,"text",150,50,0,0,LEFT,RIGHT,"Create new",1,1)
	local button2 = createButton(eTB,"button2",200,50,0,50,TOPLEFT,TOPLEFT,function() 
		CTC = HTSV.trackers[CTC].parent
		relocateLeftSide() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
	end,"Return",nil,true)
	button2:SetHidden(true)
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
	}
	local iconsByNumber = {
		[2] = "HyperTankingTools/icons/progressBarIcon.dds",
		[3] = "HyperTankingTools/icons/iconTrackerIcon.dds",
		[4] = "",
		[5] = "",
	}
	local newTrackersBackdrop = createBackground(background,"newTrackersBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newTrackersBackdrop:SetHidden(false)
	for i=2, 5 do
		local icon = createTexture(newTrackersBackdrop,"icon"..i,100,100,0,100*(i-2),TOPLEFT,TOPLEFT,iconsByNumber[i],2)
		local button = createButton(icon,"button"..i,425,100,0,0,TOPLEFT,TOPRIGHT,function() selectRightSideBackground(i) updateLeftSide() updateDisplayBackground() updateDisplayBackgroundResource() end,typesByNumber[i],nil,true)
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
	createLabel(newProgressBarBackdrop,"IDs",180,30,15,120,TOPLEFT,TOPLEFT,"IDs",0,1)
	local dropdown = createDropdown(newProgressBarBackdrop,"dropdown",200,30,15,145,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)
	createLabel(newProgressBarBackdrop,"addIdlabel",150,30,250,125,TOPLEFT,TOPLEFT,"Add ID",0,1)
	local addIDEditbox = createEditbox(newProgressBarBackdrop,"addIdEditbox",200,30,250,150,TOPLEFT,TOPLEFT,function(editbox)
		
	end)
	createButton(newProgressBarBackdrop,"button1",200,30,15,205,TOPLEFT,TOPLEFT,function() 
		removeElementFromTable(dropdown.choices,dropdown.selection)
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs)
		dropdown:updateDropdown()
	end,"Delete ID",nil,true)
	createButton(newProgressBarBackdrop,"button",200,30,250,205,TOPLEFT,TOPLEFT,function() 
		table.insert(dropdown.choices,(tonumber(addIDEditbox:GetText()) or GetAbilityIdFromName(addIDEditbox:GetText())))
		dropdown.selection = HT_pickAnyElement(dropdown.choices)
		dropdown:updateDropdown()
	end,"Add ID",nil,true)
	createLabel(newProgressBarBackdrop,"targetLabel",150,30,250,60,TOPLEFT,TOPLEFT,"Target",0,1)
	createDropdown(newProgressBarBackdrop,"targetDropdown",200,30,250,85,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),HTSV.trackers[CST].target,function(selection)
		
	end)
	
	createLabel(newProgressBarBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newProgressBarBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,HTSV.trackers[CST].barColor,function(color) 
		
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
		createNewTracker("Progress Bar",nameEditbox:GetText(),textEditbox:GetText(),dropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		HT_registerEvents()
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
	createLabel(newIconTrackerBackdrop,"IDs",180,30,15,120,TOPLEFT,TOPLEFT,"IDs",0,1)
	local dropdown = createDropdown(newIconTrackerBackdrop,"dropdown",200,30,15,145,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)
	createLabel(newIconTrackerBackdrop,"addIdlabel",150,30,250,125,TOPLEFT,TOPLEFT,"Add ID",0,1)
	local addIDEditbox = createEditbox(newIconTrackerBackdrop,"addIdEditbox",200,30,250,150,TOPLEFT,TOPLEFT,function(editbox)
		
	end)
	createButton(newIconTrackerBackdrop,"button1",200,30,15,205,TOPLEFT,TOPLEFT,function() 
		removeElementFromTable(dropdown.choices,dropdown.selection)
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs)
		dropdown:updateDropdown()
	end,"Delete ID",nil,true)
	createButton(newIconTrackerBackdrop,"button",200,30,250,205,TOPLEFT,TOPLEFT,function() 
		table.insert(dropdown.choices,(tonumber(addIDEditbox:GetText()) or GetAbilityIdFromName(addIDEditbox:GetText())))
		dropdown.selection = HT_pickAnyElement(dropdown.choices)
		dropdown:updateDropdown()
	end,"Add ID",nil,true)
	createLabel(newIconTrackerBackdrop,"targetLabel",150,30,250,60,TOPLEFT,TOPLEFT,"Target",0,1)
	createDropdown(newIconTrackerBackdrop,"targetDropdown",200,30,250,85,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),HTSV.trackers[CST].target,function(selection)
		
	end)
	
	createLabel(newIconTrackerBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newIconTrackerBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,HTSV.trackers[CST].barColor,function(color) 
		
	end)
	createTexture(newIconTrackerBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	
	createLabel(newIconTrackerBackdrop,"TextSizeX",150,30,15,440,TOPLEFT,TOPLEFT,"Width",0)
	local widthEditbox = createEditbox(newIconTrackerBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(editbox)

	end,210)
	createLabel(newIconTrackerBackdrop,"TextSizeY",150,30,250,440,TOPLEFT,TOPLEFT,"Height",0)
	local heightEditbox = createEditbox(newIconTrackerBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(editbox)

	end,30)

	createLabel(newIconTrackerBackdrop,"textLabel",150,30,250,500,TOPLEFT,TOPLEFT,"Text",0,1)
	local textEditbox = createEditbox(newIconTrackerBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(editbox)
		
	end)

	local buttonCreateTracker = createButton(newIconTrackerBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		createNewTracker("Icon Tracker",nameEditbox:GetText(),textEditbox:GetText(),dropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		HT_registerEvents()
	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (ICON TRACKER) ----------------

	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP MEMBER) ----------------
	local newGroupMemberTrackerBackdrop = createBackground(background,"newGroupMemberTrackerBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newGroupMemberTrackerBackdrop:SetHidden(true)
	createTexture(newGroupMemberTrackerBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupMemberTrackerBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newGroupMemberTrackerBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupMemberTrackerBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)
	local nameEditbox = createEditbox(newGroupMemberTrackerBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(editbox)

	end)
	createLabel(newGroupMemberTrackerBackdrop,"IDs",180,30,15,120,TOPLEFT,TOPLEFT,"IDs",0,1)
	local dropdown = createDropdown(newGroupMemberTrackerBackdrop,"dropdown",200,30,15,145,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)
	createLabel(newGroupMemberTrackerBackdrop,"addIdlabel",150,30,250,125,TOPLEFT,TOPLEFT,"Add ID",0,1)
	local addIDEditbox = createEditbox(newGroupMemberTrackerBackdrop,"addIdEditbox",200,30,250,150,TOPLEFT,TOPLEFT,function(editbox)
		
	end)
	createButton(newGroupMemberTrackerBackdrop,"button1",200,30,15,205,TOPLEFT,TOPLEFT,function() 
		removeElementFromTable(dropdown.choices,dropdown.selection)
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs)
		dropdown:updateDropdown()
	end,"Delete ID",nil,true)
	createButton(newGroupMemberTrackerBackdrop,"button",200,30,250,205,TOPLEFT,TOPLEFT,function() 
		table.insert(dropdown.choices,(tonumber(addIDEditbox:GetText()) or GetAbilityIdFromName(addIDEditbox:GetText())))
		dropdown.selection = HT_pickAnyElement(dropdown.choices)
		dropdown:updateDropdown()
	end,"Add ID",nil,true)
	createLabel(newGroupMemberTrackerBackdrop,"targetLabel",150,30,250,60,TOPLEFT,TOPLEFT,"Target",0,1)
	createDropdown(newGroupMemberTrackerBackdrop,"targetDropdown",200,30,250,85,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),HTSV.trackers[CST].target,function(selection)
		
	end)
	
	createLabel(newGroupMemberTrackerBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newGroupMemberTrackerBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,HTSV.trackers[CST].barColor,function(color) 
		HTSV.trackers[CST].barColor = color
	end)
	createTexture(newGroupMemberTrackerBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	
	createLabel(newGroupMemberTrackerBackdrop,"TextSizeX",150,30,15,440,TOPLEFT,TOPLEFT,"Width",0)
	local widthEditbox = createEditbox(newGroupMemberTrackerBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(editbox)

	end,210)
	createLabel(newGroupMemberTrackerBackdrop,"TextSizeY",150,30,250,440,TOPLEFT,TOPLEFT,"Height",0)
	local heightEditbox = createEditbox(newGroupMemberTrackerBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(editbox)

	end,30)

	createLabel(newGroupMemberTrackerBackdrop,"textLabel",150,30,250,500,TOPLEFT,TOPLEFT,"Text",0,1)
	local textEditbox = createEditbox(newGroupMemberTrackerBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(editbox)
		
	end)

	local buttonCreateTracker = createButton(newGroupMemberTrackerBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		createNewTracker("Group Member",nameEditbox:GetText(),textEditbox:GetText(),dropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		HT_registerEvents()
	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP) ----------------


	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP) ----------------
	local newGroupTrackerBackdrop = createBackground(background,"newGroupTrackerBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newGroupTrackerBackdrop:SetHidden(true)
	createTexture(newGroupTrackerBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupTrackerBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newGroupTrackerBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newGroupTrackerBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)
	local nameEditbox = createEditbox(newGroupTrackerBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(editbox)

	end)
	createLabel(newGroupTrackerBackdrop,"IDs",180,30,15,120,TOPLEFT,TOPLEFT,"IDs",0,1)
	local dropdown = createDropdown(newGroupTrackerBackdrop,"dropdown",200,30,15,145,TOPLEFT,TOPLEFT,{},nil,function(selection)

	end)
	createLabel(newGroupTrackerBackdrop,"addIdlabel",150,30,250,125,TOPLEFT,TOPLEFT,"Add ID",0,1)
	local addIDEditbox = createEditbox(newGroupTrackerBackdrop,"addIdEditbox",200,30,250,150,TOPLEFT,TOPLEFT,function(editbox)
		
	end)
	createButton(newGroupTrackerBackdrop,"button1",200,30,15,205,TOPLEFT,TOPLEFT,function() 
		removeElementFromTable(dropdown.choices,dropdown.selection)
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs)
		dropdown:updateDropdown()
	end,"Delete ID",nil,true)
	createButton(newGroupTrackerBackdrop,"button",200,30,250,205,TOPLEFT,TOPLEFT,function() 
		table.insert(dropdown.choices,(tonumber(addIDEditbox:GetText()) or GetAbilityIdFromName(addIDEditbox:GetText())))
		dropdown.selection = HT_pickAnyElement(dropdown.choices)
		dropdown:updateDropdown()
	end,"Add ID",nil,true)
	createLabel(newGroupTrackerBackdrop,"targetLabel",150,30,250,60,TOPLEFT,TOPLEFT,"Target",0,1)
	createDropdown(newGroupTrackerBackdrop,"targetDropdown",200,30,250,85,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),HTSV.trackers[CST].target,function(selection)
		
	end)
	
	createLabel(newGroupTrackerBackdrop,"colorpickerText",150,30,15,500,TOPLEFT,TOPLEFT,"Color",0,1)
	local colorpicker = createColorpicker(newGroupTrackerBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,HTSV.trackers[CST].barColor,function(color) 
		HTSV.trackers[CST].barColor = color
	end)
	createTexture(newGroupTrackerBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	
	createLabel(newGroupTrackerBackdrop,"TextSizeX",150,30,15,440,TOPLEFT,TOPLEFT,"Width",0)
	local widthEditbox = createEditbox(newGroupTrackerBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(editbox)

	end,210)
	createLabel(newGroupTrackerBackdrop,"TextSizeY",150,30,250,440,TOPLEFT,TOPLEFT,"Height",0)
	local heightEditbox = createEditbox(newGroupTrackerBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(editbox)

	end,30)

	createLabel(newGroupTrackerBackdrop,"textLabel",150,30,250,500,TOPLEFT,TOPLEFT,"Text",0,1)
	local textEditbox = createEditbox(newGroupTrackerBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(editbox)
		
	end)

	local buttonCreateTracker = createButton(newGroupTrackerBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function() 
		createNewTracker("Group",nameEditbox:GetText(),textEditbox:GetText(),dropdown.choices,tonumber(widthEditbox:GetText()),tonumber(heightEditbox:GetText()),colorpicker.color)
		relocateLeftSide()   
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		updateGeneralBackground()
		updateGeneralBackgroundResources()
		updateConditionBackground()
		updateEventBackground()
		HT_registerEvents()
	end,"Create",nil,true)
	------ BACKGROUND ON THE RIGHT WHERE U CREATE NEW TRACKERS (GROUP) ----------------





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
		HTSV.trackers[CST].icon = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end,HTSV.trackers[CST].icon)
	createLabel(displayBackground,"autoTextureDropdownLabel",180,30,15,120,TOPLEFT,TOPLEFT,"Set automatic texture from ID",0,1)
	local autoTextureDropdown = createDropdown(displayBackground,"autoTextureDropdown",200,30,15,145,TOPLEFT,TOPLEFT,HTSV.trackers[CST].IDs,HT_pickAnyElement(HTSV.trackers[CST].IDs,0),function(selection)
		
	end)
	createButton(displayBackground,"button",200,30,250,145,TOPLEFT,TOPLEFT,function() 
		HTSV.trackers[CST].icon = GetAbilityIcon(autoTextureDropdown.selection or 0)
		editbox:SetText(GetAbilityIcon(autoTextureDropdown.selection or 0))
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end,"Auto-set texture",nil,true)
	createLabel(displayBackground,"fontLabel",90,30,15,180,TOPLEFT,TOPLEFT,"Font",0,1)
	createDropdown(displayBackground,"fontDropdown",90,30,15,205,TOPLEFT,TOPLEFT,fonts,HTSV.trackers[CST].font,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].font = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then
					HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent])
			else
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)
	createLabel(displayBackground,"fontWeightLabel",60,30,105,180,TOPLEFT,TOPLEFT,"Weight",0,1)
	createDropdown(displayBackground,"fontWeightDropdown",60,30,105,205,TOPLEFT,TOPLEFT,fontWeights,HTSV.trackers[CST].fontWeight,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].fontWeight = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackground,"fontSizeLabel",50,30,160,180,TOPLEFT,TOPLEFT,"Size",0,1)
	createDropdown(displayBackground,"fontSizeDropdown",50,30,160,205,TOPLEFT,TOPLEFT,fontSizes,HTSV.trackers[CST].fontSize,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].fontSize = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackground,"textLabel",150,30,250,180,TOPLEFT,TOPLEFT,"Text",0,1)
	createEditbox(displayBackground,"textEditbox",200,30,250,205,TOPLEFT,TOPLEFT,function(editbox)
		HTSV.trackers[CST].text = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end,HTSV.trackers[CST].text)
	createLabel(displayBackground,"colorpickerText",70,30,15,250,TOPLEFT,TOPLEFT,"Bar",0,1)
	createColorpicker(displayBackground,"colorpickerRegular",70,30,15,275,TOPLEFT,TOPLEFT,HTSV.trackers[CST].barColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].barColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)


	createLabel(displayBackground,"colorpickerText2",70,30,100,250,TOPLEFT,TOPLEFT,"Outline",0,1)
	createColorpicker(displayBackground,"colorpicker2",70,30,100,275,TOPLEFT,TOPLEFT,HTSV.trackers[CST].outlineColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].outlineColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)
	createLabel(displayBackground,"colorpickerText3",70,30,185,250,TOPLEFT,TOPLEFT,"Background",0,1)
	createColorpicker(displayBackground,"colorpicker3",70,30,185,275,TOPLEFT,TOPLEFT,HTSV.trackers[CST].backgroundColor,function(color) 
		if type(color) == "table" then
			HTSV.trackers[CST].backgroundColor = color 
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)

	createLabel(displayBackground,"colorpickerLabelLabel",70,30,15,315,TOPLEFT,TOPLEFT,"Text",0,1)
	createColorpicker(displayBackground,"colorpickerLabelColorpicker",70,30,15,340,TOPLEFT,TOPLEFT,HTSV.trackers[CST].textColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].textColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)

	createLabel(displayBackground,"colorpickerTimeLabel",70,30,100,315,TOPLEFT,TOPLEFT,"Time",0,1)
	createColorpicker(displayBackground,"colorpickerTimeColorpicker",70,30,100,340,TOPLEFT,TOPLEFT,HTSV.trackers[CST].timeColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].timeColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)

	createLabel(displayBackground,"colorpickerStacksLabel",70,30,185,315,TOPLEFT,TOPLEFT,"Stacks",0,1)
	createColorpicker(displayBackground,"colorpickerStacksolorpicker",70,30,185,340,TOPLEFT,TOPLEFT,HTSV.trackers[CST].stacksColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].stacksColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)


	createCheckbox(displayBackground,"inverseCheckbox", 30,30,270,250,TOPLEFT,TOPLEFT,HTSV.trackers[CST].inverse,function(arg) 
		if CST ~= "none" then
			HTSV.trackers[CST].inverse = arg
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackground,"inverseCheckboxLabel",150,30,310,250,TOPLEFT,TOPLEFT,"Inverse",0,1)


	createCheckbox(displayBackground,"RemainingTimeCheckbox", 30,30,270,290,TOPLEFT,TOPLEFT,HTSV.trackers[CST].timer1,function(arg) 
		if CST ~= "none" then
			HTSV.trackers[CST].timer1 = arg
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackground,"RemainingTimeCheckboxLabel",150,30,310,290,TOPLEFT,TOPLEFT,"Remaining Time",0,1)


	createLabel(displayBackground,"decimalsLabel",50,30,400,280,TOPLEFT,TOPLEFT,"Decimals",0,1)
	createDropdown(displayBackground,"decimalsDropdown",50,30,400,305,TOPLEFT,TOPLEFT,{0,1},HTSV.trackers[CST].decimals,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].decimals = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)


	createCheckbox(displayBackground,"StacksCheckbox", 30,30,270,330,TOPLEFT,TOPLEFT,HTSV.trackers[CST].timer2,function(arg) 
		if CST ~= "none" then
			HTSV.trackers[CST].timer2 = arg
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackground,"StacksCheckboxLabel",150,30,310,330,TOPLEFT,TOPLEFT,"Stacks",0,1)



	createTexture(displayBackground,"edge3",475,2,15,530,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackground,"TextPosX",150,30,15,540,TOPLEFT,TOPLEFT,"X position",0)
	createEditbox(displayBackground,"TextPosXEditbox",200,30,15,565,TOPLEFT,TOPLEFT,function(editbox)
		HTSV.trackers[CST].xOffset = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end,HTSV.trackers[CST].xOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackground,"TextPosY",150,30,250,540,TOPLEFT,TOPLEFT,"Y position",0)
	createEditbox(displayBackground,"cstYposEditbox",200,30,250,565,TOPLEFT,TOPLEFT,function(editbox)
		HTSV.trackers[CST].yOffset = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end,HTSV.trackers[CST].yOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackground,"TextSizeX",150,30,15,590,TOPLEFT,TOPLEFT,"Width",0)
	createEditbox(displayBackground,"cstXsizeEditbox",200,30,15,615,TOPLEFT,TOPLEFT,function(editbox)
		HTSV.trackers[CST].sizeX = editbox:GetText()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end,HTSV.trackers[CST].sizeX,TEXT_TYPE_NUMERIC)
	createLabel(displayBackground,"TextSizeY",150,30,250,590,TOPLEFT,TOPLEFT,"Height",0)
	createEditbox(displayBackground,"cstYsizeEditbox",200,30,250,615,TOPLEFT,TOPLEFT,function(editbox)
		HTSV.trackers[CST].sizeY = editbox:GetText() 
		updateDisplayBackground()
		updateDisplayBackgroundResource()
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end,HTSV.trackers[CST].sizeY,TEXT_TYPE_NUMERIC)
	createLabel(displayBackground,"outlineThicknessLabel",150,30,15,640,TOPLEFT,TOPLEFT,"Outline Thickness",0)
	
	createDropdown(displayBackground,"outlineThicknessDropdown",200,30,15,665,TOPLEFT,TOPLEFT,{0,1,2,4,8,16},HTSV.trackers[CST].outlineThickness,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].outlineThickness = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	--[[createDropdown(displayBackground,"anchorToGroupMemberDropdown",50,30,320,405,TOPLEFT,TOPLEFT,{1,2,3,4,5,6,7,8,9,10,11,12},HTSV.trackers[CST].targetNumber,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].targetNumber = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createCheckbox(displayBackground,"anchorToGroupMemberCheckbox", 30,30,270,370,TOPLEFT,TOPLEFT,HTSV.trackers[CST].anchorToGroupMember,function(arg) 
		HTSV.trackers[CST].anchorToGroupMember = arg
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
	end)
	createLabel(displayBackground,"anchorToGroupMemberCheckboxLabel",150,30,315,370,TOPLEFT,TOPLEFT,"Anchor to group member",0,1)]]

	--------- DISPLAY -------------


	--------- DISPLAY RESOURCE-------------
	local displayBackgroundResource = createBackground(selectedTrackerSettingsBackdrop,"displayBackgroundResource",525,725,0,50,TOPLEFT,TOPLEFT)

	createTexture(displayBackgroundResource,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackgroundResource,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"DISPLAY",1,1,"BOLD_FONT",26)
	createTexture(displayBackgroundResource,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")


	createLabel(displayBackgroundResource,"fontLabel",150,30,15,180,TOPLEFT,TOPLEFT,"Font",0,1)
	createDropdown(displayBackgroundResource,"fontDropdown",150,30,15,205,TOPLEFT,TOPLEFT,fonts,HTSV.trackers[CST].font,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].font = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackgroundResource,"fontSizeLabel",50,30,160,180,TOPLEFT,TOPLEFT,"Font Size",0,1)
	createDropdown(displayBackgroundResource,"fontSizeDropdown",50,30,160,205,TOPLEFT,TOPLEFT,fontSizes,HTSV.trackers[CST].fontSize,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].fontSize = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackgroundResource,"textAlignmentLabel",150,30,250,120,TOPLEFT,TOPLEFT,"Text Alignment",0,1)
	createDropdown(displayBackgroundResource,"textAlignmentDropdown",200,30,250,145,TOPLEFT,TOPLEFT,getKeysFromTable(alignments),HTSV.trackers[CST].textAlignment,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].textAlignment = alignments[selection]
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	createLabel(displayBackgroundResource,"textLabel",150,30,250,180,TOPLEFT,TOPLEFT,"Text",0,1)
	createDropdown(displayBackgroundResource,"textDropdown",200,30,250,205,TOPLEFT,TOPLEFT,getKeysFromTable(resourceTexts),HTSV.trackers[CST].text,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].text = selection
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end)
	
	createLabel(displayBackgroundResource,"colorpickerText",70,30,15,250,TOPLEFT,TOPLEFT,"Color",0,1)
	createColorpicker(displayBackgroundResource,"colorpicker",70,30,15,275,TOPLEFT,TOPLEFT,HTSV.trackers[CST].barColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].barColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)


	createLabel(displayBackgroundResource,"colorpickerText2",70,30,100,250,TOPLEFT,TOPLEFT,"Outline",0,1)
	createColorpicker(displayBackgroundResource,"colorpicker2",70,30,100,275,TOPLEFT,TOPLEFT,HTSV.trackers[CST].outlineColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].outlineColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)
	createLabel(displayBackgroundResource,"colorpickerText3",70,30,185,250,TOPLEFT,TOPLEFT,"Background",0,1)
	createColorpicker(displayBackgroundResource,"colorpicker3",70,30,185,275,TOPLEFT,TOPLEFT,HTSV.trackers[CST].backgroundColor,function(color) 
		if CST ~= "none" then
			if type(color) == "table" then
				HTSV.trackers[CST].backgroundColor = color 
				if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
			end
		end
	end)


	createTexture(displayBackgroundResource,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackgroundResource,"TextPosX",150,30,15,430,TOPLEFT,TOPLEFT,"X position",0)
	createEditbox(displayBackgroundResource,"TextPosXEditbox",200,30,15,455,TOPLEFT,TOPLEFT,function(editbox)
		if CST ~= "none" then
			HTSV.trackers[CST].xOffset = editbox:GetText() 
			updateDisplayBackgroundResource()
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end,HTSV.trackers[CST].xOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackgroundResource,"TextPosY",150,30,250,430,TOPLEFT,TOPLEFT,"Y position",0)
	createEditbox(displayBackgroundResource,"cstYposEditbox",200,30,250,455,TOPLEFT,TOPLEFT,function(editbox)
		if CST ~= "none" then
			HTSV.trackers[CST].yOffset = editbox:GetText() 
			updateDisplayBackgroundResource()
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end,HTSV.trackers[CST].yOffset,TEXT_TYPE_NUMERIC)
	createLabel(displayBackgroundResource,"TextSizeX",150,30,15,520,TOPLEFT,TOPLEFT,"Width",0)
	createEditbox(displayBackgroundResource,"cstXsizeEditbox",200,30,15,545,TOPLEFT,TOPLEFT,function(editbox)
		if CST ~= "none" then
			HTSV.trackers[CST].sizeX = editbox:GetText()
			updateDisplayBackgroundResource()
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end,HTSV.trackers[CST].sizeX,TEXT_TYPE_NUMERIC)
	createLabel(displayBackgroundResource,"TextSizeY",150,30,250,520,TOPLEFT,TOPLEFT,"Height",0)
	createEditbox(displayBackgroundResource,"cstYsizeEditbox",200,30,250,545,TOPLEFT,TOPLEFT,function(editbox)
		if CST ~= "none" then
			HTSV.trackers[CST].sizeY = editbox:GetText() 
			updateDisplayBackgroundResource()
			if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		end
	end,HTSV.trackers[CST].sizeY,TEXT_TYPE_NUMERIC)
	--------- DISPLAY RESOURCE-------------




	--------- GENERAL -------------
	local generalBackground = createBackground(selectedTrackerSettingsBackdrop,"generalBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	generalBackground:SetHidden(true)
	createTexture(generalBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"GENERAL",1,1,"BOLD_FONT",26)
	createTexture(generalBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"Name",150,30,15,50,TOPLEFT,TOPLEFT,"Name",0,1)
	local editbox = createEditbox(generalBackground,"NameEditbox",200,30,15,75,TOPLEFT,TOPLEFT,function(editbox)
		HT_unregisterEvents()
		HTSV.trackers[editbox:GetText()] = HT_deepcopy(HTSV.trackers[CST])
		HTSV.trackers[editbox:GetText()].name = editbox:GetText()
		HT_findContainer(HTSV.trackers[CST]):SetHidden(true)
		HTSV.trackers[CST] = nil
		CST = editbox:GetText()
		HT_registerEvents()
		updateLeftSide()
		if HTSV.trackers[CST].parent ~= "HT_Trackers" and HTSV.trackers[HTSV.trackers[CST].parent].type == "Group Member" then HT_findContainer(HTSV.trackers[HTSV.trackers[CST].parent]):Update(HTSV.trackers[HTSV.trackers[CST].parent]) else HT_findContainer(HTSV.trackers[CST]):Update(HTSV.trackers[CST]) end
		
	end,HTSV.trackers[CST].name)
	
	local TargetNumberDropdown = createDropdown(generalBackground,"TargetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT,getTargetNumberChoices[HTSV.trackers[CST].target] or {1},HTSV.trackers[CST].targetNumber or 1,function(selection)
		HTSV.trackers[CST].targetNumber = selection
	end)
	createLabel(TargetNumberDropdown,"TargetNumber",50,30,0,0,BOTTOMLEFT,TOPLEFT,"Number",0,1)
	
	local dropdown = createDropdown(generalBackground,"TargetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),HTSV.trackers[CST].target,function(selection)
		HTSV.trackers[CST].target = selection
		if HTSV.trackers[CST].target == "Yourself" or HTSV.trackers[CST].target == "Current Target" then
			TargetNumberDropdown:SetHidden(true)
		else
			TargetNumberDropdown:SetHidden(false)
			TargetNumberDropdown.choices = getTargetNumberChoices[HTSV.trackers[CST].target] or {1}
			TargetNumberDropdown.selection = HTSV.trackers[CST].targetNumber
			TargetNumberDropdown:updateDropdown()
		end
	end)
	createLabel(dropdown,"Target",150,30,0,0,BOTTOMLEFT,TOPLEFT,"Target",0,1)
	
	createLabel(generalBackground,"IdsLabel",175,30,15,110,TOPLEFT,TOPLEFT,"IDs",0,1)
	local dropdown = createDropdown(generalBackground,"IDs dropdown",175,32,15,165,TOPLEFT,TOPLEFT,HTSV.trackers[CST].IDs,HT_pickAnyElement(HTSV.trackers[CST].IDs),function(selection)

	end)




	local editbox = createEditbox(generalBackground,"addIdEditbox",175,30,15,135,TOPLEFT,TOPLEFT,function(editbox)

	end)

	createButton(generalBackground,"buttonDeleteID",30,30,190,165,TOPLEFT,TOPLEFT,function()
		HT_unregisterEvents()
		removeElementFromTable(HTSV.trackers[CST].IDs,dropdown.selection)
		HT_registerEvents()
		dropdown.choices = HTSV.trackers[CST].IDs
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAddID",30,30,188,135,TOPLEFT,TOPLEFT,function() 

		table.insert(HTSV.trackers[CST].IDs,(tonumber(editbox:GetText()) or GetAbilityIdFromName(editbox:GetText())))
		HT_registerEvents()
		dropdown.choices = HTSV.trackers[CST].IDs
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].IDs)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,"+",nil,nil)


	createTexture(generalBackground,"edge3",165,2,15,400,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"loadLabel",150,30,180,387.5,TOPLEFT,TOPLEFT,"LOAD",1,1,"BOLD_FONT",26)
	createTexture(generalBackground,"edge4",165,2,330,400,TOPLEFT,TOPLEFT,"")
	
	
	createCheckbox(generalBackground,"neverCheckbox", 30,30,15,440,TOPLEFT,TOPLEFT,HTSV.trackers[CST].load.never,function(arg) 
	HTSV.trackers[CST].load.never = arg
	end)
	createLabel(generalBackground,"neverCheckboxLabel",150,30,55,440,TOPLEFT,TOPLEFT,"Never",0,1)

	createCheckbox(generalBackground,"combatCheckbox", 30,30,235,440,TOPLEFT,TOPLEFT,HTSV.trackers[CST].load.inCombat,function(arg) 
	HTSV.trackers[CST].load.inCombat = arg
	end)
	createLabel(generalBackground,"combatCheckboxLabel",150,30,275,440,TOPLEFT,TOPLEFT,"In Combat",0,1)

	createLabel(generalBackground,"classLabel",150,30,15,540,TOPLEFT,TOPLEFT,"Class",0,1)
	createDropdown(generalBackground,"classDropdown",200,30,15,565,TOPLEFT,TOPLEFT,{"Any","Dragonknight","Nightblade","Sorcerer","Templar","Warden","Necromancer"},HTSV.trackers[CST].load.class,function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].load.class = selection
		end
	end)

	createLabel(generalBackground,"roleLabel",150,30,15,480,TOPLEFT,TOPLEFT,"Role",0,1)
	createDropdown(generalBackground,"roleDropdown",200,30,15,505,TOPLEFT,TOPLEFT,{"Any","Damage Dealer","Tank","Healer"},IdToRole[HTSV.trackers[CST].load.role],function(selection)
		if CST ~= "none" then
			HTSV.trackers[CST].load.role = roleToId[selection]
		end
	end)

	createLabel(generalBackground,"skillsLabel",175,30,15,600,TOPLEFT,TOPLEFT,"Skills",0,1)
	local dropdown = createDropdown(generalBackground,"skillDropdown",175,32,15,655,TOPLEFT,TOPLEFT,HTSV.trackers[CST].load.skills,HT_pickAnyElement(HTSV.trackers[CST].load.skills),function(selection)

	end)

	local editbox = createEditbox(generalBackground,"addSkillEditbox",175,30,15,625,TOPLEFT,TOPLEFT,function(editbox)

	end,nil,TEXT_TYPE_NUMERIC)

	createButton(generalBackground,"buttonDeleteSkill",30,30,190,655,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(HTSV.trackers[CST].load.skills,dropdown.selection)
		dropdown.choices = HTSV.trackers[CST].load.skills
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].load.skills)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAddSkill",30,30,188,625,TOPLEFT,TOPLEFT,function() 

		table.insert(HTSV.trackers[CST].load.skills,tonumber(editbox:GetText()))-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = HTSV.trackers[CST].load.skills
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].load.skills)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,"+",nil,nil)



	createLabel(generalBackground,"itemSetsLabel",175,30,235,600,TOPLEFT,TOPLEFT,"Item Sets",0,1)
	local dropdown = createDropdown(generalBackground,"itemSetDropdown",175,32,235,655,TOPLEFT,TOPLEFT,HTSV.trackers[CST].load.itemSets,HT_pickAnyElement(HTSV.trackers[CST].load.itemSets),function(selection)

	end)

	local editbox = createEditbox(generalBackground,"addItemSetEditbox",175,30,235,625,TOPLEFT,TOPLEFT,function(editbox)

	end)

	createButton(generalBackground,"buttonDeleteitemSet",30,30,410,655,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(HTSV.trackers[CST].load.itemSets,dropdown.selection)
		dropdown.choices = HTSV.trackers[CST].load.itemSets
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].load.itemSets)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAdditemSet",30,30,408,625,TOPLEFT,TOPLEFT,function() 

		table.insert(HTSV.trackers[CST].load.itemSets,editbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = HTSV.trackers[CST].load.itemSets
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].load.itemSets)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end,"+",nil,nil)


	createLabel(generalBackground,"zonesLabel",175,30,235,480,TOPLEFT,TOPLEFT,"Zones",0,1)
	local dropdown = createDropdown(generalBackground,"zoneDropdown",175,32,235,535,TOPLEFT,TOPLEFT,HTSV.trackers[CST].load.zones,HT_pickAnyElement(HTSV.trackers[CST].load.zones),function(selection)

	end)

	local editbox = createEditbox(generalBackground,"addzoneEditbox",175,30,235,505,TOPLEFT,TOPLEFT,function(editbox)

	end)

	createButton(generalBackground,"buttonDeletezone",30,30,410,535,TOPLEFT,TOPLEFT,function()
		removeElementFromTable(HTSV.trackers[CST].load.zones,dropdown.selection)
		dropdown.choices = HTSV.trackers[CST].load.zones
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].load.zones)
		dropdown:updateDropdown()
		updateDisplayBackground()
		updateDisplayBackgroundResource()
	end, "-",nil,nil)
	createButton(generalBackground,"buttonAddzone",30,30,408,505,TOPLEFT,TOPLEFT,function() 

		table.insert(HTSV.trackers[CST].load.zones,editbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = HTSV.trackers[CST].load.zones
		dropdown.selection = HT_pickAnyElement(HTSV.trackers[CST].load.zones)
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
		HT_unregisterEvents()
		HTSV.trackers[CST].name = editbox:GetText() 
		HT_registerEvents()
		updateLeftSide()
		trackerSettingUpdateFunction[HTSV.trackers[CST].type](CST)
	end,HTSV.trackers[CST].name)


	createLabel(generalBackgroundResource,"IdsLabel",150,30,15,140,TOPLEFT,TOPLEFT,"Resource Types",0,1)
	local dropdown = createDropdown(generalBackgroundResource,"IDs dropdown",200,30,15,165,TOPLEFT,TOPLEFT,getKeysFromTable(resources),resourcesReverse[HTSV.trackers[CST].IDs[1]],function(selection)
		HT_unregisterEvents()
		HTSV.trackers[CST].IDs = {resources[selection]}
		HT_registerEvents()
	end)





	createTexture(generalBackgroundResource,"edge3",165,2,15,400,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackgroundResource,"loadLabel",150,30,180,387.5,TOPLEFT,TOPLEFT,"LOAD",1,1,"BOLD_FONT",26)
	createTexture(generalBackgroundResource,"edge4",165,2,330,400,TOPLEFT,TOPLEFT,"")


	--createCheckbox(generalBackgroundResource,"combatCheckbox", 30,30,15,450,TOPLEFT,TOPLEFT,HTSV.trackers[CST].load.combat,function(arg) 
	--if CST ~= "none" then
	--	HTSV.trackers[CST].load.combat = arg
	--end
	--end)
	createLabel(generalBackgroundResource,"combatCheckboxLabel",150,30,55,450,TOPLEFT,TOPLEFT,"In Combat",0,1)
	--------- GENERAL RESOURCE-------------


	
	--------- CONDITIONS -------------
	local pickProperResultControl = {
		["Set Color"] = function() HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(false) end,
		["Hide Tracker"] = function() end,
	}
	local function processResultControlType()
		HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultColorpicker"):SetHidden(true)
		HT_Settings:GetNamedChild("background"):GetNamedChild("selectedTrackerSettingsBackdrop"):GetNamedChild("conditionBackground"):GetNamedChild("resultCheckbox"):SetHidden(true)
		pickProperResultControl[HTSV.trackers[CST].conditions[CSC].result]()
	end
	local conditionBackground = createBackground(selectedTrackerSettingsBackdrop,"conditionBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	conditionBackground:SetHidden(true)

	createTexture(conditionBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(conditionBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CONDITIONS",1,1,"BOLD_FONT",26)
	createTexture(conditionBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	local dropdownArg1 = createDropdown(conditionBackground,"dropdownArg1",200,30,45,140,TOPLEFT,TOPLEFT,getKeysFromTable(conditionArgs1),HTSV.trackers[CST].conditions[CSC].arg1 or "",function(selection)
	if CSC ~= "none" then
		HTSV.trackers[CST].conditions[CSC].arg1 = selection
	end
	end)
	local addConditionLabel = createLabel(conditionBackground,"ACLabel",200,20,45,120,TOPLEFT,TOPLEFT,"Set condition",0)
	local dropdownOperator = createDropdown(conditionBackground,"dropdownOperator",50,30,260,140,TOPLEFT,TOPLEFT,getKeysFromTable(operators),HTSV.trackers[CST].conditions[CSC].operator,function(selection)
	if CSC ~= "none" then
		HTSV.trackers[CST].conditions[CSC].operator = selection
	end
	end)
	local editboxArg2 = createEditbox(conditionBackground,"editboxArg2",150,30,320,140,TOPLEFT,TOPLEFT,function(editbox) 
	if CSC ~= "none" then
		HTSV.trackers[CST].conditions[CSC].arg2 = tonumber(editbox:GetText()) 
	end
	end,HTSV.trackers[CST].conditions[CSC].arg2)
	local resultColorpicker = createColorpicker(conditionBackground,"resultColorpicker", 70,30,260,190,TOPLEFT,TOPLEFT,HTSV.trackers[CST].conditions[CSC].resultArguments,function(color) 
	if CSC ~= "none" then
		HTSV.trackers[CST].conditions[CSC].resultArguments = color
	end
	end)
	local resultCheckbox = createCheckbox(conditionBackground,"resultCheckbox", 30,30,280,150,TOPLEFT,TOPLEFT,HTSV.trackers[CST].conditions[CSC].resultArguments,function(arg) 
	if CSC ~= "none" then
		HTSV.trackers[CST].conditions[CSC].resultArguments = arg
	end
	end)
	local dropdownResult = createDropdown(conditionBackground,"dropdownResult",200,30,45,190,TOPLEFT,TOPLEFT,getKeysFromTable(conditionResults),HTSV.trackers[CST].conditions[CSC].result,function(selection)
	if CSC ~= "none" then
		HTSV.trackers[CST].conditions[CSC].result = selection
		processResultControlType()
	end
	end)
	processResultControlType()
	local resultLabel = createLabel(conditionBackground,"RLabel",200,20,45,170,TOPLEFT,TOPLEFT,"Set result",0)
	local dropdown = createDropdown(conditionBackground,"dropdown",200,30,45,80,TOPLEFT,TOPLEFT,getKeysFromTable(HTSV.trackers[CST].conditions),CSC,function(selection)
	CSC = selection
	dropdownArg1.selection = HTSV.trackers[CST].conditions[CSC].arg1
	dropdownArg1:updateDropdown()
	dropdownOperator.selection = HTSV.trackers[CST].conditions[CSC].operator
	dropdownOperator:updateDropdown()
	editboxArg2:SetText(HTSV.trackers[CST].conditions[CSC].arg2)
	resultColorpicker:SetColor(unpack(HTSV.trackers[CST].conditions[CSC].resultArguments))
	dropdownResult.selection = HTSV.trackers[CST].conditions[CSC].result
	dropdownResult:updateDropdown()
	processResultControlType()
	end)
	local selectedConditionLabel = createLabel(conditionBackground,"SCLabel",200,20,45,60,TOPLEFT,TOPLEFT,"Select/Add condition",0)
	createButton(conditionBackground,"button",30,30,15,80,TOPLEFT,TOPLEFT,function() 
		PlaySound(SOUNDS.DUEL_START)
		table.insert(HTSV.trackers[CST].conditions,{
		arg1 = "Remaining Time",
		arg2 = 2,
		operator = "<=",
		result = "Set Color",
		resultArguments = {0,0,1,1},
		})
		dropdown.choices = getKeysFromTable(HTSV.trackers[CST].conditions)
		dropdown.selection = CSC
		dropdown:updateDropdown()
		updateLeftSide()
	end,nil,"esoui/art/buttons/plus_up.dds",false)
	--------- CONDITIONS -------------


	--------- EVENTS -------------
	local eventBackground = createBackground(selectedTrackerSettingsBackdrop,"eventBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	eventBackground:SetHidden(true)

	createTexture(eventBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(eventBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"EVENT",1,1,"BOLD_FONT",26)
	createTexture(eventBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	local dropdown = createDropdown(eventBackground,"dropdown",200,30,50,70,TOPLEFT,TOPLEFT,getKeysFromTable(HTSV.trackers[CST].events),CSE,function(selection) CSE = selection end)
	createDropdown(eventBackground,"dropdown2",200,30,50,120,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),HTSV.trackers[CST].events[1].type)
	createButton(eventBackground,"button",30,30,10,70,TOPLEFT,TOPLEFT,function() 
		PlaySound(SOUNDS.DUEL_START)
		table.insert(HTSV.trackers[CST].events,{
		type = "Update Effect Duration from Event"
		})
		dropdown.choices = getKeysFromTable(HTSV.trackers[CST].events)
		dropdown:updateDropdown()
		updateLeftSide()
	end,nil,"esoui/art/buttons/plus_up.dds",nil)
	--------- EVENTS -------------



	------ BACKGROUND ON THE RIGHT WHERE U CHANGE SETTINGS OF SELECTED TRACKERS ----------------


	updateLeftSide()
	

	HT_Settings:ClearAnchors()
	HT_Settings:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,0,0)
	
end

