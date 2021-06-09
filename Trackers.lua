WM = GetWindowManager()


local function DisplayGroupControl(number)
	if not DoesUnitExist("group"..number) then return true end
	if IsUnitDead("group"..number) then return true end
	if GetUnitName("group"..number) == GetUnitName("player") then return true end
	if GetGroupMemberSelectedRole("group"..number) == 0 then return true end
	if GetUnitZoneIndex("group"..number) ~= GetUnitZoneIndex("player") then return true end
	return false
end



local function createProgressBar(parent,t)

	local container,bar,backdrop,label,icon,animationTexture,timer,stacks,iconOutline


	if parent:GetNamedChild(t.name.."_Progress Bar") then 
		container = parent:GetNamedChild(t.name.."_Progress Bar")
		backdrop = container:GetNamedChild("backdrop")
		icon = container:GetNamedChild("icon")
		bar = icon:GetNamedChild("bar")
		label = container:GetNamedChild("label")
		timer = container:GetNamedChild("timer")
		stacks = icon:GetNamedChild("stacks")
		iconOutline = icon:GetNamedChild("iconOutline")
		
	else
		container = createContainer(parent,t.name.."_Progress Bar",t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
		backdrop = WM:CreateControl("$(parent)backdrop",container,  CT_BACKDROP,4)
		icon = createTexture(container,"icon",t.sizeY-(t.outlineThickness*2),t.sizeY-(t.outlineThickness*2),0,0,CENTER,CENTER,t.icon)
		bar = createTexture(icon,"bar",t.sizeX-t.sizeY-t.outlineThickness,t.sizeY,t.outlineThickness,0,LEFT,RIGHT)
		label = createLabel(container,"label",t.sizeX-t.sizeY,t.sizeY,(t.sizeX/20)+t.sizeY,0,LEFT,LEFT,t.text,0,1,t.font,t.fontSize,"thick-outline")
		timer = createLabel(container,"timer",t.sizeX-t.sizeY,t.sizeY,t.sizeX/(-20),0,RIGHT,RIGHT,"0.0",2,1,t.font,t.fontSize,"thick-outline")
		stacks = createLabel(icon,"stacks",t.sizeY-t.outlineThickness,t.sizeY-t.outlineThickness,0,0,TOPLEFT,TOPLEFT,"0",1,1,t.font,t.fontSize,"thick-outline")
		iconOutline = WM:CreateControl("$(parent)iconOutline",icon,  CT_TEXTURE,4)
	end
	
	container:SetHandler("OnMoveStop", function(control)
        t.xOffset = container:GetLeft() - parent:GetLeft()
	    t.yOffset  = container:GetTop() - parent:GetTop()
		container:ClearAnchors()
		container:SetAnchor(TOPLEFT,parent,TOPLEFT,t.xOffset,t.yOffset)
    end)
	
	iconOutline:SetAnchor(LEFT,icon,RIGHT,0,0)
	iconOutline:SetTexture("")
	container:SetMovable(true)
	container:SetMouseEnabled(true)
	container.delete = false
	local function Process(self,targetOverride)
		if HT_processLoad(t.load) then
			local override = {
				text = t.text,
				barColor = t.barColor,
				textColor = t.textColor,
				timeColor = t.timeColor,
				stacksColor = t.stacksColor,
				backgroundColor = t.backgroundColor,
				outlineColor = t.outlineColor,
				show = true,
				targetNumber = targetOverride or t.targetNumber,
				target = t.target,
			}
			if targetOverride then
				override.target = "Group"
			end
			for _,condition in pairs(t.conditions) do
				if operators[condition.operator](conditionArgs1[condition.arg1](t,override),condition.arg2) then conditionResults[condition.result](override,condition.resultArguments) end
			end

			if targetOverride then
				container:SetHidden(not override.show or DisplayGroupControl(targetOverride))
			else
				container:SetHidden(not override.show)
			end
			local barX = t.sizeX-t.sizeY
			local barY = t.sizeY
			local remainingTime = math.max((t.expiresAt[HT_targets[override.target](override.targetNumber)] or 0) - GetGameTimeSeconds(),0)
			local duration = math.max((t.duration[HT_targets[override.target](override.targetNumber)] or 0),0)
			local stacksCount = t.stacks[HT_targets[override.target](override.targetNumber)] or 0
			if remainingTime == 0 then
				bar:SetDimensions(0,barY)
				stacksCount = 0
			else
				bar:SetDimensions(barX*(remainingTime/duration),barY)
			end
			--d(remainingTime)
			bar:SetColor(unpack(override.barColor))
			timer:SetText(getDecimals(remainingTime,t.decimals))
			label:SetText(override.text)
			stacks:SetText(stacksCount)
		else
			container:SetHidden(true)
		end
	end




	local function Update(self,t,groupAnchor)
		if t.parent == "HT_Trackers" and not container.delete then
			EVENT_MANAGER:RegisterForUpdate("HT_ProgressBar"..t.name, 100,Process)
			
		end

		for key,event in pairs(t.events) do
			for _,ID in pairs(t.IDs) do
				HT_eventFunctions[event.type]("HT"..key..t.name..ID,ID,t,event.arguments)
			end
		end


		container:SetDimensions(t.sizeX,t.sizeY)
		icon:SetDimensions(t.sizeY,t.sizeY)
		icon:SetTexture(t.icon)
		if t.hideIcon then
			icon:SetDimensions(0,0)
		end
		backdrop:SetCenterColor(unpack(t.backgroundColor))
		backdrop:ClearAnchors()
		backdrop:SetAnchor(CENTER,container,CENTER,0,0)
		backdrop:SetDimensions(t.sizeX+(t.outlineThickness*2),t.sizeY+(t.outlineThickness*2))
		backdrop:SetEdgeColor(unpack(t.outlineColor))
		backdrop:SetEdgeTexture("",  t.outlineThickness, t.outlineThickness)
		iconOutline:SetDimensions(t.outlineThickness,t.sizeY)
		iconOutline:SetColor(unpack(t.outlineColor))
		bar:SetColor(unpack(t.barColor))
		label:SetDimensions(t.sizeX-t.sizeY,t.sizeY)
		label:SetText(t.text)
		label:SetFont(string.format("$(%s)|$(KB_%s)|%s",t.font, t.fontSize, t.fontWeight))
		label:SetColor(unpack(t.textColor))
		stacks:SetDimensions(t.sizeY,t.sizeY)
		stacks:SetFont(string.format("$(%s)|$(KB_%s)|%s",t.font, t.fontSize,t.fontWeight))
		stacks:SetColor(unpack(t.stacksColor))
		timer:SetDimensions(t.sizeX-t.sizeY,t.sizeY)
		timer:SetFont(string.format("$(%s)|$(KB_%s)|%s",t.font, t.fontSize,t.fontWeight))
		timer:SetColor(unpack(t.timeColor))
		if t.inverse then
			icon:ClearAnchors()
			icon:SetAnchor(TOPRIGHT,container,TOPRIGHT,0,0)
			bar:ClearAnchors()
			bar:SetAnchor(RIGHT,icon,LEFT,0,0)
			label:ClearAnchors()
			label:SetAnchor(RIGHT,container,RIGHT,(t.sizeX/20)-t.sizeY,0)
			timer:ClearAnchors()
			timer:SetAnchor(LEFT,container,LEFT,t.sizeX/-20,0)
		else
			icon:ClearAnchors()
			icon:SetAnchor(TOPLEFT,container,TOPLEFT,0,0)
			bar:ClearAnchors()
			bar:SetAnchor(LEFT,icon,RIGHT,0,0)
			label:ClearAnchors()
			label:SetAnchor(LEFT,container,LEFT,(t.sizeX/20)+t.sizeY,0)
			timer:ClearAnchors()
			timer:SetAnchor(RIGHT,container,RIGHT,(t.sizeX/-20),0)
		end
		container:ClearAnchors()

		if t.parent == "HT_Trackers" then
			container:SetAnchor(TOPLEFT,HT_Trackers,TOPLEFT,t.xOffset,t.yOffset)
		elseif getTrackerFromName(t.parent,HTSV.trackers).type == "Group Member" and groupAnchor then
			container:SetAnchor(TOPLEFT,HT_findContainer(getTrackerFromName(t.parent,HTSV.trackers)):GetNamedChild(getTrackerFromName(t.parent,HTSV.trackers).name.."Group"..groupAnchor),TOPLEFT,t.xOffset,t.yOffset)
		else
			container:SetAnchor(TOPLEFT,HT_findContainer(getTrackerFromName(t.parent,HTSV.trackers)),TOPLEFT,t.xOffset,t.yOffset)
		end
		timer:SetHidden(not t.timer1)
		stacks:SetHidden(not t.timer2)
	end
	container.Update = Update
	container:Update(t)


	container.Process = Process

	local function UnregisterEvents(self)
		for key,event in pairs(t.events) do
			for _,ID in pairs(t.IDs) do
				HT_unregisterEventFunctions[event.type]("HT"..key..t.name..ID)
			end
		end
	end
	container.UnregisterEvents = UnregisterEvents


	local function Delete(self)
		self:UnregisterEvents()
		EVENT_MANAGER:UnregisterForUpdate("HT_ProgressBar"..t.name, 100)
		container.delete = true
		self:SetHidden(true)
	end
	container.Delete = Delete


	

	return container
end


--[[
local function createResourceBar(parent,t)
	local container = createContainer(parent,t.name,t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
	local backdrop = WM:CreateControl("$(parent)backdrop",container,  CT_BACKDROP,4)
	local bar = createTexture(container,"bar",t.sizeX,t.sizeY,0,0,TOPLEFT,TOPLEFT)
	local label = createLabel(bar,"label",t.sizeX,t.sizeY,(t.sizeX/-20)*(t.textAlignment-1),0,TOPLEFT,TOPLEFT,t.text,t.textAlignment,1,t.font,t.fontSize,"thick-outline")
	container:SetHandler("OnMoveStop", function(control)
        t.xOffset = container:GetLeft()
	    t.yOffset  = container:GetTop()
		container:ClearAnchors()
		container:SetAnchor(TOPLEFT,parent,TOPLEFT,t.xOffset,t.yOffset)
    end)
	container:SetMovable(true)
	container:SetMouseEnabled(true)
	local function Update(self,t)
		container:SetDimensions(t.sizeX,t.sizeY)
		backdrop:SetCenterColor(unpack(t.backgroundColor))
		backdrop:ClearAnchors()
		backdrop:SetAnchor(CENTER,container,CENTER,0,0)
		backdrop:SetDimensions(t.sizeX+(t.outlineThickness*2),t.sizeY+(t.outlineThickness*2))
		backdrop:SetEdgeColor(unpack(t.outlineColor))
		backdrop:SetEdgeTexture("",  t.outlineThickness, t.outlineThickness)
		bar:SetDimensions(t.sizeX,t.sizeY)
		bar:SetColor(unpack(t.color1))
		label:SetHorizontalAlignment(t.textAlignment)
		label:SetDimensions(t.sizeX,t.sizeY)
		label:SetFont(string.format("$(%s)|$(KB_%s)|%s",t.font, t.fontSize, "thick-outline"))
		label:SetAnchor(TOPLEFT,bar,TOPLEFT,(t.sizeX/-20)*(t.textAlignment-1),0)
		container:ClearAnchors()
		if t.parent == "HT_Trackers" then
			container:SetAnchor(TOPLEFT,HT_Trackers,TOPLEFT,t.xOffset,t.yOffset)
		else
			container:SetAnchor(TOPLEFT,HT_findContainer(getTrackerFromName(t.parent,HTSV.trackers)),TOPLEFT,t.xOffset,t.yOffset)
		end
	end
	container.Update = Update
end]]




--layer
--level
--tier

local function createIconTracker(parent,t)
	
	local container,icon,background,animationTexture,timer,stacks

	if parent:GetNamedChild(t.name.."_Icon Tracker") then 
		container = parent:GetNamedChild(t.name.."_Icon Tracker")
		icon = container:GetNamedChild("icon")
		background = container:GetNamedChild("background")
		timer = icon:GetNamedChild("timer")
		stacks = icon:GetNamedChild("stacks")
		animationTexture = icon:GetNamedChild("animationTexture")
		outline = container:GetNamedChild("outline")
	else
		container = createContainer(parent,t.name.."_Icon Tracker",t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
		icon = createTexture(container,"icon",t.sizeX,t.sizeY,1,1,TOPLEFT,TOPLEFT,t.icon)
		background = WM:CreateControl("$(parent)background",container,  CT_TEXTURE,4)
		timer = createLabel(icon,"timer",t.sizeX,t.sizeY/2,0,0,BOTTOM,BOTTOM,"0.0",1,1,t.font,t.fontSize,"thick-outline")
		stacks = createLabel(icon,"stacks",t.sizeX,t.sizeY/2,0,0,TOP,TOP,"0.0",1,1,t.font,t.fontSize,"thick-outline")
		animationTexture = WM:CreateControl("$(parent)animationTexture",icon,  CT_TEXTURE, 4)
		outline = WM:CreateControl("$(parent)outline",container,  CT_BACKDROP,4)
	end
	local timeline = ANIMATION_MANAGER:CreateTimeline()
	local animation = timeline:InsertAnimation(ANIMATION_TEXTURE, animationTexture)
	background:ClearAnchors()
	background:SetAnchor(CENTER,icon,CENTER,0,0)
	background:SetTexture("HyperTools/icons/regularBackground.dds")
	--background:SetDrawLayer(2)
	--icon:SetDrawLayer(3)

	animationTexture:ClearAnchors()
	animationTexture:SetAnchor(CENTER,icon,CENTER,0,0)
	animationTexture:SetAnchorFill()
	--animationTexture:SetDrawTier(2)
	animationTexture:SetHidden(true)
	animationTexture:SetTexture("/esoui/art/actionbar/abilityhighlight_mage_med.dds")

	
	animation:SetImageData(64,1)
	animation:SetFramerate(64)
	timeline:SetEnabled(true)
	timeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
	timeline:PlayFromStart()

	outline:SetAnchor(CENTER,icon,CENTER,0,0)
	--outline:SetDrawTier(3)

	container:SetHandler("OnMoveStop", function(control)
        t.xOffset = container:GetLeft() - parent:GetLeft()
	    t.yOffset  = container:GetTop() - parent:GetTop()
		container:ClearAnchors()
		container:SetAnchor(TOPLEFT,parent,TOPLEFT,t.xOffset,t.yOffset)
    end)
	
	container.timer = timer
	container.stacks = stacks
	container:SetMovable(true)
	container:SetMouseEnabled(true)


	local function Process(self,targetOverride)
		if HT_processLoad(t.load) then
			
			local override = {
				text = t.text,
				barColor = t.barColor,
				textColor = t.textColor,
				timeColor = t.timeColor,
				stacksColor = t.stacksColor,
				backgroundColor = t.backgroundColor,
				outlineColor = t.outlineColor,
				show = true,
				targetNumber = targetOverride or t.targetNumber,
				showProc = false,
				target = t.target
			}
			if targetOverride then
				override.target = "Group"
			end
			for _,condition in pairs(t.conditions) do
				if operators[condition.operator](conditionArgs1[condition.arg1](t,override),condition.arg2) then conditionResults[condition.result](override,condition.resultArguments) end
			end
			if targetOverride then
				container:SetHidden(not override.show or DisplayGroupControl(targetOverride))
			else
				container:SetHidden(not override.show)
			end
			local remainingTime = math.max((t.expiresAt[HT_targets[override.target](override.targetNumber)] or 0) - GetGameTimeSeconds(),0)
			local stacksCount = t.stacks[HT_targets[override.target](override.targetNumber)] or 0
			if remainingTime == 0 then
				stacksCount = 0
			end
			timer:SetColor(unpack(override.timeColor))
			timer:SetText(getDecimals(remainingTime,t.decimals))
			stacks:SetColor(unpack(override.stacksColor))
			stacks:SetText(stacksCount)
			icon:SetColor(unpack(override.barColor))
			animationTexture:SetHidden(not override.showProc)
		else
			container:SetHidden(true)
		end
	end


	local function Update(self,data,groupAnchor)
		--if data.parent == "HT_Trackers" then
			EVENT_MANAGER:RegisterForUpdate("HT_IconTracker"..data.name, 100,Process)
			
		--end

		for key,event in pairs(data.events) do
			for _,ID in pairs(data.IDs) do
				HT_eventFunctions[event.type]("HT"..key..data.name..ID,ID,t,event.arguments)
			end
		end

		container:SetDrawLayer(data.drawLevel)
		container:SetDimensions(data.sizeX,data.sizeY)
		icon:SetDimensions(data.sizeX,data.sizeY)
		icon:SetTexture(data.icon)
		outline:SetDimensions(data.sizeX+(data.outlineThickness*2),data.sizeY+(data.outlineThickness*2))
		outline:SetEdgeColor(unpack(data.outlineColor))
		outline:SetCenterColor(0,0,0,0)
		outline:SetEdgeTexture("",  data.outlineThickness, data.outlineThickness)
		background:SetDimensions(data.sizeX*1.2,data.sizeY*1.2)
		background:SetColor(unpack(data.backgroundColor))
		timer:SetFont(string.format("$(%s)|$(KB_%s)|%s",data.font, data.fontSize,data.fontWeight))
		stacks:SetFont(string.format("$(%s)|$(KB_%s)|%s",data.font, data.fontSize, data.fontWeight))
		container:ClearAnchors()
		if data.parent == "HT_Trackers" then
			container:SetAnchor(TOPLEFT,HT_Trackers,TOPLEFT,data.xOffset,data.yOffset)
		elseif getTrackerFromName(data.parent,HTSV.trackers).type == "Group Member" and groupAnchor then
			container:SetAnchor(TOPLEFT,HT_findContainer(getTrackerFromName(data.parent,HTSV.trackers)):GetNamedChild(getTrackerFromName(data.parent,HTSV.trackers).name.."Group"..groupAnchor),TOPLEFT,data.xOffset,data.yOffset)
		else
			container:SetAnchor(TOPLEFT,HT_findContainer(getTrackerFromName(data.parent,HTSV.trackers)),TOPLEFT,data.xOffset,data.yOffset)
		end
		if data.timer1 and data.timer2 then
			timer:SetDimensions(data.sizeX,data.sizeY/2)
			stacks:SetDimensions(data.sizeX,data.sizeY/2)
		else
			timer:SetDimensions(data.sizeX,data.sizeY)
			stacks:SetDimensions(data.sizeX,data.sizeY)
		end
		timer:SetHidden(not data.timer1)
		stacks:SetHidden(not data.timer2)
	end
	container.Update = Update
	container:Update(t)
	container.Process = Process
	
	local function UnregisterEvents(self)
		for key,event in pairs(t.events) do
			for _,ID in pairs(t.IDs) do
				HT_unregisterEventFunctions[event.type]("HT"..key..t.name..ID)
			end
		end
	end
	container.UnregisterEvents = UnregisterEvents

	local function Delete(self)
		self:UnregisterEvents()
		EVENT_MANAGER:UnregisterForUpdate("HT_IconTracker"..t.name, 100)
		self:SetHidden(true)
	end
	container.Delete = Delete


	return container
end


local function createGroup(parent,t,i)

	local container,backdrop

	if parent:GetNamedChild(t.name.."_Group"..(i or "")) then 
		container = parent:GetNamedChild(t.name.."_Group"..(i or ""))
		backdrop = container:GetNamedChild("backdrop")
	else
		container = createContainer(parent,t.name.."_Group"..(i or ""),t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
		backdrop = WM:CreateControl("$(parent)backdrop",container,  CT_BACKDROP, 4)
	end


	container:SetHandler("OnMoveStop", function(control)
		if i then
			t.xOffset = container:GetLeft() - HT_3D:GetNamedChild(i):GetLeft()
			t.yOffset  = container:GetTop() - HT_3D:GetNamedChild(i):GetTop()
			container:ClearAnchors()
			container:SetAnchor(TOPLEFT,HT_3D:GetNamedChild(i),TOPLEFT,t.xOffset,t.yOffset)
			HT_findContainer(t):Update(t)
		else
			t.xOffset = container:GetLeft() - parent:GetLeft()
			t.yOffset  = container:GetTop() - parent:GetTop()
			container:ClearAnchors()
			container:SetAnchor(TOPLEFT,parent,TOPLEFT,t.xOffset,t.yOffset)
		end
		
    end)
	


	container:SetMovable(true)
	container:SetMouseEnabled(true)
	for _,childName in pairs(t.children) do
		initializeTrackerFunctions[childName.type](container,childName)
	end

	local function Process(self,targetOverride)
		if HT_processLoad(t.load) then
			local override = {
				text = t.text,
				barColor = t.barColor,
				textColor = t.textColor,
				timeColor = t.timeColor,
				stacksColor = t.stacksColor,
				backgroundColor = t.backgroundColor,
				outlineColor = t.outlineColor,
				show = true,
				targetNumber = targetOverride or i or t.targetNumber
			}
			for _,condition in pairs(t.conditions) do
				if operators[condition.operator](conditionArgs1[condition.arg1](t,override),condition.arg2) then conditionResults[condition.result](override,condition.resultArguments) end
			end

			if i then
				container:SetHidden(not override.show or DisplayGroupControl(i))
				override.target = "Group"
			else
				container:SetHidden(not override.show)
			end

			for _,childName in pairs(t.children) do
				HT_findContainer(childName,i):Process(i)
			
			end
		else
			container:SetHidden(true)
		end
	end
	local function Update(self,t,groupAnchor)
		for _,childName in pairs(t.children) do
			if not HT_findContainer(childName,i) then initializeTrackerFunctions[childName.type](container,childName) end
		end
		if t.parent == "HT_Trackers" then
			EVENT_MANAGER:RegisterForUpdate("HT_Group"..t.name..(i or ""), 100,Process)
			
		end

		for key,event in pairs(t.events) do
			for _,ID in pairs(t.IDs) do
				HT_eventFunctions[event.type]("HT"..key..t.name..ID,ID,t,event.arguments)
			end
		end



		container:SetDimensions(t.sizeX,t.sizeY)
		container:ClearAnchors()
		backdrop:SetCenterColor(unpack(t.backgroundColor))
		backdrop:ClearAnchors()
		backdrop:SetAnchor(CENTER,container,CENTER,0,0)
		backdrop:SetDimensions(t.sizeX+(t.outlineThickness*2),t.sizeY+(t.outlineThickness*2))
		backdrop:SetEdgeColor(unpack(t.outlineColor))
		backdrop:SetEdgeTexture("",  t.outlineThickness, t.outlineThickness)

		if groupAnchor then
			container:SetAnchor(TOPLEFT,HT_3D:GetNamedChild(groupAnchor),TOPLEFT,t.xOffset,t.yOffset)
			container:SetHidden(DisplayGroupControl(groupAnchor))
		elseif t.parent == "HT_Trackers" then
			container:SetAnchor(TOPLEFT,HT_Trackers,TOPLEFT,t.xOffset,t.yOffset)
		else
			container:SetAnchor(TOPLEFT,HT_findContainer(getTrackerFromName(t.parent,HTSV.trackers)),TOPLEFT,t.xOffset,t.yOffset)
		end
		for _,childName in pairs(t.children) do
			HT_findContainer(childName,i):Update(childName,groupAnchor)
		end
	end
	container.Update = Update
	container:Update(t)
	container.Process = Process

	local function UnregisterEvents(self)
		for key,event in pairs(t.events) do
			for _,ID in pairs(t.IDs) do
				HT_unregisterEventFunctions[event.type]("HT"..key..t.name..ID)
			end
		end
		for _,childName in pairs(t.children) do
			HT_findContainer(childName,i):UnregisterEvents()
		end
	end
	container.UnregisterEvents = UnregisterEvents

	local function Delete(self)
		self:UnregisterEvents()
		EVENT_MANAGER:UnregisterForUpdate("HT_Group"..t.name..(i or ""), 100)
		self:SetHidden(true)
		for _,childName in pairs(t.children) do
			HT_findContainer(childName,i):Delete()
		end
	end
	container.Delete = Delete





	return container
end







local function createGroupMemberGroup(parent,t)

	local container

	if parent:GetNamedChild(t.name.."_Group Member") then 
		container = parent:GetNamedChild(t.name.."_Group Member")
	else
		container = createContainer(parent,t.name.."_Group Member",0,0,0,0,TOPLEFT,TOPLEFT)
	end


	container.group = {}
	for i=1,12 do
		local newGroup = createGroup(parent,t,i)

		container.group[i] = newGroup
	end

	local function Process()
		if HT_processLoad(t.load) then
			for i=1,12 do 
				container.group[i]:Process()
			end
		else
			container:SetHidden(true)
		end
	end
	container.Process = Process
	local function Update(self,t)
		for i=1,12 do 
			container.group[i]:Update(t,i)
		end
	end
	container.Update = Update
	container:Update(t)
	local function Delete(self)
		for i=1,12 do 
			container.group[i]:Delete()
		end
	end

	local function UnregisterEvents(self)
		for i=1,12 do 
			container.group[i]:UnregisterEvents()
		end
	end
	container.UnregisterEvents = UnregisterEvents
	container.Delete = Delete



	return container
end




initializeTrackerFunctions = {
	["Icon Tracker"] = createIconTracker,
	["Progress Bar"] = createProgressBar,
	["Group"] = createGroup,
	["Resource Bar"] = createResourceBar,
	["Group Member"] = createGroupMemberGroup,
}