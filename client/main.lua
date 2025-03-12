local config = require 'config.client'
local sharedConfig = require 'config.shared'
local utils = require 'modules.utils.client'
local currentTasks = nil
local currentPoint = nil

---@return table<string, string>
local function getUILocales()
    local ui = {}

    for key, value in pairs(lib.getLocales()) do
        if key:sub(1, 4) == 'nui.' then
            ui[key:sub(5)] = value
        end
    end

    return ui
end

---@param action string
---@param data table|string|boolean
local function sendNUIMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

---@param location table
local function teleportToService(location)
    SetEntityCoords(cache.ped, location.center.x, location.center.y, location.center.z, false, false, false, true)
end

---@param coords vector3
---@return number
local function createTaskBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, config.blip.sprite)
    SetBlipColour(blip, config.blip.color)
    SetBlipScale(blip, config.blip.scale)
    SetBlipAsShortRange(blip, config.blip.shortRange)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(locale('ui.service_task'))
    EndTextCommandSetBlipName(blip)

    return blip
end

---@param task table
---@param taskIndex number
local function startTaskAtLocation(task, taskIndex)
    if lib.progressCircle({
        duration = task.duration,
        label = task.label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = task.animation.dict,
            clip = task.animation.clip,
            flag = task.animation.flag
        },
    }) then 
        lib.hideTextUI()
        TriggerServerEvent('peak_service:server:taskCompleted', taskIndex)
    end
end

local function cleanupService()
    if currentPoint then
        if currentPoint.zonePoint then
            currentPoint.zonePoint:remove()
        end
        
        if currentPoint.blip then
            RemoveBlip(currentPoint.blip)
        end

        currentPoint:remove()
        currentPoint = nil
    end

    currentTasks = nil
    lib.hideTextUI()
end

---@param data table
RegisterNetEvent('peak_service:client:startService', function(data)
    currentTasks = data.tasks
    teleportToService(data.location)

    sendNUIMessage('setVisible', true)

    sendNUIMessage('updateServiceData', {
        admin = data.admin,
        remainingTasks = 0,
        originalTasks = data.originalTasks,
        reason = data.reason,
        locales = getUILocales()
    })

    local lastPenaltyTime = 0

    local zone = lib.points.new({
        coords = data.location.center,
        distance = data.location.radius,
        zoneData = data.location
    })

    function zone:onExit()
        if sharedConfig.penalties.enabled and (GetGameTimer() - lastPenaltyTime) > 10000 then
            lastPenaltyTime = GetGameTimer()
            TriggerServerEvent('peak_service:server:escapePenalty')
        end
        
        SetEntityCoords(cache.ped, self.coords.x, self.coords.y, self.coords.z, false, false, false, true)
    
        utils.notify(locale('notify.cannot_leave'), 'error')
    end

    local currentTaskIndex = 1

    local function createNewTaskPoint()
        if currentPoint then
            currentPoint:remove()
        end

        if not currentTasks or not currentTasks[currentTaskIndex] then
            return
        end

        local task = currentTasks[currentTaskIndex]

        currentPoint = lib.points.new({
            coords = task.coords,
            distance = config.marker.drawDistance,
            task = task,
            blip = createTaskBlip(task.coords),
            nearby = function(self)
                DrawMarker(config.marker.type, self.coords.x, self.coords.y, self.coords.z, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                    config.marker.scale.x, config.marker.scale.y, config.marker.scale.z, 
                    config.marker.color.r, config.marker.color.g, config.marker.color.b, config.marker.color.a * 255, 
                    false, true, 2, false, nil, nil, false)
                if self.currentDistance < 1.5 then
                    if not IsNuiFocused() then
                        lib.showTextUI(locale('ui.task_action', self.task.label))
                    end
                    
                    if IsControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        startTaskAtLocation(self.task, currentTaskIndex)
                        
                        if self.blip then
                            RemoveBlip(self.blip)
                        end
                        
                        currentTaskIndex = currentTaskIndex % #currentTasks + 1
                        createNewTaskPoint()
                    end
                else
                    lib.hideTextUI()
                end
            end
        })

        function currentPoint:onEnter()
            if self.currentDistance < 1.5 then
                lib.showTextUI(locale('ui.task_action', self.task.label))
            end
        end

        function currentPoint:onExit()
            lib.hideTextUI()
        end

        function currentPoint:onRemove()
            if self.blip then
                RemoveBlip(self.blip)
            end
            lib.hideTextUI()
        end
    end

    createNewTaskPoint()
end)

