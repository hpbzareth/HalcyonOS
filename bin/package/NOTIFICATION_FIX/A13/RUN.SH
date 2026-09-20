work_dir=$(pwd)
MAIN_FOLDER="$work_dir/build/baserom/images/"
bash $work_dir/bin/package/NOTIFICATION_FIX/A13/patchMIUIFramework.sh
bash $work_dir/bin/package/NOTIFICATION_FIX/A13/patchMIUIServices.sh
bash $work_dir/bin/package/NOTIFICATION_FIX/A13/PowerKeeper.sh