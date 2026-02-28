-- ==============================================================================
-- inventory/server/main.lua
-- Server-side inventory logic — all data lives in MySQL
-- ==============================================================================

local DB = exports['oxmysql']

-- ── Item definitions ──────────────────────────────────────────────────────────
-- Add / modify item definitions here.  weight is in grams.
local Items = {
    ['water']       = { label = 'Eau en bouteille',  weight = 500,  usable = true  },
    ['bread']       = { label = 'Pain',              weight = 200,  usable = true  },
    ['bandage']     = { label = 'Bandage',           weight = 100,  usable = true  },
    ['phone']       = { label = 'Téléphone',         weight = 150,  usable = false },
    ['id_card']     = { label = 'Carte d\'identité', weight =  50,  usable = false },
    ['money']       = { label = 'Argent liquide',    weight =   0,  usable = false },
    ['lockpick']    = { label = 'Crochet de serrure', weight = 80,  usable = true  },
}

local MAX_WEIGHT = 30000  -- 30 kg in grams

-- ── Helpers ───────────────────────────────────────────────────────────────────

---Get the primary identifier of a connected player.
---@param source number
---@return string|nil
local function getIdentifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and (id:sub(1, 6) == 'steam:' or id:sub(1, 8) == 'license:') then
            return id
        end
    end
    return nil
end

---Calculate total inventory weight for a player.
---@param identifier string
---@return number
local function getTotalWeight(identifier)
    local rows = DB:querySync(
        'SELECT i.item_name, inv.quantity FROM inventory inv JOIN items i ON inv.item_name = i.item_name WHERE inv.identifier = ?',
        { identifier }
    )
    local total = 0
    for _, row in ipairs(rows or {}) do
        local def = Items[row.item_name]
        if def then
            total = total + (def.weight * row.quantity)
        end
    end
    return total
end

-- ── Exports — public API ──────────────────────────────────────────────────────

---Add an item to a player's inventory.
---@param source number
---@param itemName string
---@param quantity number
---@return boolean success, string? reason
exports('addItem', function(source, itemName, quantity)
    quantity = quantity or 1
    local identifier = getIdentifier(source)
    if not identifier then return false, 'no_identifier' end
    if not Items[itemName] then return false, 'unknown_item' end

    -- Weight check
    local itemWeight   = Items[itemName].weight * quantity
    local totalWeight  = getTotalWeight(identifier)
    if totalWeight + itemWeight > MAX_WEIGHT then
        return false, 'too_heavy'
    end

    -- Upsert (MySQL 8.0.20+ compatible — avoids deprecated VALUES() function)
    DB:execute(
        [[INSERT INTO inventory (identifier, item_name, quantity)
          VALUES (?, ?, ?)
          ON DUPLICATE KEY UPDATE quantity = quantity + ?]],
        { identifier, itemName, quantity, quantity }
    )

    TriggerClientEvent('inventory:itemAdded', source, itemName, quantity)
    return true
end)

---Remove an item from a player's inventory.
---@param source number
---@param itemName string
---@param quantity number
---@return boolean success, string? reason
exports('removeItem', function(source, itemName, quantity)
    quantity = quantity or 1
    local identifier = getIdentifier(source)
    if not identifier then return false, 'no_identifier' end

    local row = DB:singleSync(
        'SELECT quantity FROM inventory WHERE identifier = ? AND item_name = ?',
        { identifier, itemName }
    )
    if not row or row.quantity < quantity then
        return false, 'not_enough'
    end

    if row.quantity == quantity then
        DB:execute(
            'DELETE FROM inventory WHERE identifier = ? AND item_name = ?',
            { identifier, itemName }
        )
    else
        DB:execute(
            'UPDATE inventory SET quantity = quantity - ? WHERE identifier = ? AND item_name = ?',
            { quantity, identifier, itemName }
        )
    end

    TriggerClientEvent('inventory:itemRemoved', source, itemName, quantity)
    return true
end)

---Get a player's full inventory.
---@param source number
---@return table items  Array of { item_name, label, quantity, weight }
exports('getInventory', function(source)
    local identifier = getIdentifier(source)
    if not identifier then return {} end

    local rows = DB:querySync(
        'SELECT item_name, quantity FROM inventory WHERE identifier = ?',
        { identifier }
    )
    local result = {}
    for _, row in ipairs(rows or {}) do
        local def = Items[row.item_name] or {}
        result[#result + 1] = {
            item_name = row.item_name,
            label     = def.label    or row.item_name,
            quantity  = row.quantity,
            weight    = (def.weight  or 0) * row.quantity,
        }
    end
    return result
end)

-- ── Network events ────────────────────────────────────────────────────────────

RegisterNetEvent('inventory:open', function()
    local source    = source
    local inventory = exports['inventory']:getInventory(source)
    TriggerClientEvent('inventory:display', source, inventory)
end)

RegisterNetEvent('inventory:useItem', function(itemName)
    local source     = source
    local identifier = getIdentifier(source)
    if not identifier then return end

    local def = Items[itemName]
    if not def or not def.usable then return end

    local ok = exports['inventory']:removeItem(source, itemName, 1)
    if ok then
        TriggerClientEvent('inventory:itemUsed', source, itemName)
        print(('[inventory] %s used %s'):format(identifier, itemName))
    end
end)

-- ── Commands ──────────────────────────────────────────────────────────────────

-- Admin: give item  /giveitem <playerId> <itemName> <qty>
RegisterCommand('giveitem', function(source, args)
    local targetId = tonumber(args[1])
    local itemName = args[2]
    local qty      = tonumber(args[3]) or 1

    if not targetId or not itemName then
        TriggerClientEvent('chat:addMessage', source, { args = { '[inventory]', 'Usage: /giveitem <id> <item> <qty>' } })
        return
    end

    local ok, reason = exports['inventory']:addItem(targetId, itemName, qty)
    local msg = ok
        and ('Donné %dx %s au joueur %d'):format(qty, itemName, targetId)
        or  ('Erreur: %s'):format(reason)
    TriggerClientEvent('chat:addMessage', source, { args = { '[inventory]', msg } })
end, true)
