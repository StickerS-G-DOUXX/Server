-- ==============================================================================
-- spawnmanager/server/main.lua
-- Server-side spawn coordination (no DB dependency)
-- ==============================================================================

AddEventHandler('playerSpawned', function()
    local source = source
    print(('[spawnmanager] Player %d spawned.'):format(source))
end)
