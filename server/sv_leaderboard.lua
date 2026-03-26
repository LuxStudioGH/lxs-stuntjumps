local QBCore = exports['qb-core']:GetCoreObject()

local function DebugLog(msg, type)
    if not Config.Debug then return end
    if type == "error" then 
        lib.print.error(msg)
    elseif type == "warn" then 
        lib.print.warn(msg)
    else 
        print(msg) 
    end
end

local function InitializeDatabase()
    if not MySQL then return end
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `stunt_jumps` (
            `jump_id` VARCHAR(100) NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `first_done` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `best_time` FLOAT DEFAULT 999.99,
            `best_height` FLOAT DEFAULT 0.0,
            PRIMARY KEY (`jump_id`, `citizenid`)
        )
    ]], {}, function(success)
        if success then lib.print.info('Database initialized.') end
    end)
end

MySQL.ready(InitializeDatabase)

local function SaveJumpResult(source, jumpId, time, height, success)
    DebugLog(("[DEBUG] SaveJumpResult called | Source: %s | Jump: %s | Success: %s"):format(source, jumpId, tostring(success)))
    
    if not MySQL or not jumpId then 
        DebugLog("[DEBUG] SaveJumpResult failed: MySQL or jumpId missing", "error")
        return 
    end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        DebugLog("[DEBUG] SaveJumpResult failed: Player not found for source " .. tostring(source), "error")
        return 
    end

    local citizenid = Player.PlayerData.citizenid
    local safeId = tostring(jumpId)

    MySQL.scalar('SELECT COUNT(*) FROM stunt_jumps WHERE jump_id = ? AND citizenid = ?', {safeId, citizenid}, function(exists)
        local isFirstTime = (tonumber(exists) == 0)
        DebugLog(("[DEBUG] Database Check -> Exists: %s | isFirstTime: %s"):format(exists, tostring(isFirstTime)))

        local query = [[
            INSERT INTO stunt_jumps (jump_id, citizenid, best_time, best_height) 
            VALUES (?, ?, ?, ?) 
            ON DUPLICATE KEY UPDATE 
                best_time = LEAST(best_time, VALUES(best_time)),
                best_height = GREATEST(best_height, VALUES(best_height))
        ]]

        MySQL.update(query, {safeId, citizenid, time, height}, function(affectedRows)
            if affectedRows ~= nil then 
                DebugLog("[DEBUG] DB Query Executed. Rows affected: " .. tostring(affectedRows))
                DebugLog(("[DEBUG] Reward Check -> FirstTime: %s | SuccessArg: %s | ConfigEnabled: %s"):format(tostring(isFirstTime), tostring(success), tostring(Config.RewardsEnabled)))
                
                if isFirstTime and success and Config.RewardsEnabled then
                    DebugLog("[DEBUG] CONDITIONS MET - CALLING REWARD FUNCTION", "warn")
                    GiveStuntReward(source)
                else
                    if not isFirstTime then
                        DebugLog("[DEBUG] REWARD BLOCKED: You have already completed this jump before.", "error")
                    elseif not success then
                        DebugLog("[DEBUG] REWARD BLOCKED: The client sent 'success = false'.", "error")
                    elseif not Config.RewardsEnabled then
                        DebugLog("[DEBUG] REWARD BLOCKED: Config.RewardsEnabled is false.", "error")
                    end
                end
            else
                DebugLog("[DEBUG] Database query totally failed (Nil result). Check SQL syntax.", "error")
            end
        end)
    end)
end

exports('SaveJumpResult', SaveJumpResult)

lib.callback.register('lxs-stuntjumpsgetLeaderboard', function(source, jumpId)
    DebugLog("[DEBUG] Leaderboard callback requested for jump: " .. tostring(jumpId))
    if not jumpId then return nil end
    return MySQL.query.await([[
        SELECT s.best_time, s.best_height, s.first_done, 
               JSON_VALUE(p.charinfo, '$.firstname') as fname, 
               JSON_VALUE(p.charinfo, '$.lastname') as lname
        FROM stunt_jumps s
        LEFT JOIN players p ON s.citizenid = p.citizenid
        WHERE s.jump_id = ? 
        ORDER BY s.best_time ASC 
        LIMIT 10
    ]], {tostring(jumpId)})
end)

lib.addCommand('stuntleaderboard', {
    help = 'Displays nearest stunt jump leaderboard',
    restricted = false
}, function(source)
    DebugLog("[DEBUG] Command /stuntleaderboard used by " .. source)
    TriggerClientEvent('lxs-lxs-stuntjumpscl:openLeaderboard', source)
end)

RegisterNetEvent('lxs-lxs-stuntjumpssv:saveResult', function(jumpId, time, height, isSuccess)
    local src = source
    DebugLog(("[DEBUG] NetEvent 'saveResult' received | Jump: %s | Time: %s | Success: %s"):format(tostring(jumpId), tostring(time), tostring(isSuccess)))
    
    if not jumpId then 
        DebugLog("[DEBUG] NetEvent failed: jumpId is nil", "error")
        return 
    end
    
    local wasSuccessful = (isSuccess == true or isSuccess == 1)
    DebugLog("[DEBUG] Passing to SaveJumpResult function...")
    SaveJumpResult(src, jumpId, time, height, wasSuccessful)
end)