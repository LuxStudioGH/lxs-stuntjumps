local function DrawEditorVisuals(points, currentStep, radius, drawCoords)
    local r, g, b = 255, 255, 255 
    if currentStep:find('sP') or currentStep:find('sE') then r, g, b = 0, 255, 0   
    elseif currentStep:find('lP') or currentStep:find('lE') then r, g, b = 255, 0, 0 
    elseif currentStep == 'cPos' then r, g, b = 0, 0, 255 end

    local pulse = (math.sin(GetGameTimer() * 0.005) * 0.1)
    DrawMarker(28, drawCoords.x, drawCoords.y, drawCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius + pulse, radius + pulse, radius + pulse, r, g, b, 100, false, false, 2, nil, nil, true)

    if points.sPos and currentStep == 'sEnd' then
        DrawLine(points.sPos.x, points.sPos.y, points.sPos.z, drawCoords.x, drawCoords.y, drawCoords.z, 0, 255, 0, 255)
    elseif points.lPos and currentStep == 'lEnd' then
        DrawLine(points.lPos.x, points.lPos.y, points.lPos.z, drawCoords.x, drawCoords.y, drawCoords.z, 255, 0, 0, 255)
    end
end

local function ToggleFreecam(state, startPos, cam)
    if state then
        local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(newCam, startPos.x, startPos.y, startPos.z)
        SetCamRot(newCam, 0.0, 0.0, GetEntityHeading(PlayerPedId()), 2)
        SetCamActive(newCam, true)
        RenderScriptCams(true, true, 500, true, true)
        FreezeEntityPosition(PlayerPedId(), true)
        SetEntityVisible(PlayerPedId(), false, false)
        SetEntityCollision(PlayerPedId(), false, false)
        return newCam
    else
        RenderScriptCams(false, true, 500, true, true)
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, false)
        SetEntityCollision(PlayerPedId(), true, true)
        if cam then DestroyCam(cam, false) end
        if startPos then SetEntityCoords(PlayerPedId(), startPos.x, startPos.y, startPos.z) end
        return nil
    end
end

