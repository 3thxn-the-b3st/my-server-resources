Config = {}

-- Ambulance Configuration
Config.Ambulance = {
    CommandStart = 'sellamb',
    CommandStop = 'stopsellamb',
    Job = 'ambulance',
    Interval = 10000, -- 1 minute
    PatienceTimer = 30000, -- 30 seconds before dying
    Items = {
        { item = 'medikit', label = 'Medikit', price = 500 },
        { item = 'bandage', label = 'Bandage', price = 300 }
    },
    PedModels = {
        "a_m_y_stbla_02",
        "a_m_m_eastsa_01",
        "a_f_m_tourist_01"
    }
}

-- Gang Configuration
Config.Gang = {
    CommandStart = 'sellgang',
    CommandStop = 'stopsellgang',
    Jobs = {
        ['ballas'] = true,
        ['vagos'] = true,
        ['families'] = true,
        ['gang'] = true
    },
    Interval = 15000, -- 20 seconds
    CooldownTime = 15 * 60 * 1000, -- 15 minutes
    Items = {
        { item = 'marijuana', label = 'Marijuana' },
        { item = 'cannabis', label = 'Cannabis' }
    },
    PriceRange = { min = 500, max = 1000 }, -- Dirty money per item
    PedModels = {
        "g_m_y_ballaeast_01",
        "g_m_y_famca_01",
        "a_m_y_skater_01"
    }
}

-- Mechanic Configuration
Config.Mechanic = {
    CommandStart = 'sellmech',
    CommandStop = 'stopsellmech',
    Job = 'mechanic',
    Interval = 20000, -- 20 seconds
    Item = 'fixkit',
    Price = 5000,
    PedModels = {
        "a_m_m_business_01",
        "a_m_y_business_02",
        "a_f_y_business_01"
    }
}