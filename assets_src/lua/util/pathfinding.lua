local BinaryHeap = require "util/binary_heap"
local Wargroove = require "wargroove/wargroove"
local Stats = require "util/stats"
local PosKey = require "util/posKey"
local Pathfinding = {}

Pathfinding.__index = Pathfinding
local directions = {{x = 1,y = 0},{x = -1,y = 0},{x = 0,y = 1},{x = 0,y = -1}}
local iterations = 0
local function dump(o,level)
  if type(o) == 'table' then
     local s = '\n' .. string.rep("   ", level) .. '{\n'
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
     end
     return s .. string.rep("   ", level) .. '}'
  else
     return tostring(o)
  end
end

function Pathfinding.guessList(cur, destList)
  local shortest = 100000
  for i,dest in pairs(destList) do
    local dist = Pathfinding.guess(cur, dest)
    if dist<shortest then
      shortest = dist
    end
  end
  return shortest
end
function Pathfinding.guess(cur, dest)
  return Pathfinding.newYorkDistance(cur, dest)
end
function Pathfinding.newYorkDistance(pos1, pos2)
  local newYorkDistance = math.abs(pos1.x-pos2.x)+math.abs(pos1.y-pos2.y)
  return newYorkDistance
end
function Pathfinding.withinBounds(pos)
  local mapSize = Wargroove.getMapSize()
  return (pos.x >= 0) and (pos.y >= 0) and (pos.x < mapSize.x) and (pos.y < mapSize.y)
end

function Pathfinding.tileCost(unitClassId,pos, playerId, ignoreUnits)
    local stranger = Wargroove.getUnitAt(pos)
    if ignoreUnits == nil then
      ignoreUnits = false
    end
    if not Pathfinding.withinBounds(pos) then
        return 1000
    end
    if (playerId ~= nil) and Wargroove.canSeeTile(playerId,pos) and (stranger ~= nil) and Wargroove.areEnemies(playerId, stranger.playerId) and (not ignoreUnits) then
        return 100
    end
    local unit = {}
    unit.pos = {x = pos.x, y = pos.y}
    unit.unitClassId = unitClassId
    local tileCost = Stats.getMovementCostAtPos(unit, pos)
    return tileCost
end

function Pathfinding.canStop(unitClassId,pos,playerId, ignoreUnits)
  local stranger = Wargroove.getUnitAt(pos)
  local mapSize = Wargroove.getMapSize()
  if ignoreUnits == nil then
    ignoreUnits = false
  end
  if (stranger ~= nil) and Wargroove.canSeeTile(playerId,pos) and not ignoreUnits then
    return false
  end
  return Stats.canStopOnTerrain(Wargroove.getTerrainNameAt(pos),unitClassId)
end

function Pathfinding.reconstructPath(cameFrom, dest)
  local pathLength = 0
  local path = {}
  local currentPos = dest
  if cameFrom == nil then
    return path
  end
  if dest == nil then
    return path
  end

  local currentPosKey = PosKey.generatePosKey(currentPos)
  while cameFrom[currentPosKey] ~= nil do
    currentPos = cameFrom[currentPosKey]
    currentPosKey = PosKey.generatePosKey(currentPos)
    pathLength = pathLength + 1
--    path[pathLength] = currentPos
  end
  currentPos = dest
  currentPosKey = PosKey.generatePosKey(currentPos)
  while cameFrom[currentPosKey] ~= nil do
    path[pathLength] = currentPos
    pathLength = pathLength - 1
    currentPos = cameFrom[currentPosKey]
    currentPosKey = PosKey.generatePosKey(currentPos)
  end
  return path
end

