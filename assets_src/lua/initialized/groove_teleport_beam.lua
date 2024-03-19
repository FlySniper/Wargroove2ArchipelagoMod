local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Utils = require "utils"
local UnitState = require "unit_state"
local OldTeleportBeam = require "verbs/groove_teleport_beam"

local TeleportBeam = GrooveVerb:new()

local defaultUnits = {"soldier", "dog"}

function TeleportBeam.init()
    OldTeleportBeam.getRecruitableTargets = TeleportBeam.getRecruitableTargets
end

function TeleportBeam:getRecruitableTargets(unit)
    local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local recruitableUnits = {}
    for i, unit in pairs(allUnits) do
        for i, recruit in pairs(unit.recruits) do
            
            if not OldTeleportBeam.recruitsContain(self, recruitableUnits, recruit) then
                if Wargroove.isHuman(unit.playerId) and recruit ~= "dog" and recruit ~= "soldier" then

                    for k, v in pairs(Utils.items) do
                        if v <= Utils.items["rifleman"] then
                            local count = UnitState.getState(k)
                            if recruit == k and tonumber(count) > 0 then
                                recruitableUnits[#recruitableUnits + 1] = recruit
                            end
                        end
                    end
                else
                    recruitableUnits[#recruitableUnits + 1] = recruit
                end
            end
        end
    end

    if #recruitableUnits == 0 then
        recruitableUnits = defaultUnits
    end

    return recruitableUnits
end


return TeleportBeam
