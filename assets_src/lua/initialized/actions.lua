local Events = require "initialized/events"
local Wargroove = require "wargroove/wargroove"
local UnitState = require "unit_state"
local Utils = require "utils"
local io = require "io"
local json = require "json"
local prng = require "PRNG"
local Maps = require "imported_maps"
local simplex = require "simplex"
local Biomes = require "biomes"

local Actions = {}

function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    dst["ap_location_send"] = Actions.apLocationSend
    dst["ap_count_item"] = Actions.apCountItem
    dst["ap_victory"] = Actions.apVictory
    dst["ap_prng_seed_num"] = Actions.apPRNGSeedNumber
    dst["ap_random"] = Actions.apRandom
    dst["ap_spawn_unit"] = Actions.apSpawnUnit
    dst["ap_export"] = Actions.apExport
    dst["ap_import"] = Actions.apImport
    dst["unit_random_teleport"] = Actions.unitRandomTeleport
    dst["eliminate"] = Actions.eliminate
    dst["map_randomize"] = Actions.mapRandomize
    dst["position_randomize"] = Actions.positionRandomize
    dst["position_asymmetric_randomize"] = Actions.positionAsymmetricRandomize

    -- Unlisted actions
    dst["ap_item_check"] = Actions.apItemCheck
    dst["ap_replace_production"] = Actions.replaceProduction
    dst["unit_random_co"] = Actions.unitRandomCO
    dst["ap_income_boost"] = Actions.apIncomeBoost
    dst["ap_commander_defense_boost"] = Actions.apDefenseBoost
    dst["ap_groove_boost"] = Actions.apGrooveBoost
end

-- Local functions

local function removeElementFromListXY(lst, element)
    local i = 1
    while i <= #lst do
        local pos = lst[i]
        if pos.x == element.x and pos.y == element.y then
            table.remove(lst, i)
            break
        end
        i = i + 1
    end
end

local function removePositionsAroundElement(lst, element, distance)
    for x = -distance, distance do
        for y = -distance + math.abs(x), distance - math.abs(x) do
            removeElementFromListXY(lst, {x=element.x + x, y=element.y + y})
        end
    end
end

local function findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)

    return centre
end

local function findPlaceInLocation(location, unitClassId)
    local candidates = {}
    local centre = nil
    local positions = nil

    if location == nil then
        -- No location, use whole map
        local mapSize = Wargroove.getMapSize()
        positions = {}
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                table.insert(positions, { x = x, y = y })
            end
        end
        centre = { x = math.floor(mapSize.x / 2), y = math.floor(mapSize.y / 2) }
    else
        positions = location.positions
        centre = findCentreOfLocation(location)
    end

    -- All candidates
    for i, pos in ipairs(positions) do
        if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
            local dx = pos.x - centre.x
            local dy = pos.y - centre.y
            local dist = dx * dx + dy * dy
            table.insert(candidates, { pos = pos, dist = dist })
        end
    end

    -- Sort candidates
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    return candidates
end

function Actions.eliminate(context)
    local playerId = context:getPlayerId(0)
    Wargroove.eliminate(playerId)
    if Wargroove.isHuman(playerId) and Wargroove.getTurnNumber() > 1 and Wargroove.getCurrentPlayerId() ~= playerId then
        print("Deathlink Sent")
        local map_name = UnitState.getState("Map_Name")
        if map_name == 0 or map_name == "" then
            map_name = "Humble Beginnings Rebirth"
        end
        local f = io.open("AP\\deathLinkSend", "w+")
        f:write(map_name)
        io.close(f)
    end
end

function Actions.apExport(context)
    print("AP Export")
    prng.set_seed(context:getInteger(0))
    local exportTable = {}
    exportTable["Map_Name"] = context:getString(1)
    exportTable["Author"] = context:getString(2)
    UnitState.setState("Map_Name", exportTable["Map_Name"])
    local objectives = {}
    for i = 3, 6, 1 do
        local objective = context:getString(i)
        if objective ~= nil and objective ~= "" then
            table.insert(objectives, objective)
        end
    end
    exportTable["Objectives"] = objectives

    local numPlayers = Wargroove.getNumPlayers(false)
    exportTable["Player_Count"] = numPlayers
    for i = 1, numPlayers do
        exportTable["Player_" .. i] = {team=Wargroove.getPlayerTeam(i - 1), gold=Wargroove.getMoney(i - 1)}

        for k, v in pairs(Utils.items) do
            if Utils.items[k] <= Utils.items["rifleman"] then
                exportTable["Player_" .. i]["recruit_" .. k] = Wargroove.canPlayerRecruit(i - 1, k)
            end
        end
        exportTable["Player_" .. i]["recruit_soldier"] = Wargroove.canPlayerRecruit(i - 1, "soldier")
        exportTable["Player_" .. i]["recruit_dog"] = Wargroove.canPlayerRecruit(i - 1, "dog")
    end
    local mapSize = Wargroove.getMapSize()
    exportTable["Map_Size"] = mapSize
    local locations = {}
    for x =0, mapSize.x - 1 do
        for y =0, mapSize.y - 1 do
            local pos = {x=x, y=y }
            local locId = Wargroove.getLocationIdsAt(x, y)
            if locId ~= nil and #locId ~= 0 then
                for i =1, #locId do
                    locations[locId[i]] = Wargroove.getLocationById(locId[i])
                end
            end
            exportTable["Map_Tile_" .. tostring(x) .. "_" .. tostring(y)] = {terrain=Wargroove.getTerrainNameAt(pos), unit=Wargroove.getUnitAt(pos), item=Wargroove.getMapItemAt(pos)}
        end
    end
    exportTable["Locations"] = locations
    exportTable["Triggers"] = Wargroove.getMapTriggers()
    exportTable["Counters"] = context.mapCounters
    exportTable["Flags"] = context.mapFlags
    local export = io.open("AP\\export.json", "w+")
    export:write(json.stringify(exportTable))
    io.close(export)
    context.mapFlags[99] = true
