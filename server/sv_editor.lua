local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function GenerateHash(length)
    local res = ""
    for i = 1, length do
        local rand = math.random(1, #charset)
        res = res .. string.sub(charset, rand, rand)
    end
    return res
end

lib.callback.register('stunts:server:getJumps', function(source)
    local resourceName = GetCurrentResourceName()
    local file = LoadResourceFile(resourceName, 'jumps.json')
    if not file then 
        return {angledStuntJumps = {}, normalStuntJumps = {}} 
    end
    return json.decode(file) or {angledStuntJumps = {}, normalStuntJumps = {}}
end)

RegisterNetEvent('stunts:server:SaveJump', function(jumpType, jumpData, isUpdate)
    local src = source
    local resourceName = GetCurrentResourceName()
    local file = LoadResourceFile(resourceName, 'jumps.json')
    local data = file and json.decode(file) or {angledStuntJumps = {}, normalStuntJumps = {}}

    if isUpdate then
        local found = false
        for i, jump in ipairs(data[jumpType]) do
            if jump.hash == jumpData.hash then
                data[jumpType][i] = jumpData
                found = true
                break
            end
        end
        if not found then 
            return lib.print.error(string.format("Update failed: Hash '%s' not found", tostring(jumpData.hash))) 
        end
    else
        jumpData.hash = GenerateHash(8)
        if not data[jumpType] then data[jumpType] = {} end
        table.insert(data[jumpType], jumpData)
    end

    local saved = SaveResourceFile(resourceName, 'jumps.json', json.encode(data, {indent = true}), -1)
    if saved then
        local logMsg = isUpdate and "updated" or "created"
        lib.print.info(('Jump [%s] %s by ID %s'):format(jumpData.hash, logMsg, src))

    end
end)

RegisterNetEvent('stunts:server:DeleteJump', function(jumpType, jumpHash)
    local src = source
    local resourceName = GetCurrentResourceName()
    local file = LoadResourceFile(resourceName, 'jumps.json')
    if not file then return end
    
    local data = json.decode(file)
    if not data[jumpType] then return end

    local found = false
    for i, jump in ipairs(data[jumpType]) do
        if jump.hash == jumpHash then
            table.remove(data[jumpType], i)
            found = true
            break
        end
    end

    if found then
        SaveResourceFile(resourceName, 'jumps.json', json.encode(data, {indent = true}), -1)
        lib.print.warn(('Jump [%s] was deleted by ID %s'):format(jumpHash, src))
    end
end)