-- ==============================================================================
-- oxmysql/server/main.lua
-- Async MySQL wrapper — exposes MySQL.Async and MySQL.Sync exports
-- ==============================================================================

-- ── Connection state ──────────────────────────────────────────────────────────
local ready = false

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local connectionString = GetConvar('mysql_connection_string', '')
        if connectionString == '' then
            print('[oxmysql] ^1ERROR: mysql_connection_string convar is not set.^0')
            print('[oxmysql] ^3Set it in server.cfg, e.g.:^0')
            print('[oxmysql] ^3  set mysql_connection_string "mysql://root:password@localhost/fivem_server"^0')
            return
        end
        print('[oxmysql] ^2Connected to database.^0')
        ready = true
    end
end)

-- ── Internal helper ───────────────────────────────────────────────────────────
local function assertReady()
    if not ready then
        error('[oxmysql] Database is not ready yet. Ensure oxmysql starts before other resources.')
    end
end

-- NOTE: MySQL.Async and MySQL.Sync are globals injected by the FiveM runtime
-- when a mysql-async-compatible library (oxmysql native binary, mysql-async, etc.)
-- is loaded.  This wrapper re-exports those globals under a consistent API so
-- other resources can call exports['oxmysql']:query(...) without knowing which
-- underlying library is installed.
-- ── Exports — Async API ───────────────────────────────────────────────────────

---Execute a query without returning results (INSERT, UPDATE, DELETE).
---@param query string
---@param parameters table
---@param cb function|nil  called with affected row count
exports('execute', function(query, parameters, cb)
    assertReady()
    MySQL.Async.execute(query, parameters or {}, cb)
end)

---Fetch multiple rows.
---@param query string
---@param parameters table
---@param cb function  called with array of row tables
exports('query', function(query, parameters, cb)
    assertReady()
    MySQL.Async.fetchAll(query, parameters or {}, cb)
end)

---Fetch a single row.
---@param query string
---@param parameters table
---@param cb function  called with single row table or nil
exports('single', function(query, parameters, cb)
    assertReady()
    MySQL.Async.fetchSingle(query, parameters or {}, cb)
end)

---Fetch a single scalar value.
---@param query string
---@param parameters table
---@param cb function  called with scalar value
exports('scalar', function(query, parameters, cb)
    assertReady()
    MySQL.Async.fetchScalar(query, parameters or {}, cb)
end)

-- ── Exports — Sync/Await API (server-side coroutines) ────────────────────────

---Synchronous execute (blocks coroutine until done).
---@param query string
---@param parameters table
---@return number affectedRows
exports('executeSync', function(query, parameters)
    assertReady()
    return MySQL.Sync.execute(query, parameters or {})
end)

---Synchronous fetchAll.
---@param query string
---@param parameters table
---@return table rows
exports('querySync', function(query, parameters)
    assertReady()
    return MySQL.Sync.fetchAll(query, parameters or {})
end)

---Synchronous fetchSingle.
---@param query string
---@param parameters table
---@return table|nil row
exports('singleSync', function(query, parameters)
    assertReady()
    return MySQL.Sync.fetchSingle(query, parameters or {})
end)

---Synchronous fetchScalar.
---@param query string
---@param parameters table
---@return any value
exports('scalarSync', function(query, parameters)
    assertReady()
    return MySQL.Sync.fetchScalar(query, parameters or {})
end)
