local io = require "io"
local json = require "json"
local prng = require "PRNG"

local Utils = {}
Utils.items = {
    spearman = 252000,
    wagon = 252001,
    mage = 252002,
    archer = 252003,
    knight = 252004,
    ballista = 252005,
    trebuchet = 252006,
    giant = 252007,
    griffin_walking = 252008,
    harpy = 252009,
    witch = 252010,
    dragon = 252011,
    balloon = 252012,
    travelboat = 252013,
    caravel = 252014,
    merman = 252015,
    turtle = 252016,
    harpoonship = 252017,
    warship = 252018,
    frog = 252019,
    kraken = 252020,
    thief = 252021,
    rifleman = 252022,

    BridgesEvent = 252023,
    WallsEvent = 252024,
    LandingEvent = 252025,
    AirstrikeEvent = 252026,
    FinalNorth = 252027,
    FinalEast = 252028,
    FinalSouth = 252029,
    FinalWest = 252030,
    FinalCenter = 252031,

    IncomeBoost = 252032,
    CommanderDefenseBoost = 252033,

    CherrystoneCommanders = 252034,
    FelheimCommanders = 252035,
    FloranCommanders = 252036,
    HeavensongCommanders = 252037,
    RequiemCommanders = 252038,
    PirateCommanders = 252039,
    FaahriCommanders = 252040,
    GrooveBoost = 252041,
}

Utils.COs = {
    "commander_caesar",
    "commander_darkmercia",
    "commander_elodie",
    "commander_emeric",
    "commander_greenfinger",
    "commander_koji",
    "commander_mercia",
    "commander_mercival",
    "commander_nuru",
    "commander_ragna",
    "commander_ryota",
    "commander_sedge",
    "commander_sigrid",
    "commander_tenri",
    "commander_twins",
    "commander_valder",
    "commander_vesper",
    "commander_wulfar_pirate",
    "commander_nadia",
    "commander_rhomb",
    "commander_pistil",
    "commander_lytra",
    "commander_duchess",
}

