local ESX = exports['es_extended']:getSharedObject()

local ActiveRaid = nil
local RaidCooldown = 0
local PromptActive = false
local PromptParticipants = {}
local PromptTimer = 0

local function IsGangMember(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName
end

local function BroadcastRosterUpdate(stageText, timerVal)
    if not ActiveRaid and not PromptActive then return end

    local participantData = {}
    local targets = {}

    if PromptActive then
        targets = PromptParticipants
        for pSrc, _ in pairs(PromptParticipants) do
            local xP = ESX.GetPlayerFromId(pSrc)
            if xP and IsGangMember(pSrc) then
                table.insert(participantData, { name = xP.getName(), status = 'active' })
            end
        end
    elseif ActiveRaid then
        targets = ActiveRaid.participants
        for _, pSrc in ipairs(ActiveRaid.participantList) do
            local xP = ESX.GetPlayerFromId(pSrc)
            if xP and IsGangMember(pSrc) then
                table.insert(participantData, { name = xP.getName(), status = 'active' })
            end
        end
    end

    for pSrc, _ in pairs(targets) do
        if IsGangMember(pSrc) then
            TriggerClientEvent('gang_mission:client:updateRaidRoster', pSrc, participantData, stageText or (ActiveRaid and ActiveRaid.stage or 'LOBBY'), timerVal)
        end
    end
end

AddEventHandler('esx:setJob', function(source, job)
    local isPolice = Config.Police.jobs[job.name] == true
    Player(source).state:set('isPolice', isPolice, true)
end)

AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    if xPlayer and xPlayer.job then
        local isPolice = Config.Police.jobs[xPlayer.job.name] == true
        Player(source).state:set('isPolice', isPolice, true)
    end
end)

local function FailMission(reason)
    if not ActiveRaid then return end

    for _, pSrc in ipairs(ActiveRaid.participantList) do
        Player(pSrc).state:set('inGangRaid', false, true)
        if IsGangMember(pSrc) then
            TriggerClientEvent('esx:showNotification', pSrc, '~r~MISSION FAILED:~s~ ' .. reason)
            TriggerClientEvent('gang_mission:client:missionFailed', pSrc, reason)
            TriggerClientEvent('gang_mission:finishRaid', pSrc)
        end
    end

    if ActiveRaid.getawayNetId then
        local getawayEnt = NetworkGetEntityFromNetworkId(ActiveRaid.getawayNetId)
        if DoesEntityExist(getawayEnt) then DeleteEntity(getawayEnt) end
    end

    RaidCooldown = 0
    ActiveRaid = nil
end

