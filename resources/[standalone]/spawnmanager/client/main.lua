-- ==============================================================================
-- spawnmanager/client/main.lua
-- Spawns the player at the correct position received from player_manager
-- ==============================================================================

local spawnPoints = {
    { x = -269.4, y = -955.3,  z = 31.2,  heading = 205.0 }, -- LSIA area
    { x =  215.2, y = -810.5,  z = 29.7,  heading =  90.0 }, -- Pillbox Hill
    { x = -1037.0, y = -2737.0, z = 20.2, heading =   0.0 }, -- Sandy Shores airfield
}

-- ── Spawn at a specific position ──────────────────────────────────────────────
AddEventHandler('player_manager:ready', function(data)
    local pos = data.position or spawnPoints[1]

    -- Wait until the game is loaded
    while not IsScreenFadedIn() do
        Citizen.Wait(500)
    end

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
