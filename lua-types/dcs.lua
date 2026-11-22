---@meta
-- lua-language-server stubs for the DCS Simulator Scripting Engine.
-- Keep in sync with docs/scripting/reference. Each function notes its page.

-- Not covered by docs/scripting/reference yet
---@alias functionId number

---@class Warehouse
Warehouse = {}

---@class SceneryObject: Object
SceneryObject = {}

---@class country
---@field id table<string, integer> Country IDs, such as `country.id.CJTF_BLUE`
country = {}

---@class Position3
---@field p Vec3
---@field x Vec3
---@field y Vec3
---@field z Vec3

---@class Vec2
---@field x number
---@field y number

---@class Vec3
---@field x number
---@field y number
---@field z number

---@class AI
AI = {}

---@class Airbase: Object, CoalitionObject
Airbase = {}

---@class atmosphere
atmosphere = {}

---@class coalition
coalition = {}

---@class CoalitionObject: Object
CoalitionObject = {}

---@class Controller
Controller = {}

---@class coord
coord = {}

---@class env
env = {}

---@class Group
Group = {}

---@class land
land = {}

---@class missionCommands
missionCommands = {}

---@class net
net = {}

---@class Object
Object = {}

---@class Spot
Spot = {}

---@class StaticObject: Object, CoalitionObject
StaticObject = {}

---@class timer
timer = {}

---@class trigger
trigger = {}

---@class Unit: Object, CoalitionObject
Unit = {}

---@class Weapon: Object, CoalitionObject
Weapon = {}

---@class world
world = {}

---@class AI.Option
AI.Option = {}

---@class AI.Task
AI.Task = {}

---@class trigger.action
trigger.action = {}

---@class trigger.misc
trigger.misc = {}

---@class AI.Option.Air
AI.Option.Air = {}

---@class AI.Option.Ground
AI.Option.Ground = {}

---@class AI.Option.Naval
AI.Option.Naval = {}

---@class AI.Option.Air.val
AI.Option.Air.val = {}

---@class AI.Option.Ground.val
AI.Option.Ground.val = {}

---@class AI.Option.Naval.val
AI.Option.Naval.val = {}

---@enum AI.Option.Air.id
AI.Option.Air.id = {
    ROE = 0,
    REACTION_ON_THREAT = 1,
    RADAR_USING = 3,
    FLARE_USING = 4,
    Formation = 5,
    SILENCE = 7,
    RTB_ON_OUT_OF_AMMO = 10,
    ECM_USING = 13,
    PROHIBIT_AA = 14,
    PROHIBIT_JETT = 15,
    PROHIBIT_AB = 16,
    PROHIBIT_AG = 17,
    MISSILE_ATTACK = 18,
    PROHIBIT_WP_PASS_REPORT = 19,
    JETT_TANKS_IF_EMPTY = 25,
    FORCED_ATTACK = 26,
    PREFER_VERTICAL = 32,
    ALLOW_FORMATION_SIDE_SWAP = 35,
}

---@enum AI.Option.Air.val.ECM_USING
AI.Option.Air.val.ECM_USING = {
    NEVER_USE = 0,
    USE_IF_ONLY_LOCK_BY_RADAR = 1,
    USE_IF_DETECTED_LOCK_BY_RADAR = 2,
    ALWAYS_USE = 3,
}

---@enum AI.Option.Air.val.FLARE_USING
AI.Option.Air.val.FLARE_USING = {
    NEVER = 0,
    AGAINST_FIRED_MISSILE = 1,
    WHEN_FLYING_IN_SAM_WEZ = 2,
    WHEN_FLYING_NEAR_ENEMIES = 3,
}

---@enum AI.Option.Air.val.MISSILE_ATTACK
AI.Option.Air.val.MISSILE_ATTACK = {
    MAX_RANGE = 0,
    NEZ_RANGE = 1,
    HALF_WAY_RMAX_NEZ = 2,
    TARGET_THREAT_EST = 3,
    RANDOM_RANGE = 4,
}

---@enum AI.Option.Air.val.RADAR_USING
AI.Option.Air.val.RADAR_USING = {
    NEVER = 0,
    FOR_ATTACK_ONLY = 1,
    FOR_SEARCH_IF_REQUIRED = 2,
    FOR_CONTINUOUS_SEARCH = 3,
}

---@enum AI.Option.Air.val.REACTION_ON_THREAT
AI.Option.Air.val.REACTION_ON_THREAT = {
    NO_REACTION = 0,
    PASSIVE_DEFENCE = 1,
    EVADE_FIRE = 2,
    BYPASS_AND_ESCAPE = 3,
    ALLOW_ABORT_MISSION = 4,
    AAA_EVADE_FIRE = 5,
}

