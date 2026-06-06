-- TyphonOS Kernel: coroutine scheduler with event dispatch
-- Each task is a function that loops forever, yielding via os.pullEvent.

local Kernel = {}
local tasks  = {}

function Kernel.addTask(name, fn)
    tasks[#tasks + 1] = {
        name   = name,
        co     = coroutine.create(fn),
        filter = nil,
    }
end

function Kernel.run()
    -- Prime every coroutine so they reach their first yield
    for _, task in ipairs(tasks) do
        local ok, result = coroutine.resume(task.co)
        if not ok then
            printError("[KERNEL] '" .. task.name .. "' failed on start: " .. tostring(result))
        elseif type(result) == "string" then
            task.filter = result
        end
    end

    while true do
        local event = table.pack(os.pullEventRaw())
        local name  = event[1]

        if name == "terminate" then
            print("[KERNEL] Shutdown.")
            return
        end

        local alive = {}
        for _, task in ipairs(tasks) do
            if coroutine.status(task.co) ~= "dead" then
                if task.filter == nil or task.filter == name then
                    local ok, result = coroutine.resume(task.co, table.unpack(event, 1, event.n))
                    if not ok then
                        printError("[KERNEL] '" .. task.name .. "': " .. tostring(result))
                    elseif type(result) == "string" then
                        task.filter = result
                    else
                        task.filter = nil
                    end
                end
                alive[#alive + 1] = task
            end
        end
        tasks = alive
    end
end

return Kernel
