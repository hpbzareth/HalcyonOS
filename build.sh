baserom="$1"
repo_name="$2"
prefix_id="$3"
builder_name="$4"
builder_id="$5"
work_dir=$(pwd)

# Import functions
tools_dir=${work_dir}/bin/$(uname)/$(uname -m)
export PATH=$(pwd)/bin/$(uname)/$(uname -m)/:$PATH
chmod 777 ${work_dir}/bin/*
chmod 777 ${work_dir}/bin/Linux/x86_64/*
source $work_dir/functions.sh

if [[ $(git branch --show-current) == "beta" ]]; then
    polyxver="$(cat Version)"
	status="Development"
else
    polyxver="$(cat Version)"
	status="Official"
fi

# ---> ĐÃ THÊM 2 DÒNG NÀY ĐỂ FIX LỖI THIẾU GÓI <---
sudo apt-get update -y
sudo apt-get install -y xmlstarlet aapt

check unzip aria2c 7z zip java zipalign python3 zstd bc xmlstarlet aapt

# Dọn dẹp môi trường trước khi build
rm -rf $work_dir/out
rm -rf $work_dir/build
mkdir -p $work_dir/out

python3 $work_dir/notify.py download "$repo_name" "$baserom" "$prefix_id" "$builder_name" "$builder_id"
source "$work_dir/bin/ddevice/getROM.sh" "$baserom"

python3 $work_dir/notify.py unpack "$repo_name" "$baserom" "$prefix_id" "$builder_name" "$builder_id"
# Fallback: if baserom path not found, scan for latest downloaded zip
if [[ ! -f "$baserom" ]]; then
    found_zip=$(ls -S $work_dir/*.zip 2>/dev/null | head -n 1)
    if [[ -n "$found_zip" && -f "$found_zip" ]]; then
        baserom="$found_zip"
    else
        clean_name=$(basename "${baserom%%\?*}")
        if [[ -f "$work_dir/$clean_name" ]]; then
            baserom="$work_dir/$clean_name"
        elif [[ -f "$clean_name" ]]; then
            baserom="$clean_name"
        fi
    fi
fi

if unzip -l "${baserom}" | grep -q "payload.bin"; then
    baserom_type="payload"
    echo $baserom_type > $work_dir/bin/ddevice/romtype.txt
    unpack "Found payload.bin file"
    super_list="vendor mi_ext odm odm_dlkm system system_dlkm vendor_dlkm product product_dlkm system_ext"
    unpack "ROM validation passed."
elif unzip -l "${baserom}" | grep -q "br$";then
    baserom_type="br"
    echo $baserom_type > $work_dir/bin/ddevice/romtype.txt
    super_list="system vendor product odm system_ext mi_ext"
    unpack "Found broli file"
    unpack "ROM validation passed."
elif unzip -l "${baserom}" | grep -q "super.img.*"; then
    unpack "Found super.img.* files"
    is_base_rom_eu=true
    baserom_type="eu"
    echo $baserom_type > $work_dir/bin/ddevice/romtype.txt
    unpack "ROM validation passed."
else
    error "Unpack failed"
    exit 1
fi

rm -rf app tmp config build/baserom/
find . -type d -name 'miui_*' | xargs rm -rf

unpack "Files cleaned up."
mkdir -p build/baserom/images/

# Extract partitions
if [[ ${baserom_type} == 'payload' ]]; then
    unpack "Extracting files payload.bin..."
    unzip ${baserom} payload.bin -d build/baserom >/dev/null 2>&1 || error "Extracting payload.bin error"
    unpack "File payload.bin extracted."
elif [[ ${baserom_type} == 'br' ]];then
    unpack "Extracting files *.new.dat.br"
    unzip ${baserom} -d build/baserom >/dev/null 2>&1 || error "Extracting new.dat.br error"
    unpack "File new.dat.br extracted."
elif [[ ${is_base_rom_eu} == true ]];then
    unpack "Extracting files from BASETROM [super.img]"
    unzip "${baserom}" 'images/*' -d build/baserom > /dev/null 2>&1 || error "Extracting [super.img] error"

    super_dir=$(dirname $(find build/baserom -name "super.img.0" 2>/dev/null | head -n1))
    if [ -z "$super_dir" ] || [ ! -d "$super_dir" ]; then
        super_dir="build/baserom/images"
    fi

    unpack "Merging super.img.* into super.img"
    if [ -x "/usr/bin/simg2img" ]; then
        /usr/bin/simg2img $(ls "$super_dir"/super.img.* | sort -V) build/baserom/super.img
    else
        simg2img $(ls "$super_dir"/super.img.* | sort -V) build/baserom/super.img
    fi

    if [[ ! -s build/baserom/super.img ]]; then
        error "Merging super.img failed! Output is empty."
        exit 1
    fi

    rm -f "$super_dir"/super.img.*
    unpack "[super.img] extracted."

    if [[ -n "$(find build/baserom -name 'cust.img.0' 2>/dev/null)" ]]; then
        cust_file=$(find build/baserom -name "cust.img.0" | head -n1)
        cust_dir=$(dirname "$cust_file")
        simg2img ${cust_dir}/cust.img.* build/baserom/images/cust.img 2>/dev/null || true
        rm -rf ${cust_dir}/cust.img.*
    fi
fi

if [[ ${baserom_type} == 'payload' ]]; then
    unpack "Unpacking payload.bin"
    payload-extract extract -o build/baserom/images/ build/baserom/payload.bin >/dev/null 2>&1 || error "Unpacking payload.bin failed"    
elif [[ ${baserom_type} == 'br' ]];then
    super_list=$(cat build/baserom/dynamic_partitions_op_list | grep "add " | awk '{ print $2 }')
    unpack "Unpacking new.dat.br"
        for brotlipart in ${super_list}; do 
            brotli -d build/baserom/$brotlipart.new.dat.br >/dev/null 2>&1
            python3 $work_dir/bin/Linux/x86_64/sdat2img.py build/baserom/$brotlipart.transfer.list build/baserom/$brotlipart.new.dat build/baserom/images/$brotlipart.img >/dev/null 2>&1
            rm -rf build/baserom/$brotlipart.new.dat* build/baserom/$brotlipart.transfer.list build/baserom/$brotlipart.patch.*
        done
elif [[ ${is_base_rom_eu} == true ]];then
    unpack "Unpacking BASEROM [super.img]"
    python3 bin/lpunpack.py build/baserom/super.img build/baserom/images/ >/dev/null 2>&1

    # Rename _a slot partitions to plain names
    for i in build/baserom/images/*_a.img; do
        if [ -f "$i" ]; then
            mv "$i" "${i%_a.img}.img"
        fi
    done
    # Remove all _b slot placeholders (0 byte dummies)
    rm -f build/baserom/images/*_b.img

    super_list="system system_ext product vendor odm mi_ext"
fi

for part in ${super_list}; do
    if [ -f "$work_dir/build/baserom/images/${part}.img" ]; then
        extract_partition $work_dir/build/baserom/images/${part}.img $work_dir/build/baserom/images
        PACK_TYPE=$(cat $work_dir/bin/ddevice/fstype.txt 2>/dev/null || echo "erofs")
    fi
done
echo $device_f > $work_dir/bin/ddevice/device_f.txt
getvar=$(cat $work_dir/bin/ddevice/device_f.txt)

rm -rf config
if [ -f $work_dir/${baserom}.zip ]; then rm -rf ${baserom}.zip; fi
rm -rf build/baserom/payload.bin build/baserom/images/super.img



if [ ! -s "$work_dir/bin/ddevice/device_name.txt" ]; then 
    echo "Xiaomi Device" > $work_dir/bin/ddevice/device_name.txt 
fi

mods "Gathering Devices Infomations"
bash $work_dir/bin/ddevice/getname.sh $getvar
bash $work_dir/bin/ddevice/fetchINFO.sh

python3 $work_dir/notify.py build "$repo_name" "$baserom" "$prefix_id" "$builder_name" "$builder_id"

bash $work_dir/bin/ddevice/DEBLOAT/debloat.sh
info "Done"

bash $work_dir/bin/modfile/OS1/insmod.sh
bash $work_dir/bin/modfile/OS2/insmod.sh
bash $work_dir/bin/modfile/OS3/insmod.sh
bash $work_dir/bin/modfile/Universal/insfile.sh
bash $work_dir/bin/modfile/UpdateFile/insupdate.sh
bash $work_dir/bin/package/patchpackage.sh


find "$work_dir/build/baserom/images/" -exec touch -t 200901010000.00 {} + 2> /dev/null || true

