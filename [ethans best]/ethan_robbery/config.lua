Config = {}

Config.MinPoliceToDisableNPCS = 4 -- If active police on server < this, spawn NPC police
Config.PoliceCarCount = 1         -- Number of police cars to spawn per wave
Config.RobberyDuration = 30       -- Robbery hold-out time in seconds (5 min)
Config.LobbyDuration = 30         -- Time allowed to join robbery in seconds
Config.CooldownTime = 300         -- Cooldown per store in seconds (5 min)
Config.MaxRobbers = 4             -- Maximum participants per robbery
Config.JoinRadius = 30.0          -- Radius for nearby players to receive join prompt
Config.TotalReward = 300000       -- Total dirty money split between robbers
Config.PedModel = `mp_m_shopkeep_01`

-- Jobs restricted from starting or joining store robberies
Config.RestrictedJobs = {
    ['police'] = true,
    ['ambulance'] = true
}

Config.Peds = {
    vec4(2676.61, 3280.18, 54.24, 328.88),
    vec4(-2966.25, 391.53, 15.04, 86.9),
    vec4(1959.43, 3741.15, 32.34, 300.68),
    vec4(1697.53, 4923.12, 42.06, 325.96),
    vec4(372.85, 327.87, 103.57, 247.13),
    vec4(1134.15, -983.28, 46.42, 277.94),
    vec4(1164.93, -323.53, 69.21, 103.01),
    vec4(-706.09, -914.6, 19.22, 91.94),
    vec4(-1221.29, -908.03, 12.33, 34.85),
    vec4(-1486.7, -377.5, 40.16, 138.08),
    vec4(-47.17, -1758.37, 29.42, 50.71),
    vec4(24.14, -1345.66, 28.5, 272.08)
}