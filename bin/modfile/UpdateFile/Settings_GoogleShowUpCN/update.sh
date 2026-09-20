WORK_DIR=$(pwd)
source $WORK_DIR/functions.sh
MAIN_FOLDER="$WORK_DIR/build/baserom/images"
repS="python3 $WORK_DIR/bin/strRep.py"
deviceTYPE=$(cat $WORK_DIR/bin/ddevice/device_type.txt)
APKEDITOR="java -jar $WORK_DIR/bin/apktool/apke.jar"

if [[ $deviceTYPE == "China" ]];then
    mods "Adding Google Option For China ROM"
    #ready for patch
    mkdir -p $WORK_DIR/apk_temp
    isSettingsDIR=$(find "$MAIN_FOLDER" -type d -name "Settings")
    isSettings=$(find "$MAIN_FOLDER" -type f -name "Settings.apk")

    $APKEDITOR d -t raw -f -no-dex-debug -i $isSettings -o $WORK_DIR/apk_temp/isSettings.apk.out >/dev/null 2>&1
    isMiuiSettingsSmali=$(find "$WORK_DIR/apk_temp/isSettings.apk.out" -type f -name MiuiSettings.smali)

    #patching
    sed -i '/sget-boolean v0, Lmiui\/os\/Build;->IS_GLOBAL_BUILD:Z/ a\\n    const/4 v0, 0x1' $isMiuiSettingsSmali

    #Finishing
    Settings=$(basename $isSettings)
    $APKEDITOR b -f -i $WORK_DIR/apk_temp/isSettings.apk.out -o $WORK_DIR/apk_temp/final/$Settings >/dev/null 2>&1

    if [ -f "$WORK_DIR/apk_temp/final/$Settings" ]; then
        rm -rf $isSettingsDIR/*
        cp -rf $WORK_DIR/apk_temp/final/$Settings $isSettingsDIR
    fi

    rm -rf $WORK_DIR/apk_temp
	mods "Done"
else
    mods "Region not support to patch"
fi