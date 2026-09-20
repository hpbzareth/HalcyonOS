#!/bin/bash
work_dir=$(pwd)
# Set up environment variables for GitHub workflow
TOOLS_DIR="$work_dir/bin/apktool"
BACKUP_DIR="$work_dir/backup"
SCRIPT_DIR="$work_dir/bin/package/COREPATCH"
source "${SCRIPT_DIR}/helper.sh"
# Create backup directory
mkdir -p "$BACKUP_DIR"

# API level for baksmali/smali v2
API_LEVEL=33

# ============================================
# Feature Flags (set by command-line arguments)
# ============================================
FEATURE_DISABLE_SIGNATURE_VERIFICATION=1

# Function to patch method with direct file path (no searching)
patch_method_in_file() {
  local method="$1"
  local ret_val="$2"
  local file="$3"

  # Check if file exists
  if [ ! -f "$file" ]; then
    echo "⚠ File not found: $(basename "$file")"
    return
  fi

  local start
  start=$(grep -n "^[[:space:]]*\.method.* $method" "$file" | cut -d: -f1 | head -n1)
  [ -z "$start" ] && {
    echo "⚠ Method $method not found in $(basename "$file")"
    return
  }

  local total_lines end=0 i="$start"
  total_lines=$(wc -l < "$file")
  while [ "$i" -le "$total_lines" ]; do
    line=$(sed -n "${i}p" "$file")
    [[ "$line" == *".end method"* ]] && {
      end="$i"
      break
    }
    i=$((i + 1))
  done

  [ "$end" -eq 0 ] && {
    echo "⚠ End not found for $method"
    return
  }

  local method_head
  method_head=$(sed -n "${start}p" "$file")
  method_head_escaped=$(printf "%s\n" "$method_head" | sed 's/\\/\\\\/g')

  sed -i "${start},${end}c\\
$method_head_escaped\\
    .registers 8\\
    const/4 v0, 0x$ret_val\\
    return v0\\
.end method" "$file"

  echo "✓ Patched $method to return $ret_val in $(basename "$file")"
}

# Function to add static return patch (legacy - searches for file)
add_static_return_patch() {
  local method="$1"
  local ret_val="$2"
  local decompile_dir="$3"
  local file

  # Simple working approach from old script
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l ".method.* $method" 2> /dev/null | head -n 1)

  [ -z "$file" ] && return

  # Call the new function with found file
  patch_method_in_file "$method" "$ret_val" "$file"
}

# Function to patch return-void method with direct file path
patch_return_void_in_file() {
  local method="$1"
  local file="$2"

  # Check if file exists
  if [ ! -f "$file" ]; then
    echo "⚠ File not found: $(basename "$file")"
    return
  fi

  local start
  start=$(grep -n "^[[:space:]]*\.method.* $method" "$file" | cut -d: -f1 | head -n1)
  [ -z "$start" ] && {
    echo "⚠ Method $method not found in $(basename "$file")"
    return
  }

  local total_lines end=0 i="$start"
  total_lines=$(wc -l < "$file")
  while [ "$i" -le "$total_lines" ]; do
    line=$(sed -n "${i}p" "$file")
    [[ "$line" == *".end method"* ]] && {
      end="$i"
      break
    }
    i=$((i + 1))
  done

  [ "$end" -eq 0 ] && {
    echo "⚠ Method $method end not found"
    return
  }

  local method_head
  method_head=$(sed -n "${start}p" "$file")
  method_head_escaped=$(printf "%s\n" "$method_head" | sed 's/\\/\\\\/g')

  sed -i "${start},${end}c\\
$method_head_escaped\\
    .registers 8\\
    return-void\\
.end method" "$file"

  echo "✓ Patched $method → return-void in $(basename "$file")"
}

# Function to patch return-void method (legacy - searches for file)
patch_return_void_method() {
  local method="$1"
  local decompile_dir="$2"
  local file

  # Simple working approach from old script
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l ".method.* $method" 2> /dev/null | head -n 1)
  [ -z "$file" ] && {
    echo "Method $method not found"
    return
  }

  # Call the new function with found file
  patch_return_void_in_file "$method" "$file"
}

# ============================================
# Feature-specific patch functions for framework.jar
# ============================================

