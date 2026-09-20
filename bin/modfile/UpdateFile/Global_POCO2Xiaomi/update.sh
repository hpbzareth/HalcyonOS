work_dir=$(pwd) 
source $work_dir/functions.sh
product="$work_dir/build/baserom/images/product"
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)

if [[ $regionTYPE == *"Global"* ]]; then
    mods "Disable POCO Theme"
    rm -rf "$product/media/theme"
    cp -rf "$work_dir/bin/modfile/UpdateFile/Global_POCO2Xiaomi/theme" "$product/media"
    mods "Done"
fi