---@enum AI.Option.Air.val.ROE
AI.Option.Air.val.ROE = {
    WEAPON_FREE = 0,
    OPEN_FIRE_WEAPON_FREE = 1,
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4,
}

---@enum AI.Option.Ground.id
AI.Option.Ground.id = {
    ROE = 0,
    ALARM_STATE = 9,
    DISPERSE_ON_ATTACK = 8,
    ENGAGE_AIR_WEAPONS = 20,
    AC_ENGAGEMENT_RANGE_RESTRICTION = 24,
    EVASION_OF_ARM = 31,
}

---@enum AI.Option.Ground.val.ALARM_STATE
AI.Option.Ground.val.ALARM_STATE = {
    AUTO = 0,
    GREEN = 1,
    RED = 2,
}

---@enum AI.Option.Ground.val.ROE
AI.Option.Ground.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4,
}

---@enum AI.Option.Naval.id
AI.Option.Naval.id = {
    ROE = 0,
}

---@enum AI.Option.Naval.val.ROE
AI.Option.Naval.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4,
}

---@enum AI.Skill
AI.Skill = {
    PLAYER = "Player",
    CLIENT = "Client",
    AVERAGE = "Average",
    GOOD = "Good",
    HIGH = "High",
    EXCELLENT = "Excellent",
}

---@enum AI.Task.AltitudeType
AI.Task.AltitudeType = {
    RADIO = "RADIO",
    BARO = "BARO",
}

---@enum AI.Task.Designation
AI.Task.Designation = {
    NO = "No",
    WP = "WP",
    IR_POINTER = "IR-Pointer",
    LASER = "Laser",
    AUTO = "Auto",
}

---@enum AI.Task.OrbitPattern
AI.Task.OrbitPattern = {
    RACE_TRACK = "Race-Track",
    CIRCLE = "Circle",
}

---@enum AI.Task.TurnMethod
AI.Task.TurnMethod = {
    FLY_OVER_POINT = "Fly Over Point",
    FIN_POINT = "Fin Point",
}

---@enum AI.Task.VehicleFormation
AI.Task.VehicleFormation = {
    VEE = "Vee",
    ECHELON_RIGHT = "EchelonR",
    ECHELON_LEFT = "EchelonL",
    OFF_ROAD = "Off Road",
    RANK = "Rank",
    ON_ROAD = "On Road",
    CONE = "Cone",
    DIAMOND = "Diamond",
}

---@enum AI.Task.WaypointType
AI.Task.WaypointType = {
    TAKEOFF = "TakeOff",
    TAKEOFF_PARKING = "TakeOffParking",
    TAKEOFF_PARKING_HOT = "TakeOffParkingHot",
    TURNING_POINT = "Turning Point",
    LAND = "Land",
}

---@enum AI.Task.WeaponExpend
AI.Task.WeaponExpend = {
    ONE = "One",
    TWO = "Two",
    FOUR = "Four",
    QUARTER = "Quarter",
    HALF = "Half",
    ALL = "All",
}

---@enum Airbase.Category
Airbase.Category = {
    AIRDROME = 0,
    HELIPAD = 1,
    SHIP = 2,
}

---@enum Controller.Detection
Controller.Detection = {
    VISUAL = 1,
    OPTIC = 2,
    RADAR = 4,
    IRST = 8,
    RWR = 16,
    DLINK = 32,
}

---@enum Group.Category
Group.Category = {
    AIRPLANE = 0,
    HELICOPTER = 1,
    GROUND = 2,
    SHIP = 3,
    TRAIN = 4,
}

---@enum Object.Category
Object.Category = {
    UNIT = 1,
    WEAPON = 2,
    STATIC = 3,
    BASE = 4,
    SCENERY = 5,
    CARGO = 6,
}

---@enum Spot.Category
Spot.Category = {
    INFRA_RED = 0,
    LASER = 1,
}

---@enum Unit.Category
Unit.Category = {
    AIRPLANE = 0,
    HELICOPTER = 1,
    GROUND_UNIT = 2,
    SHIP = 3,
    STRUCTURE = 4,
}

---@enum Weapon.Category
Weapon.Category = {
    SHELL = 0,
    MISSILE = 1,
    ROCKET = 2,
    BOMB = 3,
}

---@enum Weapon.GuidanceType
Weapon.GuidanceType = {
    INS = 1,
    IR = 2,
    RADAR_ACTIVE = 3,
    RADAR_SEMI_ACTIVE = 4,
    RADAR_PASSIVE = 5,
    TV = 6,
    LASER = 7,
    TELE = 8,
}