# Apply signature verification bypass patches to framework.jar (Android 13)
apply_framework_signature_patches() {
  local decompile_dir="$1"

  echo "Applying signature verification patches to framework.jar (Android 13)..."

  # Patch getMinimumSignatureSchemeVersionForTargetSdk to return 0
  echo "Patching getMinimumSignatureSchemeVersionForTargetSdk..."
  add_static_return_patch "getMinimumSignatureSchemeVersionForTargetSdk" 0 "$decompile_dir"

  # Patch verifyMessageDigest to return 1
  echo "Patching verifyMessageDigest..."
  add_static_return_patch "verifyMessageDigest" 1 "$decompile_dir"

  # Patch verifySignatures - find and patch invoke-interface result
  echo "Patching verifySignatures..."
  local file
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l "invoke-interface.*ParseResult;->isError()Z" 2> /dev/null | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-interface {v0}, Landroid/content/pm/parsing/result/ParseResult;->isError()Z"
    local linenos
    linenos=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$linenos" ]; then
      for lineno in $linenos; do
        local move_result_lineno=$((lineno + 1))
        local current_line
        current_line=$(sed -n "${move_result_lineno}p" "$file" | sed 's/^[ \t]*//')
        if [[ "$current_line" == "move-result v1" ]]; then
          local indent
          indent=$(sed -n "${move_result_lineno}p" "$file" | grep -o '^[ \t]*')
          sed -i "$((move_result_lineno + 1))i\\
${indent}const/4 v1, 0x0" "$file"
          echo "Patched verifySignatures at line $((move_result_lineno + 1))"
          break
        fi
      done
    fi
  fi

  # Patch verifyV1Signature
  echo "Patching verifyV1Signature..."
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l "verifyV1Signature.*ParseInput.*Ljava/lang/String;Z" 2> /dev/null | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-static.*verifyV1Signature"
    local lineno
    lineno=$(grep -n "$pattern" "$file" | cut -d: -f1 | head -n1)
    if [ -n "$lineno" ]; then
      sed -i "${lineno}i\\
    const/4 p3, 0x0" "$file"
      echo "Patched verifyV1Signature at line $lineno"
    fi
  fi

  # Patch verifyV2Signature
  echo "Patching verifyV2Signature..."
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l "verifyV2Signature.*ParseInput.*Ljava/lang/String;Z" 2> /dev/null | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-static.*verifyV2Signature"
    local lineno
    lineno=$(grep -n "$pattern" "$file" | cut -d: -f1 | head -n1)
    if [ -n "$lineno" ]; then
      sed -i "${lineno}i\\
    const/4 p3, 0x0" "$file"
      echo "Patched verifyV2Signature at line $lineno"
    fi
  fi

  # Patch verifyV3Signature
  echo "Patching verifyV3Signature..."
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l "verifyV3Signature.*ParseInput.*Ljava/lang/String;Z" 2> /dev/null | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-static.*verifyV3Signature"
    local lineno
    lineno=$(grep -n "$pattern" "$file" | cut -d: -f1 | head -n1)
    if [ -n "$lineno" ]; then
      sed -i "${lineno}i\\
    const/4 p3, 0x0" "$file"
      echo "Patched verifyV3Signature at line $lineno"
    fi
  fi

  # Patch verifyV3AndBelowSignatures
  echo "Patching verifyV3AndBelowSignatures..."
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l "verifyV3AndBelowSignatures.*ParseInput.*Ljava/lang/String;IZ" 2> /dev/null | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-static.*verifyV3AndBelowSignatures"
    local lineno
    lineno=$(grep -n "$pattern" "$file" | cut -d: -f1 | head -n1)
    if [ -n "$lineno" ]; then
      sed -i "${lineno}i\\
    const/4 p3, 0x0" "$file"
      echo "Patched verifyV3AndBelowSignatures at line $lineno"
    fi
  fi

  # Patch checkCapability to return 1
  echo "Patching checkCapability..."
  add_static_return_patch "checkCapability" 1 "$decompile_dir"

  # Patch checkCapabilityRecover to return 1
  echo "Patching checkCapabilityRecover..."
  add_static_return_patch "checkCapabilityRecover" 1 "$decompile_dir"

  # Patch isPackageWhitelistedForHiddenApis to return 1
  echo "Patching isPackageWhitelistedForHiddenApis..."
  add_static_return_patch "isPackageWhitelistedForHiddenApis" 1 "$decompile_dir"

  # Patch StrictJarFile findEntry
  echo "Patching StrictJarFile findEntry..."
  file=$(find "$decompile_dir" -type f -name "StrictJarFile.smali" | head -n 1)
  if [ -f "$file" ]; then
    local start_line
    start_line=$(grep -n "invoke-virtual.*findEntry.*Ljava/util/zip/ZipEntry;" "$file" | cut -d: -f1 | head -n1)

    if [ -n "$start_line" ]; then
      local i=$((start_line + 1))
      local total_lines
      total_lines=$(wc -l < "$file")

      while [ "$i" -le "$total_lines" ]; do
        line=$(sed -n "${i}p" "$file")
        if [[ "$line" == *"if-eqz v6"* ]]; then
          # Remove the if-eqz line
          sed -i "${i}d" "$file"
          echo "Removed if-eqz at line $i"
          break
        fi
        i=$((i + 1))
      done
    fi
  fi

  echo "Signature verification patches applied to framework.jar (Android 13)"
}


