-- =============================================================================
-- BATTLEFIELD GENERATION
-- All spawning logic for ground units. Sections follow the order of the
-- generation sequence in OperationInfinity.lua; each starts with its batched
-- entry point. Frontline fire control, which runs after generation, is last.
-- =============================================================================

-- Guard against multiple script loads
if _G.BattlefieldGenerationLoaded then
    env.info("[BattlefieldGeneration] Script already loaded, skipping")
    return
end
_G.BattlefieldGenerationLoaded = true

BattlefieldGeneration = {}

-- Named constants
local SHORAD_OFFSET_BASE_METERS = 1000
local SHORAD_OFFSET_VARIANCE_METERS = 500
local FIRE_OFFSET_RADIUS_METERS = 50
local FIRE_EXPENDITURE_QUANTITY = 200
local CONVOY_SPACING_METERS = 20
local ARTILLERY_SPACING_METERS = 40
-- Meters behind the gun line for the ammo truck row, close enough for the
-- trucks to rearm the guns
local AMMO_TRUCK_ROW_OFFSET_METERS = 60
-- Anchor points tried per target group. The layout search only covers a few
-- hundred meters around each anchor, and anchors near the coast or in forest
-- often have no valid ground in that radius.
local PLACEMENT_ATTEMPTS = 8

local log = Logging:create("BattlefieldGeneration")

-- =============================================================================
-- SHARED PLACEMENT HELPERS
-- =============================================================================

-- Calls place(anchor) with a new anchor from pickAnchor() until place returns
-- a position. Returns place's position and units, or nil.
local function placeWithRetries(pickAnchor, place)
    for _ = 1, PLACEMENT_ATTEMPTS do
        local pos, units = place(pickAnchor())
        if pos then
            return pos, units
        end
    end
    return nil
end

-- Random point minDist-maxDist meters from a random aerodrome in the list
local function randomPointNearRandomAerodrome(aerodromes, minDist, maxDist)
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local angle = math.random() * 2 * math.pi
    local distance = minDist + math.random() * (maxDist - minDist)
    return {
        x = aerodrome.x + distance * math.cos(angle),
        y = aerodrome.y + distance * math.sin(angle),
    }
end

