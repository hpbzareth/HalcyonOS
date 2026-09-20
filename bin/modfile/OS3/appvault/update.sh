work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)
MAIN_FOLDER="$work_dir/build/baserom/images"

isSTOCKVault=$(find "$MAIN_FOLDER" -type d \( -name "MIUIGlobalMinusScreenWidget" -o -name "MIUIGlobalMinusScreen" -o -name "MIUIPersonalAssistantT" -o -name "MIUIPersonalAssistant" -o -name "PersonalAssistant" -o -name "MIUIPersonalAssistantPhoneMIUI15" -o -name "MIUIPersonalAssistantPhoneOS2NoBeta" -o -name "MIUIPersonalAssistantPhoneOS2" -o -name "PersonalAssistant" -o -name "MIUIPersonalAssistantPhoneMIUI15" -o -name "MIUIPersonalAssistantPhoneOS2NoBeta" -o -name "MIUIPersonalAssistantPhoneOS3" -o -name "PersonalAssistant" -o -name "MIUIPersonalAssistantPhoneMIUI15" -o -name "MIUIPersonalAssistantPhoneOS2NoBeta" -o -name "MIUIPersonalAssistantOS3" \))
if [[ $androidVER == "16" ]]; then
mods "Update Appvault For OS3"
rm -rf $isSTOCKVault
mkdir -p $work_dir/build/baserom/images/product/priv-app/MIUIPersonalAssistant
cp -rf $work_dir/bin/modfile/OS3/appvault/MIUIPersonalAssistant/* $work_dir/build/baserom/images/product/priv-app/MIUIPersonalAssistant/
cp -rf $work_dir/bin/modfile/OS3/appvault/permissions/privapp_whitelist_com.miui.personalassistant.xml $work_dir/build/baserom/images/product/etc/permissions/
mods "Modify Appvault Done"
fi