local WM = GetWindowManager()

local importEditboxUpdated = false

local settingsVariables = {
	--currentLeftSide = "createNewTracker",
	currentRightSide = "newTrackersBackdrop",
	currentRightSideEdit = "displayBackground",
	typeOfCreatedTracker = "Progress Bar",
}


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
	"soft-shadow-thick","soft-shadow-thin","thick-outline","shadow",
}

local fontSizes = {
	8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,30,32,34,36,40,48,54
}

HT_settingsVisible = false

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



local function getChildrenFromName(name,table)
	if name == "HT_Trackers" then return HTSV.trackers end
	for k,v in pairs(table) do
		if k == name then return v.children end
		if getChildrenFromName(name,v.children) then return getChildrenFromName(name,v.children) end
	end
end

function changeTrackerName(fromName,toName)
	local tracker = HT_getTrackerFromName(fromName,HTSV.trackers)

	if tracker.parent ~= "HT_Trackers" and HT_getTrackerFromName(tracker.parent,HTSV.trackers).type == "Group Member" then
		HT_findContainer(HT_getTrackerFromName(tracker.parent,HTSV.trackers)):Delete()
	else
		HT_findContainer(tracker):Delete()
	end

	local parentName = tracker.parent
	local holdCopy = HT_deepcopy(tracker)
	for _,v in pairs(holdCopy.children) do
		v.parent = toName
	end
	holdCopy.name = toName
	getChildrenFromName(parentName,HTSV.trackers)[toName] = holdCopy
	HT_Settings:GetNamedChild("background"):GetNamedChild("eTB"):GetNamedChild("button"..tracker.parent..tracker.name):SetHidden(true)
	getChildrenFromName(parentName,HTSV.trackers)[tracker.name] = nil
		
	tracker = HT_getTrackerFromName(toName,HTSV.trackers)

	initializeTrackerFunctions[tracker.type](HT_findContainer(HT_getTrackerFromName(tracker.parent,HTSV.trackers)),holdCopy)
	
end

function removeDuplicateNamesFromImportedTable(importTable,parentTable)
	if HT_getTrackerFromName(importTable.name,HTSV.trackers) then
		changeUninitializedTrackerName(HT_generateNewName(importTable.name,1),importTable,parentTable)
	end
	for _,v in pairs(importTable.children) do
		removeDuplicateNamesFromImportedTable(v,importTable)
	end

end

function changeUninitializedTrackerName(toName,tracker,parent)
	local oldName =  tracker.name
	for _,v in pairs(tracker.children) do
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
		for _,v1 in pairs(v.children) do
			deleteTrackerFromName(name,v1)
		end
	end
end

local function getKeysFromTable(varTable)
	local holder = {}
	for k,_ in pairs(varTable) do
		table.insert(holder,k)
	end
	return holder
end

local function hideUI()
	HT_Settings:SetHidden(true)
	HT_settingsVisible = false

	for _,v in pairs(HTSV.trackers) do
		HT_changeLock(v,false)
	end

end

local function showUI()
	HT_Settings:SetHidden(false)
	HT_settingsVisible = true

	for _,v in pairs(HTSV.trackers) do
		HT_changeLock(v,true)
	end
end


function HT_toggleUI()
	if HT_settingsVisible then
		hideUI()
	else
		showUI()
	end
end

SLASH_COMMANDS["/hthide"] = hideUI
SLASH_COMMANDS["/htshow"] = showUI

CST = nil -- Currently Selected Tracker
local CSE = 1 -- Currently Selected Event
local CSC = 1 -- Currently Selected Condition
local CTC = "HT_Trackers"-- Current Top Control
local page = 1
local maxPage = 1

function deleteTracker(t)
	if t.parent ~= "HT_Trackers" and HT_getTrackerFromName(t.parent,HTSV.trackers).type == "Group Member" then
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

local function updateUI()
	local background = HT_Settings:GetNamedChild("background")
	local newTrackersBackdrop = background:GetNamedChild("newTrackersBackdrop")
	local selectedTrackerSettingsBackdrop = background:GetNamedChild("selectedTrackerSettingsBackdrop")
	local newProgressBarBackdrop = background:GetNamedChild("newProgressBarBackdrop")
	local newImportBackdrop = background:GetNamedChild("newImportBackdrop")
	local displayBackground = selectedTrackerSettingsBackdrop:GetNamedChild("displayBackground")
	local generalBackground = selectedTrackerSettingsBackdrop:GetNamedChild("generalBackground")
	local conditionBackground = selectedTrackerSettingsBackdrop:GetNamedChild("conditionBackground")
	local eventBackground = selectedTrackerSettingsBackdrop:GetNamedChild("eventBackground")
	newTrackersBackdrop:Update()
	selectedTrackerSettingsBackdrop:Update()
	newProgressBarBackdrop:Update()
	newImportBackdrop:Update()
	displayBackground:Update()
	generalBackground:Update()
	conditionBackground:Update()
	eventBackground:Update()
end


local function createLeftSidePanelButton(parent,counter,t)
	if t.name ~= "none" then
		local tracker = HT_getTrackerFromName(t.name,HTSV.trackers)
		local button = createButton(parent,"button"..tracker.parent..tracker.name,200,50,0,50*counter,TOPLEFT,TOPLEFT,function(ctrl,_,shift)
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
				if HT_getTrackerFromName(holdCopy.parent,HTSV.trackers).type ~= "Group Member" then
					initializeTrackerFunctions[holdCopy.type](HT_findContainer(tracker),holdCopy)
				end
			end
			CST = HT_getTrackerFromName(t.name,HTSV.trackers)
			CSC = HT_pickAnyKey(tracker.conditions)
			settingsVariables.currentRightSide = "selectedTrackerSettingsBackdrop"
			settingsVariables.currentRightSideEdit = "displayBackground"
			updateUI()
			relocateLeftSide()
			
			
			
		end,nil,nil,true)
		createButton(button,"deleteButton",23,23,-2,2,TOPRIGHT,TOPRIGHT,function()
			deleteTracker(tracker)
			relocateLeftSide()
			
			
			
			
			button:SetHidden(true)
		end,nil,"/esoui/art/buttons/decline_up.dds",true)
		local moveButton = createButton(button,"moveButton",23,23,-23,2,TOPRIGHT,TOPRIGHT,function()
			local holdCopy = HT_deepcopy(tracker)
			holdCopy.parent = HT_getTrackerFromName(HT_getTrackerFromName(t.name,HTSV.trackers).parent,HTSV.trackers).parent
			deleteTracker(tracker)
			getChildrenFromName(holdCopy.parent,HTSV.trackers)[holdCopy.name] = holdCopy
			initializeTrackerFunctions[holdCopy.type](HT_findContainer(HT_getTrackerFromName(holdCopy.parent,HTSV.trackers)),holdCopy)
			button:SetHidden(true)
			relocateLeftSide()
			
			
			
			
		end,nil,"/esoui/art/buttons/scrollbox_uparrow_up.dds",true)
		if tracker.parent == "HT_Trackers" then
			moveButton:SetHidden(true)
		end
		if tracker.type == "Group" or tracker.type == "Group Member" then
			createButton(button,"goInsideButton",23,23,-2,-2,BOTTOMRIGHT,BOTTOMRIGHT,function()
				CTC = tracker.name
				relocateLeftSide()
				
				
				
			end,nil,"/esoui/art/buttons/scrollbox_downarrow_up.dds",true)
		end
		local icon = createTexture(button,"icon",50,50,1,1,TOPLEFT,TOPLEFT,tracker.icon,4)
		createLabel(icon,"text",125,25,0,0,TOPLEFT,TOPRIGHT,tracker.name,1,1)
		createLabel(icon,"type",125,25,0,0,BOTTOMLEFT,BOTTOMRIGHT,tracker.type,1,1)
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
		for _,v1 in pairs(tracker.children) do
			hideAllButtons(v1)
		end
	end
	for _,v in pairs(HTSV.trackers) do -- hide all buttons
		hideAllButtons(v)
	end
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
	local backgroundColorDefault = { 0, 0, 0, 0.4}
	local outlineColorDefault = {0,0,0,1}
	if type == 'Group' or type == 'Group Member' then
		backgroundColorDefault = { 0, 0, 0, 0}
		outlineColorDefault = {0,0,0,0}
	end
		
	if HT_getTrackerFromName(name, HTSV.trackers) then
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
	backgroundColor = backgroundColorDefault,
	outlineColor = outlineColorDefault,
	textColor= {1,1,1,1},
	stacksColor = {1,1,1,1},
	cooldownColor = {0,0,0,0.7},
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
	conditions = {},
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
			luaCodeToExecute = "",
			dontUpdateFromThisEvent = false,
			Ids = IDs,
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
		always = false,
	},

	}




	initializeTrackerFunctions[type](HT_Trackers,HTSV.trackers[name])