-- Build a logistics convoy as a column following the road from a road point.
-- Returns an empty list if the road direction cannot be found.
local function buildRoadConvoyUnits(roadPos)
    local template = Formations:randomizeTemplate(UnitTemplates.LogisticsConvoy)
    local unitCount = 0
    for _, def in ipairs(template) do
        unitCount = unitCount + def.count
    end

    local column = Terrain:getRoadColumn(roadPos, unitCount, CONVOY_SPACING_METERS)
    local units = {}
    for _, def in ipairs(template) do
        for _ = 1, def.count do
            local slot = column[#units + 1]
            if not slot then
                return units
            end
            units[#units + 1] = {
                type = def.type,
                x = slot.x,
                y = slot.y,
                heading = slot.heading,
                skill = "High",
            }
        end
    end
    return units
end

-- =============================================================================
-- FRONTLINE
-- =============================================================================

-- Batched version of generateFrontline
function BattlefieldGeneration:generateFrontlineBatched(onComplete)
    -- Check if this region has noFrontline constraint (e.g., Tbilisi deep strike)
    local constraints = OperationInfinity.state.battlefield.spawnConstraints
    if constraints and constraints.noFrontline then
        log("Skipping frontline generation - noFrontline constraint active (deep strike zone)")
        if onComplete then
            onComplete()
        end
        return
    end

    -- Generate the coherent frontline (all platoons along a single line)
    self:generateFrontline()

    if onComplete then
        onComplete()
    end
end

function BattlefieldGeneration:generateFrontline()
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Calculate target centroid (center of all target aerodromes)
    local aerodromes = state.battlefield.targetAerodromes
    local centroid = { x = 0, y = 0 }
    for _, aerodrome in ipairs(aerodromes) do
        centroid.x = centroid.x + aerodrome.x
        centroid.y = centroid.y + aerodrome.y
    end
    centroid.x = centroid.x / #aerodromes
    centroid.y = centroid.y / #aerodromes

    -- Calculate approach direction from Krymsk to target centroid
    local homeAirbase = OperationInfinity.state.homeAirbase
    local dx = centroid.x - homeAirbase.x
    local dy = centroid.y - homeAirbase.y
    local approachDist = math.sqrt(dx * dx + dy * dy)
    local approachDir = { x = dx / approachDist, y = dy / approachDist }

    -- Frontline axis is perpendicular to approach direction (rotate 90 degrees)
    local frontlineAxis = { x = -approachDir.y, y = approachDir.x }

    -- Frontline center: positioned between player base and targets
    -- Use constraints if available, otherwise use battlefieldDistance
    local constraints = state.battlefield.spawnConstraints
    local frontlineDistance
    if constraints and constraints.minDistance and constraints.maxDistance then
        frontlineDistance = (constraints.minDistance + constraints.maxDistance) / 2
    else
        frontlineDistance = (config.battlefieldDistance.min + config.battlefieldDistance.max) / 2
    end

    -- Position frontline at specified distance from target centroid, toward player
    local frontlineCenter = {
        x = centroid.x - approachDir.x * frontlineDistance,
        y = centroid.y - approachDir.y * frontlineDistance,
    }

    -- Store frontline geometry in state
    state.battlefield.frontline.center = frontlineCenter
    state.battlefield.frontline.axis = frontlineAxis
    state.battlefield.frontline.approachDir = approachDir

    -- Determine number of platoons
    local numPlatoons = math.random(config.frontline.platoonCountMin, config.frontline.platoonCountMax)

    log("Generating coherent frontline with " .. numPlatoons .. " platoons")
    log("Frontline center: (" .. math.floor(frontlineCenter.x) .. ", " .. math.floor(frontlineCenter.y) .. ")")

    -- Calculate total frontline length and starting position
    -- Use average spacing to estimate total length, then center it
    local avgSpacing = (config.frontline.platoonSpacingMin + config.frontline.platoonSpacingMax) / 2
    local totalLength = (numPlatoons - 1) * avgSpacing
    local currentOffset = -totalLength / 2

    -- Generate platoons along the frontline
    for i = 1, numPlatoons do
        -- Add random wobble perpendicular to frontline
        local wobble = (math.random() - 0.5) * 2 * config.frontline.wobbleMax

        -- Calculate initial position along frontline
        local initialPos = {
            x = frontlineCenter.x + frontlineAxis.x * currentOffset + approachDir.x * wobble,
            y = frontlineCenter.y + frontlineAxis.y * currentOffset + approachDir.y * wobble,
        }

        -- Search for valid flat terrain
        local validPos, isValid = Terrain:findValidPosition(initialPos, config.frontline.terrainSearchRadius)

        if isValid then
            self:generateFrontlinePlatoon(validPos, i)
            -- Store ISAF position for FEBA visualization
            state.battlefield.frontline.isafPositions[#state.battlefield.frontline.isafPositions + 1] = validPos
            log("Platoon " .. i .. " at (" .. math.floor(validPos.x) .. ", " .. math.floor(validPos.y) .. ")")
        else
            log(
                "Skipping platoon "
                    .. i
                    .. " - no valid terrain at ("
                    .. math.floor(initialPos.x)
                    .. ", "
                    .. math.floor(initialPos.y)
                    .. ")"
            )
        end

        -- Advance along frontline by random spacing for next platoon
        local spacing = math.random(config.frontline.platoonSpacingMin, config.frontline.platoonSpacingMax)
        currentOffset = currentOffset + spacing
    end

    -- Generate SHORAD positions along the frontline (behind enemy lines)
    self:generateFrontlineSHORAD()
end

function BattlefieldGeneration:generateFrontlinePlatoon(position, index)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Use the stored approach direction to determine engagement orientation
    local approachDir = state.battlefield.frontline.approachDir

    -- Randomized engagement distance (300-1000m)
    local engageDist = math.random(config.frontline.engagementDistanceMin, config.frontline.engagementDistanceMax)

    -- ISAF position (friendly side, toward Krymsk)
    local isafPos = {
        x = position.x - approachDir.x * (engageDist / 2),
        y = position.y - approachDir.y * (engageDist / 2),
    }

    -- Erusea position (enemy side, toward targets)
    local eruseaPos = {
        x = position.x + approachDir.x * (engageDist / 2),
        y = position.y + approachDir.y * (engageDist / 2),
    }

    -- Find valid terrain for Erusea platoon
    local eruseaValidPos, eruseaValid = Terrain:findValidPosition(eruseaPos, 100)
    if not eruseaValid then
        log("Skipping Erusea platoon " .. index .. " - no valid terrain")
        return
    end

    -- Select formation
    local formation = Formations:getRandomFormationType()

    -- Find valid terrain for the ISAF platoon, facing the Erusea platoon
    local isafTemplate = Formations:randomizeTemplate(UnitTemplates.ISAFPlatoon)
    local isafValidPos, isafUnits = Terrain:findValidLayout(isafPos, 100, function(candidate)
        return Formations:buildPlatoonUnits(isafTemplate, candidate, {
            formation = formation,
            facing = math.atan2(eruseaValidPos.y - candidate.y, eruseaValidPos.x - candidate.x),
            widthMultiplier = 2.5,
        })
    end)
    if not isafValidPos then
        log("Skipping ISAF platoon " .. index .. " - no valid terrain")
        return
    end

    -- Calculate direction vector for fire offset
    local dx = eruseaValidPos.x - isafValidPos.x
    local dy = eruseaValidPos.y - isafValidPos.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local dirX = dx / dist
    local dirY = dy / dist
    local fireOffset = config.frontline.fireOffset

    -- Build multiple Erusea platoons
    local numEruseaPlatoons = math.random(config.frontline.enemyPlatoonsMin, config.frontline.enemyPlatoonsMax)
    local diff = state.difficulty
    local spreadRadius = config.frontline.enemySpreadRadius
    local eruseaGroups = {}

    for e = 1, numEruseaPlatoons do
        -- The first platoon searches around the Erusea position, the rest
        -- spread out from it
        local eruseaSearchPos, eruseaSearchRadius = eruseaValidPos, 100
        if e > 1 then
            local spreadAngle = (e - 1) * (math.pi / 3)
            eruseaSearchPos = {
                x = eruseaValidPos.x + spreadRadius * math.cos(spreadAngle),
                y = eruseaValidPos.y + spreadRadius * 0.5 * math.sin(spreadAngle),
            }
            eruseaSearchRadius = 50
        end

        local baseEruseaTemplate = UnitTemplates.EruseaPlatoon[diff] or UnitTemplates.EruseaPlatoon.Normal
        local eruseaTemplate = Formations:randomizeTemplate(baseEruseaTemplate)
        local eruseaSpreadPos, eruseaUnits = Terrain:findValidLayout(
            eruseaSearchPos,
            eruseaSearchRadius,
            function(candidate)
                return Formations:buildPlatoonUnits(eruseaTemplate, candidate, {
                    formation = formation,
                    facing = math.atan2(isafValidPos.y - candidate.y, isafValidPos.x - candidate.x),
                    widthMultiplier = 2.5,
                })
            end
        )

        if eruseaSpreadPos then
            -- Invisible so the ISAF platoon cannot target it: WEAPON_HOLD does
            -- not stop ground units from engaging targets while a FireAtPoint
            -- task runs. Players still see and attack it, and its air defense
            -- still engages aircraft.
            eruseaGroups[#eruseaGroups + 1] = Virtualization:registerGroup({
                name = "Erusea-F" .. index .. "-" .. e,
                center = eruseaSpreadPos,
                units = eruseaUnits,
                countryId = country.id.CJTF_RED,
                category = Group.Category.GROUND,
            }, {
                immortal = false,
                invisible = true,
                fireAtPoint = {
                    x = isafValidPos.x - dirX * fireOffset,
                    y = isafValidPos.y - dirY * fireOffset,
                    radius = FIRE_OFFSET_RADIUS_METERS,
                    expendQty = FIRE_EXPENDITURE_QUANTITY,
                },
            })
        else
            log("Skipping Erusea platoon " .. index .. "-" .. e .. " - no valid terrain")
        end
    end

    -- ISAF group is scenery: immortal and invisible, firing past the Erusea
    -- platoons so players get the kills. With no Erusea platoons it is
    -- still placed for ambiance but holds fire.
    local fireAtPoint
    if #eruseaGroups > 0 then
        fireAtPoint = {
            x = eruseaValidPos.x + dirX * fireOffset,
            y = eruseaValidPos.y + dirY * fireOffset,
            radius = FIRE_OFFSET_RADIUS_METERS,
            expendQty = FIRE_EXPENDITURE_QUANTITY,
        }
    else
        log("ISAF platoon " .. index .. " has no Erusea platoons; it will not fire")
    end
    local isafGroup = Virtualization:registerGroup({
        name = "ISAF-F" .. index,
        center = isafValidPos,
        units = isafUnits,
        countryId = country.id.CJTF_BLUE,
        category = Group.Category.GROUND,
    }, {
        immortal = true,
        invisible = true,
        holdFire = true,
        fireAtPoint = fireAtPoint,
    })
    -- updateFireTargets ceases fire once all of these are destroyed
    if isafGroup then
        isafGroup.fireTargets = eruseaGroups
    end
end

function BattlefieldGeneration:generateFrontlineSHORAD()
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Generate SHORAD along the frontline, positioned behind enemy lines
    local diff = state.difficulty
    local shoradTemplate = UnitTemplates.SHORAD[diff]

    if not shoradTemplate or #shoradTemplate == 0 then
        return
    end

    local frontline = state.battlefield.frontline
    local approachDir = frontline.approachDir
    local positions = frontline.isafPositions

    -- Place SHORAD near every 2nd or 3rd platoon position
    local shoradIndex = 0
    for i = 1, #positions, 2 do
        shoradIndex = shoradIndex + 1
        local pos = positions[i]

        -- Position SHORAD behind Erusean lines
        local offsetDist = SHORAD_OFFSET_BASE_METERS + (math.random() - 0.5) * 2 * SHORAD_OFFSET_VARIANCE_METERS
        local shoradPos = {
            x = pos.x + approachDir.x * offsetDist,
            y = pos.y + approachDir.y * offsetDist,
        }

        local template = Formations:randomizeTemplate(shoradTemplate)
        local formation = Formations:getRandomFormationType()
        local validPos, units = Terrain:findValidLayout(shoradPos, 200, function(candidate)
            return Formations:buildPlatoonUnits(template, candidate, {
                formation = formation,
                facing = math.atan2(-approachDir.y, -approachDir.x),
            })
        end)
        if validPos then
            -- Invisible so ISAF platoons in gun range cannot target it, like
            -- the Erusea platoons
            Virtualization:registerGroup({
                name = "SHORAD-F" .. shoradIndex,
                center = validPos,
                units = units,
                countryId = country.id.CJTF_RED,
                category = Group.Category.GROUND,
            }, { invisible = true })
        end
    end
end

-- =============================================================================
-- BEHIND-LINES TARGETS
-- =============================================================================

-- Random anchor for a behind-lines target near one of the target aerodromes
local function randomBehindLinesAnchor()
    local battlefield = OperationInfinity.state.battlefield
    local aerodromes = battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    return OperationInfinity:randomPointNearAerodrome(aerodrome, battlefield.spawnConstraints)
end

-- Meters pos is behind the frontline on the Erusean side; negative is in front
local function distanceBehindFrontline(pos)
    local frontline = OperationInfinity.state.battlefield.frontline
    local dx = pos.x - frontline.center.x
    local dy = pos.y - frontline.center.y
    return dx * frontline.approachDir.x + dy * frontline.approachDir.y
end

-- Random point on the line from a target aerodrome to a few miles behind a
-- random frontline platoon, so depots spread across the Erusean rear area
local function randomRearAreaAnchor()
    local battlefield = OperationInfinity.state.battlefield
    local frontline = battlefield.frontline
    local rearOffsetRange = OperationInfinity.config.behindLines.depotRearOffset

    local aerodromes = battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local platoon = frontline.isafPositions[math.random(#frontline.isafPositions)]
    local rearOffset = rearOffsetRange[1] + math.random() * (rearOffsetRange[2] - rearOffsetRange[1])
    local rearEnd = {
        x = platoon.x + frontline.approachDir.x * rearOffset,
        y = platoon.y + frontline.approachDir.y * rearOffset,
    }

    local fraction = math.random()
    return {
        x = aerodrome.x + fraction * (rearEnd.x - aerodrome.x),
        y = aerodrome.y + fraction * (rearEnd.y - aerodrome.y),
    }
end

-- Batched version of generateBehindLinesTargets
function BattlefieldGeneration:generateBehindLinesTargetsBatched(onComplete)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Check if this is a deep strike zone (noFrontline)
    local constraints = state.battlefield.spawnConstraints
    local isDeepStrike = constraints and constraints.noFrontline
    local cfg = isDeepStrike and config.deepStrike or config.behindLines

    -- Calculate all counts upfront
    local numConvoys = math.random(cfg.convoyCount[1], cfg.convoyCount[2])
    local numArtillery = math.random(cfg.artilleryCount[1], cfg.artilleryCount[2])
    local numPatrols = math.random(cfg.patrolCount[1], cfg.patrolCount[2])

    local numDepots = math.random(cfg.depotCount[1], cfg.depotCount[2])
    -- Deep strike adds fuel tanks
    local numFuelTanks = isDeepStrike and math.random(cfg.fuelTankCount[1], cfg.fuelTankCount[2]) or 0

    -- Build work items array
    local workItems = {}
    for i = 1, numConvoys do
        workItems[#workItems + 1] = { type = "convoy", index = i }
    end
    for i = 1, numArtillery do
        workItems[#workItems + 1] = { type = "artillery", index = i }
    end
    for i = 1, numPatrols do
        workItems[#workItems + 1] = { type = "patrol", index = i }
    end
    for i = 1, numDepots do
        workItems[#workItems + 1] = { type = "depot", index = i }
    end
    for i = 1, numFuelTanks do
        workItems[#workItems + 1] = { type = "fuel", index = i }
    end

    -- Shuffle so that if the unit budget runs out, the skipped groups are a
    -- random mix instead of every group of the last type
    for i = #workItems, 2, -1 do
        local j = math.random(i)
        workItems[i], workItems[j] = workItems[j], workItems[i]
    end

    local logMsg = "Generating "
        .. (isDeepStrike and "deep strike" or "behind-lines")
        .. " targets (batched): "
        .. numConvoys
        .. " convoys, "
        .. numArtillery
        .. " artillery, "
        .. numPatrols
        .. " patrols, "
        .. numDepots
        .. " depots"
    if isDeepStrike then
        logMsg = logMsg .. ", " .. numFuelTanks .. " fuel tanks"
    end
    log(logMsg)

    BatchScheduler:processArray({
        array = workItems,
        callback = function(item)
            if item.type == "convoy" then
                BattlefieldGeneration:generateConvoy(item.index)
            elseif item.type == "artillery" then
                BattlefieldGeneration:generateArtilleryBattery(item.index)
            elseif item.type == "patrol" then
                BattlefieldGeneration:generatePatrolGroup(item.index)
            elseif item.type == "depot" then
                BattlefieldGeneration:generateSupplyDepot(item.index)
            elseif item.type == "fuel" then
                BattlefieldGeneration:generateFuelStorage(item.index)
            end
        end,
        onComplete = function()
            if onComplete then
                onComplete()
            end
        end,
    })
end

function BattlefieldGeneration:generateConvoy(index)
    -- Convoys are placed on a road, in a column following it
    local pos, units = placeWithRetries(randomBehindLinesAnchor, function(anchor)
        return Terrain:findRoadLayout(anchor, 200, buildRoadConvoyUnits)
    end)
    if not pos then
        log("Skipping Convoy-" .. index .. " - no valid road")
        return
    end

    Virtualization:registerGroup({
        name = "Convoy-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })
end

function BattlefieldGeneration:generateArtilleryBattery(index)
    local state = OperationInfinity.state

    -- Find a frontline position to fire at
    local frontlinePositions = state.battlefield.frontline.isafPositions
    local fireTarget = nil
    local randomFacing = math.random() * 2 * math.pi

    if #frontlinePositions > 0 then
        local targetPos = frontlinePositions[math.random(#frontlinePositions)]
        fireTarget = {
            x = targetPos.x + (math.random() - 0.5) * 500,
            y = targetPos.y + (math.random() - 0.5) * 500,
            radius = 100,
            expendQty = 500,
        }
    end

    -- Artillery batteries are homogenous - no unit type substitution. Guns
    -- vary in count but are never missing, so a battery always has guns.
    local battery = UnitTemplates:getRandomArtilleryBattery()
    local gunConfig = {
        countVariance = Formations.config.countVariance,
        missingUnitChance = 0,
    }
    local guns = Formations:randomizeTemplate(battery.guns, { skipSubstitutions = true, config = gunConfig })
    local escort = Formations:randomizeTemplate(battery.escort, { skipSubstitutions = true })
    local lineTemplate = {}
    local gunCount = 0
    for _, def in ipairs(guns) do
        lineTemplate[#lineTemplate + 1] = def
        gunCount = gunCount + def.count
    end
    for _, def in ipairs(escort) do
        lineTemplate[#lineTemplate + 1] = def
    end

    -- Artillery needs flatter terrain (8 degree max slope)
    local pos, units = placeWithRetries(randomBehindLinesAnchor, function(anchor)
        return Terrain:findValidLayout(anchor, 300, function(candidate)
            -- Face toward the target
            local facing = randomFacing
            if fireTarget then
                facing = math.atan2(fireTarget.y - candidate.y, fireTarget.x - candidate.x)
            end
            local units = Formations:buildPlatoonUnits(lineTemplate, candidate, {
                formation = Formations.FormationType.LINE,
                facing = facing,
                spacing = ARTILLERY_SPACING_METERS,
            })
            -- One ammo truck behind the midpoint of each group of
            -- GunsPerAmmoTruck guns. Guns are first in the line template.
            local behindX = -math.cos(facing) * AMMO_TRUCK_ROW_OFFSET_METERS
            local behindY = -math.sin(facing) * AMMO_TRUCK_ROW_OFFSET_METERS
            local perTruck = UnitTemplates.GunsPerAmmoTruck
            for first = 1, gunCount, perTruck do
                local last = math.min(first + perTruck - 1, gunCount)
                local sumX, sumY = 0, 0
                for i = first, last do
                    sumX = sumX + units[i].x
                    sumY = sumY + units[i].y
                end
                local servedGuns = last - first + 1
                units[#units + 1] = {
                    type = UnitTemplates.AmmoTruck,
                    x = sumX / servedGuns + behindX,
                    y = sumY / servedGuns + behindY,
                    heading = facing,
                    skill = "High",
                }
            end
            return units
        end, {
            maxSlope = 8,
        })
    end)
    if not pos then
        log("Skipping Artillery-" .. index .. " - no valid flat terrain")
        return
    end

    Virtualization:registerGroup({
        name = "Artillery-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
        fireAtPoint = fireTarget,
        hint = "ARTILLERY",
    })
end

function BattlefieldGeneration:generatePatrolGroup(index)
    -- Get a random scattered patrol type for variety
    local template, patrolType = UnitTemplates:getRandomScatteredPatrol()
    local patrolHeading = math.random() * 2 * math.pi

    -- Choose formation based on patrol type
    local formation = Formations.FormationType.LINE
    if patrolType == "TankPatrol" or patrolType == "APCPatrol" then
        formation = Formations:getRandomFormationType()
    end

    local pos, units = placeWithRetries(randomBehindLinesAnchor, function(anchor)
        return Terrain:findValidLayout(anchor, 150, function(candidate)
            return Formations:buildPlatoonUnits(template, candidate, {
                formation = formation,
                facing = patrolHeading,
                spacing = 25,
            })
        end)
    end)
    if not pos then
        log("Skipping Patrol-" .. index .. " - no valid terrain")
        return
    end

    -- Use patrol type in group name for variety
    local groupName = patrolType .. "-" .. index

    Virtualization:registerGroup({
        name = groupName,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })

    log("Generated " .. patrolType .. " at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
end

function BattlefieldGeneration:generateSupplyDepot(index)
    local state = OperationInfinity.state

    -- With a frontline, depots spread across the rear area up to a few miles
    -- behind it. Without one, they are 5-20 km from a target aerodrome.
    local hasFrontline = #state.battlefield.frontline.isafPositions > 0
    local function pickAnchor()
        if hasFrontline then
            return randomRearAreaAnchor()
        end
        return randomPointNearRandomAerodrome(state.battlefield.targetAerodromes, 5000, 20000)
    end
    local minRearOffset = OperationInfinity.config.behindLines.depotRearOffset[1]

    -- Supply depot: trucks and cargo containers
    local template = {
        { type = "Ural-375", count = 4 },
        { type = "Ural-375 PBU", count = 2 },
        { type = "KAMAZ Truck", count = 2 },
    }
    local facing = math.random() * 2 * math.pi

    -- Depots should be near roads and on flat ground
    local pos, units = placeWithRetries(pickAnchor, function(anchor)
        local candidatePos, candidateUnits = Terrain:findValidLayout(anchor, 300, function(candidate)
            return Formations:buildPlatoonUnits(template, candidate, {
                formation = Formations.FormationType.LINE,
                facing = facing,
                spacing = 15,
            })
        end, {
            maxSlope = 8,
            maxRoadDistance = 200,
        })
        -- Snapping to a road can move a depot toward the front
        local tooCloseToFront = candidatePos ~= nil
            and hasFrontline
            and distanceBehindFrontline(candidatePos) < minRearOffset
        if tooCloseToFront then
            return nil
        end
        return candidatePos, candidateUnits
    end)
    if not pos then
        log("Skipping Depot-" .. index .. " - no valid terrain")
        return
    end

    Virtualization:registerGroup({
        name = "Depot-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
        hint = "SUPPLY DEPOT",
    })

    log("Generated supply depot at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
end

function BattlefieldGeneration:generateFuelStorage(index)
    local state = OperationInfinity.state

    -- Position fuel storage 3-15km from a random target aerodrome
    local function pickAnchor()
        return randomPointNearRandomAerodrome(state.battlefield.targetAerodromes, 3000, 15000)
    end

    -- Fuel storage: ATZ fuel trucks (highly explosive targets)
    local numTrucks = 3 + math.random(3) -- 3-6 fuel trucks
    local template = {
        { type = "ATZ-10", count = numTrucks },
    }
    local facing = math.random() * 2 * math.pi

    -- Fuel storage needs flat ground near roads
    local pos, units = placeWithRetries(pickAnchor, function(anchor)
        return Terrain:findValidLayout(anchor, 300, function(candidate)
            return Formations:buildPlatoonUnits(template, candidate, {
                formation = Formations.FormationType.LINE,
                facing = facing,
                spacing = 20,
            })
        end, {
            maxSlope = 5,
            maxRoadDistance = 300,
        })
    end)
    if not pos then
        log("Skipping FuelStorage-" .. index .. " - no valid terrain")
        return
    end

    Virtualization:registerGroup({
        name = "FuelStorage-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
        hint = "FUEL STORAGE",
    })

    log("Generated fuel storage at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
end

-- =============================================================================
-- APPROACH ROUTE TARGETS
-- Targets placed along the flight path from Krymsk to deep strike zones
-- =============================================================================

-- config.approachRoute with any keys from the region's
-- spawnConstraints.approachRoute layered on top (shallow merge)
function BattlefieldGeneration:getApproachRouteConfig()
    local base = OperationInfinity.config.approachRoute
    local constraints = OperationInfinity.state.battlefield.spawnConstraints
    local override = constraints and constraints.approachRoute
    if not base or not override then
        return base
    end

    local merged = {}
    for k, v in pairs(base) do
        merged[k] = v
    end
    for k, v in pairs(override) do
        merged[k] = v
    end
    return merged
end

function BattlefieldGeneration:generateApproachRouteTargetsBatched(onComplete)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Only generate for deep strike (noFrontline) regions
    local constraints = state.battlefield.spawnConstraints
    if not constraints or not constraints.noFrontline then
        log("Skipping approach route targets - not a deep strike zone")
        if onComplete then
            onComplete()
        end
        return
    end

    local approachConfig = self:getApproachRouteConfig()
    if not approachConfig then
        log("No approach route configuration found")
        if onComplete then
            onComplete()
        end
        return
    end

    -- Calculate target centroid (center of all target aerodromes)
    local aerodromes = state.battlefield.targetAerodromes
    local centroid = { x = 0, y = 0 }
    for _, aerodrome in ipairs(aerodromes) do
        centroid.x = centroid.x + aerodrome.x
        centroid.y = centroid.y + aerodrome.y
    end
    centroid.x = centroid.x / #aerodromes
    centroid.y = centroid.y / #aerodromes

    -- Calculate approach vector from Krymsk to target centroid
    local homeAirbase = OperationInfinity.state.homeAirbase
    local dx = centroid.x - homeAirbase.x
    local dy = centroid.y - homeAirbase.y
    local totalDistance = math.sqrt(dx * dx + dy * dy)
    local approachDir = { x = dx / totalDistance, y = dy / totalDistance }

    -- Perpendicular direction for lateral offsets (toward coast is positive)
    local perpDir = { x = -approachDir.y, y = approachDir.x }

    log("Approach route: Krymsk to centroid, total distance " .. math.floor(totalDistance / 1000) .. " km")

    -- Build work items for all waypoints and targets
    local workItems = {}
    local waypointIndex = 0

    for _, fraction in ipairs(approachConfig.waypointFractions) do
        -- Calculate waypoint position
        local waypointDistance = totalDistance * fraction

        -- Skip if inside safe zone (belt-and-suspenders check)
        if waypointDistance < approachConfig.safeZoneRadius then
            log(
                "Skipping waypoint at fraction "
                    .. fraction
                    .. " - inside safe zone ("
                    .. math.floor(waypointDistance / 1000)
                    .. " km)"
            )
        else
            waypointIndex = waypointIndex + 1
            local waypointCenter = {
                x = homeAirbase.x + approachDir.x * waypointDistance,
                y = homeAirbase.y + approachDir.y * waypointDistance,
            }

            log(
                "Waypoint "
                    .. waypointIndex
                    .. " at fraction "
                    .. fraction
                    .. " ("
                    .. math.floor(waypointDistance / 1000)
                    .. " km from Krymsk)"
            )

            -- Generate target counts for this waypoint
            local targetCounts = approachConfig.targetsPerWaypoint
            local numPatrols = math.random(targetCounts.patrolCount[1], targetCounts.patrolCount[2])
            local numArmor = math.random(targetCounts.armorCount[1], targetCounts.armorCount[2])
            local numConvoys = math.random(targetCounts.convoyCount[1], targetCounts.convoyCount[2])
            local numCheckpoints = math.random(targetCounts.checkpointCount[1], targetCounts.checkpointCount[2])

            -- Add work items for each target type
            for i = 1, numPatrols do
                workItems[#workItems + 1] = {
                    type = "patrol",
                    waypointIndex = waypointIndex,
                    targetIndex = i,
                    waypointCenter = waypointCenter,
                    approachDir = approachDir,
                    perpDir = perpDir,
                }
            end
            for i = 1, numArmor do
                workItems[#workItems + 1] = {
                    type = "armor",
                    waypointIndex = waypointIndex,
                    targetIndex = i,
                    waypointCenter = waypointCenter,
                    approachDir = approachDir,
                    perpDir = perpDir,
                }
            end
            for i = 1, numConvoys do
                workItems[#workItems + 1] = {
                    type = "convoy",
                    waypointIndex = waypointIndex,
                    targetIndex = i,
                    waypointCenter = waypointCenter,
                    approachDir = approachDir,
                    perpDir = perpDir,
                }
            end
            for i = 1, numCheckpoints do
                workItems[#workItems + 1] = {
                    type = "checkpoint",
                    waypointIndex = waypointIndex,
                    targetIndex = i,
                    waypointCenter = waypointCenter,
                    approachDir = approachDir,
                    perpDir = perpDir,
                }
            end
        end
    end

    log("Generating " .. #workItems .. " approach route targets across " .. waypointIndex .. " waypoints")

    BatchScheduler:processArray({
        array = workItems,
        callback = function(item)
            BattlefieldGeneration:generateApproachRouteTarget(item)
        end,
        onComplete = function()
            log("Approach route targets generated")
            if onComplete then
                onComplete()
            end
        end,
    })
end

function BattlefieldGeneration:generateApproachRouteTarget(item)
    local config = OperationInfinity.config
    local approachConfig = self:getApproachRouteConfig()

    -- Random position within the waypoint area with lateral offset toward coast
    local function pickAnchor()
        local lateralOffset = approachConfig.corridorOffsetMin
            + math.random() * (approachConfig.corridorOffsetMax - approachConfig.corridorOffsetMin)
        local longitudinalOffset = (math.random() - 0.5) * 2 * approachConfig.waypointRadius
        return {
            x = item.waypointCenter.x + item.approachDir.x * longitudinalOffset + item.perpDir.x * lateralOffset,
            y = item.waypointCenter.y + item.approachDir.y * longitudinalOffset + item.perpDir.y * lateralOffset,
        }
    end

    -- Group naming: AR = Approach Route
    local groupPrefix = "AR-W" .. item.waypointIndex

    if item.type == "patrol" then
        -- Use existing scattered patrol system
        local template, patrolType = UnitTemplates:getRandomScatteredPatrol()
        local facing = math.random() * 2 * math.pi
        local pos, units = placeWithRetries(pickAnchor, function(anchor)
            return Terrain:findValidLayout(anchor, 150, function(candidate)
                return Formations:buildPlatoonUnits(template, candidate, {
                    formation = Formations.FormationType.LINE,
                    facing = facing,
                    spacing = 25,
                })
            end)
        end)
        if not pos then
            log("Skipping approach route patrol - no valid terrain")
            return
        end

        local groupName = groupPrefix .. "-" .. patrolType .. "-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log(
            "Generated approach route "
                .. patrolType
                .. " at ("
                .. math.floor(pos.x)
                .. ", "
                .. math.floor(pos.y)
                .. ")"
        )
    elseif item.type == "armor" then
        -- Use armor patrol template for heavier targets
        local template = UnitTemplates:getRandomArmorPatrol()
        local formation = Formations:getRandomFormationType()
        local facing = math.random() * 2 * math.pi
        local pos, units = placeWithRetries(pickAnchor, function(anchor)
            return Terrain:findValidLayout(anchor, 200, function(candidate)
                return Formations:buildPlatoonUnits(template, candidate, {
                    formation = formation,
                    facing = facing,
                    spacing = 30,
                })
            end)
        end)
        if not pos then
            log("Skipping approach route armor - no valid terrain")
            return
        end

        local groupName = groupPrefix .. "-Armor-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log("Generated approach route armor at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
    elseif item.type == "convoy" then
        -- Convoys are placed on a road, in a column following it
        local pos, units = placeWithRetries(pickAnchor, function(anchor)
            return Terrain:findRoadLayout(anchor, 200, buildRoadConvoyUnits)
        end)
        if not pos then
            log("Skipping approach route convoy - no valid road")
            return
        end

        local groupName = groupPrefix .. "-Convoy-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log("Generated approach route convoy at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
    elseif item.type == "checkpoint" then
        -- Checkpoints near roads
        local template = Formations:randomizeTemplate(UnitTemplates.Checkpoint)
        local facing = math.random() * 2 * math.pi
        local pos, units = placeWithRetries(pickAnchor, function(anchor)
            return Terrain:findValidLayout(anchor, 150, function(candidate)
                return Formations:buildPlatoonUnits(template, candidate, {
                    formation = Formations.FormationType.LINE,
                    facing = facing,
                    spacing = 15,
                })
            end, {
                maxRoadDistance = 50,
            })
        end)
        if not pos then
            log("Skipping approach route checkpoint - no valid terrain near roads")
            return
        end

        local groupName = groupPrefix .. "-Checkpoint-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log("Generated approach route checkpoint at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
    end
end

-- =============================================================================
-- SAM SITES
-- =============================================================================

-- Find flat, dry ground for an air defense site minDist-maxDist from center
-- and lay out its units there with buildUnits(pos). Returns the position and
-- units, or nil.
local function findAirDefenseLayout(center, minDist, maxDist, searchRadius, buildUnits)
    local maxPositionAttempts = 5

    for attempt = 1, maxPositionAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)

        local initialPos = {
            x = center.x + distance * math.cos(angle),
            y = center.y + distance * math.sin(angle),
        }

        local validPos, units = Terrain:findValidLayout(initialPos, searchRadius, buildUnits, {
            maxSlope = 10,
            maxRoughness = 5,
        })

        if validPos then
            return validPos, units
        end
    end

    return nil
end

-- Batched version of generateAirDefenses
function BattlefieldGeneration:generateAirDefensesBatched(onComplete)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    local samCounts = config.samCounts[state.difficulty]
    if not samCounts then
        if onComplete then
            onComplete()
        end
        return
    end

    local samTemplates = UnitTemplates.SAMSites[state.difficulty]
    if not samTemplates then
        if onComplete then
            onComplete()
        end
        return
    end

    log("Generating air defenses for difficulty: " .. state.difficulty .. " (batched)")

    -- Roll site counts
    local counts = {}
    for samType, countRange in pairs(samCounts) do
        if samType ~= "EWR" and samTemplates[samType] then
            counts[samType] = math.random(countRange[1], countRange[2])
        end
    end

    -- Long-range sites first, longest range first, so the most valuable
    -- sites get point defense when there isn't enough SHORAD for all
    local longRangeItems = {}
    local otherItems = {}
    for samType, count in pairs(counts) do
        local typeData = IADS.siteTypes[samType]
        if not typeData or typeData.role ~= "SHORAD" then
            for i = 1, count do
                local item = { samType = samType, template = samTemplates[samType], index = i }
                if typeData and typeData.role == "SAM" then
                    longRangeItems[#longRangeItems + 1] = item
                else
                    otherItems[#otherItems + 1] = item
                end
            end
        end
    end
    table.sort(longRangeItems, function(a, b)
        return IADS.siteTypes[a.samType].maxRange > IADS.siteTypes[b.samType].maxRange
    end)

    -- One SHORAD per long-range site, never two
    local nextIndex = {}
    local function claimSHORAD(shoradType)
        local available = counts[shoradType] or 0
        local used = nextIndex[shoradType] or 0
        if used >= available then
            return nil
        end
        nextIndex[shoradType] = used + 1
        return { samType = shoradType, template = samTemplates[shoradType], index = used + 1 }
    end

    local workItems = {}
    for _, item in ipairs(longRangeItems) do
        local pointDefense = IADS.siteTypes[item.samType].pointDefense
        if pointDefense then
            item.pointDefense = claimSHORAD(pointDefense)
        end
        workItems[#workItems + 1] = item
    end
    for _, item in ipairs(otherItems) do
        workItems[#workItems + 1] = item
    end

    -- Leftover SHORAD keeps random placement
    for samType, count in pairs(counts) do
        local typeData = IADS.siteTypes[samType]
        if typeData and typeData.role == "SHORAD" then
            for i = (nextIndex[samType] or 0) + 1, count do
                workItems[#workItems + 1] = { samType = samType, template = samTemplates[samType], index = i }
            end
        end
    end

    BatchScheduler:processArray({
        array = workItems,
        callback = function(item)
            local pos = BattlefieldGeneration:generateSAMSite(item.samType, item.template, item.index)
            local pd = item.pointDefense
            if pd then
                -- Falls back to random placement if the site itself failed
                BattlefieldGeneration:generateSAMSite(pd.samType, pd.template, pd.index, pos)
            end
        end,
        onComplete = function()
            if onComplete then
                onComplete()
            end
        end,
    })
end

-- Generate a SAM site. With anchor set, place it 1-3 km from anchor as point
-- defense; otherwise near a random target aerodrome. Returns the site position,
-- or nil if no valid terrain was found.
function BattlefieldGeneration:generateSAMSite(samType, template, index, anchor)
    local state = OperationInfinity.state

    local function buildUnits(candidate)
        return self:buildSAMUnits(template, candidate)
    end

    local pos, units = nil, nil
    if anchor then
        pos, units = findAirDefenseLayout(anchor, 1000, 3000, 500, buildUnits)
        if not pos then
            log("WARNING: Could not find valid terrain for " .. samType .. " near its site - placing at random")
        end
    end

    if not pos then
        -- Pick a random target aerodrome and position SAM site near it
        local aerodromes = state.battlefield.targetAerodromes
        local aerodrome = aerodromes[math.random(#aerodromes)]

        -- Position SAM sites closer to aerodrome than frontline units
        -- Heavier SAMs positioned closer to protect the aerodrome
        local minDist = 5000 -- 5 km minimum from aerodrome
        local maxDist = 30000 -- 30 km max
        if samType == "SA10" or samType == "SA11" then
            maxDist = 15000 -- Longer range SAMs closer to protect the aerodrome
        end

        pos, units = findAirDefenseLayout(aerodrome, minDist, maxDist, 3000, buildUnits)
    end

    if not pos then
        log("WARNING: Could not find valid terrain for " .. samType .. " near aerodrome - skipping")
        return nil
    end

    local groupName = samType .. "-" .. index

    -- Register as permanent group (always spawned - SAM radars need to be active)
    local pGroup = Virtualization:registerPermanentGroup({
        name = groupName,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    })

    -- Register with IADS (ignores SHORAD and Easy types)
    IADS:registerSAMSite(pGroup, samType, pos)

    log(
        "Generated "
            .. samType
            .. " at ("
            .. math.floor(pos.x)
            .. ", "
            .. math.floor(pos.y)
            .. ")"
            .. (anchor and " as point defense" or "")
    )

    return pos
end

function BattlefieldGeneration:buildSAMUnits(template, center)
    local units = {}
    local unitIndex = 1

    for _, def in ipairs(template) do
        for c = 1, def.count do
            -- Arrange in a circular pattern
            local angle = (unitIndex - 1) * (2 * math.pi / 8)
            local radius = 50 + (unitIndex - 1) * 30

            units[#units + 1] = {
                type = def.type,
                x = center.x + radius * math.cos(angle),
                y = center.y + radius * math.sin(angle),
                heading = angle, -- Face outward
                skill = "Excellent",
            }
            unitIndex = unitIndex + 1
        end
    end

    return units
end

-- =============================================================================
-- EARLY WARNING RADARS
-- =============================================================================

function BattlefieldGeneration:generateEWRsBatched(onComplete)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    local samCounts = config.samCounts[state.difficulty]
    local ewrCountRange = nil

    if samCounts and samCounts.EWR then
        ewrCountRange = samCounts.EWR
    else
        ewrCountRange = { 1, 2 }
    end

    local samTemplates = UnitTemplates.SAMSites[state.difficulty]
    local ewrTemplate = nil

    if samTemplates and samTemplates.EWR then
        ewrTemplate = samTemplates.EWR
    else
        ewrTemplate = { { type = "1L13 EWR", count = 1 } }
    end

    local count = math.random(ewrCountRange[1], ewrCountRange[2])

    -- Build array of EWR indices
    local ewrIndices = {}
    for i = 1, count do
        ewrIndices[#ewrIndices + 1] = i
    end

    log("Generating " .. count .. " EWRs (batched)")

    BatchScheduler:processArray({
        array = ewrIndices,
        context = { template = ewrTemplate },
        callback = function(i, _, ctx)
            local aerodromes = OperationInfinity.state.battlefield.targetAerodromes
            local aerodrome = aerodromes[math.random(#aerodromes)]

            local minDist = 10000
            local maxDist = 40000

            -- EWRs need flat, dry ground
            local pos, units = findAirDefenseLayout(aerodrome, minDist, maxDist, 3000, function(candidate)
                local layout = {}
                for _, def in ipairs(ctx.template) do
                    for c = 1, def.count do
                        layout[#layout + 1] = {
                            type = def.type,
                            x = candidate.x + (c - 1) * 50,
                            y = candidate.y,
                            heading = 0,
                            skill = "Excellent",
                        }
                    end
                end
                return layout
            end)

            if not pos then
                log("WARNING: Could not find valid terrain for EWR near aerodrome - skipping")
                return
            end

            local groupName = "EWR-" .. i

            local pGroup = Virtualization:registerPermanentGroup({
                name = groupName,
                center = pos,
                units = units,
                countryId = country.id.CJTF_RED,
                category = Group.Category.GROUND,
            })

            IADS:registerEWR(pGroup)

            log("Generated EWR at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
        end,
        onComplete = function()
            if onComplete then
                onComplete()
            end
        end,
    })
end

-- =============================================================================
-- AIRBASE SHORAD
-- =============================================================================

-- Batched version of generateAirbaseSHORAD
function BattlefieldGeneration:generateAirbaseSHORADBatched(onComplete)
    local state = OperationInfinity.state
    local diff = state.difficulty
    local shoradTemplate = UnitTemplates.AirbaseSHORAD[diff]

    if not shoradTemplate or #shoradTemplate == 0 then
        log("No airbase SHORAD template for difficulty: " .. diff)
        if onComplete then
            onComplete()
        end
        return
    end

    local aerodromes = state.battlefield.targetAerodromes
    log("Generating airbase SHORAD for " .. #aerodromes .. " aerodromes (batched)")

    BatchScheduler:processArray({
        array = aerodromes,
        context = { template = shoradTemplate },
        callback = function(aerodrome, _, ctx)
            BattlefieldGeneration:generateAirbaseSHORADSite(aerodrome, ctx.template)
        end,
        onComplete = function()
            if onComplete then
                onComplete()
            end
        end,
    })
end

function BattlefieldGeneration:generateAirbaseSHORADSite(aerodrome, template)
    -- Position SHORAD close to the airbase (1-3 km) to defend against low-level attacks
    local minDist = 1000 -- 1 km minimum
    local maxDist = 3000 -- 3 km maximum

    -- Apply template randomization and position in a defensive formation
    local randomizedTemplate = Formations:randomizeTemplate(template)
    local facing = math.random() * 2 * math.pi
    local function buildUnits(candidate)
        return Formations:buildPlatoonUnits(randomizedTemplate, candidate, {
            formation = Formations.FormationType.WEDGE,
            facing = facing,
            spacing = 40,
        })
    end

    -- Try multiple positions to find valid terrain
    local pos, units = nil, nil
    local maxPositionAttempts = 5

    for attempt = 1, maxPositionAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)

        local initialPos = {
            x = aerodrome.x + distance * math.cos(angle),
            y = aerodrome.y + distance * math.sin(angle),
        }

        -- Validate terrain - SHORAD needs reasonably flat ground
        local validPos, validUnits = Terrain:findValidLayout(initialPos, 500, buildUnits, {
            maxSlope = 12,
        })

        if validPos then
            pos, units = validPos, validUnits
            break
        end
    end

    if not pos then
        log("WARNING: Could not find valid terrain for SHORAD near " .. aerodrome.name .. " - skipping")
        return
    end

    -- Create a unique name based on the aerodrome
    local safeName = string.gsub(aerodrome.name, "[^%w]", "")
    local groupName = "AirbaseSHORAD-" .. safeName

    -- Register as permanent group (always spawned - needs to be active for airbase defense)
    Virtualization:registerPermanentGroup({
        name = groupName,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    })

    log(
        "Generated airbase SHORAD for "
            .. aerodrome.name
            .. " at ("
            .. math.floor(pos.x)
            .. ", "
            .. math.floor(pos.y)
            .. ")"
    )
end

-- =============================================================================
-- FRONTLINE FIRE CONTROL
-- Runs during the mission after generation
-- =============================================================================

-- True when every Erusea platoon an ISAF platoon fires at is destroyed
local function allFireTargetsDestroyed(vGroup)
    for _, target in ipairs(vGroup.fireTargets) do
        if not target.destroyed then
            return false
        end
    end
    return true
end

-- Stop an ISAF platoon firing once its Erusea platoons are gone, so it does
-- not shell empty ground. Clearing fireAtPoint also keeps it off on respawn.
local function ceaseFireIfTargetsDestroyed(vGroup)
    if not vGroup.fireTargets or not vGroup.options.fireAtPoint then
        return
    end
    if not allFireTargetsDestroyed(vGroup) then
        return
    end
    vGroup.options.fireAtPoint = nil
    log("Cease fire for " .. vGroup.name .. " - all its Erusea platoons are destroyed")
    if vGroup.isSpawned then
        local group = Group.getByName(vGroup.spawnedGroupName)
        if group and group:isExist() then
            local controller = group:getController()
            if controller then
                controller:resetTask()
            end
        end
    end
end

function BattlefieldGeneration:updateFireTargets()
    local config = OperationInfinity.config
    local wanderRadius = config.frontline.fireTargetWanderRadius
    local updated = 0

    for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
        ceaseFireIfTargetsDestroyed(vGroup)
        -- Only update spawned frontline groups with fireAtPoint
        if vGroup.isSpawned and vGroup.options.fireAtPoint then
            local groupName = vGroup.spawnedGroupName
            if string.find(groupName, "ISAF%-F") or string.find(groupName, "Erusea%-F") then
                local group = Group.getByName(groupName)
                if group and group:isExist() then
                    -- Random offset from the group's original fire target, not
                    -- its own position (which would make it shell itself)
                    local fireTarget = vGroup.options.fireAtPoint
                    local angle = math.random() * 2 * math.pi
                    local distance = math.random() * wanderRadius
                    local newX = fireTarget.x + distance * math.cos(angle)
                    local newY = fireTarget.y + distance * math.sin(angle)

                    local task = {
                        id = "FireAtPoint",
                        params = {
                            x = newX,
                            y = newY,
                            radius = vGroup.options.fireAtPoint.radius or 50,
                            expendQty = vGroup.options.fireAtPoint.expendQty or 200,
                            expendQtyEnabled = true,
                        },
                    }

                    local controller = group:getController()
                    if controller then
                        controller:setTask(task)
                        updated = updated + 1
                    end
                end
            end
        end
    end

    log("Updated fire targets for " .. updated .. " groups")
end

env.info("[BattlefieldGeneration] Loaded successfully")
