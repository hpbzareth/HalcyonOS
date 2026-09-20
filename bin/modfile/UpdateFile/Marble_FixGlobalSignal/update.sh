work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $WORK_DIR/bin/ddevice/rom_os.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
androidVER=$(cat $WORK_DIR/bin/ddevice/androidver.txt)
device_code=$(cat $work_dir/bin/ddevice/device_f.txt)
BuildProp="$work_dir/build/baserom/images/vendor/build.prop"

#Fix Global Signal For Marble
if [[ $device_code == "marble" && $regionTYPE == *"Global"* ]]; then
    mods "Fixing Signal For Marble Global"
    sed -i "s/persist.vendor.radio.dynamic_sar=1/persist.vendor.radio.dynamic_sar=0/g" $BuildProp
fi