WORK_DIR=$(pwd)
source $WORK_DIR/functions.sh

debloat_apps=()
while IFS= read -r line || [[ -n "$line" ]]; do
    debloat_apps+=("$line")
done < $WORK_DIR/bin/ddevice/DEBLOAT/APPLIST.txt

rm -rf $WORK_DIR/build/baserom/images/product/etc/auto-install*
rm -rf $WORK_DIR/build/baserom/images/product/app/Updater
rm -rf $WORK_DIR/build/baserom/images/product/etc/permissions/cn.google.services.xml
for debloat_app in "${debloat_apps[@]}"; do
    # Find the app directory in both system and product directories
    app_dirs=$(find build/baserom/images/system/ -type d -name "*$debloat_app*" 2>/dev/null)
    app_dirs2=$(find build/baserom/images/product/ -type d -name "*$debloat_app*" 2>/dev/null)
    app_dirs3=$(find build/baserom/images/mi_ext -type d -name "*$debloat_app*" 2>/dev/null)
    # Combine the directories into one list
    all_app_dirs=($app_dirs $app_dirs2 $app_dirs3)

    for app_dir in "${all_app_dirs[@]}"; do
        # Check if the directory exists before removing
        if [[ -d "$app_dir" ]]; then
            info "Removing directory: $app_dir"
            rm -rf "$app_dir"
        fi
    done
done
info "Debloat Done"

