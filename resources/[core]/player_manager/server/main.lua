-- ==============================================================================
-- player_manager/server/main.lua
-- Player registration, loading and saving — database-backed
-- ==============================================================================

local DB = exports['oxmysql']

-- Cache: source → player data (populated in playerConnecting, served on demand)
local playerCache = {}

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

-- Default spawn position (used for new players)
local DEFAULT_POSITION = { x = -269.4, y = -955.3, z = 31.2, heading = 205.0 }

---Ensure a player row exists in the database, store result in cache.
---@param source number
---@param cb function  called with player data table once loaded
local function loadPlayer(source, cb)
    local identifier = getSteamId(source) or getLicenseId(source)
    if not identifier then
        print(('[player_manager] No identifier found for source %d — dropping.'):format(source))
        DropPlayer(source, 'Aucun identifiant valide trouvé.')
        return
    end

    local name = GetPlayerName(source) or 'Unknown'

    DB:single(
        'SELECT * FROM players WHERE identifier = ?',
        { identifier },
        function(row)
            if not row then
                DB:execute(
                    'INSERT INTO players (identifier, name, position, metadata) VALUES (?, ?, ?, ?)',
                    {
                        identifier,
                        name,
                        json.encode(DEFAULT_POSITION),
                        json.encode({}),
                    },
                    function()
                        print(('[player_manager] Registered new player: %s (%s)'):format(name, identifier))
                        local data = { identifier = identifier, name = name, isNew = true,
                                       position = DEFAULT_POSITION,
                                       metadata = {}, money = 0, bank = 0 }
                        playerCache[source] = data
                        if cb then cb(data) end
                    end
                )
            else
                DB:execute(
                    'UPDATE players SET name = ?, last_seen = NOW() WHERE identifier = ?',
                    { name, identifier },
                    function()
                        local data = {
                            identifier = identifier,
                            name       = row.name,
                            position   = json.decode(row.position or '{}'),
                            metadata   = json.decode(row.metadata  or '{}'),
                            money      = row.money or 0,
                            bank       = row.bank  or 0,
                            isNew      = false,
                        }
                        playerCache[source] = data
                        if cb then cb(data) end
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

    -- Load (or register) the player from DB during the deferral window
    loadPlayer(source, function(_data)
        deferrals.done()
    end)
end)

-- Client fires this after spawning to receive its player data
RegisterNetEvent('player_manager:requestData', function()
    local source = source
    local data   = playerCache[source]
    if data then
        TriggerClientEvent('player_manager:ready', source, data)
    else
        -- Fallback: load now (e.g. if connecting without deferral support)
        loadPlayer(source, function(d)
            TriggerClientEvent('player_manager:ready', source, d)
        end)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    playerCache[source] = nil
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
