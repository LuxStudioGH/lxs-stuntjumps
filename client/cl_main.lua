local activeJump = nil
local jumpCooldown = false
local wasAirborne = false
local jumpStartTime = 0
local insideLandingZone = false 
local maxJumpHeight = 0
local stuntCam = nil
local currentJumpData = nil
local isProcessingResult = false
local jumpLocations = {} 
local currentBlip = nil 

local function LoadJumps()
    local file = LoadResourceFile(GetCurrentResourceName(), 'jumps.json')
    if not file then return lib.print.error(_L('error_no_file')) end
    
    local data = json.decode(file)
    if not data then return lib.print.error(_L('error_malformed')) end

    local function setupZones(jumps)
        for _, jumpData in ipairs(jumps) do
            local jump = jumpData 
            local jumpId = jump.hash
            local startPos = ToVector3(jump.jumpPos.start)
            
            local shouldSkip = Config.DisableHighRiskJumps and jump.HighRisk
            if not shouldSkip then
                if Config.ShowNearbyBlips then
                    lib.zones.sphere({
                        coords = startPos,
                        radius = Config.BlipShowDistance or 100.0,
                        debug = Config.Debug,
                        onEnter = function(self)
                            if not self.blip then
                                self.blip = AddBlipForCoord(self.coords.x, self.coords.y, self.coords.z)
                                SetBlipSprite(self.blip, 515)
                                SetBlipScale(self.blip, 0.8)
                                SetBlipColour(self.blip, 5)
                                SetBlipAsShortRange(self.blip, true)
                                BeginTextCommandSetBlipName("STRING")
                                AddTextComponentString(_L('blip_name'))
                                EndTextCommandSetBlipName(self.blip)
                            end
                        end,
                        onExit = function(self)
                            if self.blip then
                                RemoveBlip(self.blip)
                                self.blip = nil
                            end
                        end
                    })
                end

                lib.zones.sphere({
                    coords = startPos,
                    radius = jump.jumpPos.radius or 5.0,
                    debug = Config.Debug, 
                    onEnter = function()
                        local ped = PlayerPedId()
                        local veh = GetVehiclePedIsIn(ped, false)
                        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and GetEntitySpeed(veh) > Config.MinStartSpeed then
                            activeJump = jumpId
                            currentJumpData = jump
                            wasAirborne = false
                            insideLandingZone = false
                            jumpStartTime = GetGameTimer() 
                            maxJumpHeight = GetEntityCoords(veh).z
                        end
                    end
                })

                local lStart = ToVector3(jump.landingPos.start)
                local lEnd = ToVector3(jump.landingPos['end'])
                local landingCenter = GetMidpoint(lStart, lEnd)

                lib.zones.sphere({
                    coords = landingCenter,
                    debug = Config.Debug, 
                    radius = jump.landingPos.radius or 10.0,
                    onEnter = function()
                        if activeJump == jumpId then insideLandingZone = true end
                    end,
                    onExit = function()
                        if activeJump == jumpId then insideLandingZone = false end
                    end,
                    inside = function() 
                        if activeJump == jumpId and not jumpCooldown then
                            local ped = PlayerPedId()
                            local veh = GetVehiclePedIsIn(ped, false)
                            if wasAirborne and veh ~= 0 and IsVehicleOnAllWheels(veh) and GetEntitySpeed(veh) > 2.0 then
                                local totalTime = (GetGameTimer() - jumpStartTime) / 1000
                                local heightGained = maxJumpHeight - startPos.z
                                CompleteJump(jumpId, totalTime, heightGained)
                            end
                        end
                    end
                })
            end
        end 
    end

    if data.angledStuntJumps then setupZones(data.angledStuntJumps) end
    if data.normalStuntJumps then setupZones(data.normalStuntJumps) end
end

function DestroyStuntCam()
    if stuntCam then
        RenderScriptCams(false, true, Config.Camera.BlendOut, true, true)
        DestroyCam(stuntCam, false)
        stuntCam = nil
    end
end

