local ESX = exports['es_extended']:getSharedObject()

local isPromptActive = false
local hasJoinedPrompt = false
local isCarryingCrate = false
local isInRaidMission = false
local isGuidedToContact = false
local raidTimerSeconds = 600
local carriedPropEntity = nil

local contactBlip = nil
local warehouseBlip = nil
local deliveryBlip = nil
local policeLiveBlip = nil
local contactPedEntity = nil
local currentDropoffCoords = nil

local activeGuards = {}
local activeGuardBlips = {}
local activeDropoffGuards = {}
local activeDropoffBlips = {}
local activeCrateProps = {}
local activeNpcPolice = {}
local activeNpcVehicles = {}
local currentRaidData = nil
local getawayTargetAdded = false

local function IsGangMember()
    local xPlayer = ESX.GetPlayerData()
    return xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData.job = job
    if job.name ~= Config.JobName then
        if isInRaidMission or isPromptActive or isGuidedToContact then
            TriggerEvent('gang_mission:finishRaid')
        end
    end
end)

CreateThread(function()
    local startCfg = Config.WarehouseRaid.ContactPed
    RequestModel(startCfg.model)
    while not HasModelLoaded(startCfg.model) do Wait(10) end

    contactPedEntity = CreatePed(4, startCfg.model, startCfg.coords.x, startCfg.coords.y, startCfg.coords.z - 1.0, startCfg.coords.w, false, true)
    SetEntityHeading(contactPedEntity, startCfg.coords.w)
    FreezeEntityPosition(contactPedEntity, true)
    SetEntityInvincible(contactPedEntity, true)
    SetBlockingOfNonTemporaryEvents(contactPedEntity, true)

    exports.ox_target:addLocalEntity(contactPedEntity, {
        {
            name = 'gang_contact_instructions',
            icon = 'fas fa-comment-dots',
            label = 'Receive Mission Instructions',
            groups = Config.JobName,
            distance = 2.5,
            onSelect = function()
                if IsGangMember() then
                    TriggerServerEvent('gang_mission:server:requestNPCStart')
                end
            end
        }
    })
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if (isGuidedToContact or isInRaidMission) and IsGangMember() then
            sleep = 0
            if contactPedEntity and DoesEntityExist(contactPedEntity) then
                local cCoords = GetEntityCoords(contactPedEntity)
                DrawMarker(2, cCoords.x, cCoords.y, cCoords.z + 1.2, 0,0,0, 0,180.0,0, 0.4,0.4,0.4, 0,255,100,200, false,true,2,false)
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('gang_mission:client:startRaidPrompt', function(duration)
    if not IsGangMember() then return end

    isPromptActive = true
    hasJoinedPrompt = false

    ESX.ShowNotification("~g~WAREHOUSE RAID:~s~ Operation available! Press ~g~[G]~s~ within " .. duration .. "s to opt in.")

    CreateThread(function()
        while isPromptActive and not hasJoinedPrompt and IsGangMember() do
            Wait(0)
            if IsControlJustReleased(0, 47) then
                hasJoinedPrompt = true
                TriggerServerEvent('gang_mission:server:joinRaidPrompt')
                ESX.ShowNotification("~g~Joined raid roster!~s~ Waiting for prompt window to end...")
                break
            end
        end
    end)
end)

RegisterNetEvent('gang_mission:client:updateRaidRoster', function(participantData, stageText, timerVal)
    if not IsGangMember() or (not isInRaidMission and not isPromptActive and not isGuidedToContact) then
        SendNUIMessage({ action = 'hide' })
        return
    end

    SendNUIMessage({
        action = 'updateRoster',
        participants = participantData,
        stageText = stageText,
        timerVal = (stageText == 'IN PROGRESS') and raidTimerSeconds or timerVal,
        isPromptActive = isPromptActive,
        hasJoined = hasJoinedPrompt
    })
end)

RegisterNetEvent('gang_mission:client:closeRaidPrompt', function()
    isPromptActive = false
    hasJoinedPrompt = false
    SendNUIMessage({ action = 'hide' })
end)

RegisterNetEvent('gang_mission:client:guideToContactNPC', function(contactCoords)
    if not IsGangMember() then return end

    isGuidedToContact = true
    ESX.ShowNotification("~g~Roster Confirmed!~s~ Proceed to the Contact NPC to receive instructions.")

    contactBlip = AddBlipForCoord(contactCoords.x, contactCoords.y, contactCoords.z)
    SetBlipSprite(contactBlip, 133)
    SetBlipColour(contactBlip, 5)
    SetBlipRoute(contactBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Mission Contact Point")
    EndTextCommandSetBlipName(contactBlip)
end)

RegisterNetEvent('gang_mission:startRaidClient', function(data)
    if not IsGangMember() then return end

    currentRaidData = data
    isInRaidMission = true
    isGuidedToContact = false
    raidTimerSeconds = Config.WarehouseRaid.Timeout / 1000

    if contactBlip then RemoveBlip(contactBlip) end

    SetTimecycleModifier("HeistInResponse5")
    PlaySoundFrontend(-1, "Pre_Screen_Stinger", "DLC_HEISTS_FAILED_WITH_SETUP_SOUNDS", true)

    local whData = Config.WarehouseRaid.Warehouses[data.whIndex]

    warehouseBlip = AddBlipForCoord(whData.coords.x, whData.coords.y, whData.coords.z)
    SetBlipSprite(warehouseBlip, 473)
    SetBlipColour(warehouseBlip, 1)
    SetBlipRoute(warehouseBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Warehouse Target")
    EndTextCommandSetBlipName(warehouseBlip)

    RequestModel(whData.guardModel)
    while not HasModelLoaded(whData.guardModel) do Wait(10) end

    for _, gPos in ipairs(whData.guards) do
        local guard = CreatePed(4, whData.guardModel, gPos.x, gPos.y, gPos.z - 1.0, gPos.w, true, true)
        GiveWeaponToPed(guard, `WEAPON_MICROSMG`, 255, false, true)
        SetPedAccuracy(guard, 60)
        SetPedArmour(guard, 50)
        SetPedRelationshipGroupHash(guard, `HATES_PLAYER`)
        TaskCombatPed(guard, PlayerPedId())
        table.insert(activeGuards, guard)

        local gBlip = AddBlipForEntity(guard)
        SetBlipSprite(gBlip, 1)
        SetBlipColour(gBlip, 1)
        SetBlipScale(gBlip, 0.8)
        table.insert(activeGuardBlips, { ped = guard, blip = gBlip })
    end

    local crateModel = Config.WarehouseRaid.CrateModel
    RequestModel(crateModel)
    while not HasModelLoaded(crateModel) do Wait(10) end

    for idx, cPos in ipairs(whData.crates) do
        local crateObj = CreateObject(crateModel, cPos.x, cPos.y, cPos.z - 1.0, true, true, false)
        FreezeEntityPosition(crateObj, true)
        table.insert(activeCrateProps, crateObj)

        exports.ox_target:addLocalEntity(crateObj, {
            {
                name = 'pickup_cargo_' .. idx,
                icon = 'fas fa-box',
                label = 'Pick up Cargo Crate',
                groups = Config.JobName,
                distance = 2.0,
                canInteract = function() return not isCarryingCrate and IsGangMember() end,
                onSelect = function() TriggerServerEvent('gang_mission:pickupCargo', idx) end
            }
        })
    end

    CreateThread(function()
        while currentRaidData and not getawayTargetAdded do
            Wait(1000)
            local netId = currentRaidData.getawayNetId
            if netId and netId ~= 0 and NetworkDoesNetworkIdExist(netId) then
                local getawayEnt = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(getawayEnt) then
                    getawayTargetAdded = true
                    exports.ox_target:addLocalEntity(getawayEnt, {
                        {
                            name = 'load_cargo_vehicle',
                            icon = 'fas fa-truck-loading',
                            label = 'Load Cargo into Vehicle',
                            groups = Config.JobName,
                            distance = 3.0,
                            canInteract = function() return isCarryingCrate and IsGangMember() end,
                            onSelect = function() TriggerServerEvent('gang_mission:loadCargo') end
                        }
                    })
                end
            end
        end
    end)

    CreateThread(function()
        while isInRaidMission and raidTimerSeconds > 0 and IsGangMember() do
            Wait(1000)
            if not isInRaidMission then break end

            raidTimerSeconds = raidTimerSeconds - 1
            SendNUIMessage({
                action = 'updateRoster',
                stageText = 'IN PROGRESS',
                timerVal = raidTimerSeconds
            })
        end
    end)

    CreateThread(function()
        while isInRaidMission and IsGangMember() do
            Wait(0)
            for _, guard in ipairs(activeGuards) do
                if DoesEntityExist(guard) and not IsEntityDead(guard) then
                    local gCoords = GetEntityCoords(guard)
                    DrawMarker(0, gCoords.x, gCoords.y, gCoords.z + 1.1, 0,0,0, 0,0,0, 0.3,0.3,0.3, 255,0,0,200, true,true,2,false)
                end
            end

            for _, cop in ipairs(activeDropoffGuards) do
                if DoesEntityExist(cop) and not IsEntityDead(cop) then
                    local cCoords = GetEntityCoords(cop)
                    DrawMarker(0, cCoords.x, cCoords.y, cCoords.z + 1.1, 0,0,0, 0,0,0, 0.3,0.3,0.3, 255,0,0,200, true,true,2,false)
                end
            end

            if currentRaidData and currentRaidData.getawayNetId then
                if NetworkDoesNetworkIdExist(currentRaidData.getawayNetId) then
                    local getawayEnt = NetworkGetEntityFromNetworkId(currentRaidData.getawayNetId)
                    if DoesEntityExist(getawayEnt) then
                        local vCoords = GetEntityCoords(getawayEnt)
                        DrawMarker(0, vCoords.x, vCoords.y, vCoords.z + 1.8, 0,0,0, 0,0,0, 0.6,0.6,0.6, 255,200,0,200, true,true,2,false)
                    end
                end
            end

            for _, crate in ipairs(activeCrateProps) do
                if DoesEntityExist(crate) then
                    local crCoords = GetEntityCoords(crate)
                    DrawMarker(2, crCoords.x, crCoords.y, crCoords.z + 0.8, 0,0,0, 0,180.0,0, 0.4,0.4,0.4, 0,200,255,200, false,true,2,false)
                end
            end

            if currentDropoffCoords then
                DrawMarker(1, currentDropoffCoords.x, currentDropoffCoords.y, currentDropoffCoords.z - 1.0, 0,0,0, 0,0,0, Config.WarehouseRaid.DeliveryRadius * 2, Config.WarehouseRaid.DeliveryRadius * 2, 1.5, 0, 255, 100, 80, false, false, 2, false)
                DrawMarker(0, currentDropoffCoords.x, currentDropoffCoords.y, currentDropoffCoords.z + 1.5, 0,0,0, 0,0,0, 1.2, 1.2, 1.2, 0, 255, 100, 200, true, true, 2, false)
            end
        end
    end)

    CreateThread(function()
        while isInRaidMission and IsGangMember() do
            Wait(1000)
            for i = #activeGuardBlips, 1, -1 do
                local item = activeGuardBlips[i]
                if not DoesEntityExist(item.ped) or IsEntityDead(item.ped) then
                    if DoesBlipExist(item.blip) then RemoveBlip(item.blip) end
                    table.remove(activeGuardBlips, i)
                end
            end

            for i = #activeDropoffBlips, 1, -1 do
                local item = activeDropoffBlips[i]
                if not DoesEntityExist(item.ped) or IsEntityDead(item.ped) then
                    if DoesBlipExist(item.blip) then RemoveBlip(item.blip) end
                    table.remove(activeDropoffBlips, i)
                end
            end
        end
    end)

    CreateThread(function()
        while isInRaidMission and IsGangMember() do
            Wait(0)
            if currentRaidData and currentRaidData.stage == 'delivering' and currentDropoffCoords then
                local playerPed = PlayerPedId()
                local pCoords = GetEntityCoords(playerPed)
                local dist = #(pCoords - currentDropoffCoords)

                if dist <= Config.WarehouseRaid.DeliveryRadius then
                    if IsPedInAnyVehicle(playerPed, false) then
                        local currentVeh = GetVehiclePedIsIn(playerPed, false)
                        local getawayEnt = NetworkGetEntityFromNetworkId(currentRaidData.getawayNetId)

                        if currentVeh == getawayEnt then
                            local aliveAmbushGuards = 0
                            for _, cop in ipairs(activeDropoffGuards) do
                                if DoesEntityExist(cop) and not IsEntityDead(cop) then
                                    aliveAmbushGuards = aliveAmbushGuards + 1
                                end
                            end

                            if aliveAmbushGuards > 0 then
                                ESX.ShowHelpNotification("~r~Clear remaining police ambush at the drop-off site! (" .. aliveAmbushGuards .. " left)")
                            else
                                ESX.ShowHelpNotification("Press ~g~[E]~s~ to deliver the cargo!")
                                if IsControlJustReleased(0, 38) then
                                    TriggerServerEvent('gang_mission:deliverRaid')
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    ESX.ShowNotification("~g~Mission Started!~s~ Eliminate 6 guards and collect the cargo crates.")
end)

-- Ambush Tracker Client Loop
CreateThread(function()
    while true do
        Wait(500)
        if currentRaidData and currentRaidData.stage == 'delivering' and IsGangMember() then
            local aliveAmbushGuards = 0
            for _, cop in ipairs(activeDropoffGuards) do
                if DoesEntityExist(cop) and not IsEntityDead(cop) then
                    aliveAmbushGuards = aliveAmbushGuards + 1
                end
            end

            SendNUIMessage({
                action = 'updateAmbush',
                remaining = aliveAmbushGuards
            })

            if aliveAmbushGuards == 0 then
                SendNUIMessage({ action = 'hideAmbush' })
            end
        else
            SendNUIMessage({ action = 'hideAmbush' })
        end
    end
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    if isInRaidMission and IsGangMember() then
        isInRaidMission = false
        isGuidedToContact = false
        isPromptActive = false
        hasJoinedPrompt = false
        SendNUIMessage({ action = 'hide' })
        SendNUIMessage({ action = 'hideAmbush' })
        ClearTimecycleModifier()
        TriggerServerEvent('gang_mission:server:playerDied')
    end
end)

RegisterNetEvent('gang_mission:client:spawnGuardWave', function(whIndex)
    if not IsGangMember() then return end

    local whData = Config.WarehouseRaid.Warehouses[whIndex]
    RequestModel(whData.guardModel)
    while not HasModelLoaded(whData.guardModel) do Wait(10) end

    for i = 1, Config.WarehouseRaid.GuardWaveCount do
        local spawnPos = whData.guards[math.random(1, #whData.guards)]
        local guard = CreatePed(4, whData.guardModel, spawnPos.x + math.random(-3, 3), spawnPos.y + math.random(-3, 3), spawnPos.z - 1.0, spawnPos.w, true, true)
        GiveWeaponToPed(guard, `WEAPON_ASSAULTRIFLE`, 255, false, true)
        SetPedAccuracy(guard, 65)
        SetPedRelationshipGroupHash(guard, `HATES_PLAYER`)
        TaskCombatPed(guard, PlayerPedId())
        table.insert(activeGuards, guard)

        local gBlip = AddBlipForEntity(guard)
        SetBlipSprite(gBlip, 1)
        SetBlipColour(gBlip, 1)
        SetBlipScale(gBlip, 0.8)
        table.insert(activeGuardBlips, { ped = guard, blip = gBlip })
    end
end)

RegisterNetEvent('gang_mission:updateRaidStage', function(newStage, delCoords)
    if not IsGangMember() or not currentRaidData then return end
    currentRaidData.stage = newStage

    if newStage == 'delivering' then
        if warehouseBlip then RemoveBlip(warehouseBlip) end
        currentDropoffCoords = delCoords

        deliveryBlip = AddBlipForCoord(delCoords.x, delCoords.y, delCoords.z)
        SetBlipSprite(deliveryBlip, 500)
        SetBlipColour(deliveryBlip, 2)
        SetBlipRoute(deliveryBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Cargo Delivery Point")
        EndTextCommandSetBlipName(deliveryBlip)

        local copModel = joaat(Config.Police.DropoffPedModel)
        RequestModel(copModel)
        while not HasModelLoaded(copModel) do Wait(10) end

        for i = 1, Config.Police.DropoffGuardCount do
            local offsetX = math.random(-12, 12)
            local offsetY = math.random(-12, 12)
            local cop = CreatePed(4, copModel, delCoords.x + offsetX, delCoords.y + offsetY, delCoords.z, 0.0, true, true)
            GiveWeaponToPed(cop, `WEAPON_CARBINERIFLE`, 255, false, true)
            SetPedAccuracy(cop, 65)
            SetPedArmour(cop, 50)
            SetPedRelationshipGroupHash(cop, `HATES_PLAYER`)
            TaskCombatPed(cop, PlayerPedId())
            table.insert(activeDropoffGuards, cop)

            local cBlip = AddBlipForEntity(cop)
            SetBlipSprite(cBlip, 1)
            SetBlipColour(cBlip, 1)
            SetBlipScale(cBlip, 0.8)
            table.insert(activeDropoffBlips, { ped = cop, blip = cBlip })
        end
    end
end)

RegisterNetEvent('gang_mission:client:spawnChasingPolice', function(getawayNetId)
    if not IsGangMember() or not NetworkDoesNetworkIdExist(getawayNetId) then return end
    local getawayEnt = NetworkGetEntityFromNetworkId(getawayNetId)
    if not DoesEntityExist(getawayEnt) then return end

    local vehModel = joaat(Config.Police.npcVehicle)
    local pedModel = joaat(Config.Police.npcPedModel)

    RequestModel(vehModel)
    RequestModel(pedModel)
    while not HasModelLoaded(vehModel) or not HasModelLoaded(pedModel) do Wait(10) end

    local vanCoords = GetEntityCoords(getawayEnt)
    local vanForward = GetEntityForwardVector(getawayEnt)
    local spawnCoords = vanCoords - (vanForward * 35.0)

    local polVeh = CreateVehicle(vehModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(getawayEnt), true, true)
    table.insert(activeNpcVehicles, polVeh)

    for i = 1, 2 do
        local cop = CreatePedInsideVehicle(polVeh, 6, pedModel, i - 2, true, true)
        GiveWeaponToPed(cop, `WEAPON_CARBINERIFLE`, 255, false, true)
        SetPedAccuracy(cop, 60)
        SetPedRelationshipGroupHash(cop, `HATES_PLAYER`)
        TaskCombatPed(cop, PlayerPedId())
        table.insert(activeNpcPolice, cop)
    end

    local driver = GetPedInVehicleSeat(polVeh, -1)
    if DoesEntityExist(driver) then
        TaskVehicleMissionTarget(driver, polVeh, getawayEnt, 8, 35.0, 786603, 10.0, 1.0, true)
    end

    ESX.ShowNotification("~r~WARNING:~s~ Police cruisers are pursuing the getaway vehicle!")
end)

RegisterNetEvent('gang_mission:client:updatePoliceLiveTracking', function(coords)
    local xPlayer = ESX.GetPlayerData()
    if not xPlayer or not xPlayer.job or not Config.Police.jobs[xPlayer.job.name] then return end

    if not policeLiveBlip then
        policeLiveBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(policeLiveBlip, 161)
        SetBlipColour(policeLiveBlip, 1)
        SetBlipScale(policeLiveBlip, 1.2)
        BeginTextCommandSetBlipName("STRING")
        AddTextCommandString("LIVE TRACKING: Raid Target")
        EndTextCommandSetBlipName(policeLiveBlip)
    else
        SetBlipCoords(policeLiveBlip, coords.x, coords.y, coords.z)
    end
end)

RegisterNetEvent('gang_mission:cargoPickedUp', function(crateIndex)
    if not IsGangMember() then return end
    isCarryingCrate = true

    if activeCrateProps[crateIndex] and DoesEntityExist(activeCrateProps[crateIndex]) then
        DeleteEntity(activeCrateProps[crateIndex])
    end

    local ped = PlayerPedId()
    local propModel = Config.WarehouseRaid.CrateModel
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(10) end

    carriedPropEntity = CreateObject(propModel, 0, 0, 0, true, true, false)
    AttachEntityToEntity(carriedPropEntity, ped, GetPedBoneIndex(ped, 28422), 0.0, -0.15, -0.1, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    RequestAnimDict("anim@heists@box_carry@")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(10) end

    CreateThread(function()
        while isCarryingCrate and IsGangMember() do
            Wait(0)
            if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) then
                TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
            end
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 23, true)
        end
    end)
end)

RegisterNetEvent('gang_mission:cargoLoaded', function()
    isCarryingCrate = false
    if carriedPropEntity and DoesEntityExist(carriedPropEntity) then
        DeleteEntity(carriedPropEntity)
        carriedPropEntity = nil
    end
    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent('gang_mission:spawnNpcPolice', function(whCoords)
    if not IsGangMember() then return end

    local vehModel = joaat(Config.Police.npcVehicle)
    local pedModel = joaat(Config.Police.npcPedModel)

    RequestModel(vehModel)
    RequestModel(pedModel)
    while not HasModelLoaded(vehModel) or not HasModelLoaded(pedModel) do Wait(10) end

    local spawnCoords = vector3(whCoords.x + 120.0, whCoords.y + 120.0, whCoords.z)
    local polVeh = CreateVehicle(vehModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
    table.insert(activeNpcVehicles, polVeh)

    for i = 1, Config.Police.npcCount do
        local cop = CreatePedInsideVehicle(polVeh, 6, pedModel, i - 2, true, true)
        GiveWeaponToPed(cop, `WEAPON_CARBINERIFLE`, 255, false, true)
        SetPedAccuracy(cop, 50)
        SetPedRelationshipGroupHash(cop, `HATES_PLAYER`)
        table.insert(activeNpcPolice, cop)
    end

    TaskVehicleDriveToCoord(GetPedInVehicleSeat(polVeh, -1), polVeh, whCoords.x, whCoords.y, whCoords.z, 20.0, 0, vehModel, 786603, 1.0, 1)

    CreateThread(function()
        local arrived = false
        while not arrived do
            Wait(2000)
            if DoesEntityExist(polVeh) and #(GetEntityCoords(polVeh) - whCoords) < 35.0 then
                arrived = true
                for _, cop in ipairs(activeNpcPolice) do
                    if DoesEntityExist(cop) then
                        TaskLeaveVehicle(cop, polVeh, 256)
                        TaskCombatPed(cop, PlayerPedId())
                    end
                end
            end
        end
    end)
end)

RegisterNetEvent('gang_mission:client:missionFailed', function(reason)
    PlaySoundFrontend(-1, "ScreenFlash", "Mission_Failed_Sounds", true)
end)

RegisterNetEvent('gang_mission:finishRaid', function()
    isInRaidMission = false
    isGuidedToContact = false
    isPromptActive = false
    hasJoinedPrompt = false
    isCarryingCrate = false
    currentDropoffCoords = nil

    ClearTimecycleModifier()
    SendNUIMessage({ action = 'hide' })
    SendNUIMessage({ action = 'hideAmbush' })

    if carriedPropEntity and DoesEntityExist(carriedPropEntity) then
        DeleteEntity(carriedPropEntity)
        carriedPropEntity = nil
    end

    --ClearPedTasks(PlayerPedId())

    for _, g in ipairs(activeGuards) do if DoesEntityExist(g) then DeleteEntity(g) end end
    for _, b in ipairs(activeGuardBlips) do if DoesBlipExist(b.blip) then RemoveBlip(b.blip) end end
    for _, g in ipairs(activeDropoffGuards) do if DoesEntityExist(g) then DeleteEntity(g) end end
    for _, b in ipairs(activeDropoffBlips) do if DoesBlipExist(b.blip) then RemoveBlip(b.blip) end end
    for _, c in ipairs(activeCrateProps) do if DoesEntityExist(c) then DeleteEntity(c) end end
    for _, p in ipairs(activeNpcPolice) do if DoesEntityExist(p) then DeleteEntity(p) end end
    for _, v in ipairs(activeNpcVehicles) do if DoesEntityExist(v) then DeleteEntity(v) end end

    activeGuards = {}
    activeGuardBlips = {}
    activeDropoffGuards = {}
    activeDropoffBlips = {}
    activeCrateProps = {}
    activeNpcPolice = {}
    activeNpcVehicles = {}

    if contactBlip then RemoveBlip(contactBlip) end
    if warehouseBlip then RemoveBlip(warehouseBlip) end
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    if policeLiveBlip then RemoveBlip(policeLiveBlip) end

    currentRaidData = nil
    getawayTargetAdded = false
end)