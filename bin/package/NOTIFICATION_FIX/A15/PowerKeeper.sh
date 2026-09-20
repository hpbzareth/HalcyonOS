work_dir=$(pwd)
source $work_dir/functions.sh
MAIN_FOLDER="$work_dir/build/baserom/images"
repS="python3 $work_dir/bin/strRep.py"
deviceTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
APKEDITOR="java -jar $work_dir/bin/apktool/apke.jar"
repS="python3 $work_dir/bin/strRep.py"


patch "Patching PowerKeeper"
#ready for patch
mkdir -p $work_dir/apk_temp
isPowerKeeperDIR=$(find "$MAIN_FOLDER" -type d -name "PowerKeeper")
isPowerKeeper=$(find "$MAIN_FOLDER" -type f -name "PowerKeeper.apk")
$APKEDITOR d -t raw -f -no-dex-debug -i $isPowerKeeper -o $work_dir/apk_temp/isPowerKeeper.apk.out >/dev/null 2>&1
Smali1=$(find "$work_dir/apk_temp/isPowerKeeper.apk.out" -type f -name MilletConfig.smali)
Smali2=$(find "$work_dir/apk_temp/isPowerKeeper.apk.out" -type f -name GmsObserver.smali)
tar1="$work_dir/bin/package/NOTIFICATION_FIX/A15/patch/gms.ini"

sed -i 's/Lmiui\/os\/Build;->IS_INTERNATIONAL_BUILD:Z/Lmiui\/os\/Build;->IS_MIUI:Z/g' $Smali1

$repS $tar1 $Smali2

#Finishing
PowerKeeper=$(basename $isPowerKeeper)
$APKEDITOR b -f -i $work_dir/apk_temp/isPowerKeeper.apk.out -o $work_dir/apk_temp/final/$PowerKeeper >/dev/null 2>&1

if [ -f "$work_dir/apk_temp/final/$PowerKeeper" ]; then
    rm -rf $isPowerKeeperDIR/*
    cp -rf $work_dir/apk_temp/final/$PowerKeeper $isPowerKeeperDIR
fi

rm -rf $work_dir/apk_temp
patch "Done"