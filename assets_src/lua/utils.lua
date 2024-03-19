local io = require "io"
local json = require "json"

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
    caravel = 252013,
    travelboat = 252014,
    merman = 252015,
    turtle = 252016,
    harpoonship = 252017,
    frog = 252018,
    kraken = 252019,
    warship = 252020,
    thief = 252021,
    rifleman = 252022,

    BridgesEvent = 252023,
    WallsEvent = 252024,
    LandingEvent = 252025,
    AirstrikeEvent = 252026,
    FinalBridges = 252027,
    FinalWalls = 252028,
    FinalSickle = 252029,
    FinalLanding = 252030,
    FinalAirstrike = 252031,

    IncomeBoost = 252032,
    CommanderDefenseBoost = 252033,

    CherrystoneCommanders = 252034,
    FelheimCommanders = 252035,
    FloranCommanders = 252036,
    HeavensongCommanders = 252037,
    RequiemCommanders = 252038,
    PirateCommanders = 252039,
    FaahriCommanders = 252040,
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
}

Utils.locations = {}
Utils.locations["Humble Beginnings Rebirth: Talk to Nadia"]=253001
Utils.locations["Humble Beginnings Rebirth: Victory"]=253002
Utils.locations["Nuru's Vengeance: Victory"]=253005
Utils.locations["Nuru's Vengeance: Destroy the Gate with a Spearman"]=253006
Utils.locations["Nuru's Vengeance: Defeat all Dogs"]=253007
Utils.locations["A Knight's Folly: Victory"]=253008
Utils.locations["Denrunaway: Chest"]=253009
Utils.locations["Denrunaway: Victory"]=253010
Utils.locations["Dragon Freeway: Victory"]=253011
Utils.locations["Deep Thicket: Find Sedge"]=253012
Utils.locations["Deep Thicket: Victory"]=253013
Utils.locations["Corrupted Inlet: Victory"]=253014
Utils.locations["Mage Mayhem: Caesar"]=253015
Utils.locations["Mage Mayhem: Victory"]=253016
Utils.locations["Endless Knight: Victory"]=253017
Utils.locations["Ambushed in the Middle: Victory (Blue)"]=253018
Utils.locations["Ambushed in the Middle: Victory (Green)"]=253019
Utils.locations["The Churning Sea: Victory"]=253020
Utils.locations["Frigid Archery: Light the Torch"]=253021
Utils.locations["Frigid Archery: Victory"]=253022
Utils.locations["Archery Lessons: Chest"]=253023
Utils.locations["Archery Lessons: Victory"]=253024
Utils.locations["Surrounded: Caesar"]=253025
Utils.locations["Surrounded: Victory"]=253026
Utils.locations["Darkest Knight: Victory"]=253027
Utils.locations["Robbed: Victory"]=253028
Utils.locations["Open Season: Caesar"]=253029
Utils.locations["Open Season: Victory"]=253030
Utils.locations["Doggo Mountain: Find all the Dogs"]=253031
Utils.locations["Doggo Mountain: Victory"]=253032
Utils.locations["Tenri's Fall: Victory"]=253033
Utils.locations["Master of the Lake: Victory"]=253034
Utils.locations["A Ballistas Revenge: Victory"]=253035
Utils.locations["Rebel Village: Victory (Pink)"]=253036
Utils.locations["Rebel Village: Victory (Red)"]=253037
Utils.locations["Foolish Canal: Victory"]=253038

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
    return commanderData["commander"], commanderData["starting_groove"]
end

return Utils