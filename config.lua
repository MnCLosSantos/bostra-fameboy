Config = {}
Config.Debug = false
-- Which translation you wish to use ?
Config.frameworkObj = "QB" -- "QB" or "ESX" or "none" (if you don't use any framework it will execute by /fameboy)
Config.Target = "qb" -- "ox" or "qb"
Config.AdminOnly = true -- true or false to lock the /fameboy command to admins only

-- Arcade machine pricing options (in dollars)
-- Each entry: { label = "Display Text", price = cost, duration = seconds }
Config.ArcadePricing = {
    { label = "5 Minutes  - $5",  price = 5,  duration = 5  * 60 },
    { label = "10 Minutes - $10", price = 10, duration = 10 * 60 },
    { label = "15 Minutes - $15", price = 15, duration = 15 * 60 },
}

-- do not change unless you know what you're doing
Config.GPUList = {
    [1] = "ETX2080",
    [2] = "ETX1050",
    [3] = "ETX660",
}

-- do not change unless you know what you're doing
Config.CPUList = {
    [1] = "U9_9900",
    [2] = "U7_8700",
    [3] = "U3_6300",
    [4] = "BENTIUM",
}
Config.useArcades = true
Config.arcadeModelHashes = {
    { hash = `prop_arcade_01` },
    { hash = `ch_prop_arcade_degenatron_01a` },
    { hash = `ch_prop_arcade_monkey_01a` },
    { hash = `ch_prop_arcade_penetrator_01a` },
    { hash = `ch_prop_arcade_street_01a` },
    { hash = `ch_prop_arcade_street_01a_off` },
    { hash = `ch_prop_arcade_street_01b` },
    { hash = `ch_prop_arcade_street_01b_off` },
    { hash = `ch_prop_arcade_invade_01a` },
    { hash = `ch_prop_arcade_street_01c` },
    { hash = `ch_prop_arcade_street_01c_off` },
    { hash = `ch_prop_arcade_street_01d` },
    { hash = `ch_prop_arcade_street_01d_off` },
    { hash = `ch_prop_arcade_street_02b` },
    { hash = `ch_prop_arcade_wizard_01a` },
    { hash = `sum_prop_arcade_qub3d_01a` },
    { hash = `vw_prop_vw_arcade_01a` },
    { hash = `vw_prop_vw_arcade_02a` },
    { hash = `vw_prop_vw_arcade_02b` },
    { hash = `vw_prop_vw_arcade_02c` },
    { hash = `vw_prop_vw_arcade_02d` },
}




Config.GamingMachine = {
	{
        name = "Pac-Man",
        link = "https://freepacman.org/",
    },
}




Config.RetroMachine = {
    {
        name = "Duo",
        link = "https://duowfriends.eu/",
    },
    {
        name = "Flappy Bird",
        link = "https://flappybird.io/",
    },
    {
        name = "Om Nom Run",
        link = "https://omnomrun.com/",
    },
}




Config.SuperMachine = {
	{
        name = "Rocket Goal",
        link = "https://rocketgoal.io/",
    },
	{
        name = "Driving Simulator",
        link = "https://www.terradrive.eu/",
    },
	{
        name = "Narrow One",
        link = "https://narrow.one/",
    },
}

for i = 1, #Config.RetroMachine do
    table.insert(Config.SuperMachine, Config.RetroMachine[i])
end

