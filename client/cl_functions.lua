function DebugLog(msg, type)
    if not Config.Debug then return end
    if type == 'error' then lib.print.error(msg)
    elseif type == 'warn' then lib.print.warn(msg)
    else lib.print.info(msg) end
end


function ToVector3(data)
    if not data then return vector3(0, 0, 0) end
    if type(data) == 'vector3' then return data end
    if type(data) == "string" then
        local x, y, z = data:match("vector3%s*%(%s*(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)%s*%)")
        if x and y and z then
            return vector3(tonumber(x), tonumber(y), tonumber(z))
        end
    elseif type(data) == "table" then
        return vector3(data.x or data.X or 0.0, data.y or data.Y or 0.0, data.z or data.Z or 0.0)
    end
    return vector3(0, 0, 0)
end

function GetMidpoint(v1, v2)
    local offset = v2 - v1    
    return v1 + (offset / 2)   
end