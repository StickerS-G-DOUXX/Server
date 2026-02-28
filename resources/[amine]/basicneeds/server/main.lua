-- ==============================================================================
-- basicneeds/server/main.lua
-- Hunger / thirst — persisted in the `player_needs` table
-- ==============================================================================

local DB = exports['oxmysql']

local DRAIN_INTERVAL = 5 * 60 * 1000  -- drain every 5 minutes
local DRAIN_AMOUNT   = 5               -- points drained per interval
local MAX_NEED       = 100

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function getIdentifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and (id:sub(1, 6) == 'steam:' or id:sub(1, 8) == 'license:') then
            return id
        end
    end
    return nil
end

-- ── Load / save ───────────────────────────────────────────────────────────────

local function loadNeeds(source)
    local identifier = getIdentifier(source)
    if not identifier then return end

    local row = DB:singleSync(
        'SELECT hunger, thirst FROM player_needs WHERE identifier = ?',
        { identifier }
    )

    if not row then
        DB:execute(
            'INSERT IGNORE INTO player_needs (identifier, hunger, thirst) VALUES (?, ?, ?)',
            { identifier, MAX_NEED, MAX_NEED }
        )
        row = { hunger = MAX_NEED, thirst = MAX_NEED }
    end

    TriggerClientEvent('basicneeds:sync', source, row.hunger, row.thirst)
end

local function saveNeeds(source, hunger, thirst)
    local identifier = getIdentifier(source)
    if not identifier then return end

    DB:execute(
        'UPDATE player_needs SET hunger = ?, thirst = ? WHERE identifier = ?',
        { hunger, thirst, identifier }
    )
end

-- ── Network events ────────────────────────────────────────────────────────────

-- Client reports its current hunger/thirst for DB save
RegisterNetEvent('basicneeds:save', function(hunger, thirst)
    saveNeeds(source, hunger, thirst)
end)

-- Client requests a reload after eating/drinking
RegisterNetEvent('basicneeds:reload', function()
    loadNeeds(source)
end)

-- ── Drain loop ────────────────────────────────────────────────────────────────

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(DRAIN_INTERVAL)
        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            TriggerClientEvent('basicneeds:drain', src, DRAIN_AMOUNT)
        end
    end
end)

-- ── Load on connect ───────────────────────────────────────────────────────────
-- The client fires basicneeds:requestLoad from onClientResourceStart after spawn.

RegisterNetEvent('basicneeds:requestLoad', function()
    loadNeeds(source)
end)