end

function Actions.apImport(context)
    Events.import(context, true, context:getInteger(0))
end

function Actions.apItemCheck(context)
    -- "Add ap item check"
    for k, v in pairs(Utils.items) do
        local f = io.open("AP\\AP_" .. tostring(v) .. ".item", "r")
        local print_file_item = io.open("AP\\AP_" .. tostring(v) .. ".item.print", "r+")
        if f ~= nil then
            local itemCount = tonumber(f:read())
            if itemCount == nil then
                itemCount = 0
            end
            UnitState.setState(k, itemCount)
            io.close(f)
        else
            UnitState.setState(k, 0)
        end
        if print_file_item ~= nil then
            local print_text = print_file_item:read()
            if print_text ~= nil and print_text ~= "" then
                Wargroove.showMessage(print_text)
            end
            io.close(print_file_item)

            local print_file_clear = io.open("AP\\AP_" .. tostring(v) .. ".item.print", "w+")
            io.close(print_file_clear)
        end
    end
end

function Actions.apCountItem(context)
    -- "Add ap count item {0} and store into {1}"
    local itemId = context:getInteger(0)
    for k, v in pairs(Utils.items) do
        if v == itemId then
            local f = io.open("AP\\AP_" .. tostring(v) .. ".item", "r")
            if f ~= nil then
                local itemCount = tonumber(f:read())
                if itemCount == nil then
                    context:setMapCounter(1, 0)
                    io.close(f)
                    return
                end
                context:setMapCounter(1, itemCount)
                io.close(f)
                return
            else
                context:setMapCounter(1, 0)
                return
            end
        end
    end
    context:setMapCounter(1, 0)
    return
end


function Actions.apLocationSend(context)
    -- "Send ap Location ID {0}"
    local locationId = context:getInteger(0)
    local f = io.open("AP\\send" .. tostring(locationId), "w")
    f:write("")
    io.close(f)
    Wargroove.showMessage("Discovered location (" .. Utils.getLocationName(locationId) .. ")")
end

function Actions.apVictory(context)
    -- "Send AP Victory"
    local final_level_name = UnitState.getState("Map_Name")
    local f = io.open("AP\\victory", "w")
    f:write(final_level_name)
    io.close(f)
end


function Actions.apIncomeBoost(context)
    -- "Read the income boost setting and apply it to player {0}"

    local flag = context.mapFlags[99]
    local map_name = UnitState.getState("Map_Name")
    if (flag == nil or flag == false or flag == 0) and map_name ~= 0 then
        return
    end
    local playerId = context:getPlayerId(0)
    if Wargroove.isHuman(playerId) then
        local item = io.open("AP\\AP_" .. tostring(Utils.items["IncomeBoost"]) .. ".item", "r")
        local itemValue = 0
        if item ~= nil then
            itemValue = tonumber(item:read())
            io.close(item)
        end
        Wargroove.changeMoney(playerId, itemValue)
    end
end

function Actions.apDefenseBoost(context)
    local item = io.open("AP\\AP_" .. tostring(Utils.items["CommanderDefenseBoost"]) .. ".item", "r")
    local itemValue = 0
    if item ~= nil then
        itemValue = tonumber(item:read())
        io.close(item)
    end
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if Wargroove.isHuman(unit.playerId) and unit.unitClass.isCommander then
            unit.damageTakenPercent = math.max(100 - (itemValue), 1)
            Wargroove.updateUnit(unit)
        end
    end
end

function Actions.apGrooveBoost(context)
    local item = io.open("AP\\AP_" .. tostring(Utils.items["GrooveBoost"]) .. ".item", "r")
    local itemValue = 0
    if item ~= nil then
        itemValue = tonumber(item:read())
        io.close(item)
    end
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if Wargroove.isHuman(unit.playerId) and unit.unitClass.isCommander then
            unit.grooveCharge = itemValue
            Wargroove.updateUnit(unit)
        end
    end
end

function Actions.unitRandomCO(context)
    local playerId = context:getPlayerId(0)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if unit.unitClass.isCommander and unit.playerId ~= -1 then
            --local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(playerId).. tostring(unit.id))) * (18 - 1 + 1)) + 1
            local commander, starting_groove = Utils.getCommanderData()
            if commander ~= "seed" and Wargroove.isHuman(unit.playerId) then
                unit.unitClassId = commander
            else
                local random = (prng.get_random_32() % 22) + 1
                unit.unitClassId = Utils.COs[random]
            end
            if (unit.inTransport) then
                local transport = Wargroove.getUnitById(unit.transportedBy)
                Wargroove.updateUnit(transport)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
            end
            Wargroove.updateUnit(unit)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
        end
    end
end

function Actions.apSetCOGroove(context)
    local playerId = context:getPlayerId(0)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            --local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(playerId).. tostring(unit.id))) * (18 - 1 + 1)) + 1
            local commander, starting_groove = Utils.getCommanderData()
            if commander ~= "seed" and Wargroove.isHuman(unit.playerId) then
                unit.grooveCharge = starting_groove
                Wargroove.updateUnit(unit)
            end
        end
    end
