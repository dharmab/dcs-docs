-- =============================================================================
-- LOGGING UTILITIES
-- Shared logging factory for consistent debug output across scripts
-- =============================================================================

-- Guard against multiple script loads
if _G.LoggingLoaded then
    env.info("[Logging] Script already loaded, skipping")
    return
end
_G.LoggingLoaded = true

Logging = {}
Logging.config = { debug = true }

-- Create a logger function with a specific prefix
-- Usage: local log = Logging:create("MyModule")
--        log("Something happened")
-- Output: [MyModule] Something happened
function Logging:create(prefix)
    return function(message)
        if Logging.config.debug then
            env.info("[" .. prefix .. "] " .. message)
        end
    end
end

env.info("[Logging] Loaded successfully")
