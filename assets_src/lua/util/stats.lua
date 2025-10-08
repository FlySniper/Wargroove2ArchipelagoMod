local Wargroove = require "wargroove/wargroove"

local Stats = {}
Stats.meleeUnits = {
	commander_emeric = true,
	commander_mercival = true,
	commander_vesper = true,
	commander_wulfar = true,
	dog = true,
	giant = true,
	knight = true,
	soldier = true,
	spearman = true,
	turtle = true,
}
Stats.sightRangeList = {
	archer = 4,
	rival = 4,
	ballista = 4,
	commander_emeric = 4,
	commander_flagship_rival = 4,
	commander_flagship_wulfar = 4,
	commander_mercival = 4,
	commander_vesper = 4,
	commander_wulfar = 4,
	commander_duchess = 4,
	dog = 4,
	dragon = 4,
	flare = 4,
	giant = 4,
	harpoonship = 4,
	harpy = 4,
	knight = 4,
	mage = 4,
	merman = 4,
	pirate_ship = 4,
	pirate_ship_loaded = 4,
	wagon = 4,
	balloon = 4,
	villager = 4,
	rifleman = 4,
	soldier = 4,
	soldier_flanked = 4,
	spearman = 4,
	trebuchet = 4,
	thief = 4,
	thief_with_gold = 4,
	travelboat = 4,
	travelboat_with_gold = 4,
	turtle = 4,
	warship = 4,
	witch = 4,
	reveal_all = 200,
	reveal_all_but_hidden = 200,
	reveal_all_but_over = 200,
	barracks = 1,
	city = 1,
	gate = 1,
	hideout = 1,
	hq = 2,
	statue = 0,
	port = 1,
	tower = 1,
	water_city = 1,
	crew = 0,
	gate_no_los_blocker = 1,
	griffin_walking = 4,
	frog = 4,
	kraken = 4,
	caravel = 4,
}

Stats.scoutList = {
	dog = true,
	turtle = true,
	reveal_all = true,
	flare = true
}

Stats.seeOverList = {
	harpy = true,
	dragon = true,
	reveal_all = true,
	reveal_all_but_hidden = true,
	witch = true
}

Stats.fowCoverList = {
	forest = true,
	reef = true,
	mangrove = true,
	cave_reef = true,
	brush = true,
	brush_invis = true,
	forest_alt = true
}

Stats.visionBlockingList = {
	forest = true,
	mountain = true,
	wall = true,
	building = true,
	mangrove = true,
	forest_alt = true,
	cave_wall = true,
	invisible_blocker_ocean = true
}

function Stats.isScout(unit)
	return Stats.scoutList[unit.unitClassId] ~= nil
end

function Stats.canSeeOver(unit)
	return Stats.seeOverList[unit.unitClassId] ~= nil
end

function Stats.isTerrainFowCover(terrainName)
	return Stats.fowCoverList[terrainName] ~= nil
end
function Stats.isTerrainBlocking(terrainName)
	return Stats.visionBlockingList[terrainName] ~= nil
end

Stats.terrain = {
	abyss = {
		willFall = {
			walking = true,
			riding = true,
			wheels = true,
			airphibious = true,
			amphibious = true,
			sailing = true,
			river_sailing = true,
		},
		cantStop = {airphibious = true}
	},
	plains = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 2,
		amphibious = 2,
		airphibious = 1
	},
	road = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 2,
		airphibious = 1
	},
	forest = {
		walking = 2,
		riding = 3,
		flying = 1,
		hovering = 1,
		amphibious = 4,
		airphibious = 1
	},
	mountain = {
		walking = 3,
		flying = 1,
		hovering = 1,
		airphibious = 1
	},
	cobblestone = {
		walking = 1,
		riding = 1,
		hovering = 1,
		amphibious = 2,
		airphibious = 1
	},
	carpet = {
		walking = 1,
		riding = 1,
		hovering = 1,
		amphibious = 2,
		airphibious = 1
	},
	wall = {
	},
	building = {
	},
	bridge = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 2,
		sailing = 2,
		airphibious = 1,
		river_sailing = 1,
		cantStop = {sailing = true, river_sailing = true}
	},
	sea = {
		sailing = 2,
		flying = 1,
		hovering = 1,
		amphibious = 1,
		airphibious = 1,
		river_sailing = 1,
		willFall = {
			walking = true,
			riding = true,
			wheels = true,
			airphibious = true
		},
		cantStop = {airphibious = true}
	},

	ocean = {
		sailing = 1,
		flying = 1,
		hovering = 1,
		amphibious = 2,
		airphibious = 1,
		river_sailing = 2,
		willFall = {
			walking = true,
			riding = true,
			wheels = true,
			airphibious = true
		},
		cantStop = {airphibious = true}
	},
	reef = {
		sailing = 3,
		flying = 1,
		hovering = 1,
		amphibious = 1,
		airphibious = 1,
		river_sailing = 4,
		willFall = {
			walking = true,
			riding = true,
			wheels = true,
			airphibious = true
		},
		cantStop = {airphibious = true}
	},
	river = {
		walking = 2,
		riding = 4,
		flying = 1,
		hovering = 1,
		amphibious = 1,
		river_sailing = 1,
		airphibious = 1,
		willFall = {
			wheels = true,
		},
	},
	beach = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		amphibious = 2,
		sailing = 3,
		river_sailing = 1,
		airphibious = 1,
		willFall = {
			wheels = true,
		},
	}
}
function Stats.getMovementType(unitClassId)
	local unitClass = Wargroove.getUnitClass(unitClassId)
	return unitClass.movementType
end
function Stats.getMovementCostAtPos(unit, pos)
	local terrainName = Wargroove.getTerrainNameAt(pos)
	if not Wargroove.canStandAt(unit.unitClassId, pos) and Stats.canStopOnTerrain(terrainName, unit.unitClassId) then
		return 100
	end
	return Stats.getTerrainCost(terrainName, unit.unitClassId)
end

function Stats.getTerrainCost(terrainName, unitClassId)
	if Stats.terrain[terrainName] == nil then
		return 100
	end
	local movementType = Stats.getMovementType(unitClassId)
	if Stats.terrain[terrainName][movementType] ~= nil then
		return Stats.terrain[terrainName][movementType]
	end
	return 100
end
function Stats.canStopOnTerrain(terrainName, unitClassId)
	if Stats.terrain[terrainName] == nil then
		return false
	end
	local movementType = Stats.getMovementType(unitClassId)
	if Stats.terrain[terrainName][movementType] ~= nil then
		return not ((Stats.terrain[terrainName]["cantStop"] ~= nil) and (Stats.terrain[terrainName]["cantStop"][movementType] == true))
	end
	return false
end

function Stats.willFallOnTerrain(terrainName, unit)
	if Stats.terrain[terrainName] == nil then
		return false
	end
	if Stats.terrain[terrainName]["willFall"] == nil then
		return false
	end
	local movementType = unit.unitClass.movementType
	return Stats.terrain[terrainName]["willFall"][movementType] == true
end

return Stats
