-- The mock replaces DCS API functions that lua-types/ declares
---@diagnostic disable: duplicate-set-field
-- =============================================================================
-- DCS MOCK
-- A small stateful stand-in for the DCS mission scripting environment.
-- Enum values come from docs/scripting/reference. Behavior is simplified:
-- flat terrain, no AI, units only move when a test moves them.
-- =============================================================================

local Mock = {}

local TERRAIN_HEIGHT = 100
local DEFAULT_LIFE = 100
-- DCS assigns IDs when a group or unit omits one; start far above script IDs
local AUTO_ID_START = 1000000

-- Approximate airbase reference points (DCS x, z) and airdrome IDs.
-- Positions are town coordinates from docs/data/terrains/Caucasus/places.csv.
local AIRBASES = {
    { name = "Krymsk", id = 15, x = -10950, z = 295962 },
    { name = "Maykop-Khanskaya", id = 16, x = -34262, z = 463600 },
    { name = "Sukhumi-Babushara", id = 20, x = -204927, z = 552530 },
    { name = "Gudauta", id = 21, x = -197070, z = 521864 },
    { name = "Senaki-Kolkhi", id = 23, x = -276848, z = 646568 },
    { name = "Kobuleti", id = 24, x = -331566, z = 638804 },
    { name = "Kutaisi", id = 25, x = -272918, z = 700541 },
    { name = "Mozdok", id = 28, x = -87449, z = 837905 },
    { name = "Tbilisi-Lochini", id = 29, x = -309472, z = 884649 },
    { name = "Vaziani", id = 31, x = -311545, z = 904352 },
}

local BLUE_COUNTRIES = { [2] = true, [80] = true }

-- Any field read from a namespace that the mock does not define is recorded
-- in env.unknown and returns another recording stub, so a script never
-- crashes on a missing mock but tests can fail on unmocked API use.
local function recordingStub(env, path)
    return setmetatable({}, {
        __index = function(t, k)
            local p = path .. "." .. tostring(k)
            env.unknown[p] = true
            local s = recordingStub(env, p)
            rawset(t, k, s)
            return s
        end,
        __call = function()
            return nil
        end,
    })
end

local function namespace(env, name, tbl)
    local stub = recordingStub(env, name)
    _G[name] = setmetatable(tbl, getmetatable(stub))
end

