work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)
MAIN_FOLDER="$work_dir/build/baserom/images"

Weather=$(find "$MAIN_FOLDER" -type d \( -name "MIUIWeather" -o -name "MiuiWeather" -o -name "Weather" \))
if [[ $regionTYPE == "China" ]]; then
  rm -rf $Weather
  mkdir -p $work_dir/build/baserom/images/product/priv-app/MIUIWeather
  cp -rf $work_dir/bin/modfile/OS3/weather/MIUIWeather/* $work_dir/build/baserom/images/product/priv-app/MIUIWeather
  cp -rf $work_dir/bin/modfile/OS3/weather/permissions/privapp-permissions-zos.xml $work_dir/build/baserom/images/product/etc/permissions/
  mods "Added MIUIWeather Done!"
fi