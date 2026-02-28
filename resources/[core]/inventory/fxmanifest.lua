-- ==============================================================================
-- inventory — fxmanifest.lua
-- Server-side inventory system backed by the database
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

name        'inventory'
description 'Player inventory — database-backed'
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
