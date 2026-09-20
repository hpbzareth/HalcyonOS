work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
MAIN_FOLDER="$work_dir/build/baserom/images"

isOriginThemeMng=$(find "$MAIN_FOLDER" -type d \( -name "MIUIThemeManager" -o -name "MIUIThemeManagerT" -o -name "MIUIThemeManagerGlobal" -o -name "ThemeManager" \))

if [[ $rom_os == "OS3" ]] ;then
  rm -rf $isOriginThemeMng
  mkdir -p $work_dir/build/baserom/images/product/priv-app/MIUIThemeManager
  cp -rf $work_dir/bin/modfile/OS3/thememanager/MIUIThemeManager/* $work_dir/build/baserom/images/product/priv-app/MIUIThemeManager
  cp -rf $work_dir/bin/modfile/OS3/thememanager/permissions/privapp_whitelist_com.android.thememanager.xml $work_dir/build/baserom/images/product/etc/permissions/
  mods "Modify ThemeManager Done"
fi