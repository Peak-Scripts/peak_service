local bridge = {}

--- @param source integer
function bridge.getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

function bridge.getSourceFromIdentifier(identifier)
    local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    return player and player.PlayerData.source or false
end

function bridge.getPlayerIdentifier(player)
    return player.PlayerData.citizenid
end

function bridge.checkCopCount()
    local amount = exports.qbx_core:GetDutyCountType('leo')
    return amount
end

--- @param player table
function bridge.getPlayerName(player)
    return ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    OnPlayerLoaded(source)
end)

return bridge