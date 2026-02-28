-- ==============================================================================
-- spawnmanager/client/main.lua
-- Spawns the player at the correct position received from player_manager
-- ==============================================================================

local DEFAULT_SPAWN = { x = -269.4, y = -955.3, z = 31.2, heading = 205.0 }

-- ── Step 1: after the game spawns us, ask the server for our player data ──────
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('player_manager:requestData')
end)

-- ── Step 2: server responds with our data — teleport to saved position ────────
AddEventHandler('player_manager:ready', function(data)
    local pos = (data.position and data.position.x) and data.position or DEFAULT_SPAWN

    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) do
        Citizen.Wait(100)
    end

    local ped = PlayerPedId()
    SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
    SetEntityHeading(ped, pos.heading or 0.0)
    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, pos.heading or 0.0, true, false)

    print(('[spawnmanager] Spawned at %.1f, %.1f, %.1f'):format(pos.x, pos.y, pos.z))
end)

-- ── Auto-save position every 60 seconds ──────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        TriggerServerEvent('player_manager:savePosition', { x = pos.x, y = pos.y, z = pos.z })
    end
end)
