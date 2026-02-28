-- ==============================================================================
-- hardcap/server/main.lua
-- Kick connecting players when the server is already full
-- ==============================================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local maxClients = GetConvarInt('sv_maxclients', 32)
    -- GetNumPlayerIndices counts current connected players
    local current = #GetPlayers()

    if current >= maxClients then
        deferrals.defer()
        deferrals.done(('Le serveur est complet (%d/%d joueurs). Réessayez plus tard.'):format(current, maxClients))
    end
end)
