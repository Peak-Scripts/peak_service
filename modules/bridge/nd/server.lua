local bridge = {}

--- @param source integer
function bridge.getPlayer(source)
    return exports.ND_Core:getPlayer(source)
end

---@param identifier string
function bridge.getSourceFromIdentifier(identifier)
    local players = exports.NDCore:getPlayers()
    for _, info in pairs(players) do
        if info.id == identifier then
            return info.source
        end
    end
    return false
end

---@param player table
function bridge.getPlayerIdentifier(player)
    return player.identifier
end

AddEventHandler('ND:characterLoaded', function(character)
    OnPlayerLoaded(character.source)
end)

return bridge