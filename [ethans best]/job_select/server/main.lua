local ESX = exports["es_extended"]:getSharedObject()

-- Server event to check status before opening the UI
RegisterNetEvent('job_quiz:checkAndOpen')
AddEventHandler('job_quiz:checkAndOpen', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    MySQL.scalar('SELECT completed_quiz FROM users WHERE identifier = ?', { xPlayer.identifier }, function(completed)
        if completed == 1 then
            TriggerClientEvent('esx:showNotification', _source, 'You have already completed your job entrance exam.')
        else
            TriggerClientEvent('job_quiz:startQuizClient', _source)
        end
    end)
end)

-- Server event to set the job and save completion to database
RegisterNetEvent('job_quiz:setJob')
AddEventHandler('job_quiz:setJob', function(jobName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        -- Verify again that they haven't already completed it
        MySQL.scalar('SELECT completed_quiz FROM users WHERE identifier = ?', { xPlayer.identifier }, function(completed)
            if completed == 1 then
                TriggerClientEvent('esx:showNotification', _source, 'Error: You have already completed this exam.')
                return
            end

            -- Mark quiz as completed in database
            MySQL.update('UPDATE users SET completed_quiz = 1 WHERE identifier = ?', { xPlayer.identifier })

            if jobName == "civilian" then
                xPlayer.setJob("unemployed", 0)
                TriggerClientEvent('esx:showNotification', _source, 'You chose to remain a civilian.')
            else
                xPlayer.setJob(jobName, 0)
                TriggerClientEvent('esx:showNotification', _source, 'You have been hired as a ' .. jobName .. '!')
                
                local playerName = GetPlayerName(_source)
                local formattedJob = string.upper(string.sub(jobName, 1, 1)) .. string.sub(jobName, 2)
                
                TriggerClientEvent('chat:addMessage', -1, {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {"City Announcement", playerName .. " has officially passed the " .. formattedJob .. " board exam!"}
                })
            end
        end)
    end
end)