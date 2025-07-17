local Ox = require '@ox_core.lib.init'
local bridge = {}

--- @param source integer
function bridge.getPlayer(source)
    return Ox.GetPlayer(source)
end

---@param stateId string
function bridge.getSourceFromIdentifier(stateId)
    local player = Ox.GetPlayerFromFilter({ stateId = stateId })

    return player and player.source or nil
end

---@param player table
function bridge.getPlayerIdentifier(player)
    return player.stateId
end

RegisterNetEvent('ox:playerLoaded', function(playerId)
    OnPlayerLoaded(playerId)
end)

return bridge