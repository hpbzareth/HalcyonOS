work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
androidVER=$(cat $work_dir/bin/ddevice/androidver.txt)
BuildProp1="$work_dir/build/baserom/images/system/system/build.prop"
BuildProp2="$work_dir/build/baserom/images/product/etc/build.prop"
BuildProp3="$work_dir/build/baserom/images/system_ext/etc/build.prop"
BuildProp4="$work_dir/build/baserom/images/vendor/build.prop"

remove_poco_launcher () {
    mods "Disable MiGlobalLauncher"
    BuildProp1="$work_dir/build/baserom/images/system/system/build.prop"
	BuildProp2="$work_dir/build/baserom/images/product/etc/build.prop"
	BuildProp3="$work_dir/build/baserom/images/system_ext/etc/build.prop"
	BuildProp4="$work_dir/build/baserom/images/vendor/build.prop"
	sed -i "s/ro.miui.product.home=com.mi.android.globallauncher/ro.miui.product.home=com.miui.home/g" $BuildProp1
	sed -i "s/ro.miui.product.home=com.mi.android.globallauncher/ro.miui.product.home=com.miui.home/g" $BuildProp2
	sed -i "s/ro.miui.product.home=com.mi.android.globallauncher/ro.miui.product.home=com.miui.home/g" $BuildProp3
    sed -i "s/ro.miui.product.home=com.mi.android.globallauncher/ro.miui.product.home=com.miui.home/g" $BuildProp4
} 

if [[ $regionTYPE == *"Global"* ]]; then
    mods "Convert POCO2MIUI"
    if [ -f build/baserom/images/system_ext/etc/init/init.miui.ext.rc ];then
        sed -i 's/    setprop ro.miui.product.home "com.mi.android.globallauncher"\+/    setprop ro.miui.product.home "com.miui.home"/' $work_dir/build/baserom/images/system_ext/etc/init/init.miui.ext.rc
    fi && mods "Done"
    remove_poco_launcher
fi