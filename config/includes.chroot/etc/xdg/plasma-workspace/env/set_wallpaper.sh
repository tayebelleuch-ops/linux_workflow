#!/bin/bash
# Set default wallpaper for new Plasma sessions
kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group "Containments" --group "1" --group "Wallpaper" --group "org.kde.image" --group "General" --key "Image" "/usr/share/wallpapers/background"