---@param data table
RegisterNetEvent('peak_service:client:updateUI', function(data)
    sendNUIMessage('updateServiceData', {
        admin = data.admin,
        remainingTasks = data.originalTasks - data.remainingTasks,
        originalTasks = data.originalTasks,
        reason = data.reason
    })
end)

---@param originalPosition table
RegisterNetEvent('peak_service:client:releaseFromService', function(originalPosition)
    cleanupService()

    if originalPosition then
        SetEntityCoords(cache.ped, originalPosition.x, originalPosition.y, originalPosition.z, false, false, false, true)
    end
    
    sendNUIMessage('setVisible', false)
end)

lib.callback.register('peak_service:client:openDialog', function()
    local input = lib.inputDialog(locale('dialog.title'), {
        {
            type = 'select',
            label = locale('dialog.type'),
            options = {
                { label = locale('dialog.type_id'), value = 'id' },
                { label = locale('dialog.type_identifier'), value = 'identifier' }
            },
            required = true
        },
        {
            type = 'input',
            label = locale('dialog.target'),
            description = locale('dialog.target_desc'),
            required = true
        },
        {
            type = 'number',
            label = locale('dialog.amount'),
            description = locale('dialog.amount_desc'),
            required = true,
            min = 1,
            max = 100
        },
        {
            type = 'input',
            label = locale('dialog.reason'),
            description = locale('dialog.reason_desc'),
            required = true
        }
    })

    if not input then return end

    return {
        playerId = input[1] == 'id' and tonumber(input[2]) or nil,
        identifier = input[1] == 'identifier' and input[2] or nil,
        amount = input[3],
        reason = input[4]
    }
end)

---@param services table
RegisterNetEvent('peak_service:client:openServicesMenu', function(services)
    if not services or #services == 0 then
        utils.notify(locale('ui.no_players'), 'inform')
        return
    end

    local options = {}
    for _, service in ipairs(services) do
        options[#options + 1] = {
            title = locale('ui.player_entry', service.playerName, service.tasksRemaining),
            description = locale('ui.player_description', service.reason, service.admin),
            metadata = {
                { label = locale('ui.player_id_input.label'), value = service.playerId },
                { label = locale('ui.tasks_label'), value = service.tasksRemaining },
                { label = locale('ui.admin_label'), value = service.admin }
            },
            arrow = true,
            onSelect = function()
                lib.registerContext({
                    id = ('service_player_%s'):format(service.playerId),
                    title = locale('ui.manage_player', service.playerName),
                    menu = 'community_service_menu',
                    options = {
                        {
                            title = locale('ui.update_button'),
                            description = locale('ui.update_description'),
                            onSelect = function()
                                local input = lib.inputDialog(locale('ui.update_service'), {
                                    {
                                        type = 'number',
                                        label = locale('ui.tasks_input.label'),
                                        description = locale('ui.tasks_input.description'),
                                        default = service.tasksRemaining,
                                        required = true,
                                        min = 0,
                                        max = 1000
                                    },
                                    {
                                        type = 'input',
                                        label = locale('ui.reason_input.label'),
                                        description = locale('ui.reason_input.description'),
                                        default = service.reason,
                                        required = true
                                    }
                                })

                                if not input then return end
                                
                                local tasksRemaining, reason = tonumber(input[1]), input[2]
                                
                                TriggerServerEvent('peak_service:server:updateService', service.playerId, {
                                    tasksRemaining = tasksRemaining,
                                    reason = reason
                                })
                            end
                        },
                        {
                            title = locale('ui.release_button'),
                            description = locale('ui.release_description'),
                            onSelect = function()
                                TriggerServerEvent('peak_service:server:updateService', service.playerId, {
                                    tasksRemaining = 0
                                })
                            end
                        }
                    }
                })
                lib.showContext(('service_player_%s'):format(service.playerId))
            end
        }
    end

    lib.registerContext({
        id = 'community_service_menu',
        title = locale('ui.services_title'),
        options = options
    })

    lib.showContext('community_service_menu')
end)

