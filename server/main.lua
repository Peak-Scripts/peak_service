--[[
    https://github.com/Peak-Scripts

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Peak Scripts <https://github.com/Peak-Scripts>
]]

local sharedConfig = require 'config.shared'
local serverConfig = require 'config.server'
local utils = require 'modules.utils.server'
local activeServices = {}
local taskTime = {}

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `peak_service` (
            `identifier` varchar(60) NOT NULL,
            `player_name` varchar(60) DEFAULT NULL,
            `tasks_remaining` int DEFAULT 0,
            `original_tasks` int DEFAULT 0,
            `admin` varchar(60) NOT NULL,
            `reason` varchar(255) NOT NULL,
            `original_position` varchar(255) NOT NULL,
            PRIMARY KEY (`identifier`)
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `peak_service_items` (
            `id` int AUTO_INCREMENT PRIMARY KEY,
            `identifier` varchar(60) NOT NULL,
            `item_name` varchar(100) NOT NULL,
            `count` int NOT NULL DEFAULT 1,
            `metadata` longtext DEFAULT NULL,
            `slot` int NOT NULL,
            INDEX `idx_identifier` (`identifier`)
        )
    ]])
end)

---@param playerId number
---@param identifier string
local function storePlayerItems(playerId, identifier)
    if not serverConfig.confiscateItems then 
        return
    end
    
    local inventory = exports.ox_inventory:GetInventory(playerId)

    if not inventory or not inventory.items then 
        return 
    end
    
    MySQL.query('DELETE FROM peak_service_items WHERE identifier = ?', { identifier })
    
    for slot, item in pairs(inventory.items) do
        if item and item.name and item.count and item.count > 0 then
            MySQL.insert('INSERT INTO peak_service_items (identifier, item_name, count, metadata, slot) VALUES (?, ?, ?, ?, ?)', {
                identifier,
                item.name,
                item.count,
                item.metadata and json.encode(item.metadata) or nil,
                slot
            })
        end
    end
    
    exports.ox_inventory:ClearInventory(playerId)
end

---@param identifier string
---@return table
local function getStoredItems(identifier)
    local items = MySQL.query.await('SELECT * FROM peak_service_items WHERE identifier = ? ORDER BY slot', { identifier })
    local formattedItems = {}
    
    for _, item in ipairs(items or {}) do
        formattedItems[#formattedItems + 1] = {
            name = item.item_name,
            count = item.count,
            metadata = item.metadata and json.decode(item.metadata) or nil,
            slot = item.slot
        }
    end
    
    return formattedItems
end

---@param playerId number
---@param identifier string
local function returnStoredItems(playerId, identifier)
    if not serverConfig.confiscateItems then 
        return 
    end
    
    local items = getStoredItems(identifier)
    
    for _, item in ipairs(items) do
        exports.ox_inventory:AddItem(playerId, item.name, item.count, item.metadata)
    end
    
    MySQL.query('DELETE FROM peak_service_items WHERE identifier = ?', { identifier })
end

