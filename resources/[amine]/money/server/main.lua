-- ==============================================================================
-- money/server/main.lua
-- Cash and bank management — backed by players.money / players.bank columns
-- ==============================================================================

local DB = exports['oxmysql']

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

-- ── Exports — public API ──────────────────────────────────────────────────────

---Get a player's cash balance.
---@param source number
---@return number
exports('getMoney', function(source)
    local identifier = getIdentifier(source)
    if not identifier then return 0 end
    local row = DB:singleSync('SELECT money FROM players WHERE identifier = ?', { identifier })
    return row and row.money or 0
end)

---Get a player's bank balance.
---@param source number
---@return number
exports('getBank', function(source)
    local identifier = getIdentifier(source)
    if not identifier then return 0 end
    local row = DB:singleSync('SELECT bank FROM players WHERE identifier = ?', { identifier })
    return row and row.bank or 0
end)

---Add cash to a player. Returns false if amount is negative.
---@param source number
---@param amount number
---@return boolean
exports('addMoney', function(source, amount)
    amount = math.floor(amount)
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    DB:execute('UPDATE players SET money = money + ? WHERE identifier = ?', { amount, identifier })
    TriggerClientEvent('money:updated', source)
    return true
end)

---Remove cash from a player. Returns false if insufficient funds.
---@param source number
---@param amount number
---@return boolean
exports('removeMoney', function(source, amount)
    amount = math.floor(amount)
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    local row = DB:singleSync('SELECT money FROM players WHERE identifier = ?', { identifier })
    if not row or row.money < amount then return false end
    DB:execute('UPDATE players SET money = money - ? WHERE identifier = ?', { amount, identifier })
    TriggerClientEvent('money:updated', source)
    return true
end)

---Add funds to a player's bank account.
---@param source number
---@param amount number
---@return boolean
exports('addBank', function(source, amount)
    amount = math.floor(amount)
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    DB:execute('UPDATE players SET bank = bank + ? WHERE identifier = ?', { amount, identifier })
    TriggerClientEvent('money:updated', source)
    return true
end)

---Remove funds from a player's bank account.
---@param source number
---@param amount number
---@return boolean
exports('removeBank', function(source, amount)
    amount = math.floor(amount)
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    local row = DB:singleSync('SELECT bank FROM players WHERE identifier = ?', { identifier })
    if not row or row.bank < amount then return false end
    DB:execute('UPDATE players SET bank = bank - ? WHERE identifier = ?', { amount, identifier })
    TriggerClientEvent('money:updated', source)
    return true
end)

-- ── Commands ──────────────────────────────────────────────────────────────────

-- /givemoney <playerId> <amount>  (admin only)
RegisterCommand('givemoney', function(source, args)
    local targetId = tonumber(args[1])
    local amount   = tonumber(args[2])

    if not targetId or not amount then
        TriggerClientEvent('chat:addMessage', source, { args = { '[money]', 'Usage: /givemoney <id> <montant>' } })
        return
    end

    local ok = exports['money']:addMoney(targetId, amount)
    local msg = ok
        and ('Donné %d€ au joueur %d'):format(amount, targetId)
        or  'Erreur: joueur introuvable ou montant invalide'
    TriggerClientEvent('chat:addMessage', source, { args = { '[money]', msg } })
end, true)

-- /wallet  — check own balance
RegisterCommand('wallet', function(source)
    if source == 0 then return end
    local cash = exports['money']:getMoney(source)
    local bank = exports['money']:getBank(source)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 50, 220, 100 },
        args  = { '[Portefeuille]', ('Liquide: %d€  |  Banque: %d€'):format(cash, bank) },
    })
end, false)
