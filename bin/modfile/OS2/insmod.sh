work_dir=$(pwd)
source $work_dir/functions.sh
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)

if [[ $rom_os == "OS2" ]]; then
mods "Starting Apply OS2 Custom Mods File..."
TARGET_DIR="$work_dir/bin/modfile/OS2"
noexecute=( "insmod" )

find "$TARGET_DIR" -type f -name "*.sh" | while read -r script; do
    base="$(basename "$script" .sh)"

    skip=false
    for ex in "${noexecute[@]}"; do
        if [[ "$base" == "$ex" ]]; then
            skip=true
            break
        fi
    done

    if [[ $skip == false ]]; then
        bash "$script"
    fi
done
fi