Config = {
    GuildID = "", -- Your Discord Server ID
    DiscordBotToken = "", -- Your Discord Bot Token
    RequiredVoiceChannelID = "" -- The ID of the voice channel the player must be in
}


function GetPlayerDiscordId(PlayerSource)
    for _, identifier in ipairs(GetPlayerIdentifiers(PlayerSource)) do
        if string.find(identifier, "discord:") then
            return string.sub(identifier, 9)
        end
    end
    return nil
end

function IsPlayerInDiscordVoiceChannel(PlayerSource, callback)
    local discordId = GetPlayerDiscordId(PlayerSource)
    if not discordId then return callback(false) end

    local endpoint = string.format("https://discord.com/api/v9/guilds/%s/voice-states/%s", Config.GuildID, discordId)
    local headers = {
        ["Authorization"] = "Bot " .. Config.DiscordBotToken,
        ["Content-Type"] = "application/json"
    }

    PerformHttpRequest(endpoint, function(statusCode, response)
        if statusCode == 200 and response then
            local data = json.decode(response)
            callback(data.channel_id and data.channel_id == Config.RequiredVoiceChannelID)
        else
            callback(false)
        end
    end, 'GET', "", headers)
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(1)
    deferrals.update('Checking If The Player In Voice Channel ...')

    IsPlayerInDiscordVoiceChannel(src, function(isInVoiceChannel)
        if isInVoiceChannel then
            deferrals.done() 
        else
            deferrals.done('Join The Voice Channel') 
        end
    end)
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3 * 60000) 


        for _, playerId in ipairs(GetPlayers()) do
            local discordId = GetPlayerDiscordId(playerId)
            if discordId then
                IsPlayerInDiscordVoiceChannel(playerId, function(isInVoiceChannel)
                    if not isInVoiceChannel then
                        DropPlayer(playerId, 'Join The Voice Channel')
                    end
                end)
            end
        end

    end
end)
