local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local isHandcuffed = false
local blackMarketZoneId = nil

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    if PlayerData.job and PlayerData.job.name == Config.JobName then
        TriggerServerEvent('esx_gangjob:requestBlackMarket')
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    if PlayerData.job and PlayerData.job.name == Config.JobName then
        TriggerServerEvent('esx_gangjob:requestBlackMarket')
    end
end)

-- Initialize ox_target Options for Players and Vehicles
CreateThread(function()
    -- Player Interactions via ox_target
    exports.ox_target:addGlobalPlayer({
        {
            name = 'gang_cuff_player',
            icon = 'fas fa-hands-bound',
            label = 'Restrain / Unrestrain',
            groups = Config.JobName,
            item = Config.HandcuffItem,
            distance = 2.0,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                TriggerServerEvent('esx_gangjob:cuffPlayer', targetServerId)
            end
        },
        {
            name = 'gang_put_in_vehicle',
            icon = 'fas fa-sign-in-alt',
            label = 'Put in Vehicle',
            groups = Config.JobName,
            distance = 2.5,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                TriggerServerEvent('esx_gangjob:putInVehicle', targetServerId)
            end
        },
        {
            name = 'gang_take_out_vehicle',
            icon = 'fas fa-sign-out-alt',
            label = 'Take out from Vehicle',
            groups = Config.JobName,
            distance = 2.5,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                TriggerServerEvent('esx_gangjob:outVehicle', targetServerId)
            end
        }
    })

    -- Vehicle Interactions via ox_target
    exports.ox_target:addGlobalVehicle({
        {
            name = 'gang_search_vehicle',
            icon = 'fas fa-search',
            label = 'Search Vehicle',
            groups = Config.JobName,
            distance = 3.0,
            onSelect = function(data)
                local plate = ESX.Math.Trim(GetVehicleNumberPlateText(data.entity))
                TriggerEvent('esx_inventoryhud:openTrunkInventory', plate, GetVehicleEngineHealth(data.entity))
            end
        }
    })
end)

-- Dynamic Black Market Zone via ox_target
RegisterNetEvent('esx_gangjob:updateBlackMarket', function(locationIndex)
    local targetCoords = Config.BlackMarketLocations[locationIndex]

    if blackMarketZoneId then
        exports.ox_target:removeZone(blackMarketZoneId)
        blackMarketZoneId = nil
    end

    blackMarketZoneId = exports.ox_target:addSphereZone({
        coords = targetCoords,
        radius = 1.5,
        debug = false,
        options = {
            {
                name = 'open_blackmarket',
                icon = 'fas fa-user-ninja',
                label = 'Access Black Market',
                groups = Config.JobName,
                distance = 2.0,
                onSelect = function()
                    OpenBlackMarketMenu()
                end
            }
        }
    })

    ESX.ShowNotification("The Black Market location has shifted.")
end)

-- Open Black Market Menu
function OpenBlackMarketMenu()
    local elements = {}
    for _, v in ipairs(Config.BlackMarketItems) do
        table.insert(elements, {
            label = v.label .. " - <span style='color:red;'>$" .. v.price .. " (Black Money)</span>",
            value = v.name,
            price = v.price,
            isWeapon = v.isWeapon
        })
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'black_market', {
        title    = 'Black Market',
        align    = 'bottom-right',
        elements = elements
    }, function(data, menu)
        TriggerServerEvent('esx_gangjob:buyBlackMarketItem', data.current.value, data.current.isWeapon, data.current.price)
    end, function(data, menu)
        menu.close()
    end)
end

-- Handcuff Client Logic
RegisterNetEvent('esx_gangjob:cuffClient', function()
    local playerPed = PlayerPedId()
    isHandcuffed = not isHandcuffed

    CreateThread(function()
        if isHandcuffed then
            RequestAnimDict('mp_arresting')
            while not HasAnimDictLoaded('mp_arresting') do Wait(100) end
            TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
            SetEnableHandcuffs(playerPed, true)
            DisablePlayerFiring(playerPed, true)
            SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
        else
            ClearPedTasks(playerPed)
            SetEnableHandcuffs(playerPed, false)
            DisablePlayerFiring(playerPed, false)
        end
    end)
end)

-- Vehicle Actions Client Logic
RegisterNetEvent('esx_gangjob:putInVehicleClient', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    if isHandcuffed and IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
        local vehicle = ESX.Game.GetClosestVehicle(coords)
        if DoesEntityExist(vehicle) then
            local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
            local freeSeat = nil

            for i = maxSeats - 1, 0, -1 do
                if IsVehicleSeatFree(vehicle, i) then
                    freeSeat = i
                    break
                end
            end

            if freeSeat then
                TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
            end
        end
    end
end)

RegisterNetEvent('esx_gangjob:outVehicleClient', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        TaskLeaveVehicle(playerPed, vehicle, 16)
    end
end)