WORK_DIR=$(pwd)
source $WORK_DIR/functions.sh
MAIN_FOLDER="$WORK_DIR/build/baserom/images"
rom_os=$(cat $WORK_DIR/bin/ddevice/rom_os.txt)
regionTYPE=$(cat $WORK_DIR/bin/ddevice/device_type.txt)
AndroidVER=$(cat $WORK_DIR/bin/ddevice/androidver.txt)
APKEDITOR="java -jar $WORK_DIR/bin/apktool/apke.jar"
repS="python3 $WORK_DIR/bin/strRep.py"

#Add Settings Lab To Settings
mods "Fixing Notification History"
mkdir -p $WORK_DIR/apk_temp
isSettingsDIR=$(find "$MAIN_FOLDER" -type d -name "Settings")
isSettings=$(find "$MAIN_FOLDER" -type f -name "Settings.apk")
$APKEDITOR d -i $isSettings -o $WORK_DIR/apk_temp/isSettings.apk.out >/dev/null 2>&1
p1=$(find "$WORK_DIR/apk_temp/isSettings.apk.out" -type f -name notification_history.xml)
res="$WORK_DIR/apk_temp/isSettings.apk.out/resources/package_1/res"

#patching
mods "Starting..."
sed -i -e 's/?android:attr\/colorBackgroundFloating/@drawable\/card_view_corner/g'        -e 's/rounded_bg/device_card_back_ground/g' $p1
mods "Stage 1 Done"

#Finishing
mods "Rebuild..."
Settings=$(basename $isSettings)
$APKEDITOR b -f -i $WORK_DIR/apk_temp/isSettings.apk.out -o $WORK_DIR/apk_temp/final/$Settings >/dev/null 2>&1

if [ -f "$WORK_DIR/apk_temp/final/$Settings" ]; then
  mods "Cleaning WorkSpace"
  rm -rf $isSettingsDIR/*
  mods "Finish Modding"
  cp -rf $WORK_DIR/apk_temp/final/$Settings $isSettingsDIR
  mods "Cleaned!"
  
fi

rm -rf $WORK_DIR/apk_temp
mods "Done"