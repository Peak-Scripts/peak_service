
local bridge = {}
local QBCore = exports['qb-core']:GetCoreObject()

--- @param source integer
function bridge.getPlayer(source)
    return QBCore.Functions.GetPlayer(source)
end

function bridge.getSourceFromIdentifier(identifier)
    local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
    return player and player.PlayerData.source or false
end

function bridge.getPlayerIdentifier(player)
    return player.PlayerData.citizenid
end

function bridge.checkCopCount()
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()

    for _, player in pairs(players) do
        if player.PlayerData.job.type == 'leo' and player.PlayerData.job.onduty then
            amount += 1
        end
    end
    return amount
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    OnPlayerLoaded(source)
end)

return bridge