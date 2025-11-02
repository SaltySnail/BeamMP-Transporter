#!/usr/bin/bash

# === Copy Server ===
echo "📁 Copying server..."
cd Server
rm -rf "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Transporter"
cp -r Transporter "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Transporter"
cd ..

