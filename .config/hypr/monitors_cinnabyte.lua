-- Monitors for cinnabyte
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({ output = "eDP-1", mode = "highres", position = "auto-left", scale = 1 }) -- Internal
hl.monitor({ output = "eDP-2", mode = "highres", position = "auto-left", scale = 1 }) -- Internal

hl.monitor({ output = "desc:AOC 27G2G3 0x00000219",           mode = "1920x1080@165", position = "auto",       scale = 1 })
hl.monitor({ output = "desc:HP Inc. HP V27i G5 CNC4262J6Z",   mode = "1920x1080@60",  position = "auto-right", scale = 1 })
hl.monitor({ output = "desc:AOC Q27G2SG4 XFXQ9HA001780",      mode = "2560x1440@144", position = "auto-right", scale = 1, vrr = 1 })

-- hl.monitor({ output = "desc:AOC 27G2G3 0x00000219", mode = "1920x1080@120", position = "auto", scale = 1 })
-- hl.monitor({ output = "serial:CNC4262J6Z", mode = "highres", position = "auto", scale = 0.5 })
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
