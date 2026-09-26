#!/bin/bash
work_dir=$(pwd)

mods "Stamping HalcyonOS branding into system properties..."

# Only overwrite specific known display props — safe and surgical approach
# Do NOT do blanket s/HyperOS/HalcyonOS/g — that breaks boot on some devices

VERSION="$(cat $work_dir/Version)"

find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i "s/^ro.build.display.id=.*/ro.build.display.id=HalcyonOS ${VERSION}/g" {} +
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i "s/^ro.mi.os.version.name=.*/ro.mi.os.version.name=HalcyonOS ${VERSION}/g" {} +
find "$work_dir/build/baserom/images/" -type f -name "*.prop" -exec sed -i "s/^ro.mi.os.version.incremental=.*/ro.mi.os.version.incremental=HalcyonOS ${VERSION}/g" {} +

mods "Branding complete!"