---@enum coalition.side
coalition.side = {
    NEUTRAL = 0,
    RED = 1,
    BLUE = 2,
}

---@enum land.SurfaceType
land.SurfaceType = {
    LAND = 1,
    SHALLOW_WATER = 2,
    WATER = 3,
    ROAD = 4,
    RUNWAY = 5,
}

---@enum trigger.flareColor
trigger.flareColor = {
    Green = 0,
    Red = 1,
    White = 2,
    Yellow = 3,
}

---@enum trigger.smokeColor
trigger.smokeColor = {
    Green = 0,
    Red = 1,
    White = 2,
    Orange = 3,
    Blue = 4,
}

---@enum world.VolumeType
world.VolumeType = {
    SEGMENT = 0,
    BOX = 1,
    SPHERE = 2,
    PYRAMID = 3,
}

---@enum world.event
world.event = {
    S_EVENT_SHOT = 1,
    S_EVENT_HIT = 2,
    S_EVENT_TAKEOFF = 3,
    S_EVENT_LAND = 4,
    S_EVENT_CRASH = 5,
    S_EVENT_EJECTION = 6,
    S_EVENT_REFUELING = 7,
    S_EVENT_DEAD = 8,
    S_EVENT_PILOT_DEAD = 9,
    S_EVENT_BASE_CAPTURED = 10,
    S_EVENT_MISSION_START = 11,
    S_EVENT_MISSION_END = 12,
    S_EVENT_REFUELING_STOP = 14,
    S_EVENT_BIRTH = 15,
    S_EVENT_HUMAN_FAILURE = 16,
    S_EVENT_DETAILED_FAILURE = 17,
    S_EVENT_ENGINE_STARTUP = 18,
    S_EVENT_ENGINE_SHUTDOWN = 19,
    S_EVENT_PLAYER_ENTER_UNIT = 20,
    S_EVENT_PLAYER_LEAVE_UNIT = 21,
    S_EVENT_PLAYER_COMMENT = 22,
    S_EVENT_SHOOTING_START = 23,
    S_EVENT_SHOOTING_END = 24,
    S_EVENT_MARK_ADDED = 25,
    S_EVENT_MARK_CHANGE = 26,
    S_EVENT_MARK_REMOVE = 27,
    S_EVENT_KILL = 28,
    S_EVENT_SCORE = 29,
    S_EVENT_UNIT_LOST = 30,
    S_EVENT_LANDING_AFTER_EJECTION = 31,
    S_EVENT_DISCARD_CHAIR_AFTER_EJECTION = 32,
    S_EVENT_WEAPON_ADD = 33,
    S_EVENT_LANDING_QUALITY_MARK = 34,
    S_EVENT_AI_ABORT_MISSION = 35,
    S_EVENT_RUNWAY_TAKEOFF = 36,
    S_EVENT_RUNWAY_TOUCH = 37,
}

-- docs/scripting/reference/classes/airbase.md
---@param name string
---@return Airbase?
function Airbase.getByName(name) end

-- docs/scripting/reference/classes/airbase.md
---@param enable boolean
function Airbase:autoCapture(enable) end

-- docs/scripting/reference/classes/airbase.md
---@return boolean
function Airbase:autoCaptureIsOn() end

-- docs/scripting/reference/classes/airbase.md
---@return string
function Airbase:getCallsign() end

-- docs/scripting/reference/classes/airbase.md
---@param available? boolean
---@return table
function Airbase:getParking(available) end

-- docs/scripting/reference/classes/airbase.md
---@return boolean
function Airbase:getRadioSilentMode() end

-- docs/scripting/reference/classes/airbase.md
---@return table
function Airbase:getRunways() end

-- docs/scripting/reference/classes/airbase.md
---@param index number
---@return Unit?
function Airbase:getUnit(index) end

-- docs/scripting/reference/classes/airbase.md
---@return Warehouse
function Airbase:getWarehouse() end

-- docs/scripting/reference/classes/airbase.md
---@param coalitionId number
function Airbase:setCoalition(coalitionId) end

-- docs/scripting/reference/classes/airbase.md
---@param silent boolean
function Airbase:setRadioSilentMode(silent) end

-- docs/scripting/reference/singletons/atmosphere.md
---@param position Vec3
---@return number
---@return number
function atmosphere.getTemperatureAndPressure(position) end

-- docs/scripting/reference/singletons/atmosphere.md
---@param position Vec3
---@return Vec3
function atmosphere.getWind(position) end

