-- ==============================================================================
-- spawnmanager — fxmanifest.lua
-- Basic spawn-point manager (standalone utility)
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

name        'spawnmanager'
description 'Simple spawn manager — picks the first free spawn point'
version     '1.0.0'
author      'MyServer'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}
