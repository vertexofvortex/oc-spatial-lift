local sh = require("shell")
local cfg = require("config")

sh.execute(string.format("cp -r /mnt/%s/* /home/spatial-lift/", cfg.updates.update_floppy_address))
