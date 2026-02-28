-- ==============================================================================
-- chat/server/main.lua
-- Server-side chat handling — broadcasts messages, handles chat commands
-- ==============================================================================

-- ── Helpers ───────────────────────────────────────────────────────────────────

---Broadcast a styled chat message to all players.
---@param template table  { color, prefix, msg }
local function broadcast(template)
    TriggerClientEvent('chat:addMessage', -1, template)
end

---Send a message only to one player.
---@param target number
---@param template table
local function sendTo(target, template)
    TriggerClientEvent('chat:addMessage', target, template)
end

-- ── Chat message relay ────────────────────────────────────────────────────────

RegisterNetEvent('chat:messageEntered', function(author, color, message)
    local source = source
    -- Sanitise input — strip leading/trailing whitespace, limit length
    message = tostring(message):match('^%s*(.-)%s*$')
    if #message == 0 or #message > 300 then return end

    print(('[chat] %s: %s'):format(author, message))
    broadcast({
        color = color or { 255, 255, 255 },
        multiline = true,
        args = { author, message },
    })
end)

-- ── Commands ──────────────────────────────────────────────────────────────────

-- /me <action>  — describe a roleplay action
RegisterCommand('me', function(source, args)
    if source == 0 then return end
    local action = table.concat(args, ' '):match('^%s*(.-)%s*$')
    if action == '' then return end
    local name = GetPlayerName(source) or 'Inconnu'
    broadcast({
        color = { 180, 80, 220 },
        multiline = true,
        args = { '* ' .. name, action },
    })
end, false)

-- /ooc <message>  — out-of-character global chat
RegisterCommand('ooc', function(source, args)
    if source == 0 then return end
    local msg = table.concat(args, ' '):match('^%s*(.-)%s*$')
    if msg == '' then return end
    local name = GetPlayerName(source) or 'Inconnu'
    broadcast({
        color = { 100, 200, 255 },
        multiline = true,
        args = { '[HRP] ' .. name, msg },
    })
end, false)

-- /help  — show available commands
RegisterCommand('help', function(source)
    if source == 0 then
        print('Commandes chat disponibles: /me /ooc /help')
        return
    end
    local cmds = {
        '/me <action>   — Action RP visible par tous',
        '/ooc <message> — Message hors-RP [HRP]',
        '/help          — Cette aide',
    }
    for _, line in ipairs(cmds) do
        sendTo(source, { color = { 255, 220, 50 }, args = { '[Aide]', line } })
    end
end, false)
