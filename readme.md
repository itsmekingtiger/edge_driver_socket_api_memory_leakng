I built a driver using UDP socket.

But when I install that driver, then it freeze whole hub about few days later.

After digging in, I found a reason and problematic codes.

That was memory leak and caused by creating socket.



[Here](https://github.com/itsmekingtiger/edge_driver_socket_api_memory_leakng) is a simplest code to reproduce.



The result of running driver is, increasing memory usage as shown.

```
2022-07-15T08:28:39 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 352.6KiB
2022-07-15T08:28:40 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:28:49 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 354.6KiB
2022-07-15T08:28:50 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:28:59 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 356.2KiB
2022-07-15T08:29:00 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:29:09 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 357.3KiB
2022-07-15T08:29:10 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:29:19 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 359.0KiB
2022-07-15T08:29:20 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:29:29 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 360.4KiB
2022-07-15T08:29:30 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:29:39 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 361.8KiB
2022-07-15T08:29:40 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:29:49 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 364.1KiB
2022-07-15T08:29:50 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:29:59 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 365.7KiB
2022-07-15T08:30:00 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:30:10 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 367.0KiB
2022-07-15T08:30:10 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:30:20 DEBUG LAN BinarySwitch  DEBUG       Current Memory usage: 368.1KiB
2022-07-15T08:30:20 DEBUG LAN BinarySwitch  dumy name device thread event handled
```



And you can comment lines that creating socket,

```diff
function lifecycles.init(driver, device)
    device.thread:call_on_schedule(10, function()
        do
            collectgarbage("collect")
            collectgarbage("collect")

            local mem_useage = collectgarbage("count")

            log.debug(string.format("DEBUG\tCurrent Memory usage: %.1fKiB",
                mem_useage))
        end

-       for i = 1, 10 do
-           local sock = assert(socket.udp())
-           sock:setoption("broadcast", true)
-           sock:settimeout(3)
-           sock:close()
-       end
+       -- for i = 1, 10 do
+       --     local sock = assert(socket.udp())
+       --     sock:setoption("broadcast", true)
+       --     sock:settimeout(3)
+       --     sock:close()
+       -- end

    end, "Resync Connectivity")
end
```



You can see there is no leak.

```
2022-07-15T08:07:06 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:07:06 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:07:16 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:07:16 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:07:26 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:07:26 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:07:36 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:07:36 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:07:46 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:07:46 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:07:56 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:07:56 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:08:06 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:08:06 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:08:16 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:08:16 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:08:26 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:08:26 DEBUG LAN BinarySwitch  dumy name device thread event handled
2022-07-15T08:08:36 DEBUG LAN BinarySwitch  DEBUG   Current Memory usage: 352.1KiB
2022-07-15T08:08:36 DEBUG LAN BinarySwitch  dumy name device thread event handled
```



Is it kind of bug or did I wrong at some points?



Additionally here I append my original code.

```lua
local function _scan(opt)
    
    ...
    
    local sock = assert(socket.udp())
    if opt.laddr == "255.255.255.255" then
        sock:setoption("broadcast", true)
    end
    sock:settimeout(opt.timeout)

    local scan_msg = format_scan_message(opt.type, opt.mac)
    log.info(string.format("scanning with message: %s", scan_msg))

    assert(sock:sendto(scan_msg, opt.laddr, PORT), "failed to scan device")

    local msgs = {}

    while true do
        --- There are two possible case, [data, ip, port] or [nil, err, nil]
        local buf, ip, port = sock:receivefrom()
        if buf == nil then
            sock:close()
            return msgs
        end

        msgs[#msgs + 1] = buf

        if opt.find_one then
            sock:close()
            return msgs
        end
    end
end
```



Thank you in advance for your reply.