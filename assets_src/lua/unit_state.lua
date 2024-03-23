local Wargroove = require "wargroove/wargroove"
local UnitState = {}
local globalStateUnitPos = { x = -42, y = -60 }

function UnitState.getState(key)
    local unit = Wargroove.getUnitAt(globalStateUnitPos)
    if unit == nil then
        return 0
    end
    local state = Wargroove.getUnitState(unit, key)
    if state == nil then
        state = 0
    end
    return state
end


function UnitState.setState(key, value)
    local unit = Wargroove.getUnitAt(globalStateUnitPos)
    if unit == nil then
        Wargroove.spawnUnit( -1, globalStateUnitPos, "soldier", true)
        unit = Wargroove.getUnitAt(globalStateUnitPos)
        Wargroove.updateUnit(unit)
        Wargroove.setUnitState(unit, "player_1_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.setUnitState(unit, "player_2_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.setUnitState(unit, "player_3_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.setUnitState(unit, "player_4_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.setUnitState(unit, "player_5_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.setUnitState(unit, "player_6_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.setUnitState(unit, "player_7_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.setUnitState(unit, "player_8_recruits", "soldier,dog,spearman,wagon,mage,archer,knight,ballista,trebuchet,giant,griffin_walking,harpy,witch,dragon,balloon,caravel,travelboat,merman,turtle,harpoonship,frog,kraken,warship,thief,rifleman")
        Wargroove.updateUnit(unit)
    end
    Wargroove.setUnitState(unit, key, value)
    Wargroove.updateUnit(unit)
end

return UnitState