function Pathfinding.forceMoveAlongPath(unitId, path, facing)
  local meanPos = {x=0,y=0}
  local count = 0
  
  for id,tile in pairs(path) do
    meanPos.x = meanPos.x + tile.x
    meanPos.y = meanPos.y + tile.y
    count = count + 1
  end
  if count>0 then
      meanPos.x = math.floor(0.5+meanPos.x/count);
      meanPos.y = math.floor(0.5+meanPos.y/count);
      Wargroove.trackCameraTo(meanPos)
  end
  local unit = Wargroove.getUnitById(unitId)
  local lastTile = unit.pos
  for i,tile in ipairs(path) do
    local delta = {x = tile.x-lastTile.x, y = tile.y-lastTile.y}
    if delta.y == 1 then
      Wargroove.playUnitAnimation(unitId,"run_down")
    elseif delta.y == -1 then
      Wargroove.playUnitAnimation(unitId,"run_up")
    else
      Wargroove.playUnitAnimation(unitId,"run")
    end
    if delta.x == 1 then
      Wargroove.setFacingOverride(unitId,"right")
    elseif delta.x == -1 then
      Wargroove.setFacingOverride(unitId,"left")
    end
    Wargroove.moveUnitToOverride(unitId, unit.pos, tile.x-unit.pos.x, tile.y-unit.pos.y, 2.5)
    while Wargroove.isLuaMoving(unitId) do
      coroutine.yield()
    end
    lastTile = tile
  end
  unit.pos = { x = path[#path].x, y = path[#path].y }
  Wargroove.unsetFacingOverride(unitId)
  Wargroove.updateUnit(unit)
--  Wargroove.playUnitAnimation(unitId,"hit")
end

function Pathfinding.isBetter(gScore, tentative_gScore)
  if ((tentative_gScore.dist + tentative_gScore.bonus)<(gScore.dist+gScore.bonus)) then
    return true
  else
    return false
  end
end

local unitIdCache = -1
local pathCache = {}
local cameFromCache = {}
local gScoreCache = {}
local penaltyFunctionCache = {}
local edgeCache = {}

function Pathfinding.reportDeadUnit(unitId)
  local unit = Wargroove.getUnitById(unitId)
  for i,other in pairs(Wargroove.getUnitsAtLocation()) do
    local dist = Pathfinding.newYorkDistance(unit.pos,other.pos)
    if dist<=unit.unitClass.moveRange then
      Pathfinding.clearCache(other.id)
    end
  end
end

function Pathfinding.clearCache(unitId)
  pathCache = {}
  pathCache[unitId] = nil
  cameFromCache = {}
  gScoreCache = {}
  penaltyFunctionCache = {}
  edgeCache = nil
end
function Pathfinding.clearCaches()

  cameFromCache = {}
  gScoreCache = {}
  penaltyFunctionCache = {}
  edgeCache = nil
end


function Pathfinding.AStar(unit, destList, penaltyFunctions)
  if unitIdCache ~= unit.id then
    unitIdCache = unit.id
    Pathfinding.clearCaches()
  end
  if penaltyFunctions == nil then
    penaltyFunctions = {}
  end
  if penaltyFunctions.pathPenaltyId == nil then
    penaltyFunctions.pathPenaltyId = ""
  end
  if penaltyFunctions.posPenaltyId == nil then
    penaltyFunctions.posPenaltyId = ""
  end
  if destList == nil then
    return {unit.pos}
  end
  if next(destList) == nil then
    return {unit.pos}
  end
  local unitClass = Wargroove.getUnitClass(unit.unitClassId)
  if destList.x ~= nil then
    destList = {{x = destList.x, y = destList.y}}
  end
  if cameFromCache == nil then
    cameFromCache = {}
  end
  if gScoreCache == nil then
    gScoreCache = {}
  end
  if penaltyFunctionCache == nil then
    penaltyFunctionCache = {}
  end
  if penaltyFunctions.pathPenaltyId ~= penaltyFunctionCache.pathPenaltyId then
    Pathfinding.clearCache(unit.id)
  elseif penaltyFunctions.posPenaltyId ~= penaltyFunctionCache.posPenaltyId then
    Pathfinding.clearCache(unit.id)
  end
  if pathCache[unit.id]~=nil then
    return pathCache[unit.id]
  end
  penaltyFunctionCache.pathPenaltyId = penaltyFunctions.pathPenaltyId
  penaltyFunctionCache.posPenaltyId = penaltyFunctions.posPenaltyId

  local bestPos = {dist = 100000,pos = nil}
  
  for key,gscore in pairs(gScoreCache) do
    local pos = PosKey.revertPosKey(key)
    local dist = Pathfinding.guessList(pos, destList)
    if dist < bestPos.dist then
      bestPos = {dist = dist,pos = pos}
    end
  end
  local startKey = PosKey.generatePosKey(unit.pos)
  if edgeCache == nil then
    edgeCache = {}
    edgeCache[startKey] = true
  end
  gScoreCache[startKey] = {dist = 0,nWait = 0, bonus = 0}
  local openSet = BinaryHeap()
  for key,value in pairs(edgeCache) do
    local pos = PosKey.revertPosKey(key)
    openSet:insert(Pathfinding.guessList(pos, destList)+gScoreCache[startKey].dist+gScoreCache[startKey].bonus,startKey)
  end
  local plzStop = 0
  while (openSet:empty() == false) do
    iterations = iterations+1
    plzStop = plzStop+1
    local currentScore,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    for i,dest in ipairs(destList) do
      if (currentPos.x == dest.x) and (currentPos.y == dest.y) then
        local path = Pathfinding.reconstructPath(cameFromCache, currentPos)
        pathCache[unit.id] = path
        return path
      end
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      if Pathfinding.withinBounds(newPos) then
        local newPosKey = PosKey.generatePosKey(newPos)
        local ignoreUnits = true
        if gScoreCache[currentPosKey].dist <= unitClass.moveRange then
          ignoreUnits = false
        end
        local turnMovePoints = unitClass.moveRange-(gScoreCache[currentPosKey].dist%unitClass.moveRange)
        local tileCost = Pathfinding.tileCost(unit.unitClassId,newPos,unit.playerId,ignoreUnits)
        local moveCost = tileCost
        local canStand = Pathfinding.canStop(unit.unitClassId,newPos,unit.playerId, ignoreUnits)
        if canStand then
          turnMovePoints = turnMovePoints-gScoreCache[currentPosKey].nWait
        end
        if tileCost>turnMovePoints then --unit have to wait til next turn :(
          moveCost = tileCost+(unitClass.moveRange-turnMovePoints)
        end 
        if tileCost>unitClass.moveRange then --unit can never cross this :(
          moveCost = 100
        end
        if gScoreCache[newPosKey] == nil then
          gScoreCache[newPosKey] = {dist = 100000,nWait = 100000, bonus = 100000}
        end
        local tentative_gScore = {}
        tentative_gScore.dist = gScoreCache[currentPosKey].dist+moveCost
        tentative_gScore.bonus = gScoreCache[currentPosKey].bonus
        tentative_gScore.nWait = gScoreCache[currentPosKey].nWait
        if canStand then
          tentative_gScore.nWait = 0
        else
          tentative_gScore.nWait = gScoreCache[currentPosKey].nWait+moveCost
        end
        if (tentative_gScore.dist%unitClass.moveRange) == 0 then
          if penaltyFunctions["posPenalty"]~=nil then
            tentative_gScore.bonus = tentative_gScore.bonus+penaltyFunctions["posPenalty"](unit,newPos)
          end
        end
        if penaltyFunctions["pathPenalty"]~=nil then
          tentative_gScore.bonus = tentative_gScore.bonus+penaltyFunctions["pathPenalty"](unit,newPos)
        end
        if Pathfinding.isBetter(gScoreCache[newPosKey], tentative_gScore) then
          gScoreCache[newPosKey].dist = tentative_gScore.dist
          gScoreCache[newPosKey].bonus = tentative_gScore.bonus
          gScoreCache[newPosKey].nWait = tentative_gScore.nWait
          local fScore = tentative_gScore.dist+tentative_gScore.bonus+Pathfinding.guessList(newPos, destList)
          cameFromCache[newPosKey] = currentPos
          local dist = Pathfinding.guessList(newPos, destList)
          if dist < bestPos.dist then
            bestPos = {dist = dist,pos = newPos}
          end
          edgeCache[newPosKey] = true
          openSet:insert(fScore,newPosKey)
        end
      end
    end
    edgeCache[currentPosKey] = nil

  end
  local path = Pathfinding.reconstructPath(cameFromCache, bestPos.pos)
  pathCache[unit.id] = path
  return path
end

function Pathfinding.getMoveTiles(unit)
  local openSet = BinaryHeap()
  local unitClass = Wargroove.getUnitClass(unit.unitClassId)
  local gScore = {}
  local availableTiles = {}
  local startKey = PosKey.generatePosKey(unit.pos)
  gScore[startKey] = {dist = 0,nWait = 0, bonus = 0}
  openSet:insert(gScore[startKey],startKey)
  while (openSet:empty() == false) do
    local currentScore,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      if Pathfinding.withinBounds(newPos) and (Pathfinding.newYorkDistance(unit.pos,newPos) <= unitClass.moveRange) then
        local newPosKey = PosKey.generatePosKey(newPos)
        local turnMovePoints = unitClass.moveRange-(gScore[currentPosKey].dist%unitClass.moveRange)
        local tileCost = Pathfinding.tileCost(unit.unitClassId,newPos,unit.playerId,false)
        local moveCost = tileCost
        local canStand = Pathfinding.canStop(unit.unitClassId,newPos,unit.playerId, false)
        if canStand then
          turnMovePoints = turnMovePoints-gScore[currentPosKey].nWait
        end
        if tileCost>turnMovePoints then --unit have to wait til next turn :(
          moveCost = tileCost+(unitClass.moveRange-turnMovePoints)
        end 
        if tileCost>unitClass.moveRange then --unit can never cross this :(
          moveCost = 100
        end
        if gScore[newPosKey] == nil then
          gScore[newPosKey] = {dist = 100000,nWait = 100000, bonus = 100000}
        end
        local tentative_gScore = {}
        tentative_gScore.dist = gScore[newPosKey].dist
        tentative_gScore.bonus = gScore[newPosKey].bonus
        tentative_gScore.nWait = gScore[newPosKey].nWait
        tentative_gScore.dist = gScore[currentPosKey].dist+moveCost
        if canStand then
          tentative_gScore.nWait = 0
        else
          tentative_gScore.nWait = gScore[currentPosKey].nWait+moveCost
        end
        if Pathfinding.isBetter(gScore[newPosKey], tentative_gScore) then
          gScore[newPosKey].dist = tentative_gScore.dist
          gScore[newPosKey].bonus = tentative_gScore.bonus
          gScore[newPosKey].nWait = tentative_gScore.nWait
          if gScore[newPosKey].dist<=unitClass.moveRange then
            availableTiles[newPosKey] = gScore[newPosKey].dist
            openSet:insert(gScore[newPosKey].dist+gScore[newPosKey].bonus,newPosKey)
          end
        end
      end
    end

  end
  return availableTiles
end

function Pathfinding.getDistanceToLocationMap(centerPos, range, location)

  local openSet = BinaryHeap()
  local distMap = {}
  for i, pos in ipairs(location) do
      local startKey = PosKey.generatePosKey(pos)
      distMap[startKey] = 0
      openSet:insert(distMap[startKey],startKey)
  end
  while (openSet:empty() == false) do
    local currentScore,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      if Pathfinding.withinBounds(newPos) and (Pathfinding.newYorkDistance(centerPos,newPos) <= range) then
        local newPosKey = PosKey.generatePosKey(newPos)
        if distMap[newPosKey] == nil then
          distMap[newPosKey] = 1000
        end
        local tentative_gScore = distMap[currentPosKey]+1
        if distMap[newPosKey] > tentative_gScore then
          distMap[newPosKey] = tentative_gScore
          openSet:insert(distMap[newPosKey],newPosKey)
        end
      end
    end

  end
  return distMap
end



function Pathfinding.findClosestOpenSpot(unitClassId, start)
  local openSet = BinaryHeap()
  local startKey = PosKey.generatePosKey(start)
  local gScore = {}
  gScore[startKey] = 0

  openSet:insert(0,startKey)
  while openSet:empty() == false do
    local currentPosKey
    _,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    if Wargroove.getUnitAt(currentPos) == nil then
      return currentPos
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      local newPosKey = PosKey.generatePosKey(newPos)
      local tentative_gScore = gScore[currentPosKey] + Pathfinding.tileCost(unitClassId,newPos,nil, false)
      
      --Prioritise Roads and bridges
      if Wargroove.getTerrainNameAt(newPos) == "road" or Wargroove.getTerrainNameAt(newPos) == "bridge" then
        tentative_gScore = tentative_gScore -0.01
      end
      if gScore[newPosKey] == nil and Pathfinding.withinBounds(newPos) then
        gScore[newPosKey] = tentative_gScore
        openSet:insert(gScore[newPosKey],newPosKey)
      end
    end

  end
  return nil
end

function Pathfinding.findClosestEnemy(unit)
  local openSet = BinaryHeap()
  local startKey = PosKey.generatePosKey(unit.pos)
  local gScore = {}
  gScore[startKey] = 0

  openSet:insert(0,startKey)
  while openSet:empty() == false do
    local currentPosKey
    _,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    local target = Wargroove.getUnitAt(currentPos)
    if (target ~= nil) and Wargroove.areEnemies(unit.playerId,target.playerId) then
      return currentPos
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      local newPosKey = PosKey.generatePosKey(newPos)
      local tentative_gScore = gScore[currentPosKey] + Pathfinding.tileCost(unit.unitClassId,newPos,nil, false)
      if gScore[newPosKey] == nil and Pathfinding.withinBounds(newPos) then
        gScore[newPosKey] = tentative_gScore
        openSet:insert(gScore[newPosKey],newPosKey)
      end
    end

  end
  return nil
end

local lastIterations = 0
function Pathfinding.printIterations()
  print("Pathfinding iterations: " .. tostring(iterations-lastIterations))
  lastIterations = iterations
end

return Pathfinding
