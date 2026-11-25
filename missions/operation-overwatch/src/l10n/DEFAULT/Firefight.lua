-- =============================================================================
-- FIREFIGHT
-- Spawns the troops-in-contact scenario: a friendly patrol, the enemy force,
-- and an MQ-9 JTAC.
--
-- The two sides fire at points near each other (docs/recipes/ground-firefight.md)
-- so the fight lasts until players break it. Every ground group is invisible:
-- WEAPON_HOLD does not stop ground AI from engaging while FireAtPoint runs
-- (Operation Infinity, BattlefieldGeneration.lua), so without invisibility the
-- two sides would kill each other.
-- =============================================================================

if _G.FirefightLoaded then
    env.info("[Firefight] Script already loaded, skipping")
    return
end
_G.FirefightLoaded = true

Firefight = {}

local log = Logging:create("Firefight")

-- Enemy distance from the friendly patrol. Afghanistan firefights were long
-- range: about half of engagements were beyond 300 m, and insurgents often
-- fired from 500 m or more, where troops could not see the shooters
-- (Ehrhart, "Taking Back the Infantry Half-Kilometer", 2009).
local CONTACT_DISTANCE_MIN_METERS = 400
local CONTACT_DISTANCE_MAX_METERS = 900
-- Unit spread around each side's center. Insurgents fire from dispersed
-- positions along a compound wall, treeline, or ridge.
local FRIENDLY_SPREAD_METERS = 40
local ENEMY_SPREAD_METERS = 150
-- MANPADS distance from the main enemy, so the threat comes from an
-- unexpected direction
local MANPADS_DISTANCE_MIN_METERS = 1000
local MANPADS_DISTANCE_MAX_METERS = 2000
-- FireAtPoint aim points fall short of the other side by this much
local FIRE_SHORT_METERS = 60
local FIRE_RADIUS_METERS = 50
local FIRE_EXPENDITURE_QUANTITY = 200
local FIRE_WANDER_METERS = 40
local UNIT_PLACEMENT_ATTEMPTS = 20

-- MQ-9 orbit (docs/recipes/jtac-setup.md: within 5 km of the targets)
local JTAC_HEIGHT_AGL_METERS = 3000
local JTAC_SPEED_MPS = 60
local JTAC_TYPE = "MQ-9 Reaper"
local WEAPON_TYPE_AUTO = 1073741822

local GROUND_ROE_OPTION = 0 -- AI.Option.Ground.id.ROE
local ROE_WEAPON_HOLD = 4 -- AI.Option.Ground.val.ROE.WEAPON_HOLD
local AIR_ROE_OPTION = 0 -- AI.Option.Air.id.ROE

-- Friendly patrol, 2010 coalition vehicles
Firefight.friendlyVehicleTypes = { "CHAP_MATV", "MaxxPro_MRAP", "M1126 Stryker ICV" }
Firefight.friendlyVehicleCount = { min = 2, max = 3 }
Firefight.friendlyDismounts = {
    { type = "Soldier M4", count = 4 },
    { type = "Soldier M249", count = 2 },
}
-- Resupplies units within 100 m so they keep firing (ground-firefight.md)
Firefight.ammoCarrierType = "M30_CC"

local function wrappedAction(tasks, id, params)
    tasks[#tasks + 1] = {
        enabled = true,
        auto = false,
        id = "WrappedAction",
        number = #tasks + 1,
        params = { action = { id = id, params = params } },
    }
end

local function fireAtPointTask(target)
    return {
        id = "FireAtPoint",
        params = {
            x = target.x,
            y = target.y,
            radius = FIRE_RADIUS_METERS,
            expendQty = FIRE_EXPENDITURE_QUANTITY,
            expendQtyEnabled = true,
        },
    }
end

-- A point between `from` and `to`, FIRE_SHORT_METERS short of `to`
local function aimPointShortOf(from, to)
    local distance = Spatial:getDistance2D(from, to)
    local fraction = math.max(0, (distance - FIRE_SHORT_METERS) / distance)
    return {
        x = from.x + (to.x - from.x) * fraction,
        y = from.y + (to.y - from.y) * fraction,
    }
