local ESX = exports['es_extended']:getSharedObject()
local activeDuel = nil      -- Stores { opponentServerId, opponentNetId, status }
local isPoliceCache = false

-- Cache Police status on job updates
RegisterNetEvent('esx:setJob', function(job)
    isPoliceCache = Config.PoliceJobs[job.name] or false
    LocalPlayer.state:set('isPolice', isPoliceCache, true)
end)

AddEventHandler('esx:playerLoaded', function(xPlayer)
    isPoliceCache = Config.PoliceJobs[xPlayer.job.name] or false
    LocalPlayer.state:set('isPolice', isPoliceCache, true)
end)

--------------------------------------------------------------------------------
-- OPTIMIZED SAFEZONE & TARGETING THREAD
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerId = PlayerId()
        local inRaid = LocalPlayer.state.inGangRaid or false

        -- 1. Aiming / Firing Restrictions
        if IsPlayerFreeAiming(playerId) then
            sleep = 0
            local foundEntity, targetedEntity = GetEntityPlayerIsFreeAimingAt(playerId)
            if foundEntity and IsEntityAPed(targetedEntity) and IsPedAPlayer(targetedEntity) then
                local targetPlayerIndex = NetworkGetPlayerIndexFromPed(targetedEntity)
                local targetServerId = GetPlayerServerId(targetPlayerIndex)
                local isTargetPolice = Player(targetServerId).state.isPolice or false

                if inRaid then
                    -- RAID MODE: Only allow shooting Police players (NPC shooting is naturally allowed)
                    if not isTargetPolice then
                        DisablePlayerFiring(playerId, true)
                    end
                elseif activeDuel then
                    -- DUEL MODE: Only allow firing at designated opponent
                    if targetServerId ~= activeDuel.opponentServerId then
                        DisablePlayerFiring(playerId, true)
                    end
                else
                    -- STANDARD SAFEZONE: Disable firing at any player unless local player is police
                    if not isPoliceCache then
                        DisablePlayerFiring(playerId, true)
                    end
                end
            end
        end

        -- Block firing during Prep / Countdown phases of duels
        if activeDuel and (activeDuel.status == 'prep' or activeDuel.status == 'countdown') then
            sleep = 0
            DisablePlayerFiring(playerId, true)
        end

        -- 2. VDM / Ghost Collision Loop
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        if inVehicle or activeDuel or inRaid then
            sleep = 0
            SetPedCanBeKnockedOffVehicle(playerPed, 1)

            if not activeDuel then
                -- Disable vehicle damage proofs if in raid so police/NPCs can damage vehicles normally
                if not inRaid then
                    SetEntityProofs(playerPed, false, false, false, true, false, false, false, false)
                else
                    SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
                end

                local vehicle = inVehicle and GetVehiclePedIsIn(playerPed, false) or ESX.Game.GetClosestVehicle()
                if DoesEntityExist(vehicle) then
                    local pCoords = GetEntityCoords(playerPed)
                    local vCoords = GetEntityCoords(vehicle)
                    if #(pCoords - vCoords) < 5.0 and not inRaid then
                        SetEntityNoCollisionEntity(playerPed, vehicle, false)
                        SetEntityNoCollisionEntity(vehicle, playerPed, false)
                    end
                end
            else
                SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
                local opponentPed = NetworkGetEntityFromNetworkId(activeDuel.opponentNetId or 0)
                if DoesEntityExist(opponentPed) then
                    local oppVehicle = IsPedInAnyVehicle(opponentPed, false) and GetVehiclePedIsIn(opponentPed, false) or nil
                    if oppVehicle then
                        SetEntityNoCollisionEntity(playerPed, oppVehicle, true)
                        SetEntityNoCollisionEntity(oppVehicle, playerPed, true)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

