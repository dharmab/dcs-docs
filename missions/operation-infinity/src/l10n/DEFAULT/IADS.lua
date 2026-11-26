-- =============================================================================
-- INTEGRATED AIR DEFENSE SYSTEM
-- Emission control for long-range SAM sites on Normal/Hard difficulties.
-- Rules in priority order:
--   1. HARM defense: go dark when an ARM aimed at the site gets close
--   2. Keep guiding: stay on while the site's own missiles are in flight
--   3. Cueing: turn on when an EWR track or spy report is inside cue range
--   4. Autonomous fallback: random pulses when no EWR is alive nearby
-- SHORAD (SA-8, SA-15) stays on DCS default AI as point defense.
-- =============================================================================

-- Guard against multiple script loads
if _G.IADSLoaded then
    env.info("[IADS] Script already loaded, skipping")
    return
end
_G.IADSLoaded = true

IADS = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

IADS.config = {
    updateInterval = 10, -- Seconds between main updates
    harmUpdateInterval = 2, -- Seconds between ARM checks while an ARM is in flight
    ewrDetectionRange = 250000, -- 250 km: a site with no live EWR this close runs autonomously
    cueRangeFraction = 0.75, -- Fraction of max range at which EWR/spy cues turn a site on
    autonomousRangeFraction = 0.5, -- Fraction of max range at which a pulsing site holds on its own track
    cueHoldTime = 20, -- Seconds a site stays on after its last cue (hysteresis)
    autonomousTrackHoldTime = 20, -- Seconds a pulsing site stays on after its own radar's last track
    harmConeDegrees = 15, -- Half-angle of the cone around an ARM's velocity vector
    darkPeriodMin = 60, -- Seconds a site stays dark after a HARM shutdown
    darkPeriodMax = 180,
    pulseOnMin = 10, -- Autonomous pulse on duration (seconds)
    pulseOnMax = 20,
    pulseOffMin = 90, -- Autonomous pulse off duration (seconds)
    pulseOffMax = 240,
    spyCycleMin = 120, -- Seconds between spy report cycles
    spyCycleMax = 240,
    spyDelayMin = 20, -- Seconds before a spy report reaches the IADS
    spyDelayMax = 40,
    spyReportDuration = 60, -- Seconds a spy report stays a cued target
    spyMaxAltitudeAGL = 1524, -- 5000 ft AGL
    spyTerritoryRadius = 60000, -- 60 km around each target aerodrome
}

-- HARM shutdown ETA rolls (seconds). Normal sites are scared and shut down
-- early; Hard sites are brave and keep emitting until the HARM is close.
local NORMAL_SHUTDOWN_ETA_MIN = 30
local NORMAL_SHUTDOWN_ETA_SPREAD = 30
local HARD_SHUTDOWN_ETA_MIN = 15
local HARD_SHUTDOWN_ETA_SPREAD = 15

-- Below this horizontal speed (m/s) an ARM's heading is meaningless
local MINIMUM_ARM_SPEED = 50

-- Delay before the first update after enable (seconds)
local INITIAL_UPDATE_DELAY = 5

-- Site types keyed by the samCounts key. maxRange is the launcher ThreatRange
-- from Quaggles' DCS Lua datamine (DCS 2.9.27). role "SAM" sites are under
-- emission control; role "SHORAD" sites stay on DCS default AI.
-- pointDefense names the SHORAD type paired 1-3 km from the site at generation.
IADS.siteTypes = {
    SA2 = { role = "SAM", maxRange = 43000 },
    SA3 = { role = "SAM", maxRange = 18000, pointDefense = "SA8" },
    SA6 = { role = "SAM", maxRange = 25000, pointDefense = "SA8" },
    SA10 = { role = "SAM", maxRange = 120000, pointDefense = "SA15" },
    SA11 = { role = "SAM", maxRange = 50000, pointDefense = "SA15" },
    SA8 = { role = "SHORAD" },
    SA15 = { role = "SHORAD" },
}

-- Difficulties with emission control
local EMISSION_CONTROL_DIFFICULTIES = {
    Normal = true,
    Hard = true,
}

-- =============================================================================
-- STATE
-- =============================================================================

IADS.state = {
    initialized = false,
    enabled = false,
    difficulty = nil,
    ewrs = {}, -- Array of {pGroup, name, center, alive}
    samSites = {}, -- Array of SAM site data
    sitesByGroupName = {}, -- Spawned group name -> SAM site
    trackedARMs = {}, -- Array of {weapon, rolls, triggered}
    harmLoopRunning = false,
    spyReports = {}, -- Array of {x, y, activeAt, expiresAt}
    nextSpyReportTime = 0,
    cuedTargets = {}, -- Cued targets from the last main update
}

