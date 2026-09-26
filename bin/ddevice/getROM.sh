#!/bin/bash

baserom="$1"
work_dir=$(pwd)
source $work_dir/functions.sh

# Check whether it is a local package or a link
if [ ! -f "${baserom}" ] && [ "$(echo $baserom |grep http)" != "" ]; then
    info "Download link detected, starting a download..."
    aria2c --max-download-limit=1024M --file-allocation=none -s10 -x10 -j10 --content-disposition -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" "${baserom}"
    # Strip query string to get the clean filename
    baserom=$(basename ${baserom} | cut -d'?' -f1)
    # If the clean basename doesn't exist, scan for any newly downloaded zip
    if [ ! -f "$work_dir/${baserom}" ]; then
        downloaded=$(find "$work_dir" -maxdepth 1 -name "*.zip" -newer "$work_dir/functions.sh" 2>/dev/null | head -n1)
        if [ -n "$downloaded" ]; then
            baserom=$(basename "$downloaded")
            info "Detected downloaded file: ${baserom}"
        else
            error "Download error! No zip file found after download."
            return 1
        fi
    fi
elif [ -f "${baserom}" ]; then
    info "BASEROM: ${baserom}"
else
    error "BASEROM: Invalid parameter"
    return 1
fi


# Get ROM Info
if [ "$(echo $baserom |grep miui_)" != "" ]; then
    device_code=$(basename $baserom |cut -d '_' -f 2)
    base_rom_code=$(echo "$baserom" | awk -F'_' '{print $3}')
elif [ "$(echo $baserom |grep xiaomi.eu_)" != "" ]; then
    device_code=$(basename $baserom | cut -d '_' -f 2)
    base_rom_code=$(echo "$baserom" | awk -F'_' '{print $3}')
elif [ "$(echo $baserom | grep -E '.*-ota_full-.*')" != "" ]; then
    device_code=$(basename $baserom | cut -d '-' -f 1)
    base_rom_code=$(basename $baserom | cut -d '-' -f 3)

    # Transform device_code
    device_code=$(echo $device_code | awk -F '_' '{
        if (NF == 1) {
            print toupper($1)
        } else if (NF == 2) {
            print toupper($1) toupper(substr($2, 1, 1)) substr($2, 2)
        } else if (NF == 3) {
            printf toupper($1) toupper($2) toupper(substr($3, 1, 1)) substr($3, 2)
        }
    }')
else
    device_code="YourDevice"
    base_rom_code="Unknown"
fi

device_f=$(echo $device_code | sed 's/\(Global\|EEAGlobal\|INGlobal\|IDGlobal\|RUGlobal\|TWGlobal\|TRGlobal\|JPGlobal\)$//' | tr '[:upper:]' '[:lower:]')

# Determine Device Type
info "Get Device Type"
if echo "$device_code" | grep -q 'EEAGlobal'; then
    DEVICE_TYPE="EEAGlobal"
elif echo "$device_code" | grep -q 'INGlobal'; then
    DEVICE_TYPE="INGlobal"
elif echo "$device_code" | grep -q 'IDGlobal'; then
    DEVICE_TYPE="IDGlobal"
elif echo "$device_code" | grep -q 'RUGlobal'; then
    DEVICE_TYPE="RUGlobal"
elif echo "$device_code" | grep -q 'JPGlobal'; then
    DEVICE_TYPE="JPGlobal"
elif echo "$device_code" | grep -q 'Global'; then
    DEVICE_TYPE="Global"
elif echo "$device_code" | grep -q 'TWGlobal'; then
    DEVICE_TYPE="TWGlobal"
elif echo "$device_code" | grep -q 'TRGlobal'; then
    DEVICE_TYPE="TRGlobal"
else
    DEVICE_TYPE="China"
fi

# Check OS version from base_rom_code
if echo "$base_rom_code" | grep -q "OS1"; then
    ROM_OS="OS1"
elif echo "$base_rom_code" | grep -q "OS2"; then
    ROM_OS="OS2"
elif echo "$base_rom_code" | grep -q "OS3"; then
    ROM_OS="OS3"
elif echo "$base_rom_code" | grep -q "V14"; then
    ROM_OS="MIUI"
elif echo "$base_rom_code" | grep -q "V13"; then
    ROM_OS="MIUI"
else
    echo "Unsupport ROM Exiting..."
    return 1
fi

echo $base_rom_code > $work_dir/bin/ddevice/base_rom_code.txt
echo $base_rom_code > $work_dir/bin/ddevice/os_code.txt
echo $device_code > $work_dir/bin/ddevice/device_code.txt
echo $DEVICE_TYPE > $work_dir/bin/ddevice/device_type.txt
echo $ROM_OS > $work_dir/bin/ddevice/rom_os.txt
echo $device_f > $work_dir/bin/ddevice/device_f.txt
