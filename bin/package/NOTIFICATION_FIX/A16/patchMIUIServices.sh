work_dir=$(pwd)
source $work_dir/functions.sh
repS="python3 $work_dir/bin/strRep.py"
if [[ ! -d $dir/jar_temp ]]; then

	mkdir $dir/jar_temp
	
fi

jar_util() 
{
    cd $work_dir
    #binary
    if [[ $3 == "fw" ]]; then 
        bak="java -jar $work_dir/bin/apktool/baksmaliv2.jar d --api 36"
        sma="java -jar $work_dir/bin/apktool/smaliv2.jar a --api 36"
    fi

    if [[ $1 == "d" ]]; then
        patch "$2"
        if [[ -f $work_dir/build/baserom/images/system_ext/framework/miui-services.jar ]]; then
            sudo cp $work_dir/build/baserom/images/system_ext/framework/miui-services.jar $work_dir/jar_temp
            sudo chown $(whoami) $work_dir/jar_temp/$2
            unzip $work_dir/jar_temp/$2 -d $work_dir/jar_temp/$2.out  >/dev/null 2>&1
            if [[ -d $work_dir/jar_temp/"$2.out" ]]; then
                rm -rf $work_dir/jar_temp/$2
                for dex in $(find $work_dir/jar_temp/"$2.out" -maxdepth 1 -name "*dex" ); do
                    if [[ $4 ]]; then
                        if [[ ! "$dex" == *"$4"* ]]; then
                            $bak $dex -o "$dex.out"
                            [[ -d "$dex.out" ]] && rm -rf $dex
                        fi
                    else
                        $bak $dex -o "$dex.out"
                        [[ -d "$dex.out" ]] && rm -rf $dex        
                    fi
                done
                # Create necessary directories and copy xBuild.smali
                # mkdir -p $work_dir/jar_temp/$2.out/classes.dex.out/miuix/os
                # cp $work_dir/bin/shPlugin/NOTIFICATION_FIX/A13/xBuild.smali $work_dir/jar_temp/$2.out/classes.dex.out/miuix/os/
            fi
        fi
    else 
        if [[ $1 == "a" ]]; then 
            if [[ -d $work_dir/jar_temp/$2.out ]]; then
                cd $work_dir/jar_temp/$2.out
                for fld in $(find -maxdepth 1 -name "*.out" ); do
                    if [[ $4 ]]; then
                        if [[ ! "$fld" == *"$4"* ]]; then
                            $sma $fld -o $(echo ${fld//.out})
                            [[ -f $(echo ${fld//.out}) ]] && rm -rf $fld
                        fi
                    else 
                        $sma $fld -o $(echo ${fld//.out})
                        [[ -f $(echo ${fld//.out}) ]] && rm -rf $fld    
                    fi
                done
                7za a -tzip -mx=0 $work_dir/jar_temp/$2_notal $work_dir/jar_temp/$2.out/. >/dev/null 2>&1
                #zip -r -j -0 $work_dir/jar_temp/$2_notal $work_dir/jar_temp/$2.out/.
                zipalign 4 $work_dir/jar_temp/$2_notal $work_dir/jar_temp/$2
                if [[ -f $work_dir/jar_temp/$2 ]]; then
                    sudo cp -rf $work_dir/jar_temp/$2 $work_dir/build/baserom/images/system_ext/framework/miui-services.jar
                    final_dir="$work_dir/module/*"
                    #7za a -tzip "$work_dir/miui-services_patched_$(date "+%d%m%y").zip" $final_dir
                    patch "Success"
                    rm -rf $work_dir/jar_temp/$2.out $work_dir/jar_temp/$2_notal 
                else
                    patch "Fail"
                fi
            fi
        fi
    fi
}
find_and_replace() {
    local search=$1
    local replace=$2
    local base_dir=$work_dir/jar_temp/miui-services.jar.out
	local files=(
        "ActivityManagerServiceImpl.smali"
        "BroadcastQueueModernStubImpl.smali"
        "MiProcessTracker.smali"
        "MutableActivityManagerShellCommandStubImpl.smali"
        "PreStartFeedbackImpl.smali"
        "ProcessManagerService.smali"
        "ProcessPolicy.smali"
        "ProcessSceneCleaner.smali"
        "AudioServiceStubImpl.smali"
        "ClipboardChecker.smali"
        "ClipboardServiceStubImpl.smali"
        "DevicePolicyManagerServiceStubImpl.smali"
        "InputManagerServiceStubImpl.smali"
        "InputMethodManagerServiceImpl.smali"
        "SogouInputMethodSwitcher.smali"
        "JobServiceContextImpl.smali"
        "GnssEventTrackingImpl.smali"
        "PackageManagerServiceImpl.smali"
        "MiuiShortcutTriggerHelper\$ShortcutSettingsObserver.smali"
        "ActivityTaskSupervisorImpl.smali"
        "MiuiSplitInputMethodImpl.smali"
        "WindowManagerServiceImpl.smali"
        "DeviceIdleControllerStubImpl.smali"
        "ForceDarkAppListManager.smali"
    )

    for file in "${files[@]}"; do
        file_path=$(find "$base_dir" -name "$file")
        if [[ -n $file_path ]]; then
            if grep -q "$search" "$file_path"; then
                sed -i "s|$search|$replace|g" "$file_path"
            fi
        fi
    done
}


miui-services() {
    jar_util d "miui-services.jar" fw
	
	p1=$(find "$work_dir/jar_temp/" -type f -name PolicyManager.smali)

    find_and_replace "Lmiui/os/Build;->IS_INTERNATIONAL_BUILD:Z" "Lmiui/os/Build;->IS_MIUI:Z"
	
	sed -i '/sput-boolean v[0-9]\+, Lcom\/miui\/server\/greeze\/PolicyManager;->CN_MODEL:Z/a\
\n    const/4 v0, 0x0' $p1

    jar_util a "miui-services.jar" 
}

if [[ ! -d $work_dir/jar_temp ]]; then
    mkdir $work_dir/jar_temp
fi

miui-services