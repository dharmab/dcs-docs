-- =============================================================================
-- OPERATION OVERWATCH
-- Config, event handling, and per-flight F10 menus.
-- =============================================================================

if _G.OperationOverwatchLoaded then
    env.info("[OperationOverwatch] Script already loaded, skipping")
    return
end
_G.OperationOverwatchLoaded = true

OperationOverwatch = {}

local log = Logging:create("OperationOverwatch")

local METERS_PER_NAUTICAL_MILE = 1852
local MESSAGE_SECONDS = 15
local AM = 0

OperationOverwatch.config = {
    blueCountryId = country.id.USA,
    redCountryId = country.id.INSURGENTS,

    -- One JTAC per tasking slot; the slot count is the tasking limit.
    -- UHF AM so every player aircraft can tune them; the M-2000C has no FM
    -- radio. callname is the DCS JTAC callsign index for SetCallsign.
    jtacSlots = {
        { callsign = "Axeman", callname = 1, frequency = 256.1, modulation = AM, modulationName = "AM" },
        { callsign = "Darknight", callname = 2, frequency = 256.3, modulation = AM, modulationName = "AM" },
        { callsign = "Warrior", callname = 3, frequency = 256.5, modulation = AM, modulationName = "AM" },
        { callsign = "Pointer", callname = 4, frequency = 256.7, modulation = AM, modulationName = "AM" },
    },
    laserCode = 1688,
    jtacFuelKg = 1800,

    -- A tasking succeeds when every key unit or this fraction of the enemy
    -- is destroyed. It ends this long after its last flight leaves.
    successFraction = 0.7,
    abandonedTimeoutSeconds = 600,
    -- After success, the scene stays up this long before removal
    removalDelaySeconds = 60,
    -- Chance the JTAC warns of a SAM team. The warning is a hint, not a
    -- guarantee.
    samWarningChance = { withManpads = 0.5, withoutManpads = 0.2 },

    -- Helicopter types that get CAS taskings. Other helicopters (CH-47F) get
    -- no Check In menu.
    rotaryCasTypes = {
        ["AH-64D_BLK_II"] = true,
        ["OH-58D"] = true,
    },
    rotaryTaskingRadius = 20 * METERS_PER_NAUTICAL_MILE,

    -- Polygon of map points { x, y } covering Kandahar and Helmand provinces,
    -- and the tasking site mask. Both are generated in TerrainData.lua.
    areaOfOperations = TerrainData.areaOfOperations,
    siteGrid = TerrainData,
    -- FARP Pasab is an Invisible FARP on the old airstrip at FOB Pasab
    -- (formerly FOB Wilson), on Highway 1 in Zhari district; the map models
    -- the FOB. FARP Gereshk is on open ground with no fields or compounds
    -- within 300 m, 9 km west of Gereshk, covering Sangin, Gereshk, Lashkar
    -- Gah, and Nad-e Ali.
    farps = {
        { name = "FARP Pasab", position = { x = -262271.9, y = -68797.5 } },
        { name = "FARP Gereshk", position = { x = -237350, y = -160450 } },
    },
    -- On Highway 1 halfway between Kandahar Airfield and Camp Bastion
    checkInPoint = { x = -257475, y = -108266 },
}

OperationOverwatch.state = {
    menus = {}, -- group name -> { root, checkIn, join, joinEntries }
}

-- -----------------------------------------------------------------------------
-- Flights
-- -----------------------------------------------------------------------------

-- "fixed", "rotary", or nil for aircraft that get no CAS taskings
function OperationOverwatch:flightCategory(unit)
    local group = unit:getGroup()
    local category = group:getCategory()
    if category == Group.Category.AIRPLANE then
        return "fixed"
    end
    local isHelicopter = category == Group.Category.HELICOPTER
    local isCasHelicopter = self.config.rotaryCasTypes[unit:getTypeName()] == true
    if isHelicopter and isCasHelicopter then
        return "rotary"
    end
    return nil
end

local function message(groupId, text)
    trigger.action.outTextForGroup(groupId, text, MESSAGE_SECONDS)
end

function OperationOverwatch:checkIn(groupName)
    local flight = Tasking.state.flights[groupName]
    if not flight then
        return
    end
    local maxTaskings = #self.config.jtacSlots
    if Tasking:activeCount() >= maxTaskings then
        message(flight.groupId, "All " .. maxTaskings .. " JTACs are working taskings. Use Join Tasking.")
        return
    end
    local tasking, reason = Tasking:create(flight.category)
    if not tasking then
        log("Check In by " .. groupName .. " failed: " .. tostring(reason))
        message(flight.groupId, "No tasking available. Try again.")
        return
    end
    Tasking:assign(flight, tasking)
end

function OperationOverwatch:join(args)
    local flight = Tasking.state.flights[args.groupName]
    local tasking = Tasking.state.taskings[args.taskingId]
    if not flight then
        return
    end
    local taskingIsActive = tasking ~= nil and tasking.status == Tasking.Status.ACTIVE
    if not taskingIsActive then
        message(flight.groupId, "That tasking has ended.")
        return
    end
    Tasking:assign(flight, tasking)
