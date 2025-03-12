local bridge = {}

local ESX = exports['es_extended']:getSharedObject()

--- @param source integer
function bridge.getPlayer(source)
    return ESX.GetPlayerFromId(source)
end

function bridge.getSourceFromIdentifier(identifier)
    local player = ESX.GetPlayerFromIdentifier(identifier)
    return player and player.source or false
end

function bridge.checkCopCount()
    local amount = 0
    local players = ESX.GetExtendedPlayers()

    for i = 1, #players do 
        local player = players[i]
        if player.job.name == 'police' then
            amount += 1
        end
    end

    return amount
end

RegisterNetEvent('esx:playerLoaded', function(player)
    OnPlayerLoaded(player)
  end)

return bridge