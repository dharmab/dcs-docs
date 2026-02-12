-- =============================================================================
-- BATTLEFIELD GENERATION
-- All spawning logic for ground units (frontline, behind-lines, air defenses)
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

local log = Logging:create("BattlefieldGeneration")

-- =============================================================================
-- FRONTLINE GENERATION
-- =============================================================================

function BattlefieldGeneration:generateFrontline()
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Calculate target centroid (center of all target aerodromes)
    local aerodromes = state.battlefield.targetAerodromes
    local centroid = {x = 0, y = 0}
    for _, aerodrome in ipairs(aerodromes) do
        centroid.x = centroid.x + aerodrome.x
        centroid.y = centroid.y + aerodrome.y
    end
    centroid.x = centroid.x / #aerodromes
    centroid.y = centroid.y / #aerodromes

    -- Calculate approach direction from Krymsk to target centroid
    local krymsk = config.krymsk
    local dx = centroid.x - krymsk.x
    local dy = centroid.y - krymsk.y
    local approachDist = math.sqrt(dx * dx + dy * dy)
    local approachDir = {x = dx / approachDist, y = dy / approachDist}

    -- Frontline axis is perpendicular to approach direction (rotate 90 degrees)
    local frontlineAxis = {x = -approachDir.y, y = approachDir.x}

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
    local numPlatoons = math.random(
        config.frontline.platoonCountMin,
        config.frontline.platoonCountMax
    )

    log("Generating coherent frontline with " .. numPlatoons .. " platoons")
    log("Frontline center: (" .. math.floor(frontlineCenter.x) .. ", " ..
        math.floor(frontlineCenter.y) .. ")")

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
        local validPos, isValid = Terrain:findValidPosition(
            initialPos,
            config.frontline.terrainSearchRadius
        )

        if isValid then
            self:generateFrontlinePlatoon(validPos, i)
            -- Store ISAF position for FEBA visualization
            state.battlefield.frontline.isafPositions[#state.battlefield.frontline.isafPositions + 1] = validPos
            log("Platoon " .. i .. " at (" .. math.floor(validPos.x) .. ", " ..
                math.floor(validPos.y) .. ")")
        else
            log("Skipping platoon " .. i .. " - no valid terrain at (" ..
                math.floor(initialPos.x) .. ", " .. math.floor(initialPos.y) .. ")")
        end

        -- Advance along frontline by random spacing for next platoon
        local spacing = math.random(
            config.frontline.platoonSpacingMin,
            config.frontline.platoonSpacingMax
        )
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
    local engageDist = math.random(
        config.frontline.engagementDistanceMin,
        config.frontline.engagementDistanceMax
    )

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

    -- Find valid terrain for ISAF platoon
    local isafValidPos, isafValid = Terrain:findValidPosition(isafPos, 100)
    if not isafValid then
        log("Skipping ISAF platoon " .. index .. " - no valid terrain")
        return
    end

    -- Find valid terrain for Erusea platoon
    local eruseaValidPos, eruseaValid = Terrain:findValidPosition(eruseaPos, 100)
    if not eruseaValid then
        log("Skipping Erusea platoon " .. index .. " - no valid terrain")
        return
    end

    -- Calculate facing directions (toward each other)
    local isafFacing = math.atan2(eruseaValidPos.y - isafValidPos.y, eruseaValidPos.x - isafValidPos.x)
    local eruseaFacing = math.atan2(isafValidPos.y - eruseaValidPos.y, isafValidPos.x - eruseaValidPos.x)

    -- Calculate direction vector for fire offset
    local dx = eruseaValidPos.x - isafValidPos.x
    local dy = eruseaValidPos.y - isafValidPos.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local dirX = dx / dist
    local dirY = dy / dist
    local fireOffset = config.frontline.fireOffset

    -- Select formation
    local formation = Formations:getRandomFormationType()

    -- Build ISAF units with formation and facing
    local isafTemplate = Formations:randomizeTemplate(UnitTemplates.ISAFPlatoon)
    local isafUnits = Formations:buildPlatoonUnits(isafTemplate, isafValidPos, {
        formation = formation,
        facing = isafFacing,
        widthMultiplier = 2.5,
    })

    -- Register ISAF group (immortal/invisible for visual firefight only)
    Virtualization:registerGroup({
        name = "ISAF-F" .. index,
        center = isafValidPos,
        units = isafUnits,
        countryId = country.id.CJTF_BLUE,
        category = Group.Category.GROUND,
    }, {
        immortal = true,
        invisible = true,
        holdFire = true,
        fireAtPoint = {
            x = eruseaValidPos.x + dirX * fireOffset,
            y = eruseaValidPos.y + dirY * fireOffset,
            radius = FIRE_OFFSET_RADIUS_METERS,
            expendQty = FIRE_EXPENDITURE_QUANTITY,
        },
    })

    -- Build multiple Erusea platoons
    local numEruseaPlatoons = math.random(
        config.frontline.enemyPlatoonsMin,
        config.frontline.enemyPlatoonsMax
    )
    local diff = state.difficulty
    local spreadRadius = config.frontline.enemySpreadRadius

    for e = 1, numEruseaPlatoons do
        local eruseaSpreadPos
        if e == 1 then
            eruseaSpreadPos = eruseaValidPos
        else
            local spreadAngle = (e - 1) * (math.pi / 3)
            eruseaSpreadPos = {
                x = eruseaValidPos.x + spreadRadius * math.cos(spreadAngle),
                y = eruseaValidPos.y + spreadRadius * 0.5 * math.sin(spreadAngle),
            }
            local validSpreadPos, spreadValid = Terrain:findValidPosition(eruseaSpreadPos, 50)
            if spreadValid then
                eruseaSpreadPos = validSpreadPos
            else
                eruseaSpreadPos = eruseaValidPos
            end
        end

        local eFacing = math.atan2(isafValidPos.y - eruseaSpreadPos.y, isafValidPos.x - eruseaSpreadPos.x)

        local baseEruseaTemplate = UnitTemplates.EruseaPlatoon[diff] or UnitTemplates.EruseaPlatoon.Normal
        local eruseaTemplate = Formations:randomizeTemplate(baseEruseaTemplate)
        local eruseaUnits = Formations:buildPlatoonUnits(eruseaTemplate, eruseaSpreadPos, {
            formation = formation,
            facing = eFacing,
            widthMultiplier = 2.5,
        })

        Virtualization:registerGroup({
            name = "Erusea-F" .. index .. "-" .. e,
            center = eruseaSpreadPos,
            units = eruseaUnits,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {
            immortal = false,
            invisible = false,
            fireAtPoint = {
                x = isafValidPos.x - dirX * fireOffset,
                y = isafValidPos.y - dirY * fireOffset,
                radius = FIRE_OFFSET_RADIUS_METERS,
                expendQty = FIRE_EXPENDITURE_QUANTITY,
            },
        })
    end
end

function BattlefieldGeneration:updateFireTargets()
    local config = OperationInfinity.config
    local wanderRadius = config.frontline.fireTargetWanderRadius
    local updated = 0

    for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
        -- Only update spawned frontline groups with fireAtPoint
        if vGroup.isSpawned and vGroup.options.fireAtPoint then
            local groupName = vGroup.spawnedGroupName
            if string.find(groupName, "ISAF%-F") or string.find(groupName, "Erusea%-F") then
                local group = Group.getByName(groupName)
                if group and group:isExist() then
                    -- Random offset from group center
                    local angle = math.random() * 2 * math.pi
                    local distance = math.random() * wanderRadius
                    local newX = vGroup.center.x + distance * math.cos(angle)
                    local newY = vGroup.center.y + distance * math.sin(angle)

                    local task = {
                        id = "FireAtPoint",
                        params = {
                            x = newX,
                            y = newY,
                            radius = vGroup.options.fireAtPoint.radius or 50,
                            expendQty = vGroup.options.fireAtPoint.expendQty or 200,
                            expendQtyEnabled = true,
                        }
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

        local validPos, isValid = Terrain:findValidPosition(shoradPos, 200)
        if isValid then
            local template = Formations:randomizeTemplate(shoradTemplate)
            local units = Formations:buildPlatoonUnits(template, validPos, {
                formation = Formations:getRandomFormationType(),
                facing = math.atan2(-approachDir.y, -approachDir.x),
            })

            Virtualization:registerGroup({
                name = "SHORAD-F" .. shoradIndex,
                center = validPos,
                units = units,
                countryId = country.id.CJTF_RED,
                category = Group.Category.GROUND,
            }, {})
        end
    end
end

-- Batched version of generateFrontline
function BattlefieldGeneration:generateFrontlineBatched(onComplete)
    -- Check if this region has noFrontline constraint (e.g., Tbilisi deep strike)
    local constraints = OperationInfinity.state.battlefield.spawnConstraints
    if constraints and constraints.noFrontline then
        log("Skipping frontline generation - noFrontline constraint active (deep strike zone)")
        if onComplete then onComplete() end
        return
    end

    -- Generate the coherent frontline (all platoons along a single line)
    self:generateFrontline()

    if onComplete then onComplete() end
end

-- =============================================================================
-- BEHIND-LINES TARGETS
-- =============================================================================

function BattlefieldGeneration:generateConvoy(index)
    local state = OperationInfinity.state

    -- Pick a random target aerodrome and position convoy near it
    local aerodromes = state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local initialPos = OperationInfinity:randomPointNearAerodrome(aerodrome, state.battlefield.spawnConstraints)

    -- Convoys should be near roads (within 100m)
    local pos, valid = Terrain:findValidPosition(initialPos, 200, {
        maxRoadDistance = 100,
    })
    if not valid then
        log("Skipping Convoy-" .. index .. " near " .. aerodrome.name .. " - no valid terrain near roads")
        return
    end

    -- Apply template randomization and use LINE formation for convoy
    local template = Formations:randomizeTemplate(UnitTemplates.LogisticsConvoy)
    local units = Formations:buildPlatoonUnits(template, pos, {
        formation = Formations.FormationType.LINE,
        spacing = 20, -- Tighter spacing for convoy
    })

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

    -- Pick a random target aerodrome and position artillery near it
    local aerodromes = state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local initialPos = OperationInfinity:randomPointNearAerodrome(aerodrome, state.battlefield.spawnConstraints)

    -- Artillery needs flatter terrain (8 degree max slope)
    local pos, valid = Terrain:findValidPosition(initialPos, 300, {
        maxSlope = 8,
    })
    if not valid then
        log("Skipping Artillery-" .. index .. " near " .. aerodrome.name .. " - no valid flat terrain")
        return
    end

    -- Find a frontline position to fire at
    local frontlinePositions = state.battlefield.frontline.isafPositions
    local fireTarget = nil
    local facingDirection = math.random() * 2 * math.pi

    if #frontlinePositions > 0 then
        local targetPos = frontlinePositions[math.random(#frontlinePositions)]
        fireTarget = {
            x = targetPos.x + (math.random() - 0.5) * 500,
            y = targetPos.y + (math.random() - 0.5) * 500,
            radius = 100,
            expendQty = 500,
        }
        -- Face toward the target
        facingDirection = math.atan2(fireTarget.y - pos.y, fireTarget.x - pos.x)
    end

    -- Artillery batteries are homogenous - no unit type substitution
    local template = Formations:randomizeTemplate(UnitTemplates.ArtilleryBattery, {
        skipSubstitutions = true,
    })
    local units = Formations:buildPlatoonUnits(template, pos, {
        formation = Formations.FormationType.LINE,
        facing = facingDirection,
        spacing = 40, -- Wider spacing for artillery
    })

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
    })
end

function BattlefieldGeneration:generatePatrolGroup(index)
    local state = OperationInfinity.state

    -- Pick a random target aerodrome and position patrol near it
    local aerodromes = state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local initialPos = OperationInfinity:randomPointNearAerodrome(aerodrome, state.battlefield.spawnConstraints)

    -- Find valid terrain for patrol
    local pos, valid = Terrain:findValidPosition(initialPos, 150)
    if not valid then
        log("Skipping Patrol-" .. index .. " near " .. aerodrome.name .. " - no valid terrain")
        return
    end

    -- Get a random scattered patrol type for variety
    local template, patrolType = UnitTemplates:getRandomScatteredPatrol()
    local patrolHeading = math.random() * 2 * math.pi

    -- Choose formation based on patrol type
    local formation = Formations.FormationType.LINE
    if patrolType == "TankPatrol" or patrolType == "APCPatrol" then
        formation = Formations:getRandomFormationType()
    end

    local units = Formations:buildPlatoonUnits(template, pos, {
        formation = formation,
        facing = patrolHeading,
        spacing = 25,
    })

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

    -- Pick a random target aerodrome and position depot near it
    local aerodromes = state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]

    -- Position depots 5-20km from aerodrome
    local angle = math.random() * 2 * math.pi
    local distance = 5000 + math.random() * 15000
    local initialPos = {
        x = aerodrome.x + distance * math.cos(angle),
        y = aerodrome.y + distance * math.sin(angle),
    }

    -- Depots should be near roads and on flat ground
    local pos, valid = Terrain:findValidPosition(initialPos, 300, {
        maxSlope = 8,
        maxRoadDistance = 200,
    })
    if not valid then
        log("Skipping Depot-" .. index .. " near " .. aerodrome.name .. " - no valid terrain")
        return
    end

    -- Supply depot: trucks and cargo containers
    local template = {
        { type = "Ural-375", count = 4 },
        { type = "Ural-375 PBU", count = 2 },
        { type = "KAMAZ Truck", count = 2 },
    }
    local units = Formations:buildPlatoonUnits(template, pos, {
        formation = Formations.FormationType.LINE,
        spacing = 15,
    })

    Virtualization:registerGroup({
        name = "Depot-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })

    log("Generated supply depot at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
end

function BattlefieldGeneration:generateFuelStorage(index)
    local state = OperationInfinity.state

    -- Pick a random target aerodrome and position fuel storage near it
    local aerodromes = state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]

    -- Position fuel storage 3-15km from aerodrome
    local angle = math.random() * 2 * math.pi
    local distance = 3000 + math.random() * 12000
    local initialPos = {
        x = aerodrome.x + distance * math.cos(angle),
        y = aerodrome.y + distance * math.sin(angle),
    }

    -- Fuel storage needs flat ground near roads
    local pos, valid = Terrain:findValidPosition(initialPos, 300, {
        maxSlope = 5,
        maxRoadDistance = 300,
    })
    if not valid then
        log("Skipping FuelStorage-" .. index .. " near " .. aerodrome.name .. " - no valid terrain")
        return
    end

    -- Fuel storage: ATZ fuel trucks (highly explosive targets)
    local numTrucks = 3 + math.random(3)  -- 3-6 fuel trucks
    local template = {
        { type = "ATZ-10", count = numTrucks },
    }
    local units = Formations:buildPlatoonUnits(template, pos, {
        formation = Formations.FormationType.LINE,
        spacing = 20,
    })

    Virtualization:registerGroup({
        name = "FuelStorage-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })

    log("Generated fuel storage at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
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

    -- Deep strike adds supply depots and fuel tanks
    local numDepots = isDeepStrike and math.random(cfg.depotCount[1], cfg.depotCount[2]) or 0
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

    local logMsg = "Generating " .. (isDeepStrike and "deep strike" or "behind-lines") ..
        " targets (batched): " .. numConvoys .. " convoys, " ..
        numArtillery .. " artillery, " .. numPatrols .. " patrols"
    if isDeepStrike then
        logMsg = logMsg .. ", " .. numDepots .. " depots, " .. numFuelTanks .. " fuel tanks"
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
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- APPROACH ROUTE TARGETS
-- Targets placed along the flight path from Krymsk to deep strike zones
-- =============================================================================

function BattlefieldGeneration:generateApproachRouteTargetsBatched(onComplete)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Only generate for deep strike (noFrontline) regions
    local constraints = state.battlefield.spawnConstraints
    if not constraints or not constraints.noFrontline then
        log("Skipping approach route targets - not a deep strike zone")
        if onComplete then onComplete() end
        return
    end

    local approachConfig = config.approachRoute
    if not approachConfig then
        log("No approach route configuration found")
        if onComplete then onComplete() end
        return
    end

    -- Calculate target centroid (center of all target aerodromes)
    local aerodromes = state.battlefield.targetAerodromes
    local centroid = {x = 0, y = 0}
    for _, aerodrome in ipairs(aerodromes) do
        centroid.x = centroid.x + aerodrome.x
        centroid.y = centroid.y + aerodrome.y
    end
    centroid.x = centroid.x / #aerodromes
    centroid.y = centroid.y / #aerodromes

    -- Calculate approach vector from Krymsk to target centroid
    local krymsk = config.krymsk
    local dx = centroid.x - krymsk.x
    local dy = centroid.y - krymsk.y
    local totalDistance = math.sqrt(dx * dx + dy * dy)
    local approachDir = {x = dx / totalDistance, y = dy / totalDistance}

    -- Perpendicular direction for lateral offsets (toward coast is positive)
    local perpDir = {x = -approachDir.y, y = approachDir.x}

    log("Approach route: Krymsk to centroid, total distance " ..
        math.floor(totalDistance / 1000) .. " km")

    -- Build work items for all waypoints and targets
    local workItems = {}
    local waypointIndex = 0

    for _, fraction in ipairs(approachConfig.waypointFractions) do
        -- Calculate waypoint position
        local waypointDistance = totalDistance * fraction

        -- Skip if inside safe zone (belt-and-suspenders check)
        if waypointDistance < approachConfig.safeZoneRadius then
            log("Skipping waypoint at fraction " .. fraction ..
                " - inside safe zone (" .. math.floor(waypointDistance / 1000) .. " km)")
        else
            waypointIndex = waypointIndex + 1
            local waypointCenter = {
                x = krymsk.x + approachDir.x * waypointDistance,
                y = krymsk.y + approachDir.y * waypointDistance,
            }

            log("Waypoint " .. waypointIndex .. " at fraction " .. fraction ..
                " (" .. math.floor(waypointDistance / 1000) .. " km from Krymsk)")

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

    log("Generating " .. #workItems .. " approach route targets across " ..
        waypointIndex .. " waypoints")

    BatchScheduler:processArray({
        array = workItems,
        callback = function(item)
            BattlefieldGeneration:generateApproachRouteTarget(item)
        end,
        onComplete = function()
            log("Approach route targets generated")
            if onComplete then onComplete() end
        end,
    })
end

function BattlefieldGeneration:generateApproachRouteTarget(item)
    local config = OperationInfinity.config
    local approachConfig = config.approachRoute

    -- Calculate position within waypoint area with lateral offset toward coast
    local lateralOffset = approachConfig.corridorOffsetMin +
        math.random() * (approachConfig.corridorOffsetMax - approachConfig.corridorOffsetMin)
    local longitudinalOffset = (math.random() - 0.5) * 2 * approachConfig.waypointRadius

    local initialPos = {
        x = item.waypointCenter.x + item.approachDir.x * longitudinalOffset +
            item.perpDir.x * lateralOffset,
        y = item.waypointCenter.y + item.approachDir.y * longitudinalOffset +
            item.perpDir.y * lateralOffset,
    }

    -- Group naming: AR = Approach Route
    local groupPrefix = "AR-W" .. item.waypointIndex

    if item.type == "patrol" then
        -- Use existing scattered patrol system
        local pos, valid = Terrain:findValidPosition(initialPos, 150)
        if not valid then
            log("Skipping approach route patrol - no valid terrain")
            return
        end

        local template, patrolType = UnitTemplates:getRandomScatteredPatrol()
        local units = Formations:buildPlatoonUnits(template, pos, {
            formation = Formations.FormationType.LINE,
            facing = math.random() * 2 * math.pi,
            spacing = 25,
        })

        local groupName = groupPrefix .. "-" .. patrolType .. "-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log("Generated approach route " .. patrolType .. " at (" ..
            math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")

    elseif item.type == "armor" then
        -- Use armor patrol template for heavier targets
        local pos, valid = Terrain:findValidPosition(initialPos, 200)
        if not valid then
            log("Skipping approach route armor - no valid terrain")
            return
        end

        local template = UnitTemplates:getRandomArmorPatrol()
        local units = Formations:buildPlatoonUnits(template, pos, {
            formation = Formations:getRandomFormationType(),
            facing = math.random() * 2 * math.pi,
            spacing = 30,
        })

        local groupName = groupPrefix .. "-Armor-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log("Generated approach route armor at (" ..
            math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")

    elseif item.type == "convoy" then
        -- Position convoy near roads
        local pos, valid = Terrain:findValidPosition(initialPos, 200, {
            maxRoadDistance = 100,
        })
        if not valid then
            log("Skipping approach route convoy - no valid terrain near roads")
            return
        end

        local template = Formations:randomizeTemplate(UnitTemplates.LogisticsConvoy)
        local units = Formations:buildPlatoonUnits(template, pos, {
            formation = Formations.FormationType.LINE,
            spacing = 20,
        })

        local groupName = groupPrefix .. "-Convoy-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log("Generated approach route convoy at (" ..
            math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")

    elseif item.type == "checkpoint" then
        -- Checkpoints near roads
        local pos, valid = Terrain:findValidPosition(initialPos, 150, {
            maxRoadDistance = 50,
        })
        if not valid then
            log("Skipping approach route checkpoint - no valid terrain near roads")
            return
        end

        local template = Formations:randomizeTemplate(UnitTemplates.Checkpoint)
        local units = Formations:buildPlatoonUnits(template, pos, {
            formation = Formations.FormationType.LINE,
            spacing = 15,
        })

        local groupName = groupPrefix .. "-Checkpoint-" .. item.targetIndex

        Virtualization:registerGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        }, {})

        log("Generated approach route checkpoint at (" ..
            math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
    end
end

-- =============================================================================
-- AIR DEFENSE GENERATION
-- =============================================================================

function BattlefieldGeneration:generateSAMSite(samType, template, index)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    -- Pick a random target aerodrome and position SAM site near it
    local aerodromes = state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]

    -- Position SAM sites closer to aerodrome than frontline units
    -- Heavier SAMs positioned closer to protect the aerodrome
    local minDist = 5000  -- 5 km minimum from aerodrome
    local maxDist = 30000 -- 30 km max
    if samType == "SA10" or samType == "SA11" then
        maxDist = 15000 -- Longer range SAMs closer to protect the aerodrome
    end

    -- Try multiple random positions near the aerodrome until we find valid terrain
    local pos = nil
    local maxPositionAttempts = 5

    for attempt = 1, maxPositionAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)

        local initialPos = {
            x = aerodrome.x + distance * math.cos(angle),
            y = aerodrome.y + distance * math.sin(angle),
        }

        -- Validate terrain - SAM sites need flat, dry ground
        local validPos, found = Terrain:findValidPosition(initialPos, 3000, {
            maxSlope = 10,
            maxRoughness = 5,
        })

        if found then
            pos = validPos
            break
        end
    end

    if not pos then
        log("WARNING: Could not find valid terrain for " .. samType .. " near aerodrome - skipping")
        return
    end

    local units = self:buildSAMUnits(template, pos)
    local groupName = samType .. "-" .. index

    -- Register as permanent group (always spawned - SAM radars need to be active)
    Virtualization:registerPermanentGroup({
        name = groupName,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    })

    -- Register with IADS for emission control
    IADS:registerSAMSite(groupName, samType, pos)

    log("Generated " .. samType .. " at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
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

-- Batched version of generateAirDefenses
function BattlefieldGeneration:generateAirDefensesBatched(onComplete)
    local config = OperationInfinity.config
    local state = OperationInfinity.state

    local samCounts = config.samCounts[state.difficulty]
    if not samCounts then
        if onComplete then onComplete() end
        return
    end

    local samTemplates = UnitTemplates.SAMSites[state.difficulty]
    if not samTemplates then
        if onComplete then onComplete() end
        return
    end

    log("Generating air defenses for difficulty: " .. state.difficulty .. " (batched)")

    -- Build work items for all SAM sites
    local workItems = {}
    for samType, countRange in pairs(samCounts) do
        if samType ~= "EWR" then
            local template = samTemplates[samType]
            if template then
                local count = math.random(countRange[1], countRange[2])
                for i = 1, count do
                    workItems[#workItems + 1] = {
                        samType = samType,
                        template = template,
                        index = i,
                    }
                end
            end
        end
    end

    BatchScheduler:processArray({
        array = workItems,
        callback = function(item)
            BattlefieldGeneration:generateSAMSite(item.samType, item.template, item.index)
        end,
        onComplete = function()
            if onComplete then onComplete() end
        end,
    })
end

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

            -- Try multiple random positions near the aerodrome until we find valid terrain
            local pos = nil
            local maxPositionAttempts = 5

            for attempt = 1, maxPositionAttempts do
                local angle = math.random() * 2 * math.pi
                local distance = minDist + math.random() * (maxDist - minDist)

                local initialPos = {
                    x = aerodrome.x + distance * math.cos(angle),
                    y = aerodrome.y + distance * math.sin(angle),
                }

                -- Validate terrain - EWRs need flat, dry ground
                local validPos, found = Terrain:findValidPosition(initialPos, 3000, {
                    maxSlope = 10,
                    maxRoughness = 5,
                })

                if found then
                    pos = validPos
                    break
                end
            end

            if not pos then
                log("WARNING: Could not find valid terrain for EWR near aerodrome - skipping")
                return
            end

            local units = {}
            for _, def in ipairs(ctx.template) do
                for c = 1, def.count do
                    units[#units + 1] = {
                        type = def.type,
                        x = pos.x + (c - 1) * 50,
                        y = pos.y,
                        heading = 0,
                        skill = "Excellent",
                    }
                end
            end

            local groupName = "EWR-" .. i

            Virtualization:registerPermanentGroup({
                name = groupName,
                center = pos,
                units = units,
                countryId = country.id.CJTF_RED,
                category = Group.Category.GROUND,
            })

            IADS:registerEWR(groupName)

            log("Generated EWR at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
        end,
        onComplete = function()
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- AIRBASE SHORAD GENERATION
-- =============================================================================

function BattlefieldGeneration:generateAirbaseSHORADSite(aerodrome, template)
    -- Position SHORAD close to the airbase (1-3 km) to defend against low-level attacks
    local minDist = 1000  -- 1 km minimum
    local maxDist = 3000  -- 3 km maximum

    -- Try multiple positions to find valid terrain
    local pos = nil
    local maxPositionAttempts = 5

    for attempt = 1, maxPositionAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)

        local initialPos = {
            x = aerodrome.x + distance * math.cos(angle),
            y = aerodrome.y + distance * math.sin(angle),
        }

        -- Validate terrain - SHORAD needs reasonably flat ground
        local validPos, found = Terrain:findValidPosition(initialPos, 500, {
            maxSlope = 12,
        })

        if found then
            pos = validPos
            break
        end
    end

    if not pos then
        log("WARNING: Could not find valid terrain for SHORAD near " .. aerodrome.name .. " - skipping")
        return
    end

    -- Apply template randomization and position in a defensive formation
    local randomizedTemplate = Formations:randomizeTemplate(template)
    local units = Formations:buildPlatoonUnits(randomizedTemplate, pos, {
        formation = Formations.FormationType.WEDGE,
        spacing = 40,
    })

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

    log("Generated airbase SHORAD for " .. aerodrome.name .. " at (" ..
        math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
end

-- Batched version of generateAirbaseSHORAD
function BattlefieldGeneration:generateAirbaseSHORADBatched(onComplete)
    local state = OperationInfinity.state
    local diff = state.difficulty
    local shoradTemplate = UnitTemplates.AirbaseSHORAD[diff]

    if not shoradTemplate or #shoradTemplate == 0 then
        log("No airbase SHORAD template for difficulty: " .. diff)
        if onComplete then onComplete() end
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
            if onComplete then onComplete() end
        end,
    })
end

env.info("[BattlefieldGeneration] Loaded successfully")
