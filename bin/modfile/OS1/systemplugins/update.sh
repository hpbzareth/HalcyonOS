WORK_DIR=$(pwd)
MAIN_FOLDER="$WORK_DIR/build/baserom/images"
rom_os=$(cat $WORK_DIR/bin/ddevice/rom_os.txt)
androidVER=$(cat $WORK_DIR/bin/ddevice/androidver.txt)

MIUISystemUIPluginDIR=$(find "$MAIN_FOLDER" -type d -name "MIUISystemUIPlugin")


if [[ $rom_os == "OS1" ]];then
    rm -rf $MIUISystemUIPluginDIR/*.apk
    cp -rf $WORK_DIR/bin/modfile/OS1/systemplugins/MIUISystemUIPlugin.apk $MIUISystemUIPluginDIR
fi