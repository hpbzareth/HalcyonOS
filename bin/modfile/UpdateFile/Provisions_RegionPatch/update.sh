work_dir=$(pwd)
source $work_dir/functions.sh
MAIN_FOLDER="$work_dir/build/baserom/images"
repS="python3 $work_dir/bin/strRep.py"
deviceTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
APKEDITOR="java -jar $work_dir/bin/apktool/apke.jar"
repS="python3 $work_dir/bin/strRep.py"

if [[ $rom_os == "OS3" || $rom_os == "OS2" || $rom_os == "OS1" ]]; then
mods "Remove Region Check for HalcyonOS"
#ready for patch
mkdir -p $work_dir/apk_temp
isProvisionDIR=$(find "$MAIN_FOLDER" -type d -name "Provision")
isProvision=$(find "$MAIN_FOLDER" -type f -name "Provision.apk")
$APKEDITOR d -t raw -f -no-dex-debug -i $isProvision -o $work_dir/apk_temp/isProvision.apk.out >/dev/null 2>&1
isMiuiProvisionSmali=$(find "$work_dir/apk_temp/isProvision.apk.out" -type f -name Utils.smali)
tar1="$work_dir/bin/modfile/UpdateFile/Provisions_RegionPatch/remove_regioncheck.ini"

$repS $tar1 $isMiuiProvisionSmali >/dev/null 2>&1

#Finishing
Provision=$(basename $isProvision)
$APKEDITOR b -f -i $work_dir/apk_temp/isProvision.apk.out -o $work_dir/apk_temp/final/$Provision >/dev/null 2>&1

if [ -f "$work_dir/apk_temp/final/$Provision" ]; then
    rm -rf $isProvisionDIR/*
    cp -rf $work_dir/apk_temp/final/$Provision $isProvisionDIR
fi

rm -rf $work_dir/apk_temp
mods "Done"
fi
