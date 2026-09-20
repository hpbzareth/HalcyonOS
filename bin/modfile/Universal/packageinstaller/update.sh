WDIR=$(pwd)
source $WDIR/functions.sh
MAINF=$WDIR/build/baserom/images/
# Define ROM infomation
androidVer=$(cat $WDIR/bin/ddevice/androidver.txt)
deviceTYPE=$(cat $WDIR/bin/ddevice/device_type.txt)

# Check for required dependencies
if [ "$deviceTYPE" == "China" ]; then
	rm -rf $WDIR/build/baserom/images/product/priv-app/MIUIPackageInstaller/*
    cp -rf $WDIR/bin/modfile/Universal/packageinstaller/MIUIPackageInstaller.apk $WDIR/build/baserom/images/product/priv-app/MIUIPackageInstaller
    cp -rf $WDIR/bin/modfile/Universal/packageinstaller/privapp_whitelist_kashi.pkginstaller.xml $WDIR/build/baserom/images/product/etc/permissions/
else
    rm -rf $WDIR/build/baserom/images/system/system/priv-app/GooglePackageInstaller/*
    cp -rf $WDIR/bin/modfile/Universal/packageinstaller/GooglePackageInstaller.apk $WDIR/build/baserom/images/system/system/priv-app/GooglePackageInstaller
    cp -rf $WDIR/bin/modfile/Universal/packageinstaller/privapp_whitelist_kashi.pkginstaller.xml $WDIR/build/baserom/images/system/system/etc/permissions/
fi
mods "Done"
