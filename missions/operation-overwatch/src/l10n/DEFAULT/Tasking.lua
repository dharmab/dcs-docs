-- =============================================================================
-- TASKING
-- CAS tasking lifecycle: check-in, join, success, abandonment, and the
-- JTAC's radio calls.
--
-- A flight is a player group. Flights are keyed by group name.
-- =============================================================================

if _G.TaskingLoaded then
    env.info("[Tasking] Script already loaded, skipping")
    return
end
_G.TaskingLoaded = true

Tasking = {}

local log = Logging:create("Tasking")

local UPDATE_INTERVAL_SECONDS = 5
local FIRE_UPDATE_INTERVAL_SECONDS = 60
local BRIEF_DISPLAY_SECONDS = 60
local CALL_DISPLAY_SECONDS = 20
local LASER_HEIGHT_METERS = 1
-- The JTAC rounds the friendlies' range estimate
local ESTIMATE_ROUNDING_METERS = 100
-- The laser leaves from below the MQ-9
local LASER_LOCAL_POSITION = { x = 0, y = -1, z = 0 }

Tasking.Status = { ACTIVE = "active", ENDED = "ended" }
Tasking.EndReason = { SUCCESS = "success", ABANDONED = "abandoned" }

Tasking.scenarioNames = { firefight = "Troops in Contact" }

Tasking.state = {
    nextId = 1,
    taskings = {}, -- id -> tasking
    slots = {}, -- slot index -> tasking id
    flights = {}, -- group name -> flight
    lastFireUpdate = 0,
}

-- Called when the set of active taskings changes. OperationOverwatch sets it
-- to rebuild every flight's Join Tasking menu.
local onTaskingsChanged = function() end

function Tasking:setOnTaskingsChanged(callback)
    onTaskingsChanged = callback
end

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function unitIsAlive(name)
    local unit = Unit.getByName(name)
    if not unit then
        return false
    end
    local unitExists = unit:isExist()
    local unitHasLife = unit:getLife() > 0
    return unitExists and unitHasLife
end

local function countAlive(names)
    local alive = 0
    for _, name in ipairs(names) do
        if unitIsAlive(name) then
            alive = alive + 1
        end
    end
    return alive
end

local function toVec3(point)
    return { x = point.x, y = land.getHeight({ x = point.x, y = point.y }), z = point.y }
end

local function messageFlight(flight, text, seconds)
    trigger.action.outTextForGroup(flight.groupId, text, seconds or CALL_DISPLAY_SECONDS)
end

function Tasking:messageAssigned(tasking, text, seconds)
    for groupName in pairs(tasking.flights) do
        local flight = self.state.flights[groupName]
        if flight then
            messageFlight(flight, text, seconds)
        end
    end
end

function Tasking:formatGrid(point)
    local lat, lon = coord.LOtoLL({ x = point.x, y = 0, z = point.y })
    local mgrs = coord.LLtoMGRS(lat, lon)
    return string.format(
        "%s%s %05d %05d",
        mgrs.UTMZone,
        mgrs.MGRSDigraph,
        math.floor(mgrs.Easting),
        math.floor(mgrs.Northing)
    )
end

-- -----------------------------------------------------------------------------
-- Queries
-- -----------------------------------------------------------------------------

