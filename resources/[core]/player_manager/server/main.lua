-- ==============================================================================
-- player_manager/server/main.lua
-- Player registration, loading and saving — database-backed
-- ==============================================================================

local DB = exports['oxmysql']

-- ── Helpers ───────────────────────────────────────────────────────────────────

---Return the first Steam identifier for a player, or nil.
---@param source number
---@return string|nil
local function getSteamId(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:sub(1, 6) == 'steam:' then
            return id
        end
    end
    return nil
end

---Return the first license identifier for a player, or nil.
---@param source number
---@return string|nil
local function getLicenseId(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

-- ── Player registration / loading ─────────────────────────────────────────────

---Ensure a player row exists in the database, then trigger client ready.
---@param source number
local function loadPlayer(source)
    local identifier = getSteamId(source) or getLicenseId(source)
    if not identifier then
        print(('[player_manager] No identifier found for source %d — dropping.'):format(source))
        DropPlayer(source, 'Aucun identifiant valide trouvé.')
        return
    end

    local name = GetPlayerName(source) or 'Unknown'

    -- Check if the player already exists
    DB:single(
        'SELECT * FROM players WHERE identifier = ?',
        { identifier },
        function(row)
            if not row then
                -- New player — insert
                DB:execute(
                    'INSERT INTO players (identifier, name, position, metadata) VALUES (?, ?, ?, ?)',
                    {
                        identifier,
                        name,
                        json.encode({ x = -269.4, y = -955.3, z = 31.2 }), -- default spawn
                        json.encode({}),
                    },
                    function()
                        print(('[player_manager] Registered new player: %s (%s)'):format(name, identifier))
                        TriggerClientEvent('player_manager:ready', source, { identifier = identifier, name = name, isNew = true })
                    end
                )
            else
                -- Existing player — update name and last_seen
                DB:execute(
                    'UPDATE players SET name = ?, last_seen = NOW() WHERE identifier = ?',
                    { name, identifier },
                    function()
                        TriggerClientEvent('player_manager:ready', source, {
                            identifier = identifier,
                            name        = row.name,
                            position    = json.decode(row.position or '{}'),
                            metadata    = json.decode(row.metadata  or '{}'),
                            isNew       = false,
                        })
                    end
                )
            end
        end
    )
end

-- ── Save player position ───────────────────────────────────────────────────────

RegisterNetEvent('player_manager:savePosition', function(position)
    local source     = source
    local identifier = getSteamId(source) or getLicenseId(source)
    if not identifier then return end

    DB:execute(
        'UPDATE players SET position = ? WHERE identifier = ?',
        { json.encode(position), identifier }
    )
end)

-- ── Events ────────────────────────────────────────────────────────────────────

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    deferrals.update(('Chargement du joueur %s…'):format(name))

    -- Give oxmysql a tick to be ready
    Citizen.SetTimeout(100, function()
        deferrals.done()
    end)
end)

AddEventHandler('playerSpawned', function()
    local source = source
    loadPlayer(source)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    print(('[player_manager] Player %d dropped: %s'):format(source, reason))
end)

-- ── Commands ──────────────────────────────────────────────────────────────────

RegisterCommand('players', function(source, args, rawCommand)
    local rows = DB:querySync('SELECT identifier, name, last_seen FROM players ORDER BY last_seen DESC LIMIT 20', {})
    if source == 0 then
        -- Console
        print('── Last 20 players ─────────────────────────────')
        for _, r in ipairs(rows or {}) do
            print(('  %s  |  %s  |  last seen: %s'):format(r.identifier, r.name, tostring(r.last_seen)))
        end
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 200, 0 },
            args  = { '[player_manager]', ('Total players in DB: %d'):format(#(rows or {})) },
        })
    end
end, true)