end

function Actions.unitRandomTeleport(context)
    -- "Randomly Teleport all {0} owned by {1} from {2} to {3} (silent = {4})"
    local units = context:gatherUnits(1, 0, 2)
    local target = context:getLocation(3)
    local silent = context:getBoolean(4)

    for i, unit in ipairs(units) do
        local candidates = findPlaceInLocation(target, unit.unitClassId)
        local oldPos = unit.pos
        local numcandidates = #candidates
        if numcandidates > 0 then
            -- local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(unit.playerId).. tostring(unit.id))) * (numcandidates - 1 + 1)) + 1
            local random = (prng.get_random_32() % numcandidates) + 1
            unit.pos = candidates[random].pos
        end

        if not unit.inTransport then
            if (not silent) and Wargroove.canCurrentlySeeTile(oldPos) then
                Wargroove.spawnMapAnimation(oldPos, 0, "fx/mapeditor_unitdrop")
                Wargroove.waitFrame()
                Wargroove.setVisibleOverride(unit.id, false)
            end

            Wargroove.updateUnit(unit)

            if (not silent) then
                Wargroove.waitTime(0.2)
                Wargroove.unsetVisibleOverride(unit.id)
            end

            if (not silent) and Wargroove.canCurrentlySeeTile(unit.pos) then
                Wargroove.trackCameraTo(unit.pos)
                Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
                Wargroove.playMapSound("spawn", unit.pos)
                Wargroove.waitTime(0.2)
            end
        end
    end
end

function Actions.locationRandomTeleportToUnit(context)
    -- "Randomly Move location {0} to {1} owned by {2} at {3}."
    local location = context:getLocation(0)
    local units = context:gatherUnits(2, 1, 3)
    local num_units = #units
    if num_units == 0 then
       return
    end
    local random = (prng.get_random_32() % num_units) + 1
    local unit = units[random]
    if (unit.inTransport) then
        local transport = Wargroove.getUnitById(unit.transportedBy)
        Wargroove.moveLocationTo(location.id, transport.pos)
    else
        Wargroove.moveLocationTo(location.id, unit.pos)
    end
end

local function replaceProductionStructure(playerId, unit, productionClassStr, productionApClassStr)

    if unit.playerId == playerId and Wargroove.isHuman(unit.playerId) and unit.unitClass.id == productionClassStr then
        unit.unitClassId = productionApClassStr
        Wargroove.updateUnit(unit)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
    end
    if Wargroove.isNeutral(unit.playerId) and unit.unitClass.id == productionApClassStr then
        unit.unitClassId = productionClassStr
        Wargroove.updateUnit(unit)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
    end
    if unit.playerId == playerId and not Wargroove.isHuman(unit.playerId) and unit.unitClass.id == productionApClassStr then
        unit.unitClassId = productionClassStr
        Wargroove.updateUnit(unit)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
    end
end

function Actions.replaceProduction(context)
    local playerId = context:getPlayerId(0)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        replaceProductionStructure(playerId, unit, "barracks", "barracks_ap")
        replaceProductionStructure(playerId, unit, "tower", "tower_ap")
        replaceProductionStructure(playerId, unit, "port", "port_ap")
        replaceProductionStructure(playerId, unit, "hideout", "hideout_ap")
    end
end

function Actions.apPRNGSeedNumber(context)
    -- "Seed our unique PRNG algorithm"
    local seedId = context:getInteger(0)
    local seedFile = io.open("AP\\seed" .. tostring(seedId), "r")
    local seed = 0
    if seedFile ~= nil then
        seed = tonumber(seedFile:read())
        io.close(seedFile)
    end
    prng.set_seed(seed)
end

function Actions.apRandom(context)
    -- "Counter {0}: Set to a random number between {1} and {2} (inclusive)."
    local counterId = context:getInteger(0)
    local min = context:getInteger(1)
    local max = context:getInteger(2)

    local value = math.floor((prng.get_random_32() % (max - min + 1)) + min)

    context:setMapCounter(0, value)
end

function Actions.apSpawnUnit(context)
    -- "Spawn {5} {0} with colour variation {7} at {1} for {2} facing {8} (silent = {3}, no delay = {4}, random location = {6})."
    local unitClassId = context:getUnitClass(0)
    local location = context:getLocation(1)
    local playerId = context:getPlayerId(2)
    local silent = context:getBoolean(3)
    local noDelay = context:getBoolean(4)
    local spawnCount = context:getInteger(5)
    local randomizeLocation = context:getBoolean(6)
    local skinColour = context:getString(7)
    local facing = context:getString(8)

    Actions.apDoSpawnUnit(spawnCount, unitClassId, playerId, location, silent, noDelay, randomizeLocation, false, skinColour, facing)
end

