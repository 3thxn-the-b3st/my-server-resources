local ESX = exports['es_extended']:getSharedObject()

-- 200 Guaranteed safe, open-air street and field locations
local emergencyLocations = {
    -- Pillbox Hill & Legion Square Streets (1-15)
    vector3(328.7, -572.8, 43.2),
    vector3(295.5, -583.5, 43.2),
    vector3(220.4, -565.1, 43.2),
    vector3(160.2, -550.4, 43.1),
    vector3(112.5, -730.8, 31.4),
    vector3(71.5, -812.5, 30.5),
    vector3(154.2, -943.5, 29.3),
    vector3(205.1, -1005.2, 29.3),
    vector3(268.4, -1060.5, 29.3),
    vector3(365.1, -1045.2, 29.4),
    vector3(315.2, -750.1, 29.4),
    vector3(250.4, -850.2, 29.4),
    vector3(180.1, -900.5, 30.2),
    vector3(100.2, -1050.4, 29.3),
    vector3(50.5, -1120.1, 29.4),

    -- Davis & Strawberry Open Roads (16-30)
    vector3(151.1, -1553.8, 29.3),
    vector3(104.2, -1450.1, 29.3),
    vector3(55.8, -1350.2, 29.3),
    vector3(-45.2, -1250.8, 29.2),
    vector3(-120.5, -1415.2, 30.6),
    vector3(-225.1, -1525.8, 31.3),
    vector3(-325.4, -1650.2, 31.8),
    vector3(330.1, -1890.5, 26.3),
    vector3(210.5, -1800.1, 27.2),
    vector3(105.8, -1725.4, 29.3),
    vector3(-10.2, -1650.4, 29.3),
    vector3(-100.1, -1550.2, 30.1),
    vector3(-200.4, -1350.5, 31.1),
    vector3(-280.2, -1200.1, 31.3),
    vector3(120.4, -1300.2, 29.3),

    -- Vespucci & Del Perro Beachside Streets (31-45)
    vector3(-814.2, -1229.8, 7.3),
    vector3(-950.4, -1320.1, 2.0),
    vector3(-1100.5, -1450.2, 5.1),
    vector3(-1250.8, -1520.4, 3.8),
    vector3(-1400.1, -1480.2, 5.2),
    vector3(-1500.2, -1350.5, 10.2),
    vector3(-1632.1, -998.4, 13.0),
    vector3(-1550.5, -825.1, 11.2),
    vector3(-1425.8, -710.4, 15.2),
    vector3(-1300.2, -620.1, 21.3),
    vector3(-1150.4, -750.2, 18.4),
    vector3(-1000.1, -900.5, 12.1),
    vector3(-900.2, -1050.4, 10.2),
    vector3(-1350.1, -1150.2, 6.4),
    vector3(-1450.4, -1000.1, 13.5),

    -- Rockford Hills & Vinewood Wide Boulevards (46-60)
    vector3(-449.8, -340.5, 34.5),
    vector3(-580.2, -250.1, 35.6),
    vector3(-700.5, -180.2, 37.2),
    vector3(-850.1, -110.5, 37.8),
    vector3(-1000.4, -50.1, 40.1),
    vector3(-1150.2, 50.4, 52.3),
    vector3(-1300.5, 150.2, 56.4),
    vector3(-1450.8, 250.1, 60.1),
    vector3(-300.2, 150.5, 87.2),
    vector3(-150.1, 220.4, 91.5),
    vector3(-50.2, 100.4, 65.1),
    vector3(-200.5, -50.2, 54.2),
    vector3(-350.1, -150.4, 46.5),
    vector3(-550.4, -50.2, 42.1),
    vector3(-750.1, 80.4, 55.4),

    -- Downtown Vinewood & Mirror Park (61-75)
    vector3(378.2, 794.1, 187.5),
    vector3(250.1, 550.2, 150.2),
    vector3(150.4, 350.1, 112.5),
    vector3(204.1, -153.2, 59.9),
    vector3(280.5, -280.4, 53.5),
    vector3(350.2, -410.1, 43.1),
    vector3(1138.2, -982.1, 46.1),
    vector3(1100.5, -850.2, 34.5),
    vector3(1050.2, -700.1, 59.1),
    vector3(1150.4, -550.2, 65.2),
    vector3(900.1, -650.4, 58.2),
    vector3(750.5, -550.1, 42.3),
    vector3(600.2, -450.5, 31.4),
    vector3(450.1, -300.2, 45.1),
    vector3(250.4, 100.1, 100.2),

    -- East Los Santos & La Mesa (76-90)
    vector3(850.2, -500.1, 27.2),
    vector3(950.5, -400.4, 31.4),
    vector3(1050.1, -300.2, 38.5),
    vector3(750.4, -180.5, 73.5),
    vector3(650.1, -50.2, 85.1),
    vector3(550.5, 80.1, 95.2),
    vector3(820.2, -200.4, 69.4),
    vector3(910.5, -120.1, 74.2),
    vector3(1020.1, -50.4, 80.5),
    vector3(1120.4, 20.2, 83.1),
    vector3(1250.1, -100.2, 80.4),
    vector3(1350.4, -250.1, 55.2),
    vector3(1200.2, -400.5, 33.1),
    vector3(900.5, -750.1, 30.5),
    vector3(800.1, -850.4, 25.4),

    -- Sandy Shores & Desert Flats (91-115)
    vector3(1850.2, 3600.4, 33.2),
    vector3(1950.5, 3750.1, 32.1),
    vector3(2050.1, 3900.2, 32.5),
    vector3(1650.4, 3800.5, 34.2),
    vector3(1450.2, 3700.1, 33.8),
    vector3(1250.5, 3600.4, 34.1),
    vector3(1050.1, 3550.2, 33.5),
    vector3(850.4, 3500.1, 33.1),
    vector3(650.2, 3450.5, 31.2),
    vector3(450.5, 3400.2, 30.5),
    vector3(1350.1, 3350.4, 38.1),
    vector3(1550.4, 3450.2, 35.4),
    vector3(1750.2, 3500.1, 33.2),
    vector3(2150.5, 3700.4, 31.5),
    vector3(2250.1, 3550.2, 35.1),
    vector3(2350.4, 3400.1, 38.4),
    vector3(1900.1, 3300.5, 41.2),
    vector3(1700.2, 3250.4, 43.1),
    vector3(1500.5, 3200.1, 41.5),
    vector3(1100.2, 3300.4, 36.2),
    vector3(900.4, 3250.1, 35.4),
    vector3(700.1, 3200.5, 33.2),
    vector3(500.2, 3150.2, 31.1),
    vector3(300.5, 3100.4, 32.4),
    vector3(200.1, 3050.1, 35.2),

    -- Grand Senora Desert & Route 68 Open Fields (116-145)
    vector3(2600.1, 2800.4, 37.2),
    vector3(2400.2, 2900.1, 41.5),
    vector3(2200.5, 3000.2, 45.1),
    vector3(2000.1, 3100.5, 47.8),
    vector3(1350.2, 3100.4, 40.5),
    vector3(1150.5, 3050.1, 40.2),
    vector3(950.1, 3000.2, 40.8),
    vector3(750.2, 2950.4, 41.2),
    vector3(550.1, 2900.5, 42.1),
    vector3(350.2, 2850.1, 43.5),
    vector3(2700.4, 3000.2, 37.5),
    vector3(2500.1, 3150.5, 38.2),
    vector3(2300.2, 3300.1, 35.4),
    vector3(1750.5, 2900.2, 46.1),
    vector3(1550.1, 2850.4, 48.2),
    vector3(1250.4, 2900.1, 43.5),
    vector3(1050.2, 2850.5, 42.1),
    vector3(850.1, 2800.2, 44.5),
    vector3(650.4, 2750.1, 45.2),
    vector3(450.2, 2700.4, 46.1),
    vector3(250.5, 2650.2, 48.4),
    vector3(150.1, 2750.5, 45.2),
    vector3(300.4, 2950.1, 41.2),
    vector3(500.1, 3050.4, 38.5),
    vector3(700.2, 3100.2, 36.1),
    vector3(900.5, 3150.1, 37.4),
    vector3(1100.1, 3200.4, 39.2),
    vector3(1300.4, 3250.2, 41.1),
    vector3(2100.2, 2700.5, 43.2),
    vector3(2350.1, 2650.4, 40.1),

    -- Paleto Bay Highway & Flat Shoulders (146-175)
    vector3(-150.2, 6200.4, 31.2),
    vector3(-250.5, 6300.1, 31.5),
    vector3(-350.1, 6400.2, 31.8),
    vector3(-450.4, 6250.5, 28.2),
    vector3(-300.2, 6100.1, 31.2),
    vector3(-150.5, 5950.4, 31.5),
    vector3(-50.1, 5800.2, 35.2),
    vector3(100.4, 5650.5, 40.1),
    vector3(250.2, 5500.1, 43.2),
    vector3(400.5, 5350.2, 47.5),
    vector3(-400.1, 6000.4, 31.2),
    vector3(-200.4, 5850.2, 32.5),
    vector3(-50.2, 5700.1, 38.4),
    vector3(150.5, 5550.4, 42.1),
    vector3(300.1, 5400.2, 45.5),
    vector3(-350.5, 5800.1, 32.1),
    vector3(-250.1, 5650.4, 34.2),
    vector3(-100.2, 5500.5, 39.1),
    vector3(50.4, 5350.1, 44.2),
    vector3(200.2, 5200.4, 48.5),
    vector3(-450.2, 5600.1, 33.2),
    vector3(-300.5, 5450.4, 37.5),
    vector3(-150.1, 5300.2, 41.1),
    vector3(0.4, 5150.5, 46.2),
    vector3(150.2, 5000.1, 51.4),
    vector3(-100.4, 6450.2, 31.5),
    vector3(-200.2, 6500.4, 31.2),
    vector3(-300.1, 6550.1, 31.8),
    vector3(-400.5, 6350.2, 29.4),
    vector3(-450.1, 6150.4, 30.2),

    -- Grapeseed Open Farmland Roads (176-200)
    vector3(1650.1, 4800.4, 42.1),
    vector3(1800.5, 4900.1, 48.2),
    vector3(1950.2, 5000.5, 53.5),
    vector3(2100.4, 5100.2, 59.1),
    vector3(2250.1, 5200.4, 63.2),
    vector3(2400.5, 5300.1, 59.8),
    vector3(2150.2, 4600.5, 38.2),
    vector3(1950.4, 4400.2, 37.5),
    vector3(1750.1, 4200.4, 35.2),
    vector3(1550.5, 4000.1, 34.8),
    vector3(1500.2, 4200.5, 35.4),
    vector3(1700.4, 4400.1, 37.2),
    vector3(1900.1, 4600.4, 40.1),
    vector3(2050.5, 4800.2, 46.5),
    vector3(2200.2, 5000.1, 53.2),
    vector3(2350.4, 5150.5, 58.4),
    vector3(1550.1, 4500.2, 36.5),
    vector3(1750.4, 4700.1, 41.2),
    vector3(1950.2, 4900.4, 48.1),
    vector3(2100.1, 5050.2, 55.4),
    vector3(2300.5, 5250.1, 61.2),
    vector3(1600.4, 4150.5, 35.1),
    vector3(1800.2, 4350.2, 36.4),
    vector3(2000.5, 4550.1, 37.8),
    vector3(2150.1, 4750.4, 39.5)
}

