local ffi = require("ffi")
local os_name = os.getenv("OS")
if os_name and os_name:match("^Windows") then
    ffi.cdef[[
        void Sleep(unsigned int dwMilliseconds);
    ]]
    function sleep(seconds)
        ffi.C.Sleep(math.floor(seconds * 1000))
    end
else
    -- Further checks for Unix-like systems
    local home_path = os.getenv("HOME")
    if home_path then
        ffi.cdef[[
            int usleep(unsigned int useconds);
        ]]
        function usleep(microseconds)
            ffi.C.usleep(math.floor(microseconds))
        end
        function sleep(seconds)
            usleep(seconds * 1000000)
        end
    else
        print("Could not determine OS")
    end
end