local log = Logging:create("IADS")

local function randomBetween(min, max)
    return min + math.random() * (max - min)
end

-- =============================================================================
-- REGISTRATION
-- =============================================================================

-- pGroup: the table returned by Virtualization:registerPermanentGroup.
-- The live group name (pGroup.spawnedGroupName) is resolved at lookup time.
function IADS:registerEWR(pGroup)
    self.state.ewrs[#self.state.ewrs + 1] = {
        pGroup = pGroup,
        name = pGroup.name,
        center = pGroup.center,
        alive = true,
    }
    log("Registered EWR: " .. pGroup.name)
end

function IADS:registerSAMSite(pGroup, siteType, center)
    local typeData = self.siteTypes[siteType]
    if not typeData or typeData.role ~= "SAM" then
        log("Not under emission control: " .. pGroup.name .. " (" .. siteType .. ")")
        return nil
    end

    local samSite = {
        pGroup = pGroup,
        name = pGroup.name,
        siteType = siteType,
        center = center,
        maxRange = typeData.maxRange,
        cueRange = typeData.maxRange * self.config.cueRangeFraction,
        autonomousRange = typeData.maxRange * self.config.autonomousRangeFraction,
        alive = true,
        emitting = false,
        missiles = {}, -- Own missiles in flight
        lastCueTime = -math.huge,
        lastCueSource = nil,
        darkUntil = 0,
        autonomous = false,
        pulseOnUntil = nil,
        nextPulseTime = 0,
    }

    self.state.samSites[#self.state.samSites + 1] = samSite
    log(
        "Registered SAM site: "
            .. pGroup.name
            .. " ("
            .. siteType
            .. ", cue "
            .. math.floor(samSite.cueRange / 1000)
            .. " km)"
    )

    return samSite
end

-- =============================================================================
-- GROUP LOOKUP
-- =============================================================================

-- Returns the live DCS group for a permanent group, or nil if it is dead
local function getLiveGroup(pGroup)
    if not pGroup.spawnedGroupName then
        return nil
    end
    local group = Group.getByName(pGroup.spawnedGroupName)
    if not group or not group:isExist() or group:getSize() == 0 then
        return nil
    end
    return group
end

local function isBlueAircraft(object)
    if not object or not object:isExist() then
        return false
    end
    -- Detections include weapons, whose getDesc().category is a Weapon.Category
    -- value that can equal a Unit.Category value
    local objectIsUnit = object:getCategory() == Object.Category.UNIT
    if not objectIsUnit then
        return false
    end
    if object:getCoalition() ~= coalition.side.BLUE then
        return false
    end
    local category = object:getDesc().category
    return category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER
end

-- =============================================================================
-- EMISSION CONTROL
-- =============================================================================

function IADS:setEmission(samSite, active, reason)
    if samSite.emitting == active then
        return
    end

    local group = getLiveGroup(samSite.pGroup)
    if not group then
        return
    end

    group:enableEmission(active)
    samSite.emitting = active
    log(samSite.pGroup.spawnedGroupName .. " radar " .. (active and "ON" or "OFF") .. " (" .. reason .. ")")
end

-- =============================================================================
-- RULE 1: HARM DEFENSE
-- =============================================================================

function IADS:rollShutdownETA()
    local r = math.random()
    if self.state.difficulty == "Hard" then
        return HARD_SHUTDOWN_ETA_MIN + HARD_SHUTDOWN_ETA_SPREAD * r * r
    end
    return NORMAL_SHUTDOWN_ETA_MIN + NORMAL_SHUTDOWN_ETA_SPREAD * (1 - r * r)
end

function IADS:trackARM(weapon)
    self.state.trackedARMs[#self.state.trackedARMs + 1] = {
        weapon = weapon,
        rolls = {}, -- SAM site -> shutdown ETA roll
        triggered = {}, -- SAM site -> true once this ARM shut it down
    }
    log("Tracking ARM: " .. weapon:getTypeName() .. " (" .. #self.state.trackedARMs .. " in flight)")

    if not self.state.harmLoopRunning then
        self.state.harmLoopRunning = true
        log("HARM loop started")
        timer.scheduleFunction(function(_, time)
            return IADS:updateARMs()
        end, nil, timer.getTime() + self.config.harmUpdateInterval)
    end
end

function IADS:startDarkPeriod(samSite, now, reason)
    local darkUntil = now + randomBetween(self.config.darkPeriodMin, self.config.darkPeriodMax)
    if darkUntil > samSite.darkUntil then
        samSite.darkUntil = darkUntil
    end
    log(samSite.name .. " dark for " .. math.floor(samSite.darkUntil - now) .. "s (" .. reason .. ")")
    self:setEmission(samSite, false, reason)
end

function IADS:checkARM(arm, now)
    local pos = arm.weapon:getPoint()
    local vel = arm.weapon:getVelocity()
    -- Horizontal geometry only: HARMs loft, so the 3D velocity points high early on
    local speed = math.sqrt(vel.x * vel.x + vel.z * vel.z)
    if speed < MINIMUM_ARM_SPEED then
        return
    end

    local cosCone = math.cos(math.rad(self.config.harmConeDegrees))

    for _, samSite in ipairs(self.state.samSites) do
        if samSite.alive then
            local dx = samSite.center.x - pos.x
            local dy = samSite.center.y - pos.z
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 0 then
                local cosAngle = (dx * vel.x + dy * vel.z) / (distance * speed)
                if cosAngle >= cosCone then
                    local eta = distance / speed
                    local roll = arm.rolls[samSite]
                    if not roll then
                        roll = self:rollShutdownETA()
                        arm.rolls[samSite] = roll
                        log(
                            "ARM aimed at "
                                .. samSite.name
                                .. ": ETA "
                                .. math.floor(eta)
                                .. "s, shutdown at "
                                .. math.floor(roll)
                                .. "s"
                        )
                    end
                    if not arm.triggered[samSite] and eta <= roll then
                        arm.triggered[samSite] = true
                        self:startDarkPeriod(samSite, now, "HARM ETA " .. math.floor(eta) .. "s")
                    end
                end
            end
        end
    end
end

function IADS:updateARMs()
    local now = timer.getTime()
    local remaining = {}

    for _, arm in ipairs(self.state.trackedARMs) do
        if arm.weapon:isExist() then
            remaining[#remaining + 1] = arm
            self:checkARM(arm, now)
        end
    end
    self.state.trackedARMs = remaining

    if #remaining == 0 then
        self.state.harmLoopRunning = false
        log("HARM loop stopped: no ARMs in flight")
        return nil
    end

    return now + self.config.harmUpdateInterval
end

-- =============================================================================
-- RULE 2: KEEP GUIDING
-- =============================================================================

local function pruneMissiles(samSite)
    local remaining = {}
    for _, weapon in ipairs(samSite.missiles) do
        if weapon:isExist() then
            remaining[#remaining + 1] = weapon
        end
    end
    samSite.missiles = remaining
end

-- =============================================================================
-- RULE 3: CUEING
-- =============================================================================

-- Merge radar detections from all live EWRs, keyed by object ID
function IADS:getEWRTargets(cuedTargets)
    local seen = {}
    for _, ewr in ipairs(self.state.ewrs) do
        if ewr.alive then
            local group = getLiveGroup(ewr.pGroup)
            if not group then
                ewr.alive = false
                log("EWR destroyed: " .. ewr.name)
            else
                local targets = group:getController():getDetectedTargets(Controller.Detection.RADAR)
                for _, target in ipairs(targets) do
                    local object = target.object
                    if isBlueAircraft(object) then
                        local id = object:getID()
                        if not seen[id] then
                            seen[id] = true
                            local pos = object:getPoint()
                            cuedTargets[#cuedTargets + 1] = { x = pos.x, y = pos.z, source = "EWR cue" }
                        end
                    end
                end
            end
        end
    end
end

local function isInSpyTerritory(pos, aerodromes, radius)
    for _, aerodrome in ipairs(aerodromes) do
        if Spatial:getDistance2D(pos, aerodrome) < radius then
            return true
        end
    end
    return false
end

-- Civilians with phones report low-flying blue aircraft near the target aerodromes
function IADS:runSpyCycle(now)
    local aerodromes = OperationInfinity.state.battlefield.targetAerodromes
    local reported = 0

    for _, category in ipairs({ Group.Category.AIRPLANE, Group.Category.HELICOPTER }) do
        for _, group in ipairs(coalition.getGroups(coalition.side.BLUE, category)) do
            for _, unit in ipairs(group:getUnits()) do
                if unit:isExist() and unit:inAir() then
                    local pos = unit:getPoint()
                    local pos2D = { x = pos.x, y = pos.z }
                    local agl = pos.y - land.getHeight(pos2D)
                    if
                        agl < self.config.spyMaxAltitudeAGL
                        and isInSpyTerritory(pos2D, aerodromes, self.config.spyTerritoryRadius)
                    then
                        local activeAt = now + randomBetween(self.config.spyDelayMin, self.config.spyDelayMax)
                        self.state.spyReports[#self.state.spyReports + 1] = {
                            x = pos2D.x,
                            y = pos2D.y,
                            activeAt = activeAt,
                            expiresAt = activeAt + self.config.spyReportDuration,
                        }
                        reported = reported + 1
                    end
                end
            end
        end
    end

    log("Spy cycle: " .. reported .. " aircraft reported")
end

function IADS:getSpyTargets(now, cuedTargets)
    if now >= self.state.nextSpyReportTime then
        self:runSpyCycle(now)
        self.state.nextSpyReportTime = now + randomBetween(self.config.spyCycleMin, self.config.spyCycleMax)
    end

    local remaining = {}
    for _, report in ipairs(self.state.spyReports) do
        if now < report.expiresAt then
            remaining[#remaining + 1] = report
            if now >= report.activeAt then
                cuedTargets[#cuedTargets + 1] = { x = report.x, y = report.y, source = "spy report" }
            end
        end
    end
    self.state.spyReports = remaining
end

-- Returns the source of the first cued target inside the site's cue range
local function findCue(samSite, cuedTargets)
    for _, target in ipairs(cuedTargets) do
        if Spatial:getDistance2D(target, samSite.center) < samSite.cueRange then
            return target.source
        end
    end
    return nil
end

-- =============================================================================
-- RULE 4: AUTONOMOUS FALLBACK
-- =============================================================================

function IADS:hasLiveEWRNear(samSite)
    for _, ewr in ipairs(self.state.ewrs) do
        if ewr.alive and Spatial:getDistance2D(ewr.center, samSite.center) < self.config.ewrDetectionRange then
            return true
        end
    end
    return false
end

-- True when the site's own radar tracks a blue aircraft inside autonomous range
local function ownRadarHasTarget(samSite, group)
    local targets = group:getController():getDetectedTargets(Controller.Detection.RADAR)
    for _, target in ipairs(targets) do
        local object = target.object
        if isBlueAircraft(object) then
            local pos = object:getPoint()
            if Spatial:getDistance2D({ x = pos.x, y = pos.z }, samSite.center) < samSite.autonomousRange then
                return true
            end
        end
    end
    return false
end

function IADS:startPulse(samSite, now)
    local pulseOnUntil = now + randomBetween(self.config.pulseOnMin, self.config.pulseOnMax)
    samSite.pulseOnUntil = pulseOnUntil
    self:setEmission(samSite, true, "autonomous pulse")

    -- Pulses are shorter than the main loop, so end them on their own timer
    timer.scheduleFunction(function(_, time)
        if samSite.pulseOnUntil == pulseOnUntil then
            IADS:evaluateSite(samSite, timer.getTime(), IADS.state.cuedTargets)
        end
        return nil
    end, nil, pulseOnUntil)
end

function IADS:updatePulse(samSite, group, now)
    if samSite.pulseOnUntil then
        if now < samSite.pulseOnUntil then
            self:setEmission(samSite, true, "autonomous pulse")
            return
        end
        if ownRadarHasTarget(samSite, group) then
            samSite.pulseOnUntil = now + self.config.autonomousTrackHoldTime
            log(samSite.name .. " holding pulse on own radar track")
            self:setEmission(samSite, true, "autonomous track")
            return
        end
        samSite.pulseOnUntil = nil
        samSite.nextPulseTime = now + randomBetween(self.config.pulseOffMin, self.config.pulseOffMax)
        self:setEmission(samSite, false, "pulse over")
        return
    end

    if now >= samSite.nextPulseTime then
        self:startPulse(samSite, now)
        return
    end

    self:setEmission(samSite, false, "autonomous, between pulses")
end

-- =============================================================================
-- SITE EVALUATION
-- =============================================================================

function IADS:evaluateSite(samSite, now, cuedTargets)
    if not samSite.alive then
        return
    end

    local group = getLiveGroup(samSite.pGroup)
    if not group then
        samSite.alive = false
        samSite.emitting = false
        log("SAM site destroyed: " .. samSite.name)
        return
    end

    -- Rule 1: HARM dark period
    if now < samSite.darkUntil then
        self:setEmission(samSite, false, "HARM dark period")
        return
    end

    -- Rule 2: own missiles in flight
    pruneMissiles(samSite)
    if #samSite.missiles > 0 then
        self:setEmission(samSite, true, "guiding")
        return
    end

    -- Rule 3: EWR and spy cues, with hysteresis
    local cueSource = findCue(samSite, cuedTargets)
    if cueSource then
        samSite.lastCueTime = now
        samSite.lastCueSource = cueSource
    end
    if now - samSite.lastCueTime < self.config.cueHoldTime then
        self:setEmission(samSite, true, samSite.lastCueSource)
        return
    end

    -- Rule 4: autonomous fallback
    local autonomous = not self:hasLiveEWRNear(samSite)
    if autonomous ~= samSite.autonomous then
        samSite.autonomous = autonomous
        if autonomous then
            samSite.pulseOnUntil = nil
            samSite.nextPulseTime = now + randomBetween(self.config.pulseOffMin, self.config.pulseOffMax)
            log(
                samSite.name
                    .. " autonomous: no live EWR within "
                    .. math.floor(self.config.ewrDetectionRange / 1000)
                    .. " km"
            )
        end
    end
    if autonomous then
        self:updatePulse(samSite, group, now)
        return
    end

    self:setEmission(samSite, false, "no cue")
end

-- =============================================================================
-- MAIN LOOP
-- =============================================================================

function IADS:update()
    local now = timer.getTime()

    local cuedTargets = {}
    self:getEWRTargets(cuedTargets)
    self:getSpyTargets(now, cuedTargets)
    self.state.cuedTargets = cuedTargets

    for _, samSite in ipairs(self.state.samSites) do
        self:evaluateSite(samSite, now, cuedTargets)
    end

    return now + self.config.updateInterval
end

-- =============================================================================
-- EVENT HANDLER
-- =============================================================================

IADS.eventHandler = {}

function IADS.eventHandler:onEvent(event)
    if event.id ~= world.event.S_EVENT_SHOT or not event.weapon or not event.initiator then
        return
    end

    local ok, err = pcall(function()
        IADS:handleShot(event.initiator, event.weapon)
    end)
    if not ok then
        log("Error handling shot event: " .. tostring(err))
    end
end

function IADS:handleShot(initiator, weapon)
    if weapon:getDesc().guidance == Weapon.GuidanceType.RADAR_PASSIVE then
        if initiator:getCoalition() == coalition.side.BLUE then
            self:trackARM(weapon)
        end
        return
    end

    local group = initiator:getGroup()
    if not group then
        return
    end
    local samSite = self.state.sitesByGroupName[group:getName()]
    if samSite then
        samSite.missiles[#samSite.missiles + 1] = weapon
        log(samSite.name .. " fired " .. weapon:getTypeName() .. " (" .. #samSite.missiles .. " in flight)")
        self:setEmission(samSite, true, "guiding")
    end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- Called after Virtualization has spawned the permanent groups, so
-- spawnedGroupName is set for every registered site and EWR.
function IADS:enable(difficulty)
    self.state.difficulty = difficulty

    if not EMISSION_CONTROL_DIFFICULTIES[difficulty] then
        log("No emission control on " .. difficulty)
        return
    end

    self.state.enabled = true
    log(
        "Enabled with difficulty: "
            .. difficulty
            .. " ("
            .. #self.state.samSites
            .. " sites, "
            .. #self.state.ewrs
            .. " EWRs)"
    )

    -- Alarm state RED keeps tracks, so a site fires as soon as it emits
    for _, samSite in ipairs(self.state.samSites) do
        local group = getLiveGroup(samSite.pGroup)
        if group then
            self.state.sitesByGroupName[samSite.pGroup.spawnedGroupName] = samSite
            group:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
            group:enableEmission(false)
            samSite.emitting = false
        else
            samSite.alive = false
            log("WARNING: SAM site not spawned: " .. samSite.name)
        end
    end

    self.state.nextSpyReportTime = timer.getTime() + randomBetween(self.config.spyCycleMin, self.config.spyCycleMax)

    world.addEventHandler(self.eventHandler)

    timer.scheduleFunction(function(_, time)
        return IADS:update()
    end, nil, timer.getTime() + INITIAL_UPDATE_DELAY)
end

function IADS:init()
    if self.state.initialized then
        log("Already initialized!")
        return
    end

    self.state.initialized = true
    log("Initialization complete")
end

-- =============================================================================
-- STATS
-- =============================================================================

function IADS:getStats()
    local activeRadars = 0
    for _, samSite in ipairs(self.state.samSites) do
        if samSite.alive and samSite.emitting then
            activeRadars = activeRadars + 1
        end
    end

    return {
        enabled = self.state.enabled,
        difficulty = self.state.difficulty,
        ewrCount = #self.state.ewrs,
        samSiteCount = #self.state.samSites,
        activeRadars = activeRadars,
        trackedARMs = #self.state.trackedARMs,
    }
end

env.info("[IADS] Loaded successfully")