local function CaptureJumpPoints(currentType, sRad, lRad)
    local steps = {
        {label = _L('editor_step_start'), key = 'sPos', rad = sRad},
        {label = _L('editor_step_land_area'), key = 'sEnd', rad = sRad},
        {label = _L('editor_step_target'), key = 'lPos', rad = lRad},
        {label = _L('editor_step_boundary'), key = 'lEnd', rad = lRad},
        {label = _L('editor_step_cam'), key = 'cPos', rad = 1.0},
    }
    
    local points = {}
    local originalCoords = GetEntityCoords(PlayerPedId())
    local isFreecam = true
    local cam = ToggleFreecam(true, originalCoords)
    local currentPos = originalCoords
    local speed = 0.5
    local controlsStr = _L('editor_controls')

    for _, step in ipairs(steps) do
        lib.notify({title = _L('editor_title'), description = _L('editor_move_to', step.label), type = 'inform'})
        
        while true do
            local dt = GetFrameTime()
            Wait(0)
            
            if not lib.isTextUIOpen() then lib.showTextUI(controlsStr, {position = "right-center"}) end

            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 31, true)
            EnableControlAction(0, 30, true)
            EnableControlAction(0, 249, true)

            if IsDisabledControlJustPressed(0, 47) then -- G Key
                isFreecam = not isFreecam
                if isFreecam then
                    cam = ToggleFreecam(true, GetEntityCoords(PlayerPedId()))
                else
                    currentPos = GetCamCoord(cam)
                    SetEntityCoords(PlayerPedId(), currentPos.x, currentPos.y, currentPos.z)
                    ToggleFreecam(false, nil, cam)
                    cam = nil
                end
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
            end

            local moveMultiplier = speed * (dt * 100.0)
            if IsDisabledControlPressed(0, 19) then moveMultiplier = moveMultiplier * 0.2 end

            if isFreecam and cam then
                local camRot = GetCamRot(cam, 2)
                local right, forward, up, _ = GetCamMatrix(cam)

                if IsDisabledControlPressed(0, 32) then currentPos = currentPos + (forward * moveMultiplier) end
                if IsDisabledControlPressed(0, 33) then currentPos = currentPos - (forward * moveMultiplier) end
                if IsDisabledControlPressed(0, 34) then currentPos = currentPos - (right * moveMultiplier) end
                if IsDisabledControlPressed(0, 35) then currentPos = currentPos + (right * moveMultiplier) end
                if IsDisabledControlPressed(0, 21) then currentPos = currentPos + (up * moveMultiplier) end
                if IsDisabledControlPressed(0, 36) then currentPos = currentPos - (up * moveMultiplier) end

                local mouseX = GetDisabledControlNormal(0, 1) * -4.0
                local mouseY = GetDisabledControlNormal(0, 2) * -4.0
                SetCamRot(cam, camRot.x + mouseY, 0.0, camRot.z + mouseX, 2)
                SetCamCoord(cam, currentPos.x, currentPos.y, currentPos.z)
                SetEntityCoordsNoOffset(PlayerPedId(), currentPos.x, currentPos.y, currentPos.z, false, false, false)
            else
                currentPos = GetEntityCoords(PlayerPedId())
            end

            DrawEditorVisuals(points, step.key, step.rad, currentPos)

            if IsDisabledControlJustPressed(0, 15) then speed = math.min(speed + 0.1, 10.0) end
            if IsDisabledControlJustPressed(0, 14) then speed = math.max(speed - 0.1, 0.01) end

            if IsDisabledControlJustPressed(0, 38) then 
                points[step.key] = currentPos
                PlaySoundFrontend(-1, "WEAPON_PURCHASE", "HUD_AMMO_SHOP_SOUNDSET", 1)
                break
            end
            
            if IsDisabledControlJustPressed(0, 322) then 
                if cam then ToggleFreecam(false, originalCoords, cam) end
                SetEntityCoords(PlayerPedId(), originalCoords.x, originalCoords.y, originalCoords.z)
                lib.hideTextUI()
                return nil 
            end
        end
        Wait(200)
    end

    if cam then ToggleFreecam(false, originalCoords, cam) 
    else SetEntityCoords(PlayerPedId(), originalCoords.x, originalCoords.y, originalCoords.z) end
    lib.hideTextUI()

    return {
        jumpPos = {
            start = ("vector3(%.2f, %.2f, %.2f)"):format(points.sPos.x, points.sPos.y, points.sPos.z),
            ['end'] = ("vector3(%.2f, %.2f, %.2f)"):format(points.sEnd.x, points.sEnd.y, points.sEnd.z),
            radius = sRad
        },
        landingPos = {
            start = ("vector3(%.2f, %.2f, %.2f)"):format(points.lPos.x, points.lPos.y, points.lPos.z),
            ['end'] = ("vector3(%.2f, %.2f, %.2f)"):format(points.lEnd.x, points.lEnd.y, points.lEnd.z),
            radius = lRad
        },
        camPos = ("vector3(%.2f, %.2f, %.2f)"):format(points.cPos.x, points.cPos.y, points.cPos.z)
    }
end

local function OpenJumpActions(jType, jump)
    local sRad = (jump.jumpPos and jump.jumpPos.radius) or 5.0
    local lRad = (jump.landingPos and jump.landingPos.radius) or 15.0
    local startCoords = ToVector3(jump.jumpPos.start)
    local landCoords = ToVector3(jump.landingPos.start)
    local threadActive = true

    CreateThread(function()
        while threadActive do
            Wait(0)
            DrawMarker(28, startCoords.x, startCoords.y, startCoords.z, 0,0,0,0,0,0, sRad+0.0, sRad+0.0, sRad+0.0, 0, 255, 0, 60, false, false, 2, nil, nil, true)
            DrawMarker(28, landCoords.x, landCoords.y, landCoords.z, 0,0,0,0,0,0, lRad+0.0, lRad+0.0, lRad+0.0, 255, 0, 0, 60, false, false, 2, nil, nil, true)
        end
    end)

    lib.registerContext({
        id = 'stunt_action_menu',
        title = _L('menu_jump_title', (jump.hash or _L('unknown'))),
        onExit = function() threadActive = false end,
        menu = 'stunt_manage_menu',
        options = {
            {
                title = _L('menu_tp_start'),
                icon = 'location-dot',
                onSelect = function() SetEntityCoords(PlayerPedId(), startCoords.x, startCoords.y, startCoords.z) end
            },
            {
                title = _L('menu_redo_coords'),
                description = _L('menu_redo_coords_desc'),
                icon = 'arrows-rotate',
                onSelect = function()
                    threadActive = false
                    local newData = CaptureJumpPoints(jType, sRad, lRad)
                    if newData then
                        newData.hash = jump.hash
                        TriggerServerEvent('stunts:server:SaveJump', jType, newData, true)
                        lib.notify({title = _L('editor_title'), description = _L('notify_jump_updated'), type = 'warning'})
                    end
                end
            },
            {
                title = _L('menu_delete_jump'),
                icon = 'trash',
                iconColor = '#ff4d4d',
                onSelect = function()
                    threadActive = false
                    local alert = lib.alertDialog({header = _L('confirm_delete_title'), content = _L('confirm_delete_desc'), cancel = true})
                    if alert == 'confirm' then 
                        TriggerServerEvent('stunts:server:DeleteJump', jType, jump.hash) 
                        lib.notify({title = _L('editor_title'), description = _L('notify_jump_deleted'), type = 'error'})
                    end
                end
            }
        }
    })
    lib.showContext('stunt_action_menu')
