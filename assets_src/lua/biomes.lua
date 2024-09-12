local Wargroove = require "wargroove/wargroove"
local simplex = require "simplex"

local Biomes = {}

Biomes.LAND_BIOME_SHIFT = 1000
Biomes.SEA_BIOME_SHIFT = 2000
Biomes.FOREST_BIOME_SHIFT = 3000
Biomes.RUINS_BIOME_SHIFT = 4000
Biomes.Archipelago_BIOME_SHIFT = 5000
Biomes.RIVER_BIOME_SHIFT = 6000


function Biomes.landBiome(x, y, isSymmetric)
    local noise = simplex.Noise2DSymmetric(x , y , 1.0, 1.0, Biomes.LAND_BIOME_SHIFT, isSymmetric)
    if noise < 0.45 then
        Wargroove.setTerrainType({x=x, y=y}, "plains", false)
    end
    if noise >= 0.45 and noise < 0.80 then
        Wargroove.setTerrainType({x=x, y=y}, "forest", false)
    end
    if noise >= 0.80 and noise < 0.90 then
        Wargroove.setTerrainType({x=x, y=y}, "road", false)
    end
    if noise >= 0.90 then
        Wargroove.setTerrainType({x=x, y=y}, "mountain", false)
    end
end

function Biomes.forestRoadBiome(x, y, isSymmetric)
    local noise = simplex.Noise2DSymmetric(x , y , 1.0, 1.0, Biomes.FOREST_BIOME_SHIFT, isSymmetric)
    if noise < 0.0 then
        Wargroove.setTerrainType({x=x, y=y}, "forest", false)
    end
    if noise >= 0.0 and noise < 0.60 then
        Wargroove.setTerrainType({x=x, y=y}, "road", false)
    end
    if noise >= 0.60 and noise < 0.95 then
        Wargroove.setTerrainType({x=x, y=y}, "plains", false)
    end
    if noise >= 0.95 then
        Wargroove.setTerrainType({x=x, y=y}, "mountain", false)
    end
end

function Biomes.ruinsBiome(x, y, isSymmetric)
    local noise = simplex.Noise2DSymmetric(x , y , 1.0, 1.0, Biomes.RUINS_BIOME_SHIFT, isSymmetric)
    if noise < -0.75 then
        Wargroove.setTerrainType({x=x, y=y}, "cobblestone", false)
    end
    if noise >= -0.75 and noise < 0.0 then
        Wargroove.setTerrainType({x=x, y=y}, "carpet", false)
    end
    if noise >= 0.0 and noise < 0.15 then
        Wargroove.setTerrainType({x=x, y=y}, "wall", false)
    end
    if noise >= 0.15 and noise < 0.50 then
        Wargroove.setTerrainType({x=x, y=y}, "road", false)
    end
    if noise >= 0.50 then
        Wargroove.setTerrainType({x=x, y=y}, "plains", false)
    end
end

function Biomes.seaBiome(x, y, isSymmetric)
    local noise = simplex.Noise2DSymmetric(x , y , 1/5.0, 1/5.0, Biomes.SEA_BIOME_SHIFT, isSymmetric)
    if noise < -0.4 then
        Wargroove.setTerrainType({x=x, y=y}, "sea", false)
    end
    if noise >= -0.4 and noise < 0.4 then
        Wargroove.setTerrainType({x=x, y=y}, "beach", false)
    end
    if noise >= 0.4 and noise < 0.65 then
        Wargroove.setTerrainType({x=x, y=y}, "ocean", false)
    end
    if noise >= 0.65 then
        Wargroove.setTerrainType({x=x, y=y}, "reef", false)
    end
end

function Biomes.archipelagoBeachBiome(x, y, isSymmetric)
    local noise = simplex.Noise2DSymmetric(x , y , 1, 1, Biomes.Archipelago_BIOME_SHIFT, isSymmetric)
    if noise < -0.80 then
        Wargroove.setTerrainType({x=x, y=y}, "reef", false)
    end
    if noise >= -0.80 and noise < -0.60 then
        Wargroove.setTerrainType({x=x, y=y}, "ocean", false)
    end
    if noise >= -0.60 and noise < 0.20 then
        Wargroove.setTerrainType({x=x, y=y}, "beach", false)
    end
    if noise >= 0.20 and noise < 0.60 then
        Wargroove.setTerrainType({x=x, y=y}, "plains", false)
    end
    if noise >= 0.60 and noise < 0.80 then
        Wargroove.setTerrainType({x=x, y=y}, "forest", false)
    end
    if noise >= 0.80 then
        Wargroove.setTerrainType({x=x, y=y}, "mountain", false)
    end
end

function Biomes.bridgeRiver(x, y, isSymmetric)
    local noise = simplex.Noise2DSymmetric(x , y , 1.0, 1.0, Biomes.RIVER_BIOME_SHIFT, isSymmetric)
    if noise < 0.0 then
        Wargroove.setTerrainType({x=x, y=y}, "river", false)
    end
    if noise >= 0.0 and noise < 0.60 then
        Wargroove.setTerrainType({x=x, y=y}, "river", false)
        Wargroove.setTerrainType({x=x, y=y}, "bridge", false)
    end
    if noise >= 0.60 and noise < 0.90 then
        Wargroove.setTerrainType({x=x, y=y}, "plains", false)
    end
    if noise >= 0.90 then
        Wargroove.setTerrainType({x=x, y=y}, "forest", false)
    end
end

return Biomes