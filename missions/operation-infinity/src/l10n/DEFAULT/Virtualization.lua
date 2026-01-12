-- =============================================================================
-- VIRTUALIZATION SYSTEM
-- Spawns/despawns ground units based on player proximity to reduce unit count
-- =============================================================================

-- Guard against multiple script loads
if _G.VirtualizationLoaded then
    env.info("[Virtualization] Script already loaded, skipping")
    return
end
_G.VirtualizationLoaded = true

Virtualization = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

Virtualization.config = {
    spawnDistance = 185200,      -- 100 nm in meters
    despawnDistance = 222240,    -- 120 nm in meters (hysteresis)
    updateInterval = 15,         -- Seconds between update checks
    debug = true,
}

-- =============================================================================
-- STATE
-- =============================================================================

Virtualization.state = {
    initialized = false,
    virtualGroups = {},          -- Array of virtual group definitions
    permanentGroups = {},        -- Groups that are always spawned (EWRs, radars)
    groupCounter = 1000,
    unitCounter = 1000,
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

function Virtualization:log(message)
    if self.config.debug then
        env.info("[Virtualization] " .. message)
    end
end

function Virtualization:getNextGroupId()
    self.state.groupCounter = self.state.groupCounter + 1
    return self.state.groupCounter
end

function Virtualization:getNextUnitId()
    self.state.unitCounter = self.state.unitCounter + 1
    return self.state.unitCounter
end

function Virtualization:getDistance2D(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

-- =============================================================================
-- GROUP REGISTRATION
-- =============================================================================

function Virtualization:registerGroup(groupData, options)
    options = options or {}

    local vGroup = {
        name = groupData.name,
        category = groupData.category or Group.Category.GROUND,
        countryId = groupData.countryId or country.id.CJTF_RED,
        coalition = coalition.side.RED,
        center = groupData.center,
        units = groupData.units,
        isSpawned = false,
        spawnedGroupName = nil,
        options = {
            immortal = options.immortal or false,
            invisible = options.invisible or false,
            holdFire = options.holdFire or false,
            task = options.task or nil,
            fireAtPoint = options.fireAtPoint or nil,
        },
    }

    table.insert(self.state.virtualGroups, vGroup)
    self:log("Registered virtual group: " .. vGroup.name .. " with " .. #vGroup.units .. " units")

    return vGroup
end

function Virtualization:registerPermanentGroup(groupData, options)
    options = options or {}

    local pGroup = {
        name = groupData.name,
        category = groupData.category or Group.Category.GROUND,
        countryId = groupData.countryId or country.id.CJTF_RED,
        coalition = coalition.side.RED,
        center = groupData.center,
        units = groupData.units,
        isSpawned = false,
        spawnedGroupName = nil,
        options = {
            immortal = options.immortal or false,
            invisible = options.invisible or false,
            holdFire = options.holdFire or false,
            task = options.task or nil,
            fireAtPoint = options.fireAtPoint or nil,
        },
    }

    table.insert(self.state.permanentGroups, pGroup)
    self:log("Registered permanent group: " .. pGroup.name)

    return pGroup
end

-- =============================================================================
-- SPAWNING AND DESPAWNING
-- =============================================================================

function Virtualization:buildGroupData(vGroup)
    local groupId = self:getNextGroupId()
    local groupName = vGroup.name .. "-" .. groupId
    local units = {}

    for i, vUnit in ipairs(vGroup.units) do
        if vUnit.health == nil or vUnit.health > 0 then
            local unitId = self:getNextUnitId()
            units[#units + 1] = {
                unitId = unitId,
                name = groupName .. "-Unit-" .. i,
                type = vUnit.type,
                skill = vUnit.skill or "Average",
                x = vUnit.x,
                y = vUnit.y,
                heading = vUnit.heading or 0,
                playerCanDrive = false,
            }
        end
    end

    if #units == 0 then
        return nil
    end

    local tasks = {}

    if vGroup.options.immortal then
        tasks[#tasks + 1] = {
            enabled = true,
            auto = false,
            id = "WrappedAction",
            number = #tasks + 1,
            params = {
                action = {
                    id = "SetImmortal",
                    params = {value = true},
                },
            },
        }
    end

    if vGroup.options.invisible then
        tasks[#tasks + 1] = {
            enabled = true,
            auto = false,
            id = "WrappedAction",
            number = #tasks + 1,
            params = {
                action = {
                    id = "SetInvisible",
                    params = {value = true},
                },
            },
        }
    end

    if vGroup.options.holdFire then
        -- ROE option 0 = AI.Option.Ground.id.ROE, value 4 = WEAPON_HOLD
        tasks[#tasks + 1] = {
            enabled = true,
            auto = false,
            id = "WrappedAction",
            number = #tasks + 1,
            params = {
                action = {
                    id = "Option",
                    params = {
                        name = 0,  -- AI.Option.Ground.id.ROE
                        value = 4, -- AI.Option.Ground.val.ROE.WEAPON_HOLD
                    },
                },
            },
        }
    end

    if vGroup.options.fireAtPoint then
        tasks[#tasks + 1] = {
            enabled = true,
            auto = false,
            id = "FireAtPoint",
            number = #tasks + 1,
            params = {
                x = vGroup.options.fireAtPoint.x,
                y = vGroup.options.fireAtPoint.y,
                radius = vGroup.options.fireAtPoint.radius or 50,
                expendQty = vGroup.options.fireAtPoint.expendQty or 200,
                expendQtyEnabled = true,
                templateId = "",
                zoneRadius = vGroup.options.fireAtPoint.radius or 50,
            },
        }
    end

    local groupData = {
        groupId = groupId,
        name = groupName,
        task = "Ground Nothing",
        visible = false,
        hidden = false,
        start_time = 0,
        x = vGroup.center.x,
        y = vGroup.center.y,
        units = units,
        route = {
            points = {
                [1] = {
                    x = vGroup.center.x,
                    y = vGroup.center.y,
                    alt = 0,
                    alt_type = "BARO",
                    type = "Turning Point",
                    action = "Off Road",
                    speed = 0,
                    speed_locked = true,
                    ETA = 0,
                    ETA_locked = true,
                    task = {
                        id = "ComboTask",
                        params = {
                            tasks = tasks,
                        },
                    },
                },
            },
        },
    }

    return groupData
end

function Virtualization:spawnGroup(vGroup)
    local groupData = self:buildGroupData(vGroup)

    if not groupData then
        self:log("Cannot spawn " .. vGroup.name .. " - all units destroyed")
        return nil
    end

    local group = coalition.addGroup(vGroup.countryId, vGroup.category, groupData)

    if group then
        vGroup.isSpawned = true
        vGroup.spawnedGroupName = groupData.name
        self:log("Spawned group: " .. groupData.name .. " with " .. #groupData.units .. " units")
        return group
    else
        self:log("Failed to spawn group: " .. vGroup.name)
        return nil
    end
end

function Virtualization:despawnGroup(vGroup)
    if not vGroup.isSpawned or not vGroup.spawnedGroupName then
        return
    end

    local group = Group.getByName(vGroup.spawnedGroupName)

    if group and group:isExist() then
        local units = group:getUnits()

        for i, vUnit in ipairs(vGroup.units) do
            local liveUnit = units[i]
            if liveUnit and liveUnit:isExist() then
                local life = liveUnit:getLife()
                local life0 = liveUnit:getLife0()
                if life0 > 0 then
                    vUnit.health = life / life0
                else
                    vUnit.health = 1.0
                end
            else
                vUnit.health = 0
            end
        end

        group:destroy()
        self:log("Despawned group: " .. vGroup.spawnedGroupName)
    end

    vGroup.isSpawned = false
    vGroup.spawnedGroupName = nil
end

function Virtualization:spawnPermanentGroups()
    for _, pGroup in ipairs(self.state.permanentGroups) do
        if not pGroup.isSpawned then
            local groupData = self:buildGroupData(pGroup)
            if groupData then
                local group = coalition.addGroup(pGroup.countryId, pGroup.category, groupData)
                if group then
                    pGroup.isSpawned = true
                    pGroup.spawnedGroupName = groupData.name
                    self:log("Spawned permanent group: " .. groupData.name)
                end
            end
        end
    end
end

-- Batched version of spawnPermanentGroups
function Virtualization:spawnPermanentGroupsBatched(onComplete)
    -- Filter to only unspawned permanent groups
    local toSpawn = {}
    for _, pGroup in ipairs(self.state.permanentGroups) do
        if not pGroup.isSpawned then
            table.insert(toSpawn, pGroup)
        end
    end

    if #toSpawn == 0 then
        if onComplete then onComplete() end
        return
    end

    self:log("Spawning " .. #toSpawn .. " permanent groups (batched)")

    BatchScheduler:processArray({
        array = toSpawn,
        callback = function(pGroup)
            local groupData = Virtualization:buildGroupData(pGroup)
            if groupData then
                local group = coalition.addGroup(pGroup.countryId, pGroup.category, groupData)
                if group then
                    pGroup.isSpawned = true
                    pGroup.spawnedGroupName = groupData.name
                    Virtualization:log("Spawned permanent group: " .. groupData.name)
                end
            end
        end,
        onComplete = function()
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- PLAYER PROXIMITY CHECKING
-- =============================================================================

function Virtualization:getClosestPlayerDistance(vGroup)
    local players = coalition.getPlayers(coalition.side.BLUE)
    local minDistance = math.huge

    for _, player in ipairs(players) do
        if player and player:isExist() then
            local pos = player:getPoint()
            local playerPos2D = {x = pos.x, y = pos.z}
            local distance = self:getDistance2D(playerPos2D, vGroup.center)
            if distance < minDistance then
                minDistance = distance
            end
        end
    end

    return minDistance
end

-- =============================================================================
-- UPDATE LOOP
-- =============================================================================

function Virtualization:update()
    local players = coalition.getPlayers(coalition.side.BLUE)

    if #players == 0 then
        return timer.getTime() + self.config.updateInterval
    end

    -- Cache player positions once per update cycle
    local playerPositions = {}
    for _, player in ipairs(players) do
        if player and player:isExist() then
            local pos = player:getPoint()
            table.insert(playerPositions, { x = pos.x, y = pos.z })
        end
    end

    if #playerPositions == 0 then
        return timer.getTime() + self.config.updateInterval
    end

    -- Start batched processing of virtual groups
    self:updateBatched(playerPositions)

    return timer.getTime() + self.config.updateInterval
end

-- Process virtual groups with time-budgeted batching
function Virtualization:updateBatched(playerPositions)
    local spawnQueue = {}
    local despawnQueue = {}

    -- Use time-budgeted processing for distance checks
    local startTime = timer.getTime() * 1000
    local budgetMs = BatchScheduler.config.frameBudgetMs
    local itemsProcessed = 0

    for _, vGroup in ipairs(self.state.virtualGroups) do
        -- Calculate minimum distance to any player using cached positions
        local minDist = math.huge
        for _, pPos in ipairs(playerPositions) do
            local dist = self:getDistance2D(pPos, vGroup.center)
            if dist < minDist then
                minDist = dist
            end
        end

        -- Queue spawn/despawn decisions
        if vGroup.isSpawned and minDist > self.config.despawnDistance then
            table.insert(despawnQueue, vGroup)
        elseif not vGroup.isSpawned and minDist < self.config.spawnDistance then
            table.insert(spawnQueue, vGroup)
        end

        itemsProcessed = itemsProcessed + 1

        -- Check time budget (but process at least 1 item)
        local elapsed = (timer.getTime() * 1000) - startTime
        if itemsProcessed >= 1 and elapsed >= budgetMs then
            -- Schedule remaining groups for next frame
            local remaining = {}
            local foundCurrent = false
            for _, g in ipairs(self.state.virtualGroups) do
                if foundCurrent then
                    table.insert(remaining, g)
                elseif g == vGroup then
                    foundCurrent = true
                end
            end
            if #remaining > 0 then
                timer.scheduleFunction(function()
                    Virtualization:updateBatchedContinue(remaining, playerPositions, spawnQueue, despawnQueue)
                end, nil, timer.getTime() + 0.001)
                return
            end
            break
        end
    end

    -- Process queues
    self:processQueues(despawnQueue, spawnQueue)
end

-- Continue processing remaining virtual groups
function Virtualization:updateBatchedContinue(groups, playerPositions, spawnQueue, despawnQueue)
    local startTime = timer.getTime() * 1000
    local budgetMs = BatchScheduler.config.frameBudgetMs
    local itemsProcessed = 0

    for idx, vGroup in ipairs(groups) do
        local minDist = math.huge
        for _, pPos in ipairs(playerPositions) do
            local dist = self:getDistance2D(pPos, vGroup.center)
            if dist < minDist then
                minDist = dist
            end
        end

        if vGroup.isSpawned and minDist > self.config.despawnDistance then
            table.insert(despawnQueue, vGroup)
        elseif not vGroup.isSpawned and minDist < self.config.spawnDistance then
            table.insert(spawnQueue, vGroup)
        end

        itemsProcessed = itemsProcessed + 1

        local elapsed = (timer.getTime() * 1000) - startTime
        if itemsProcessed >= 1 and elapsed >= budgetMs then
            local remaining = {}
            for i = idx + 1, #groups do
                table.insert(remaining, groups[i])
            end
            if #remaining > 0 then
                timer.scheduleFunction(function()
                    Virtualization:updateBatchedContinue(remaining, playerPositions, spawnQueue, despawnQueue)
                end, nil, timer.getTime() + 0.001)
                return
            end
            break
        end
    end

    self:processQueues(despawnQueue, spawnQueue)
end

-- Process spawn and despawn queues with time budgeting
function Virtualization:processQueues(despawnQueue, spawnQueue)
    -- Process despawns first (frees resources)
    if #despawnQueue > 0 then
        BatchScheduler:processArray({
            array = despawnQueue,
            callback = function(vGroup)
                Virtualization:despawnGroup(vGroup)
            end,
            onComplete = function()
                -- Then process spawns
                if #spawnQueue > 0 then
                    BatchScheduler:processArray({
                        array = spawnQueue,
                        callback = function(vGroup)
                            Virtualization:spawnGroup(vGroup)
                        end,
                    })
                end
            end,
        })
    elseif #spawnQueue > 0 then
        BatchScheduler:processArray({
            array = spawnQueue,
            callback = function(vGroup)
                Virtualization:spawnGroup(vGroup)
            end,
        })
    end
end

-- =============================================================================
-- EVENT HANDLER
-- =============================================================================

Virtualization.eventHandler = {}

function Virtualization.eventHandler:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD or
       event.id == world.event.S_EVENT_CRASH or
       event.id == world.event.S_EVENT_UNIT_LOST then

        local unit = event.initiator
        if unit then
            local unitName = unit:getName()
            Virtualization:handleUnitDeath(unitName)
        end
    end
end

function Virtualization:handleUnitDeath(unitName)
    for _, vGroup in ipairs(self.state.virtualGroups) do
        if vGroup.isSpawned and vGroup.spawnedGroupName then
            if string.find(unitName, vGroup.spawnedGroupName, 1, true) then
                for i, vUnit in ipairs(vGroup.units) do
                    if string.find(unitName, "Unit-" .. i, 1, true) then
                        vUnit.health = 0
                        self:log("Unit killed: " .. unitName)
                        return
                    end
                end
            end
        end
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function Virtualization:init()
    if self.state.initialized then
        self:log("Already initialized!")
        return
    end

    self:log("Initializing Virtualization System...")

    world.addEventHandler(self.eventHandler)

    timer.scheduleFunction(function(_, time)
        return Virtualization:update()
    end, nil, timer.getTime() + 5)

    self.state.initialized = true
    self:log("Initialization complete")
end

-- =============================================================================
-- API
-- =============================================================================

function Virtualization:getStats()
    local total = #self.state.virtualGroups
    local spawned = 0
    local totalUnits = 0
    local spawnedUnits = 0

    for _, vGroup in ipairs(self.state.virtualGroups) do
        totalUnits = totalUnits + #vGroup.units
        if vGroup.isSpawned then
            spawned = spawned + 1
            for _, vUnit in ipairs(vGroup.units) do
                if vUnit.health == nil or vUnit.health > 0 then
                    spawnedUnits = spawnedUnits + 1
                end
            end
        end
    end

    return {
        totalGroups = total,
        spawnedGroups = spawned,
        totalUnits = totalUnits,
        spawnedUnits = spawnedUnits,
    }
end

function Virtualization:clear()
    for _, vGroup in ipairs(self.state.virtualGroups) do
        if vGroup.isSpawned then
            self:despawnGroup(vGroup)
        end
    end

    self.state.virtualGroups = {}
    self:log("Cleared all virtual groups")
end

env.info("[Virtualization] Loaded successfully")
