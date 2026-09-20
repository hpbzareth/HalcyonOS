work_dir=$(pwd)
MAIN_FOLDER="$work_dir/build/baserom/images"
source $work_dir/functions.sh
deviceTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)

if [[ $deviceTYPE == "China" ]];then
mods "Adding MultiLanguage To ROM..."
cp -rf $work_dir/bin/modfile/UpdateFile/MultiLang/updatesource/* $work_dir/build/baserom/images/product/overlay/
mods "Done!"
fi