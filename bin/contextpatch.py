#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
from re import sub
from difflib import SequenceMatcher

fix_permission = {
    "/vendor/bin/hw/android.hardware.wifi@1.0":           "u:object_r:hal_wifi_default_exec:s0",
    "/vendor/bin/hw/vendor.qti.camera.provider-service_64": "u:object_r:hal_camera_default_exec:s0",
    "/system/system/bin/init":                            "u:object_r:init_exec:s0",
    "/system_ext/xbin/xeu_toolbox":                       "u:object_r:xeu_toolbox_exec:s0",
    "/vendor/lib64/hw/camera.qcom.core.so":               "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/hw/camera.qcom.so":                    "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/hw/com.qti.chi.override.so":           "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/libchicore.so":                        "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/libchilog.so":                         "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/libmicamera_adapter.so":               "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/libmicamera_hal_core.so":              "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/libmicamera_aidl_provider.so":         "u:object_r:same_process_hal_file:s0",
    "/vendor/lib64/com.qti.feature2.gs.sm8850.so":        "u:object_r:same_process_hal_file:s0",
}



def get_fix_permission(path: str):
    result = None
    if path in fix_permission:
        result = fix_permission[path]
    else:
        for key, perm in fix_permission.items():
            if key.endswith('/') and path.startswith(key):
                result = perm
                break
    if isinstance(result, str):
        return [result]
    return result


def scan_context(file) -> dict:  # 读取context文件返回一个字典
    context = {}
    with open(file, "r", encoding='utf-8') as file_:
        for i in file_.readlines(): 
            filepath, *other = i.strip().replace('\\', '').split()
            context[filepath] = other
            if len(other) > 1:
                print(f"[Warn] {i[0]} has too much data.")
    return context


def scan_dir(folder) -> list:  # 读取解包的目录，返回一个字典
    part_name = os.path.basename(folder)
    allfiles = ['/', '/lost+found', f'/{part_name}/lost+found', f'/{part_name}', f'/{part_name}/']
    for root, dirs, files in os.walk(folder, topdown=True):
        for dir_ in dirs:
            yield os.path.join(root, dir_).replace(folder, '/' + part_name).replace('\\', '/')
        for file in files:
            yield os.path.join(root, file).replace(folder, '/' + part_name).replace('\\', '/')
        for rv in allfiles:
            yield rv


def context_patch(fs_file, dir_path) -> tuple:  # 接收两个字典对比
    new_fs = {}
    r_new_fs = {}
    add_new = 0
    permission_d = None
    print("ContextPatcher: Load origin %d" % (len(fs_file.keys())) + " entries")
    try:
        if dir_path.endswith('/system'):
            permission_d = ['u:object_r:system_file:s0']
        elif dir_path.endswith('/vendor'):
            permission_d = ['u:object_r:vendor_file:s0']
        else:
            permission_d = fs_file.get(list(fs_file)[5])
    except IndexError:
        pass
    if not permission_d:
        permission_d = ['u:object_r:system_file:s0']
    for i in scan_dir(os.path.abspath(dir_path)):
        if fs_file.get(i):
            new_fs[sub(r'([^-_/a-zA-Z0-9])', r'\\\1', i)] = fs_file[i]
        else:
            permission = permission_d
            if r_new_fs.get(i):
                continue
            if i:
                if (fixed := get_fix_permission(i)):
                    permission = fixed
                else:
                    for e in fs_file.keys():
                        if SequenceMatcher(None, (path := os.path.dirname(i)), e).quick_ratio() >= 0.85:
                            if e == path:
                                continue
                            permission = fs_file[e]
                            break
                        else:
                            permission = permission_d
            print(f"ADD [{i} {permission}]")
            add_new += 1
            r_new_fs[i] = permission
            new_fs[sub(r'([^-_/a-zA-Z0-9])', r'\\\1', i)] = permission
    return new_fs, add_new


def main(dir_path, fs_config) -> None:
    new_fs, add_new = context_patch(scan_context(os.path.abspath(fs_config)), dir_path)
    with open(fs_config, "w+", encoding='utf-8', newline='\n') as f:
        f.writelines([i + " " + " ".join(new_fs[i]) + "\n" for i in sorted(new_fs.keys())])
    print('ContextPatcher: Add %d' % add_new + " entries")


def usage():
    print("Usage:")
    print("%s <folder> <context_config>" % (sys.argv[0]))
    print("    This script will auto patch file_context")


if __name__ == '__main__':
    import sys

    if len(sys.argv) < 3:
        usage()
        sys.exit()
    if os.path.isdir(sys.argv[1]) or os.path.isfile(sys.argv[2]):
        main(sys.argv[1], sys.argv[2])
        print("Done!")
    else:
        print("The path or filetype you have given may wrong,please check it weather correct.")
        usage()
