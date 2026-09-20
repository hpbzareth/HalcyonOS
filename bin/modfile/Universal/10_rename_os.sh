#!/bin/bash
work_dir=$(pwd)

mods "Renaming HalcyonOS to HalcyonOS in system properties..."
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i 's/HalcyonOS/HalcyonOS/g' {} +
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i 's/MIUI/HalcyonOS/g' {} +
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i 's/HalcyonOS/HalcyonOS/g' {} +
mods "Renaming complete!"

