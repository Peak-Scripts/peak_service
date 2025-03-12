local utils = {}
local sharedConfig = require 'config.shared'
local serverConfig = require 'config.server'

--- @param source integer
--- @param message string
--- @param type string
function utils.notify(source, message, type)
    lib.notify(source, { 
        position = 'top',
        title = 'Community Service',
        description = message, 
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
              color = '#909296'
            }
        },
        type = type 
    })
end

function utils.debugPrint(message)
    if not sharedConfig.debug.prints then return end

    print(('^1[DEBUG]^0 %s'):format(message))
end

--- @param source integer
--- @param location vector3
--- @param maxDistance number
function utils.checkDistance(source, location, maxDistance)
    if not (type(location) == 'vector3' or type(location) == 'vector4') then
        return false
    end

    local locationCoords = vec3(location.x, location.y, location.z)
    local ped = GetPlayerPed(source)
    local playerPos = GetEntityCoords(ped)

    local distance = #(playerPos - locationCoords)
    return distance < maxDistance
end

function utils.handleExploit(source, data)
    -- If this is triggered, 90% of the time the player is cheating or doing something weird. Take precautions and investigate the player.

    DropPlayer(source, 'Exploiting the server')
    utils.logPlayer(source, data)
end

--- @param source integer
--- @param data table
function utils.logPlayer(source, data)
    if not serverConfig.logging.enabled then return end

    if serverConfig.logging.system == 'ox_lib' then
        lib.logger(source, 'Store Robbery', data.message)
    elseif serverConfig.logging.system == 'discord' then
        local playerName = GetPlayerName(source)
        local identifiers = GetPlayerIdentifiers(source)
    
        local playerIdentifiers = {}
    
        for _, id in pairs(identifiers) do
            if id:find('discord:') then
                playerIdentifiers.discord = id:gsub('discord:', '')
            elseif id:find('steam:') then
                playerIdentifiers.steam = id:gsub('steam:', '')
            elseif id:find('license:') then
                playerIdentifiers.license = id:gsub('license:', '')
            elseif id:find('license2:') then
                playerIdentifiers.license2 = id:gsub('license2:', '')
            elseif id:find('xbl:') then
                playerIdentifiers.xbox = id:gsub('xbox:', '')
            elseif id:find('live:') then
                playerIdentifiers.live = id:gsub('live:', '')
            elseif id:find('ip:') then
                playerIdentifiers.ip = id:gsub('ip:', '')
            elseif id:find('fivem:') then
                playerIdentifiers.ip = id:gsub('fivem:', '')
            end
        end
    
        local logMessage = ('%s\n\n**Player Identifiers:**\n' ..
            'Player: %s\n' ..
            'FiveM: %s\n' ..
            'Discord: %s\n' ..
            'Steam: %s\n' ..
            'License: %s\n' ..
            'License2: %s\n' ..
            'Xbox: %s\n' ..
            'Live: %s\n' ..
            'IP: %s'):format(
            data.message, 
            playerName,
            playerIdentifiers.fivem or 'Unknown',
            playerIdentifiers.discord or 'Unknown',
            playerIdentifiers.steam or 'Unknown',
            playerIdentifiers.license or 'Unknown',
            playerIdentifiers.license2 or 'Unknown',
            playerIdentifiers.xbl or 'Unknown',
            playerIdentifiers.live or 'Unknown',
            playerIdentifiers.ip or 'Unknown'
        )
    
        local payload = {
            username = serverConfig.logging.name,
            avatar_url = serverConfig.logging.image,
            embeds = {}
        }
    
        if data.title then
            table.insert(payload.embeds, {
                color = data.color,
                title = ('**%s**'):format(data.title),
                description = logMessage,
                footer = {
                    text = os.date('%a %b %d, %I:%M%p'),
                    icon_url = serverConfig.logging.image
                }
            })
        end
    
        if #payload.embeds == 0 then
            payload.embeds = nil
        end

        PerformHttpRequest(serverConfig.logging.webhookUrl, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
    end
end

return utils