function Actions.apDoSpawnUnit(spawnCount, unitClassId, playerId, location, silent, noDelay, randomizeLocation, drop, skinColour, facing)
    local droppedUnits = {}

    for i=1, spawnCount, 1 do
        -- Get candidates
        local candidates = findPlaceInLocation(location, unitClassId)

        -- Spawn at the best candidate
        if #candidates > 0 then
            local idx = 1
            if randomizeLocation then
                idx = math.floor((prng.get_random_32() % (#candidates - 1 + 1)) + 1)
            end
            local pos = candidates[idx].pos
            if not silent and not noDelay then
                Wargroove.trackCameraTo(pos)
            end

            if drop then
                local unitId = Wargroove.spawnUnit(playerId, {x=pos.x, y=-5}, unitClassId, false)
                Wargroove.clearCaches()

                Wargroove.moveUnitToOverride(unitId, pos, 0, 0, 15, "pow3In")
                table.insert(droppedUnits, {id=unitId, effectSpawned=false, endPos=pos})
            else
                Wargroove.spawnUnit(playerId, pos, unitClassId, false, "", "", "", false, skinColour, facing or "right")
                Wargroove.clearCaches()
                if (not silent) and Wargroove.canCurrentlySeeTile(pos) then
                    Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")

                    if not noDelay then
                        Wargroove.playMapSound("spawn", pos)
                        Wargroove.waitTime(0.5)
                    else
                        if i==1 then
                            Wargroove.playMapSound("spawn", pos)
                        end
                    end
                end
            end
        end
    end

    if drop and #droppedUnits > 0 then
        local stillDroppping = true

        while stillDroppping do
            stillDroppping = false
            for i=1, #droppedUnits do
                if Wargroove.isLuaMoving(droppedUnits[i].id) then
                    stillDroppping = true
                elseif not droppedUnits[i].effectSpawned then
                    local unit = Wargroove.getUnitById(droppedUnits[i].id)
                    unit.pos = droppedUnits[i].endPos
                    Wargroove.updateUnit(unit)

                    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
                    Wargroove.playMapSound("spawn", unit.pos)
                    droppedUnits[i].effectSpawned = true
                end
            end
            coroutine.yield()
        end
    end
end


--Map Randomization Actions---------------------------------------------------------------------------------------------

function Actions.positionAsymmetricRandomize(context)
    local distance = context:getInteger(0)
    local strongholds = { context:getInteger(1), context:getInteger(1) }
    local barracks = { context:getInteger(2), context:getInteger(2) }
    local towers = { context:getInteger(3), context:getInteger(3) }
    local hideouts = { context:getInteger(4), context:getInteger(4) }
    local ports = { context:getInteger(5), context:getInteger(5) }
    local playerVillages = { context:getInteger(6), context:getInteger(6) }
    local neutralVillages = { context:getInteger(7), context:getInteger(7) }
    local neutralProduction = { context:getInteger(8), context:getInteger(8) }

    local two_player_half_angle = math.rad(120)
    local four_player_quadrant_angle = math.rad(60)
    local percent_stronghold = { small=0.50, large=0.60 }
    local percent_production = { small=0.80, large=1.0 }
    local stronghold_loc = {positions={}}
    local production_loc = {positions={}}
    local size = Wargroove.getMapSize()
    local whole_map = {positions={}}
    local players = Wargroove.getNumPlayers(true)
    local halfX = (size.x - 1) / 2.0
    local halfY = (size.y - 1) / 2.0
    local small = size.x
    local large = size.y
    local isXSmall = true
    if large < small then
        local temp = small
        small = large
        large = temp
        isXSmall = false
    end
    for x=0,size.x do
        for y=0,size.y do
            if x ~= halfX or y ~= halfY - 1 then
                table.insert(whole_map.positions, {x=x, y=y})
                local smallStrongholdX = percent_stronghold.small * halfX
                local smallStrongholdY = percent_stronghold.small * halfY
                local smallProductionX = percent_production.small * halfX
                local smallProductionY = percent_production.small * halfY
                local largeStrongholdX = percent_stronghold.large * halfX
                local largeStrongholdY = percent_stronghold.large * halfY
                local largeProductionX = percent_production.large * halfX
                local largeProductionY = percent_production.large * halfY

                local angle = math.atan(halfY - y, halfX - x)
                local posDistance = math.sqrt((halfX - x)*(halfX - x) + (halfY - y) * (halfY - y))
                local minX = smallStrongholdX * math.cos(angle)
                local minY = smallStrongholdY * math.sin(angle)
                local minDistance = math.sqrt(minX * minX + minY * minY)
                local maxX = largeStrongholdX * math.cos(angle)
                local maxY = largeStrongholdY * math.sin(angle)
                local maxDistance = math.sqrt(maxX * maxX + maxY * maxY)
                if posDistance >= minDistance and posDistance < maxDistance then
                    table.insert(stronghold_loc.positions, {x=x, y=y})
                end
                minX = smallProductionX * math.cos(angle)
                minY = smallProductionY * math.sin(angle)
                minDistance = math.sqrt(minX * minX + minY * minY)
                maxX = largeProductionX * math.cos(angle)
                maxY = largeProductionY * math.sin(angle)
                maxDistance = math.sqrt(maxX * maxX + maxY * maxY)
                if posDistance >= minDistance and posDistance < maxDistance then
                    table.insert(production_loc.positions, {x=x, y=y})
                end
            end
        end
    end

    while #(stronghold_loc.positions) > 0 do
        if strongholds[1] <= 0 and strongholds[2] <=0 then
            break
        end
        local rand = (prng.get_random_32() % #(stronghold_loc.positions)) + 1
        local q1Pos = stronghold_loc.positions[rand]
        local p1Pos
        local p2Pos
        table.remove(stronghold_loc.positions, rand)
        local angle = (math.atan(halfY - q1Pos.y, halfX - q1Pos.x) + (math.pi * 2)) % (math.pi * 2)
        if angle < two_player_half_angle and angle >= math.pi - two_player_half_angle then
            p1Pos = q1Pos
        elseif angle >= (math.pi * 2) - two_player_half_angle and angle < math.pi + two_player_half_angle then
            p2Pos = q1Pos
        end
        if p1Pos ~= nil and strongholds[1] > 0 and Wargroove.canStandAt("hq", p1Pos) then
            Wargroove.spawnUnit(0, p1Pos, "hq", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            removePositionsAroundElement(stronghold_loc.positions, p1Pos, distance)
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
            strongholds[1] = strongholds[1] - 1
        end
        if p2Pos ~= nil and strongholds[2] > 0 and Wargroove.canStandAt("hq", p2Pos) then
            Wargroove.spawnUnit(1, p2Pos, "hq", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            removePositionsAroundElement(stronghold_loc.positions, p2Pos, distance)
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
            strongholds[2] = strongholds[2] - 1
        end
    end

    while #(production_loc.positions) > 0 do
        if barracks[1] <= 0 and towers[1] <= 0 and hideouts[1] <= 0 and ports[1] <= 0
                and barracks[2] <= 0 and towers[2] <= 0 and hideouts[2] <= 0 and ports[2] <= 0 then
            break
        end
        local rand = (prng.get_random_32() % #(production_loc.positions)) + 1
        local q1Pos = production_loc.positions[rand]
        local p1Pos
        local p2Pos
        table.remove(production_loc.positions, rand)
        local angle = (math.atan(halfY - q1Pos.y, halfX - q1Pos.x) + (math.pi * 2)) % (math.pi * 2)
        if angle < two_player_half_angle then
            p1Pos = q1Pos
        elseif angle >= (math.pi * 2) - two_player_half_angle then
            p2Pos = q1Pos
        end
        if p1Pos ~= nil and Wargroove.canStandAt("barracks", p1Pos) and barracks[1] > 0 then
            Wargroove.spawnUnit(0, p1Pos, "barracks", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            barracks[1] = barracks[1] - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
        elseif p2Pos ~= nil and Wargroove.canStandAt("barracks", p2Pos) and barracks[2] > 0 then
            Wargroove.spawnUnit(1, p2Pos, "barracks", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            barracks[2] = barracks[2] - 1
            removePositionsAroundElement(production_loc.positions, p2Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        elseif p1Pos ~= nil and Wargroove.canStandAt("tower", p1Pos) and towers[1] > 0 then
            Wargroove.spawnUnit(0, p1Pos, "tower", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            towers[1] = towers[1] - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
        elseif p2Pos ~= nil and Wargroove.canStandAt("tower", p2Pos) and towers[2] > 0 then
            Wargroove.spawnUnit(1, p2Pos, "tower", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            towers[2] = towers[2] - 1
            removePositionsAroundElement(production_loc.positions, p2Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        elseif p1Pos ~= nil and Wargroove.canStandAt("hideout", p1Pos) and hideouts[1] > 0 then
            Wargroove.spawnUnit(0, p1Pos, "hideout", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            hideouts[1] = hideouts[1] - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, distance)
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
        elseif p2Pos ~= nil and Wargroove.canStandAt("hideout", p2Pos) and hideouts[2] > 0 then
            Wargroove.spawnUnit(1, p2Pos, "hideout", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            hideouts[2] = hideouts[2] - 1
            removePositionsAroundElement(production_loc.positions, p2Pos, distance)
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        elseif p1Pos ~= nil and Wargroove.canStandAt("port", p1Pos) and ports[1] > 0 then
            Wargroove.spawnUnit(0, p1Pos, "port", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            ports[1] = ports[1] - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
        elseif p2Pos ~= nil and Wargroove.canStandAt("port", p2Pos) and ports[2] > 0 then
            Wargroove.spawnUnit(1, p2Pos, "port", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            ports[2] = ports[2] - 1
            removePositionsAroundElement(production_loc.positions, p2Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        end
    end

    while #(whole_map.positions) > 0 do
        if neutralVillages[1] <= 0 and playerVillages[1] <=0 and neutralProduction[1] <=0 and
                neutralVillages[2] <= 0 and playerVillages[2] <=0 and neutralProduction[2] <=0 then
            break
        end
        local rand = (prng.get_random_32() % #(whole_map.positions)) + 1
        local randomProduction = (prng.get_random_32() % 4) + 0
        local productionClass = "barracks"
        if randomProduction == 0 then
            productionClass = "barracks"
        elseif randomProduction == 1 then
            productionClass = "tower"
        elseif randomProduction == 2 then
            productionClass = "port"
        elseif randomProduction == 3 then
            productionClass = "hideout"
        end
        local v1Pos = whole_map.positions[rand]
        table.remove(whole_map.positions, rand)
        local playerId = 1
        if v1Pos.y < halfY then
            playerId = 0
        end
        if Wargroove.getUnitAt(v1Pos) == nil then
            if Wargroove.canStandAt("city", v1Pos) and neutralVillages[playerId + 1] > 0 then
                Wargroove.spawnUnit(-1, v1Pos, "city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralVillages[playerId + 1] = neutralVillages[playerId + 1] - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
            elseif Wargroove.canStandAt("water_city", v1Pos) and neutralVillages[playerId + 1] > 0 then
                Wargroove.spawnUnit(-1, v1Pos, "water_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralVillages[playerId + 1] = neutralVillages[playerId + 1] - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
            elseif Wargroove.canStandAt("river_city", v1Pos) and neutralVillages[1] > 0 then
                Wargroove.spawnUnit(-1, v1Pos, "river_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralVillages[playerId + 1] = neutralVillages[playerId + 1] - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
            elseif Wargroove.canStandAt("city", v1Pos) and playerVillages[playerId + 1] > 0 then
                Wargroove.spawnUnit(playerId, v1Pos, "city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                local unit = Wargroove.getUnitAt(v1Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                playerVillages[playerId + 1] = playerVillages[playerId + 1] - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
            elseif Wargroove.canStandAt("water_city", v1Pos) and playerVillages[playerId + 1] > 0 then
                Wargroove.spawnUnit(playerId, v1Pos, "water_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                local unit = Wargroove.getUnitAt(v1Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                playerVillages[playerId + 1] = playerVillages[playerId + 1] - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
            elseif Wargroove.canStandAt("river_city", v1Pos) and playerVillages[playerId + 1] > 0 then
                Wargroove.spawnUnit(playerId, v1Pos, "river_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                local unit = Wargroove.getUnitAt(v1Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                playerVillages[playerId + 1] = playerVillages[playerId + 1] - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
            elseif Wargroove.canStandAt(productionClass, v1Pos) and neutralProduction[playerId + 1] > 0 then
                Wargroove.spawnUnit(-1, v1Pos, productionClass, false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralProduction[playerId + 1] = neutralProduction[playerId + 1] - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
            end
        end
    end
end

function Actions.positionRandomize(context)
    local distance = context:getInteger(0)
    local strongholds = context:getInteger(1)
    local barracks = context:getInteger(2)
    local towers = context:getInteger(3)
    local hideouts = context:getInteger(4)
    local ports = context:getInteger(5)
    local playerVillages = context:getInteger(6)
    local neutralVillages = context:getInteger(7)
    local neutralProduction = context:getInteger(8)

    local two_player_half_angle = math.rad(120)
    local four_player_quadrant_angle = math.rad(60)
    local percent_stronghold = { small=0.50, large=0.60 }
    local percent_production = { small=0.80, large=1.0 }
    local stronghold_loc = {positions={}}
    local production_loc = {positions={}}
    local size = Wargroove.getMapSize()
    local whole_map = {positions={}}
    local players = Wargroove.getNumPlayers(true)
    local halfX = (size.x - 1) / 2.0
    local halfY = (size.y - 1) / 2.0
    local small = size.x
    local large = size.y
    local isXSmall = true
    if large < small then
        local temp = small
        small = large
        large = temp
        isXSmall = false
    end
    for x=0,size.x do
        for y=0,size.y do
            if x ~= (size.x / 2.0) - 1 or y ~= (size.y / 2.0) - 1 then
                table.insert(whole_map.positions, {x=x, y=y})
                local smallStrongholdX = percent_stronghold.small * halfX
                local smallStrongholdY = percent_stronghold.small * halfY
                local smallProductionX = percent_production.small * halfX
                local smallProductionY = percent_production.small * halfY
                local largeStrongholdX = percent_stronghold.large * halfX
                local largeStrongholdY = percent_stronghold.large * halfY
                local largeProductionX = percent_production.large * halfX
                local largeProductionY = percent_production.large * halfY

                local angle = math.atan(halfY - y, halfX - x)
                local posDistance = math.sqrt((halfX - x)*(halfX - x) + (halfY - y) * (halfY - y))
                local minX = smallStrongholdX * math.cos(angle)
                local minY = smallStrongholdY * math.sin(angle)
                local minDistance = math.sqrt(minX * minX + minY * minY)
                local maxX = largeStrongholdX * math.cos(angle)
                local maxY = largeStrongholdY * math.sin(angle)
                local maxDistance = math.sqrt(maxX * maxX + maxY * maxY)
                if posDistance >= minDistance and posDistance < maxDistance then
                    table.insert(stronghold_loc.positions, {x=x, y=y})
                end
                minX = smallProductionX * math.cos(angle)
                minY = smallProductionY * math.sin(angle)
                minDistance = math.sqrt(minX * minX + minY * minY)
                maxX = largeProductionX * math.cos(angle)
                maxY = largeProductionY * math.sin(angle)
                maxDistance = math.sqrt(maxX * maxX + maxY * maxY)
                if posDistance >= minDistance and posDistance < maxDistance then
                    table.insert(production_loc.positions, {x=x, y=y})
                end
            end
        end
    end

    while #(stronghold_loc.positions) > 0 do
        if strongholds <= 0 then
            break
        end
        local rand = (prng.get_random_32() % #(stronghold_loc.positions)) + 1
        local q1Pos = stronghold_loc.positions[rand]
        local q2Pos = {x=(size.x - q1Pos.x - 1) % size.x, y=(size.y - q1Pos.y - 1) % size.y}
        local p1Pos = {x=-1,y=-1}
        local p2Pos = {x=-1,y=-1}
        table.remove(stronghold_loc.positions, rand)
        removeElementFromListXY(stronghold_loc.positions, q2Pos)
        local angle = (math.atan(halfY - q1Pos.y, halfX - q1Pos.x) + (math.pi * 2)) % (math.pi * 2)
        if angle < two_player_half_angle and angle >= math.pi - two_player_half_angle then
            p1Pos = q1Pos
            p2Pos = q2Pos
        elseif angle >= (math.pi * 2) - two_player_half_angle and angle < math.pi + two_player_half_angle then
            p1Pos = q2Pos
            p2Pos = q1Pos
        end
        if Wargroove.canStandAt("hq", p1Pos) then
            Wargroove.spawnUnit(0, p1Pos, "hq", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            Wargroove.spawnUnit(1, p2Pos, "hq", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            strongholds = strongholds - 1
            removePositionsAroundElement(stronghold_loc.positions, q1Pos, distance)
            removePositionsAroundElement(stronghold_loc.positions, q2Pos, distance)
            removePositionsAroundElement(whole_map.positions, q1Pos, distance)
            removePositionsAroundElement(whole_map.positions, q2Pos, distance)
        end
    end

    while #(production_loc.positions) > 0 do
        if barracks <= 0 and towers <= 0 and hideouts <= 0 and ports <= 0 then
            break
        end
        local rand = (prng.get_random_32() % #(production_loc.positions)) + 1
        local q1Pos = production_loc.positions[rand]
        local q2Pos = {x=(size.x - q1Pos.x - 1) % size.x, y=(size.y - q1Pos.y - 1) % size.y}
        local p1Pos = {x=-1,y=-1}
        local p2Pos = {x=-1,y=-1}
        table.remove(production_loc.positions, rand)
        removeElementFromListXY(production_loc.positions, q2Pos)
        local angle = (math.atan(halfY - q1Pos.y, halfX - q1Pos.x) + (math.pi * 2)) % (math.pi * 2)
        if angle < two_player_half_angle then
            p1Pos = q1Pos
            p2Pos = q2Pos
        elseif angle >= (math.pi * 2) - two_player_half_angle then
            p1Pos = q2Pos
            p2Pos = q1Pos
        end
        if Wargroove.canStandAt("barracks", p1Pos) and barracks > 0 then
            Wargroove.spawnUnit(0, p1Pos, "barracks", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            Wargroove.spawnUnit(1, p2Pos, "barracks", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            barracks = barracks - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(production_loc.positions, p2Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        elseif Wargroove.canStandAt("tower", p1Pos) and towers > 0 then
            Wargroove.spawnUnit(0, p1Pos, "tower", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            Wargroove.spawnUnit(1, p2Pos, "tower", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            towers = towers - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(production_loc.positions, p2Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        elseif Wargroove.canStandAt("hideout", p1Pos) and hideouts > 0 then
            Wargroove.spawnUnit(0, p1Pos, "hideout", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            Wargroove.spawnUnit(1, p2Pos, "hideout", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            hideouts = hideouts - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, distance)
            removePositionsAroundElement(production_loc.positions, p2Pos, distance)
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        elseif Wargroove.canStandAt("port", p1Pos) and ports > 0 then
            Wargroove.spawnUnit(0, p1Pos, "port", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            Wargroove.spawnUnit(1, p2Pos, "port", false)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
            local unit = Wargroove.getUnitAt(p1Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            unit = Wargroove.getUnitAt(p2Pos)
            unit:setHealth(10, -1)
            Wargroove.updateUnit(unit)
            ports = ports - 1
            removePositionsAroundElement(production_loc.positions, p1Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(production_loc.positions, p2Pos, math.floor(distance * 1.5))
            removePositionsAroundElement(whole_map.positions, p1Pos, distance)
            removePositionsAroundElement(whole_map.positions, p2Pos, distance)
        end
    end
    while #(whole_map.positions) > 0 do
        if neutralVillages <= 0 and playerVillages <=0 and neutralProduction <=0 then
            break
        end
        local rand = (prng.get_random_32() % #(whole_map.positions)) + 1
        local randomProduction = (prng.get_random_32() % 4) + 0
        local productionClass = "barracks"
        if randomProduction == 0 then
            productionClass = "barracks"
        elseif randomProduction == 1 then
            productionClass = "tower"
        elseif randomProduction == 2 then
            productionClass = "port"
        elseif randomProduction == 3 then
            productionClass = "hideout"
        end
        local v1Pos = whole_map.positions[rand]
        local v2Pos = {x=(size.x - v1Pos.x - 1) % size.x, y=(size.y - v1Pos.y - 1) % size.y}
        local p1Pos = {x=-1,y=-1}
        local p2Pos = {x=-1,y=-1}
        if v1Pos.y < halfY then
            p2Pos = v1Pos
            p1Pos = v2Pos
        else
            p1Pos = v1Pos
            p2Pos = v2Pos
        end
        table.remove(whole_map.positions, rand)
        removeElementFromListXY(whole_map.positions, v2Pos)
        if Wargroove.getUnitAt(p1Pos) == nil and Wargroove.getUnitAt(p2Pos) == nil  then
            if Wargroove.canStandAt("city", v1Pos) and neutralVillages > 0 then
                Wargroove.spawnUnit(-1, v1Pos, "city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                Wargroove.spawnUnit(-1, v2Pos, "city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralVillages = neutralVillages - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
                removePositionsAroundElement(whole_map.positions, v2Pos, distance)
            elseif Wargroove.canStandAt("water_city", v1Pos) and neutralVillages > 0 then
                Wargroove.spawnUnit(-1, v1Pos, "water_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                Wargroove.spawnUnit(-1, v2Pos, "water_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralVillages = neutralVillages - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
                removePositionsAroundElement(whole_map.positions, v2Pos, distance)
            elseif Wargroove.canStandAt("river_city", v1Pos) and neutralVillages > 0 then
                Wargroove.spawnUnit(-1, v1Pos, "river_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                Wargroove.spawnUnit(-1, v2Pos, "river_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralVillages = neutralVillages - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
                removePositionsAroundElement(whole_map.positions, v2Pos, distance)
            elseif Wargroove.canStandAt("city", v1Pos) and playerVillages > 0 then
                Wargroove.spawnUnit(0, p1Pos, "city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                Wargroove.spawnUnit(1, p2Pos, "city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                local unit = Wargroove.getUnitAt(p1Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                unit = Wargroove.getUnitAt(p2Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                playerVillages = playerVillages - 1
                removePositionsAroundElement(whole_map.positions, p1Pos, distance)
                removePositionsAroundElement(whole_map.positions, p2Pos, distance)
            elseif Wargroove.canStandAt("water_city", v1Pos) and playerVillages > 0 then
                Wargroove.spawnUnit(0, p1Pos, "water_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                Wargroove.spawnUnit(1, p2Pos, "water_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                local unit = Wargroove.getUnitAt(p1Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                unit = Wargroove.getUnitAt(p2Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                playerVillages = playerVillages - 1
                removePositionsAroundElement(whole_map.positions, p1Pos, distance)
                removePositionsAroundElement(whole_map.positions, p2Pos, distance)
            elseif Wargroove.canStandAt("river_city", v1Pos) and playerVillages > 0 then
                Wargroove.spawnUnit(0, p1Pos, "river_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                Wargroove.spawnUnit(1, p2Pos, "river_city", false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                local unit = Wargroove.getUnitAt(p1Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                unit = Wargroove.getUnitAt(p2Pos)
                unit:setHealth(100, -1)
                Wargroove.updateUnit(unit)
                playerVillages = playerVillages - 1
                removePositionsAroundElement(whole_map.positions, p1Pos, distance)
                removePositionsAroundElement(whole_map.positions, p2Pos, distance)
            elseif Wargroove.canStandAt(productionClass, v1Pos) and neutralProduction > 0 then
                Wargroove.spawnUnit(-1, v1Pos, productionClass, false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                Wargroove.spawnUnit(-1, v2Pos, productionClass, false)
                Wargroove.waitFrame()
                Wargroove.clearCaches()
                neutralProduction = neutralProduction - 1
                removePositionsAroundElement(whole_map.positions, v1Pos, distance)
                removePositionsAroundElement(whole_map.positions, v2Pos, distance)
            end
        end
    end
end

function Actions.mapRandomize(context)
    local location = context:getLocation(0)
    local xScalar = context:getInteger(1)
    local yScalar = xScalar
    local isSymmetric = context:getBoolean(2)
    local hasArchipelago = math.min(math.max(context:getInteger(3), 0), 100)
    local hasOcean = math.min(math.max(context:getInteger(4), 0), 100)
    local hasLand = math.min(math.max(context:getInteger(5), 0), 100)
    local hasForestRoad = math.min(math.max(context:getInteger(6), 0), 100)
    local hasRuins = math.min(math.max(context:getInteger(7), 0), 100)
    local hasRiverBridge = math.min(math.max(context:getInteger(8), 0), 100)
    if (hasArchipelago == 0) and (hasOcean == 0) and (hasLand == 0) and (hasForestRoad == 0)
            and (hasRuins == 0) and (hasRiverBridge == 0) then
        return
    end
    local biome_weights = { archipelago=hasArchipelago, ocean=hasOcean, land=hasLand, forestRoad=hasForestRoad,
                            ruins=hasRuins, riverBridge=hasRiverBridge}
    local max_value = 0
    for key, value in pairs(biome_weights) do
        max_value = max_value + value
    end
    for key, value in pairs(biome_weights) do
        biome_weights[key] = value / max_value
    end
    if xScalar < 0 then
        xScalar = -1.0 / xScalar
    end
    if yScalar < 0 then
        yScalar = -1.0 / yScalar
    end
    local size = Wargroove.getMapSize()
    local halfX = (size.x - 1) / 2.0
    local halfY = (size.y - 1) / 2.0
    -- Check to see if we're in a Skirmish or not. If so, randomize the whole map
    -- This doesn't actually work since skirmishes can have not 4 triggers, but it's something
    if (#Wargroove.getMapTriggers()) == 4 or location == "any" or location == nil then
        location = {positions={}}
        for x=0,size.x do
            for y=0,size.y do
                table.insert(location.positions, {x=x, y=y})
            end
        end
    end
    simplex.Init()
    for _, pos in ipairs(location.positions) do
        local x = pos.x
        local y = pos.y
        local noiseValue = simplex.Noise2DSymmetric(x , y , xScalar, yScalar, 0, isSymmetric)
        noiseValue = (noiseValue + 1.0) / 2.0
        if noiseValue < biome_weights.archipelago then
            Biomes.archipelagoBeachBiome(x, y, isSymmetric)
        elseif noiseValue < biome_weights.archipelago + biome_weights.ocean then
            Biomes.seaBiome(x, y, isSymmetric)
        elseif noiseValue < biome_weights.archipelago + biome_weights.ocean +
                biome_weights.land then
            Biomes.landBiome(x, y, isSymmetric)
        elseif noiseValue < biome_weights.archipelago + biome_weights.ocean + biome_weights.land +
                biome_weights.forestRoad then
            Biomes.forestRoadBiome(x, y, isSymmetric)
        elseif noiseValue < biome_weights.archipelago + biome_weights.ocean + biome_weights.land +
                biome_weights.forestRoad + biome_weights.riverBridge then
            Biomes.bridgeRiver(x, y, isSymmetric)
        elseif noiseValue < biome_weights.archipelago + biome_weights.ocean + biome_weights.land +
                biome_weights.forestRoad + biome_weights.riverBridge + biome_weights.ruins then
            Biomes.ruinsBiome(x, y, isSymmetric)
        end
    end
end

return Actions
