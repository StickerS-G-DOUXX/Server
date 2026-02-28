-- ==============================================================================
-- basicneeds/client/main.lua
-- Hunger / thirst HUD — uses native GTA progress bars
-- ==============================================================================

local hunger = 100
local thirst = 100

local WARN_THRESHOLD = 20  -- warn player when below this value

-- ── Receive sync from server ──────────────────────────────────────────────────

RegisterNetEvent('basicneeds:sync', function(h, t)
    hunger = h
    thirst = t
end)

-- ── Drain event from server ───────────────────────────────────────────────────

RegisterNetEvent('basicneeds:drain', function(amount)
    hunger = math.max(0, hunger - amount)
    thirst = math.max(0, thirst - amount)

    -- Save to server
    TriggerServerEvent('basicneeds:save', hunger, thirst)

    -- Warnings
    if hunger <= WARN_THRESHOLD then
        TriggerEvent('chat:addMessage', { color = { 255, 80, 0 },
            args = { '[Besoins]', ('Vous avez faim ! Faim: %d%%'):format(hunger) } })
    end
    if thirst <= WARN_THRESHOLD then
        TriggerEvent('chat:addMessage', { color = { 0, 150, 255 },
            args = { '[Besoins]', ('Vous avez soif ! Soif: %d%%'):format(thirst) } })
    end

    -- Apply GTA effects at very low levels
    if hunger <= 0 then
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
    end
end)

-- ── HUD draw loop ─────────────────────────────────────────────────────────────

local HUD_X      = 0.02
local HUD_Y_FOOD = 0.92
local HUD_Y_WATER = 0.94
local BAR_W      = 0.10
local BAR_H      = 0.015

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- Background tracks
        DrawRect(HUD_X, HUD_Y_FOOD,  BAR_W, BAR_H, 60, 60, 60, 180)
        DrawRect(HUD_X, HUD_Y_WATER, BAR_W, BAR_H, 60, 60, 60, 180)

        -- Hunger bar (red) — width shrinks as hunger decreases
        local foodW = hunger / 100 * BAR_W
        DrawRect(HUD_X - (BAR_W - foodW) / 2, HUD_Y_FOOD,  foodW, BAR_H, 220, 60,  60,  220)

        -- Thirst bar (blue)
        local waterW = thirst / 100 * BAR_W
        DrawRect(HUD_X - (BAR_W - waterW) / 2, HUD_Y_WATER, waterW, BAR_H, 60, 100, 220, 220)
    end
end)

-- ── On resource start, request our needs from server ─────────────────────────

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('basicneeds:requestLoad')
    end
end)
