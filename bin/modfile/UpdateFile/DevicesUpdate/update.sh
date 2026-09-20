work_dir=$(pwd)
MAIN_FOLDER="$work_dir/build/baserom/images"
source $work_dir/functions.sh
device_code=$(cat $work_dir/bin/ddevice/device_f.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)

if [[ $device_code == "spes" ]]; then
    mods "Add Dolby and Speaker Balance for SPES"
    cp -rf $work_dir/bin/modfile/UpdateFile/DevicesUpdate/spes/sound/mixer_paths.xml $work_dir/build/baserom/images/vendor/etc/mixer_paths.xml
    cp -rf $work_dir/bin/modfile/UpdateFile/DevicesUpdate/spes/sound/dolby/system/app/Atmos $work_dir/build/baserom/images/system/system/app/
    cp -rf $work_dir/bin/modfile/UpdateFile/DevicesUpdate/spes/sound/dolby/system/etc/* $work_dir/build/baserom/images/system/system/etc/
    cp -rf $work_dir/bin/modfile/UpdateFile/DevicesUpdate/spes/sound/dolby/system/vendor/etc/* $work_dir/build/baserom/images/vendor/etc/
    cp -rf $work_dir/bin/modfile/UpdateFile/DevicesUpdate/spes/sound/dolby/system/vendor/lib/* $work_dir/build/baserom/images/vendor/lib/
fi