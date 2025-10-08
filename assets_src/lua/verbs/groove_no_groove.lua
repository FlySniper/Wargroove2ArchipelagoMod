local GrooveVerb = require "wargroove/groove_verb"

local noGroove = GrooveVerb:new()


function noGroove:getMaximumRange(unit, endPos)
  return 1
end

function noGroove:canExecuteAnywhere(unit)
    return false
end

function noGroove:getTargetType()
    return "all"
end

function noGroove:execute(unit, targetPos, strParam, path)
end

return noGroove
