baserom="$1"
work_dir=$(pwd)
source $work_dir/functions.sh

regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
AndroidVer=$(< $work_dir/build/baserom/images/system/system/build.prop grep "ro.system.build.version.release" |awk 'NR==1' |cut -d '=' -f 2)
sdkLevel=$(< $work_dir/build/baserom/images/system/system/build.prop grep "ro.system.build.version.sdk" |awk 'NR==1' |cut -d '=' -f 2)
device_code=$(cat $work_dir/bin/ddevice/device_code.txt)
name=$(cat $work_dir/bin/ddevice/name_devices.txt)
base_rom_code=$(cat $work_dir/bin/ddevice/base_rom_code.txt)
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
starxVER=$(cat $work_dir/Version)
systemtype=$(cat $work_dir/bin/ddevice/fstype.txt)

if grep -q "ro.build.ab_update=true" build/baserom/images/vendor/build.prop; then
echo "VAB" > $work_dir/bin/script2flash/META-INF/Data/Structure
else
echo "Non-VAB" > $work_dir/bin/script2flash/META-INF/Data/Structure
fi

if [ -f $work_dir/build/baserom/images/vendor/etc/init/hw/init.qcom.rc ]; then
   echo "Snapdragon" > $work_dir/bin/script2flash/META-INF/Data/Chip
else
   echo "Mediatek" > $work_dir/bin/script2flash/META-INF/Data/Chip
fi 

echo "$os_type" > $work_dir/bin/ddevice/os_type.txt
echo "$AndroidVer" > $work_dir/bin/ddevice/androidver.txt
echo "$sdkLevel" > $work_dir/bin/ddevice/sdkLevel.txt
#Parse Data
echo "$AndroidVer" > $work_dir/bin/script2flash/META-INF/Data/AndroidVer
echo "$base_rom_code" > $work_dir/bin/script2flash/META-INF/Data/RomBased
echo "$starxVER" > $work_dir/bin/script2flash/META-INF/Data/Version
echo "$regionTYPE" > $work_dir/bin/script2flash/META-INF/Data/Region
echo "$name" > $work_dir/bin/script2flash/META-INF/Data/DeviceName
echo "$systemtype" > $work_dir/bin/script2flash/META-INF/Data/Types


echo "------------------Nothings BuildInfo ---------------------"
echo "- Device Name:"$name""
echo "- Codename:"$device_code""
echo "- Xiaomi Version:"$rom_os""  
echo "- BuildRegion:"$regionTYPE""
echo "- Android:"$AndroidVer""                                      
echo "- Xiaomi Version:"$base_rom_code""                                                                        
echo "- BuildTool Version:"$starxVER""
echo "- OS Type:"$systemtype""
echo "--------------------------------------------------------"