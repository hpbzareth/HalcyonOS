#!/bin/bash
work_dir=$(pwd)
source $work_dir/functions.sh

FILE_JSON="$work_dir/bin/ddevice/data/devices.json"
KEY="${1:-$(cat $work_dir/bin/ddevice/device_f.txt)}"

# Find the exact key with correct capitalization from the reference lists
EXACT_KEY=$(grep -ix "$KEY" "$work_dir/bin/ddevice/data/devices_data.txt" 2>/dev/null || grep -ix "$KEY" "$work_dir/bin/ddevice/data/pad_data.txt" 2>/dev/null)

if [ -z "$EXACT_KEY" ]; then
  # Fallback to key itself if not matched in the lists
  EXACT_KEY="$KEY"
fi

VALUE=$(jq -r --arg key "$EXACT_KEY" '.[$key] // "Không tìm thấy key"' "$FILE_JSON")
echo "$VALUE" > $work_dir/bin/ddevice/name_devices.txt