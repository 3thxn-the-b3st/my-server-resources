fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Gang Warehouse Raid Mission with Custom NUI HUD & Ambush Tracker'
version '2.3.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}