Utils.locations = {}
Utils.locations["Humble Beginnings Rebirth: Talk to Nadia"]=253001
Utils.locations["Humble Beginnings Rebirth: Victory"]=253002
Utils.locations["Humble Beginnings Rebirth: Good Dog"]=253003
Utils.locations["Nuru's Vengeance: Victory"]=253005
Utils.locations["Nuru's Vengeance: Destroy the Gate with a Spearman"]=253006
Utils.locations["Nuru's Vengeance: Defeat all Dogs"]=253007
Utils.locations["Cherrystone Landing: Smacked a Trebuchet"]= 253008
Utils.locations["Cherrystone Landing: Smacked a Fortified Village"]= 253009
Utils.locations["Cherrystone Landing: Victory"]= 253010
Utils.locations["Den-Two-Away: Victory"]= 253011
Utils.locations["Den-Two-Away: Commander Captures the Lumbermill"]= 253012
Utils.locations["Skydiving: Victory"]= 253013
Utils.locations["Skydiving: Dragon Defeats Stronghold"]= 253014
Utils.locations["Terrible Tributaries: Victory"]= 253015
Utils.locations["Terrible Tributaries: Swimming Knights"]= 253016
Utils.locations["Terrible Tributaries: Steal Code Names"]= 253017
Utils.locations["Beached: Victory"]= 253018
Utils.locations["Beached: Turtle Power"]= 253019
Utils.locations["Beached: Happy Turtle"]= 253020
Utils.locations["Riflemen Blockade: Victory"]= 253021
Utils.locations["Riflemen Blockade: From the Mountains"]= 253022
Utils.locations["Riflemen Blockade: To the Road"]= 253023
Utils.locations["Wagon Freeway: Victory"]= 253024
Utils.locations["Wagon Freeway: All Mine Now"]= 253025
Utils.locations["Wagon Freeway: Pigeon Carrier"]= 253026
Utils.locations["Kraken Strait: Victory"]= 253027
Utils.locations["Kraken Strait: Well Defended"]= 253028
Utils.locations["Kraken Strait: Clipped Wings"]= 253029
Utils.locations["A Ribbitting Time: Victory"]= 253030
Utils.locations["A Ribbitting Time: Leap Frog"]= 253031
Utils.locations["A Ribbitting Time: Frogway Robbery"]= 253032
Utils.locations["Precarious Cliffs: Victory"]= 253033
Utils.locations["Precarious Cliffs: No Crit for You"]= 253034
Utils.locations["Precarious Cliffs: Out Ranged"]= 253035
Utils.locations["Grand Theft Village: Victory"]= 253036
Utils.locations["Grand Theft Village: Stand Tall"]= 253037
Utils.locations["Grand Theft Village: Pillager"]= 253038
Utils.locations["Bridge Brigade: Victory"]= 253039
Utils.locations["Bridge Brigade: From the Depths"]= 253040
Utils.locations["Bridge Brigade: Back to the Depths"]= 253041
Utils.locations["Swimming at the Docks: Victory"]= 253042
Utils.locations["Swimming at the Docks: Dogs Counter Knights"]= 253043
Utils.locations["Swimming at the Docks: Kayaking"]= 253044
Utils.locations["Ancient Discoveries: Victory"]= 253045
Utils.locations["Ancient Discoveries: So many Choices"]= 253046
Utils.locations["Ancient Discoveries: Height Advantage"]= 253047
Utils.locations["Observation Isle: Victory"]= 253048
Utils.locations["Observation Isle: Become the Watcher"]= 253049
Utils.locations["Observation Isle: Execute the Watcher"]= 253050
Utils.locations["Majestic Mountain: Victory"]= 253051
Utils.locations["Majestic Mountain: Mountain Climbing"]= 253052
Utils.locations["Majestic Mountain: Legend of the Mountains"]= 253053
Utils.locations["Floran Trap: Victory"]= 253054
Utils.locations["Floran Trap: Means of Production"]= 253055
Utils.locations["Floran Trap: Aerial Reconnaissance"]= 253056
------------------------------------------------------------------------------------------------------------------------
Utils.locations["Slippery Bridge: Victory"]= 253300
Utils.locations["Slippery Bridge: Control the Water"]= 253301
Utils.locations["Spire Fire: Destroy the Towers"]= 253305
Utils.locations["Spire Fire: Air Superiority"]= 253306
Utils.locations["Spire Fire: Dragon Survives"]= 253307
Utils.locations["Sunken Forest: Victory"]= 253310
Utils.locations["Sunken Forest: High Ground"]= 253311
Utils.locations["Sunken Forest: Coastal Siege"]= 253312
Utils.locations["Tenri's Mistake: Victory"]= 253315
Utils.locations["Tenri's Mistake: Mighty Barracks"]= 253316
Utils.locations["Tenri's Mistake: Commander Arrives"]= 253317
Utils.locations["Enmity Cliffs: Victory"]= 253320
Utils.locations["Enmity Cliffs: Spear Flood"]= 253321
Utils.locations["Enmity Cliffs: Across the Gap"]= 253322
Utils.locations["Portal Peril: Victory"]= 253325
Utils.locations["Portal Peril: Unleash the Hounds"]= 253326
Utils.locations["Portal Peril: Overcharged"]= 253327
Utils.locations["Towers of the Abyss: Victory"]= 253330
Utils.locations["Towers of the Abyss: Siege Master"]= 253331
Utils.locations["Towers of the Abyss: Perfect Defense"]= 253332
Utils.locations["Gnarled Mountaintop: Victory"]= 253335
Utils.locations["Gnarled Mountaintop: Watch the Watchtower"]= 253336
Utils.locations["Gnarled Mountaintop: Vine Skip"]= 253337
Utils.locations["Gold Rush: Victory"]= 253340
Utils.locations["Gold Rush: Lumber Island"]= 253341
Utils.locations["Gold Rush: Starglass Rush"]= 253342
Utils.locations["Finishing Blow: Victory"]= 253345
Utils.locations["Finishing Blow: Mass Destruction"]= 253346
Utils.locations["Finishing Blow: Defortification"]= 253347
Utils.locations["Frantic Inlet: Victory"]= 253350
Utils.locations["Frantic Inlet: Plug the Gap"]= 253351
Utils.locations["Frantic Inlet: Portal Detour"]= 253352
Utils.locations["Operation Seagull: Victory"]= 253355
Utils.locations["Operation Seagull: Crack the Crystal"]= 253356
Utils.locations["Operation Seagull: Counter Break"]= 253357
Utils.locations["Air Support: Victory"]= 253360
Utils.locations["Air Support: Roadkill"]= 253361
Utils.locations["Air Support: Flight Economy"]= 253362
Utils.locations["Fortification: Victory"]= 253365
Utils.locations["Fortification: Hyper Repair"]= 253366
Utils.locations["Fortification: Defensive Artillery"]= 253367
Utils.locations["Split Valley: Victory"]= 253370
Utils.locations["Split Valley: Longshot"]= 253371
Utils.locations["Split Valley: Ranged Trinity"]= 253372

function Utils.getLocationName(id)
    for k,v in pairs(Utils.locations) do
        if v == id then
            return k
        end
    end
    return ""
end

function Utils.getItemName(id)
    for k,v in pairs(Utils.items) do
        if v == id then
            return k
        end
    end
    return ""
end

function Utils.getCommanderData()
    local f = io.open("AP\\commander.json", "r")
    if f == nil then
        -- Return Mercival and 0 starting groove in case the player closes the client. This prevents cheating
        return "commander_mercival", 0
    end
    local fileText = f:read("*all")
    io.close(f)
    local commanderData = json.parse(fileText)
    return commanderData["commander"], 0
end

function Utils.getSettings()
    local f = io.open("AP\\AP_settings.json", "r")
    if f == nil then
        return nil
    end
    local fileText = f:read("*all")
    io.close(f)
    local data = json.parse(fileText)
    return data
end

function Utils.shuffle(lst)
    for i = #lst, 2, -1 do
        local j = (prng.get_random_32() % i) + 1
        lst[i], lst[j] = lst[j], lst[i]
    end
end

function Utils.listContains(lst, value)
    for i = 1,#lst do
        if (lst[i] == value) then
            return true
        end
    end
    return false
end

function Utils.getAvailableCommanders()
    local f = io.open("AP\\available_commanders.json", "r")
    local available_commanders = {}
    if f == nil then
        return {"commander_mercival"}
    end
    local fileText = f:read("*all")
    io.close(f)
    local data = json.parse(fileText)
    if data == nil then
        return available_commanders
    end
    for index = 1,#data do
        for coIndex = 1,#Utils.COs do
            if data[index][1][2] == Utils.COs[coIndex] then
                table.insert(available_commanders, Utils.COs[coIndex])
            end
        end
    end
    if next(available_commanders) == nil then
        available_commanders = {"commander_mercival"}
    end
    return available_commanders
end

return Utils