-- Install a fresh mock environment into _G and return its state table.
-- options.terrain: a TerrainModel for surface, road, and coordinate queries
-- options.surfaceAt: function(x, z) overriding the terrain's surface type
function Mock.install(options)
    options = options or {}
    local terrain = assert(options.terrain, "Mock.install needs options.terrain")

    local env = {
        now = 0,
        queue = {},
        nextFunctionId = 0,
        log = {},
        messages = {},
        markers = {},
        drawings = {},
        menus = {},
        flags = {},
        groups = {}, -- Array of group records in spawn order
        groupsByName = {},
        unitsByName = {},
        players = {},
        detections = {}, -- Group name -> array of detected objects
        eventHandlers = {},
        unknown = {},
        surfaceAt = options.surfaceAt or function(x, z)
            return terrain:surfaceAt(x, z)
        end,
        wind = options.wind or { x = 0, z = 0 },
        nextObjectId = AUTO_ID_START,
    }

    local function newObjectId()
        env.nextObjectId = env.nextObjectId + 1
        return env.nextObjectId
    end

    -- -------------------------------------------------------------------------
    -- env, timer
    -- -------------------------------------------------------------------------

    namespace(env, "env", {
        info = function(message)
            env.log[#env.log + 1] = message
        end,
        warning = function(message)
            env.log[#env.log + 1] = "WARNING " .. message
        end,
        error = function(message)
            env.log[#env.log + 1] = "ERROR " .. message
        end,
    })

    namespace(env, "timer", {
        getTime = function()
            return env.now
        end,
        getAbsTime = function()
            return env.now
        end,
        getTime0 = function()
            return 0
        end,
        scheduleFunction = function(fn, arg, time)
            env.nextFunctionId = env.nextFunctionId + 1
            env.queue[env.nextFunctionId] = { fn = fn, arg = arg, time = time }
            return env.nextFunctionId
        end,
        removeFunction = function(id)
            env.queue[id] = nil
        end,
        setFunctionTime = function(id, time)
            if env.queue[id] then
                env.queue[id].time = time
            end
        end,
    })

    -- Run scheduled functions in time order until `seconds` from now.
    -- Mission time stays frozen while a function runs, as in DCS.
    function env.advance(seconds)
        local stop = env.now + seconds
        while true do
            local nextId, nextEntry
            for id, entry in pairs(env.queue) do
                if
                    entry.time <= stop
                    and (not nextEntry or entry.time < nextEntry.time or (entry.time == nextEntry.time and id < nextId))
                then
                    nextId, nextEntry = id, entry
                end
            end
            if not nextEntry then
                break
            end
            env.queue[nextId] = nil
            env.now = math.max(env.now, nextEntry.time)
            local nextTime = nextEntry.fn(nextEntry.arg, env.now)
            if nextTime then
                env.queue[nextId] = { fn = nextEntry.fn, arg = nextEntry.arg, time = math.max(nextTime, env.now) }
            end
        end
        env.now = stop
    end

    -- -------------------------------------------------------------------------
    -- Enums
    -- -------------------------------------------------------------------------

    namespace(env, "coalition", {
        side = { NEUTRAL = 0, RED = 1, BLUE = 2 },
    })
    namespace(env, "country", { id = { RUSSIA = 0, USA = 2, CJTF_BLUE = 80, CJTF_RED = 81 } })
    namespace(env, "Group", { Category = { AIRPLANE = 0, HELICOPTER = 1, GROUND = 2, SHIP = 3, TRAIN = 4 } })
    namespace(env, "Unit", {
        Category = { AIRPLANE = 0, HELICOPTER = 1, GROUND_UNIT = 2, SHIP = 3, STRUCTURE = 4 },
    })
    namespace(env, "Object", {
        Category = { UNIT = 1, WEAPON = 2, STATIC = 3, BASE = 4, SCENERY = 5, CARGO = 6 },
    })
    namespace(env, "Weapon", {
        Category = { SHELL = 0, MISSILE = 1, ROCKET = 2, BOMB = 3 },
        GuidanceType = {
            INS = 1,
            IR = 2,
            RADAR_ACTIVE = 3,
            RADAR_SEMI_ACTIVE = 4,
            RADAR_PASSIVE = 5,
            TV = 6,
            LASER = 7,
            TELE = 8,
        },
    })
    namespace(env, "Controller", { Detection = { VISUAL = 1, OPTIC = 2, RADAR = 4, IRST = 8, RWR = 16, DLINK = 32 } })
    namespace(env, "AI", {
        Option = {
            Air = {
                id = { ROE = 0, REACTION_ON_THREAT = 1, RADAR_USING = 3 },
                val = {
                    ROE = {
                        WEAPON_FREE = 0,
                        OPEN_FIRE_WEAPON_FREE = 1,
                        OPEN_FIRE = 2,
                        RETURN_FIRE = 3,
                        WEAPON_HOLD = 4,
                    },
                    RADAR_USING = {
                        NEVER = 0,
                        FOR_ATTACK_ONLY = 1,
                        FOR_SEARCH_IF_REQUIRED = 2,
                        FOR_CONTINUOUS_SEARCH = 3,
                    },
                },
            },
            Ground = {
                id = { ROE = 0, ALARM_STATE = 9 },
                val = {
                    ROE = { OPEN_FIRE = 2, RETURN_FIRE = 3, WEAPON_HOLD = 4 },
                    ALARM_STATE = { AUTO = 0, GREEN = 1, RED = 2 },
                },
            },
        },
    })

    -- -------------------------------------------------------------------------
    -- Units and groups
    -- -------------------------------------------------------------------------

    local function newController(record)
        local controller = {}
        function controller:setTask(task)
            record.tasks[#record.tasks + 1] = task
        end
        function controller:pushTask(task)
            record.tasks[#record.tasks + 1] = task
        end
        function controller:resetTask()
            record.tasks = {}
        end
        function controller:hasTask()
            return #record.tasks > 0
        end
        function controller:setCommand(command)
            record.commands[#record.commands + 1] = command
        end
        function controller:setOption(id, value)
            record.options[id] = value
        end
        function controller:setOnOff(on)
            record.on = on
        end
        function controller:knowTarget() end
        function controller:getDetectedTargets()
            local targets = {}
            for _, object in ipairs(env.detections[record.name] or {}) do
                targets[#targets + 1] = { object = object, visible = true, distance = true }
            end
            return targets
        end
        return controller
    end

    local function newUnit(unitRecord, groupRecord)
        local unit = { record = unitRecord }
        function unit:getName()
            return unitRecord.name
        end
        function unit:getTypeName()
            return unitRecord.type
        end
        function unit:getID()
            return unitRecord.unitId
        end
        function unit:isExist()
            return unitRecord.alive and groupRecord.alive
        end
        function unit:isActive()
            return groupRecord.active
        end
        function unit:getPoint()
            return { x = unitRecord.x, y = unitRecord.alt, z = unitRecord.z }
        end
        function unit:getPosition()
            local h = unitRecord.heading
            return {
                p = self:getPoint(),
                x = { x = math.cos(h), y = 0, z = math.sin(h) },
                y = { x = 0, y = 1, z = 0 },
                z = { x = -math.sin(h), y = 0, z = math.cos(h) },
            }
        end
        function unit:getVelocity()
            return { x = unitRecord.vx, y = 0, z = unitRecord.vz }
        end
        function unit:getGroup()
            return groupRecord.object
        end
        function unit:getCoalition()
            return groupRecord.side
        end
        function unit:getCountry()
            return groupRecord.countryId
        end
        function unit:getLife()
            return unitRecord.life
        end
        function unit:getLife0()
            return DEFAULT_LIFE
        end
        function unit:getPlayerName()
            return unitRecord.playerName
        end
        function unit:inAir()
            return unitRecord.inAir
        end
        function unit:getDesc()
            return { category = groupRecord.unitCategory, typeName = unitRecord.type }
        end
        function unit:getCategory()
            return Object.Category.UNIT
        end
        function unit:getController()
            return groupRecord.controller
        end
        function unit:enableEmission(on)
            unitRecord.emission = on
        end
        function unit:destroy()
            env.killUnit(unitRecord.name)
        end
        return unit
    end

    local UNIT_CATEGORY_BY_GROUP = { [0] = 0, [1] = 1, [2] = 2, [3] = 3 }

    -- Create a group from a mission-format group table. Used by
    -- coalition.addGroup and by the mission file loader.
    function env.addGroup(countryId, category, data, extra)
        extra = extra or {}
        local record = {
            name = data.name,
            groupId = data.groupId or newObjectId(),
            data = data,
            countryId = countryId,
            category = category,
            unitCategory = UNIT_CATEGORY_BY_GROUP[category],
            side = BLUE_COUNTRIES[countryId] and 2 or 1,
            alive = true,
            active = not extra.lateActivation,
            fromMission = extra.fromMission or false,
            spawnTime = env.now,
            emission = nil,
            tasks = {},
            commands = {},
            options = {},
            units = {},
        }
        record.controller = newController(record)

        local group = { record = record }
        record.object = group

        local defaultAlt = (category == 0 or category == 1) and 0 or TERRAIN_HEIGHT
        for _, u in ipairs(data.units) do
            local unitRecord = {
                name = u.name,
                type = u.type,
                unitId = u.unitId or newObjectId(),
                x = u.x,
                z = u.y,
                alt = u.alt or defaultAlt,
                heading = u.heading or 0,
                vx = 0,
                vz = 0,
                life = DEFAULT_LIFE,
                alive = true,
                inAir = false,
                skill = u.skill,
            }
            unitRecord.object = newUnit(unitRecord, record)
            record.units[#record.units + 1] = unitRecord
            env.unitsByName[u.name] = unitRecord
        end

        function group:getName()
            return record.name
        end
        function group:getID()
            return record.groupId
        end
        function group:isExist()
            return record.alive
        end
        function group:getCoalition()
            return record.side
        end
        function group:getCategory()
            return record.category
        end
        function group:getController()
            return record.controller
        end
        -- Like DCS, only live units are returned
        function group:getUnits()
            local units = {}
            for _, unitRecord in ipairs(record.units) do
                if unitRecord.alive then
                    units[#units + 1] = unitRecord.object
                end
            end
            return units
        end
        function group:getUnit(index)
            return self:getUnits()[index]
        end
        function group:getSize()
            return #self:getUnits()
        end
        function group:activate()
            record.active = true
        end
        function group:enableEmission(on)
            record.emission = on
        end
        function group:destroy()
            record.alive = false
            env.groupsByName[record.name] = nil
            for _, unitRecord in ipairs(record.units) do
                env.unitsByName[unitRecord.name] = nil
            end
        end

        env.groups[#env.groups + 1] = record
        env.groupsByName[record.name] = record
        return group
    end

    function env.killUnit(name)
        local unitRecord = env.unitsByName[name]
        assert(unitRecord, "no unit named " .. name)
        unitRecord.alive = false
        unitRecord.life = 0
        env.unitsByName[name] = nil
    end

    function env.setUnitLife(name, life)
        env.unitsByName[name].life = life
    end

    -- Groups created by scripts (not loaded from the mission file)
    function env.spawnedGroups()
        local result = {}
        for _, record in ipairs(env.groups) do
            if not record.fromMission then
                result[#result + 1] = record
            end
        end
        return result
    end

    -- Load every group placed in a mission file
    function env.loadMission(path)
        local chunk = assert(loadfile(path))
        local sandbox = {}
        setfenv(chunk, sandbox)
        chunk()
        local mission = assert(sandbox.mission, "no mission table in " .. path)
        local categories = { plane = 0, helicopter = 1, vehicle = 2, ship = 3 }
        for _, side in pairs(mission.coalition) do
            for _, countryData in ipairs(side.country or {}) do
                for key, category in pairs(categories) do
                    if countryData[key] then
                        for _, groupData in ipairs(countryData[key].group) do
                            env.addGroup(countryData.id, category, groupData, {
                                lateActivation = groupData.lateActivation,
                                fromMission = true,
                            })
                        end
                    end
                end
            end
        end
        return mission
    end

    -- A client aircraft in the air at DCS (x, z)
    function env.addPlayer(name, x, z, playerOptions)
        playerOptions = playerOptions or {}
        local group = env.addGroup(playerOptions.countryId or 80, 0, {
            name = name,
            groupId = newObjectId(),
            units = { { name = name, type = playerOptions.type or "F-16C_50", x = x, y = z } },
        }, { fromMission = true })
        local unitRecord = group.record.units[1]
        unitRecord.alt = playerOptions.alt or 6000
        unitRecord.inAir = unitRecord.alt > TERRAIN_HEIGHT
        unitRecord.playerName = name
        env.players[#env.players + 1] = unitRecord
        return unitRecord
    end

    function env.removePlayer(unitRecord)
        for i, p in ipairs(env.players) do
            if p == unitRecord then
                table.remove(env.players, i)
                break
            end
        end
        env.groupsByName[unitRecord.name].object:destroy()
    end

    -- A weapon in flight; fire it with env.fireEvent(S_EVENT_SHOT)
    function env.makeWeapon(spec)
        local w = {
            alive = true,
            x = spec.x,
            z = spec.z,
            alt = spec.alt or 5000,
            vx = spec.vx or 0,
            vz = spec.vz or 0,
        }
        local weapon = { record = w }
        function weapon:isExist()
            return w.alive
        end
        function weapon:getTypeName()
            return spec.type or "AGM_88"
        end
        function weapon:getDesc()
            return { guidance = spec.guidance, category = Weapon.Category.MISSILE }
        end
        function weapon:getPoint()
            return { x = w.x, y = w.alt, z = w.z }
        end
        function weapon:getVelocity()
            return { x = w.vx, y = 0, z = w.vz }
        end
        function weapon:getCategory()
            return Object.Category.WEAPON
        end
        function weapon:getCoalition()
            return spec.side or coalition.side.BLUE
        end
        return weapon
    end

    function env.fireEvent(event)
        event.time = event.time or env.now
        for _, handler in ipairs(env.eventHandlers) do
            handler:onEvent(event)
        end
    end

    function env.unitObject(name)
        return env.unitsByName[name] and env.unitsByName[name].object
    end

    function env.groupObject(name)
        return env.groupsByName[name] and env.groupsByName[name].object
    end

    function env.logContains(pattern)
        for _, line in ipairs(env.log) do
            if line:find(pattern) then
                return true
            end
        end
        return false
    end

    -- -------------------------------------------------------------------------
    -- Singletons
    -- -------------------------------------------------------------------------

    coalition.addGroup = function(countryId, category, data)
        return env.addGroup(countryId, category, data)
    end
    coalition.getPlayers = function(side)
        local result = {}
        for _, p in ipairs(env.players) do
            local record = env.groupsByName[p.name]
            if record and record.side == side and p.alive then
                result[#result + 1] = p.object
            end
        end
        return result
    end
    coalition.getGroups = function(side, category)
        local result = {}
        for _, record in ipairs(env.groups) do
            if record.alive and record.side == side and (category == nil or record.category == category) then
                result[#result + 1] = record.object
            end
        end
        return result
    end
    coalition.addStaticObject = function()
        return nil
    end

    Group.getByName = function(name)
        return env.groupObject(name)
    end
    Unit.getByName = function(name)
        return env.unitObject(name)
    end

    local airbaseObjects = {}
    for _, a in ipairs(AIRBASES) do
        local airbase = {}
        function airbase:getName()
            return a.name
        end
        function airbase:getID()
            return a.id
        end
        function airbase:getPoint()
            return { x = a.x, y = TERRAIN_HEIGHT, z = a.z }
        end
        airbaseObjects[#airbaseObjects + 1] = airbase
    end
    namespace(env, "Airbase", {
        getByName = function(name)
            for _, airbase in ipairs(airbaseObjects) do
                if airbase:getName() == name then
                    return airbase
                end
            end
            return nil
        end,
    })

    namespace(env, "land", {
        SurfaceType = { LAND = 1, SHALLOW_WATER = 2, WATER = 3, ROAD = 4, RUNWAY = 5 },
        getHeight = function()
            return TERRAIN_HEIGHT
        end,
        getSurfaceType = function(p)
            return env.surfaceAt(p.x, p.y)
        end,
        getClosestPointOnRoads = function(roadType, x, y)
            assert(roadType == "roads", "the mock has no " .. tostring(roadType) .. " network")
            local roadX, roadY = terrain:closestRoadPoint(x, y)
            return roadX, roadY
        end,
        isVisible = function()
            return true
        end,
    })

    namespace(env, "world", {
        event = {
            S_EVENT_SHOT = 1,
            S_EVENT_HIT = 2,
            S_EVENT_TAKEOFF = 3,
            S_EVENT_LAND = 4,
            S_EVENT_CRASH = 5,
            S_EVENT_EJECTION = 6,
            S_EVENT_DEAD = 8,
            S_EVENT_BIRTH = 15,
            S_EVENT_UNIT_LOST = 30,
        },
        VolumeType = { SEGMENT = 0, BOX = 1, SPHERE = 2, PYRAMID = 3 },
        addEventHandler = function(handler)
            env.eventHandlers[#env.eventHandlers + 1] = handler
        end,
        removeEventHandler = function(handler)
            for i, h in ipairs(env.eventHandlers) do
                if h == handler then
                    table.remove(env.eventHandlers, i)
                    return
                end
            end
        end,
        searchObjects = function()
            return 0
        end,
        getAirbases = function()
            return airbaseObjects
        end,
    })

    namespace(env, "atmosphere", {
        getWind = function()
            return { x = env.wind.x, y = 0, z = env.wind.z }
        end,
    })

    namespace(env, "coord", {
        LOtoLL = function(p)
            local lat, lon = terrain:toLatLon(p.x, p.z)
            return lat, lon, p.y
        end,
        LLtoLO = function(lat, lon, alt)
            local x, z = terrain:fromLatLon(lat, lon)
            return { x = x, y = alt or 0, z = z }
        end,
        LLtoMGRS = function(lat, lon)
            return terrain.toMGRS(lat, lon)
        end,
    })

    local function addMenu(path)
        env.menus[#env.menus + 1] = path
        return path
    end
    local function removeMenu(path)
        for i, m in ipairs(env.menus) do
            if m == path then
                table.remove(env.menus, i)
                return
            end
        end
    end
    namespace(env, "missionCommands", {
        addSubMenuForCoalition = function(_, name, parent)
            return addMenu({ name = name, parent = parent })
        end,
        addCommandForCoalition = function(_, name, parent, fn, arg)
            return addMenu({ name = name, parent = parent, fn = fn, arg = arg })
        end,
        removeItemForCoalition = function(_, path)
            removeMenu(path)
        end,
        addSubMenuForGroup = function(groupId, name, parent)
            return addMenu({ groupId = groupId, name = name, parent = parent })
        end,
        addCommandForGroup = function(groupId, name, parent, fn, arg)
            return addMenu({ groupId = groupId, name = name, parent = parent, fn = fn, arg = arg })
        end,
        removeItemForGroup = function(_, path)
            removeMenu(path)
        end,
    })

    -- Find a menu command by name and run it
    function env.runMenu(name)
        for _, m in ipairs(env.menus) do
            if m.name == name and m.fn then
                m.fn(m.arg)
                return
            end
        end
        error("no menu command named " .. name)
    end

    local function message(text)
        env.messages[#env.messages + 1] = text
    end
    local function draw(kind)
        return function(...)
            env.drawings[#env.drawings + 1] = { kind = kind, args = { ... } }
        end
    end
    namespace(env, "trigger", {
        action = {
            outText = message,
            outTextForCoalition = function(_, text)
                message(text)
            end,
            outTextForGroup = function(_, text)
                message(text)
            end,
            markToAll = function(id, text, pos)
                env.markers[#env.markers + 1] = { id = id, text = text, pos = pos }
            end,
            markToCoalition = function(id, text, pos)
                env.markers[#env.markers + 1] = { id = id, text = text, pos = pos }
            end,
            -- Marks and drawings share one ID space; drawings take the ID second
            removeMark = function(id)
                for i, m in ipairs(env.markers) do
                    if m.id == id then
                        table.remove(env.markers, i)
                        return
                    end
                end
                for i, d in ipairs(env.drawings) do
                    if d.args[2] == id then
                        table.remove(env.drawings, i)
                        return
                    end
                end
            end,
            circleToAll = draw("circle"),
            lineToAll = draw("line"),
            arrowToAll = draw("arrow"),
            textToAll = draw("text"),
            setUserFlag = function(flag, value)
                env.flags[flag] = value
            end,
        },
        misc = {
            getUserFlag = function(flag)
                return env.flags[flag] or 0
            end,
        },
    })

    return env
end

return Mock
