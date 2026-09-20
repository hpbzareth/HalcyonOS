work_dir=$(pwd)
source $work_dir/functions.sh

mods "Starting Apply Universal File..."
TARGET_DIR="$work_dir/bin/modfile/Universal"
noexecute=( "insfile" )

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
