Config = {}

-- Target job allowed to start and participate in the raid
Config.JobName = 'gang'

-- Raid Prompt & Schedule Settings
Config.RaidSchedule = {
    Interval = 900000,          -- Time between raid prompts (15 minutes in ms)
    PromptDuration = 30,         -- Duration of prompt window in seconds
    NPCProximityRadius = 15.0    -- Max distance all participants must be from Contact NPC
}

-- Police & Ambush Settings
Config.Police = {
    jobs = {
        police = true,
        sheriff = true
    },
    npcBackup = true,            -- Spawns NPC police as fallback if 0 real police online
    npcCount = 6,                -- 6 NPC cops spawn if no real police online
    npcVehicle = 'police3',
    npcPedModel = 's_m_y_cop_01',
    TrackingInterval = 5000,     -- Real-time police blip update rate (5 seconds)

    -- Dynamic Chasing Police
    ChasingPoliceInterval = 30000,

    -- Drop-off Ambush
    DropoffGuardCount = 6,         -- 6 Police guards defending the drop-off site
    DropoffPedModel = 's_m_y_cop_01'
}

-- Warehouse Raid Mission Settings
Config.WarehouseRaid = {
    Debug = false,
    MinPlayers = 1,
    MaxPlayers = 6,
    Cooldown = 1800000,         -- 30 minutes cooldown in ms
    Timeout = 600000,           -- STRICT 10 Minutes mission limit (600,000 ms)
    CratesRequired = 4,
    GetawayVehicle = 'burrito',
    CrateModel = `hei_prop_heist_box`,
    DeliveryRadius = 30.0,      -- 30 meters radius requirement for delivery
    
    -- Difficulty Settings
    EnableGuardWaves = true,
    GuardWaveInterval = 35000,  -- Spawns extra guards every 35 seconds
    GuardWaveCount = 6,         -- Spawns 6 guards per wave

    RewardPerPlayer = {
        min = 35000,
        max = 60000
    },

    ContactPed = {
        model = `s_m_y_dealer_01`,
        coords = vector4(116.2, -1946.8, 20.7, 200.0)
    },

    Warehouses = {
        [1] = {
            name = "Elysian Island Warehouse",
            coords = vector3(1010.5, -2510.2, 28.3),
            vehicleSpawn = vector4(1005.1, -2520.0, 28.3, 270.0),
            guardModel = 'g_m_y_mexgang_01',
            guards = {
                vector4(1015.0, -2505.0, 28.3, 180.0),
                vector4(1020.0, -2515.0, 28.3, 90.0),
                vector4(1005.0, -2500.0, 28.3, 0.0),
                vector4(1012.0, -2518.0, 28.3, 45.0),
                vector4(1022.0, -2508.0, 28.3, 210.0),
                vector4(1002.0, -2512.0, 28.3, 310.0)
            },
            crates = {
                vector3(1014.2, -2508.1, 28.3),
                vector3(1018.5, -2512.3, 28.3),
                vector3(1008.1, -2503.2, 28.3),
                vector3(1011.0, -2515.0, 28.3)
            }
        },
        [2] = {
            name = "Cypress Flats Warehouse",
            coords = vector3(805.2, -2230.1, 29.4),
            vehicleSpawn = vector4(798.1, -2240.0, 29.4, 180.0),
            guardModel = 'g_m_y_ballaeast_01',
            guards = {
                vector4(810.0, -2225.0, 29.4, 270.0),
                vector4(800.0, -2235.0, 29.4, 0.0),
                vector4(812.0, -2238.0, 29.4, 90.0),
                vector4(795.0, -2228.0, 29.4, 135.0),
                vector4(815.0, -2230.0, 29.4, 180.0),
                vector4(790.0, -2233.0, 29.4, 45.0)
            },
            crates = {
                vector3(808.2, -2228.1, 29.4),
                vector3(802.1, -2232.0, 29.4),
                vector3(811.5, -2236.4, 29.4),
                vector3(797.3, -2226.5, 29.4)
            }
        }
    },

    DeliveryLocations = {
        vector3(-470.2, -1725.1, 18.6),
        vector3(1210.5, -1310.2, 35.2),
        vector3(-1150.1, -2160.4, 13.2)
    }
}