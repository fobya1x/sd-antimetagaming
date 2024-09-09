Config = {
    GuildID = "", -- Your Discord Server ID
    DiscordBotToken = "", -- Your Discord Bot Token
    RequiredVoiceChannelID = "" -- The ID of the voice channel the player must be in
}

-- Function to get the player's Discord ID
function GetPlayerDiscordId(PlayerSource)
    local identifiers = GetPlayerIdentifiers(PlayerSource)
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "discord:") then
            return string.sub(identifier, 9) 
        end
    end
    return nil 
end

function IsPlayerInDiscordVoiceChannel(PlayerSource, callback)
    local discordId = GetPlayerDiscordId(PlayerSource)

    if discordId then
        local endpoint = string.format("https://discord.com/api/v9/guilds/%s/members/%s", Config.GuildID, discordId)
        
        local headers = {
            ["Authorization"] = "Bot " .. Config.DiscordBotToken,
            ["Content-Type"] = "application/json"
        }

        PerformHttpRequest(endpoint, function(statusCode, response, headers)
            if statusCode == 200 and response then
                local data = json.decode(response)
                
				print(data.channel_id)
                if data and data.voice_state and data.voice_state.channel_id == Config.RequiredVoiceChannelID then
                    print("Player is in the required voice channel.")
                    callback(true)
                else
                    print("Player is not in the required voice channel.")
                    callback(false)
                end
            else
                print("Failed to retrieve player information from Discord.")
                callback(false)
            end
        end, 'GET', "", headers)
    else
        print("Player does not have a linked Discord account.")
        callback(false) 
    end
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    IsPlayerInDiscordVoiceChannel(src, function(isInVoiceChannel)
        if isInVoiceChannel then
            deferrals.done()
        else
            deferrals.done("You must be in the required Discord voice channel to join!") -- Deny access
        end
    end)
end)
