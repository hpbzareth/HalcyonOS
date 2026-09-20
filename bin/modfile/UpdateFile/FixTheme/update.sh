work_dir=$(pwd)
MAIN_FOLDER="$work_dir/build/baserom/images"
source $work_dir/functions.sh
device_code=$(cat $work_dir/bin/ddevice/device_f.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)

if [[ $regionTYPE == *"Global"* && $rom_os == "OS2" ]]; then 
  mods "Fixing Icon For HalcyonOS 2.0"
  rm -rf $work_dir/build/baserom/images/product/media/theme
  cp -rf $work_dir/bin/modfile/UpdateFile/FixTheme/HalcyonOS/theme $work_dir/build/baserom/images/product/media/
fi


