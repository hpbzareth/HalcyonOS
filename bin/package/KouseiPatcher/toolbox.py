from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from typing import Optional


@dataclass
class Patch:
    smali_class: str
    method: str
    position: str
    anchor: str
    lines_to_add: list[str]
    anchor_is_directive: bool = False
    anchor_is_substring: bool = False


PATCHES: list[Patch] = [
    Patch(
        smali_class="android/app/Instrumentation.smali",
        method="newApplication(Ljava/lang/Class;Landroid/content/Context;)Landroid/app/Application;",
        position="above",
        anchor="return-object",
        anchor_is_substring=True,
        lines_to_add=[
            "invoke-static {p1}, Landroid/security/kaorios/KaoriosHook;->initContext(Landroid/content/Context;)V",
        ],
    ),
    Patch(
        smali_class="android/app/Instrumentation.smali",
        method="newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;",
        position="above",
        anchor="return-object",
        anchor_is_substring=True,
        lines_to_add=[
            "invoke-static {p3}, Landroid/security/kaorios/KaoriosHook;->initContext(Landroid/content/Context;)V",
        ],
    ),
    Patch(
        smali_class="android/app/ApplicationPackageManager.smali",
        method="hasSystemFeature(Ljava/lang/String;I)Z",
        position="below",
        anchor=".locals",
        anchor_is_directive=True,
        lines_to_add=[
            "invoke-static {p1, p2}, Landroid/security/kaorios/KaoriosHook;->hasSystemFeature(Ljava/lang/String;I)Ljava/lang/Boolean;",
            "move-result-object v0",
            "if-eqz v0, :cond_kaorios",
            "invoke-virtual {v0}, Ljava/lang/Boolean;->booleanValue()Z",
            "move-result v0",
            "return v0",
            ":cond_kaorios",
        ],
    ),
    Patch(
        smali_class="android/security/keystore2/AndroidKeyStoreKeyPairGeneratorSpi.smali",
        method="generateKeyPair()Ljava/security/KeyPair;",
        position="replace",
        anchor=".locals",
        anchor_is_directive=True,
        lines_to_add=[
            ".locals 15",
            "invoke-static {p0}, Landroid/security/kaorios/KaoriosHook;->initGenerateSoftwareKeyPair(Ljava/lang/Object;)Ljava/security/KeyPair;",
            "move-result-object v14",
            "if-eqz v14, :cond_kaorios",
            "return-object v14",
            ":cond_kaorios",
        ],
    ),
    Patch(
        smali_class="android/security/keystore2/AndroidKeyStoreSpi.smali",
        method="engineGetCertificateChain(Ljava/lang/String;)[Ljava/security/cert/Certificate;",
        position="below",
        anchor="aput-object v2, v3, v4",
        anchor_is_substring=True,
        lines_to_add=[
            "invoke-static {v3}, Landroid/security/kaorios/KaoriosHook;->CertificateChainIfNeeded([Ljava/security/cert/Certificate;)[Ljava/security/cert/Certificate;",
            "move-result-object v3",
        ],
    ),
]

SERVICES_PATCH = Patch(
    smali_class="com/android/server/SystemServer.smali",
    method="run()V",
    position="above",
    anchor="Lcom/android/server/SystemServer;->startOtherServices(Lcom/android/server/utils/TimingsTraceAndSlog;)V",
    anchor_is_substring=True,
    lines_to_add=[
        "invoke-static {}, Landroid/security/kaorios/KaoriosHook;->initSystemServer()V",
    ],
)


GUARD_COMMENT = "# [kaorios-patched]"


def find_smali_file(base_dir: str, smali_class: str) -> Optional[str]:
    target = os.path.normpath(smali_class)
    for root, _dirs, files in os.walk(base_dir):
        for fname in files:
            full = os.path.join(root, fname)
            normalized = os.path.normpath(full)
            if normalized.endswith(target):
                return full
    return None


def indent_of(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]


def method_signature_matches(line: str, method_sig: str) -> bool:
    stripped = line.strip()
    if not stripped.startswith(".method"):
        return False
    return method_sig in stripped


def apply_patch(patch: Patch, base_dir: str) -> bool:
    filepath = find_smali_file(base_dir, patch.smali_class)
    if not filepath:
        return False

    with open(filepath, "r", encoding="utf-8") as f:
        original_lines = f.readlines()

    for ln in original_lines:
        if GUARD_COMMENT in ln:
            first_add = patch.lines_to_add[0].strip()
            content = "".join(original_lines)
            if first_add in content:
                return True
            break

    in_target_method = False
    method_depth = 0
    anchor_stripped = patch.anchor.strip()
    inserted = False
    new_lines: list[str] = []

    i = 0
    while i < len(original_lines):
        line = original_lines[i]
        stripped = line.strip()

        if stripped.startswith(".method") and not in_target_method:
            if method_signature_matches(stripped, patch.method):
                in_target_method = True
                method_depth = 1
                new_lines.append(line)
                i += 1
                continue

        if in_target_method:
            if stripped.startswith(".method"):
                method_depth += 1
            elif stripped.startswith(".end method"):
                method_depth -= 1
                if method_depth == 0:
                    in_target_method = False

            if not inserted:
                match = False
                if patch.anchor_is_directive:
                    match = stripped.startswith(anchor_stripped)
                    if not match and anchor_stripped == ".locals":
                        match = stripped.startswith(".registers")
                elif patch.anchor_is_substring:
                    match = anchor_stripped in stripped
                else:
                    match = stripped == anchor_stripped

                if match:
                    base_indent = indent_of(line)
                    inject = [f"{base_indent}{l}\n" for l in patch.lines_to_add]
                    inject[0] = inject[0].rstrip("\n") + "  " + GUARD_COMMENT + "\n"

                    if patch.position == "above":
                        new_lines.extend(inject)
                        new_lines.append(line)
                    elif patch.position == "replace":
                        new_lines.extend(inject)
                    else:
                        new_lines.append(line)
                        new_lines.extend(inject)

                    inserted = True
                    i += 1
                    continue

        new_lines.append(line)
        i += 1

    if not inserted:
        return False

    with open(filepath, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    return True


def main():
    parser = argparse.ArgumentParser(description="Kaorios smali patcher")
    parser.add_argument("base_dir", help="Thư mục chứa smali")
    parser.add_argument("--services", action="store_true", help="Patch thêm SystemServer (initSystemServer)")
    args = parser.parse_args()

    if not os.path.isdir(args.base_dir):
        sys.exit(1)

    patches = list(PATCHES)
    if args.services:
        patches.append(SERVICES_PATCH)

    for patch in patches:
        if not apply_patch(patch, args.base_dir):
            sys.exit(1)


if __name__ == "__main__":
    main()