-- docs/scripting/reference/singletons/atmosphere.md
---@param position Vec3
---@return Vec3
function atmosphere.getWindWithTurbulence(position) end

-- docs/scripting/reference/singletons/coalition.md
---@param countryId number
---@param groupCategory number
---@param groupData table
---@return Group
function coalition.addGroup(countryId, groupCategory, groupData) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@param refPoint table
function coalition.addRefPoint(coalitionId, refPoint) end

-- docs/scripting/reference/singletons/coalition.md
---@param countryId number
---@param staticData table
---@return StaticObject
function coalition.addStaticObject(countryId, staticData) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@return table
function coalition.getAirbases(coalitionId) end

-- docs/scripting/reference/singletons/coalition.md
---@param countryId number
---@return number
function coalition.getCountryCoalition(countryId) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@param groupCategory? number
---@return table
function coalition.getGroups(coalitionId, groupCategory) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@return Vec3
function coalition.getMainRefPoint(coalitionId) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@return table
function coalition.getPlayers(coalitionId) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@return table
function coalition.getRefPoints(coalitionId) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@param serviceType number
---@return table
function coalition.getServiceProviders(coalitionId, serviceType) end

-- docs/scripting/reference/singletons/coalition.md
---@param coalitionId number
---@return table
function coalition.getStaticObjects(coalitionId) end

-- docs/scripting/reference/classes/coalition-object.md
---@return number
function CoalitionObject:getCoalition() end

-- docs/scripting/reference/classes/coalition-object.md
---@return number
function CoalitionObject:getCountry() end

-- docs/scripting/reference/classes/controller.md
---@param detectionTypes? number
---@return table
function Controller:getDetectedTargets(detectionTypes) end

-- docs/scripting/reference/classes/controller.md
---@return boolean
function Controller:hasTask() end

-- docs/scripting/reference/classes/controller.md
---@param target Object
---@param detectionTypes number
---@return boolean
---@return boolean
---@return any ...
function Controller:isTargetDetected(target, detectionTypes) end

-- docs/scripting/reference/classes/controller.md
---@param target Object
---@param type boolean
---@param distance boolean
function Controller:knowTarget(target, type, distance) end

-- docs/scripting/reference/classes/controller.md
function Controller:popTask() end

-- docs/scripting/reference/classes/controller.md
---@param task table
function Controller:pushTask(task) end

-- docs/scripting/reference/classes/controller.md
function Controller:resetTask() end

-- docs/scripting/reference/classes/controller.md
---@param altitude number
---@param keep boolean
---@param altType string
function Controller:setAltitude(altitude, keep, altType) end

-- docs/scripting/reference/classes/controller.md
---@param command table
function Controller:setCommand(command) end

-- docs/scripting/reference/classes/controller.md
---@param on boolean
function Controller:setOnOff(on) end

-- docs/scripting/reference/classes/controller.md
---@param optionId number
---@param value any
function Controller:setOption(optionId, value) end

-- docs/scripting/reference/classes/controller.md
---@param speed number
---@param keep boolean
function Controller:setSpeed(speed, keep) end

-- docs/scripting/reference/classes/controller.md
---@param task table
function Controller:setTask(task) end

-- docs/scripting/reference/singletons/coord.md
---@param latitude number
---@param longitude number
---@param altitude? number
---@return Vec3
function coord.LLtoLO(latitude, longitude, altitude) end

-- docs/scripting/reference/singletons/coord.md
---@param latitude number
---@param longitude number
---@return table
function coord.LLtoMGRS(latitude, longitude) end

-- docs/scripting/reference/singletons/coord.md
---@param point Vec3
---@return number
---@return number
---@return number
function coord.LOtoLL(point) end

-- docs/scripting/reference/singletons/coord.md
---@param mgrs table
---@return number
---@return number
function coord.MGRStoLL(mgrs) end

-- docs/scripting/reference/singletons/env.md
---@param message string
---@param showMessageBox? boolean
function env.error(message, showMessageBox) end

-- docs/scripting/reference/singletons/env.md
---@param key string
---@return string
function env.getValueDictByKey(key) end

-- docs/scripting/reference/singletons/env.md
---@param message string
---@param showMessageBox? boolean
function env.info(message, showMessageBox) end

-- docs/scripting/reference/singletons/env.md
---@param enabled boolean
function env.setErrorMessageBoxEnabled(enabled) end

-- docs/scripting/reference/singletons/env.md
---@param message string
---@param showMessageBox? boolean
function env.warning(message, showMessageBox) end

-- docs/scripting/reference/classes/group.md
---@param name string
---@return Group?
function Group.getByName(name) end

