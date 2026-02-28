-- ==============================================================================
-- money — fxmanifest.lua
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

name        'money'
description 'Gestion argent liquide et bancaire — base de données'
version     '1.0.0'
author      'MyServer'

dependencies {
    'oxmysql',
    'player_manager',
}

server_scripts {
    'server/main.lua',
}
