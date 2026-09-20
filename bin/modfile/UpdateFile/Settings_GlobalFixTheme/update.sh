WORK_DIR=$(pwd)
source $WORK_DIR/functions.sh
MAIN_FOLDER="$WORK_DIR/build/baserom/images"
androidVER=$(cat $WORK_DIR/bin/ddevice/androidver.txt)
APKEDITOR="java -jar $WORK_DIR/bin/apktool/apke.jar"
regionTYPE=$(cat $WORK_DIR/bin/ddevice/device_type.txt)

if [[ $androidVER == "16" || $androidVER == "15" || $androidVER == "14" || $androidVER == "13" && $regionTYPE == *"Global"* ]];then
    #ready for patch
	mods "Fixing Theme Issues"
    mkdir -p $WORK_DIR/apk_temp
    isSettingsDIR=$(find "$MAIN_FOLDER" -type d -name "Settings")
    isSettings=$(find "$MAIN_FOLDER" -type f -name "Settings.apk")

    $APKEDITOR d -t raw -f -no-dex-debug -i $isSettings -o $WORK_DIR/apk_temp/isSettings.apk.out >/dev/null 2>&1
    isMiuiSettingsSmali=$(find "$WORK_DIR/apk_temp/isSettings.apk.out" -type f -name MiuiSettings.smali)

    #patching
    sed -i '
    /sget v10, Lcom\/android\/settings\/R$id;->personalize_title:I/,/sget-boolean v10, Lmiui\/os\/Build;->IS_INTERNATIONAL_BUILD:Z/ {
        /sget-boolean v10, Lmiui\/os\/Build;->IS_INTERNATIONAL_BUILD:Z/c\    const/4 v10, 0
    }
    ' $isMiuiSettingsSmali

    sed -i '
    /sget v10, Lcom\/android\/settings\/R$id;->theme_settings:I/,/sget-boolean v10, Lmiui\/os\/Build;->IS_INTERNATIONAL_BUILD:Z/ {
        /sget-boolean v10, Lmiui\/os\/Build;->IS_INTERNATIONAL_BUILD:Z/c\    const/4 v10, 0
    }
    ' $isMiuiSettingsSmali

    sed -i '
    /sget v10, Lcom\/android\/settings\/R$id;->wallpaper_settings:I/,/sget-boolean v10, Lmiui\/os\/Build;->IS_INTERNATIONAL_BUILD:Z/ {
        /sget-boolean v10, Lmiui\/os\/Build;->IS_INTERNATIONAL_BUILD:Z/c\    const/4 v10, 0
    }
    ' $isMiuiSettingsSmali


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
    mods "This Android version is not supported"
fi