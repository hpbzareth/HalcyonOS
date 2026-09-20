work_dir=$(pwd)
source $work_dir/functions.sh
repS="python3 $work_dir/bin/strRep.py"
sdkLevel=$(cat $work_dir/build/baserom/images/system/system/build.prop |grep "ro.build.version.sdk" |cut -d "=" -f 2 |awk 'NR==1')
jar_util() 
{
    cd $work_dir
    #binary
    if [[ $3 == "fw" ]]; then 
        bak="java -jar $work_dir/bin/apktool/baksmaliv2.jar d --api $sdkLevel"
        sma="java -jar $work_dir/bin/apktool/smaliv2.jar a --api $sdkLevel"
    fi

    if [[ $1 == "d" ]]; then
        patch -ne "$2"
        if [[ -f $work_dir/build/baserom/images/system_ext/framework/miui-framework.jar ]]; then
            sudo cp $work_dir/build/baserom/images/system_ext/framework/miui-framework.jar $work_dir/jar_temp
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
                    sudo cp -rf $work_dir/jar_temp/$2 $work_dir/build/baserom/images/system_ext/framework/miui-framework.jar
                    final_dir="$work_dir/module/*"
                    #7za a -tzip "$work_dir/miui-services_patched_$(date "+%d%m%y").zip" $final_dir
                    patch "$2 Success"
                    rm -rf $work_dir/jar_temp/$2.out $work_dir/jar_temp/$2_notal 
                else
                    patch "$2 Fail"
                fi
            fi
        fi
    fi
}

find_and_replace() {
    local search=$1
    local replace=$2
    local base_dir=$work_dir/jar_temp/miui-framework.jar.out
    local files=(
        "ApplicationPackageManagerInjector.smali"
        "AppOpsManagerInjector.smali"
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

find_and_replace_build_file() {
    local search=$1
    local replace=$2
    local base_dir=$work_dir/jar_temp/miui-framework.jar.out
    local file="Build.smali"

    file_path=$(find "$base_dir" -name "$file")
    if [[ -n $file_path ]]; then
        if grep -q "$search" "$file_path"; then
            sed -i "s|$search|$replace|g" "$file_path"
        fi
    fi
}


miui-framework() {
    jar_util d "miui-framework.jar" fw

    search="Lmiui/os/Build;->IS_INTERNATIONAL_BUILD"
    replace="Lmiui/os/Build;->IS_MIUI"
    
    find_and_replace "$search" "$replace"

    jar_util a "miui-framework.jar" 
}

if [[ ! -d $work_dir/jar_temp ]]; then
    mkdir $work_dir/jar_temp
fi

miui-framework