local ESX = exports['es_extended']:getSharedObject()

local activeMode = nil -- 'ambulance', 'gang', 'mechanic', or nil
local currentNPC = nil
local lastGangSellTime = 0

-- Helper function to clear active target / ped state
local function CleanupNPC(wasKilled)
    if currentNPC and DoesEntityExist(currentNPC) then
        exports.ox_target:removeLocalEntity(currentNPC, 'jobsell_target_option')
        if not wasKilled then
            TaskWanderStandard(currentNPC, 10.0, 10)
        end
        SetPedAsNoLongerNeeded(currentNPC)
        currentNPC = nil
    end
end

-- Shared function to spawn a ped 30-45 units away
local function SpawnNPCNearPlayer(modelList)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local modelName = modelList[math.random(#modelList)]
    local modelHash = GetHashKey(modelName)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end

    local angle = math.random() * 2 * math.pi
    local distance = math.random(30, 45) + 0.0
    local spawnX = playerCoords.x + (math.cos(angle) * distance)
    local spawnY = playerCoords.y + (math.sin(angle) * distance)
    local found, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, playerCoords.z + 10.0, 0)
    local spawnZ = found and groundZ or playerCoords.z

    local ped = CreatePed(4, modelHash, spawnX, spawnY, spawnZ, 0.0, true, true)
    TaskGoToEntity(ped, playerPed, -1, 1.5, 1.0, 1073741824, 0)
    return ped
end

-- ==========================================
-- AMBULANCE SELLING
-- ==========================================
local function SpawnAmbulanceCustomer()
    currentNPC = SpawnNPCNearPlayer(Config.Ambulance.PedModels)

    local animSet = "move_m@injured"
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do Wait(10) end

    SetPedMovementClipset(currentNPC, animSet, 1.0)
    SetEntityHealth(currentNPC, 120)

    local request = Config.Ambulance.Items[math.random(#Config.Ambulance.Items)]
    local amount = math.random(3, 5)

    ESX.ShowNotification(('An injured citizen is approaching requesting %dx %s (30s remaining)'):format(amount, request.label), 'info')

    exports.ox_target:addLocalEntity(currentNPC, {
        {
            name = 'jobsell_target_option',
            icon = 'fas fa-hand-holding-medical',
            label = ('Sell %dx %s'):format(amount, request.label),
            canInteract = function(entity)
                return activeMode == 'ambulance' and currentNPC == entity and GetEntityHealth(entity) > 0
            end,
            onSelect = function()
                TriggerServerEvent('esx_npc_jobsell:server:sellItem', 'ambulance', request.item, amount)
            end
        }
    })

    -- 30 Second Timer
    local targetNPC = currentNPC
    CreateThread(function()
        Wait(Config.Ambulance.PatienceTimer)
        if activeMode == 'ambulance' and currentNPC == targetNPC then
            SetEntityHealth(currentNPC, 0)
            ESX.ShowNotification('The patient has died because of not having his medikit or bandage on time.', 'error')
            Wait(5000)
            CleanupNPC(true)
        end
    end)
end

RegisterCommand(Config.Ambulance.CommandStart, function()
    local playerData = ESX.GetPlayerData()
    if not playerData.job or playerData.job.name ~= Config.Ambulance.Job then
        ESX.ShowNotification('You must be an ambulance worker to sell medical supplies!', 'error')
        return
    end

    if activeMode then
        ESX.ShowNotification('You are already selling items!', 'error')
        return
    end

    activeMode = 'ambulance'
    ESX.ShowNotification('Started selling medical supplies to injured citizens...', 'success')

    CreateThread(function()
        while activeMode == 'ambulance' do
            Wait(Config.Ambulance.Interval)
            if activeMode ~= 'ambulance' then break end
            if not currentNPC then
                SpawnAmbulanceCustomer()
            end
        end
    end)
end, false)

RegisterCommand(Config.Ambulance.CommandStop, function()
    if activeMode ~= 'ambulance' then
        ESX.ShowNotification('You are not currently selling medical supplies.', 'info')
        return
    end
    activeMode = nil
    ESX.ShowNotification('Stopped selling medical supplies.', 'info')
    CleanupNPC(false)
end, false)

-- ==========================================
-- GANG SELLING
-- ==========================================
local function SpawnAIPoliceCruiser(coords)
    local vehicleHash = GetHashKey("police")
    local driverHash = GetHashKey("s_m_y_cop_01")

    RequestModel(vehicleHash)
    RequestModel(driverHash)
    while not HasModelLoaded(vehicleHash) or not HasModelLoaded(driverHash) do Wait(10) end

    local spawnCoords = vector3(coords.x + 50.0, coords.y + 50.0, coords.z)
    local copVehicle = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
    local copPed = CreatePedInsideVehicle(copVehicle, 26, driverHash, -1, true, true)

    TaskVehicleDriveToCoord(copPed, copVehicle, coords.x, coords.y, coords.z, 30.0, 0, vehicleHash, 786587, 1.0, 1)
    GiveWeaponToPed(copPed, GetHashKey('WEAPON_COMBATPISTOL'), 250, false, true)

    CreateThread(function()
        while DoesEntityExist(copPed) do
            Wait(1000)
            if #(GetEntityCoords(copPed) - GetEntityCoords(PlayerPedId())) < 20.0 then
                TaskCombatPed(copPed, PlayerPedId(), 0, 16)
                break
            end
        end
    end)
end

local function HandleGangCustomer()
    currentNPC = SpawnNPCNearPlayer(Config.Gang.PedModels)
    local chance = math.random(1, 100)

    if chance <= 70 then
        -- Legitimate Customer
        local request = Config.Gang.Items[math.random(#Config.Gang.Items)]
        local amount = math.random(1, 3)

        ESX.ShowNotification(('A buyer is approaching asking for %dx %s'):format(amount, request.label), 'info')

        exports.ox_target:addLocalEntity(currentNPC, {
            {
                name = 'jobsell_target_option',
                icon = 'fas fa-cannabis',
                label = ('Sell %dx %s'):format(amount, request.label),
                canInteract = function(entity)
                    return activeMode == 'gang' and currentNPC == entity
                end,
                onSelect = function()
                    TriggerServerEvent('esx_npc_jobsell:server:sellItem', 'gang', request.item, amount)
                end
            }
        })

    elseif chance <= 85 then
        -- Attack/Robber NPC
        ESX.ShowNotification('The buyer tried to setup and attack you!', 'error')
        GiveWeaponToPed(currentNPC, GetHashKey('WEAPON_PISTOL'), 250, false, true)
        TaskCombatPed(currentNPC, PlayerPedId(), 0, 16)

    else
        -- Snitch NPC / Cops Alerted
        ESX.ShowNotification('The citizen spotted your drugs and called the police!', 'error')
        TaskReactAndFleePed(currentNPC, PlayerPedId())

        local playerCoords = GetEntityCoords(PlayerPedId())
        ESX.TriggerServerCallback('esx_npc_jobsell:server:checkPoliceCount', function(policeCount)
            if policeCount > 0 then
                TriggerServerEvent('esx_npc_jobsell:server:policeAlert', playerCoords)
            else
                SpawnAIPoliceCruiser(playerCoords)
            end

            activeMode = nil
            lastGangSellTime = GetGameTimer()
            ESX.ShowNotification('Police alerted! Selling canceled for 15 minutes.', 'error')
            CleanupNPC(false)
        end)
    end
end

RegisterCommand(Config.Gang.CommandStart, function()
    local playerData = ESX.GetPlayerData()
    if not playerData.job or not Config.Gang.Jobs[playerData.job.name] then
        ESX.ShowNotification('Only gang members can sell street drugs!', 'error')
        return
    end

    if activeMode then
        ESX.ShowNotification('You are already selling items!', 'error')
        return
    end

    local currentTime = GetGameTimer()
    if lastGangSellTime ~= 0 and (currentTime - lastGangSellTime) < Config.Gang.CooldownTime then
        local remainingMin = math.ceil((Config.Gang.CooldownTime - (currentTime - lastGangSellTime)) / 60000)
        ESX.ShowNotification(('You are on heat! Wait %d minutes before selling again.'):format(remainingMin), 'error')
        return
    end

    activeMode = 'gang'
    ESX.ShowNotification('Looking for drug buyers in the area...', 'success')

    CreateThread(function()
        while activeMode == 'gang' do
            Wait(Config.Gang.Interval)
            if activeMode ~= 'gang' then break end
            if not currentNPC then
                HandleGangCustomer()
            end
        end
    end)
end, false)

RegisterCommand(Config.Gang.CommandStop, function()
    if activeMode ~= 'gang' then
        ESX.ShowNotification('You are not currently selling drugs.', 'info')
        return
    end
    activeMode = nil
    ESX.ShowNotification('Stopped selling drugs.', 'info')
    CleanupNPC(false)
end, false)

-- ==========================================
-- MECHANIC SELLING
-- ==========================================
local function SpawnMechanicCustomer()
    currentNPC = SpawnNPCNearPlayer(Config.Mechanic.PedModels)

    ESX.ShowNotification(('A driver is approaching asking for 1x Repair Kit ($%d)'):format(Config.Mechanic.Price), 'info')

    exports.ox_target:addLocalEntity(currentNPC, {
        {
            name = 'jobsell_target_option',
            icon = 'fas fa-wrench',
            label = ('Sell Fixkit ($%d)'):format(Config.Mechanic.Price),
            canInteract = function(entity)
                return activeMode == 'mechanic' and currentNPC == entity
            end,
            onSelect = function()
                TriggerServerEvent('esx_npc_jobsell:server:sellItem', 'mechanic', Config.Mechanic.Item, 1)
            end
        }
    })
end

RegisterCommand(Config.Mechanic.CommandStart, function()
    local playerData = ESX.GetPlayerData()
    if not playerData.job or playerData.job.name ~= Config.Mechanic.Job then
        ESX.ShowNotification('You must be a mechanic to sell repair kits!', 'error')
        return
    end

    if activeMode then
        ESX.ShowNotification('You are already selling items!', 'error')
        return
    end

    activeMode = 'mechanic'
    ESX.ShowNotification('Started offering repair kits to stranded drivers...', 'success')

    CreateThread(function()
        while activeMode == 'mechanic' do
            Wait(Config.Mechanic.Interval)
            if activeMode ~= 'mechanic' then break end
            if not currentNPC then
                SpawnMechanicCustomer()
            end
        end
    end)
end, false)

RegisterCommand(Config.Mechanic.CommandStop, function()
    if activeMode ~= 'mechanic' then
        ESX.ShowNotification('You are not currently selling repair kits.', 'info')
        return
    end
    activeMode = nil
    ESX.ShowNotification('Stopped selling repair kits.', 'info')
    CleanupNPC(false)
end, false)

-- ==========================================
-- TRANSACTION FINISHED
-- ==========================================
RegisterNetEvent('esx_npc_jobsell:client:transactionComplete', function()
    if currentNPC then
        ResetPedMovementClipset(currentNPC, 0.2)
        TaskWanderStandard(currentNPC, 10.0, 10)
        SetPedAsNoLongerNeeded(currentNPC)
        exports.ox_target:removeLocalEntity(currentNPC, 'jobsell_target_option')
        currentNPC = nil
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupNPC(false)
    end
end)