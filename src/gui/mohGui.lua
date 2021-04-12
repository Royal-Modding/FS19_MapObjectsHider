--- ${title}

---@author ${author}
---@version r_version_r
---@date 08/04/2021

---@class MOHGui : Class
---@field onClickBack function
---@field registerControls function
---@field mohList any
---@field mohListItemTemplate any
---@field mohLHOBox any
---@field mohNOHBox any
---@field mohRestoreButton any
---@field mohCamera CameraElement
MOHGui = {}
MOHGui.CONTROLS = {"mohList", "mohListItemTemplate", "mohLHOBox", "mohNOHBox", "mohRestoreButton", "mohCamera"}

local MOHGui_mt = Class(MOHGui, ScreenElement)

---@param target table
---@return MOHGui
function MOHGui:new(target)
    ---@type MOHGui
    local o = ScreenElement:new(target, MOHGui_mt)
    o.returnScreenName = ""
    o.cameraId = nil
    o.originCameraPos = {}
    o.originCameraRot = {}

    ---@type HiddenObject
    o.lastSelectedHiddenObject = nil
    ---@type table<integer, integer>
    o.materialsBackup = {}

    o:registerControls(MOHGui.CONTROLS)

    ---@type HiddenObject[]
    o.hiddenObjects = {}

    return o
end

function MOHGui:onCreate()
    self.mohListItemTemplate:unlinkElement()
    self.mohListItemTemplate:setVisible(false)
    self.cameraId = createCamera("mohCam", math.rad(60), 0.1, 10000)
    self.mohCamera:createOverlay(self.cameraId)
end

function MOHGui:onOpen()
    self:loadCamera()
    self.lastSelectedHiddenObject = nil
    self.materialsBackup = {}

    self.mohLHOBox:setVisible(true)
    self.mohRestoreButton:setDisabled(true)
    self.hiddenObjects = {}
    RequestObjectsListEvent.sendToServer()
    MOHGui:superClass().onOpen(self)
end

function MOHGui:onClose()
    self:hideLastHiddenObject()
    MOHGui:superClass().onClose(self)
end

function MOHGui:loadCamera()
    local tY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, 0, 0, 0)
    self.originCameraPos = {0, tY + 1250, 0}
    self.originCameraRot = {math.rad(-90), 0, 0}
    self:resetCamera()
end

function MOHGui:resetCamera()
    if self.cameraId ~= nil then
        setWorldTranslation(self.cameraId, unpack(self.originCameraPos))
        setRotation(self.cameraId, unpack(self.originCameraRot))
    end
end

function MOHGui:sendCameraTo(objectId, zoom)
    local x, y, z = getWorldTranslation(objectId)
    setWorldTranslation(self.cameraId, x, y + (4 * zoom), z + (4 * zoom))
    setRotation(self.cameraId, math.rad(-40), 0, 0)
end

---@param hiddenObjects HiddenObject[]
function MOHGui:onHiddenObjectsReceived(hiddenObjects)
    self.hiddenObjects = hiddenObjects
    local mapNode = MapObjectsHider.mapNode
    local dateFormat = "%d/%m/%Y %H:%M:%S" -- change this based on locale
    for _, ho in pairs(self.hiddenObjects) do
        ho.id = EntityUtility.indexToNode(ho.index, mapNode)
        ho.name = getName(ho.id)
        ho.datetime = getDateAt(dateFormat, 2018, 11, 20, 0, 0, 0, ho.timestamp, 0)
    end

    table.sort(
        self.hiddenObjects,
        ---@param a HiddenObject
        ---@param b HiddenObject
        function(a, b)
            return a.timestamp > b.timestamp
        end
    )

    self:refreshList()
end

function MOHGui:refreshList()
    self.mohList:deleteListItems()

    self.mohLHOBox:setVisible(false)

    if #self.hiddenObjects > 0 then
        for _, ho in pairs(self.hiddenObjects) do
            local new = self.mohListItemTemplate:clone(self.mohList)
            new:setVisible(true)
            new.elements[1]:setText(ho.name)
            new.elements[2]:setText(ho.datetime)
            new.elements[3]:setText(ho.player)
            new:updateAbsolutePosition()
        end
        self.mohNOHBox:setVisible(false)
        self.mohRestoreButton:setDisabled(false)
    else
        self.mohNOHBox:setVisible(true)
        self.mohRestoreButton:setDisabled(true)
    end
    self:onSelectionChanged()
end

function MOHGui:onClickRestore()
    if self.mohList:getSelectedElement() ~= nil then
        self:hideLastHiddenObject()
        local selectedIndex = self.mohList:getSelectedElementIndex()
        local selectedHiddenObject = self.hiddenObjects[selectedIndex]
        ArrayUtility.removeAt(self.hiddenObjects, selectedIndex)
        ObjectShowRequestEvent.sendToServer(selectedHiddenObject.index)
        self:refreshList()
    end
end

function MOHGui:update(dt)
    MOHGui:superClass().update(self, dt)
    if self.isOpen then
        self.mohCamera:setRenderDirty()
    end
end

function MOHGui:onSelectionChanged()
    local sIndex = self.mohList:getSelectedElementIndex()
    self:hideLastHiddenObject()
    if sIndex > 0 and #self.hiddenObjects >= sIndex then
        local selectedHiddenObject = self.hiddenObjects[sIndex]
        self:sendCameraTo(selectedHiddenObject.id, self:showHiddenObject(selectedHiddenObject))
    else
        self:resetCamera()
    end
end

---@param hiddenObject HiddenObject
---@return integer
function MOHGui:showHiddenObject(hiddenObject)
    local bestRadius = -1
    EntityUtility.queryNodeHierarchy(
        hiddenObject.id,
        ---@param node integer
        function(node)
            if getHasClassId(node, ClassIds.SHAPE) then
                self.materialsBackup[node] = getMaterial(node, 0)
                setMaterial(node, Placeable.GLOW_MATERIAL, 0)
                local _, _, _, radius = getShapeBoundingSphere(node)
                if radius > bestRadius then
                    bestRadius = radius
                end
            end
        end
    )
    setVisibility(hiddenObject.id, true)
    self.lastSelectedHiddenObject = hiddenObject
    return bestRadius
end

function MOHGui:hideLastHiddenObject()
    if self.lastSelectedHiddenObject ~= nil then
        setVisibility(self.lastSelectedHiddenObject.id, false)
        EntityUtility.queryNodeHierarchy(
            self.lastSelectedHiddenObject.id,
            ---@param node integer
            function(node)
                if getHasClassId(node, ClassIds.SHAPE) then
                    setMaterial(node, self.materialsBackup[node], 0)
                end
            end
        )
        self.materialsBackup = {}
        self.lastSelectedHiddenObject = nil
    end
end

function MOHGui:delete()
    if self.cameraId ~= nil then
        delete(self.cameraId)
    end
    MOHGui:superClass().delete(self)
end
