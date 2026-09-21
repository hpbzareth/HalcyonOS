#!/bin/bash
work_dir=$(pwd)

mods "Renaming OS display name to HalcyonOS in system properties..."

# Only target known safe display/brand props — do NOT do a blanket replace
# These are the props that show the OS name to the user in Settings/About
PROP_FILES=(
    "$work_dir/build/baserom/images/system/system/build.prop"
    "$work_dir/build/baserom/images/system/system/product/etc/build.prop"
    "$work_dir/build/baserom/images/product/etc/build.prop"
    "$work_dir/build/baserom/images/vendor/build.prop"
    "$work_dir/build/baserom/images/odm/etc/build.prop"
)

for prop in "${PROP_FILES[@]}"; do
    [ -f "$prop" ] || continue
    # Xiaomi HyperOS full string first (most specific)
    sed -i 's/Xiaomi HyperOS/HalcyonOS/g' "$prop"
    # Remaining standalone HyperOS (display values only, e.g. ro.mi.os.version.name)
    sed -i 's/\(ro\.mi\.os\.version\.name=\)HyperOS/\1HalcyonOS/g' "$prop"
    sed -i 's/\(ro\.build\.display\.id=.*\)HyperOS/\1HalcyonOS/g' "$prop"
    sed -i 's/\(ro\.product\.brand_display=\).*$/\1HalcyonOS/g' "$prop"
    sed -i 's/\(ro\.product\.system\.brand_display=\).*$/\1HalcyonOS/g' "$prop"
done

mods "Renaming complete!"
