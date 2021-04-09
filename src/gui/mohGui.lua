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
MOHGui = {}
MOHGui.CONTROLS = {"mohList", "mohListItemTemplate", "mohLHOBox", "mohNOHBox", "mohRestoreButton"}

local MOHGui_mt = Class(MOHGui, ScreenElement)

---@param target table
---@return MOHGui
function MOHGui:new(target)
    ---@type MOHGui
    local o = ScreenElement:new(target, MOHGui_mt)
    o.returnScreenName = ""

    o:registerControls(MOHGui.CONTROLS)

    ---@type HiddenObject[]
    o.hiddenObjects = {}

    return o
end

function MOHGui:onCreate()
    self.mohListItemTemplate:unlinkElement()
    self.mohListItemTemplate:setVisible(false)
end

function MOHGui:onOpen()
    self.mohLHOBox:setVisible(true)
    self.mohRestoreButton:setDisabled(true)
    self.hiddenObjects = {}
    RequestObjectsListEvent.sendToServer()
    MOHGui:superClass().onOpen(self)
end

function MOHGui:onClose()
    MOHGui:superClass().onClose(self)
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
end

function MOHGui:onClickRestore()
    if self.mohList:getSelectedElement() ~= nil then
        local selectedIndex = self.mohList:getSelectedElementIndex()
        local selectedHiddenObject = self.hiddenObjects[selectedIndex]
        ArrayUtility.removeAt(self.hiddenObjects, selectedIndex)
        ObjectShowRequestEvent.sendToServer(selectedHiddenObject.index)
        self:refreshList()
    end
end
