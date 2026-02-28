-- ==============================================================================
-- chat — fxmanifest.lua
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

name        'chat'
description 'Système de chat FR avec commandes /me, /ooc, /help'
version     '1.0.0'
author      'MyServer'

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}
