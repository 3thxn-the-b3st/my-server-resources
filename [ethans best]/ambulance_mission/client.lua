local currentBlip = nil
local missionActive = false
local spawnedPed = nil
local pendingMissionData = nil
local isWaitingForAccept = false
local activeMissionCoords = nil
local missionTimerActive = false

RegisterNetEvent('solo_ambulance:syncAlert', function(data)
    -- Double-check client side if ESX is loaded and the player has the ambulance job
    local ESX = exports['es_extended']:getSharedObject()
    local playerData = ESX.GetPlayerData()

    if not playerData or not playerData.job or playerData.job.name ~= 'ambulance' then 
        return 
    end

    if missionActive or isWaitingForAccept then return end 
    
    pendingMissionData = data
    isWaitingForAccept = true

    TriggerEvent('esx:showNotification', 'Incoming Emergency: Press [G] to accept dispatch. (Expires in 10s)')

    CreateThread(function()
        local timer = GetGameTimer() + 10000

        while GetGameTimer() < timer do
            Wait(0)

            if IsControlJustPressed(0, 47) then 
                TriggerServerEvent('solo_ambulance:acceptMission')
                StartMissionRoute(pendingMissionData)
                
                TriggerEvent('esx:showNotification', '~g~Dispatch Accepted:~s~ Route set to emergency coordinates.')
                
                isWaitingForAccept = false
                pendingMissionData = nil
                return
            end
        end

        if isWaitingForAccept then
            isWaitingForAccept = false
            pendingMissionData = nil
            TriggerEvent('esx:showNotification', '~y~Dispatch Expired:~s~ You missed the emergency call window.')
        end
    end)
end)

RegisterNetEvent('solo_ambulance:missionTaken', function()
    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end
end)

local function IsInNorthernArea(coords)
    local isSandy = (coords.x >= -300 and coords.x <= 1800 and coords.y >= 2600 and coords.y <= 4000)
    local isPaleto = (coords.x >= -400 and coords.x <= 300 and coords.y >= 4000 and coords.y <= 7200)
    return isSandy or isPaleto
end

local function CleanupMission()
    if DoesEntityExist(spawnedPed) then
        exports.ox_target:removeLocalEntity(spawnedPed, {'resolve_emergency', 'revive_patient', 'body_bag', 'check_vitals'})
        DeleteEntity(spawnedPed)
    end
    
    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end

    spawnedPed = nil
    missionActive = false
    pendingMissionData = nil
    activeMissionCoords = nil
    missionTimerActive = false
    
    lib.hideTextUI()
end

