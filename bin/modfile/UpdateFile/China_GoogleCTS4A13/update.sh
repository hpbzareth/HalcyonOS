work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $WORK_DIR/bin/ddevice/rom_os.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
androidVER=$(cat $WORK_DIR/bin/ddevice/androidver.txt)
MAIN_FOLDER="$work_dir/build/baserom/images"

if [[ $regionTYPE == "China" && $androidVER == "13" ]]; then
  mods "Adding CTS For Android 13 China"
  cp -rf $work_dir/bin/modfile/UpdateFile/China_GoogleCTS4A13/CircleToSearchOverlay.apk $work_dir/build/baserom/images/product/overlay/
  cp -rf $work_dir/bin/modfile/UpdateFile/China_GoogleCTS4A13/Gemini $work_dir/build/baserom/images/product/priv-app/
  cp -rf $work_dir/bin/modfile/UpdateFile/China_GoogleCTS4A13/GoogleCTS $work_dir/build/baserom/images/product/app
fi