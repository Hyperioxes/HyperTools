WM = GetWindowManager()


local function DisplayGroupControl(number)
	if not DoesUnitExist("group"..number) then return true end
	if IsUnitDead("group"..number) then return true end
	return false
end



local function createProgressBar(parent,t)
	if parent:GetNamedChild(t.name.."_Progress Bar") then 
		local container = parent:GetNamedChild(t.name.."_Progress Bar")
		container:SetHidden(false)
		container.delete = false
		container:Update(t)
		return nil 
	end
	local container = createContainer(parent,t.name.."_Progress Bar",t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
	local backdrop = WM:CreateControl("$(parent)backdrop",container,  CT_BACKDROP,4)
	local icon = createTexture(container,"icon",t.sizeY-(t.outlineThickness*2),t.sizeY-(t.outlineThickness*2),0,0,CENTER,CENTER,t.icon)
	local bar = createTexture(icon,"bar",t.sizeX-t.sizeY-t.outlineThickness,t.sizeY,t.outlineThickness,0,LEFT,RIGHT)
	local label = createLabel(container,"label",t.sizeX-t.sizeY,t.sizeY,(t.sizeX/20)+t.sizeY,0,LEFT,LEFT,t.text,0,1,t.font,t.fontSize,"thick-outline")
	local timer = createLabel(container,"timer",t.sizeX-t.sizeY,t.sizeY,t.sizeX/(-20),0,RIGHT,RIGHT,"0.0",2,1,t.font,t.fontSize,"thick-outline")
	local stacks = createLabel(icon,"stacks",t.sizeY-t.outlineThickness,t.sizeY-t.outlineThickness,0,0,TOPLEFT,TOPLEFT,"0",1,1,t.font,t.fontSize,"thick-outline")
	container:SetHandler("OnMoveStop", function(control)
        t.xOffset = container:GetLeft() - parent:GetLeft()
	    t.yOffset  = container:GetTop() - parent:GetTop()
		updateLeftSide()
		container:ClearAnchors()
		container:SetAnchor(TOPLEFT,parent,TOPLEFT,t.xOffset,t.yOffset)
    end)
	local iconOutline = WM:CreateControl("$(parent)iconOutline",icon,  CT_TEXTURE,4)
	iconOutline:SetAnchor(LEFT,icon,RIGHT,0,0)
	iconOutline:SetTexture("")
	container:SetMovable(true)
	container:SetMouseEnabled(true)
	container.delete = false
	local function Process(self,previousTarget,groupNumber)
		local override = {
			text = groupNumber,
			barColor = t.barColor,
			show = true,
			targetNumber = previousTarget
		}
		for _,condition in pairs(t.conditions) do
			if operators[condition.operator](conditionArgs1[condition.arg1](t),condition.arg2) then conditionResults[condition.result](override,condition.resultArguments) end
		end
		if groupNumber then
			container:SetHidden(DisplayGroupControl(groupNumber))
		else
			container:SetHidden(not override.show)
		end
		local barX = t.sizeX-t.sizeY
		local barY = t.sizeY
		local remainingTime = math.max((t.expiresAt[HT_targets[t.target](override.targetNumber)] or 0) - GetGameTimeSeconds(),0)
		local duration = math.max((t.duration[HT_targets[t.target](override.targetNumber)] or 0),0)
		local stacksCount = t.stacks[HT_targets[t.target](override.targetNumber)] or 0
		if remainingTime == 0 then
			bar:SetDimensions(0,barY)
			stacksCount = 0
		else
			bar:SetDimensions(barX*(remainingTime/duration),barY)
		end
		bar:SetColor(unpack(override.barColor))
		timer:SetText(getDecimals(remainingTime,t.decimals))
		label:SetText(override.text)
		stacks:SetText(stacksCount)
	end




	local function Update(self,t,groupAnchor)
		if t.parent == "HT_Trackers" and not container.delete then
			EVENT_MANAGER:RegisterForUpdate("HT_ProgressBar"..t.name, 100,Process)
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
		elseif HTSV.trackers[t.parent].type == "Group Member" and groupAnchor then
			container:SetAnchor(TOPLEFT,HT_findContainer(HTSV.trackers[t.parent]):GetNamedChild(HTSV.trackers[t.parent].name.."Group"..groupAnchor),TOPLEFT,t.xOffset,t.yOffset)
		else
			container:SetAnchor(TOPLEFT,HT_findContainer(HTSV.trackers[t.parent]),TOPLEFT,t.xOffset,t.yOffset)
		end
		timer:SetHidden(not t.timer1)
		stacks:SetHidden(not t.timer2)
	end
	container.Update = Update
	container:Update(t)


	container.Process = Process

	local function Delete(self)
		EVENT_MANAGER:UnregisterForUpdate("HT_ProgressBar"..t.name, 100)
		container.delete = true
		self:SetHidden(true)
	end
	container.Delete = Delete
	return container
end



local function createResourceBar(parent,t)
	local container = createContainer(parent,t.name,t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
	local backdrop = WM:CreateControl("$(parent)backdrop",container,  CT_BACKDROP,4)
	local bar = createTexture(container,"bar",t.sizeX,t.sizeY,0,0,TOPLEFT,TOPLEFT)
	local label = createLabel(bar,"label",t.sizeX,t.sizeY,(t.sizeX/-20)*(t.textAlignment-1),0,TOPLEFT,TOPLEFT,t.text,t.textAlignment,1,t.font,t.fontSize,"thick-outline")
	container:SetHandler("OnMoveStop", function(control)
        t.xOffset = container:GetLeft()
	    t.yOffset  = container:GetTop()
		updateLeftSide()
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
			container:SetAnchor(TOPLEFT,HT_findContainer(HTSV.trackers[t.parent]),TOPLEFT,t.xOffset,t.yOffset)
		end
	end
	container.Update = Update
end


local function createIconTracker(parent,t)
	if parent:GetNamedChild(t.name.."_Icon Tracker") then 
		local container = parent:GetNamedChild(t.name.."_Icon Tracker")
		container:SetHidden(false)
		container:Update(t)
		return nil 
	end
	local container = createContainer(parent,t.name.."_Icon Tracker",t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
	local icon = createTexture(container,"icon",t.sizeX,t.sizeY,1,1,TOPLEFT,TOPLEFT,t.icon)
	local timer = createLabel(icon,"timer",t.sizeX,t.sizeY/2,0,0,BOTTOM,BOTTOM,"0.0",1,1,t.font,t.fontSize,"thick-outline")
	local stacks = createLabel(icon,"stacks",t.sizeX,t.sizeY/2,0,0,TOP,TOP,"0.0",1,1,t.font,t.fontSize,"thick-outline")
	container:SetHandler("OnMoveStop", function(control)
        t.xOffset = container:GetLeft() - parent:GetLeft()
	    t.yOffset  = container:GetTop() - parent:GetTop()
		updateLeftSide()
		container:ClearAnchors()
		container:SetAnchor(TOPLEFT,parent,TOPLEFT,t.xOffset,t.yOffset)
    end)
	local outline = WM:CreateControl("$(parent)outline",container,  CT_BACKDROP,4)
	outline:SetAnchor(CENTER,container,CENTER,0,0)
	outline:SetCenterColor(0,0,0,0)
	container.timer = timer
	container.stacks = stacks
	container:SetMovable(true)
	container:SetMouseEnabled(true)


	local function Process(override)
		local override = override or {
			text = t.text,
			barColor = t.barColor,
			show = true,
			targetNumber = t.targetNumber
		}
		for _,condition in pairs(t.conditions) do
			if operators[condition.operator](conditionArgs1[condition.arg1](t),condition.arg2) then conditionResults[condition.result](override,condition.resultArguments) end
		end
		container:SetHidden(not override.show)
		local remainingTime = math.max((t.expiresAt[HT_targets[t.target]()] or 0) - GetGameTimeSeconds(),0)
		local stacksCount = t.stacks[HT_targets[t.target]()] or 0
		if remainingTime == 0 then
			stacksCount = 0
		end
		timer:SetColor(unpack(t.timeColor))
		timer:SetText(getDecimals(remainingTime,t.decimals))
		stacks:SetColor(unpack(t.stacksColor))
		stacks:SetText(stacksCount)
	end


	local function Update(self,t)
		if t.parent == "HT_Trackers" then
			EVENT_MANAGER:RegisterForUpdate("HT_IconTracker"..t.name, 100,Process)
		end
		container:SetDimensions(t.sizeX,t.sizeY)
		icon:SetDimensions(t.sizeX,t.sizeY)
		icon:SetTexture(t.icon)
		outline:SetDimensions(t.sizeX+(t.outlineThickness*2),t.sizeY+(t.outlineThickness*2))
		outline:SetEdgeColor(unpack(t.outlineColor))
		outline:SetEdgeTexture("",  t.outlineThickness, t.outlineThickness)
		timer:SetFont(string.format("$(%s)|$(KB_%s)|%s",t.font, t.fontSize,t.fontWeight))
		stacks:SetFont(string.format("$(%s)|$(KB_%s)|%s",t.font, t.fontSize, t.fontWeight))
		container:ClearAnchors()
		if t.parent == "HT_Trackers" then
			container:SetAnchor(TOPLEFT,HT_Trackers,TOPLEFT,t.xOffset,t.yOffset)
		else
			container:SetAnchor(TOPLEFT,HT_findContainer(HTSV.trackers[t.parent]),TOPLEFT,t.xOffset,t.yOffset)
		end
		if t.timer1 and t.timer2 then
			timer:SetDimensions(t.sizeX,t.sizeY/2)
			stacks:SetDimensions(t.sizeX,t.sizeY/2)
		else
			timer:SetDimensions(t.sizeX,t.sizeY)
			stacks:SetDimensions(t.sizeX,t.sizeY)
		end
		timer:SetHidden(not t.timer1)
		stacks:SetHidden(not t.timer2)
	end
	container.Update = Update
	container:Update(t)
	container.Process = Process
	


	local function Delete(self)
		EVENT_MANAGER:UnregisterForUpdate("HT_IconTracker"..t.name, 100)
		self:SetHidden(true)
	end
	container.Delete = Delete

	return container
end


local function createGroup(parent,t,i)
	if parent:GetNamedChild(t.name.."_Group"..(i or "")) then 
		local container = parent:GetNamedChild(t.name.."_Group")
		container:SetHidden(false)
		container:Update(t)
		return nil 
	end
	local container = createContainer(parent,t.name.."_Group"..(i or ""),t.sizeX,t.sizeY,t.xOffset,t.yOffset,TOPLEFT,TOPLEFT)
	container:SetHandler("OnMoveStop", function(control)
        t.xOffset = container:GetLeft()
	    t.yOffset  = container:GetTop()
		updateLeftSide()
		container:ClearAnchors()
		container:SetAnchor(TOPLEFT,parent,TOPLEFT,t.xOffset,t.yOffset)
    end)
	local backdrop = WM:CreateControl("$(parent)backdrop",container,  CT_BACKDROP, 4)


	container:SetMovable(true)
	container:SetMouseEnabled(true)
	for _,childName in pairs(t.children) do
		initializeTrackerFunctions[HTSV.trackers[childName].type](container,HTSV.trackers[childName])
	end

	local function Process(previousOverride)
		local override = {
			text = t.text,
			barColor = t.barColor,
			show = true,
			targetNumber = t.targetNumber
		}
		for _,condition in pairs(t.conditions) do
			if operators[condition.operator](conditionArgs1[condition.arg1](t),condition.arg2) then conditionResults[condition.result](override,condition.resultArguments) end
		end
		container:SetHidden(DisplayGroupControl(i))
		--container:SetHidden(not override.show)
		for _,childName in pairs(t.children) do
			HT_findContainer(HTSV.trackers[childName],i):Process(i or 6,i)
			
		end
	end
	local function Update(self,t,groupAnchor)
		for _,childName in pairs(t.children) do
			if not HT_findContainer(HTSV.trackers[childName],i) then initializeTrackerFunctions[HTSV.trackers[childName].type](container,HTSV.trackers[childName]) end
		end
		if t.parent == "HT_Trackers" then
			EVENT_MANAGER:RegisterForUpdate("HT_Group"..t.name..(i or ""), 100,Process)
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
			container:SetAnchor(CENTER,HT_3D:GetNamedChild(groupAnchor),CENTER,t.xOffset,t.yOffset)
			container:SetHidden(DisplayGroupControl(groupAnchor))
		elseif t.parent == "HT_Trackers" then
			container:SetAnchor(TOPLEFT,HT_Trackers,TOPLEFT,t.xOffset,t.yOffset)
		else
			container:SetAnchor(TOPLEFT,HT_findContainer(HTSV.trackers[t.parent]),TOPLEFT,t.xOffset,t.yOffset)
		end
		for _,childName in pairs(t.children) do
			HT_findContainer(HTSV.trackers[childName],i):Update(HTSV.trackers[childName],groupAnchor)
		end
	end
	container.Update = Update
	container:Update(t)
	container.Process = Process
	
	


	local function Delete(self)
		EVENT_MANAGER:UnregisterForUpdate("HT_Group"..t.name..(i or ""), 100)
		self:SetHidden(true)
	end
	container.Delete = Delete
	return container
end







local function createGroupMemberGroup(parent,t)
	local container = createContainer(parent,t.name.."_Group Member",0,0,0,0,TOPLEFT,TOPLEFT)
	container.group = {}
	for i=1,12 do
		local newGroup = createGroup(HT_Trackers,t,i)

		container.group[i] = newGroup
	end

	local function Process(override)
		for i=1,12 do 
			container.group[i]:Process(override)
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