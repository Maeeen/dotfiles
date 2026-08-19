-- Per-host autostart for cinnabyte
hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
end)
