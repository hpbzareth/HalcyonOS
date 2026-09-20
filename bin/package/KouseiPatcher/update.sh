#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

work_dir=$(pwd)
source $work_dir/functions.sh
prop="$work_dir/bin/package/KouseiPatcher/prop"
appdir="$work_dir/bin/package/KouseiPatcher/app"
kaoriospatch=$(grep "install_toolbox" $work_dir/config.env | cut -d '=' -f 2)

if [[ $kaoriospatch == "true" ]]; then
bash $work_dir/bin/package/KouseiPatcher/fakelock_patch.sh
bash $work_dir/bin/package/KouseiPatcher/patcher.sh
cp -rf $appdir/KaoriosToolbox $work_dir/build/baserom/images/system/system/priv-app
cp -rf $appdir/com.kousei.kaorios.xml $work_dir/build/baserom/images/system/system/etc/permissions
cat $prop/build.prop >> $work_dir/build/baserom/images/system/system/build.prop
fi