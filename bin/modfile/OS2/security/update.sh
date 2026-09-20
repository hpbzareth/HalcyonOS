work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
deviceTYPE=$(cat $WORK_DIR/bin/ddevice/device_type.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
MAIN_FOLDER="$work_dir/build/baserom/images"
isOriginSECU=$(find "$MAIN_FOLDER" -type d \( -name "MIUISecurityCenter" -o -name "MIUISecurityCenterT" -o -name "MIUISecurityCenterGlobal" -o -name "SecurityCenter" \))


if [[ $rom_os == "OS2" ]]; then
  rm -rf $isOriginSECU
  mkdir -p $work_dir/build/baserom/images/product/priv-app/MIUISecurityCenter
  cp -rf $work_dir/bin/modfile/OS2/security/permissions/privapp_whitelist_com.miui.securitycenter.xml $work_dir/build/baserom/images/product/etc/permissions/
  cp -rf $work_dir/bin/modfile/OS2/security/MIUISecurityCenter/* $work_dir/build/baserom/images/product/priv-app/MIUISecurityCenter
  mods "Modify Secu Done"
fi

