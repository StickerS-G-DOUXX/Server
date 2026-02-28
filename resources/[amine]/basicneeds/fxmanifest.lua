-- ==============================================================================
-- basicneeds — fxmanifest.lua
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

name        'basicneeds'
description 'Système faim / soif persisté en base de données'
version     '1.0.0'
author      'MyServer'

dependencies {
    'oxmysql',
    'player_manager',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}