local playerActiveMissions = {}

-- Safe check for on-duty ambulance count using ESX extended players
local function GetOnDutyAmbulanceCount()
    local count = 0
    local xPlayers = ESX.GetExtendedPlayers('job', 'ambulance')
    if xPlayers then
        count = #xPlayers
    end
    return math.max(count, 1)
end

-- Distributed Automated Loop: Ensures only on-duty ambulance workers get mission coordinates
CreateThread(function()
    while true do
        local playerCount = GetOnDutyAmbulanceCount()
        local baseIntervalMs = 50000 
        local dynamicWait = math.floor(baseIntervalMs / playerCount)
        
        Wait(math.random(dynamicWait, dynamicWait + 10000))

        local xPlayers = ESX.GetExtendedPlayers('job', 'ambulance')
        if xPlayers then
            for _, xPlayer in ipairs(xPlayers) do
                local pid = xPlayer.source
                -- Only dispatch a new mission if this specific ambulance player is free
                if not playerActiveMissions[pid] then
                    local locIndex = math.random(1, #emergencyLocations)
                    local missionData = {
                        coords = emergencyLocations[locIndex],
                        isDead = math.random(1, 10) > 5
                    }
                    
                    -- Send independent mission data to this specific player
                    TriggerClientEvent('solo_ambulance:syncAlert', pid, missionData)
                end
            end
        end
    end
end)

RegisterNetEvent('solo_ambulance:acceptMission', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or xPlayer.job.name ~= 'ambulance' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Action Denied',
            description = 'You must be an ambulance worker to accept this dispatch.',
            type = 'error'
        })
        return
    end

    playerActiveMissions[src] = true
