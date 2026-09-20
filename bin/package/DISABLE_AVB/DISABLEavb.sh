work_dir=$(pwd)
source $work_dir/functions.sh
device_code=$(cat $work_dir/bin/ddevice/device_f.txt)


# Disable AVB For Some Devices
if grep -qw "$device_code" "$work_dir/bin/package/DISABLE_AVB/avb_list.txt"; then
    disable_avb_verify $work_dir/build/baserom/images/vendor >/dev/null 2>&1
	bash $work_dir/bin/package/DISABLE_AVB/HMATools/start
else
    for img in $(find $work_dir/build/baserom/images -type f -name "vbmeta*.img");do
        sudo $work_dir/bin/vbmeta-disable-verification ${img}
        python3 $work_dir/bin/patch-vbmeta.py ${img}
    done
	disable_avb_verify $work_dir/build/baserom/images/vendor >/dev/null 2>&1
fi
