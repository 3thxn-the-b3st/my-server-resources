local activeLobbies = {}
local storeCooldowns = {}

local function CountPolice()
    local xPlayers = ESX.GetExtendedPlayers('job', 'police')
    return #xPlayers
end

local function IsJobRestricted(jobName)
    return Config.RestrictedJobs[jobName] == true
end

--------------------------------------------------------------------------------
-- Lobby Trigger Request
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:requestLobby', function(storeIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    if IsJobRestricted(xPlayer.job.name) then
        TriggerClientEvent('esx_robbery:showNotification', src, "~r~Emergency personnel cannot initiate store robberies.~s~")
        return
    end

    if storeCooldowns[storeIndex] and os.time() < storeCooldowns[storeIndex] then
        local remaining = storeCooldowns[storeIndex] - os.time()
        TriggerClientEvent('esx_robbery:showNotification', src, ("~r~This store was recently robbed. Wait %s seconds.~s~"):format(remaining))
        return
    end

    if activeLobbies[storeIndex] then return end

    activeLobbies[storeIndex] = {
        host = src,
        members = { xPlayer.getName() },
        memberIds = { src },
        started = false,
        cancelled = false
    }

    local pedCoords = Config.Peds[storeIndex]
    local players = ESX.GetExtendedPlayers()

    for _, target in ipairs(players) do
        if not IsJobRestricted(target.job.name) then
            local tPed = GetPlayerPed(target.source)
            local tCoords = GetEntityCoords(tPed)
            if #(tCoords - vec3(pedCoords.x, pedCoords.y, pedCoords.z)) <= Config.JoinRadius then
                TriggerClientEvent('esx_robbery:showJoinPrompt', target.source, storeIndex)
                TriggerClientEvent('esx_robbery:updateUI', target.source, { 
                    display = true, 
                    status = "ROBBERY LOBBY",
                    members = activeLobbies[storeIndex].members, 
                    timer = Config.LobbyDuration 
                })
            end
        end
    end

    SetTimeout(Config.LobbyDuration * 1000, function()
        if activeLobbies[storeIndex] and not activeLobbies[storeIndex].started and not activeLobbies[storeIndex].cancelled then
            activeLobbies[storeIndex].started = true
            TriggerEvent('esx_robbery:startRobbery', storeIndex)
        end
    end)
end)

--------------------------------------------------------------------------------
-- Join Lobby Event
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:joinLobby', function(storeIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local lobby = activeLobbies[storeIndex]

    if not xPlayer then return end

    if IsJobRestricted(xPlayer.job.name) then
        TriggerClientEvent('esx_robbery:showNotification', src, "~r~Emergency personnel cannot join store robberies.~s~")
        return
    end

    if lobby and not lobby.started and not lobby.cancelled and #lobby.members < Config.MaxRobbers then
        for _, id in ipairs(lobby.memberIds) do
            if id == src then return end
        end

        table.insert(lobby.members, xPlayer.getName())
        table.insert(lobby.memberIds, src)

        for _, id in ipairs(lobby.memberIds) do
            TriggerClientEvent('esx_robbery:updateUI', id, { 
                display = true, 
                status = "ROBBERY LOBBY",
                members = lobby.members, 
                timer = Config.LobbyDuration 
            })
        end
    end
end)

--------------------------------------------------------------------------------
-- Start Active Robbery Event
--------------------------------------------------------------------------------
RegisterNetEvent('esx_robbery:startRobbery', function(storeIndex)
    local lobby = activeLobbies[storeIndex]
    if not lobby then return end

    local storePos = vec3(Config.Peds[storeIndex].x, Config.Peds[storeIndex].y, Config.Peds[storeIndex].z)
    
    TriggerClientEvent('esx_robbery:emergencyAlert', -1, storePos)
    TriggerClientEvent('esx_robbery:startStoreAnimation', -1, storeIndex)

    for _, robberId in ipairs(lobby.memberIds) do
        TriggerClientEvent('esx_robbery:updateUI', robberId, { 
            display = true, 
            status = "ROBBERY IN PROGRESS",
            members = lobby.members, 
            timer = Config.RobberyDuration 
        })
    end

    CreateThread(function()
        local timeRemaining = Config.RobberyDuration
        
        while timeRemaining > 0 do
            Wait(1000)
            timeRemaining = timeRemaining - 1

            -- Check distance of participants (50 unit radius)
            for _, robberId in ipairs(lobby.memberIds) do
                local ped = GetPlayerPed(robberId)
                if DoesEntityExist(ped) then
                    local playerCoords = GetEntityCoords(ped)
                    if #(playerCoords - storePos) > 50.0 then
                        lobby.cancelled = true
                        break
                    end
                else
                    lobby.cancelled = true
                    break
                end
            end

            -- Cancel if player strays > 50m
            if lobby.cancelled then
                for _, robberId in ipairs(lobby.memberIds) do
                    TriggerClientEvent('esx_robbery:clearPoliceNpc', robberId)
                    TriggerClientEvent('esx_robbery:updateUI', robberId, { display = false, members = {}, timer = 0 })
                    TriggerClientEvent('esx_robbery:showNotification', robberId, "~r~A robber left the store area. Robbery cancelled!~s~")
                end
                
                storeCooldowns[storeIndex] = os.time() + Config.CooldownTime
                activeLobbies[storeIndex] = nil
                return
            end

            -- Spawn police wave every 30s
            if timeRemaining % 30 == 0 and timeRemaining > 0 then
                if CountPolice() < Config.MinPoliceToDisableNPCS then
                    for _, robberId in ipairs(lobby.memberIds) do
                        TriggerClientEvent('esx_robbery:spawnPoliceWave', robberId, storePos, Config.PoliceCarCount)
                    end
                end
            end
        end

        -- Direct Payout to Inventory & Escape Notification
        local splitAmount = math.floor(Config.TotalReward / #lobby.memberIds)
        
        for _, robberId in ipairs(lobby.memberIds) do
            local xPlayer = ESX.GetPlayerFromId(robberId)
            if xPlayer then
                xPlayer.addAccountMoney('black_money', splitAmount)
                TriggerClientEvent('esx_robbery:updateUI', robberId, { display = false, members = {}, timer = 0 })
                TriggerClientEvent('esx_robbery:showNotification', robberId, ("~g~Robbery Complete! Received $%s dirty money directly! RUN! You have 15 seconds!~s~"):format(splitAmount))
            end
        end

        -- 15-Second Delay before clearing police
        SetTimeout(15000, function()
            for _, robberId in ipairs(lobby.memberIds) do
                TriggerClientEvent('esx_robbery:clearPoliceNpc', robberId)
            end
        end)

        storeCooldowns[storeIndex] = os.time() + Config.CooldownTime
        activeLobbies[storeIndex] = nil
    end)
end)