-- Active taskings, most recent first
function Tasking:activeList()
    local list = {}
    for _, tasking in pairs(self.state.taskings) do
        if tasking.status == self.Status.ACTIVE then
            list[#list + 1] = tasking
        end
    end
    table.sort(list, function(a, b)
        return a.id > b.id
    end)
    return list
end

function Tasking:activeCount()
    return #self:activeList()
end

function Tasking:freeSlot()
    local slotCount = #OperationOverwatch.config.jtacSlots
    for index = 1, slotCount do
        if not self.state.slots[index] then
            return index
        end
    end
    return nil
end

-- "Axeman: Troops in Contact, 41R QQ 12345 67890"
function Tasking:describe(tasking)
    local scenarioName = self.scenarioNames[tasking.scenario]
    return tasking.slot.callsign .. ": " .. scenarioName .. ", " .. self:formatGrid(tasking.spawned.friendlyCenter)
end

function Tasking:assignedFlightCount(tasking)
    local count = 0
    for _ in pairs(tasking.flights) do
        count = count + 1
    end
    return count
end

-- -----------------------------------------------------------------------------
-- JTAC radio calls
-- -----------------------------------------------------------------------------

function Tasking:keyUnitDescription(tasking)
    local counts = {}
    local order = {}
    for _, unit in ipairs(tasking.force.units) do
        if unit.key then
            if not counts[unit.role] then
                counts[unit.role] = 0
                order[#order + 1] = unit.role
            end
            counts[unit.role] = counts[unit.role] + 1
        end
    end
    local labels = {
        [EnemyForce.Role.TECHNICAL] = "technical",
        [EnemyForce.Role.ZU23] = "ZU-23",
    }
    local parts = {}
    for _, role in ipairs(order) do
        local count = counts[role]
        local label = labels[role] or role
        parts[#parts + 1] = count .. " x " .. label .. (count > 1 and "s" or "")
    end
    return parts
end

function Tasking:briefText(tasking)
    local spawned = tasking.spawned
    local slot = tasking.slot
    local distance = Spatial:getDistance2D(spawned.friendlyCenter, spawned.enemyCenter)
    local bearing = Sites:bearingDegrees(spawned.friendlyCenter, spawned.enemyCenter)
    local riflemen = EnemyForce:countRole(tasking.force, EnemyForce.Role.RIFLEMAN)
        + EnemyForce:countRole(tasking.force, EnemyForce.Role.RPG)

    local lines = {
        string.format("%s, %.2f %s. Troops in contact.", slot.callsign, slot.frequency, slot.modulationName),
        "Friendlies: " .. self:formatGrid(spawned.friendlyCenter) .. ", marked by green smoke.",
        -- Friendlies cannot see the shooters at these ranges, so the count and
        -- the mark are estimates
        string.format(
            "Friendlies taking fire from an estimated %d dismounts, %03d true, %d meters. "
                .. "Friendlies cannot see the shooters. Red smoke marks the approximate enemy position.",
            riflemen,
            bearing,
            math.floor(distance / ESTIMATE_ROUNDING_METERS + 0.5) * ESTIMATE_ROUNDING_METERS
        ),
    }
    local keyUnits = self:keyUnitDescription(tasking)
    if #keyUnits > 0 then
        lines[#lines + 1] = "Priority targets: "
            .. table.concat(keyUnits, ", ")
            .. ". Laser on priority targets, code "
            .. OperationOverwatch.config.laserCode
            .. "."
    end
    if tasking.samWarning then
        lines[#lines + 1] = "Reports of a SAM team in the area."
    end
    lines[#lines + 1] = "Cleared hot on the enemy position. Do not engage within 100 meters of friendlies."
    return table.concat(lines, "\n")
end

-- -----------------------------------------------------------------------------
-- Marks
-- -----------------------------------------------------------------------------

function Tasking:popSmoke(tasking)
    local spawned = tasking.spawned
    trigger.action.smoke(toVec3(spawned.friendlyCenter), trigger.smokeColor.Green)
    trigger.action.smoke(toVec3(spawned.enemyCenter), trigger.smokeColor.Red)
end

-- Keep the laser on the first living key unit
function Tasking:updateLaser(tasking)
    local jtac = tasking.spawned.jtacUnitName and Unit.getByName(tasking.spawned.jtacUnitName)
    local target
    for _, name in ipairs(tasking.spawned.keyUnitNames) do
        if unitIsAlive(name) then
            target = Unit.getByName(name)
            break
        end
    end

    if not (jtac and target) then
        if tasking.laser then
            tasking.laser:destroy()
            tasking.laser = nil
        end
        return
    end

    local point = target:getPoint()
    local aim = { x = point.x, y = point.y + LASER_HEIGHT_METERS, z = point.z }
    if tasking.laser then
        tasking.laser:setPoint(aim)
    else
        tasking.laser = Spot.createLaser(jtac, LASER_LOCAL_POSITION, aim, OperationOverwatch.config.laserCode)
    end
end

-- -----------------------------------------------------------------------------
-- Flights
-- -----------------------------------------------------------------------------

-- Register or refresh a flight. category: "fixed" or "rotary"
function Tasking:registerFlight(groupName, groupId, category)
    local flight = self.state.flights[groupName]
    if not flight then
        flight = { groupName = groupName, groupId = groupId, category = category, taskingId = nil }
        self.state.flights[groupName] = flight
    end
    flight.groupId = groupId
    flight.category = category
    return flight
end

function Tasking:assign(flight, tasking)
    if flight.taskingId == tasking.id then
        messageFlight(flight, self:briefText(tasking), BRIEF_DISPLAY_SECONDS)
        return
    end
    self:release(flight)
    flight.taskingId = tasking.id
    tasking.flights[flight.groupName] = true
    tasking.lastFlightLeftAt = nil
    log(flight.groupName .. " assigned to tasking " .. tasking.id)
    messageFlight(flight, self:briefText(tasking), BRIEF_DISPLAY_SECONDS)
    self:popSmoke(tasking)
end

-- Remove a flight from its tasking (landed, died, left, or re-tasked)
function Tasking:release(flight)
    local tasking = flight.taskingId and self.state.taskings[flight.taskingId]
    flight.taskingId = nil
    if not tasking then
        return
    end
    tasking.flights[flight.groupName] = nil
    log(flight.groupName .. " released from tasking " .. tasking.id)
    local taskingIsActive = tasking.status == self.Status.ACTIVE
    local noFlightsRemain = self:assignedFlightCount(tasking) == 0
    if taskingIsActive and noFlightsRemain then
        tasking.lastFlightLeftAt = timer.getTime()
    end
end

function Tasking:removeFlight(groupName)
    local flight = self.state.flights[groupName]
    if flight then
        self:release(flight)
        self.state.flights[groupName] = nil
    end
end

-- -----------------------------------------------------------------------------
-- Creating and ending taskings
-- -----------------------------------------------------------------------------

function Tasking:create(flightCategory)
    local config = OperationOverwatch.config
    local slotIndex = self:freeSlot()
    if not slotIndex then
        return nil, "full"
    end

    local center = Sites:pickTaskingCenter(flightCategory)
    if not center then
        return nil, "nosite"
    end

    local force = EnemyForce:roll(flightCategory)
    local warningChance = force.hasManpads and config.samWarningChance.withManpads
        or config.samWarningChance.withoutManpads

    local tasking = {
        id = self.state.nextId,
        slotIndex = slotIndex,
        slot = config.jtacSlots[slotIndex],
        scenario = "firefight",
        flightCategory = flightCategory,
        status = self.Status.ACTIVE,
        createdAt = timer.getTime(),
        center = center,
        force = force,
        samWarning = math.random() < warningChance,
        manpadsLaunched = false,
        flights = {},
        lastFlightLeftAt = nil,
    }

    local spawned = Firefight:spawn(tasking)
    if not spawned then
        return nil, "nosite"
    end
    tasking.spawned = spawned
    tasking.initialEnemyCount = #spawned.enemyUnitNames

    self.state.nextId = self.state.nextId + 1
    self.state.taskings[tasking.id] = tasking
    self.state.slots[slotIndex] = tasking.id
    log("Created tasking " .. tasking.id .. " in slot " .. slotIndex .. " for " .. flightCategory)
    self:updateLaser(tasking)
    onTaskingsChanged()
    return tasking
end

function Tasking:destroyGroups(tasking)
    for _, name in ipairs(tasking.spawned.groupNames) do
        local group = Group.getByName(name)
        if group and group:isExist() then
            group:destroy()
        end
    end
end

function Tasking:finish(tasking, reason)
    if tasking.status ~= self.Status.ACTIVE then
        return
    end
    local config = OperationOverwatch.config
    tasking.status = self.Status.ENDED
    tasking.endReason = reason
    if tasking.laser then
        tasking.laser:destroy()
        tasking.laser = nil
    end
    -- The slot is freed below, so a new tasking can spawn a JTAC with the same
    -- callsign and frequency right away. Remove this one now so they never
    -- overlap.
    local jtac = tasking.spawned.jtacGroupName and Group.getByName(tasking.spawned.jtacGroupName)
    if jtac and jtac:isExist() then
        jtac:destroy()
    end

    if reason == self.EndReason.SUCCESS then
        self:messageAssigned(
            tasking,
            tasking.slot.callsign .. ": Good effects. Enemy is broken and withdrawing. Tasking complete.",
            CALL_DISPLAY_SECONDS
        )
        -- Leave the scene up briefly so players see the result
        timer.scheduleFunction(function()
            Tasking:destroyGroups(tasking)
        end, nil, timer.getTime() + config.removalDelaySeconds)
    else
        self:destroyGroups(tasking)
    end

    for groupName in pairs(tasking.flights) do
        local flight = self.state.flights[groupName]
        if flight then
            flight.taskingId = nil
        end
    end
    tasking.flights = {}
    self.state.slots[tasking.slotIndex] = nil
    log("Tasking " .. tasking.id .. " ended: " .. reason)
    onTaskingsChanged()
end

-- -----------------------------------------------------------------------------
-- Evaluation
-- -----------------------------------------------------------------------------

-- Success when every key unit is destroyed or config.successFraction of the
-- enemy force is destroyed
function Tasking:isSuccessful(tasking)
    local spawned = tasking.spawned
    local keyUnitsAlive = countAlive(spawned.keyUnitNames)
    local hasKeyUnits = #spawned.keyUnitNames > 0
    local allKeyUnitsDestroyed = hasKeyUnits and keyUnitsAlive == 0

    local enemyAlive = countAlive(spawned.enemyUnitNames)
    local destroyedFraction = 1 - enemyAlive / tasking.initialEnemyCount
    local enoughEnemyDestroyed = destroyedFraction >= OperationOverwatch.config.successFraction

    return allKeyUnitsDestroyed or enoughEnemyDestroyed
end

function Tasking:isAbandoned(tasking)
    if not tasking.lastFlightLeftAt then
        return false
    end
    local idleSeconds = timer.getTime() - tasking.lastFlightLeftAt
    return idleSeconds >= OperationOverwatch.config.abandonedTimeoutSeconds
end

function Tasking:update()
    local now = timer.getTime()
    local fireUpdateIsDue = now - self.state.lastFireUpdate >= FIRE_UPDATE_INTERVAL_SECONDS
    for _, tasking in ipairs(self:activeList()) do
        if self:isSuccessful(tasking) then
            self:finish(tasking, self.EndReason.SUCCESS)
        elseif self:isAbandoned(tasking) then
            self:finish(tasking, self.EndReason.ABANDONED)
        else
            self:updateLaser(tasking)
            if fireUpdateIsDue then
                Firefight:updateFireTargets(tasking.spawned)
            end
        end
    end
    if fireUpdateIsDue then
        self.state.lastFireUpdate = now
    end
end

function Tasking:start()
    timer.scheduleFunction(function(_, time)
        local ok, err = pcall(Tasking.update, Tasking)
        if not ok then
            env.error("[Tasking] update failed: " .. tostring(err))
        end
        return time + UPDATE_INTERVAL_SECONDS
    end, nil, timer.getTime() + UPDATE_INTERVAL_SECONDS)
end

-- -----------------------------------------------------------------------------
-- Events
-- -----------------------------------------------------------------------------

function Tasking:findByUnit(unitName, listKey)
    for _, tasking in ipairs(self:activeList()) do
        for _, name in ipairs(tasking.spawned[listKey]) do
            if name == unitName then
                return tasking
            end
        end
    end
    return nil
end

-- The JTAC calls a MANPADS launch with a bearing from the friendlies, and
-- the MANPADS becomes a key unit
function Tasking:onShot(shooterName)
    for _, tasking in ipairs(self:activeList()) do
        local shooterIsManpads = tasking.spawned.manpadsUnitName == shooterName
        if shooterIsManpads and not tasking.manpadsLaunched then
            tasking.manpadsLaunched = true
            local spawned = tasking.spawned
            spawned.keyUnitNames[#spawned.keyUnitNames + 1] = shooterName
            local manpads = Unit.getByName(shooterName)
            local p = manpads:getPoint()
            local bearing = Sites:bearingDegrees(spawned.friendlyCenter, { x = p.x, y = p.z })
            local distance = Spatial:getDistance2D(spawned.friendlyCenter, { x = p.x, y = p.z })
            local text = string.format(
                "%s: SAM launch, SAM launch! Launch point %03d true, %d meters from friendlies.",
                tasking.slot.callsign,
                bearing,
                math.floor(distance)
            )
            self:messageAssigned(tasking, text, CALL_DISPLAY_SECONDS)
            log("Tasking " .. tasking.id .. ": MANPADS launch, now a key unit")
            return
        end
    end
end

function Tasking:onFriendlyHit(targetName, initiatorIsPlayer)
    if not initiatorIsPlayer then
        return
    end
    local tasking = self:findByUnit(targetName, "friendlyUnitNames")
    if tasking then
        self:messageAssigned(
            tasking,
            tasking.slot.callsign .. ": CEASE FIRE, CEASE FIRE! Friendlies hit!",
            CALL_DISPLAY_SECONDS
        )
        log("Tasking " .. tasking.id .. ": player hit friendly unit " .. targetName)
    end
end

env.info("[Tasking] Loaded successfully")
