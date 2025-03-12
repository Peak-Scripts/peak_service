local Ox = require '@ox_core.lib.init'
local bridge = {}

--- @param source integer
function bridge.getPlayer(source)
    return Ox.GetPlayer(source)
end

function bridge.getSourceFromIdentifier(identifier)
    local player = Ox.GetPlayerFromFilter({ identifier = identifier })
    return player and player.source or nil
end

function bridge.getPlayerIdentifier(player)
    return player.identifier
end

function bridge.checkCopCount()
    local amount = 0
    
    local players = Ox.GetPlayers({ groups = { ['police'] = 1 } })
    for _, player in pairs(players) do
        amount += 1
    end

    return amount
end

RegisterNetEvent('ox:playerLoaded', function(playerId)
    OnPlayerLoaded(playerId)
end)

return bridge