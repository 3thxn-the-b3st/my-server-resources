fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Synced Solo/Team Ambulance Mission Script'
version '2.0.4'

dependency 'ox_lib'

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

server_script 'server.lua'