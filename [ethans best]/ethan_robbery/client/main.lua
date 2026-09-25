local activeRobbery = nil
local spawnedPeds = {}
local inLobby = false
local currentLobbyIndex = nil
local activePoliceVehicles = {}
local activePolicePeds = {}

--------------------------------------------------------------------------------
-- Helper Function: Native ESX Notification Wrapper
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:showNotification', function(msg)
    ESX.ShowNotification(msg)
end)

--------------------------------------------------------------------------------
-- Helper Function: Calculate Precise Floor Elevation inside MLOs
--------------------------------------------------------------------------------
local function GetCorrectGroundZ(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    
    local interior = GetInteriorAtCoords(x, y, z)
    if interior ~= 0 then
        LoadInterior(interior)
    end

    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    local attempts = 0

    while not foundGround and attempts < 20 do
        Wait(50)
        foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        attempts = attempts + 1
    end

    return foundGround and groundZ or z
end

--------------------------------------------------------------------------------
-- Ped Spawning Thread
--------------------------------------------------------------------------------
CreateThread(function()
    RequestModel(Config.PedModel)
    while not HasModelLoaded(Config.PedModel) do Wait(10) end

    for index, coords in ipairs(Config.Peds) do
        local correctZ = GetCorrectGroundZ(coords.x, coords.y, coords.z)
        
        local ped = CreatePed(4, Config.PedModel, coords.x, coords.y, correctZ, coords.w, false, true)
        
        SetEntityHeading(ped, coords.w)
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, correctZ, false, false, false)
        
        Wait(200)
        
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        spawnedPeds[index] = ped
    end
end)

--------------------------------------------------------------------------------
-- Aim Detection Logic to Initiate Robbery
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()

        if IsPlayerFreeAiming(PlayerId()) and not activeRobbery then
            local _, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if DoesEntityExist(targetEntity) then
                for index, ped in ipairs(spawnedPeds) do
                    if targetEntity == ped then
                        sleep = 250
                        local pCoords = GetEntityCoords(playerPed)
                        local pedCoords = GetEntityCoords(ped)
                        if #(pCoords - pedCoords) < 10.0 then
                            TriggerServerEvent('esx_robbery:requestLobby', index)
                            Wait(5000)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

--------------------------------------------------------------------------------
-- Lobby Key Prompt (Press G to Join)
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:showJoinPrompt', function(storeIndex)
    inLobby = true
    currentLobbyIndex = storeIndex
    
    ESX.ShowNotification("Robbery Started! Press ~g~[G]~s~ to join the robbery lobby!")

    CreateThread(function()
        local timer = GetGameTimer() + (Config.LobbyDuration * 1000)
        while inLobby and GetGameTimer() < timer do
            if IsControlJustPressed(0, 47) then -- Key: G
                TriggerServerEvent('esx_robbery:joinLobby', currentLobbyIndex)
                inLobby = false
                break
            end
            Wait(0)
        end
        inLobby = false
    end)
end)

--------------------------------------------------------------------------------
-- NUI Interface Communication
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:updateUI', function(data)
    SendNUIMessage({
        action = "updateLobby",
        display = data.display,
        status = data.status,
        members = data.members,
        timer = data.timer
    })
end)

--------------------------------------------------------------------------------
-- Emergency Dispatch Alert & Pulsing Blip
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:emergencyAlert', function(coords)
    local xPlayer = ESX.GetPlayerData()
    if xPlayer.job and (xPlayer.job.name == 'police' or xPlayer.job.name == 'ambulance') then
        ESX.ShowNotification("~r~EMERGENCY DISPATCH:~s~ Store robbery in progress!")
        
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 1.2)
        SetBlipColour(blip, 1)
        SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Robbery in Progress")
        EndTextCommandSetBlipName(blip)

        Wait(Config.RobberyDuration * 1000)
        RemoveBlip(blip)
    end
end)

--------------------------------------------------------------------------------
-- Store Ped Safe Animation Routine
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:startStoreAnimation', function(storeIndex)
    local ped = spawnedPeds[storeIndex]
    if not ped then return end

    RequestAnimDict("mp_am_hold_up")
    while not HasAnimDictLoaded("mp_am_hold_up") do Wait(10) end

    TaskPlayAnim(ped, "mp_am_hold_up", "holdup_victim_20s", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    Wait(Config.RobberyDuration * 1000)
    
    ClearPedTasks(ped)
end)

--------------------------------------------------------------------------------
-- Dynamic Police Wave Spawner
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:spawnPoliceWave', function(coords, carCount)
    local vehicleModel = `police`
    local officerModel = `s_m_y_cop_01`
    local spawnAmount = carCount or Config.PoliceCarCount

    RequestModel(vehicleModel)
    RequestModel(officerModel)
    while not HasModelLoaded(vehicleModel) or not HasModelLoaded(officerModel) do Wait(10) end

    for i = 1, spawnAmount do
        local spawnVector = vec3(coords.x + math.random(-40, 40), coords.y + math.random(-40, 40), coords.z)
        local _, outPos, outHeading = GetClosestVehicleNodeWithHeading(spawnVector.x, spawnVector.y, spawnVector.z, 1, 3.0, 0)
        
        if outPos then
            local veh = CreateVehicle(vehicleModel, outPos.x, outPos.y, outPos.z, outHeading, true, true)
            table.insert(activePoliceVehicles, veh)

            for seat = -1, 2 do
                local cop = CreatePedInsideVehicle(veh, 6, officerModel, seat, true, true)
                GiveWeaponToPed(cop, `WEAPON_PISTOL`, 250, false, true)
                SetPedCombatAttributes(cop, 46, true)
                SetPedAccuracy(cop, 60)
                TaskCombatPed(cop, PlayerPedId(), 0, 16)
                table.insert(activePolicePeds, cop)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- Cleanup Active Police NPCs and Vehicles
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:clearPoliceNpc', function()
    for _, ped in ipairs(activePolicePeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, veh in ipairs(activePoliceVehicles) do
        if DoesEntityExist(veh) then DeleteEntity(veh) end
    end
    activePolicePeds = {}
    activePoliceVehicles = {}
end)