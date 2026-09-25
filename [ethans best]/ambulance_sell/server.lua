local ESX = exports['es_extended']:getSharedObject()

-- Server Callback for Police Count
ESX.RegisterServerCallback('esx_npc_jobsell:server:checkPoliceCount', function(source, cb)
    local xPlayers = ESX.GetExtendedPlayers('job', 'police')
    cb(#xPlayers)
end)

-- Unified Selling Event
RegisterNetEvent('esx_npc_jobsell:server:sellItem', function(mode, itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local itemData = exports.ox_inventory:GetItem(src, itemName)
    if not itemData or itemData.count < amount then
        TriggerClientEvent('esx:showNotification', src, ('You do not have %dx %s in your inventory!'):format(amount, itemName), 'error')
        return
    end

    local totalPrice = 0
    local payoutAccount = 'money'

    if mode == 'ambulance' then
        local priceMap = { medikit = 500, bandage = 300 }
        totalPrice = (priceMap[itemName] or 300) * amount
        payoutAccount = 'money'

    elseif mode == 'gang' then
        local unitPrice = math.random(Config.Gang.PriceRange.min, Config.Gang.PriceRange.max)
        totalPrice = unitPrice * amount
        payoutAccount = 'black_money'

    elseif mode == 'mechanic' then
        totalPrice = Config.Mechanic.Price * amount
        payoutAccount = 'money'
    end

    if exports.ox_inventory:RemoveItem(src, itemName, amount) then
        if payoutAccount == 'black_money' then
            xPlayer.addAccountMoney('black_money', totalPrice)
        else
            xPlayer.addMoney(totalPrice)
        end

        TriggerClientEvent('esx:showNotification', src, ('Sold %dx %s for $%d!'):format(amount, itemName, totalPrice), 'success')
        TriggerClientEvent('esx_npc_jobsell:client:transactionComplete', src)
    else
        TriggerClientEvent('esx:showNotification', src, 'Failed to remove items from inventory.', 'error')
    end
end)

-- Dispatch Alert
RegisterNetEvent('esx_npc_jobsell:server:policeAlert', function(coords)
    local xPlayers = ESX.GetExtendedPlayers('job', 'police')
    for _, xPlayer in pairs(xPlayers) do
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'DISPATCH: Illegal drug activity reported in the area!', 'error')
    end
end)