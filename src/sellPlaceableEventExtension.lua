--- ${title}

---@author ${author}
---@version r_version_r
---@date 12/04/2021

---@param connection Connection
function SellPlaceableEvent:run(connection)
    if not connection:getIsServer() then
        local state = SellPlaceableEvent.STATE_FAILED
        local sellPrice = 0

        if self.placeable ~= nil then
            if g_currentMission:getHasPlayerPermission("sellPlaceable", connection) then
                if self.placeable:canBeSold() then
                    self.placeable:onSell()
                    g_currentMission:addPlaceableToDelete(self.placeable)

                    local ownerFarmId = self.placeable:getOwnerFarmId()
                    if ownerFarmId ~= 0 then
                        sellPrice = g_currentMission.economyManager:getSellPrice(self.placeable)
                        print("add money " .. tostring(sellPrice))
                        g_currentMission:addMoney(sellPrice, ownerFarmId, MoneyType.SHOP_PROPERTY_SELL, true, true)
                    end

                    state = SellPlaceableEvent.STATE_SUCCESS
                else
                    state = SellPlaceableEvent.STATE_IN_USE
                end
            else
                state = SellPlaceableEvent.STATE_NO_PERMISSION
            end
        end

        connection:sendEvent(SellPlaceableEvent:newServerToClient(state, sellPrice))
    else
        g_messageCenter:publish(SellPlaceableEvent, {self.state, self.sellPrice})
    end
end
