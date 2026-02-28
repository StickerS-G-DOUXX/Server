-- ==============================================================================
-- player_manager — fxmanifest.lua
-- Handles player registration, loading and saving data to the database
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

name        'player_manager'
description 'Player registration and data persistence'
version     '1.0.0'
author      'MyServer'

dependencies {
    'oxmysql',
}

server_scripts {
    'server/main.lua',
}
