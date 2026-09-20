work_dir=$(pwd)
source $work_dir/functions.sh
sdkLevel=$(cat $work_dir/bin/ddevice/sdkLevel.txt)
deviceTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
tar1="$work_dir/bin/modfile/UpdateFile/Framework_FixDevicePolicy/enforceVersionPolicy.ini"
repS="python3 $work_dir/bin/strRep.py"
jar_util() 
{
    cd $work_dir
    #binary
    if [[ $3 == "fw" ]]; then 
        bak="java -jar $work_dir/bin/apktool/baksmaliv2.jar d --api $sdkLevel"
        sma="java -jar $work_dir/bin/apktool/smaliv2.jar a --api $sdkLevel"
    fi

    if [[ $1 == "d" ]]; then
        patch "Patching $2 : "
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

miui-services() {
    jar_util d "miui-services.jar" fw

    p1=$(find "$work_dir/jar_temp/miui-services.jar.out" -type f -name SystemServerImpl.smali)

    $repS $tar1 $p1

    jar_util a "miui-services.jar" 
}

if [[ ! -d $work_dir/jar_temp ]]; then
    mkdir $work_dir/jar_temp
fi

patch "Bypass Devices Policy Check..."
miui-services

