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
Utils.locations["Unknown Location (253008)"]=253008
Utils.locations["Unknown Location (253009)"]=253009
Utils.locations["Unknown Location (253010)"]=253010
Utils.locations["Unknown Location (253011)"]=253011
Utils.locations["Unknown Location (253012)"]=253012
Utils.locations["Unknown Location (253013)"]=253013
Utils.locations["Unknown Location (253014)"]=253014
Utils.locations["Unknown Location (253015)"]=253015
Utils.locations["Unknown Location (253016)"]=253016
Utils.locations["Unknown Location (253017)"]=253017
Utils.locations["Unknown Location (253018)"]=253018
Utils.locations["Unknown Location (253019)"]=253019
Utils.locations["Unknown Location (253020)"]=253020
Utils.locations["Unknown Location (253021)"]=253021
Utils.locations["Unknown Location (253022)"]=253022
Utils.locations["Unknown Location (253023)"]=253023
Utils.locations["Unknown Location (253024)"]=253024
Utils.locations["Unknown Location (253025)"]=253025
Utils.locations["Unknown Location (253026)"]=253026
Utils.locations["Unknown Location (253027)"]=253027
Utils.locations["Unknown Location (253028)"]=253028
Utils.locations["Unknown Location (253029)"]=253029
Utils.locations["Unknown Location (253030)"]=253030
Utils.locations["Unknown Location (253031)"]=253031
Utils.locations["Unknown Location (253032)"]=253032
Utils.locations["Unknown Location (253033)"]=253033
Utils.locations["Unknown Location (253034)"]=253034
Utils.locations["Unknown Location (253035)"]=253035
Utils.locations["Unknown Location (253036)"]=253036
Utils.locations["Unknown Location (253037)"]=253037
Utils.locations["Unknown Location (253038)"]=253038
Utils.locations["Unknown Location (253039)"]=253039
Utils.locations["Unknown Location (253040)"]=253040
Utils.locations["Unknown Location (253041)"]=253041
Utils.locations["Unknown Location (253042)"]=253042
Utils.locations["Unknown Location (253043)"]=253043
Utils.locations["Unknown Location (253044)"]=253044
Utils.locations["Unknown Location (253045)"]=253045
Utils.locations["Unknown Location (253046)"]=253046
Utils.locations["Unknown Location (253047)"]=253047
Utils.locations["Unknown Location (253048)"]=253048
Utils.locations["Unknown Location (253049)"]=253049
Utils.locations["Unknown Location (253050)"]=253050

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