-- docs/scripting/reference/classes/group.md
function Group:activate() end

-- docs/scripting/reference/classes/group.md
function Group:destroy() end

-- docs/scripting/reference/classes/group.md
---@param enable boolean
function Group:enableEmission(enable) end

-- docs/scripting/reference/classes/group.md
---@return number
function Group:getCategory() end

-- docs/scripting/reference/classes/group.md
---@return number
function Group:getCoalition() end

-- docs/scripting/reference/classes/group.md
---@return Controller
function Group:getController() end

-- docs/scripting/reference/classes/group.md
---@return number
function Group:getID() end

-- docs/scripting/reference/classes/group.md
---@return number
function Group:getInitialSize() end

-- docs/scripting/reference/classes/group.md
---@return string
function Group:getName() end

-- docs/scripting/reference/classes/group.md
---@return number
function Group:getSize() end

-- docs/scripting/reference/classes/group.md
---@param index number
---@return Unit
function Group:getUnit(index) end

-- docs/scripting/reference/classes/group.md
---@return table
function Group:getUnits() end

-- docs/scripting/reference/classes/group.md
---@return boolean
function Group:isExist() end

-- docs/scripting/reference/singletons/land.md
---@param roadType string
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return table
function land.findPathOnRoads(roadType, x1, y1, x2, y2) end

-- docs/scripting/reference/singletons/land.md
---@param roadType string
---@param x number
---@param y number
---@return number
---@return number
function land.getClosestPointOnRoads(roadType, x, y) end

-- docs/scripting/reference/singletons/land.md
---@param position Vec2
---@return number
function land.getHeight(position) end

-- docs/scripting/reference/singletons/land.md
---@param origin Vec3
---@param direction Vec3
---@param distance number
---@return Vec3?
function land.getIP(origin, direction, distance) end

-- docs/scripting/reference/singletons/land.md
---@param position Vec2
---@return number
function land.getSurfaceHeightWithSeabed(position) end

-- docs/scripting/reference/singletons/land.md
---@param position Vec2
---@return number
function land.getSurfaceType(position) end

-- docs/scripting/reference/singletons/land.md
---@param origin Vec3
---@param destination Vec3
---@return boolean
function land.isVisible(origin, destination) end

-- docs/scripting/reference/singletons/land.md
---@param start Vec2
---@param finish Vec2
---@return table
function land.profile(start, finish) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param name string
---@param path? table
---@param handler function
---@param argument any
---@return table
function missionCommands.addCommand(name, path, handler, argument) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param coalitionId number
---@param name string
---@param path? table
---@param handler function
---@param argument any
---@return table
function missionCommands.addCommandForCoalition(coalitionId, name, path, handler, argument) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param groupId number
---@param name string
---@param path? table
---@param handler function
---@param argument any
---@return table
function missionCommands.addCommandForGroup(groupId, name, path, handler, argument) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param name string
---@param path? table
---@return table
function missionCommands.addSubMenu(name, path) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param coalitionId number
---@param name string
---@param path? table
---@return table
function missionCommands.addSubMenuForCoalition(coalitionId, name, path) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param groupId number
---@param name string
---@param path? table
---@return table
function missionCommands.addSubMenuForGroup(groupId, name, path) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param path table
function missionCommands.removeItem(path) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param coalitionId number
---@param path table
function missionCommands.removeItemForCoalition(coalitionId, path) end

-- docs/scripting/reference/singletons/mission-commands.md
---@param groupId number
---@param path table
function missionCommands.removeItemForGroup(groupId, path) end

-- docs/scripting/reference/singletons/net.md
---@param state string
---@param luaCode string
---@return string
function net.dostring_in(state, luaCode) end

-- docs/scripting/reference/singletons/net.md
---@param playerID number
---@param sideID number
---@param slotID string
---@return boolean
function net.force_player_slot(playerID, sideID, slotID) end

-- docs/scripting/reference/singletons/net.md
---@return number
function net.get_my_player_id() end

-- docs/scripting/reference/singletons/net.md
---@param playerID number
---@return string
function net.get_name(playerID) end

-- docs/scripting/reference/singletons/net.md
---@param playerID number
---@param attribute? string
---@return any
function net.get_player_info(playerID, attribute) end

-- docs/scripting/reference/singletons/net.md
---@return table
function net.get_player_list() end

-- docs/scripting/reference/singletons/net.md
---@return number
function net.get_server_id() end

-- docs/scripting/reference/singletons/net.md
---@param playerID number
---@return number
---@return string
function net.get_slot(playerID) end

-- docs/scripting/reference/singletons/net.md
---@param playerID number
---@param statID number
---@return number
function net.get_stat(playerID, statID) end

