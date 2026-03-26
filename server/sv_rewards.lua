local QBCore = exports['qb-core']:GetCoreObject()

local function IsItemInPool(itemName)
    for _, v in ipairs(Config.RewardPool) do
        if v.item == itemName then return true end
    end
    return false
end

function GiveStuntReward(src)
    if not Config.RewardsEnabled then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local isOxInventory = GetResourceState('ox_inventory') == 'started'

    for _, loot in ipairs(Config.RewardPool) do
        if loot.GuaranteedReward then
            local itemExists = loot.type == "currency" or QBCore.Shared.Items[loot.item]
            
            if itemExists then
                if loot.type == "currency" then
                    local amount = math.random(loot.min, loot.max)
                    Player.Functions.AddMoney("bank", amount, "stunt-jump-reward")
                elseif loot.type == "item" then
                    if isOxInventory then
                        exports.ox_inventory:AddItem(src, loot.item, loot.amount)
                    else
                        Player.Functions.AddItem(loot.item, loot.amount)
                        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[loot.item], "add")
                    end
                end
            else
                lib.print.error(("Item '%s' found in Config but missing from QBCore.Shared.Items!"):format(loot.item))
            end
        end
    end

    local totalWeight = 0
    local pool = {}
    for _, loot in ipairs(Config.RewardPool) do
        if not loot.GuaranteedReward and loot.chance > 0 then
            if QBCore.Shared.Items[loot.item] or loot.type == "currency" then
                table.insert(pool, loot)
                totalWeight = totalWeight + loot.chance
            else
                lib.print.error(("Skipping lucky drop '%s' - Item missing from Framework!"):format(loot.item))
            end
        end
    end

    if totalWeight > 0 then
        local roll = math.random(1, totalWeight)
        local counter = 0
        for _, loot in ipairs(pool) do
            counter = counter + loot.chance
            if roll <= counter then
                if IsItemInPool(loot.item) then
                    if loot.type == "currency" then
                        Player.Functions.AddMoney("bank", math.random(loot.min, loot.max), "stunt-lucky-drop")
                    elseif loot.type == "item" then
                        if isOxInventory then
                            exports.ox_inventory:AddItem(src, loot.item, loot.amount)
                        else
                            Player.Functions.AddItem(loot.item, loot.amount)
                            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[loot.item], "add")
                        end
                    end
                end
                break 
            end
        end
    end

    if Config.RewardDriverXp then
        exports.brutal_gym:AddSkillCount(src, "Driving", Config.RewardXpCount)
    end
end