local Wargroove = require "wargroove/wargroove"
local Events = require "initialized/events"
local UnitState = require "unit_state"
local Utils = require "utils"
local io = require "io"

local Conditions = {}

-- This is called by the game when the map is loaded.
function Conditions.init()
  Events.addToConditionsList(Conditions)
end

function Conditions.populate(dst)
    dst["ap_has_item"] = Conditions.apHasItem

    -- Unlisted conditions
    dst["ap_has_death_link"] = Conditions.apHasDeathLink
end

function Conditions.apHasDeathLink(context)
    local playerId = context:getPlayerId(0)
    if Wargroove.isHuman(playerId) then
        local f = io.open("AP\\deathLinkReceive", "r")
        if f ~= nil then
            io.close(f)
            Wargroove.showDialogueBox("neutral", "generic_archer", "Deathlink Received", "", {}, "standard", true)
            Wargroove.eliminate(playerId)
            local file = io.open("AP\\deathLinkReceive", "w+")
            file:write("1")
            io.close(file)
            return true
        end
    end
    return false
end

function Conditions.apHasItem(context)
    -- "Add ap has item {0} of count {1} {2} current count"
    local itemId = context:getInteger(0)
    local itemExpectedCount = context:getInteger(1)
    local op = context:getOperator(2)
    local itemCount = 0
    local f = io.open("AP\\AP_" .. tostring(itemId) .. ".item", "r")
    if f ~= nil then
        itemCount = tonumber(f:read())
        if itemCount == nil then
            io.close(f)
            return false
        end
        io.close(f)
    end
    return op(itemCount, itemExpectedCount)
end

return Conditions