-- docs/scripting/reference/singletons/net.md
---@param json string
---@return any
function net.json2lua(json) end

-- docs/scripting/reference/singletons/net.md
---@param playerID number
---@param message string
function net.kick(playerID, message) end

-- docs/scripting/reference/singletons/net.md
---@param message string
function net.log(message) end

-- docs/scripting/reference/singletons/net.md
---@param value any
---@return string
function net.lua2json(value) end

-- docs/scripting/reference/singletons/net.md
---@param message string
---@param from? number
function net.recv_chat(message, from) end

-- docs/scripting/reference/singletons/net.md
---@param message string
---@param all boolean
function net.send_chat(message, all) end

-- docs/scripting/reference/singletons/net.md
---@param message string
---@param playerID number
function net.send_chat_to(message, playerID) end

-- docs/scripting/reference/singletons/net.md
---@param sideID number
---@param slotID string
function net.set_slot(sideID, slotID) end

-- docs/scripting/reference/singletons/net.md
---@param message string
function net.trace(message) end

-- docs/scripting/reference/classes/object.md
function Object:destroy() end

-- docs/scripting/reference/classes/object.md
---@return number
function Object:getCategory() end

-- docs/scripting/reference/classes/object.md
---@return table
function Object:getDesc() end

-- docs/scripting/reference/classes/object.md
---@return string
function Object:getName() end

-- docs/scripting/reference/classes/object.md
---@return Vec3
function Object:getPoint() end

-- docs/scripting/reference/classes/object.md
---@return Position3
function Object:getPosition() end

-- docs/scripting/reference/classes/object.md
---@return string
function Object:getTypeName() end

-- docs/scripting/reference/classes/object.md
---@return Vec3
function Object:getVelocity() end

-- docs/scripting/reference/classes/object.md
---@param attributeName string
---@return boolean
function Object:hasAttribute(attributeName) end

-- docs/scripting/reference/classes/object.md
---@return boolean
function Object:inAir() end

-- docs/scripting/reference/classes/object.md
---@return boolean
function Object:isExist() end

-- docs/scripting/reference/classes/spot.md
---@param source Object
---@param localPosition table
---@param targetPoint Vec3
---@return Spot
function Spot.createInfraRed(source, localPosition, targetPoint) end

-- docs/scripting/reference/classes/spot.md
---@param source Object
---@param localPosition table
---@param targetPoint Vec3
---@param laserCode number
---@return Spot
function Spot.createLaser(source, localPosition, targetPoint, laserCode) end

-- docs/scripting/reference/classes/spot.md
function Spot:destroy() end

-- docs/scripting/reference/classes/spot.md
---@return number
function Spot:getCode() end

-- docs/scripting/reference/classes/spot.md
---@return Vec3
function Spot:getPoint() end

-- docs/scripting/reference/classes/spot.md
---@param code number
function Spot:setCode(code) end

-- docs/scripting/reference/classes/spot.md
---@param targetPoint Vec3
function Spot:setPoint(targetPoint) end

-- docs/scripting/reference/classes/static-object.md
---@param name string
---@return StaticObject?
function StaticObject.getByName(name) end

-- docs/scripting/reference/classes/static-object.md
---@return number
function StaticObject:getLife() end

-- docs/scripting/reference/singletons/timer.md
---@return number
function timer.getAbsTime() end

-- docs/scripting/reference/singletons/timer.md
---@return number
function timer.getTime() end

-- docs/scripting/reference/singletons/timer.md
---@return number
function timer.getTime0() end

-- docs/scripting/reference/singletons/timer.md
---@param id functionId
function timer.removeFunction(id) end

-- docs/scripting/reference/singletons/timer.md
---@param callback function
---@param argument any
---@param runTime number
---@return functionId
function timer.scheduleFunction(callback, argument, runTime) end

-- docs/scripting/reference/singletons/timer.md
---@param id functionId
---@param newTime number
function timer.setFunctionTime(id, newTime) end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param id number
---@param startPoint Vec3
---@param endPoint Vec3
---@param color table
---@param fillColor table
---@param lineType number
---@param readOnly boolean
---@param message string
function trigger.action.arrowToAll(
    coalitionId,
    id,
    startPoint,
    endPoint,
    color,
    fillColor,
    lineType,
    readOnly,
    message
)
end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param id number
---@param center Vec3
---@param radius number
---@param color table
---@param fillColor table
---@param lineType number
---@param readOnly? boolean
---@param message? string
function trigger.action.circleToAll(coalitionId, id, center, radius, color, fillColor, lineType, readOnly, message) end