---@param count number
---@return table
local function generateServiceTasks(count)
    local tasks = {}
    local availableTasks = table.clone(sharedConfig.tasks)
    local spots = serverConfig.taskSpots

    for i = 1, count do
        if #availableTasks == 0 then
            availableTasks = table.clone(sharedConfig.tasks)
        end

        local randomTaskIndex = math.random(1, #availableTasks)

        tasks[i] = table.clone(availableTasks[randomTaskIndex])

        table.remove(availableTasks, randomTaskIndex)
        
        local spotIndex = ((i-1) % #spots) + 1
        tasks[i].coords = spots[spotIndex]
        tasks[i].typeIndex = i
    end

    return tasks
end

---@param playerId number
local function loadPlayerService(playerId)
    local player = bridge.getPlayer(playerId)
    local identifier = bridge.getPlayerIdentifier(player)

    if not player or not identifier then 
        return 
    end
    
    local result = MySQL.single.await('SELECT * FROM peak_service WHERE identifier = ?', {
        identifier
    })
    
    if result then
        local originalPos = result.original_position and json.decode(result.original_position)

        if not originalPos or not next(originalPos) then
            local ped = GetPlayerPed(playerId)
            
            if ped then
                local coords = GetEntityCoords(ped)

                originalPos = { x = coords.x, y = coords.y, z = coords.z }

                MySQL.update('UPDATE peak_service SET original_position = ? WHERE identifier = ?', {
                    json.encode(originalPos),
                    identifier
                })
            end
        end

        local tasks = generateServiceTasks(result.tasks_remaining)

        local currentPlayerName = GetPlayerName(playerId)
        local finalPlayerName = result.player_name and result.player_name ~= 'Unknown' and result.player_name or currentPlayerName
        
        activeServices[playerId] = {
            tasksRemaining = result.tasks_remaining,
            originalTasks = result.original_tasks,
            admin = result.admin,
            reason = result.reason,
            identifier = identifier,
            playerName = finalPlayerName,
            originalPosition = originalPos,
            tasks = tasks
        }

        if result.player_name == 'Unknown' or not result.player_name then
            MySQL.update('UPDATE peak_service SET player_name = ? WHERE identifier = ?', {
                currentPlayerName,
                identifier
            })
        end

        TriggerClientEvent('peak_service:client:startService', playerId, {
            location = sharedConfig.location,
            tasks = tasks,
            admin = result.admin,
            reason = result.reason,
            remainingTasks = result.tasks_remaining,
            originalTasks = result.original_tasks,
            originalPosition = originalPos
        })
    end
end

---@param playerId number
local function saveServiceData(playerId)
    local service = activeServices[playerId]

    if not service or not service.identifier then 
        return 
    end
    
    MySQL.update('INSERT INTO peak_service (identifier, player_name, tasks_remaining, original_tasks, admin, reason, original_position) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE tasks_remaining = VALUES(tasks_remaining), original_tasks = VALUES(original_tasks), admin = VALUES(admin), reason = VALUES(reason), original_position = VALUES(original_position), player_name = VALUES(player_name)', {
        service.identifier,
        service.playerName or GetPlayerName(playerId),
        service.tasksRemaining,
        service.originalTasks,
        service.admin,
        service.reason,
        json.encode(service.originalPosition)
    })
end

---@param playerId number
local function releasePlayer(playerId)
    if not activeServices[playerId] then 
        return 
    end
    
    local originalPosition = activeServices[playerId].originalPosition
    local service = activeServices[playerId]
    
    if service.identifier then
        MySQL.query('DELETE FROM peak_service WHERE identifier = ?', {
            service.identifier
        })
    end

    utils.logPlayer(playerId, {
        title = 'Community Service Release',
        message = ('Player released from community service. Original admin: %s, Reason: %s'):format(service.admin, service.reason)
    })
    
    if serverConfig.confiscateItems then
        returnStoredItems(playerId, service.identifier)
    end
    
    activeServices[playerId] = nil
    taskTime[playerId] = nil
    
    TriggerClientEvent('peak_service:client:releaseFromService', playerId, originalPosition)

    utils.notify(playerId, locale('notify.service_completed'), 'success')
end

---@param data table
local function startService(data)
    local admin = source
    
    if not IsPlayerAceAllowed(admin, 'command') then 
        return 
    end
    
    local target = tonumber(data.playerId)
    local identifier = data.identifier

    if target and activeServices[target] then 
        utils.notify(admin, locale('notify.already_in_service'), 'error')
        return 
    end

    local targetPlayer, originalPosition, playerName

    if target then
        playerName = GetPlayerName(target)
        
        if not playerName then
            utils.notify(admin, locale('notify.invalid_player'), 'error')
            return
        end

        targetPlayer = bridge.getPlayer(target)
        identifier = bridge.getPlayerIdentifier(targetPlayer)

        local targetPed = GetPlayerPed(target)

        if targetPed then
            local coords = GetEntityCoords(targetPed)
            originalPosition = { x = coords.x, y = coords.y, z = coords.z }

            if serverConfig.confiscateItems then
                storePlayerItems(target, identifier)
            end
        end
    end

    if not identifier then
        utils.notify(admin, locale('notify.invalid_identifier'), 'error')
        return
    end

    local existingService = MySQL.single.await('SELECT 1 FROM peak_service WHERE identifier = ?', { identifier })

    if existingService then
        utils.notify(admin, locale('notify.already_in_service'), 'error')
        return
    end

    local tasks = generateServiceTasks(data.amount)

    if target then
        activeServices[target] = {
            tasksRemaining = data.amount,
            originalTasks = data.amount,
            admin = GetPlayerName(admin),
            reason = data.reason,
            identifier = identifier,
            playerName = playerName,
            originalPosition = originalPosition,
            tasks = tasks
        }
    end

    MySQL.update('INSERT INTO peak_service (identifier, player_name, tasks_remaining, original_tasks, admin, reason, original_position) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE tasks_remaining = VALUES(tasks_remaining), original_tasks = VALUES(original_tasks), admin = VALUES(admin), reason = VALUES(reason), player_name = VALUES(player_name)', {
        identifier,
        playerName or 'Unknown',
        data.amount,
        data.amount,
        GetPlayerName(admin),
        data.reason,
        originalPosition and json.encode(originalPosition) or '{}'
    })

    if target then
        TriggerClientEvent('peak_service:client:startService', target, {
            location = sharedConfig.location,
            tasks = tasks,
            admin = GetPlayerName(admin),
            reason = data.reason,
            remainingTasks = data.amount,
            originalTasks = data.amount,
            originalPosition = originalPosition
        })

        utils.notify(admin, locale('notify.sent_to_service', target), 'success')
        utils.notify(target, locale('notify.been_sent_to_service', GetPlayerName(admin)), 'inform')
    else
        utils.notify(admin, locale('notify.offline_service_assigned', identifier), 'success')
    end
end

---@param taskIndex number
RegisterNetEvent('peak_service:server:taskCompleted', function(taskIndex)
    local source = source

    if not activeServices[source] then
        local player = bridge.getPlayer(source)
        local identifier = bridge.getPlayerIdentifier(player)
        
        if identifier then
            local result = MySQL.single.await('SELECT * FROM peak_service WHERE identifier = ?', {
                identifier
            })
            
            if result then
                loadPlayerService(source)
            end
        end
        
        if not activeServices[source] then return end
    end

    if not taskIndex or type(taskIndex) ~= 'number' then 
        return 
    end
    
    local service = activeServices[source]
    
    if not service.tasks or not service.tasks[taskIndex] then 
        return 
    end

    local currentTime = os.time()
    
    if taskTime[source] and (currentTime - taskTime[source]) < 2 then
        utils.handleExploit(source, {
            title = 'Community Service Exploit Attempt',
            message = 'Player attempted to complete a task too quickly.'
        })
        return
    end

    local taskCoords = service.tasks[taskIndex].coords
    local distance = utils.checkDistance(source, taskCoords, 3.0)

    if not distance then
        utils.handleExploit(source, {
            title = 'Community Service Exploit Attempt',
            message = 'Player tried to complete task from invalid distance'
        })
        return
    end

    taskTime[source] = currentTime
    service.tasksRemaining = service.tasksRemaining - 1
    
    utils.logPlayer(source, {
        title = 'Community Service Task Completed',
        message = ('Player completed task %d. Remaining tasks: %d'):format(taskIndex, service.tasksRemaining)
    })
    
    saveServiceData(source)
    
    TriggerClientEvent('peak_service:client:updateUI', source, {
        admin = service.admin,
        remainingTasks = service.tasksRemaining,
        completedTasks = service.originalTasks - service.tasksRemaining,
        originalTasks = service.originalTasks,
        reason = service.reason
    })
    
    if service.tasksRemaining <= 0 then
        releasePlayer(source)
    else
        utils.notify(source, locale('notify.tasks_remaining', service.tasksRemaining), 'inform')
    end
end)

---@param playerId number
---@param data table
---@return boolean
local function updateService(playerId, data)
    if not activeServices[playerId] then return false end
    
    local service = activeServices[playerId]
    local changes = {}
    
    if data.tasksRemaining then
        changes[#changes + 1] = ('tasks: %d → %d'):format(service.tasksRemaining, data.tasksRemaining)
        
        local completedTasks = service.originalTasks - service.tasksRemaining

        service.originalTasks = data.tasksRemaining
        service.tasksRemaining = data.tasksRemaining - completedTasks

        service.tasks = generateServiceTasks(service.tasksRemaining)
        
        TriggerClientEvent('peak_service:client:updateTasks', playerId, service.tasks)
    end
    
    if data.reason then
        changes[#changes + 1] = ('reason: %s → %s'):format(service.reason, data.reason)
        service.reason = data.reason
    end
    
    utils.logPlayer(playerId, {
        title = 'Community Service Updated',
        message = ('Service updated. Changes: %s'):format(table.concat(changes, ', '))
    })
    
    saveServiceData(playerId)
    
    TriggerClientEvent('peak_service:client:updateUI', playerId, {
        admin = service.admin,
        remainingTasks = service.tasksRemaining,
        completedTasks = service.originalTasks - service.tasksRemaining,
        originalTasks = service.originalTasks,
        reason = service.reason
    })
    
    return true
end

RegisterNetEvent('peak_service:server:escapePenalty', function()
    local source = source

    if not activeServices[source] then 
        return 
    end
    
    local service = activeServices[source]
    local currentTasks = service.tasksRemaining
    local newTasks = currentTasks + sharedConfig.penalties.tasks
    
    utils.logPlayer(source, {
        title = 'Community Service Escape Attempt',
        message = ('Player attempted to escape. Added %d tasks as penalty. New total: %d'):format(sharedConfig.penalties.tasks, newTasks)
    })
    
    local updated = updateService(source, {
        tasksRemaining = service.originalTasks + sharedConfig.penalties.tasks
    })
    
    if updated then
        utils.notify(source, locale('notify.escape_penalty', sharedConfig.penalties.tasks), 'error')
    end
end)

---@param identifier string
RegisterNetEvent('peak_service:server:openItemStash', function(identifier)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command') then 
        return 
    end
    
    local items = getStoredItems(identifier)
    local stashId = ('peak_service_%s'):format(identifier)
    
    exports.ox_inventory:RegisterStash(stashId, 'Community Service Items', 200, 100000)
    
    SetTimeout(200, function()
        TriggerClientEvent('ox_inventory:openInventory', source, 'stash', stashId)
        
        SetTimeout(500, function()
            exports.ox_inventory:ClearInventory(stashId)
            
            for _, item in ipairs(items) do
                exports.ox_inventory:AddItem(stashId, item.name, item.count, item.metadata)
            end
        end)
    end)
    
    local hasProcessed = false
    
    local eventHandler = function(playerId, inventoryId)
        if playerId == source and inventoryId == stashId and not hasProcessed then
            hasProcessed = true
            
            local stashItems = exports.ox_inventory:GetInventory(stashId)

            if stashItems and stashItems.items then
                local itemsToSave = {}

                for slot, item in pairs(stashItems.items) do
                    if item and item.name and item.count and item.count > 0 then
                        itemsToSave[#itemsToSave + 1] = {
                            name = item.name,
                            count = item.count,
                            metadata = item.metadata,
                            slot = slot
                        }
                    end
                end
                
                MySQL.query('DELETE FROM peak_service_items WHERE identifier = ?', { identifier })
                
                for _, item in ipairs(itemsToSave) do
                    MySQL.insert('INSERT INTO peak_service_items (identifier, item_name, count, metadata, slot) VALUES (?, ?, ?, ?, ?)', {
                        identifier,
                        item.name,
                        item.count,
                        item.metadata and json.encode(item.metadata) or nil,
                        item.slot or 1
                    })
                end
                
                utils.notify(source, locale('notify.items_saved'), 'success')
            end
        end
    end
    
    AddEventHandler('ox_inventory:closedInventory', eventHandler)
end)

---@param playerId number
---@param identifier string
---@param data table
RegisterNetEvent('peak_service:server:updateService', function(playerId, identifier, data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command') then 
        return 
    end
    
    local playerName
    local isOnline = playerId and activeServices[playerId]
    
    if isOnline then
        playerName = GetPlayerName(playerId)
    else
        if not identifier then
            utils.notify(source, locale('notify.invalid_service_data'), 'error')
            return
        end
    end

    if data.tasksRemaining == 0 then
        if isOnline then
            if releasePlayer(playerId) then
                utils.notify(source, locale('notify.player_released', playerName), 'success')
            end
        else
            MySQL.query('DELETE FROM peak_service WHERE identifier = ?', { identifier })
            
            utils.notify(source, locale('notify.offline_player_released'), 'success')
        end
    else
        if isOnline then
            if updateService(playerId, data) then
                utils.notify(source, locale('notify.service_updated', playerName), 'success')
            end
        else
            MySQL.update('UPDATE peak_service SET tasks_remaining = ?, reason = ? WHERE identifier = ?', {
                data.tasksRemaining,
                data.reason,
                identifier
            })

            utils.notify(source, locale('notify.offline_service_updated'), 'success')
        end
    end
end)

---@param resourceName string
AddEventHandler('onResourceStart', function(resourceName)
    if cache.resource ~= resourceName then return end

    local players = GetPlayers()

    for _, playerId in ipairs(players) do
        loadPlayerService(tonumber(playerId))
    end
end)
  
AddEventHandler('playerDropped', function()
    local source = source

    if activeServices[source] then
        saveServiceData(source)
    end
end)

---@param playerId number
function OnPlayerLoaded(playerId)
    loadPlayerService(playerId)
end

lib.addCommand(serverConfig.commands.services.name, {
    help = serverConfig.commands.services.help,
    restricted = serverConfig.commands.services.restricted
}, function(source)
    local services = {}
    local onlinePlayers = {}
    
    for playerId, service in pairs(activeServices) do
        local playerName = GetPlayerName(playerId)

        if playerName then
            onlinePlayers[playerId] = true
            services[#services + 1] = {
                playerId = playerId,
                playerName = playerName,
                tasksRemaining = service.tasksRemaining,
                reason = service.reason,
                admin = service.admin,
                identifier = service.identifier,
                isOnline = true
            }
        end
    end
    
    local allServices = MySQL.query.await('SELECT * FROM peak_service')
    
    if allServices then
        for _, service in ipairs(allServices) do
            local playerId = bridge.getSourceFromIdentifier(service.identifier)
            
            if not playerId or not onlinePlayers[playerId] then
                services[#services + 1] = {
                    playerId = playerId,
                    playerName = service.player_name or service.identifier,
                    tasksRemaining = service.tasks_remaining,
                    reason = service.reason,
                    admin = service.admin,
                    identifier = service.identifier,
                    isOnline = false
                }
            end
        end
    end

    TriggerClientEvent('peak_service:client:openServicesMenu', source, services)
end)

lib.addCommand(serverConfig.commands.comserv.name, {
    help = serverConfig.commands.comserv.help,
    restricted = serverConfig.commands.comserv.restricted,
}, function(source)
    local data = lib.callback.await('peak_service:client:openDialog', source)

    if not data then 
        return 
    end

    startService({
        playerId = data.playerId,
        identifier = data.identifier,
        amount = data.amount,
        reason = data.reason
    })
end)

lib.addCommand(serverConfig.commands.removecomserv.name, {
    help = serverConfig.commands.removecomserv.help,
    restricted = serverConfig.commands.removecomserv.restricted,
    params = {
        {
            name = 'playerId',
            type = 'number',
            help = 'Server ID of the player',
            optional = false
        }
    }
}, function(source, args)
    local playerId = args.playerId

    if not activeServices[playerId] then
        utils.notify(source, locale('notify.player_not_in_service'), 'error')
        return
    end

    local playerName = GetPlayerName(playerId)

    releasePlayer(playerId)

    utils.notify(source, locale('notify.player_released', playerName), 'success')
end)