# Main framework patching function
patch_framework() {
  local framework_path="$work_dir/build/baserom/images/system/system/framework/framework.jar"
  local decompile_dir="$work_dir/framework_decompile"

  echo "Starting framework.jar patch..."

  # Decompile framework.jar
  decompile_jar "$framework_path"

  # Apply feature-specific patches based on flags
  apply_framework_signature_patches "$decompile_dir"

  # Recompile framework.jar
  recompile_jar "$framework_path"

  # Clean up
  rm -rf "$work_dir/framework" "$decompile_dir"

  if [ ! -f "framework_patched.jar" ]; then
    err "Critical Error: framework_patched.jar was not created."
    return 1
  fi

  echo "Framework.jar patching completed."
}

# ============================================
# Feature-specific patch functions for services.jar
# ============================================

# Apply disable secure flag patches to services.jar
apply_services_disable_secure_flag() {
  local decompile_dir="$1"
  add_static_return_patch "isScreenCaptureAllowed(I)Z" 1 "$decompile_dir"
  patch_return_void_method "setScreenCaptureDisabled(Landroid/content/ComponentName;ZZ)V" "$decompile_dir"
  add_static_return_patch "isSecureLocked()Z" 0 "$decompile_dir"
  patch_return_void_method "setSecure(Z)V" "$decompile_dir"
}

# Apply signature verification bypass patches to services.jar (Android 13)
apply_services_signature_patches() {
  local decompile_dir="$1"

  echo "Applying signature verification patches to services.jar (Android 13)..."

  # Patch checkDowngrade to return-void
  echo "Patching checkDowngrade..."
  patch_return_void_method "checkDowngrade" "$decompile_dir"

  # Patch shouldCheckUpgradeKeySetLocked to return 0
  echo "Patching shouldCheckUpgradeKeySetLocked..."
  add_static_return_patch "shouldCheckUpgradeKeySetLocked" 0 "$decompile_dir"

  # Patch verifySignatures to return 0
  echo "Patching verifySignatures..."
  add_static_return_patch "verifySignatures" 0 "$decompile_dir"

  # Patch matchSignaturesCompat to return 1
  echo "Patching matchSignaturesCompat..."
  add_static_return_patch "matchSignaturesCompat" 1 "$decompile_dir"

  # Patch isPersistent check
  echo "Patching isPersistent check..."
  local file
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l "invoke-interface.*isPersistent()Z" 2> /dev/null | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-interface {v4}, Lcom/android/server/pm/pkg/AndroidPackage;->isPersistent()Z"
    local linenos
    linenos=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$linenos" ]; then
      for lineno in $linenos; do
        local move_result_lineno=$((lineno + 1))
        local current_line
        current_line=$(sed -n "${move_result_lineno}p" "$file" | sed 's/^[ \t]*//')
        if [[ "$current_line" == "move-result v2" ]]; then
          local indent
          indent=$(sed -n "${move_result_lineno}p" "$file" | grep -o '^[ \t]*')
          sed -i "$((move_result_lineno + 1))i\\
${indent}const/4 v2, 0x0" "$file"
          echo "Patched isPersistent check at line $((move_result_lineno + 1))"
          break
        fi
      done
    fi
  fi

  echo "Signature verification patches applied to services.jar (Android 13)"
}

