--- ${title}

---@author ${author}
---@version r_version_r
---@date 09/04/2021

---@class CameraElement : Class
---@field addCallback function
---@field raiseCallback function
CameraElement = {}
local CameraElement_mt = Class(CameraElement, GuiElement)
Gui.CONFIGURATION_CLASS_MAPPING["camera"] = CameraElement

---@param target table
---@param custom_mt? table
---@return CameraElement
function CameraElement:new(target, custom_mt)
    ---@type CameraElement
    local g = GuiElement:new(target, custom_mt or CameraElement_mt)
    g.cameraId = nil
    g.isRenderDirty = false
    g.overlay = 0
    g.superSamplingFactor = 1
    g.shapesMask = 255
    g.lightsMask = 16711680
    return g
end

function CameraElement:delete()
    self:destroyOverlay()
    CameraElement:superClass().delete(self)
end

---@param xmlFile integer
---@param key string
function CameraElement:loadFromXML(xmlFile, key)
    CameraElement:superClass().loadFromXML(self, xmlFile, key)

    self.superSamplingFactor = getXMLInt(xmlFile, key .. "#superSamplingFactor") or self.superSamplingFactor
    self.shapesMask = getXMLInt(xmlFile, key .. "#shapesMask") or self.shapesMask
    self.lightsMask = getXMLInt(xmlFile, key .. "#lightsMask") or self.lightsMask

    self:addCallback(xmlFile, key .. "#onCameraLoad", "onCameraLoadCallback")
end

---@param profile GuiProfile
---@param applyProfile boolean
function CameraElement:loadProfile(profile, applyProfile)
    CameraElement:superClass().loadProfile(self, profile, applyProfile)
    self.superSamplingFactor = profile:getNumber("superSamplingFactor", self.superSamplingFactor)
    self.shapesMask = profile:getNumber("shapesMask", self.shapesMask)
    self.lightsMask = profile:getNumber("lightsMask", self.lightsMask)
end

function CameraElement:copyAttributes(src)
    CameraElement:superClass().copyAttributes(self, src)
    self.superSamplingFactor = src.superSamplingFactor
    self.shapesMask = src.shapesMask
    self.lightsMask = src.lightsMask
end

---@param cameraNode integer
function CameraElement:createOverlay(cameraNode)
    self.cameraId = cameraNode
    if self.overlay ~= 0 then
        delete(self.overlay)
        self.overlay = 0
    end

    local resolutionX = math.ceil(g_screenWidth * self.size[1]) * self.superSamplingFactor
    local resolutionY = math.ceil(g_screenHeight * self.size[2]) * self.superSamplingFactor
    local aspectRatio = resolutionX / resolutionY

    self.overlay = createRenderOverlay(self.cameraId, aspectRatio, resolutionX, resolutionY, true, self.shapesMask, self.lightsMask)

    self.isRenderDirty = true

    self:raiseCallback("onCameraLoadCallback", self.cameraId, self.overlay)
end

function CameraElement:destroyOverlay()
    if self.overlay ~= 0 then
        delete(self.overlay)
        self.overlay = 0
    end
end

function CameraElement:update(dt)
    CameraElement:superClass().update(self, dt)

    if self.isRenderDirty and self.overlay ~= 0 then
        updateRenderOverlay(self.overlay)
        self.isRenderDirty = false
    end
end

function CameraElement:draw()
    if self.overlay ~= 0 then
        renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
    CameraElement:superClass().draw(self)
end

function CameraElement:canReceiveFocus()
    return false
end

function CameraElement:setRenderDirty()
    self.isRenderDirty = true
end
