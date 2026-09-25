local ESX = exports['es_extended']:getSharedObject()
local activeDuels = {}

local function getDuelByPlayer(src)
    for id, duel in pairs(activeDuels) do
        if duel.p1 == src or duel.p2 == src then
            return id, duel
        end
    end
    return nil, nil
end

RegisterNetEvent('safezone_duel:server:requestDuel', function(targetId)
    local src = source
    if src == targetId or getDuelByPlayer(src) or getDuelByPlayer(targetId) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Duel unavailable.', type = 'error' })
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    TriggerClientEvent('ox_lib:notify', src, { title = 'Duel Requested', description = 'Request sent to ID ' .. targetId, type = 'inform' })
    TriggerClientEvent('safezone_duel:client:receiveRequest', targetId, src, xPlayer.getName())
end)

RegisterNetEvent('safezone_duel:server:respondRequest', function(senderId, accepted)
    local src = source
    if not accepted then
        TriggerClientEvent('ox_lib:notify', senderId, { title = 'Declined', description = 'Duel request declined.', type = 'error' })
        return
    end

    local p1Ped = GetPlayerPed(senderId)
    local p2Ped = GetPlayerPed(src)
    local sessionId = 'duel_' .. senderId .. '_' .. src

    activeDuels[sessionId] = {
        p1 = senderId,
        p2 = src,
        state = 'prep',
        timer = Config.ReadyTimeout or 60
    }

    TriggerClientEvent('safezone_duel:client:startPrepTimer', senderId, src, NetworkGetNetworkIdFromEntity(p2Ped))
    TriggerClientEvent('safezone_duel:client:startPrepTimer', src, senderId, NetworkGetNetworkIdFromEntity(p1Ped))

    CreateThread(function()
        while activeDuels[sessionId] and activeDuels[sessionId].state == 'prep' and activeDuels[sessionId].timer > 0 do
            TriggerClientEvent('safezone_duel:client:updatePrepUI', activeDuels[sessionId].p1, activeDuels[sessionId].timer)
            TriggerClientEvent('safezone_duel:client:updatePrepUI', activeDuels[sessionId].p2, activeDuels[sessionId].timer)
            Wait(1000)
            if activeDuels[sessionId] then
                activeDuels[sessionId].timer = activeDuels[sessionId].timer - 1
            end
        end

        if activeDuels[sessionId] and activeDuels[sessionId].state == 'prep' then
            activeDuels[sessionId].state = 'countdown'
            TriggerClientEvent('safezone_duel:client:startCountdown', activeDuels[sessionId].p1)
            TriggerClientEvent('safezone_duel:client:startCountdown', activeDuels[sessionId].p2)
        end
    end)
end)

RegisterNetEvent('safezone_duel:server:duelActive', function()
    local src = source
    local id, duel = getDuelByPlayer(src)
    if duel and duel.state == 'countdown' then
        duel.state = 'active'
        TriggerClientEvent('safezone_duel:client:setDuelActive', duel.p1)
        TriggerClientEvent('safezone_duel:client:setDuelActive', duel.p2)
    end
end)

RegisterNetEvent('safezone_duel:server:surrender', function()
    local src = source
    local id, duel = getDuelByPlayer(src)
    if not duel then return end

    local winnerId = (duel.p1 == src) and duel.p2 or duel.p1
    local winnerObj = ESX.GetPlayerFromId(winnerId)
    local loserObj = ESX.GetPlayerFromId(src)

    local winnerName = winnerObj and winnerObj.getName() or 'Opponent'
    local loserName = loserObj and loserObj.getName() or 'Player'

    TriggerClientEvent('safezone_duel:client:endDuel', src, false, winnerName, loserName .. ' surrendered.')
    TriggerClientEvent('safezone_duel:client:endDuel', winnerId, true, winnerName, loserName .. ' surrendered.')

    activeDuels[id] = nil
end)

RegisterNetEvent('safezone_duel:server:onDeath', function()
    local src = source
    local id, duel = getDuelByPlayer(src)
    if not duel or duel.state ~= 'active' then return end

    local winnerId = (duel.p1 == src) and duel.p2 or duel.p1
    local winnerObj = ESX.GetPlayerFromId(winnerId)
    local loserObj = ESX.GetPlayerFromId(src)

    local winnerName = winnerObj and winnerObj.getName() or 'Opponent'
    local loserName = loserObj and loserObj.getName() or 'Player'

    TriggerClientEvent('safezone_duel:client:endDuel', src, false, winnerName, loserName .. ' was eliminated.')
    TriggerClientEvent('safezone_duel:client:endDuel', winnerId, true, winnerName, 'Eliminated ' .. loserName .. ' in combat.')

    activeDuels[id] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    local id, duel = getDuelByPlayer(src)
    if duel then
        local winnerId = (duel.p1 == src) and duel.p2 or duel.p1
        local winnerObj = ESX.GetPlayerFromId(winnerId)
        TriggerClientEvent('safezone_duel:client:endDuel', winnerId, true, winnerObj and winnerObj.getName() or 'Opponent', 'Opponent disconnected.')
        activeDuels[id] = nil
    end
end)