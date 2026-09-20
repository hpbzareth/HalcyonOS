work_dir=$(pwd)
MAIN_FOLDER="$work_dir/build/baserom/images/"
bash $work_dir/bin/package/NOTIFICATION_FIX/A15/patchMIUIServices.sh
bash $work_dir/bin/package/NOTIFICATION_FIX/A15/patchMIUIFramework.sh
bash $work_dir/bin/package/NOTIFICATION_FIX/A15/PowerKeeper.sh