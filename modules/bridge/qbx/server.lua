local bridge = {}

--- @param source integer
function bridge.getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

---@param identifier string
function bridge.getSourceFromIdentifier(identifier)
    local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    return player and player.PlayerData.source or false
end

---@param
function bridge.getPlayerIdentifier(player)
    return player.PlayerData.citizenid
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    OnPlayerLoaded(source)
end)

return bridge