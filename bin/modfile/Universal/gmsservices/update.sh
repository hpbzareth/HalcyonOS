work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
MAIN_FOLDER="$work_dir/build/baserom/images"

if [[ $regionTYPE == "China" ]]; then 
  aria2c -q -d "$work_dir/bin/modfile/Universal/gmsservices/product/priv-app/GoogleVelvet_CTS/" -o GoogleVelvet_CTS.apk https://github.com/tiencv2006/nothingsvn_oplus-toolbuild/releases/download/oplus/GoogleVelvet_CTS.apk && info "Get File Successfully"
  cp -rf $work_dir/bin/modfile/Universal/gmsservices/product/* $work_dir/build/baserom/images/product/
  cp -rf $work_dir/bin/modfile/Universal/gmsservices/system_ext/* $work_dir/build/baserom/images/system_ext/
  echo "ro.miui.has_gmscore=1" >> $work_dir/build/baserom/images/system/system/build.prop
  if [[ $androidVER == "13" ]]; then 
    cp -rf $work_dir/bin/modfile/Universal/gmsservices/maps/A13/framework $work_dir/build/baserom/images/product/
  elif [[ $androidVER == "14" ]]; then
    cp -rf $work_dir/bin/modfile/Universal/gmsservices/maps/A14/framework $work_dir/build/baserom/images/product/
  else
    cp -rf $work_dir/bin/modfile/Universal/gmsservices/maps/A15/framework $work_dir/build/baserom/images/product/
  fi
  mods "Added GMS Done"
else
  mods "Detected Xiaomi Global ROM!Skipped Added GMS."
fi
