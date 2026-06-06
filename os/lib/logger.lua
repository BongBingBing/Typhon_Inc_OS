-- Logging utility: DEBUG / INFO / WARN / ERROR with optional file output

local Logger  = {}
local LEVELS  = { DEBUG=1, INFO=2, WARN=3, ERROR=4 }
local CLR     = { DEBUG=colors.gray, INFO=colors.white, WARN=colors.yellow, ERROR=colors.red }
local log_buf = {}
local log_file= nil

Logger.level  = "INFO"

function Logger.init(path)
    if path then
        if not fs.exists(fs.getDir(path)) then fs.makeDir(fs.getDir(path)) end
        log_file = fs.open(path, "a")
    end
end

function Logger.setLevel(lvl) Logger.level = lvl end

local function write(lvl, msg)
    if LEVELS[lvl] < LEVELS[Logger.level] then return end
    local ts   = tostring(os.time())
    local line = string.format("[%s][%s] %s", ts, lvl, msg)

    if term.isColour() then term.setTextColour(CLR[lvl] or colors.white) end
    print(line)
    if term.isColour() then term.setTextColour(colors.white) end

    if log_file then log_file.writeLine(line); log_file.flush() end

    log_buf[#log_buf + 1] = { ts=ts, level=lvl, msg=msg }
    if #log_buf > 200 then table.remove(log_buf, 1) end
end

function Logger.debug(m) write("DEBUG", m) end
function Logger.info(m)  write("INFO",  m) end
function Logger.warn(m)  write("WARN",  m) end
function Logger.error(m) write("ERROR", m) end

-- Returns the last n log entries as a list of {ts, level, msg}
function Logger.getRecent(n)
    local out   = {}
    local start = math.max(1, #log_buf - (n or 20) + 1)
    for i = start, #log_buf do out[#out + 1] = log_buf[i] end
    return out
end

return Logger
