local bridge = {}

--- @param source integer
function bridge.getPlayer(source)
    return exports.ND_Core:getPlayer(source)
end

function bridge.getSourceFromIdentifier(identifier)
    local players = exports.NDCore:getPlayers()
    for _, info in pairs(players) do
        if info.id == identifier then
            return info.source
        end
    end
    return false
end

function bridge.checkCopCount()
    local amount = 0
    local players = exports.NDCore:getPlayers()
    local policeDepartments = { 'sahp', 'lspd', 'bcso' }

    for _, player in pairs(players) do
        for i=1, #policeDepartments do
            if player.groups[policeDepartments[i]] then
                amount += 1
            end
        end
    end
    
    return amount
end

AddEventHandler('ND:characterLoaded', function(character)
    OnPlayerLoaded(character.source)
end)

return bridge