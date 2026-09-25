fx_version 'cerulean'
game 'gta5'

author 'ESX Robbery Script'
description 'Store Robbery with NPC Police Backup, Lobby system, and UI'
version '1.0.0'

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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}