end)

-- Handle dispatch mission reward logic
RegisterNetEvent('solo_ambulance:reward', function(amount, actionType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    playerActiveMissions[src] = nil

    if actionType == "revive" then
        xPlayer.addAccountMoney('bank', amount)
        TriggerClientEvent('esx:showNotification', src, '~g~+$3,000~s~ added to your bank account for reviving the patient.')
    elseif actionType == "bodybag" then
        xPlayer.addAccountMoney('bank', amount)
        TriggerClientEvent('esx:showNotification', src, '~g~+$1,000~s~ added to your bank account for securing the body.')
    elseif actionType == "cancel" then
        TriggerClientEvent('esx:showNotification', src, '~y~Mission cleared.~s~ No penalty or reward applied.')
    end
end)

-- Handle penalty fine when mission timer expires
RegisterNetEvent('solo_ambulance:missionFailedFine', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    playerActiveMissions[src] = nil

    local bankBalance = xPlayer.getAccount('bank').money
    if bankBalance >= 500 then
        xPlayer.removeAccountMoney('bank', 500)
        TriggerClientEvent('esx:showNotification', src, '~r~-$500 Fine:~s~ Deducted from your bank for missing the emergency call.')
    else
        xPlayer.setAccountMoney('bank', 0)
        TriggerClientEvent('esx:showNotification', src, '~r~-$500 Fine:~s~ Your bank account was emptied due to insufficient funds.')
    end
end)

-- Admin / Testing Command
RegisterCommand('testamb', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    --[[if not xPlayer or xPlayer.job.name ~= 'ambulance' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Command Denied',
            description = 'You must have the ambulance job to use this test command.',
            type = 'error'
        })
        return
    end]]--

    if playerActiveMissions[source] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Test Failed',
            description = 'You already have an active emergency mission!',
            type = 'error'
        })
        return
    end

    local locIndex = math.random(1, #emergencyLocations)
    local missionData = {
        coords = emergencyLocations[locIndex],
        isDead = math.random(1, 10) > 5
    }

    TriggerClientEvent('solo_ambulance:syncAlert', source, missionData)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Test Success',
        description = 'Forced a unique personal test dispatch call.',
        type = 'success'
    })
end, false)