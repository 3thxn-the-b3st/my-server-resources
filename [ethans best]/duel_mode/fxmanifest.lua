fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Safezone Duel System'
description 'Server-wide safezone, police rules, and 1v1 duel system for ESX'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}