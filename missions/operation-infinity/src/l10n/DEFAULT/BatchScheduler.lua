-- =============================================================================
-- BATCH SCHEDULER
-- Time-budgeted work processing to avoid triggering DCS Antifreeze
-- =============================================================================

-- Guard against multiple script loads
if _G.BatchSchedulerLoaded then
    env.info("[BatchScheduler] Script already loaded, skipping")
    return
end
_G.BatchSchedulerLoaded = true

BatchScheduler = {}

BatchScheduler.config = {
    frameBudgetMs = 1,  -- Max milliseconds per frame
    minItems = 1,       -- Always process at least 1 item
}

local NEXT_FRAME_MS = 1
local NEXT_FRAME_SECONDS = NEXT_FRAME_MS / 1000
local log = Logging:create("BatchScheduler")

local function scheduleNextFrame(fn)
    timer.scheduleFunction(fn, nil, timer.getTime() + NEXT_FRAME_SECONDS)
end

-- Process array items within time budget, yielding between frames
-- params.array: Array of items to process
-- params.callback: Function(item, index, context) called for each item
-- params.onComplete: Function(context) called when all items processed
-- params.context: Optional context object passed to callbacks
function BatchScheduler:processArray(params)
    local array = params.array
    local callback = params.callback
    local onComplete = params.onComplete
    local context = params.context or {}
    local index = 1
    local total = #array

    if total == 0 then
        if onComplete then onComplete(context) end
        return
    end

    local function processBatch()
        local startTime = timer.getTime() * 1000  -- Current time in ms
        local budgetMs = BatchScheduler.config.frameBudgetMs
        local itemsProcessed = 0

        while index <= total do
            callback(array[index], index, context)
            index = index + 1
            itemsProcessed = itemsProcessed + 1

            -- Check time budget (but always process at least minItems)
            local elapsed = (timer.getTime() * 1000) - startTime
            if itemsProcessed >= BatchScheduler.config.minItems and elapsed >= budgetMs then
                break
            end
        end

        if index <= total then
            return timer.getTime() + NEXT_FRAME_SECONDS  -- Next frame
        else
            if onComplete then onComplete(context) end
            return nil
        end
    end

    timer.scheduleFunction(processBatch, nil, timer.getTime() + NEXT_FRAME_SECONDS)
end

-- Execute sequential async steps with callbacks
-- params.steps: Array of {name = "step name", fn = function(context, done)}
-- params.onComplete: Function(context) called when all steps complete
-- params.onError: Function(err, stepName, context) called on error
-- params.context: Optional context object passed to all steps
function BatchScheduler:runSequence(params)
    local steps = params.steps
    local onComplete = params.onComplete
    local onError = params.onError
    local context = params.context or {}

    local stepIndex = 1

    local function runNextStep()
        if stepIndex > #steps then
            if onComplete then onComplete(context) end
            return nil
        end

        local step = steps[stepIndex]
        stepIndex = stepIndex + 1

        local function done(err)
            if err then
                if onError then
                    onError(err, step.name, context)
                else
                    log("Error in step " .. step.name .. ": " .. tostring(err))
                end
                return
            end
            scheduleNextFrame(runNextStep)
        end

        step.fn(context, done)
    end

    scheduleNextFrame(runNextStep)
end

env.info("[BatchScheduler] Loaded successfully")