end

local function placeUnit(center, spread)
    for _ = 1, UNIT_PLACEMENT_ATTEMPTS do
        local point = Spatial:randomPointInRadius(center, spread)
        if Sites:isValidPoint(point) then
            return point
        end
    end
    return center
end

-- Build a ground group. specs: array of { type, skill }
-- options: invisible, immortal, holdFire, fireAt (map point)
local function buildGroundGroup(name, center, spread, facing, specs, options)
    local groupId = Units:getNextGroupId()
    local units = {}
    for i, spec in ipairs(specs) do
        local point = placeUnit(center, spread)
        units[#units + 1] = {
            unitId = Units:getNextUnitId(),
            name = name .. "-" .. i,
            type = spec.type,
            skill = spec.skill or "High",
            x = point.x,
            y = point.y,
            heading = facing,
            playerCanDrive = false,
        }
    end

    local tasks = {}
    if options.immortal then
        wrappedAction(tasks, "SetImmortal", { value = true })
    end
    if options.invisible then
        wrappedAction(tasks, "SetInvisible", { value = true })
    end
    if options.holdFire then
        wrappedAction(tasks, "Option", { name = GROUND_ROE_OPTION, value = ROE_WEAPON_HOLD })
    end
    if options.fireAt then
        local fire = fireAtPointTask(options.fireAt)
        fire.enabled = true
        fire.auto = false
        fire.number = #tasks + 1
        tasks[#tasks + 1] = fire
    end

    return {
        groupId = groupId,
        name = name,
        task = "Ground Nothing",
        visible = false,
        hidden = false,
        x = center.x,
        y = center.y,
        units = units,
        route = {
            points = {
                {
                    x = center.x,
                    y = center.y,
                    type = "Turning Point",
                    action = "Off Road",
                    speed = 0,
                    ETA = 0,
                    ETA_locked = true,
                    formation_template = "",
                    task = { id = "ComboTask", params = { tasks = tasks } },
                },
            },
        },
    }
end

local function spawn(countryId, category, data)
    local ok, group = pcall(coalition.addGroup, countryId, category, data)
    if not ok or not group then
        log("Failed to spawn " .. data.name .. ": " .. tostring(group))
        return nil
    end
    log("Spawned " .. data.name .. " with " .. #data.units .. " units")
    return group
end

local function unitNames(data)
    local names = {}
    for _, unit in ipairs(data.units) do
        names[#names + 1] = unit.name
    end
    return names
end

local function friendlySpecs()
    local specs = {}
    local vehicleCount = math.random(Firefight.friendlyVehicleCount.min, Firefight.friendlyVehicleCount.max)
    for _ = 1, vehicleCount do
        local vehicleType = Firefight.friendlyVehicleTypes[math.random(#Firefight.friendlyVehicleTypes)]
        specs[#specs + 1] = { type = vehicleType }
    end
    for _, dismount in ipairs(Firefight.friendlyDismounts) do
        for _ = 1, dismount.count do
            specs[#specs + 1] = { type = dismount.type }
        end
    end
    specs[#specs + 1] = { type = Firefight.ammoCarrierType }
    return specs
end

local function specsForRoles(force, roles)
    local wanted = {}
    for _, role in ipairs(roles) do
        wanted[role] = true
    end
    local specs = {}
    for _, unit in ipairs(force.units) do
        if wanted[unit.role] then
            specs[#specs + 1] = unit
        end
    end
    return specs
end

local function buildJtacGroup(name, slot, orbitCenter, targetGroupId)
    local config = OperationOverwatch.config
    local height = land.getHeight({ x = orbitCenter.x, y = orbitCenter.y })
    local altitude = height + JTAC_HEIGHT_AGL_METERS
    local frequencyHz = slot.frequency * 1000000

    local tasks = {}
    wrappedAction(tasks, "SetCallsign", { callname = slot.callname, number = 1 })
    wrappedAction(tasks, "SetFrequency", { frequency = frequencyHz, modulation = slot.modulation, power = 10 })
    wrappedAction(tasks, "SetImmortal", { value = true })
    wrappedAction(tasks, "SetInvisible", { value = true })
    wrappedAction(tasks, "Option", { name = AIR_ROE_OPTION, value = ROE_WEAPON_HOLD })
    tasks[#tasks + 1] = {
        enabled = true,
        auto = false,
        id = "Orbit",
        number = #tasks + 1,
        params = {
            pattern = "Circle",
            point = { x = orbitCenter.x, y = orbitCenter.y },
            speed = JTAC_SPEED_MPS,
            altitude = altitude,
        },
    }
    -- The enemy groups are invisible to AI sensors, so this FAC task may not
    -- find them. The script lasers and smokes key units itself (Tasking.lua).
    tasks[#tasks + 1] = {
        enabled = true,
        auto = false,
        id = "FAC_EngageGroup",
        number = #tasks + 1,
        params = {
            groupId = targetGroupId,
            weaponType = WEAPON_TYPE_AUTO,
            designation = "Laser",
            datalink = true,
            priority = 0,
        },
    }

    local unitId = Units:getNextUnitId()
    return {
        groupId = Units:getNextGroupId(),
        name = name,
        task = "AFAC",
        communication = true,
        frequency = slot.frequency,
        modulation = slot.modulation,
        uncontrolled = false,
        hidden = false,
        x = orbitCenter.x,
        y = orbitCenter.y,
        units = {
            {
                unitId = unitId,
                name = name .. "-1",
                type = JTAC_TYPE,
                skill = "Excellent",
                x = orbitCenter.x,
                y = orbitCenter.y,
                alt = altitude,
                alt_type = "BARO",
                speed = JTAC_SPEED_MPS,
                heading = 0,
                psi = 0,
                payload = { flare = 0, chaff = 0, fuel = config.jtacFuelKg, gun = 0, pylons = {} },
                -- Numeric as in docs/recipes/jtac-setup.md; SetCallsign names it
                callsign = unitId,
            },
        },
        route = {
            points = {
                {
                    x = orbitCenter.x,
                    y = orbitCenter.y,
                    alt = altitude,
                    alt_type = "BARO",
                    type = "Turning Point",
                    action = "Turning Point",
                    speed = JTAC_SPEED_MPS,
                    speed_locked = true,
                    ETA = 0,
                    ETA_locked = true,
                    task = { id = "ComboTask", params = { tasks = tasks } },
                },
            },
        },
    }
end

-- Spawn the scenario for a tasking.
-- tasking: { id, slot, center, force }
-- Returns a table of spawned group and unit names, or nil on failure.
function Firefight:spawn(tasking)
    local config = OperationOverwatch.config
    local prefix = "OW-T" .. tasking.id
    local friendlyCenter = tasking.center
    local enemyCenter = Sites:pickPointNear(friendlyCenter, CONTACT_DISTANCE_MIN_METERS, CONTACT_DISTANCE_MAX_METERS)
    if not enemyCenter then
        log(prefix .. ": no valid enemy position")
        return nil
    end

    local towardEnemy = math.atan2(enemyCenter.y - friendlyCenter.y, enemyCenter.x - friendlyCenter.x)
    local towardFriendlies = towardEnemy + math.pi
    local Role = EnemyForce.Role
    local result = {
        friendlyCenter = friendlyCenter,
        enemyCenter = enemyCenter,
        groupNames = {},
        friendlyUnitNames = {},
        enemyUnitNames = {},
        keyUnitNames = {},
        manpadsUnitName = nil,
        fireGroups = {},
    }

    -- specs: the EnemyForce units behind data.units, in the same order
    local function track(group, data, isEnemy, specs)
        if not group then
            return
        end
        result.groupNames[#result.groupNames + 1] = data.name
        for i, name in ipairs(unitNames(data)) do
            if isEnemy then
                result.enemyUnitNames[#result.enemyUnitNames + 1] = name
                local spec = specs and specs[i]
                if spec and spec.key then
                    result.keyUnitNames[#result.keyUnitNames + 1] = name
                end
            else
                result.friendlyUnitNames[#result.friendlyUnitNames + 1] = name
            end
        end
    end

    local friendlyAim = aimPointShortOf(friendlyCenter, enemyCenter)
    local friendlyData = buildGroundGroup(
        prefix .. "-Friendly",
        friendlyCenter,
        FRIENDLY_SPREAD_METERS,
        towardEnemy,
        friendlySpecs(),
        { immortal = true, invisible = true, fireAt = friendlyAim }
    )
    track(spawn(config.blueCountryId, Group.Category.GROUND, friendlyData), friendlyData, false)
    result.fireGroups[#result.fireGroups + 1] = { name = friendlyData.name, aim = friendlyAim }

    local enemyAim = aimPointShortOf(enemyCenter, friendlyCenter)
    local enemyGroups = {
        {
            suffix = "-Fire",
            roles = { Role.RIFLEMAN, Role.RPG, Role.TECHNICAL },
            options = { invisible = true, fireAt = enemyAim },
        },
        { suffix = "-Vehicles", roles = { Role.LIGHT_VEHICLE }, options = { invisible = true, holdFire = true } },
        { suffix = "-AAA", roles = { Role.ZU23 }, options = { invisible = true } },
    }
    local fireGroupId
    for _, spec in ipairs(enemyGroups) do
        local specs = specsForRoles(tasking.force, spec.roles)
        if #specs > 0 then
            local data = buildGroundGroup(
                prefix .. "-Enemy" .. spec.suffix,
                enemyCenter,
                ENEMY_SPREAD_METERS,
                towardFriendlies,
                specs,
                spec.options
            )
            local group = spawn(config.redCountryId, Group.Category.GROUND, data)
            track(group, data, true, specs)
            if spec.options.fireAt then
                fireGroupId = data.groupId
                result.fireGroups[#result.fireGroups + 1] = { name = data.name, aim = enemyAim }
            end
        end
    end

    local manpadsSpecs = specsForRoles(tasking.force, { Role.MANPADS })
    if #manpadsSpecs > 0 then
        local manpadsCenter = Sites:pickPointNear(enemyCenter, MANPADS_DISTANCE_MIN_METERS, MANPADS_DISTANCE_MAX_METERS)
        if manpadsCenter then
            local data = buildGroundGroup(prefix .. "-Enemy-MANPADS", manpadsCenter, 0, 0, manpadsSpecs, {
                invisible = true,
            })
            local group = spawn(config.redCountryId, Group.Category.GROUND, data)
            track(group, data, true, manpadsSpecs)
            if group then
                result.manpadsUnitName = data.units[1].name
            end
        else
            log(prefix .. ": no valid MANPADS position, skipping it")
        end
    end

    if fireGroupId then
        local jtacData = buildJtacGroup(prefix .. "-JTAC", tasking.slot, enemyCenter, fireGroupId)
        if spawn(config.blueCountryId, Group.Category.AIRPLANE, jtacData) then
            result.groupNames[#result.groupNames + 1] = jtacData.name
            result.jtacGroupName = jtacData.name
            result.jtacUnitName = jtacData.units[1].name
        end
    end

    log(
        string.format(
            "%s: %d friendly, %d enemy (%d key) units",
            prefix,
            #result.friendlyUnitNames,
            #result.enemyUnitNames,
            #result.keyUnitNames
        )
    )
    return result
end

-- Move each fire group's aim point around its original target so the fire
-- looks less mechanical (Operation Infinity, updateFireTargets)
function Firefight:updateFireTargets(spawned)
    for _, fireGroup in ipairs(spawned.fireGroups) do
        local group = Group.getByName(fireGroup.name)
        if group and group:isExist() then
            local aim = Spatial:randomPointInRadius(fireGroup.aim, FIRE_WANDER_METERS)
            group:getController():setTask(fireAtPointTask(aim))
        end
    end
end

env.info("[Firefight] Loaded successfully")
