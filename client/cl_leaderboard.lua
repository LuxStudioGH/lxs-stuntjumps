local function GetJumpData()
    return lib.callback.await('stunts:server:getJumps', false)
end

RegisterNetEvent('lxs-lxs-stuntjumpscl:openLeaderboard', function()
    local data = GetJumpData()
    if not data then 
        return lib.notify({ title = _L('error_title'), description = _L('error_no_data'), type = 'error' })
    end

    local pCoords = GetEntityCoords(PlayerPedId())
    local nearestJump = nil
    local shortestDist = 25.0
    
    for _, jType in ipairs({'normalStuntJumps', 'angledStuntJumps'}) do
        if data[jType] then
            for _, jump in ipairs(data[jType]) do
                local jumpPos = ToVector3(jump.jumpPos.start)
                local dist = #(pCoords - jumpPos)
                if dist < shortestDist then
                    shortestDist = dist
                    nearestJump = jump
                end
            end
        end
    end

    if not nearestJump then 
        return lib.notify({ title = _L('leaderboard_title'), description = _L('error_no_jump_near'), type = 'error' })
    end

    local options = {}
    local jumpId = nearestJump.hash 
    local stats = lib.callback.await('lxs-stuntjumpsgetLeaderboard', false, jumpId)

    if stats and #stats > 0 then
        for i, row in ipairs(stats) do
           local name = _L('unknown')
            if row.fname and row.lname then
                name = row.fname .. " " .. row.lname
            end
            
            local rankEmoji = "🏁"
            if i == 1 then rankEmoji = "🥇" 
            elseif i == 2 then rankEmoji = "🥈" 
            elseif i == 3 then rankEmoji = "🥉" end

            table.insert(options, {
                title = ('%s %s'):format(rankEmoji, name),
                description = _L('leaderboard_stat_row'):format(row.best_time, row.best_height),
                readOnly = true,
            })
        end
    else
        table.insert(options, { 
            title = _L('no_records_title'), 
            description = _L('no_records_desc'), 
            disabled = true 
        })
    end

   lib.registerContext({
        id = 'jump_leaderboard',
        title = _L('leaderboard_header'),
        options = options
    })
    lib.showContext('jump_leaderboard')
end)