function StartMissionRoute(data)
    missionActive = true
    activeMissionCoords = data.coords
    
    if currentBlip then
        RemoveBlip(currentBlip)
    end

    currentBlip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(currentBlip, 153)
    SetBlipColour(currentBlip, 1)
    SetBlipScale(currentBlip, 1.1)
    SetBlipRoute(currentBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Active Emergency")
    EndTextCommandSetBlipName(currentBlip)

    local isNorthern = IsInNorthernArea(data.coords)
    local timeLimit = isNorthern and (8 * 60 * 1000) or (8 * 60 * 1000)

    missionTimerActive = true
    
    CreateThread(function()
        local startTime = GetGameTimer()
        local targetVec = vec3(data.coords.x, data.coords.y, data.coords.z)
        
        while missionActive and missionTimerActive do
            Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - targetVec)
            local timeLeft = timeLimit - (GetGameTimer() - startTime)

            if distance <= 35.0 then
                missionTimerActive = false
                lib.hideTextUI()
                TriggerEvent('esx:showNotification', '~g~Arrived at Scene:~s~ Stabilize or bag the patient.')
                break
            end

            if timeLeft <= 0 then
                if missionActive then
                    CleanupMission()
                    TriggerServerEvent('solo_ambulance:missionFailedFine')
                    TriggerEvent('esx:showNotification', '~r~Mission Failed:~s~ You failed to attend the emergency in time. $500 fined from your bank.')
                end
                break
            else
                local minutes = math.floor(timeLeft / 60000)
                local seconds = math.floor((timeLeft % 60000) / 1000)
                lib.showTextUI(string.format('Emergency Timer: %02d:%02d', minutes, seconds), {
                    position = 'top-center',
                    icon = 'fa-solid fa-clock',
                    style = { borderRadius = 0, backgroundColor = '#141414ba', color = 'white' }
                })
            end
        end
    end)

    CreateThread(function()
        local modelHash = `a_m_m_skidrow_01`
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 200 do 
            Wait(10)
            timeout = timeout + 1
        end

        if DoesEntityExist(spawnedPed) then
            DeleteEntity(spawnedPed)
        end

        local groundFound, groundZ = GetGroundZFor_3dCoord(data.coords.x, data.coords.y, data.coords.z + 3.0, false)
        local spawnZ = groundFound and groundZ or data.coords.z

        spawnedPed = CreatePed(4, modelHash, data.coords.x, data.coords.y, spawnZ + 0.5, 0.0, false, true)
        
        SetEntityAsMissionEntity(spawnedPed, true, true)
        SetEntityInvincible(spawnedPed, true)
        SetEntityHealth(spawnedPed, 0)
        ClearPedTasksImmediately(spawnedPed)

        FreezeEntityPosition(spawnedPed, false)
        SetPedToRagdoll(spawnedPed, 1000, 1000, 0, 0, 0, 0)
        Wait(350)
        FreezeEntityPosition(spawnedPed, true)
        SetEntityHeading(spawnedPed, math.random(0, 359) + 0.0)

        -- Optimized Marker Thread (Only renders when player is within 50 meters)
        CreateThread(function()
            while DoesEntityExist(spawnedPed) do
                local playerPed = PlayerPedId()
                local pCoords = GetEntityCoords(spawnedPed)
                local playerCoords = GetEntityCoords(playerPed)
                
                if #(playerCoords - pCoords) <= 50.0 then
                    DrawMarker(20, pCoords.x, pCoords.y, pCoords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.8, 0.8, 0.8, 255, 50, 50, 200, false, true, 2, false, nil, nil, false)
                    Wait(0)
                else
                    Wait(500) -- Sleep longer when far away to save resources
                end
            end
        end)

        SetInitialTarget(data)
    end)
end

function SetInitialTarget(data)
    exports.ox_target:removeLocalEntity(spawnedPed, {'resolve_emergency', 'revive_patient', 'body_bag', 'check_vitals'})
    
    exports.ox_target:addLocalEntity(spawnedPed, {
        {
            name = 'check_vitals',
            icon = 'fa-solid fa-stethoscope',
            label = 'Check Vitals',
            distance = 2.0,
            onSelect = function()
                local success = lib.progressBar({
                    duration = 5000,
                    label = 'Checking patient vitals and writing notes...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = {
                        dict = 'amb@medic@standing@tendtodead@idle_a',
                        clip = 'idle_a'
                    },
                    prop = {
                        model = `prop_notepad_01`,
                        bone = 18905,
                        pos = vec3(0.1, 0.02, 0.05),
                        rot = vec3(10.0, 0.0, 0.0)
                    }
                })

                if success then
                    if data.isDead then
                        TriggerEvent('esx:showNotification', 'Vitals Result: Patient has flatlined. A body bag is required.')
                        SetBodyBagTarget()
                    else
                        TriggerEvent('esx:showNotification', '~g~Vitals Result:~s~ Patient has a weak pulse! Prepare to revive.')
                        SetReviveTarget()
                    end
                end
            end
        }
    })
end

function SetReviveTarget()
    exports.ox_target:removeLocalEntity(spawnedPed, 'check_vitals')

    exports.ox_target:addLocalEntity(spawnedPed, {
        {
            name = 'revive_patient',
            icon = 'fa-solid fa-briefcase-medical',
            label = 'Revive Patient (Perform CPR)',
            distance = 2.0,
            onSelect = function()
                local success = lib.progressBar({
                    duration = 6000,
                    label = 'Performing CPR / Medical treatment...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = {
                        dict = 'mini@cpr@char_a@cpr_str',
                        clip = 'cpr_pumpchest'
                    }
                })

                if success then
                    FreezeEntityPosition(spawnedPed, false)
                    SetEntityInvincible(spawnedPed, false)
                    SetEntityHealth(spawnedPed, 200)
                    ClearPedTasksImmediately(spawnedPed)
                    TaskWanderStandard(spawnedPed, 10.0, 10)

                    TriggerServerEvent('solo_ambulance:reward', 3000, "revive")
                    TriggerEvent('esx:showNotification', '~g~Success:~s~ Patient has been successfully resuscitated!')

                    local savedPed = spawnedPed
                    spawnedPed = nil
                    
                    CleanupMission()

                    SetTimeout(30000, function()
                        if DoesEntityExist(savedPed) then
                            DeleteEntity(savedPed)
                        end
                    end)
                end
            end
        }
    })