local function TriggerRaidPrompt(isForced, adminSource)
    if ActiveRaid then return false, "A raid is already active." end
    if PromptActive then return false, "A raid prompt is already active." end

    PromptActive = true
    PromptParticipants = {}
    PromptTimer = Config.RaidSchedule.PromptDuration

    local xPlayers = ESX.GetExtendedPlayers()
    local targetCount = 0

    for _, xP in ipairs(xPlayers) do
        if xP.job.name == Config.JobName then
            TriggerClientEvent('gang_mission:client:startRaidPrompt', xP.source, Config.RaidSchedule.PromptDuration)
            targetCount = targetCount + 1
        end
    end

    if targetCount == 0 then
        PromptActive = false
        return false, "No eligible gang players online to receive the prompt."
    end

    CreateThread(function()
        while PromptTimer > 0 and PromptActive do
            Wait(1000)
            PromptTimer = PromptTimer - 1
            BroadcastRosterUpdate('LOBBY', PromptTimer)
        end

        PromptActive = false

        local participantSources = {}
        for src, _ in pairs(PromptParticipants) do
            if IsGangMember(src) then
                table.insert(participantSources, src)
            end
        end

        if #participantSources < Config.WarehouseRaid.MinPlayers then
            for _, src in ipairs(participantSources) do
                TriggerClientEvent('esx:showNotification', src, '~r~Warehouse Raid cancelled: Not enough participants joined.')
                TriggerClientEvent('gang_mission:client:closeRaidPrompt', src)
            end
        else
            ActiveRaid = {
                stage = 'contact_phase',
                participants = PromptParticipants,
                participantList = participantSources,
                warehouseIndex = math.random(1, #Config.WarehouseRaid.Warehouses),
                deliveryIndex = math.random(1, #Config.WarehouseRaid.DeliveryLocations),
                cratesCollected = {},
                cratesCarriedBy = {},
                cratesLoadedCount = 0,
                getawayNetId = nil,
                policeAlerted = false,
                startTime = os.time()
            }

            BroadcastRosterUpdate('CONTACT PHASE', 0)

            local contactCoords = vector3(Config.WarehouseRaid.ContactPed.coords.x, Config.WarehouseRaid.ContactPed.coords.y, Config.WarehouseRaid.ContactPed.coords.z)
            for _, src in ipairs(participantSources) do
                TriggerClientEvent('gang_mission:client:guideToContactNPC', src, contactCoords)
            end
        end
    end)

    return true, ("Raid prompt triggered for %d gang player(s)."):format(targetCount)
end

RegisterCommand('forceraid', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source == 0 or (xPlayer and xPlayer.getGroup() == 'admin') then
        local success, msg = TriggerRaidPrompt(true, source)
        if source == 0 then print('[Gang Mission] ' .. msg) else TriggerClientEvent('esx:showNotification', source, (success and '~g~' or '~r~') .. msg) end
    else
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission to force a raid.')
    end
end, false)

RegisterCommand('resetraid', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source == 0 or (xPlayer and xPlayer.getGroup() == 'admin') then
        FailMission("Raid reset by Administrator.")
        PromptActive = false
        PromptParticipants = {}
        RaidCooldown = 0
        local msg = "Raid state and cooldowns have been reset."
        if source == 0 then print('[Gang Mission] ' .. msg) else TriggerClientEvent('esx:showNotification', source, '~g~' .. msg) end
    else
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission to reset the raid.')
    end
end, false)

CreateThread(function()
    while true do
        Wait(Config.RaidSchedule.Interval)
        if not ActiveRaid and not PromptActive and os.time() >= RaidCooldown then
            TriggerRaidPrompt(false)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if ActiveRaid and ActiveRaid.startTime and ActiveRaid.stage ~= 'contact_phase' then
            local timeElapsed = os.time() - ActiveRaid.startTime
            local timeLimit = Config.WarehouseRaid.Timeout / 1000

            if timeElapsed >= timeLimit then
                FailMission("10-Minute time limit expired!")
            end
        end
    end
end)

RegisterNetEvent('gang_mission:server:playerDied', function()
    local source = source
    if not IsGangMember(source) then return end
    if not ActiveRaid or not ActiveRaid.participants[source] then return end

    ActiveRaid.participants[source] = nil
    for i, pSrc in ipairs(ActiveRaid.participantList) do
        if pSrc == source then
            table.remove(ActiveRaid.participantList, i)
            break
        end
    end

    Player(source).state:set('inGangRaid', false, true)
    TriggerClientEvent('esx:showNotification', source, '~r~MISSION FAILED:~s~ You were eliminated from the raid.')
    TriggerClientEvent('gang_mission:client:missionFailed', source, "You were eliminated.")
    TriggerClientEvent('gang_mission:finishRaid', source)

    if #ActiveRaid.participantList == 0 then
        FailMission("All gang participants were eliminated!")
    else
        BroadcastRosterUpdate('IN PROGRESS', 0)
    end
end)

RegisterNetEvent('gang_mission:server:joinRaidPrompt', function()
    local source = source
    if not IsGangMember(source) or not PromptActive then return end

    if not PromptParticipants[source] then
        PromptParticipants[source] = true
        BroadcastRosterUpdate('LOBBY', PromptTimer)
    end
end)

RegisterNetEvent('gang_mission:server:requestNPCStart', function()
    local source = source
    if not IsGangMember(source) then return end
    if not ActiveRaid or ActiveRaid.stage ~= 'contact_phase' then return end
    if not ActiveRaid.participants[source] then return end

    local npcCoords = vector3(Config.WarehouseRaid.ContactPed.coords.x, Config.WarehouseRaid.ContactPed.coords.y, Config.WarehouseRaid.ContactPed.coords.z)

    for pSrc, _ in pairs(ActiveRaid.participants) do
        local ped = GetPlayerPed(pSrc)
        if not DoesEntityExist(ped) or #(GetEntityCoords(ped) - npcCoords) > Config.RaidSchedule.NPCProximityRadius then
            local missingXP = ESX.GetPlayerFromId(pSrc)
            local missingName = missingXP and missingXP.getName() or "A member"
            
            for src, _ in pairs(ActiveRaid.participants) do
                TriggerClientEvent('esx:showNotification', src, ('~r~Cannot start! Waiting for %s to reach the contact point.'):format(missingName))
            end
            return
        end
    end

    ActiveRaid.stage = 'in_progress'
    ActiveRaid.startTime = os.time()
    local whData = Config.WarehouseRaid.Warehouses[ActiveRaid.warehouseIndex]

    local veh = CreateVehicle(joaat(Config.WarehouseRaid.GetawayVehicle), whData.vehicleSpawn.x, whData.vehicleSpawn.y, whData.vehicleSpawn.z, whData.vehicleSpawn.w, true, true)
    while not DoesEntityExist(veh) do Wait(50) end
    ActiveRaid.getawayNetId = NetworkGetNetworkIdFromEntity(veh)

    BroadcastRosterUpdate('IN PROGRESS', 0)

    for pSrc, _ in pairs(ActiveRaid.participants) do
        Player(pSrc).state:set('inGangRaid', true, true)
        TriggerClientEvent('gang_mission:startRaidClient', pSrc, {
            whIndex = ActiveRaid.warehouseIndex,
            delIndex = ActiveRaid.deliveryIndex,
            getawayNetId = ActiveRaid.getawayNetId,
            cratesRequired = Config.WarehouseRaid.CratesRequired
        })
    end

    if Config.WarehouseRaid.EnableGuardWaves then
        CreateThread(function()
            while ActiveRaid and ActiveRaid.stage == 'in_progress' do
                Wait(Config.WarehouseRaid.GuardWaveInterval)
                if ActiveRaid and ActiveRaid.stage == 'in_progress' then
                    for pSrc, _ in pairs(ActiveRaid.participants) do
                        TriggerClientEvent('gang_mission:client:spawnGuardWave', pSrc, ActiveRaid.warehouseIndex)
                        TriggerClientEvent('esx:showNotification', pSrc, '~r~WARNING:~s~ 6 Enemy gang reinforcements arrived!')
                    end
                end
            end
        end)
    end
end)

RegisterNetEvent('gang_mission:pickupCargo', function(crateIndex)
    local source = source
    if not IsGangMember(source) then return end
    if not ActiveRaid or ActiveRaid.stage ~= 'in_progress' then return end
    if not ActiveRaid.participants[source] then return end

    if ActiveRaid.cratesCollected[crateIndex] then
        TriggerClientEvent('esx:showNotification', source, '~r~This crate has already been picked up.')
        return
    end

    local ped = GetPlayerPed(source)
    local pCoords = GetEntityCoords(ped)
    local crateCoords = Config.WarehouseRaid.Warehouses[ActiveRaid.warehouseIndex].crates[crateIndex]

    if #(pCoords - crateCoords) > 5.0 then
        TriggerClientEvent('esx:showNotification', source, '~r~You are too far from the cargo.')
        return
    end

    ActiveRaid.cratesCollected[crateIndex] = true
    ActiveRaid.cratesCarriedBy[source] = crateIndex

    TriggerClientEvent('gang_mission:cargoPickedUp', source, crateIndex)
end)

RegisterNetEvent('gang_mission:loadCargo', function()
    local source = source
    if not IsGangMember(source) then return end
    if not ActiveRaid or ActiveRaid.stage ~= 'in_progress' then return end
    if not ActiveRaid.participants[source] then return end

    local crateIndex = ActiveRaid.cratesCarriedBy[source]
    if not crateIndex then
        TriggerClientEvent('esx:showNotification', source, '~r~You are not carrying any cargo.')
        return
    end

    local getawayEnt = NetworkGetEntityFromNetworkId(ActiveRaid.getawayNetId)
    if DoesEntityExist(getawayEnt) then
        local pCoords = GetEntityCoords(GetPlayerPed(source))
        local vCoords = GetEntityCoords(getawayEnt)
        if #(pCoords - vCoords) > 7.0 then
            TriggerClientEvent('esx:showNotification', source, '~r~You are too far from the getaway vehicle.')
            return
        end
    end

    ActiveRaid.cratesCarriedBy[source] = nil
    ActiveRaid.cratesLoadedCount = ActiveRaid.cratesLoadedCount + 1

    TriggerClientEvent('gang_mission:cargoLoaded', source)

    for pSrc, _ in pairs(ActiveRaid.participants) do
        TriggerClientEvent('esx:showNotification', pSrc, ('~g~Cargo Loaded (%d/%d)'):format(ActiveRaid.cratesLoadedCount, Config.WarehouseRaid.CratesRequired))
    end

    if ActiveRaid.cratesLoadedCount >= Config.WarehouseRaid.CratesRequired then
        ActiveRaid.stage = 'delivering'
        local delCoords = Config.WarehouseRaid.DeliveryLocations[ActiveRaid.deliveryIndex]

        for pSrc, _ in pairs(ActiveRaid.participants) do
            TriggerClientEvent('gang_mission:updateRaidStage', pSrc, 'delivering', delCoords)
            TriggerClientEvent('esx:showNotification', pSrc, '~r~DISPATCH:~s~ All cargo loaded! Police have been alerted to the getaway vehicle!')
        end

        if not ActiveRaid.policeAlerted then
            ActiveRaid.policeAlerted = true

            local policeCount = 0
            local xPlayers = ESX.GetExtendedPlayers()
            for _, xP in ipairs(xPlayers) do
                if Config.Police.jobs[xP.job.name] then policeCount = policeCount + 1 end
            end

            local whCoords = Config.WarehouseRaid.Warehouses[ActiveRaid.warehouseIndex].coords

            if policeCount > 0 then
                for _, xP in ipairs(xPlayers) do
                    if Config.Police.jobs[xP.job.name] then
                        TriggerClientEvent('esx:showNotification', xP.source, '~r~DISPATCH:~s~ Gang Warehouse Raid getaway in progress! Live tracking active.')
                    end
                end

                CreateThread(function()
                    while ActiveRaid and ActiveRaid.stage == 'delivering' do
                        local trackingCoords = whCoords
                        local getawayEnt = NetworkGetEntityFromNetworkId(ActiveRaid.getawayNetId)
                        if DoesEntityExist(getawayEnt) then
                            trackingCoords = GetEntityCoords(getawayEnt)
                        end

                        local onlinePols = ESX.GetExtendedPlayers()
                        for _, xP in ipairs(onlinePols) do
                            if Config.Police.jobs[xP.job.name] then
                                TriggerClientEvent('gang_mission:client:updatePoliceLiveTracking', xP.source, trackingCoords)
                            end
                        end
                        Wait(Config.Police.TrackingInterval)
                    end
                end)
            else
                if Config.Police.npcBackup then
                    TriggerClientEvent('gang_mission:spawnNpcPolice', ActiveRaid.participantList[1], whCoords)
                end
            end

            CreateThread(function()
                while ActiveRaid and ActiveRaid.stage == 'delivering' do
                    Wait(Config.Police.ChasingPoliceInterval)
                    if ActiveRaid and ActiveRaid.getawayNetId then
                        for pSrc, _ in pairs(ActiveRaid.participants) do
                            TriggerClientEvent('gang_mission:client:spawnChasingPolice', pSrc, ActiveRaid.getawayNetId)
                        end
                    end
                end
            end)
        end
    end
end)

RegisterNetEvent('gang_mission:deliverRaid', function()
    local source = source
    if not IsGangMember(source) then return end
    if not ActiveRaid or ActiveRaid.stage ~= 'delivering' then return end
    if not ActiveRaid.participants[source] then return end

    local pCoords = GetEntityCoords(GetPlayerPed(source))
    local dropCoords = Config.WarehouseRaid.DeliveryLocations[ActiveRaid.deliveryIndex]

    if #(pCoords - dropCoords) > Config.WarehouseRaid.DeliveryRadius then
        TriggerClientEvent('esx:showNotification', source, '~r~Getaway vehicle is not within the drop-off radius.')
        return
    end

    for _, pSrc in ipairs(ActiveRaid.participantList) do
        Player(pSrc).state:set('inGangRaid', false, true)
        local xPlayer = ESX.GetPlayerFromId(pSrc)
        if xPlayer then
            local reward = math.random(Config.WarehouseRaid.RewardPerPlayer.min, Config.WarehouseRaid.RewardPerPlayer.max)
            xPlayer.addAccountMoney('black_money', reward)
            TriggerClientEvent('esx:showNotification', pSrc, ('~g~Raid Complete!~s~ You received $%s black money.'):format(reward))
        end
        TriggerClientEvent('gang_mission:finishRaid', pSrc)
    end

    local getawayEnt = NetworkGetEntityFromNetworkId(ActiveRaid.getawayNetId)
    if DoesEntityExist(getawayEnt) then DeleteEntity(getawayEnt) end

    RaidCooldown = 0
    ActiveRaid = nil
end)