--------------------------------------------------------------------------------
-- EVENT-BASED DAMAGE PROTECTION
--------------------------------------------------------------------------------
AddEventHandler('gameEventTriggered', function(eventName, eventData)
    if eventName == "CEventNetworkEntityDamage" then
        local victim = eventData[1]
        local attacker = eventData[2]
        local isDead = eventData[6] == 1
        local playerPed = PlayerPedId()

        if victim == playerPed then
            SetPedSuffersCriticalHits(playerPed, false)

            local isDuelActive = activeDuel and activeDuel.status == 'active'
            local inRaid = LocalPlayer.state.inGangRaid or false
            local cancelDamage = false

            if IsEntityAPed(attacker) then
                if IsPedAPlayer(attacker) then
                    local attackerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
                    local isAttackerPolice = Player(attackerServerId).state.isPolice or false

                    if inRaid then
                        -- In raid: Accept damage from Police players, block non-police player damage
                        if not isAttackerPolice then cancelDamage = true end
                    elseif isDuelActive then
                        if attackerServerId ~= activeDuel.opponentServerId then cancelDamage = true end
                    elseif not isPoliceCache then
                        cancelDamage = true
                    end
                else
                    -- Attacker is an NPC Ped (Warehouse Guard / NPC Police): Allow damage during raid
                    if not inRaid and not isPoliceCache then
                        cancelDamage = true
                    end
                end
            elseif IsEntityAVehicle(attacker) then
                local driver = GetPedInVehicleSeat(attacker, -1)
                if driver ~= 0 and IsPedAPlayer(driver) then
                    local driverServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(driver))
                    local isDriverPolice = Player(driverServerId).state.isPolice or false

                    if inRaid then
                        if not isDriverPolice then cancelDamage = true end
                    elseif isDuelActive then
                        if driverServerId ~= activeDuel.opponentServerId then cancelDamage = true end
                    elseif not isPoliceCache then
                        cancelDamage = true
                    end
                end
            end

            if cancelDamage then
                local currentHealth = GetEntityHealth(playerPed)
                local maxHealth = GetEntityMaxHealth(playerPed)
                if currentHealth < maxHealth and not isDead then
                    SetEntityHealth(playerPed, maxHealth)
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- OX_TARGET REGISTRATION
--------------------------------------------------------------------------------
CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        {
            name = 'safezone_challenge_duel',
            icon = 'fas fa-swords',
            label = 'Challenge to Duel',
            distance = 2.5,
            canInteract = function(entity)
                return activeDuel == nil and not (LocalPlayer.state.inGangRaid or false) and not IsEntityDead(entity)
            end,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetEntityOwner(data.entity))
                if targetServerId and targetServerId > 0 then
                    TriggerServerEvent('safezone_duel:server:requestDuel', targetServerId)
                else
                    lib.notify({ title = 'Error', description = 'Target lost. Try again.', type = 'error' })
                end
            end
        }
    })
end)

--------------------------------------------------------------------------------
-- DUEL EVENTS & UI
--------------------------------------------------------------------------------
RegisterNetEvent('safezone_duel:client:receiveRequest', function(senderId, senderName)
    local alert = lib.alertDialog({
        header = 'Duel Challenge',
        content = senderName .. ' [' .. senderId .. '] has challenged you to a duel!\nDo you accept?',
        centered = true,
        cancel = true
    })

    TriggerServerEvent('safezone_duel:server:respondRequest', senderId, alert == 'confirm')
end)

RegisterNetEvent('safezone_duel:client:startPrepTimer', function(opponentServerId, opponentNetId)
    activeDuel = {
        opponentServerId = opponentServerId,
        opponentNetId = opponentNetId,
        status = 'prep'
    }
    lib.notify({ title = 'Duel Accepted', description = '1-Minute warmup started. Type /surrender to forfeit.', type = 'inform' })
end)

RegisterNetEvent('safezone_duel:client:updatePrepUI', function(secondsLeft)
    if activeDuel and activeDuel.status == 'prep' then
        lib.showTextUI('DUEL STARTS IN: ' .. secondsLeft .. 's | /surrender to Forfeit', { position = 'top-center', icon = 'clock' })
    end
end)

RegisterNetEvent('safezone_duel:client:startCountdown', function()
    if not activeDuel then return end
    activeDuel.status = 'countdown'

    for i = Config.StartCountdown, 1, -1 do
        lib.showTextUI('FIGHT IN: ' .. i, { position = 'top-center', icon = 'clock' })
        PlaySoundFrontend(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", true)
        Wait(1000)
    end

    lib.showTextUI('FIGHT!', { position = 'top-center', icon = 'swords' })
    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)

    TriggerServerEvent('safezone_duel:server:duelActive')
    Wait(1500)
    lib.hideTextUI()
end)

RegisterNetEvent('safezone_duel:client:setDuelActive', function()
    if activeDuel then
        activeDuel.status = 'active'
        lib.notify({ title = 'DUEL IS LIVE', description = 'You can now fight your opponent! Type /surrender to forfeit.', type = 'warning' })
    end
end)

RegisterNetEvent('safezone_duel:client:endDuel', function(isWinner, winnerName, reason)
    lib.hideTextUI()
    activeDuel = nil

    CreateThread(function()
        local titleText = isWinner and '🏆 VICTORY! 🏆' or '☠️ DEFEAT ☠️'
        local message = isWinner and ('You won against ' .. winnerName .. '!\n' .. reason) or ('Winner: ' .. winnerName .. '\n' .. reason)
        local iconType = isWinner and 'trophy' or 'skull'

        PlaySoundFrontend(-1, isWinner and "RACE_PLACED_FIRST" or "ScreenFlash", "HUD_AWARDS", true)

        for i = 10, 1, -1 do
            lib.showTextUI(titleText .. '\n' .. message .. '\nClosing in ' .. i .. 's', {
                position = 'top-center',
                icon = iconType
            })
            Wait(1000)
        end
        lib.hideTextUI()
    end)
end)

RegisterCommand('surrender', function()
    if activeDuel then
        TriggerServerEvent('safezone_duel:server:surrender')
    else
        lib.notify({ title = 'Error', description = 'You are not in a duel.', type = 'error' })
    end
end, false)

AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
        local victim = data[1]
        if victim == PlayerPedId() and IsEntityDead(victim) and activeDuel then
            TriggerServerEvent('safezone_duel:server:onDeath')
        end
    end
end)