end


local function onSceneChange(_,scene)
	if scene == SCENE_SHOWN then
		HT_Settings:SetHidden(not HT_settingsVisible)
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
				local tableToExport = HT_deepcopy(CST)
				HT_nullify(tableToExport)
				dialog:GetNamedChild("EditBox"):SetText(convertToString(tableToExport))
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
	createLabel(background,'versionLabel',100,30,0,0,BOTTOMLEFT,BOTTOMLEFT,'Hyper Tools '..HT.version)
	createButton(background,"exitButton",25,25,0,0,TOPRIGHT,TOPRIGHT,function() hideUI() end,nil,"/esoui/art/buttons/decline_up.dds",true)

	------ BACKGROUND ON THE LEFT WITH ALL EXISTING TRACKERS ----------------
---
	local eTB = createBackground(background,"eTB",200,775,25,25,TOPLEFT,TOPLEFT) -- existing trackers background
	eTB.Update = function()
		if settingsVariables.currentRightSide == "eTB" then
			eTB:SetHidden(false)
		else
			eTB:SetHidden(true)
		end
	end

	createButton(eTB,"button",200,50,0,0,TOPLEFT,TOPLEFT,function()
		settingsVariables.currentRightSide = "newTrackersBackdrop"
		updateUI()
		relocateLeftSide()
		
		
		
	end,nil,nil,true)
	local buttonIcon = createTexture(eTB,"buttonIcon",50,50,0,0,TOPLEFT,TOPLEFT,"HyperTools/icons/plusIcon.dds",2)
	createLabel(buttonIcon,"text",150,50,0,0,LEFT,RIGHT,"Create new",1,1) --Label is separate cuz otherwise the text is offset

	local returnButton = createButton(eTB,"returnButton",200,50,0,50,TOPLEFT,TOPLEFT,function() 
		CTC = HT_getTrackerFromName(CTC,HTSV.trackers).parent
		relocateLeftSide()
		
		
		
	end,"Return",nil,true)
	returnButton:SetHidden(true) --Hidden on default, because you start at the top, outside of any group

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
	newTrackersBackdrop.Update = function()
		if settingsVariables.currentRightSide == "newTrackersBackdrop" then
			newTrackersBackdrop:SetHidden(false)
		else
			newTrackersBackdrop:SetHidden(true)
		end
	end


	local newProgressBarBackdrop = createBackground(background,"newProgressBarBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newProgressBarBackdrop:SetHidden(true)

	createTexture(newProgressBarBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newProgressBarBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newProgressBarBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newProgressBarBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Name",0,1)

	local nameEditboxPB = createEditbox(newProgressBarBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(_) end)
	nameEditboxPB.Update = function()
		nameEditboxPB:SetText("")
	end

	local iDDropdownPB = createDropdown(newProgressBarBackdrop,"IDs dropdown",175,32,15,195,TOPLEFT,TOPLEFT,{},nil,function(_) end)
	iDDropdownPB.Update = function()
		iDDropdownPB.choices = {}
		iDDropdownPB.selection = nil
		iDDropdownPB:updateDropdown()
	end

	local idEditboxPB = createEditbox(iDDropdownPB,"addIdEditbox",175,30, 0,0,BOTTOM,TOP,function(_) end,nil,nil,"Ids")
	idEditboxPB.Update = function()
		idEditboxPB:SetText("")
	end

	createButton(iDDropdownPB,"buttonDeleteID",30,30,0,0,LEFT,RIGHT,function()
		HT_removeElementFromTable(iDDropdownPB.choices,iDDropdownPB.selection)
		iDDropdownPB.selection = HT_pickAnyElement(iDDropdownPB.choices)
		iDDropdownPB:updateDropdown()
	end, nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",nil)

	createButton(idEditboxPB,"buttonAddID",30,30,0,0,LEFT,RIGHT,function()
		table.insert(iDDropdownPB.choices,(tonumber(idEditboxPB:GetText()) or GetAbilityIdFromName(idEditboxPB:GetText())))
		iDDropdownPB.selection = HT_pickAnyElement(iDDropdownPB.choices)
		iDDropdownPB:updateDropdown()
	end,nil,"/esoui/art/buttons/plus_up.dds",nil)

	local targetNumberDropdownPB = createDropdown(newProgressBarBackdrop,"TargetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT, {1},1,function(_) end,"Number")
	targetNumberDropdownPB.Update = function()
		targetNumberDropdownPB.selection = 1
		targetNumberDropdownPB:updateDropdown()
	end

	local targetDropdownPB = createDropdown(newProgressBarBackdrop,"TargetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),"Yourself",function(selection)
		if selection == "Yourself" or selection == "Current Target" then
			targetNumberDropdownPB:SetHidden(true)
		else
			targetNumberDropdownPB:SetHidden(false)
			targetNumberDropdownPB.choices = getTargetNumberChoices[selection] or {1}
			targetNumberDropdownPB:updateDropdown()
		end
	end,"Target")
	targetDropdownPB.Update = function()
		targetDropdownPB.selection = "Yourself"
		targetDropdownPB:updateDropdown()
	end

	local typeDropdownPB = createDropdown(newProgressBarBackdrop,"typeDropdownPB",200,30,245,145,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),"Get Effect Duration",function(_) end,"Type")
	typeDropdownPB.Update = function()
		typeDropdownPB.selection = "Get Effect Duration"
		typeDropdownPB:updateDropdown()
	end

	local colorpickerPB = createColorpicker(newProgressBarBackdrop,"colorpicker",70,30,15,525,TOPLEFT,TOPLEFT,CST.barColor,function(_) end,"Color")
	colorpickerPB.Update = function()
		colorpickerPB:SetColor(1,1,1,1)
	end

	createTexture(newProgressBarBackdrop,"edge3",475,2,15,400,TOPLEFT,TOPLEFT,"")

	local widthEditboxPB = createEditbox(newProgressBarBackdrop,"cstXsizeEditbox",200,30,15,465,TOPLEFT,TOPLEFT,function(_) end,210,nil,"Width")
	widthEditboxPB.Update = function()
		widthEditboxPB:SetText(210)
	end

	local heightEditboxPB = createEditbox(newProgressBarBackdrop,"cstYsizeEditbox",200,30,250,465,TOPLEFT,TOPLEFT,function(_) end,30,nil,"Height")
	heightEditboxPB.Update = function()
		heightEditboxPB:SetText(30)
	end

	local textEditboxPB = createEditbox(newProgressBarBackdrop,"textEditbox",200,30,250,525,TOPLEFT,TOPLEFT,function(_) end,nil,nil,"Text")
	textEditboxPB.Update = function()
		textEditboxPB:SetText("")
	end

	createButton(newProgressBarBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function()
		createNewTracker(settingsVariables.typeOfCreatedTracker,nameEditboxPB:GetText(),textEditboxPB:GetText(),iDDropdownPB.choices,tonumber(widthEditboxPB:GetText()),tonumber(heightEditboxPB:GetText()),colorpickerPB.color,targetDropdownPB.selection,targetNumberDropdownPB.selection,typeDropdownPB.selection)
		
		
		
		relocateLeftSide()
		relocateLeftSide()
	end,"Create",nil,true)

	newProgressBarBackdrop.Update = function()
		if settingsVariables.currentRightSide == "newProgressBarBackdrop" then
			newProgressBarBackdrop:SetHidden(false)
		else
			newProgressBarBackdrop:SetHidden(true)
		end
		nameEditboxPB:Update()
		textEditboxPB:Update()
		iDDropdownPB:Update()
		widthEditboxPB:Update()
		heightEditboxPB:Update()
		colorpickerPB:Update()
		targetDropdownPB:Update()
		targetNumberDropdownPB:Update()
		typeDropdownPB:Update()
	end

	local newImportBackdrop = createBackground(background,"newImportBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	newImportBackdrop:SetHidden(true)

	createTexture(newImportBackdrop,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newImportBackdrop,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CREATE NEW PROGRESS BAR",1,1,"BOLD_FONT",26)
	createTexture(newImportBackdrop,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(newImportBackdrop,"name",150,30,15,60,TOPLEFT,TOPLEFT,"Import String",0,1)

	local nameEditboxImport = createEditbox(newImportBackdrop,"editbox",200,30,15,85,TOPLEFT,TOPLEFT,function(_) end)
	nameEditboxImport.Update = function()
		nameEditboxImport:SetText("")
	end

	createButton(newImportBackdrop,"buttonCreateTracker",200,30,150,700,TOPLEFT,TOPLEFT,function()
		local importString = nameEditbox:GetText()
		if importString then
			importString = string.sub(importString,2,#importString-1)
			local importedTable = importFromString(importString)
			removeDuplicateNamesFromImportedTable(importedTable,HTSV.trackers)
			importedTable.parent = "HT_Trackers"
			HT_adjustDataForNewestVersion({importedTable})
			HTSV.trackers[importedTable.name] = importedTable
			initializeTrackerFunctions[importedTable.type](HT_Trackers,importedTable)
		end
		relocateLeftSide()
		relocateLeftSide()
		
		
		
	end,"Create",nil,true)

	newImportBackdrop.Update = function()
		if settingsVariables.currentRightSide == "newImportBackdrop" then
			newImportBackdrop:SetHidden(false)
		else
			newImportBackdrop:SetHidden(true)
		end
		nameEditboxImport:Update()
	end

	for i=2, 6 do
		local icon = createTexture(newTrackersBackdrop,"icon"..i,100,100,0,100*(i-2),TOPLEFT,TOPLEFT,iconsByNumber[i],2)
		local button = createButton(icon,"button"..i,425,100,0,0,TOPLEFT,TOPRIGHT,function()
			settingsVariables.typeOfCreatedTracker = typesByNumber[i]
			settingsVariables.currentRightSide = "newProgressBarBackdrop"
			if i==6 then settingsVariables.currentRightSide = "newImportBackdrop" end
			updateUI()
			relocateLeftSide()
		end,nil,nil,true)
		createLabel(button,"title"..i,425,50,0,0,TOP,TOP,typesByNumber[i],1,1,"BOLD_FONT",26)
		createLabel(button,"text"..i,425,50,0,0,BOTTOM,BOTTOM,textsByNumber[i],1,1,nil,nil)
	end

	------ BACKGROUND ON THE RIGHT WHERE U CHANGE SETTINGS OF SELECTED TRACKERS ----------------

	local selectedTrackerSettingsBackdrop = createBackground(background,"selectedTrackerSettingsBackdrop",525,775,250,25,TOPLEFT,TOPLEFT)
	selectedTrackerSettingsBackdrop.Update = function()
		if settingsVariables.currentRightSide == "selectedTrackerSettingsBackdrop" then
			selectedTrackerSettingsBackdrop:SetHidden(false)
		else
			selectedTrackerSettingsBackdrop:SetHidden(true)
		end
	end

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
	local tabsBackgrounds = {
		[1] = {
			[1] = "displayBackground",
			[2] = "eventBackground",
		},
		[2] = {
			[1] = "generalBackground",
			[2] = "conditionBackground",
		},
	}

	for n=1,2 do -- 4 button at the top of right side of settings -> [Display,Event,Conditions,General]
		for i=1,2 do
			local button = createButton(selectedTrackerSettingsBackdrop,"button"..n..i,525/2,25,(525/2)*(i-1),25*(n-1),TOPLEFT,TOPLEFT,function()
				settingsVariables.currentRightSideEdit = tabsBackgrounds[n][i]
				updateUI()
			end,tabs[n][i],nil,true)
			if n==1 and i==1 then button.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1) end
		end
	end

	--------- DISPLAY -------------
	local displayBackground = createBackground(selectedTrackerSettingsBackdrop,"displayBackground",525,725,0,50,TOPLEFT,TOPLEFT)

	createTexture(displayBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(displayBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"DISPLAY",1,1,"BOLD_FONT",26)
	createTexture(displayBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	local displayEditbox = createEditbox(displayBackground,"displayEditbox",475,30,15,90,TOPLEFT,TOPLEFT,function(thisEditbox)
		CST.icon = thisEditbox:GetText()
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.icon,nil,"Texture Path")
	displayEditbox.Update = function()
		displayEditbox:SetText(CST.icon)
	end

	local autoTextureDropdown = createDropdown(displayBackground,"autoTextureDropdown",200,30,15,145,TOPLEFT,TOPLEFT,HT_getIdsFromAllEvents(CST),HT_pickAnyElement(HT_getIdsFromAllEvents(CST),0),function(_) end,"Set automatic texture from ID")
	autoTextureDropdown.Update = function()
		autoTextureDropdown.choices = HT_getIdsFromAllEvents(CST)
		autoTextureDropdown.selection = HT_pickAnyElement(HT_getIdsFromAllEvents(CST),0)
		autoTextureDropdown:updateDropdown()
	end

	createButton(displayBackground,"button",200,30,250,145,TOPLEFT,TOPLEFT,function() 
		CST.icon = GetAbilityIcon(autoTextureDropdown.selection or 0)
		editbox:SetText(GetAbilityIcon(autoTextureDropdown.selection or 0))
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		relocateLeftSide()
	end,"Auto-set texture",nil,true)

	local fontDropdown = createDropdown(displayBackground,"fontDropdown",90,30,15,205,TOPLEFT,TOPLEFT,fonts,CST.font,function(selection)
		if CST.name ~= "none" then
			CST.font = selection
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then
					HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers))
			else
				if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end,"Font")
	fontDropdown.Update = function()
		fontDropdown.selection = CST.font
		fontDropdown:updateDropdown()
	end

	local fontWeightDropdown = createDropdown(displayBackground,"fontWeightDropdown",60,30,105,205,TOPLEFT,TOPLEFT,fontWeights,CST.fontWeight,function(selection)
		if CST.name ~= "none" then
			CST.fontWeight = selection
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Weight")
	fontWeightDropdown.Update = function()
		fontWeightDropdown.selection = CST.fontWeight
		fontWeightDropdown:updateDropdown()
	end

	local fontSizeDropdown = createDropdown(displayBackground,"fontSizeDropdown",50,30,160,205,TOPLEFT,TOPLEFT,fontSizes,CST.fontSize,function(selection)
		if CST.name ~= "none" then
			CST.fontSize = selection
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Size")
	fontSizeDropdown.Update = function()
		fontSizeDropdown.selection = CST.fontSize
		fontSizeDropdown:updateDropdown()
	end

	local displayTextEditbox = createEditbox(displayBackground,"displayTextEditbox",200,30,250,205,TOPLEFT,TOPLEFT,function(thisEditbox)
		CST.text = thisEditbox:GetText()
		
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.text,nil,"Text")
	displayTextEditbox.Update = function()
		displayTextEditbox:SetText(CST.text)
	end

	local displayColorpickerBar = createColorpicker(displayBackground,"displayColorpickerBar",70,30,15,275,TOPLEFT,TOPLEFT,CST.barColor,function(color)
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.barColor = color 
				if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end,"Bar")
	displayColorpickerBar.Update = function()
		displayColorpickerBar:SetColor(unpack(CST.barColor))
	end

	local displayColorpickerOutline = createColorpicker(displayBackground,"displayColorpickerOutline",70,30,100,275,TOPLEFT,TOPLEFT,CST.outlineColor,function(color)
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.outlineColor = color 
				if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end,"Outline")
	displayColorpickerOutline.Update = function()
		displayColorpickerOutline:SetColor(unpack(CST.outlineColor))
	end

	local displayColorpickerBackground = createColorpicker(displayBackground,"displayColorpickerBackground",70,30,185,275,TOPLEFT,TOPLEFT,CST.backgroundColor,function(color)
		if type(color) == "table" then
			CST.backgroundColor = color 
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Background")
	displayColorpickerBackground.Update = function()
		displayColorpickerBackground:SetColor(unpack(CST.backgroundColor))
	end

	local colorpickerLabelColorpicker = createColorpicker(displayBackground,"colorpickerLabelColorpicker",70,30,15,340,TOPLEFT,TOPLEFT,CST.textColor,function(color)
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.textColor = color 
				if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end,"Text")
	colorpickerLabelColorpicker.Update = function()
		colorpickerLabelColorpicker:SetColor(unpack(CST.textColor))
	end

	local colorpickerTimeColorpicker = createColorpicker(displayBackground,"colorpickerTimeColorpicker",70,30,100,340,TOPLEFT,TOPLEFT,CST.timeColor,function(color)
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.timeColor = color 
				if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end,"Time")
	colorpickerTimeColorpicker.Update = function()
		colorpickerTimeColorpicker:SetColor(unpack(CST.timeColor))
	end

	local colorpickerStacksColorpicker = createColorpicker(displayBackground,"colorpickerStacksColorpicker",70,30,185,340,TOPLEFT,TOPLEFT,CST.stacksColor,function(color)
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.stacksColor = color 
				if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end,"Stacks")
	colorpickerStacksColorpicker.Update = function()
		colorpickerStacksColorpicker:SetColor(unpack(CST.stacksColor))
	end

	local colorpickerCooldownColorpicker = createColorpicker(displayBackground,"colorpickerCooldownColorpicker",70,30,185,405,TOPLEFT,TOPLEFT,CST.cooldownColor,function(color)
		if CST.name ~= "none" then
			if type(color) == "table" then
				CST.cooldownColor = color 
				if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			end
		end
	end,"Cooldown")
	colorpickerCooldownColorpicker.Update = function()
		colorpickerCooldownColorpicker:SetColor(unpack(CST.cooldownColor))
	end

	local inverseCheckbox = createCheckbox(displayBackground,"inverseCheckbox", 30,30,270,250,TOPLEFT,TOPLEFT,CST.inverse,function(arg)
		if CST.name ~= "none" then
			CST.inverse = arg
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Inverse")
	inverseCheckbox.UpdateCheckbox = function()
		inverseCheckbox:Update(CST.inverse)
	end

	local reimainingTimeCheckbox = createCheckbox(displayBackground,"remainingTimeCheckbox", 30,30,270,290,TOPLEFT,TOPLEFT,CST.timer1,function(arg)
		if CST.name ~= "none" then
			CST.timer1 = arg
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Remaining Time")
	reimainingTimeCheckbox.UpdateCheckbox = function()
		reimainingTimeCheckbox:Update(CST.timer1)
	end

	local decimalsDropdown = createDropdown(displayBackground,"decimalsDropdown",50,30,400,305,TOPLEFT,TOPLEFT,{0,1},CST.decimals,function(selection)
		if CST.name ~= "none" then
			CST.decimals = selection
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Decimals")
	decimalsDropdown.Update = function()
		decimalsDropdown.selection = CST.decimals
		decimalsDropdown:updateDropdown()
	end

	local stacksCheckbox = createCheckbox(displayBackground,"stacksCheckbox", 30,30,270,330,TOPLEFT,TOPLEFT,CST.timer2,function(arg)
		if CST.name ~= "none" then
			CST.timer2 = arg
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Stacks")
	stacksCheckbox.UpdateCheckbox = function()
		stacksCheckbox:Update(CST.timer2)
	end

	local drawLevelDropdown = createDropdown(displayBackground,"drawLevelDropdown",50,30,15,400,TOPLEFT,TOPLEFT,{0,1,2,3,4},CST.drawLevel,function(selection)
		if CST.name ~= "none" then
			CST.drawLevel = selection
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Draw Level")
	drawLevelDropdown.Update = function()
		drawLevelDropdown.selection = CST.drawLevel
		drawLevelDropdown:updateDropdown()
	end

	createTexture(displayBackground,"edge3",475,2,15,530,TOPLEFT,TOPLEFT,"")

	local positionXEditbox = createEditbox(displayBackground,"positionXEditbox",200,30,15,565,TOPLEFT,TOPLEFT,function(thisEditbox)
		CST.xOffset = thisEditbox:GetText()
		
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.xOffset,TEXT_TYPE_NUMERIC,"X position")
	positionXEditbox.Update = function()
		positionXEditbox:SetText(math.floor(CST.sizeX))
	end

	local positionYEditbox = createEditbox(displayBackground,"positionYEditbox",200,30,250,565,TOPLEFT,TOPLEFT,function(thisEditbox)
		CST.yOffset = thisEditbox:GetText()
		
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.yOffset,TEXT_TYPE_NUMERIC,"Y position")
	positionYEditbox.Update = function()
		positionYEditbox:SetText(math.floor(CST.sizeY))
	end

	local sizeXEditbox = createEditbox(displayBackground,"sizeXEditbox",200,30,15,615,TOPLEFT,TOPLEFT,function(thisEditbox)
		CST.sizeX = thisEditbox:GetText()
		
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.sizeX,TEXT_TYPE_NUMERIC,"Width")
	sizeXEditbox.Update = function()
		sizeXEditbox:SetText(math.floor(CST.xOffset))
	end

	local sizeYEditbox = createEditbox(displayBackground,"sizeYEditbox",200,30,250,615,TOPLEFT,TOPLEFT,function(thisEditbox)
		CST.sizeY = thisEditbox:GetText()
		
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.sizeY,TEXT_TYPE_NUMERIC,"Height")
	sizeYEditbox.Update = function()
		sizeYEditbox:SetText(math.floor(CST.yOffset))
	end
	
	local outlineThicknessDropdown = createDropdown(displayBackground,"outlineThicknessDropdown",200,30,15,665,TOPLEFT,TOPLEFT,{1,2,4,8,16},CST.outlineThickness,function(selection)
		if CST.name ~= "none" then
			CST.outlineThickness = selection
			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
		end
	end,"Outline Thickness")
	outlineThicknessDropdown.Update = function()
		outlineThicknessDropdown:SetHidden(false)
		outlineThicknessDropdown.selection = CST.outlineThickness
		outlineThicknessDropdown:updateDropdown()
	end

	displayBackground.Update = function()
		local displayButton = selectedTrackerSettingsBackdrop:GetNamedChild("button21")
		if settingsVariables.currentRightSideEdit == "displayBackground" then
			displayBackground:SetHidden(false)
			displayButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
		else
			displayBackground:SetHidden(true)
			displayButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
		end
		displayEditbox:Update()
		autoTextureDropdown:Update()
		fontDropdown:Update()
		fontWeightDropdown:Update()
		fontSizeDropdown:Update()
		displayTextEditbox:Update()
		displayColorpickerBar:Update()
		displayColorpickerOutline:Update()
		displayColorpickerBackground:Update()
		colorpickerLabelColorpicker:Update()
		colorpickerTimeColorpicker:Update()
		colorpickerStacksColorpicker:Update()
		colorpickerCooldownColorpicker:Update()
		inverseCheckbox:Update()
		reimainingTimeCheckbox:Update()
		decimalsDropdown:Update()
		stacksCheckbox:Update()
		drawLevelDropdown:Update()
		positionXEditbox:Update()
		positionYEditbox:Update()
		sizeXEditbox:Update()
		sizeYEditbox:Update()
		outlineThicknessDropdown:Update()
	end

	--------- DISPLAY -------------

	--------- GENERAL -------------
	local generalBackground = createBackground(selectedTrackerSettingsBackdrop,"generalBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	generalBackground:SetHidden(true)

	createTexture(generalBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"generalLabel",150,30,180,10,TOPLEFT,TOPLEFT,"GENERAL",1,1,"BOLD_FONT",26)
	createTexture(generalBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	local generalNameEditbox = createEditbox(generalBackground,"generalNameEditbox",200,30,15,75,TOPLEFT,TOPLEFT,function(thisEditbox)
		if not HT_getTrackerFromName(thisEditbox:GetText(),HTSV.trackers) then
			changeTrackerName(CST.name,thisEditbox:GetText())
			CST = HT_getTrackerFromName(thisEditbox:GetText(),HTSV.trackers)

			if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
			relocateLeftSide()
			relocateLeftSide()
		else
			d("Duplicate name")
		end
	end,CST.name,nil,"Name")
	generalNameEditbox.Update = function()
		generalNameEditbox:SetText(CST.name)
	end

	local targetNumberDropdown = createDropdown(generalBackground,"targetNumberDropdown",50,30,395,75,TOPLEFT,TOPLEFT,getTargetNumberChoices[CST.target] or {1},CST.targetNumber or 1,function(selection)
		CST.targetNumber = selection
	end,"Number")
	targetNumberDropdown.Update = function()
		if (CST.type == "Group Member" or (CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member")) or (CST.target == "Yourself" or CST.target == "Current Target") then
			targetNumberDropdown:SetHidden(true)
		else
			targetNumberDropdown:SetHidden(false)
			targetNumberDropdown.choices = getTargetNumberChoices[CST.target] or {1}
			targetNumberDropdown.selection = CST.targetNumber
			targetNumberDropdown:updateDropdown()
		end
	end

	local targetDropdown = createDropdown(generalBackground,"targetDropdown",150,30,245,75,TOPLEFT,TOPLEFT,getKeysFromTable(HT_targets),CST.target,function(selection)
		CST.target = selection
		if CST.target == "Yourself" or CST.target == "Current Target" then
			targetNumberDropdown:SetHidden(true)
		else
			targetNumberDropdown:SetHidden(false)
			targetNumberDropdown.choices = getTargetNumberChoices[CST.target] or {1}
			targetNumberDropdown.selection = CST.targetNumber
			targetNumberDropdown:updateDropdown()
		end
	end,"Target")
	targetDropdown.Update = function()
		if CST.type == "Group Member" or (CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member") then
			targetDropdown:SetHidden(true)
		else
			targetDropdown:SetHidden(false)
			targetDropdown.selection = CST.target
			targetDropdown:updateDropdown()
		end
	end

	createButton(generalBackground,"exportButton",200,30,15,250,TOPLEFT,TOPLEFT,function() 
		importEditboxUpdated = false
		ZO_Dialogs_ShowDialog("HT_Export")
	end,"Export Tracker",nil,true)

	createTexture(generalBackground,"edge3",165,2,15,300,TOPLEFT,TOPLEFT,"")
	createLabel(generalBackground,"loadLabel",150,30,180,287.5,TOPLEFT,TOPLEFT,"LOAD",1,1,"BOLD_FONT",26)
	createTexture(generalBackground,"edge4",165,2,330,300,TOPLEFT,TOPLEFT,"")
	
	local neverCheckbox = createCheckbox(generalBackground,"neverCheckbox", 30,30,15,340,TOPLEFT,TOPLEFT,CST.load.never,function(arg)
	CST.load.never = arg
	end,"Never")
	neverCheckbox.UpdateCheckbox = function()
		neverCheckbox:Update(CST.load.never)
	end

	local alwaysCheckbox = createCheckbox(generalBackground,"alwaysCheckbox", 30,30,115,340,TOPLEFT,TOPLEFT,CST.load.always,function(arg)
		CST.load.always = arg
	end,"Always")
	alwaysCheckbox.UpdateCheckbox = function()
		alwaysCheckbox:Update(CST.load.always)
	end

	local combatCheckbox = createCheckbox(generalBackground,"combatCheckbox", 30,30,235,340,TOPLEFT,TOPLEFT,CST.load.inCombat,function(arg)
	CST.load.inCombat = arg
	end,"In Combat")
	combatCheckbox.UpdateCheckbox = function()
		combatCheckbox:Update(CST.load.inCombat)
	end

	local classDropdown = createDropdown(generalBackground,"classDropdown",200,30,15,565,TOPLEFT,TOPLEFT,{"Any","Dragonknight","Nightblade","Sorcerer","Templar","Warden","Necromancer"},CST.load.class,function(selection)
		if CST.name ~= "none" then
			CST.load.class = selection
		end
	end,"Class")
	classDropdown.Update = function()
		classDropdown.selection = CST.load.class
		classDropdown:updateDropdown()
	end

	local roleDropdown = createDropdown(generalBackground,"roleDropdown",200,30,15,505,TOPLEFT,TOPLEFT,{"Any","Damage Dealer","Tank","Healer"},IdToRole[CST.load.role],function(selection)
		if CST.name ~= "none" then
			CST.load.role = roleToId[selection]
		end
	end,"Role")
	roleDropdown.Update = function()
		roleDropdown.selection = IdToRole[CST.load.role]
		roleDropdown:updateDropdown()
	end

	local bossDropdown = createDropdown(generalBackground,"bossDropdown",175,32,15,435,TOPLEFT,TOPLEFT,CST.load.bosses,HT_pickAnyElement(CST.load.bosses),function(_) end,"Boss")
	bossDropdown.Update = function()
		bossDropdown.choices = CST.load.bosses
		bossDropdown.selection = HT_pickAnyElement(CST.load.bosses)
		bossDropdown:updateDropdown()
	end

	local addBossEditbox = createEditbox(generalBackground,"addBossEditbox",175,30,15,405,TOPLEFT,TOPLEFT,function(_) end)
	addBossEditbox.Update = function()

	end

	createButton(generalBackground,"buttonDeleteBoss",30,30,190,435,TOPLEFT,TOPLEFT,function()
		HT_removeElementFromTable(CST.load.bosses,bossDropdown.selection)
		bossDropdown.choices = CST.load.bosses
		bossDropdown.selection = HT_pickAnyElement(CST.load.bosses)
		bossDropdown:updateDropdown()
	end, "-",nil,nil)

	createButton(generalBackground,"buttonAddBoss",30,30,188,405,TOPLEFT,TOPLEFT,function()
		table.insert(CST.load.bosses,addBossEditbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		addBossEditbox:SetText(nil)
		bossDropdown.choices = CST.load.bosses
		bossDropdown.selection = HT_pickAnyElement(CST.load.bosses)
		bossDropdown:updateDropdown()
	end,"+",nil,nil)

	local skillDropdown = createDropdown(generalBackground,"skillDropdown",175,32,15,655,TOPLEFT,TOPLEFT,CST.load.skills,HT_pickAnyElement(CST.load.skills),function(_) end,"Skills")
	skillDropdown.Update = function()
		skillDropdown.choices = CST.load.skills
		skillDropdown.selection = HT_pickAnyElement(CST.load.skills)
		skillDropdown:updateDropdown()
	end

	local addSkillEditbox = createEditbox(generalBackground,"addSkillEditbox",175,30,15,625,TOPLEFT,TOPLEFT,function(_) end,nil,TEXT_TYPE_NUMERIC)
	addSkillEditbox.Update = function()

	end

	createButton(generalBackground,"buttonDeleteSkill",30,30,190,655,TOPLEFT,TOPLEFT,function()
		HT_removeElementFromTable(CST.load.skills,dropdown.selection)
		dropdown.choices = CST.load.skills
		dropdown.selection = HT_pickAnyElement(CST.load.skills)
		dropdown:updateDropdown()
	end, "-",nil,nil)

	createButton(generalBackground,"buttonAddSkill",30,30,188,625,TOPLEFT,TOPLEFT,function()
		table.insert(CST.load.skills,tonumber(editbox:GetText()))-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = CST.load.skills
		dropdown.selection = HT_pickAnyElement(CST.load.skills)
		dropdown:updateDropdown()
	end,"+",nil,nil)

	local itemSetDropdown = createDropdown(generalBackground,"itemSetDropdown",175,32,235,655,TOPLEFT,TOPLEFT,CST.load.itemSets,HT_pickAnyElement(CST.load.itemSets),function(_) end,"Item Sets")
	itemSetDropdown.Update = function()
		itemSetDropdown.choices = CST.load.itemSets
		itemSetDropdown.selection = HT_pickAnyElement(CST.load.itemSets)
		itemSetDropdown:updateDropdown()
	end

	local addItemSetEditbox = createEditbox(generalBackground,"addItemSetEditbox",175,30,235,625,TOPLEFT,TOPLEFT,function(_) end)
	addItemSetEditbox.Update = function()

	end

	createButton(generalBackground,"buttonDeleteitemSet",30,30,410,655,TOPLEFT,TOPLEFT,function()
		HT_removeElementFromTable(CST.load.itemSets,dropdown.selection)
		dropdown.choices = CST.load.itemSets
		dropdown.selection = HT_pickAnyElement(CST.load.itemSets)
		dropdown:updateDropdown()
	end, "-",nil,nil)

	createButton(generalBackground,"buttonAdditemSet",30,30,408,625,TOPLEFT,TOPLEFT,function()
		table.insert(CST.load.itemSets,editbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = CST.load.itemSets
		dropdown.selection = HT_pickAnyElement(CST.load.itemSets)
		dropdown:updateDropdown()
	end,"+",nil,nil)

	local zoneDropdown = createDropdown(generalBackground,"zoneDropdown",175,32,235,535,TOPLEFT,TOPLEFT,CST.load.zones,HT_pickAnyElement(CST.load.zones),function(_) end,"Zones")
	zoneDropdown.Update = function()
		zoneDropdown.choices = CST.load.zones
		zoneDropdown.selection = HT_pickAnyElement(CST.load.zones)
		zoneDropdown:updateDropdown()
	end

	local addZoneEditbox = createEditbox(generalBackground,"addzoneEditbox",175,30,235,505,TOPLEFT,TOPLEFT,function(_) end)
	addZoneEditbox.Update = function()

	end

	createButton(generalBackground,"buttonDeletezone",30,30,410,535,TOPLEFT,TOPLEFT,function()
		HT_removeElementFromTable(CST.load.zones,dropdown.selection)
		dropdown.choices = CST.load.zones
		dropdown.selection = HT_pickAnyElement(CST.load.zones)
		dropdown:updateDropdown()
	end, "-",nil,nil)

	createButton(generalBackground,"buttonAddzone",30,30,408,505,TOPLEFT,TOPLEFT,function()
		table.insert(CST.load.zones,editbox:GetText())-- or GetAbilityIdFromName(editbox:GetText())))
		editbox:SetText(nil)
		dropdown.choices = CST.load.zones
		dropdown.selection = HT_pickAnyElement(CST.load.zones)
		dropdown:updateDropdown()
	end,"+",nil,nil)

	generalBackground.Update = function()
		local generalButton = selectedTrackerSettingsBackdrop:GetNamedChild("button11")
		if settingsVariables.currentRightSideEdit == "generalBackground" then
			generalBackground:SetHidden(false)
			generalButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
		else
			generalBackground:SetHidden(true)
			generalButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
		end
		generalNameEditbox:Update()
		targetNumberDropdown:Update()
		targetDropdown:Update()
		neverCheckbox:UpdateCheckbox()
		alwaysCheckbox:UpdateCheckbox()
		combatCheckbox:UpdateCheckbox()
		classDropdown:Update()
		roleDropdown:Update()
		zoneDropdown:Update()
		skillDropdown:Update()
		itemSetDropdown:Update()
	end

	--------- GENERAL -------------










	--------- CONDITIONS -------------

	local conditionBackground = createBackground(selectedTrackerSettingsBackdrop,"conditionBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	conditionBackground:SetHidden(true)

	createTexture(conditionBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(conditionBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"CONDITIONS",1,1,"BOLD_FONT",26)
	createTexture(conditionBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	local dropdownArg1 = createDropdown(conditionBackground,"dropdownArg1",200,30,45,140,TOPLEFT,TOPLEFT,getKeysFromTable(conditionArgs1),CST.conditions[CSC].arg1 or "",function(selection)
	if CSC ~= "none" then
		CST.conditions[CSC].arg1 = selection
	end
	end,"Set Condition")
	dropdownArg1.Update = function()
		if CST.name ~= "none" and CST.conditions[CSC] then
			dropdownArg1.selection = CST.conditions[CSC].arg1 or ""
			dropdownArg1:updateDropdown()
		end
	end

	local dropdownOperator = createDropdown(conditionBackground,"dropdownOperator",50,30,260,140,TOPLEFT,TOPLEFT,getKeysFromTable(operators),CST.conditions[CSC].operator,function(selection)
	if CSC ~= "none" then
		CST.conditions[CSC].operator = selection
	end
	end)
	dropdownOperator.Update = function()
		dropdownOperator.selection = CST.conditions[CSC].operator
		dropdownOperator:updateDropdown()
	end

	local editboxArg2 = createEditbox(conditionBackground,"editboxArg2",150,30,320,140,TOPLEFT,TOPLEFT,function(thisEditbox)
	if CSC ~= "none" then
		CST.conditions[CSC].arg2 = tonumber(thisEditbox:GetText())
	end
	end,CST.conditions[CSC].arg2)
	editboxArg2.Update = function()
		editboxArg2:SetText(CST.conditions[CSC].arg2)
	end

	local resultColorpicker = createColorpicker(conditionBackground,"resultColorpicker", 70,30,260,190,TOPLEFT,TOPLEFT,CST.conditions[CSC].resultArguments,function(color) 
	if CSC ~= "none" then
		CST.conditions[CSC].resultArguments = color
	end
	end)
	resultColorpicker.Update = function()
		local visibilityConditions = {
			["Set Bar Color"] = false,
			["Set Text Color"] = false,
			["Set Timer Color"] = false,
			["Set Stacks Color"] = false,
			["Set Background Color"] = false,
			["Set Border Color"] = false,
			["Hide Tracker"] = true,
			["Show Proc"] = true,
		}
		resultColorpicker:SetHidden(visibilityConditions[CST.conditions[CSC].result])
		resultColorpicker:SetColor(unpack(CST.conditions[CSC].resultArguments))
	end

	local resultCheckbox = createCheckbox(conditionBackground,"resultCheckbox", 30,30,280,150,TOPLEFT,TOPLEFT,CST.conditions[CSC].resultArguments,function(arg)
	if CSC ~= "none" then
		CST.conditions[CSC].resultArguments = arg
	end
	end)
	resultCheckbox.UpdateCheckbox = function()
		local visibilityConditions = {
			["Set Bar Color"] = true,
			["Set Text Color"] = true,
			["Set Timer Color"] = true,
			["Set Stacks Color"] = true,
			["Set Background Color"] = true,
			["Set Border Color"] = true,
			["Hide Tracker"] = true,
			["Show Proc"] = true,
		}
		resultCheckbox:SetHidden(visibilityConditions[CST.conditions[CSC].result])
	end

	local dropdownResult = createDropdown(conditionBackground,"dropdownResult",200,30,45,190,TOPLEFT,TOPLEFT,getKeysFromTable(conditionResults),CST.conditions[CSC].result,function(selection)
	if CSC ~= "none" then
		CST.conditions[CSC].result = selection
	end
	end,"Set Result")
	dropdownResult.Update = function()
		dropdownResult.selection = CST.conditions[CSC].result
		dropdownResult:updateDropdown()
	end

	local conditionsDropdown = createDropdown(conditionBackground,"conditionsDropdown",200,30,45,80,TOPLEFT,TOPLEFT,getKeysFromTable(CST.conditions),CSC,function(selection)
	CSC = selection
	dropdownArg1.selection = CST.conditions[CSC].arg1
	dropdownArg1:updateDropdown()
	dropdownOperator.selection = CST.conditions[CSC].operator
	dropdownOperator:updateDropdown()
	editboxArg2:SetText(CST.conditions[CSC].arg2)
	resultColorpicker:SetColor(unpack(CST.conditions[CSC].resultArguments))
	dropdownResult.selection = CST.conditions[CSC].result
	dropdownResult:updateDropdown()
	end,"Select/Add condition")
	conditionsDropdown.Update = function()
		conditionsDropdown.choices = getKeysFromTable(CST.conditions)
		conditionsDropdown.selection = HT_pickAnyKey(CST.conditions)
		conditionsDropdown:updateDropdown()
	end

	createButton(conditionBackground,"button",30,30,15,80,TOPLEFT,TOPLEFT,function()
		table.insert(CST.conditions,{
		arg1 = "Remaining Time",
		arg2 = 0,
		operator = "<",
		result = "Hide Tracker",
		resultArguments = {0,0,1,1},
		})
		conditionsDropdown.choices = getKeysFromTable(CST.conditions)
		conditionsDropdown.selection = CSC
		conditionsDropdown:updateDropdown()
		relocateLeftSide()
	end,nil,"esoui/art/buttons/plus_up.dds",false)

	createButton(conditionsDropdown,"deleteButton",30,30,0,0,LEFT,RIGHT,function()
		CST.conditions[CSC] = nil
		conditionsDropdown.choices = getKeysFromTable(CST.conditions)
		conditionsDropdown.selection = HT_pickAnyKey(CST.conditions)
		conditionsDropdown:updateDropdown()
		relocateLeftSide()
	end,nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",false)

	conditionBackground.Update = function()
		local conditionButton = selectedTrackerSettingsBackdrop:GetNamedChild("button11")
		if settingsVariables.currentRightSideEdit == "conditionBackground" then
			conditionBackground:SetHidden(false)
			conditionButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
		else
			conditionBackground:SetHidden(true)
			conditionButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
		end
		dropdownArg1:Update()
		dropdownOperator:Update()
		editboxArg2:Update()
		resultColorpicker:Update()
		resultCheckbox:UpdateCheckbox()
		dropdownResult:Update()
		conditionsDropdown:Update()
	end

	--------- CONDITIONS -------------


	--------- EVENTS -------------
	local eventBackground = createBackground(selectedTrackerSettingsBackdrop,"eventBackground",525,725,0,50,TOPLEFT,TOPLEFT)
	eventBackground:SetHidden(true)

	createTexture(eventBackground,"edge1",165,2,15,22.5,TOPLEFT,TOPLEFT,"")
	createLabel(eventBackground,"displayLabel",150,30,180,10,TOPLEFT,TOPLEFT,"EVENT",1,1,"BOLD_FONT",26)
	createTexture(eventBackground,"edge2",165,2,330,22.5,TOPLEFT,TOPLEFT,"")

	local backgroundIdDropdown = createDropdown(eventBackground,"backgroundIdDropdown",175,32,300,100,TOPLEFT,TOPLEFT,CST.events[CSE].arguments.Ids,HT_pickAnyElement(CST.events[CSE].arguments.Ids),function(_) end)
	backgroundIdDropdown.Update = function()
		local visibilityConditions = {
			["Get Effect Duration"] = false,
			["Get Effect Cooldown"] = false,
			["Entering/Exiting Combat"] = true,
		}
		backgroundIdDropdown.choices = CST.events[CSE].arguments.Ids
		backgroundIdDropdown.selection = HT_pickAnyElement(CST.events[CSE].arguments.Ids)
		backgroundIdDropdown:updateDropdown()
		backgroundIdDropdown:SetHidden(visibilityConditions[CST.events[CSE].type])
	end

	local addIdEditbox = createEditbox(backgroundIdDropdown,"addIdEditbox",175,30,0,0,BOTTOM,TOP,function(_) end,nil,nil,"Ids")
	addIdEditbox.Update = function()

	end

	createButton(backgroundIdDropdown,"buttonDeleteID",30,30,0,0,LEFT,RIGHT,function()
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		HT_removeElementFromTable(CST.events[CSE].arguments.Ids,dropdown.selection)
		backgroundIdDropdown.choices = CST.events[CSE].arguments.Ids
		backgroundIdDropdown.selection = HT_pickAnyElement(CST.events[CSE].arguments.Ids)
		backgroundIdDropdown:updateDropdown()
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end, nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",nil)

	createButton(addIdEditbox,"buttonAddID",30,30,0,0,LEFT,RIGHT,function()
		table.insert(CST.events[CSE].arguments.Ids,(tonumber(editbox:GetText()) or GetAbilityIdFromName(editbox:GetText())))
		backgroundIdDropdown.choices = CST.events[CSE].arguments.Ids
		backgroundIdDropdown.selection = HT_pickAnyElement(CST.events[CSE].arguments.Ids)
		backgroundIdDropdown:updateDropdown()
	end,nil,"/esoui/art/buttons/plus_up.dds",nil)

	local arg1Editbox = createEditbox(eventBackground,"arg1Editbox",50,30,270,170,TOPLEFT,TOPLEFT,function(thisEditbox)
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.events[CSE].arguments.cooldown = thisEditbox:GetText()
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.events[CSE].arguments.cooldown,TEXT_TYPE_NUMERIC,"Cooldown")
	arg1Editbox.Update = function()
		local visibilityConditions = {
			["Get Effect Duration"] = true,
			["Get Effect Cooldown"] = false,
			["Entering/Exiting Combat"] = true,
		}
		arg1Editbox:SetText(CST.events[CSE].arguments.cooldown or 0)
		arg1Editbox:SetHidden(visibilityConditions[CST.events[CSE].type])
	end

	local onlyYourCastCheckbox = createCheckbox(eventBackground,"onlyYourCastCheckbox", 30,30,60,175,TOPLEFT,TOPLEFT,CST.events[CSE].arguments.onlyYourCast,function(arg)
		if CST ~= "none" then
			CST.events[CSE].arguments.onlyYourCast = arg
		end
	end, "Only your cast")
	onlyYourCastCheckbox.UpdateCheckbox = function()
		local visibilityConditions = {
			["Get Effect Duration"] = false,
			["Get Effect Cooldown"] = false,
			["Entering/Exiting Combat"] = true,
		}
		onlyYourCastCheckbox:Update(CST.events[CSE].arguments.onlyYourCast)
		onlyYourCastCheckbox:SetHidden(visibilityConditions[CST.events[CSE].type])
	end

	local overwriteShorterDurationCheckbox = createCheckbox(eventBackground,"overwriteShorterDurationCheckbox", 30,30,60,205,TOPLEFT,TOPLEFT,CST.events[CSE].arguments.overwriteShorterDuration,function(arg)
	if CST ~= "none" then
		CST.events[CSE].arguments.overwriteShorterDuration = arg
	end
	end,"Don't overwrite effects when shorter duration is applied")
	overwriteShorterDurationCheckbox.UpdateCheckbox = function()
		local visibilityConditions = {
			["Get Effect Duration"] = false,
			["Get Effect Cooldown"] = true,
			["Entering/Exiting Combat"] = true,
		}
		overwriteShorterDurationCheckbox:Update(CST.events[CSE].arguments.overwriteShorterDuration or true)
		overwriteShorterDurationCheckbox:SetHidden(visibilityConditions[CST.events[CSE].type])
	end

	local dontUpdateFromThisEventCheckbox = createCheckbox(eventBackground,"dontUpdateFromThisEventCheckbox", 30,30,60,650,TOPLEFT,TOPLEFT,CST.events[CSE].arguments.dontUpdateFromThisEvent,function(arg)
	if CST ~= "none" then
		CST.events[CSE].arguments.dontUpdateFromThisEvent = arg
	end
	end,"Don't update duration and stacks from this event (ignore original code and run only custom one)")
	dontUpdateFromThisEventCheckbox.UpdateCheckbox = function()
		dontUpdateFromThisEventCheckbox:Update(CST.events[CSE].arguments.dontUpdateFromThisEvent)
		local visibilityConditions = {
			["Get Effect Duration"] = false,
			["Get Effect Cooldown"] = false,
			["Entering/Exiting Combat"] = true,
		}
		dontUpdateFromThisEventCheckbox:SetHidden(visibilityConditions[CST.events[CSE].type])
	end

	local eventTypeDropdown = createDropdown(eventBackground,"eventTypeDropdown",200,30,50,140,TOPLEFT,TOPLEFT,getKeysFromTable(HT_eventFunctions),CST.events[CSE].type,function(selection)
	if CST.name ~= "none" then
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.events[CSE].type = selection
		if selection == "Get Effect Cooldown" then
			arg1Editbox:SetHidden(false)
			arg1Editbox:SetText(CST.events[CSE].arguments.cooldown)
			overwriteShorterDurationCheckbox:SetHidden(true)
		elseif selection == "Get Effect Duration" then
			onlyYourCastCheckbox:Update(CST.events[CSE].arguments.onlyYourCast)
			overwriteShorterDurationCheckbox:SetHidden(false)
			overwriteShorterDurationCheckbox:Update(CST.events[CSE].arguments.overwriteShorterDuration)
			arg1Editbox:SetHidden(true)
		end
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end
	end,"Event Type")
	eventTypeDropdown.Update = function()
		eventTypeDropdown.selection = CST.events[CSE].type
		eventTypeDropdown:updateDropdown()
	end

	createTexture(eventBackground,"edge37",165,2,15,272.5,TOPLEFT,TOPLEFT,"")
	createLabel(eventBackground,"displayLabel2",150,30,180,260,TOPLEFT,TOPLEFT,"ADVANCED",1,1,"BOLD_FONT",26)
	createTexture(eventBackground,"edge47",165,2,330,272.5,TOPLEFT,TOPLEFT,"")

	local luaCodeEditbox = createMultilineEditbox(eventBackground,"luaCodeEditbox",400,300,50,320,TOPLEFT,TOPLEFT,function(thisEditbox)
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.events[CSE].arguments.luaCodeToExecute = thisEditbox:GetText()
		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):Update(HT_getTrackerFromName(CST.parent,HTSV.trackers)) else HT_findContainer(CST):Update(CST) end
	end,CST.events[CSE].arguments.luaCodeToExecute,nil,"Custom Lua Code executed every time event fires")
	luaCodeEditbox.Update = function()
		luaCodeEditbox:SetText(CST.events[CSE].arguments.luaCodeToExecute)
	end

	local eventsDropdown = createDropdown(eventBackground,"eventsDropdown",200,30,50,70,TOPLEFT,TOPLEFT,getKeysFromTable(CST.events),CSE,function(selection)
	CSE = selection
	if CST.events[CSE].type == "Get Effect Cooldown" then
		arg1Editbox:SetHidden(false)
		arg1Editbox:SetText(CST.events[CSE].arguments.cooldown)
	else
		arg1Editbox:SetHidden(true)
	end
	eventTypeDropdown.selection = CST.events[CSE].type
	eventTypeDropdown:updateDropdown()
	end,"Select/Add Event")
	eventsDropdown.Update = function()
		eventsDropdown.choices = getKeysFromTable(CST.events)
		eventsDropdown.selection = HT_pickAnyKey(CST.events)
		eventsDropdown:updateDropdown()
	end

	createButton(eventsDropdown,"button",30,30,0,0,RIGHT,LEFT,function()
	table.insert(CST.events,{
	type = "Get Effect Duration",
	arguments = {
		cooldown = 0,
		onlyYourCast = false,
		overwriteShorterDuration = false,
		luaCodeToExecute = "",
		Ids = {},
	}
	})
		backgroundIdDropdown.choices = getKeysFromTable(CST.events)
		backgroundIdDropdown.selection = CSC
		backgroundIdDropdown:updateDropdown()
	relocateLeftSide()
	end,nil,"esoui/art/buttons/plus_up.dds",false)

	createButton(eventsDropdown,"deleteButton",30,30,0,0,LEFT,RIGHT,function()

		if CST.parent ~= "HT_Trackers" and HT_getTrackerFromName(CST.parent,HTSV.trackers).type == "Group Member" then HT_findContainer(HT_getTrackerFromName(CST.parent,HTSV.trackers)):UnregisterEvents() else HT_findContainer(CST):UnregisterEvents() end
		CST.events[CSE] = nil
		backgroundIdDropdown.choices = getKeysFromTable(CST.events)
		backgroundIdDropdown.selection = HT_pickAnyKey(CST.events)
		backgroundIdDropdown:updateDropdown()
		relocateLeftSide()
	end,nil,"/esoui/art/miscellaneous/spinnerminus_up.dds",false)

	eventBackground.Update = function()
		local eventButton = selectedTrackerSettingsBackdrop:GetNamedChild("button11")
		if settingsVariables.currentRightSideEdit == "eventBackground" then
			eventBackground:SetHidden(false)
			eventButton.backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
		else
			eventBackground:SetHidden(true)
			eventButton.backdrop:SetEdgeColor(0.2, 0.7, 0.1, 1)
		end
		backgroundIdDropdown:Update()
		addIdEditbox:Update()
		arg1Editbox:Update()
		onlyYourCastCheckbox:UpdateCheckbox()
		overwriteShorterDurationCheckbox:UpdateCheckbox()
		dontUpdateFromThisEventCheckbox:UpdateCheckbox()
		eventTypeDropdown:Update()
		luaCodeEditbox:Update()
		eventsDropdown:Update()
	end
	--------- EVENTS -------------


	------ BACKGROUND ON THE RIGHT WHERE U CHANGE SETTINGS OF SELECTED TRACKERS ----------------

	relocateLeftSide()
	HT_Settings:ClearAnchors()
	HT_Settings:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,0,0)
	SCENE_MANAGER:GetScene("hud"):RegisterCallback("StateChange", onSceneChange)
	SCENE_MANAGER:GetScene("hudui"):RegisterCallback("StateChange", onSceneChange)
end

