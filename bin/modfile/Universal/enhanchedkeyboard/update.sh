work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
MAIN_FOLDER="$work_dir/build/baserom/images"
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt) 
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)

applykeyboard=$(find "$MAIN_FOLDER" -type d \( -name "MIUIFrequentPhrase" -o -name "MIUIFrequentPhraseT" \))

if [[ $regionTYPE == "China" ]]; then
rm -rf $applykeyboard
mkdir -p $work_dir/build/baserom/images/product/app/MIUIFrequentPhrase
cp -rf $work_dir/bin/modfile/Universal/enhanchedkeyboard/MIUIFrequentPhrase.apk $work_dir/build/baserom/images/product/app/MIUIFrequentPhrase
mods "Added EnhancedKeyboard Done"
fi

