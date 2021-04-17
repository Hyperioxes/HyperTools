local function createProgressBar(index,text,sizeX,sizeY,xOffset,yOffset,texturePath)
	local container = createContainer(HT_Trackers,index,sizeX,sizeY,xOffset,yOffset,TOPLEFT,TOPLEFT)
	local icon = createTexture(container,"icon",sizeY,sizeY,0,0,TOPLEFT,TOPLEFT,texturePath)
	local bar = createTexture(container,"bar",sizeX-sizeY,sizeY,sizeY,0,TOPLEFT,TOPLEFT)
	local label = createLabel(container,"label",sizeX-sizeY,sizeY,sizeY,0,TOPLEFT,TOPLEFT,text)
	container:SetHandler("OnMoveStop", function(control)
        trackers[index].xOffset = container:GetLeft()
	    trackers[index].yOffset  = container:GetTop()
    end)
	container.data = {
		originalSizeX = sizeX,
		originalSizeY = sizeY,
	}
	container:SetMovable(true)
	container:SetMouseEnabled(true)
end