end

local function OpenNearestJump()
    local data = lib.callback.await('stunts:server:getJumps', false)
    local pCoords = GetEntityCoords(PlayerPedId())
    local nearest, dist, nType = nil, 99999.0, nil
    for _, jType in ipairs({'normalStuntJumps', 'angledStuntJumps'}) do
        if data[jType] then
            for _, jump in ipairs(data[jType]) do
                local jCoords = ToVector3(jump.jumpPos.start)
                local d = #(pCoords - jCoords)
                if d < dist then dist = d nearest = jump nType = jType end
            end
        end
    end
    if nearest then OpenJumpActions(nType, nearest) else lib.notify({description = _L('notify_no_jumps'), type = 'error'}) end
end

RegisterCommand(Config.StuntAdminCommand.name, function()
    local isAllowed = lib.callback.await('lxs-stuntjumpscheckPerms', false)
    if not isAllowed then
        lib.notify({title = _L('editor_title'), description = _L('notify_no_perms'), type = 'error'})
        return
    end

    lib.registerContext({
        id = 'stunt_editor_main',
        title = _L('editor_main_title'),
        options = {
            { 
                title = _L('menu_nearest_jump'), 
                description = _L('menu_nearest_jump_desc'), 
                icon = 'magnifying-glass-location', 
                onSelect = OpenNearestJump 
            },
            { 
                title = _L('menu_create_jump'), 
                description = _L('menu_create_jump_desc'),
                icon = 'plus', 
                onSelect = function()
                    local input = lib.inputDialog(_L('input_jump_settings'), {
                        {type='select', label=_L('input_type'), options={
                            {value='normalStuntJumps', label=_L('type_normal')},
                            {value='angledStuntJumps', label=_L('type_angled')}
                        }}, 
                        {type='number', label=_L('input_start_rad'), default=5}, 
                        {type='number', label=_L('input_land_rad'), default=25}
                    })
                    if not input then return end
                    local data = CaptureJumpPoints(input[1], input[2], input[3])
                    if data then 
                        TriggerServerEvent('stunts:server:SaveJump', input[1], data, false) 
                        lib.notify({title = _L('editor_title'), description = _L('notify_jump_created'), type = 'success'})
                    end
                end 
            },
            { 
                title = _L('menu_browse_all'), 
                icon = 'list', 
                onSelect = function()
                    local data = lib.callback.await('stunts:server:getJumps', false)
                    local options = {}
                    for _, t in ipairs({'normalStuntJumps', 'angledStuntJumps'}) do
                        if data[t] then
                            for _, j in ipairs(data[t]) do
                                table.insert(options, { 
                                    title = (j.hash or _L('no_hash')), 
                                    description = t:gsub('StuntJumps', ''), 
                                    onSelect = function() OpenJumpActions(t, j) end 
                                })
                            end
                        end
                    end
                    lib.registerContext({
                        id='stunt_manage_menu', 
                        title=_L('menu_all_jumps'), 
                        menu='stunt_editor_main', 
                        options=options
                    })
                    lib.showContext('stunt_manage_menu')
                end 
            }
        }
    })
    lib.showContext('stunt_editor_main')
end, false)