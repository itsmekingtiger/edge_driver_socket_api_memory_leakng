local Driver = require("st.driver")
local caps = require("st.capabilities")

local cosock = require("cosock")
local socket = cosock.socket
local log = require("log")

-------------------------------------------------------------------------------
--- Discovery
---
--- Just create dummy device.
-------------------------------------------------------------------------------
local function dummy_fetch_device_info()
    return {
        name = "dummy name",
        vendor = "dummy vendor",
        mn = "dummy mn",
        model = "dummy model",
        location = "dummy location",
    }
end

local function create_device(driver, device)
    local metadata = {
        type = "LAN",
        device_network_id = device.location,
        label = device.name,
        profile = "BinarySwitch.v1",
        manufacturer = device.mn,
        model = device.model,
        vendor_provided_label = device.UDN,
    }
    return driver:try_create_device(metadata)
end

function discovery(driver, opts, cons)
    local device = dummy_fetch_device_info()
    return create_device(driver, device)
end

-------------------------------------------------------------------------------
--- LifeCycle
---
--- Main parts of this problem.
--- Original code(my lan driver) invoke function every 30 sec,
--- which advertises server's IP via broadcast.
-------------------------------------------------------------------------------
local lifecycles = {}
function lifecycles.init(driver, device)
    device.thread:call_on_schedule(10, function()
        do
            collectgarbage("collect"); collectgarbage("collect");
            local mem_usage = collectgarbage("count")
            log.debug(string.format("DEBUG\tCurrent Memory usage: %.1fKiB", mem_usage))
        end

        --- Creating socket cause memory leaks,
        --- never be GCed.
        --- try with comment below loop and see memory usage.
        ---
        --- At here, to demonstrate clearly, creating 10 sockets.
        --- When you create one socket, you can check increasing memory usage about 100 bytes.
        for i = 1, 10 do
            local sock = assert(socket.udp())
            sock:setoption("broadcast", true)
            sock:settimeout(3)
            sock:close()
        end

    end, "Resync Connectivity")
end

function lifecycles.removed(_, device)
    for timer in pairs(device.thread.timers) do
        device.thread:cancel_timer(timer)
    end
end

-------------------------------------------------------------------------------
--- Driver
---
--- Just dummy driver with empty handlers.
-------------------------------------------------------------------------------

local driver = Driver('LAN-BinarySwitch', {
    discovery = discovery,
    lifecycle_handlers = lifecycles,
    supported_capabilities = { caps.switch, caps.refresh },
    capability_handlers = {
        [caps.switch.ID] = {
            [caps.switch.commands.on.NAME] = function(_, device, command) end,
            [caps.switch.commands.off.NAME] = function(_, device, command) end,
        },
        [caps.refresh.ID] = {
            [caps.refresh.commands.refresh.NAME] = function(_, device, command) end,
        },
    },
})

driver:run()