-- docs/scripting/reference/singletons/trigger.md
---@param unitName string
---@param smokeColor number
---@param altitude? number
function trigger.action.ctfColorTag(unitName, smokeColor, altitude) end

-- docs/scripting/reference/singletons/trigger.md
---@param position Vec3
---@param smokeType number
---@param density number
---@param name string
function trigger.action.effectSmokeBig(position, smokeType, density, name) end

-- docs/scripting/reference/singletons/trigger.md
---@param name string
function trigger.action.effectSmokeStop(name) end

-- docs/scripting/reference/singletons/trigger.md
---@param position Vec3
---@param power number
function trigger.action.explosion(position, power) end

-- docs/scripting/reference/singletons/trigger.md
---@param position Vec3
---@param power number
function trigger.action.illuminationBomb(position, power) end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param id number
---@param startPoint Vec3
---@param endPoint Vec3
---@param color table
---@param lineType number
---@param readOnly? boolean
---@param message? string
function trigger.action.lineToAll(coalitionId, id, startPoint, endPoint, color, lineType, readOnly, message) end

-- docs/scripting/reference/singletons/trigger.md
---@param id number
---@param text string
---@param position Vec3
---@param readOnly? boolean
---@param message? string
function trigger.action.markToAll(id, text, position, readOnly, message) end

-- docs/scripting/reference/singletons/trigger.md
---@param id number
---@param text string
---@param position Vec3
---@param coalitionId number
---@param readOnly? boolean
---@param message? string
function trigger.action.markToCoalition(id, text, position, coalitionId, readOnly, message) end

-- docs/scripting/reference/singletons/trigger.md
---@param id number
---@param text string
---@param position Vec3
---@param groupId number
---@param readOnly? boolean
---@param message? string
function trigger.action.markToGroup(id, text, position, groupId, readOnly, message) end

-- docs/scripting/reference/singletons/trigger.md
---@param shapeId number
---@param coalitionId number
---@param id number
---@param point1 Vec3
---@param ... any
function trigger.action.markupToAll(shapeId, coalitionId, id, point1, ...) end

-- docs/scripting/reference/singletons/trigger.md
---@param soundFile string
function trigger.action.outSound(soundFile) end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param soundFile string
function trigger.action.outSoundForCoalition(coalitionId, soundFile) end

-- docs/scripting/reference/singletons/trigger.md
---@param countryId number
---@param soundFile string
function trigger.action.outSoundForCountry(countryId, soundFile) end

-- docs/scripting/reference/singletons/trigger.md
---@param groupId number
---@param soundFile string
function trigger.action.outSoundForGroup(groupId, soundFile) end

-- docs/scripting/reference/singletons/trigger.md
---@param unitId number
---@param soundFile string
function trigger.action.outSoundForUnit(unitId, soundFile) end

-- docs/scripting/reference/singletons/trigger.md
---@param text string
---@param displayTime number
---@param clearView? boolean
function trigger.action.outText(text, displayTime, clearView) end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param text string
---@param displayTime number
---@param clearView? boolean
function trigger.action.outTextForCoalition(coalitionId, text, displayTime, clearView) end

-- docs/scripting/reference/singletons/trigger.md
---@param countryId number
---@param text string
---@param displayTime number
---@param clearView? boolean
function trigger.action.outTextForCountry(countryId, text, displayTime, clearView) end

-- docs/scripting/reference/singletons/trigger.md
---@param groupId number
---@param text string
---@param displayTime number
---@param clearView? boolean
function trigger.action.outTextForGroup(groupId, text, displayTime, clearView) end

-- docs/scripting/reference/singletons/trigger.md
---@param unitId number
---@param text string
---@param displayTime number
---@param clearView? boolean
function trigger.action.outTextForUnit(unitId, text, displayTime, clearView) end

-- docs/scripting/reference/singletons/trigger.md
---@param group Group
---@param taskIndex number
function trigger.action.pushAITask(group, taskIndex) end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param id number
---@param point1 Vec3
---@param point2 Vec3
---@param point3 Vec3
---@param point4 Vec3
---@param color table
---@param fillColor table
---@param lineType number
---@param readOnly boolean
---@param message string
function trigger.action.quadToAll(
    coalitionId,
    id,
    point1,
    point2,
    point3,
    point4,
    color,
    fillColor,
    lineType,
    readOnly,
    message
)
end

