-- ==============================================================================
-- inventory/client/main.lua
-- Client-side inventory UI (minimal — extend with NUI as needed)
-- ==============================================================================

local isOpen = false

-- ── Keybind — open inventory (default: TAB) ───────────────────────────────────
RegisterCommand('openinventory', function()
    if not isOpen then
        TriggerServerEvent('inventory:open')
    end
end, false)
RegisterKeyMapping('openinventory', 'Ouvrir l\'inventaire', 'keyboard', 'F2')

-- ── Receive inventory data from server ────────────────────────────────────────
RegisterNetEvent('inventory:display', function(items)
    isOpen = true
    -- Basic chat display (replace with NUI for a proper UI)
    TriggerEvent('chat:addMessage', { args = { '[Inventaire]', '────────────────────────' } })
    if #items == 0 then
        TriggerEvent('chat:addMessage', { args = { '[Inventaire]', 'Votre inventaire est vide.' } })
    else
        for _, item in ipairs(items) do
            TriggerEvent('chat:addMessage', {
                args = { '[Inventaire]', ('%s × %d  (%.1f kg)'):format(item.label, item.quantity, item.weight / 1000) },
            })
        end
    end
    TriggerEvent('chat:addMessage', { args = { '[Inventaire]', '────────────────────────' } })
    isOpen = false
end)

-- ── Feedback events ───────────────────────────────────────────────────────────
RegisterNetEvent('inventory:itemAdded', function(itemName, qty)
    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 100 },
        args  = { '[Inventaire]', ('+%d × %s'):format(qty, itemName) },
    })
end)

RegisterNetEvent('inventory:itemRemoved', function(itemName, qty)
    TriggerEvent('chat:addMessage', {
        color = { 255, 100, 0 },
        args  = { '[Inventaire]', ('-%d × %s'):format(qty, itemName) },
    })
end)

RegisterNetEvent('inventory:itemUsed', function(itemName)
    TriggerEvent('chat:addMessage', {
        color = { 100, 200, 255 },
        args  = { '[Inventaire]', ('Vous avez utilisé : %s'):format(itemName) },
    })
end)
