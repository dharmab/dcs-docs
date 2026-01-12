-- =============================================================================
-- INTEGRATED AIR DEFENSE SYSTEM
-- Emission control for SAM sites on Normal/Hard difficulties
-- EWRs always active, SAM radars pulse based on threat detection
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
    updateInterval = 10,          -- Seconds between radar state updates
    ewrDetectionRange = 250000,   -- 250 km (EWR detection range)
    samActivationRange = 60000,   -- 60 km (SAM radar activation threshold)
    pulseOnDuration = 30,         -- Seconds radar stays on
    pulseOffDuration = 45,        -- Seconds radar stays off
    debug = true,
}

-- =============================================================================
-- STATE
-- =============================================================================

IADS.state = {
    initialized = false,
    enabled = false,
    difficulty = nil,
    ewrGroups = {},               -- Array of registered EWR group names
    samSites = {},                -- Array of SAM site data
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

function IADS:log(message)
    if self.config.debug then
        env.info("[IADS] " .. message)
    end
end

function IADS:getDistance2D(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

-- =============================================================================
-- REGISTRATION
-- =============================================================================

function IADS:registerEWR(groupName)
    table.insert(self.state.ewrGroups, groupName)
    self:log("Registered EWR: " .. groupName)
end

function IADS:registerSAMSite(groupName, siteType, center)
    local samSite = {
        groupName = groupName,
        siteType = siteType,
        center = center,
        radarActive = false,
        lastStateChange = 0,
        pulsePhase = "off",       -- "on" or "off"
    }

    table.insert(self.state.samSites, samSite)
    self:log("Registered SAM site: " .. groupName .. " (" .. siteType .. ")")

    return samSite
end

-- =============================================================================
-- THREAT DETECTION
-- =============================================================================

function IADS:getBlueAircraftPositions()
    local positions = {}

    -- Get all blue aircraft (players and AI)
    for _, side in ipairs({coalition.side.BLUE}) do
        local groups = coalition.getGroups(side, Group.Category.AIRPLANE)

        for _, group in ipairs(groups) do
            if group and group:isExist() then
                local units = group:getUnits()
                for _, unit in ipairs(units) do
                    if unit and unit:isExist() then
                        local pos = unit:getPoint()
                        table.insert(positions, {
                            x = pos.x,
                            y = pos.z,  -- Note: 3D y is altitude, z is north-south
                            alt = pos.y,
                            unit = unit,
                        })
                    end
                end
            end
        end

        -- Also check helicopters
        local heliGroups = coalition.getGroups(side, Group.Category.HELICOPTER)
        for _, group in ipairs(heliGroups) do
            if group and group:isExist() then
                local units = group:getUnits()
                for _, unit in ipairs(units) do
                    if unit and unit:isExist() then
                        local pos = unit:getPoint()
                        table.insert(positions, {
                            x = pos.x,
                            y = pos.z,
                            alt = pos.y,
                            unit = unit,
                        })
                    end
                end
            end
        end
    end

    return positions
end

function IADS:getClosestThreatDistance(samSite)
    local threats = self:getBlueAircraftPositions()
    local minDistance = math.huge

    for _, threat in ipairs(threats) do
        -- Only consider airborne threats (alt > 50m)
        if threat.alt > 50 then
            local distance = self:getDistance2D(threat, samSite.center)
            if distance < minDistance then
                minDistance = distance
            end
        end
    end

    return minDistance
end

-- =============================================================================
-- EMISSION CONTROL
-- =============================================================================

function IADS:setRadarState(samSite, active)
    local group = Group.getByName(samSite.groupName)
    if not group or not group:isExist() then
        return false
    end

    local controller = group:getController()
    if not controller then
        return false
    end

    if active then
        -- Weapons free, radar on
        controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
    else
        -- Weapons hold, radar off (but still tracking)
        controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
    end

    local previousState = samSite.radarActive
    samSite.radarActive = active
    samSite.lastStateChange = timer.getTime()

    if previousState ~= active then
        self:log(samSite.groupName .. " radar " .. (active and "ACTIVE" or "STANDBY"))
    end

    return true
end

function IADS:updateSAMSite(samSite)
    local currentTime = timer.getTime()
    local timeSinceChange = currentTime - samSite.lastStateChange
    local threatDistance = self:getClosestThreatDistance(samSite)

    -- Threat within activation range
    if threatDistance < self.config.samActivationRange then
        -- Threat close - activate radar
        if not samSite.radarActive then
            self:setRadarState(samSite, true)
            samSite.pulsePhase = "on"
        else
            -- Already active - check if we should pulse off to avoid being predictable
            if timeSinceChange > self.config.pulseOnDuration then
                -- Brief off period even with threat nearby
                self:setRadarState(samSite, false)
                samSite.pulsePhase = "off"
            end
        end
    else
        -- No immediate threat
        if samSite.radarActive then
            -- Radar is on - check if pulse on duration exceeded
            if timeSinceChange > self.config.pulseOnDuration then
                self:setRadarState(samSite, false)
                samSite.pulsePhase = "off"
            end
        else
            -- Radar is off - check if we should pulse on
            if samSite.pulsePhase == "off" and timeSinceChange > self.config.pulseOffDuration then
                -- Occasional pulse to search for targets
                self:setRadarState(samSite, true)
                samSite.pulsePhase = "on"
            end
        end
    end
end

-- Version that uses pre-cached threat positions (more efficient)
function IADS:updateSAMSiteCached(samSite, bluePositions)
    local currentTime = timer.getTime()
    local timeSinceChange = currentTime - samSite.lastStateChange

    -- Calculate threat distance using cached positions
    local threatDistance = math.huge
    for _, threat in ipairs(bluePositions) do
        if threat.alt > 50 then
            local distance = self:getDistance2D(threat, samSite.center)
            if distance < threatDistance then
                threatDistance = distance
            end
        end
    end

    -- Same logic as updateSAMSite but with pre-computed distance
    if threatDistance < self.config.samActivationRange then
        if not samSite.radarActive then
            self:setRadarState(samSite, true)
            samSite.pulsePhase = "on"
        else
            if timeSinceChange > self.config.pulseOnDuration then
                self:setRadarState(samSite, false)
                samSite.pulsePhase = "off"
            end
        end
    else
        if samSite.radarActive then
            if timeSinceChange > self.config.pulseOnDuration then
                self:setRadarState(samSite, false)
                samSite.pulsePhase = "off"
            end
        else
            if samSite.pulsePhase == "off" and timeSinceChange > self.config.pulseOffDuration then
                self:setRadarState(samSite, true)
                samSite.pulsePhase = "on"
            end
        end
    end
end

function IADS:updateEmissionControl()
    for _, samSite in ipairs(self.state.samSites) do
        self:updateSAMSite(samSite)
    end
end

-- =============================================================================
-- MAIN LOOP
-- =============================================================================

function IADS:update()
    if not self.state.enabled then
        return timer.getTime() + self.config.updateInterval
    end

    -- Skip on VeryEasy/Easy (no IADS emission control)
    if self.state.difficulty == "VeryEasy" or self.state.difficulty == "Easy" then
        return timer.getTime() + self.config.updateInterval
    end

    -- Use batched emission control with cached positions
    self:updateEmissionControlBatched()

    return timer.getTime() + self.config.updateInterval
end

-- Batched version with position caching
function IADS:updateEmissionControlBatched()
    -- Cache blue aircraft positions ONCE per update cycle
    local bluePositions = self:getBlueAircraftPositions()

    if #self.state.samSites == 0 then
        return
    end

    -- Process SAM sites with time budgeting
    local startTime = timer.getTime() * 1000
    local budgetMs = BatchScheduler.config.frameBudgetMs
    local itemsProcessed = 0

    for idx, samSite in ipairs(self.state.samSites) do
        self:updateSAMSiteCached(samSite, bluePositions)
        itemsProcessed = itemsProcessed + 1

        local elapsed = (timer.getTime() * 1000) - startTime
        if itemsProcessed >= 1 and elapsed >= budgetMs then
            -- Schedule remaining SAM sites for next frame
            local remaining = {}
            for i = idx + 1, #self.state.samSites do
                table.insert(remaining, self.state.samSites[i])
            end
            if #remaining > 0 then
                timer.scheduleFunction(function()
                    IADS:updateEmissionControlBatchedContinue(remaining, bluePositions)
                end, nil, timer.getTime() + 0.001)
            end
            return
        end
    end
end

-- Continue processing remaining SAM sites
function IADS:updateEmissionControlBatchedContinue(samSites, bluePositions)
    local startTime = timer.getTime() * 1000
    local budgetMs = BatchScheduler.config.frameBudgetMs
    local itemsProcessed = 0

    for idx, samSite in ipairs(samSites) do
        self:updateSAMSiteCached(samSite, bluePositions)
        itemsProcessed = itemsProcessed + 1

        local elapsed = (timer.getTime() * 1000) - startTime
        if itemsProcessed >= 1 and elapsed >= budgetMs then
            local remaining = {}
            for i = idx + 1, #samSites do
                table.insert(remaining, samSites[i])
            end
            if #remaining > 0 then
                timer.scheduleFunction(function()
                    IADS:updateEmissionControlBatchedContinue(remaining, bluePositions)
                end, nil, timer.getTime() + 0.001)
            end
            return
        end
    end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

function IADS:enable(difficulty)
    self.state.enabled = true
    self.state.difficulty = difficulty

    self:log("Enabled with difficulty: " .. difficulty)

    -- On Normal/Hard, set initial state to radars off
    if difficulty == "Normal" or difficulty == "Hard" then
        for _, samSite in ipairs(self.state.samSites) do
            self:setRadarState(samSite, false)
        end
    end
end

function IADS:init()
    if self.state.initialized then
        self:log("Already initialized!")
        return
    end

    self:log("Initializing IADS...")

    -- Schedule update loop
    timer.scheduleFunction(function(_, time)
        return IADS:update()
    end, nil, timer.getTime() + 5)

    self.state.initialized = true
    self:log("Initialization complete")
end

-- =============================================================================
-- STATS
-- =============================================================================

function IADS:getStats()
    local activeRadars = 0
    for _, samSite in ipairs(self.state.samSites) do
        if samSite.radarActive then
            activeRadars = activeRadars + 1
        end
    end

    return {
        enabled = self.state.enabled,
        difficulty = self.state.difficulty,
        ewrCount = #self.state.ewrGroups,
        samSiteCount = #self.state.samSites,
        activeRadars = activeRadars,
    }
end

function IADS:clear()
    -- Set all radars to standby before clearing
    for _, samSite in ipairs(self.state.samSites) do
        self:setRadarState(samSite, false)
    end

    self.state.ewrGroups = {}
    self.state.samSites = {}
    self:log("Cleared all registered sites")
end

env.info("[IADS] Loaded successfully")
