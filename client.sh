#!/usr/bin/bash

# === Compress client ===
echo " 🛠️ Compressing client..."
cd Client
zip -r "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Client/TransporterGameMode.zip" art levels lua scripts ui settings vehicles LICENSE
cd ..
