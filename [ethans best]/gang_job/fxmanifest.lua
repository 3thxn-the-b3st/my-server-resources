fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'ESX Dynamic Gang Job Resource with ox_target'
version '1.0.0'

dependencies {
    'ox_target',
    'es_extended'
}

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}