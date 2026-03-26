Config.RewardsEnabled = true -- Enable rewards, given once per stunt location
Config.RewardDriverXp = false -- Supports: brutal_gym 
Config.RewardXpCount = 15 -- Amount of XP to give

Config.RewardPool = {
    -- This item will ALWAYS be given if GuaranteedReward is true
    { item = "money", min = 1000, max = 2500, type = "currency", chance = 0, GuaranteedReward = true },
    -- These are rolled based on chance
    { item = "advancedrepairkit", amount = 1, chance = 50, type = "item" },
    { item = "nitrous", amount = 1, chance = 10, type = "item" },
    { item = "nitrous", amount = 1, chance = 5, type = "item" },
}