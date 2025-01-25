fx_version 'cerulean'
game 'gta5'

author 'Emojiado'
description 'Sistema de Gestión de NPCs'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server/*.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'mysql-async'
}

lua54 'yes'