local sh = require("shell")
local cfg = require("config")

sh.execute(string.format("cp -r /home/spatial-lift/* /mnt/%s/", cfg.updates.update_floppy_address))
