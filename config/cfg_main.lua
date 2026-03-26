Config = {}

Config = {
    Locale = 'en', -- Currently supports: en, es, de, fr, uwu
    UseNUI = true, -- Set to false to use ox_lib notify instead
    ShowFailureNotify = false, -- Set to true to notify on failure (Would suggest leaving as false due to failure detection false firing sometimes...)
    Debug = false,    -- Visualizes the start and landing zones with spheres.
    JumpTimeout = 5000,    -- Maximum time allowed (in ms) to reach the landing zone after hitting a ramp.
    MinStartSpeed = 5.0,    -- Minimum speed (m/s) required to trigger a jump.
    AirborneThreshold = 0.2,  -- Lower values look better as it triggers earlier, but can falsely trigger on slight height adjustments... :c
    RequiredAirFrames = 3,     -- Number of consecutive frames in air before cam triggers
    MinZVelocity      = 3.5, -- If the car launches UP faster than this, trigger cam instantly (ignores frame delay)
    CooldownTime = 5000,     -- Time to wait (in ms) before a player can attempt another stunt jump.
    DisableHighRiskJumps = false, -- Disables jumps deemed as "high risk", Currently: Prison
    ShowNearbyBlips = true, -- Displays nearest stunt jump blip :p
    BlipShowDistance = 250, -- How far away you can see the blip

    Camera = {
        Enabled = true,         -- Toggle the cinematic stunt camera on or off.
        Fov = 50.0,         -- The field of view for the cinematic camera. Lower values = more zoom.
        BlendIn = 500,         -- How quickly (in ms) the camera transitions from the player to the stunt view.
        BlendOut = 1000,         -- How smoothly (in ms) the camera returns to the player after the jump ends.
    }
}

Config.StuntAdminCommand = {
    -- The command players type in chat
    name = 'stuntcreator', 
    -- Set to true to allow EVERYONE on the server to use this menu.
    -- Set to false to restrict it to the permissions listed below.
    everyone = false, 
    -- Set 'enabled' to true to restrict access based on QBCore ranks.
    groups = {
        enabled = true,
        allowed = {
            ['god'] = true,   -- Allow 'god' rank
            ['admin'] = true, -- Allow 'admin' rank
        }
    },
    -- Whitelisted jobs who can use stunt creator
    jobs = {
        enabled = false,
        allowed = {
            ['thrillmaker'] = 0,
        }
    },
    -- Set 'enabled' to true to use FiveM's built-in Ace system.
    -- Requires 'add_ace group.admin handling.use allow' in your server.cfg.
    ace = {
        enabled = false,
        permission = 'stuntadmin.use'
    },
    -- Set 'enabled' to true to allow specific players by their license.
    license = {
        enabled = false,
        allowed = {
            -- 'license:97645980c867e3b15f974677d6d803e26c986eca',
        }
    }
}


-- Ignore this, locale stuff..
Locales = {}

function _L(str, ...)
    local locale = Config.Locale
    if not Locales[locale] then return str end

    local text = Locales[locale][str]
    if not text then return str end

    local args = {...}
    if #args > 0 then
        return string.format(text, table.unpack(args))
    end

    return text 
end