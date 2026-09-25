fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Job Selection Quiz System'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

shared_scripts {
    '@es_extended/imports.lua'
}