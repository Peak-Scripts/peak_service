
local bridge = {}
local QBCore = exports['qb-core']:GetCoreObject()

--- @param source integer
function bridge.getPlayer(source)
    return QBCore.Functions.GetPlayer(source)
end

---@param identifier string
function bridge.getSourceFromIdentifier(identifier)
    local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
    return player and player.PlayerData.source or false
end

---@param player table
function bridge.getPlayerIdentifier(player)
    return player.PlayerData.citizenid
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    OnPlayerLoaded(source)
end)

return bridge