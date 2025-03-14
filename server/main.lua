local sharedConfig = require 'config.shared'
local serverConfig = require 'config.server'
local utils = require 'modules.utils.server'
local activeServices = {}
local taskTime = {}

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `peak_service` (
            `identifier` varchar(60) NOT NULL,
            `tasks_remaining` int DEFAULT 0,
            `original_tasks` int DEFAULT 0,
            `admin` varchar(60) NOT NULL,
            `reason` varchar(255) NOT NULL,
            `original_position` varchar(255) NOT NULL,
            PRIMARY KEY (`identifier`)
        )
    ]])
end)

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

    if not player or not identifier then return end
    
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

        activeServices[playerId] = {
            tasksRemaining = result.tasks_remaining,
            originalTasks = result.original_tasks,
            admin = result.admin,
            reason = result.reason,
            identifier = identifier,
            originalPosition = originalPos,
            tasks = tasks
        }

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

    if not service or not service.identifier then return end
    
    MySQL.update('INSERT INTO peak_service (identifier, tasks_remaining, original_tasks, admin, reason, original_position) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE tasks_remaining = VALUES(tasks_remaining), original_tasks = VALUES(original_tasks), admin = VALUES(admin), reason = VALUES(reason), original_position = VALUES(original_position)', {
        service.identifier,
        service.tasksRemaining,
        service.originalTasks,
        service.admin,
        service.reason,
        json.encode(service.originalPosition)
    })
end

---@param playerId number
local function releasePlayer(playerId)
    if not activeServices[playerId] then return end
    
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
        exports.ox_inventory:ReturnInventory(playerId)
    end
    
    activeServices[playerId] = nil
    
    TriggerClientEvent('peak_service:client:releaseFromService', playerId, originalPosition)
    utils.notify(playerId, locale('notify.service_completed'), 'success')
end

---@param data table
local function startService(data)
    local admin = source
    
    if not IsPlayerAceAllowed(admin, 'command') then return end
    
    local target = tonumber(data.playerId)
    local identifier = data.identifier

    if target and activeServices[target] then 
        utils.notify(admin, locale('notify.already_in_service'), 'error')
        return 
    end

    local targetPlayer, originalPosition

    if target then
        if not GetPlayerName(target) then
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
                exports.ox_inventory:ConfiscateInventory(target)
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
            originalPosition = originalPosition,
            tasks = tasks
        }
    end

    MySQL.update('INSERT INTO peak_service (identifier, tasks_remaining, original_tasks, admin, reason, original_position) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE tasks_remaining = VALUES(tasks_remaining), original_tasks = VALUES(original_tasks), admin = VALUES(admin), reason = VALUES(reason)', {
        identifier,
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

    if not taskIndex or type(taskIndex) ~= 'number' then return end
    
    local service = activeServices[source]
    
    if not service.tasks or not service.tasks[taskIndex] then return end

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

RegisterNetEvent('peak_service:server:escapePenalty', function()
    local source = source
    if not activeServices[source] then return end
    
    local service = activeServices[source]
    service.tasksRemaining = service.tasksRemaining + sharedConfig.penalties.tasks
    
    utils.logPlayer(source, {
        title = 'Community Service Escape Attempt',
        message = ('Player attempted to escape. Added %d tasks as penalty. New total: %d'):format(sharedConfig.penalties.tasks, service.tasksRemaining)
    })
    
    saveServiceData(source)
    
    TriggerClientEvent('peak_service:client:updateUI', source, {
        admin = service.admin,
        remainingTasks = service.tasksRemaining,
        originalTasks = service.originalTasks,
        reason = service.reason
    })
    
    utils.notify(source, locale('notify.escape_penalty', sharedConfig.penalties.tasks), 'error')
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
        service.tasksRemaining = data.tasksRemaining

        if data.tasksRemaining > (service.originalTasks - completedTasks) then
            service.originalTasks = data.tasksRemaining + completedTasks
        end
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

---@param playerId number
---@param data table
RegisterNetEvent('peak_service:server:updateService', function(playerId, data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command') then return end
    
    if not activeServices[playerId] then
        utils.notify(source, locale('notify.player_not_in_service'), 'error')
        return
    end

    local playerName = GetPlayerName(playerId)

    if data.tasksRemaining == 0 then
        releasePlayer(playerId)
        utils.notify(source, locale('notify.player_released', playerName), 'success')
    else
        if updateService(playerId, data) then
            utils.notify(source, locale('notify.service_updated', playerName), 'success')
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
    
    for playerId, service in pairs(activeServices) do
        local playerName = GetPlayerName(playerId)
        if playerName then
            services[#services + 1] = {
                playerId = playerId,
                playerName = playerName,
                tasksRemaining = service.tasksRemaining,
                reason = service.reason,
                admin = service.admin
            }
        end
    end

    TriggerClientEvent('peak_service:client:openServicesMenu', source, services)
end)

lib.addCommand(serverConfig.commands.comserv.name, {
    help = serverConfig.commands.comserv.help,
    restricted = serverConfig.commands.comserv.restricted,
}, function(source)
    local data = lib.callback.await('peak_service:client:openDialog', source)
    if not data then return end

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

