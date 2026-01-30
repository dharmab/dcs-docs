-- =============================================================================
-- UNIT ID UTILITIES
-- Centralized ID generation to prevent collisions across scripts
-- =============================================================================

-- Guard against multiple script loads
if _G.UnitsLoaded then
    env.info("[Units] Script already loaded, skipping")
    return
end
_G.UnitsLoaded = true

Units = {}
Units.state = {
    groupCounter = 1000,
    unitCounter = 1000,
}

function Units:getNextGroupId()
    self.state.groupCounter = self.state.groupCounter + 1
    return self.state.groupCounter
end

function Units:getNextUnitId()
    self.state.unitCounter = self.state.unitCounter + 1
    return self.state.unitCounter
end

env.info("[Units] Loaded successfully")