end

-- -----------------------------------------------------------------------------
-- F10 menus
-- -----------------------------------------------------------------------------

function OperationOverwatch:buildJoinEntries(groupName)
    local menus = self.state.menus[groupName]
    local flight = Tasking.state.flights[groupName]
    if not (menus and flight) then
        return
    end
    if menus.join then
        missionCommands.removeItemForGroup(flight.groupId, menus.join)
    end
    menus.join = missionCommands.addSubMenuForGroup(flight.groupId, "Join Tasking", menus.root)
    local active = Tasking:activeList()
    if #active == 0 then
        missionCommands.addCommandForGroup(flight.groupId, "No active taskings", menus.join, function()
            message(flight.groupId, "No active taskings. Use Check In.")
        end)
        return
    end
    for _, tasking in ipairs(active) do
        missionCommands.addCommandForGroup(flight.groupId, Tasking:describe(tasking), menus.join, function(args)
            OperationOverwatch:join(args)
        end, { groupName = groupName, taskingId = tasking.id })
    end
end

function OperationOverwatch:addMenus(groupName)
    local flight = Tasking.state.flights[groupName]
    if not flight or self.state.menus[groupName] then
        return
    end
    local root = missionCommands.addSubMenuForGroup(flight.groupId, "Overwatch")
    local menus = { root = root }
    menus.checkIn = missionCommands.addCommandForGroup(flight.groupId, "Check In", root, function(name)
        OperationOverwatch:checkIn(name)
    end, groupName)
    self.state.menus[groupName] = menus
    self:buildJoinEntries(groupName)
end

function OperationOverwatch:removeMenus(groupName, groupId)
    local menus = self.state.menus[groupName]
    if menus then
        missionCommands.removeItemForGroup(groupId, menus.root)
        self.state.menus[groupName] = nil
    end
end

function OperationOverwatch:rebuildAllJoinMenus()
    for groupName in pairs(self.state.menus) do
        self:buildJoinEntries(groupName)
    end
end

-- -----------------------------------------------------------------------------
-- Events
-- -----------------------------------------------------------------------------

local E = world.event
local FLIGHT_ENDING_EVENTS = {
    [E.S_EVENT_LAND] = true,
    [E.S_EVENT_CRASH] = true,
    [E.S_EVENT_EJECTION] = true,
    [E.S_EVENT_DEAD] = true,
    [E.S_EVENT_PILOT_DEAD] = true,
    [E.S_EVENT_PLAYER_LEAVE_UNIT] = true,
    [E.S_EVENT_UNIT_LOST] = true,
}

local function playerUnit(object)
    if not object or not object.getPlayerName then
        return nil
    end
    local ok, playerName = pcall(object.getPlayerName, object)
    if ok and playerName then
        return object
    end
    return nil
end

function OperationOverwatch:onTakeoff(unit)
    local category = self:flightCategory(unit)
    if not category then
        return
    end
    local group = unit:getGroup()
    local groupName = group:getName()
    Tasking:registerFlight(groupName, group:getID(), category)
    self:addMenus(groupName)
    log(groupName .. " airborne as a " .. category .. " flight")
end

function OperationOverwatch:onFlightEnded(unit)
    local group = unit:getGroup()
    if not group then
        return
    end
    local groupName = group:getName()
    local flight = Tasking.state.flights[groupName]
    if not flight then
        return
    end
    self:removeMenus(groupName, flight.groupId)
    Tasking:removeFlight(groupName)
    log(groupName .. " no longer airborne")
end

function OperationOverwatch:onEvent(event)
    local id = event.id
    if id == E.S_EVENT_TAKEOFF then
        local unit = playerUnit(event.initiator)
        if unit then
            self:onTakeoff(unit)
        end
    elseif FLIGHT_ENDING_EVENTS[id] then
        local unit = playerUnit(event.initiator)
        if unit then
            self:onFlightEnded(unit)
        end
    elseif id == E.S_EVENT_SHOT then
        if event.initiator then
            Tasking:onShot(event.initiator:getName())
        end
    elseif id == E.S_EVENT_HIT then
        local initiatorIsPlayer = playerUnit(event.initiator) ~= nil
        if event.target and event.target.getName then
            Tasking:onFriendlyHit(event.target:getName(), initiatorIsPlayer)
        end
    end
end

function OperationOverwatch:init()
    Tasking:setOnTaskingsChanged(function()
        OperationOverwatch:rebuildAllJoinMenus()
    end)
    world.addEventHandler({
        onEvent = function(_, event)
            local ok, err = pcall(OperationOverwatch.onEvent, OperationOverwatch, event)
            if not ok then
                env.error("[OperationOverwatch] event " .. tostring(event.id) .. " failed: " .. tostring(err))
            end
        end,
    })
    Tasking:start()
    log("Initialized")
end

OperationOverwatch:init()

env.info("[OperationOverwatch] Loaded successfully")
