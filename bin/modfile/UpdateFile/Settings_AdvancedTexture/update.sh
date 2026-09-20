work_dir=$(pwd)
source $work_dir/functions.sh

# Unlock Advanced Texture
if ! is_property_exists persist.sys.background_blur_supported build/baserom/images/product/etc/build.prop; then
    echo "persist.sys.background_blur_supported=true" >> build/baserom/images/product/etc/build.prop
    echo "persist.sys.background_blur_version=2" >> build/baserom/images/product/etc/build.prop
else
    sed -i "s/persist.sys.background_blur_supported=.*/persist.sys.background_blur_supported=true/" build/baserom/images/product/etc/build.prop
fi

#SpeedUp GameTurbo Animation
echo "debug.game.video.speed=true" >> build/baserom/images/product/etc/build.prop
echo "debug.game.video.support=true" >> build/baserom/images/product/etc/build.prop

# Unlock MEMC; unlocking the screen enhance engine is a prerequisite.
if  grep -q "ro.vendor.media.video.frc.support" build/baserom/images/vendor/build.prop ;then
    sed -i "s/ro.vendor.media.video.frc.support=.*/ro.vendor.media.video.frc.support=true/" build/baserom/images/vendor/build.prop
else
    echo "ro.vendor.media.video.frc.support=true" >> build/baserom/images/vendor/build.prop
fi