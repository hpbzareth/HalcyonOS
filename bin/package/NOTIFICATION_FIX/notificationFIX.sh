WORK_DIR=$(pwd)
source $WORK_DIR/functions.sh
AndroidVER=$(cat $WORK_DIR/bin/ddevice/androidver.txt)
regionTYPE=$(cat $WORK_DIR/bin/ddevice/device_type.txt)

if [[ $regionTYPE == *"Global"* ]]; then
warn "No Support Global ROM!Skipping..."
else
patch "Start Notification FIX..."
if [[ $AndroidVER == "13" ]];then
    bash $WORK_DIR/bin/package/NOTIFICATION_FIX/A13/RUN.SH
elif [[ $AndroidVER == "14" ]];then
    bash $WORK_DIR/bin/package/NOTIFICATION_FIX/A14/RUN.SH
elif [[ $AndroidVER == "15" ]];then
    bash $WORK_DIR/bin/package/NOTIFICATION_FIX/A15/RUN.SH
elif [[ $AndroidVER == "16" ]];then
    bash $WORK_DIR/bin/package/NOTIFICATION_FIX/A16/RUN.SH
fi

fi