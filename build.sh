#!/usr/bin/bash

set -e  # Stop on error

# === Compress Client ===
./client.sh

# === Copy Server ===
./server.sh

# === Compress Release ===
#echo "📦 Compressing release..."
#cd export

# Clean previous outputs
#rm -rf Client BeamMP-Sumo.zip

# Prepare structure
#mkdir -p Client

# Copy zipped client archive into this Client folder
#cp ../Client/SumoGamemode.zip Client/

# Create final bundle
#zip -r BeamMP-Sumo.zip Client ../Server

#cd ..
echo "✅ All complete, King Julian!"
