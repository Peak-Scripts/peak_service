local bridge = {}

local ESX = exports['es_extended']:getSharedObject()

--- @param source integer
function bridge.getPlayer(source)
    return ESX.GetPlayerFromId(source)
end

---@param identifier string
function bridge.getSourceFromIdentifier(identifier)
    local player = ESX.GetPlayerFromIdentifier(identifier)
    return player and player.source or false
end

---@param player table
function bridge.getPlayerIdentifier(player)
    return player.identifier
end

AddEventHandler('esx:playerLoaded', function(player)
    OnPlayerLoaded(player)
end)

return bridge