function CompleteJump(id, time, height)
    if not activeJump or isProcessingResult or not id then return end
    isProcessingResult = true

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local safeId = tostring(id)

    activeJump = nil
    jumpCooldown = true
    currentJumpData = nil
    wasAirborne = false
    insideLandingZone = false
    DestroyStuntCam()

    if vehicle == 0 then
        if Config.ShowFailureNotify then
            lib.notify({
                title = _L('jump_failed_title'),
                description = _L('error_not_in_veh'),
                type = 'error'
            })
        end
        TriggerServerEvent('lxs-lxs-stuntjumpssv:saveResult', safeId, time, height, false)
    else
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
        TriggerServerEvent('lxs-lxs-stuntjumpssv:saveResult', safeId, time, height, true)
        
        local timeStr = string.format("%.2f", time)
        local heightStr = string.format("%.2f", height)

        if Config.UseNUI then
            SendNUIMessage({
                action = "showSuccess",
                title = _L('jump_success_title'),
                labelTime = _L('input_jump_time'), 
                labelHeight = _L('input_jump_height'),
                time = timeStr,
                height = heightStr
            })
        else
            lib.notify({
                title = _L('jump_success_title'),
                description = string.format("%s: %ss | %s: %sm", 
                    _L('input_jump_time'), timeStr, 
                    _L('input_jump_height'), heightStr
                ),
                type = 'success'
            })
        end
    end

    SetTimeout(Config.CooldownTime, function() 
        jumpCooldown = false 
        isProcessingResult = false
    end)
end

local function FailJump(reason)
    if isProcessingResult then return end
    isProcessingResult = true
    
    activeJump = nil
    currentJumpData = nil
    wasAirborne = false
    insideLandingZone = false
    
    DestroyStuntCam()
    
    if Config.ShowFailureNotify then
    PlaySoundFrontend(-1, "Hack_Failed", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", 1)
    lib.notify({ 
        title = _L('jump_failed_title'), 
        description = reason, 
        type = 'error' 
       })
    end
    
    SetTimeout(1000, function()
        isProcessingResult = false
    end)
end

CreateThread(function()
    local airtimeFrames = 0 

    while true do
        local sleep = 1000
        
        if activeJump and not isProcessingResult then
            sleep = 0 
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local currentTime = GetGameTimer()

            if veh == 0 then
                airtimeFrames = 0 
                FailJump(_L('fail_left_vehicle'))
            elseif (currentTime - jumpStartTime) > Config.JumpTimeout then
                airtimeFrames = 0 
                FailJump(_L('fail_too_slow'))
            else
                local coords = GetEntityCoords(veh)
                local velocity = GetEntityVelocity(veh)
                
                if coords.z > maxJumpHeight then maxJumpHeight = coords.z end

                local isCurrentlyAirborne = IsEntityInAir(veh) and GetEntityHeightAboveGround(veh) > Config.AirborneThreshold

                if not wasAirborne then
                    if isCurrentlyAirborne then
                        airtimeFrames = airtimeFrames + 1
                        
                        if airtimeFrames >= Config.RequiredAirFrames or velocity.z > Config.MinZVelocity then
                            wasAirborne = true
                            
                            if Config.Camera.Enabled and currentJumpData and currentJumpData.camPos and not stuntCam then
                                local cPos = ToVector3(currentJumpData.camPos)
                                stuntCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                SetCamCoord(stuntCam, cPos.x, cPos.y, cPos.z)
                                SetCamFov(stuntCam, Config.Camera.Fov)
                                PointCamAtEntity(stuntCam, veh, 0, 0, 0, true)
                                RenderScriptCams(true, true, Config.Camera.BlendIn, true, true)
                            end
                        end
                    else
                        airtimeFrames = 0
                    end
                end

                if stuntCam then
                    PointCamAtEntity(stuntCam, veh, 0, 0, 0, true)
                end

                if wasAirborne and not insideLandingZone and IsVehicleOnAllWheels(veh) then
                    airtimeFrames = 0
                    FailJump(_L('fail_wrong_spot'))
                elseif wasAirborne and not IsVehicleOnAllWheels(veh) then
                    if GetEntitySpeed(veh) < 1.0 and GetEntityUprightValue(veh) < 0.5 then
                        airtimeFrames = 0
                        FailJump(_L('fail_crashed'))
                    end
                end
            end 
        else
            airtimeFrames = 0
        end 
        Wait(sleep)
    end
end)

CreateThread(function()
    LoadJumps()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if currentBlip then
            RemoveBlip(currentBlip)
        end
    end
end)