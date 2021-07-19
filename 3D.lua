function HT_Initialize3D()
    local WM = GetWindowManager()
    local HT_3D = WM:CreateTopLevelWindow("HT_3D")
    HT_3D:SetResizeToFitDescendents(false)
    HT_3D:SetMovable(false)
    HT_3D:SetMouseEnabled(false)
    HT_3D:SetHidden(false)

    local RenderSpace = CreateControl("RenderSpace", GuiRoot, CT_CONTROL)
    RenderSpace:Create3DRenderSpace()
    HT.RenderSpace = RenderSpace
    for i = 1, 12 do
        local c = WM:CreateControl("$(parent)" .. i, HT_3D, CT_CONTROL)
        c:SetAnchor(CENTER, HT_3D, CENTER, 0, 0)
        c:SetDrawLayer(DL_BACKGROUND)
        c:SetDrawTier(DT_MIN_VALUE)
        c:SetMouseEnabled(false)
        c:SetHidden(true)
    end

    HT_3D:ClearAnchors()
    HT_3D:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    EVENT_MANAGER:RegisterForUpdate("HT_3DUpdate", 10, UpdateIndicators)
end

function UpdateForUnit(i, camMatrixInv, screenX, screenY)

    local _, worldX, worldY, worldZ = GetUnitRawWorldPosition("group" .. i)
    local PworldX, PworldY, PworldZ = GuiRender3DPositionToWorldPosition(RenderSpace:Get3DRenderSpaceOrigin())
    local mtx = matrix:new(1, 4, 0)

    worldY = worldY + 200

    mtx[1][1] = worldX
    mtx[1][2] = worldY
    mtx[1][3] = worldZ
    mtx[1][4] = 1

    mtx = matrix.mul(mtx, camMatrixInv)

    local distance = mtx[1][3]
    if (mtx[1][3] <= 0) then
        return true
    end

    local worldWidth, worldHeight = GetWorldDimensionsOfViewFrustumAtDepth(distance)
    local UIUnitsPerWorldUnitX, UIUnitsPerWorldUnitY = screenX / worldWidth, screenY / worldHeight
    local x = mtx[1][1] * UIUnitsPerWorldUnitX
    local y = -mtx[1][2] * UIUnitsPerWorldUnitY
    local c = HT_3D:GetNamedChild(i)
    c:SetAnchor(CENTER, HT_3D, CENTER, x, y)
    HT.groupDistance[i] = math.sqrt(((worldX-PworldX)^2)+((worldY-PworldY)^2)+((worldZ-PworldZ)^2))
    return false
end

function UpdateIndicators()
    if not IsUnitGrouped("player") then
        return
    end
    local RenderSpace = HT.RenderSpace
    Set3DRenderSpaceToCurrentCamera(RenderSpace:GetName())
    local cameraX, cameraY, cameraZ = GuiRender3DPositionToWorldPosition(RenderSpace:Get3DRenderSpaceOrigin())
    local forwardX, forwardY, forwardZ = RenderSpace:Get3DRenderSpaceForward()
    local rightX, rightY, rightZ = RenderSpace:Get3DRenderSpaceRight()
    local upX, upY, upZ = RenderSpace:Get3DRenderSpaceUp()

    local camMatrix = matrix:new(4, 4, 0)

    camMatrix[1][1] = rightX
    camMatrix[1][2] = rightY
    camMatrix[1][3] = rightZ
    camMatrix[1][4] = 0

    camMatrix[2][1] = upX
    camMatrix[2][2] = upY
    camMatrix[2][3] = upZ
    camMatrix[2][4] = 0

    camMatrix[3][1] = forwardX
    camMatrix[3][2] = forwardY
    camMatrix[3][3] = forwardZ
    camMatrix[3][4] = 0

    camMatrix[4][1] = cameraX
    camMatrix[4][2] = cameraY
    camMatrix[4][3] = cameraZ
    camMatrix[4][4] = 1

    local camMatrixInv = matrix.invert(camMatrix)
    local screenX, screenY = GuiRoot:GetDimensions()

    for i = 1, 12 do
        HT_3D:GetNamedChild(i):SetHidden(UpdateForUnit(i, camMatrixInv, screenX, screenY))

    end
end