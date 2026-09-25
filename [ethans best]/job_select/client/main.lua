local ESX = exports["es_extended"]:getSharedObject()
local isUIOpen = false

-- Command to test
RegisterCommand('openjobquiz', function()
    TriggerServerEvent('job_quiz:checkAndOpen')
end)

-- Main trigger event (Call this after character creation)
RegisterNetEvent('job_quiz:openMenu')
AddEventHandler('job_quiz:openMenu', function()
    TriggerServerEvent('job_quiz:checkAndOpen')
end)

-- Received from server if database check passes
RegisterNetEvent('job_quiz:startQuizClient')
AddEventHandler('job_quiz:startQuizClient', function()
    openJobQuizUI()
end)

function openJobQuizUI()
    if not isUIOpen then
        isUIOpen = true
        SetNuiFocus(true, true)
        
        local ped = PlayerPedId()
        SetEntityVisible(ped, false, 0)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)

        SendNUIMessage({
            action = "openMenu"
        })
    end
end

RegisterNUICallback('setPlayerJob', function(data, cb)
    local jobName = data.job
    
    TriggerServerEvent('job_quiz:setJob', jobName)
    
    isUIOpen = false
    SetNuiFocus(false, false)
    
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, 0)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)

    cb('ok')
end)