# Main services patching function
patch_services() {
  local services_path="$work_dir/build/baserom/images/system/system/framework/services.jar"
  local decompile_dir="$work_dir/services_decompile"

  echo "Starting services.jar patch..."

  # Decompile services.jar
  decompile_jar "$services_path"

  # Apply feature-specific patches based on flags
  apply_services_signature_patches "$decompile_dir"
  #apply_services_disable_secure_flag "$decompile_dir"

  # Recompile services.jar
  recompile_jar "$services_path"

  # Clean up
  rm -rf "$work_dir/services" "$decompile_dir"

  if [ ! -f "services_patched.jar" ]; then
    err "Critical Error: services_patched.jar was not created."
    return 1
  fi

  echo "Services.jar patching completed."
}

# ============================================
# Feature-specific patch functions for miui-services.jar
# ============================================

# Apply Gboard patches
apply_miui_services_gboard() {
  local decompile_dir="$1"

  # Add Gboard
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/server/input/InputManagerServiceStubImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/server/inputmethod/InputMethodManagerServiceImpl.smali"

  echo "Gboard patches applied to miui-services.jar"
}

# Apply ContentExtension patches
apply_miui_services_contentextension() {
  local decompile_dir="$1"
  replace_line_contains_in_smali_method "IS_INTERNATIONAL_BUILD" "updateContentCatcherWhitelist()V" "    const/4 v0, 0x0" "$decompile_dir/smali/com/android/server/am/ProcessPolicy.smali"
  echo "ContentExtension patches applied to miui-services.jar"
}

# Apply floating
apply_miui_services_floating() {
  local decompile_dir="$1"
  for i in "$decompile_dir/"*"/com/android/server/wm/MiuiFreeFormStackDisplayStrategy.smali"; do
    patch_method_in_file "getMaxMiuiFreeFormStackCount(Ljava/lang/String;Lcom/android/server/wm/MiuiFreeFormActivityStack;)I" 6 "$i"
  done
}

# Main miui-services patching function
patch_miui_services() {
  local miui_services_path="$work_dir/build/baserom/images/system_ext/framework/miui-services.jar"
  local decompile_dir="$work_dir/miui-services_decompile"

  echo "Starting miui-services.jar patch..."

  # Decompile miui-services.jar
  decompile_jar "$miui_services_path"

  # Apply mod
  apply_miui_services_gboard "$decompile_dir"
  apply_miui_services_contentextension "$decompile_dir"
  apply_miui_services_floating "$decompile_dir"

  # Recompile miui-services.jar
  recompile_jar "$miui_services_path"

  # Clean up
  rm -rf "$work_dir/miui-services" "$decompile_dir"

  if [ ! -f "miui-services_patched.jar" ]; then
    err "Critical Error: miui-services_patched.jar was not created."
    return 1
  fi

  echo "Miui-services.jar patching completed."
}

# ============================================
# Feature-specific patch functions for miui-framework.jar
# ============================================

# Apply Gboard patches
apply_miui_framework_gboard() {
  local decompile_dir="$1"

  # Add Gboard
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/android/inputmethodservice/InputMethodServiceInjector.smali"

  echo "Gboard patches applied to miui-framework.jar"
}

# Main miui-framework patching function
patch_miui_framework() {
  local miui_framework_path="$work_dir/build/baserom/images/system_ext/framework/miui-framework.jar"
  local decompile_dir="$work_dir/miui-framework_decompile"

  echo "Starting miui-framework.jar patch..."

  # Decompile miui-framework.jar
  decompile_jar "$miui_framework_path"

  # Apply mod
  apply_miui_framework_gboard "$decompile_dir"

  # Recompile miui-framework.jar
  recompile_jar "$miui_framework_path"

  # Clean up
  rm -rf "$work_dir/miui-framework" "$decompile_dir"

  if [ ! -f "miui-framework_patched.jar" ]; then
    err "Critical Error: miui-framework_patched.jar was not created."
    return 1
  fi

  echo "Miui-framework.jar patching completed."
}

# Main function
# Initialize environment and check tools
FEATURE_DISABLE_SIGNATURE_VERIFICATION=1
FEATURE_DISABLE_SECURE_FLAG=1
init_env
ensure_tools || exit 1

# Patch requested JARs
patch_framework
patch_services
patch_miui_services
patch_miui_framework

# Add patched JARs
mv -f "framework_patched.jar" "$work_dir/build/baserom/images/system/system/framework/framework.jar"
mv -f "services_patched.jar" "$work_dir/build/baserom/images/system/system/framework/services.jar"
mv -f "miui-services_patched.jar" "$work_dir/build/baserom/images/system_ext/framework/miui-services.jar"
mv -f "miui-framework_patched.jar" "$work_dir/build/baserom/images/system_ext/framework/miui-framework.jar"