end

function SetBodyBagTarget()
    exports.ox_target:removeLocalEntity(spawnedPed, 'check_vitals')

    exports.ox_target:addLocalEntity(spawnedPed, {
        {
            name = 'body_bag',
            icon = 'fa-solid fa-user-injured',
            label = 'Place Body Bag',
            distance = 2.0,
            onSelect = function()
                local success = lib.progressBar({
                    duration = 5000,
                    label = 'Securing body in a bag...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = {
                        dict = 'amb@medic@standing@tendtodead@idle_a',
                        clip = 'idle_a'
                    }
                })

                if success then
                    local pedCoords = GetEntityCoords(spawnedPed)
                    local pedHeading = GetEntityHeading(spawnedPed)
                    
                    if DoesEntityExist(spawnedPed) then
                        DeleteEntity(spawnedPed)
                    end

                    local propModel = `xm_prop_body_bag`
                    RequestModel(propModel)
                    local timeout = 0
                    while not HasModelLoaded(propModel) and timeout < 200 do
                        Wait(10)
                        timeout = timeout + 1
                    end

                    if HasModelLoaded(propModel) then
                        local bodyBagProp = CreateObject(propModel, pedCoords.x, pedCoords.y, pedCoords.z + 0.5, true, true, true)
                        
                        if DoesEntityExist(bodyBagProp) then
                            SetEntityHeading(bodyBagProp, pedHeading)
                            PlaceObjectOnGroundProperly(bodyBagProp)
                            
                            FreezeEntityPosition(bodyBagProp, false)
                            Wait(100)
                            FreezeEntityPosition(bodyBagProp, true)

                            SetTimeout(30000, function()
                                if DoesEntityExist(bodyBagProp) then
                                    DeleteEntity(bodyBagProp)
                                end
                            end)
                        end
                    end

                    TriggerServerEvent('solo_ambulance:reward', 1000, "bodybag")
                    TriggerEvent('esx:showNotification', '~g~Success:~s~ Body secured in a bag. $1,000 deposited to your bank.')
                    
                    CleanupMission()
                end
            end
        }
    })
end

RegisterCommand('missingbody', function()
    if not missionActive or not activeMissionCoords then
        TriggerEvent('esx:showNotification', 'Command Failed: You do not have an active emergency mission.')
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - activeMissionCoords)

    if distance <= 75.0 then
        CleanupMission()
        TriggerServerEvent('solo_ambulance:reward', 0, "cancel")
        TriggerEvent('esx:showNotification', 'Dispatch Cancelled: Declared missing body. Searching for new calls...')
    else
        TriggerEvent('esx:showNotification', '~r~Too Far:~s~ You must be within the emergency perimeter to declare a missing body.')
    end
end, false)

--- Crouching Module
local isCrouched = false

CreateThread(function()
    RequestAnimSet("move_ped_crouched")
    while not HasAnimSetLoaded("move_ped_crouched") do
        Wait(5)
    end
end)

local function ToggleCrouch()
    local playerPed = PlayerPedId()

    if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
        if IsPedInAnyVehicle(playerPed, false) or not IsPedOnFoot(playerPed) then return end

        isCrouched = not isCrouched

        if isCrouched then
            SetPedMovementClipset(playerPed, "move_ped_crouched", 0.15)
            SetPedStrafeClipset(playerPed, "move_ped_crouched_strafing", 0.15)
            SetPedUsingActionMode(playerPed, false, -1, "DEFAULT_ACTION")
        else
            ResetPedMovementClipset(playerPed, 0.15)
            ResetPedStrafeClipset(playerPed)
        end
    end
end

RegisterCommand("crouch", function()
    ToggleCrouch()
end, false)

RegisterKeyMapping("crouch", "Toggle Crouch", "keyboard", "LCONTROL")