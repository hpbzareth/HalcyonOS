work_dir=$(pwd)
ANDROID_DEVICE=$(cat $work_dir/bin/ddevice/device_f.txt)
gfFile="$work_dir/build/baserom/images/product/etc/device_features/*.xml"
rom_os=$(cat $work_dir/bin/ddevice/rom_os.txt)
regionTYPE=$(cat $work_dir/bin/ddevice/device_type.txt)
str='<item>120</item>'
str1='<item>90</item>'
str2='<item>1</item>'
checkfps='<bool name="support_smart_fps">true</bool>'

#Check DeviceCodeName
if [ -f $work_dir/build/baserom/images/product/etc/device_features/*.xml ]; then

if [ `grep -c "$str" $gfFile` -eq '0' ];then
	sed '/<item>144<\/item>/a\        <item>120<\/item>' $gfFile > ${gfFile}.new
	mv ${gfFile}.new $gfFile
	echo "Added 120hz to ${gfFile}"
fi

if [ `grep -c "$str1" $gfFile` -eq '0' ];then
	sed '/<item>120<\/item>/a\        <item>90<\/item>' $gfFile > ${gfFile}.new
	mv ${gfFile}.new $gfFile
	echo "Added 90hz to ${gfFile}"
fi

if [ `grep -c "$str2" $gfFile` -eq '0' ];then
	sed '/<item>60<\/item>/a\        <item>1<\/item>' $gfFile > ${gfFile}.new
	mv ${gfFile}.new $gfFile
	echo "Added 1hz to ${gfFile}"
fi

if [ `grep -c "$checkfps" $gfFile` -eq '0' ];then
    sed '/<integer name="defaultFps">60<\/integer>/a\    <bool name="support_smart_fps">true<\/bool>\<integer name="smart_fps_value">120<\/integer>' $gfFile > ${gfFile}.new
    mv ${gfFile}.new $gfFile
	echo "Added SmartFPS to ${gfFile}"
fi
fi