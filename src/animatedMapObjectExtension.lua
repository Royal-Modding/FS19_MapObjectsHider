--- ${title}

---@author ${author}
---@version r_version_r
---@date 07/04/2021

AnimatedMapObjectExtension = {}

--- Store all animated map objects so that they can be easily processed later
---@param superFunc function
---@param nodeId integer
function AnimatedMapObjectExtension:load(superFunc, nodeId, ...)
    local result = superFunc(self, nodeId, ...)
    self.mapObjectsHider = {}
    self.mapObjectsHider.rootNode = nodeId
    self.mapObjectsHider.collisions = {}
    EntityUtility.queryNodeHierarchy(
        self.mapObjectsHider.rootNode,
        ---@param node integer
        function(node)
            local rigidType = getRigidBodyType(node)
            if rigidType ~= "NoRigidBody" then
                self.mapObjectsHider.collisions[node] = true
                MapObjectsHider.animatedMapObjectCollisions[node] = self
            end
        end
    )
    return result
end
