--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 02/12/2020

MapObjectsHiderSync = {}

MapObjectsHiderSync_mt = Class(MapObjectsHiderSync, Object)

InitObjectClass(MapObjectsHiderSync, "MapObjectsHiderSync")

function MapObjectsHiderSync:new(isServer, isClient, customMt)
    local o = Object:new(isServer, isClient, customMt or MapObjectsHiderSync_mt)
    registerObjectClassName(o, "MapObjectsHiderSync")
    return o
end

function MapObjectsHiderSync:delete()
    unregisterObjectClassName(self)
    MapObjectsHiderSync:superClass().delete(self)
end

function MapObjectsHiderSync:writeStream(streamId)
    local objectsCount = #MapObjectsHider.hiddenObjects
    local collisionsCount = 0
    local collisions = {}
    streamWriteInt32(streamId, objectsCount)
    for i = 1, objectsCount, 1 do
        local obj = MapObjectsHider.hiddenObjects[i]
        collisionsCount = collisionsCount + #obj.collisions
        for _, col in pairs(obj.collisions) do
            table.insert(collisions, col.index)
        end
        streamWriteString(streamId, obj.index)
    end
    streamWriteInt32(streamId, collisionsCount)
    for i = 1, collisionsCount, 1 do
        streamWriteString(streamId, collisions[i])
    end
    MapObjectsHiderSync:superClass().writeStream(self, streamId)
end

function MapObjectsHiderSync:readStream(streamId)
    local objectsCount = streamReadInt32(streamId)
    for i = 1, objectsCount, 1 do
        local objIndex = streamReadString(streamId)
        MapObjectsHider:hideNode(Utility.indexToNode(objIndex, MapObjectsHider.mapNode))
    end
    local collisionsCount = streamReadInt32(streamId)
    for i = 1, collisionsCount, 1 do
        local colIndex = streamReadString(streamId)
        MapObjectsHider:decollideNode(Utility.indexToNode(colIndex, MapObjectsHider.mapNode))
    end
    MapObjectsHiderSync:superClass().readStream(self, streamId)
end

function MapObjectsHiderSync:readUpdateStream(streamId, timestamp, connection)
    MapObjectsHiderSync:superClass().readUpdateStream(self, streamId, timestamp, connection)
end

function MapObjectsHiderSync:writeUpdateStream(streamId, connection, dirtyMask)
    MapObjectsHiderSync:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end

function MapObjectsHiderSync:update(dt)
    MapObjectsHiderSync:superClass().update(self, dt)
end

function MapObjectsHiderSync:updateTick(dt)
    MapObjectsHiderSync:superClass().updateTick(self, dt)
end

function MapObjectsHiderSync:draw()
    MapObjectsHiderSync:superClass().draw(self)
end

function MapObjectsHiderSync:mouseEvent(posX, posY, isDown, isUp, button)
    MapObjectsHiderSync:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
