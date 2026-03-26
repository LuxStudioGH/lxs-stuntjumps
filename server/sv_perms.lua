local QBCore = exports['qb-core']:GetCoreObject()

local function hasLicense(source)
    local cfg = Config.StuntAdminCommand.license
    if not cfg.enabled then return false end 

    local identifiers = GetPlayerIdentifiers(source)
    local allowedList = cfg.allowed

    for _, id in ipairs(identifiers) do
        for _, allowed in ipairs(allowedList) do
            if id == allowed or string.find(id, allowed) then
                return true
            end
        end
    end

    lib.print.warn(("License check failed for ID %s"):format(source))
    return false
end

local function hasAce(source)
    local cfg = Config.StuntAdminCommand.ace
    if not cfg.enabled then return false end
    
    local allowed = IsAceAllowed(source, cfg.permission)
    if not allowed then
        lib.print.warn(("Ace permission '%s' denied for ID %s"):format(cfg.permission, source))
    end
    return allowed
end

local function hasGroup(source)
    local cfg = Config.StuntAdminCommand.groups
    if not cfg.enabled then return false end

    if QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            for group, allowed in pairs(cfg.allowed) do
                if allowed and QBCore.Functions.HasPermission(source, group) then
                    return true
                end
            end
        end
    end

    for group, allowed in pairs(cfg.allowed) do
        if allowed and IsAceAllowed(source, ('group.%s'):format(group)) then
            return true
        end
    end

    lib.print.warn(("Group/Rank check failed for ID %s"):format(source))
    return false
end

local function hasJob(source)
    local cfg = Config.StuntAdminCommand.jobs
    if not cfg.enabled then return false end

    if QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local jobName = Player.PlayerData.job.name
            local jobGrade = Player.PlayerData.job.grade.level
            if cfg.allowed[jobName] and jobGrade >= cfg.allowed[jobName] then
                return true
            end
        end
    end
        
    lib.print.warn(("Job whitelist check failed for ID %s"):format(source))
    return false
end

local function canUse(source)
    local cfg = Config.StuntAdminCommand
    
    if cfg.everyone then 
        return true 
    end

    if not cfg.ace.enabled and 
       not cfg.license.enabled and 
       not cfg.jobs.enabled and 
       not cfg.groups.enabled then 
        lib.print.error("All permission methods are disabled in config! Access denied by default.")
        return false 
    end

    if hasAce(source) then return true end
    if hasLicense(source) then return true end
    if hasGroup(source) then return true end
    if hasJob(source) then return true end

    lib.print.warn(("Final access DENIED for ID %s"):format(source))
    return false
end

lib.callback.register('lxs-stuntjumpscheckPerms', function(source)
    local allowed = canUse(source)
    return allowed
end)