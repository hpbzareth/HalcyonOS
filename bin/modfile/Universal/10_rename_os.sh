#!/bin/bash
work_dir=$(pwd)

mods "Renaming OS references to HalcyonOS in system properties..."
# Replace HyperOS branding (from Xiaomi HyperOS ROMs)
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i 's/Xiaomi HyperOS/HalcyonOS/g' {} +
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i 's/HyperOS/HalcyonOS/g' {} +
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i 's/hyperos/halcyonos/g' {} +
# Replace MIUI branding
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i 's/MIUI/HalcyonOS/g' {} +
mods "Renaming complete!"

