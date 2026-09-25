Config = {}

Config.JobName = 'gang'

-- Currency Configuration
Config.BlackMarketAccount = 'black_money' -- 'black_money' / 'dirty_money' depending on your ESX setup

-- Handcuff Item Requirement
Config.HandcuffItem = 'handcuffs'

-- Black Market Settings
Config.BlackMarketTimer = 3600000 -- 1 Hour in milliseconds (3600000 ms)

-- 5 Configurable Dynamic Locations
Config.BlackMarketLocations = {
    [1] = vector3(106.12, -1303.12, 28.76), -- Alleyway 1
    [2] = vector3(893.11, -3203.22, 5.90),   -- Docks
    [3] = vector3(154.23, -3212.11, 5.90),   -- Industrial Zone
    [4] = vector3(2550.23, 4670.33, 34.07),  -- Grapeseed Farm
    [5] = vector3(-3171.11, 1087.99, 20.83)  -- Chumash Cove
}

-- Black Market Inventory
Config.BlackMarketItems = {
    { name = 'WEAPON_ASSAULTRIFLE', label = 'Assault Rifle', price = 50000, isWeapon = true },
    { name = 'WEAPON_HEAVYPISTOL', label = 'Heavy Pistol', price = 15000, isWeapon = true },
    { name = 'WEAPON_ASSAULTRIFLE_MK2', label = 'Assault Rifle Mk II', price = 85000, isWeapon = true },
    { name = 'ammo-rifle', label = 'Rifle Ammo', price = 500, isWeapon = false },
    { name = 'ammo-9', label = 'Pistol Ammo', price = 250, isWeapon = false },
    { name = 'at_suppressor_heavy', label = 'Heavy Suppressor', price = 2000, isWeapon = false },
    { name = 'at_clip_extended', label = 'Extended Magazine', price = 1500, isWeapon = false }
}