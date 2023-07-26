local cfg = require("configuration")

local cfgs = cfg.read()

print(cfgs["config_main"])
print(cfgs["config_version"])