-- docs/scripting/reference/singletons/trigger.md
---@param soundFile string
---@param position Vec3
---@param modulation number
---@param loop boolean
---@param frequency number
---@param power number
---@param name string
function trigger.action.radioTransmission(soundFile, position, modulation, loop, frequency, power, name) end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param id number
---@param startPoint Vec3
---@param endPoint Vec3
---@param color table
---@param fillColor table
---@param lineType number
---@param readOnly boolean
---@param message string
function trigger.action.rectToAll(
    coalitionId,
    id,
    startPoint,
    endPoint,
    color,
    fillColor,
    lineType,
    readOnly,
    message
)
end

-- docs/scripting/reference/singletons/trigger.md
---@param id number
function trigger.action.removeMark(id) end

-- docs/scripting/reference/singletons/trigger.md
---@param group Group
---@param taskIndex number
function trigger.action.setAITask(group, taskIndex) end

-- docs/scripting/reference/singletons/trigger.md
---@param unitName string
---@param mass number
function trigger.action.setUnitInternalCargo(unitName, mass) end

-- docs/scripting/reference/singletons/trigger.md
---@param flagName string
---@param value number
function trigger.action.setUserFlag(flagName, value) end

-- docs/scripting/reference/singletons/trigger.md
---@param position Vec3
---@param flareColor number
---@param azimuth number
function trigger.action.signalFlare(position, flareColor, azimuth) end

-- docs/scripting/reference/singletons/trigger.md
---@param position Vec3
---@param smokeColor number
function trigger.action.smoke(position, smokeColor) end

-- docs/scripting/reference/singletons/trigger.md
---@param name string
function trigger.action.stopRadioTransmission(name) end

-- docs/scripting/reference/singletons/trigger.md
---@param coalitionId number
---@param id number
---@param point Vec3
---@param color table
---@param fillColor table
---@param fontSize number
---@param readOnly boolean
---@param text string
function trigger.action.textToAll(coalitionId, id, point, color, fillColor, fontSize, readOnly, text) end

-- docs/scripting/reference/singletons/trigger.md
---@param flagName string
---@return number
function trigger.misc.getUserFlag(flagName) end

-- docs/scripting/reference/singletons/trigger.md
---@param zoneName string
---@return table?
function trigger.misc.getZone(zoneName) end

-- docs/scripting/reference/classes/unit.md
---@param name string
---@return Unit?
function Unit.getByName(name) end

-- docs/scripting/reference/classes/unit.md
---@param enable boolean
function Unit:enableEmission(enable) end

-- docs/scripting/reference/classes/unit.md
---@return table
function Unit:getAmmo() end

-- docs/scripting/reference/classes/unit.md
---@return string
function Unit:getCallsign() end

-- docs/scripting/reference/classes/unit.md
---@return Controller
function Unit:getController() end

-- docs/scripting/reference/classes/unit.md
---@return number
function Unit:getFuel() end

-- docs/scripting/reference/classes/unit.md
---@return Group
function Unit:getGroup() end

-- docs/scripting/reference/classes/unit.md
---@return number
function Unit:getID() end

-- docs/scripting/reference/classes/unit.md
---@return number
function Unit:getLife() end

-- docs/scripting/reference/classes/unit.md
---@return number
function Unit:getLife0() end

-- docs/scripting/reference/classes/unit.md
---@return number
function Unit:getNumber() end

-- docs/scripting/reference/classes/unit.md
---@return string?
function Unit:getPlayerName() end

-- docs/scripting/reference/classes/unit.md
---@return boolean
---@return Object
function Unit:getRadar() end

-- docs/scripting/reference/classes/unit.md
---@return table
function Unit:getSensors() end

-- docs/scripting/reference/classes/unit.md
---@return boolean
function Unit:isActive() end

-- docs/scripting/reference/classes/weapon.md
---@return Unit?
function Weapon:getLauncher() end

-- docs/scripting/reference/classes/weapon.md
---@return Object?
function Weapon:getTarget() end

-- docs/scripting/reference/singletons/world.md
---@param handler table
function world.addEventHandler(handler) end

-- docs/scripting/reference/singletons/world.md
---@param coalitionId? number
---@return table
function world.getAirbases(coalitionId) end

-- docs/scripting/reference/singletons/world.md
---@return table
function world.getMarkPanels() end

-- docs/scripting/reference/singletons/world.md
---@return Unit?
function world.getPlayer() end

-- docs/scripting/reference/singletons/world.md
---@param handler table
function world.removeEventHandler(handler) end

-- docs/scripting/reference/singletons/world.md
---@param searchVolume table
---@return number
function world.removeJunk(searchVolume) end

-- docs/scripting/reference/singletons/world.md
---@param objectCategory number
---@param searchVolume table
---@param handler function
function world.searchObjects(objectCategory, searchVolume, handler) end
