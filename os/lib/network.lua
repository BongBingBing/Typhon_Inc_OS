-- Network message bus over wired/wireless modem
-- Topics are plain strings; handlers receive (data, from_channel, reply_channel).

local Network = {}
local modem        = nil
local my_channel   = nil
local cfg          = nil
local subscriptions= {}   -- topic -> {fn, ...}

function Network.init(config, channel)
    cfg        = config
    my_channel = channel
    local side = config.network.modem_side

    if not peripheral.isPresent(side) then
        error("No modem on side '" .. side .. "'. Check config.network.modem_side")
    end
    modem = peripheral.wrap(side)
    modem.open(channel)
    modem.open(config.network.emergency_channel)
    modem.open(config.network.broadcast_channel)
end

function Network.subscribe(topic, fn)
    subscriptions[topic] = subscriptions[topic] or {}
    subscriptions[topic][#subscriptions[topic] + 1] = fn
end

function Network.send(channel, topic, data)
    if not modem then return end
    modem.transmit(channel, my_channel, { topic = topic, data = data, from = my_channel })
end

function Network.broadcast(topic, data)
    Network.send(cfg.network.broadcast_channel, topic, data)
end

function Network.emergency(topic, data)
    Network.send(cfg.network.emergency_channel, topic, data)
end

-- Dispatch a raw modem_message event to registered handlers
local function dispatch(side, ch, reply_ch, msg, dist)
    if type(msg) ~= "table" or not msg.topic then return end
    local list = subscriptions[msg.topic]
    if list then
        for _, fn in ipairs(list) do fn(msg.data, msg.from, reply_ch) end
    end
    local wild = subscriptions["*"]
    if wild then
        for _, fn in ipairs(wild) do fn(msg.topic, msg.data, msg.from) end
    end
end

-- Kernel task: blocks on modem_message and dispatches
function Network.task()
    return function()
        while true do
            local _, side, ch, reply_ch, msg, dist = os.pullEvent("modem_message")
            dispatch(side, ch, reply_ch, msg, dist)
        end
    end
end

return Network
