-- ==============================================================================
-- chat/client/main.lua
-- Client-side chat — forwards player messages to the server
-- ==============================================================================

-- Listen for the native FiveM chatMessage event (fired when a player submits
-- something in the default chat box) and relay it to the server handler.
AddEventHandler('chatMessage', function(author, color, message)
    -- Prevent the default local display — our server will broadcast
    CancelEvent()
    TriggerServerEvent('chat:messageEntered', author, color, message)
end)
