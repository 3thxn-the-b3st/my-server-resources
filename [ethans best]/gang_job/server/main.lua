local ESX = exports['es_extended']:getSharedObject()
local activeBlackMarketIndex = 1

-- Hourly Dynamic Black Market Rotator
CreateThread(function()
    while true do
        activeBlackMarketIndex = math.random(1, #Config.BlackMarketLocations)
        TriggerClientEvent('esx_gangjob:updateBlackMarket', -1, activeBlackMarketIndex)
        Wait(Config.BlackMarketTimer)
    end
end)

-- Sync Black Market position on join
RegisterNetEvent('esx_gangjob:requestBlackMarket', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.job.name == Config.JobName then
        TriggerClientEvent('esx_gangjob:updateBlackMarket', source, activeBlackMarketIndex)
    end
end)

-- Handcuff Item Use
ESX.RegisterUsableItem(Config.HandcuffItem, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.job.name == Config.JobName then
        TriggerClientEvent('esx_gangjob:useHandcuffs', source)
    else
        TriggerClientEvent('esx:showNotification', source, 'You do not know how to use these effectively.')
    end
end)

-- Black Market Purchase Server Event (Uses Black Money)
RegisterNetEvent('esx_gangjob:buyBlackMarketItem', function(itemName, isWeapon, price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or xPlayer.job.name ~= Config.JobName then return end

    local accountName = Config.BlackMarketAccount or 'black_money'
    local playerBlackMoney = xPlayer.getAccount(accountName).money

    if playerBlackMoney >= price then
        xPlayer.removeAccountMoney(accountName, price)
        if isWeapon then
            xPlayer.addWeapon(itemName, 100)
        else
            xPlayer.addInventoryItem(itemName, 1)
        end
        TriggerClientEvent('esx:showNotification', source, 'Purchase successful using dirty money.')
    else
        TriggerClientEvent('esx:showNotification', source, 'You do not have enough black money.')
    end
end)

-- Vehicle Actions Syncing
RegisterNetEvent('esx_gangjob:putInVehicle', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.job.name == Config.JobName then
        TriggerClientEvent('esx_gangjob:putInVehicleClient', targetId)
    end
end)

RegisterNetEvent('esx_gangjob:outVehicle', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.job.name == Config.JobName then
        TriggerClientEvent('esx_gangjob:outVehicleClient', targetId)
    end
end)

RegisterNetEvent('esx_gangjob:cuffPlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.job.name == Config.JobName then
        TriggerClientEvent('esx_gangjob:cuffClient', targetId)
    end
end)