#!/bin/bash
work_dir=$(pwd)
# Set up environment variables for GitHub workflow
TOOLS_DIR="$work_dir/bin/apktool"
WORK_DIR="$work_dir"
BACKUP_DIR="$WORK_DIR/backup"
SCRIPT_DIR="$work_dir/bin/package/COREPATCH"
source "${SCRIPT_DIR}/helper.sh"
# Create backup directory
mkdir -p "$BACKUP_DIR"
INVOKE_DIR="$work_dir/bin/package/COREPATCH/INVOKE"

# API level for baksmali/smali v2
API_LEVEL=35

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

# Function to replace an entire method with a custom implementation
replace_entire_method() {
  local method_signature="$1"
  local decompile_dir="$2"
  local new_method_body="$3"
  local specific_class="$4" # Optional: specific class name to search in
  local file

  # If specific class provided, search in that class file
  if [ -n "$specific_class" ]; then
    file=$(find "$decompile_dir" -type f -path "*/${specific_class}.smali" | head -n 1)
    if [ -z "$file" ]; then
      echo "⚠ Class file $specific_class.smali not found"
      return 0
    fi
    # Verify method exists in this file
    if ! grep -q "\.method.* ${method_signature}" "$file" 2> /dev/null; then
      echo "⚠ Method $method_signature not found in $specific_class"
      return 0
    fi
  else
    # Search across all smali files
    file=$(find "$decompile_dir" -type f -name "*.smali" -exec grep -l "\.method.* ${method_signature}" {} + 2> /dev/null | head -n 1)
  fi

  [ -z "$file" ] && {
    echo "⚠ Method $method_signature not found in decompile directory"
    return 0
  }

  local start
  start=$(grep -n "^[[:space:]]*\.method.* ${method_signature}" "$file" | cut -d: -f1 | head -n1)
  [ -z "$start" ] && {
    echo "⚠ Method $method_signature start not found in $(basename "$file")"
    return 0
  }

  local total_lines end=0 i="$start" line
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
    echo "⚠ Method $method_signature end not found in $(basename "$file")"
    return 0
  }

  local method_head
  method_head=$(sed -n "${start}p" "$file")
  method_head_escaped=$(printf "%s\n" "$method_head" | sed 's/\\/\\\\/g')

  # Replace the entire method with the new body
  sed -i "${start},${end}c\\
$method_head_escaped\\
$new_method_body\\
.end method" "$file"

  echo "✓ Replaced entire method $method_signature in $(basename "$file")"
  return 0
}

# Function to modify invoke-custom methods
modify_invoke_custom_methods() {
  local decompile_dir="$1"
  echo "Checking for invoke-custom..."

  # Simple working approach from old script
  local smali_files
  smali_files=$(grep -rl "invoke-custom" "$decompile_dir" --include="*.smali" 2> /dev/null)

  [ -z "$smali_files" ] && {
    echo "No invoke-custom found"
    return
  }

  local count=0
  for smali_file in $smali_files; do
    count=$((count + 1))

    # Patch equals method
    sed -i "/.method.*equals(/,/^.end method$/ {
            /^    .registers/c\    .registers 2
            /^    invoke-custom/d
            /^    move-result/d
            /^    return/c\    const/4 v0, 0x0\n\n    return v0
        }" "$smali_file"

    # Patch hashCode method
    sed -i "/.method.*hashCode(/,/^.end method$/ {
            /^    .registers/c\    .registers 2
            /^    invoke-custom/d
            /^    move-result/d
            /^    return/c\    const/4 v0, 0x0\n\n    return v0
        }" "$smali_file"

    # Patch toString method
    sed -i "/.method.*toString(/,/^.end method$/ {
            s/^[[:space:]]*\.registers.*/    .registers 1/
            /^    invoke-custom/d
            /^    move-result.*/d
            /^    return.*/c\    const/4 v0, 0x0\n\n    return-object v0
        }" "$smali_file"
  done

  echo "[INFO] Modified $count files with invoke-custom"
}

# ============================================
# Feature-specific patch functions for framework.jar
# ============================================

# Apply signature verification bypass patches to framework.jar
apply_framework_signature_patches() {
  local decompile_dir="$1"

  echo "Applying signature verification patches to framework.jar..."

  # Patch ParsingPackageUtils isError result
  local file
  file=$(find "$decompile_dir" -type f -path "*/com/android/internal/pm/pkg/parsing/ParsingPackageUtils.smali" | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-interface {v2}, Landroid/content/pm/parsing/result/ParseResult;->isError()Z"
    local linenos
    linenos=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$linenos" ]; then
      local patched=0
      for invoke_lineno in $linenos; do
        found=0
        for offset in 1 2 3; do
          move_lineno=$((invoke_lineno + offset))
          line_content=$(sed -n "${move_lineno}p" "$file" | sed 's/^[ \t]*//')
          if [[ "$line_content" == "const/4 v4, 0x0" ]]; then
            echo "Already patched at line $move_lineno"
            found=1
            patched=1
            break 2
          fi
          if [[ "$line_content" == "move-result v4" ]]; then
            indent=$(sed -n "${move_lineno}p" "$file" | grep -o '^[ \t]*')
            sed -i "$((move_lineno + 1))i\\
${indent}const/4 v4, 0x0" "$file"
            echo "Patched const/4 v4, 0x0 after move-result v4 at line $((move_lineno + 1))"
            found=1
            patched=1
            break 2
          fi
        done
      done
      [ $patched -eq 0 ] && echo "Unable to patch: No matching pattern found where patching makes sense."
    else
      echo "Pattern not found in $file"
    fi
  else
    echo "ParsingPackageUtils.smali not found"
  fi

  # Patch invoke unsafeGetCertsWithoutVerification
  echo "Patching invoke-static call for unsafeGetCertsWithoutVerification..."
  local file
  file=$(find "$decompile_dir" -type f -name "*.smali" -print0 | xargs -0 grep -l "ApkSignatureVerifier;->unsafeGetCertsWithoutVerification" 2> /dev/null | head -n 1)
  if [ -f "$file" ]; then
    local pattern="ApkSignatureVerifier;->unsafeGetCertsWithoutVerification"
    local line_numbers
    line_numbers=$(grep -n "$pattern" "$file" | cut -d: -f1)

    for lineno in $line_numbers; do
      local previous_line
      previous_line=$(sed -n "$((lineno - 1))p" "$file")
      echo "$previous_line" | grep -q "const/4 v1, 0x1" && {
        echo "Already patched above line $lineno"
        continue
      }
      sed -i "${lineno}i\\
    const/4 v1, 0x1" "$file"
      echo "Patched at line $((lineno)) in file: $file"
    done
  else
    echo "Smali file containing the target line not found"
  fi

  # Patch ApkSigningBlockUtils isEqual
  echo "Patching ApkSigningBlockUtils isEqual check..."
  local file
  file=$(find "$decompile_dir" -type f -path "*/android/util/apk/ApkSigningBlockUtils.smali" | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-static {v5, v6}, Ljava/security/MessageDigest;->isEqual([B[B)Z"
    local linenos
    linenos=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$linenos" ]; then
      for invoke_lineno in $linenos; do
        found=0
        for offset in 1 2 3; do
          move_result_lineno=$((invoke_lineno + offset))
          current_line=$(sed -n "${move_result_lineno}p" "$file" | sed 's/^[ \t]*//')
          if [[ "$current_line" == "const/4 v7, 0x1" ]]; then
            echo "Already patched line $move_result_lineno"
            found=1
            break
          fi
          if [[ "$current_line" == "move-result v7" ]]; then
            orig_indent=$(sed -n "${move_result_lineno}p" "$file" | grep -o '^[ \t]*')
            sed -i "${move_result_lineno}s|.*|${orig_indent}const/4 v7, 0x1|" "$file"
            echo "Patched move-result at line $move_result_lineno"
            found=1
            break
          fi
        done
        [ $found -eq 0 ] && echo "move-result v7 not found within 3 lines after invoke-static at line $invoke_lineno"
      done
    else
      echo "Target invoke-static line not found in $file"
    fi
  else
    echo "ApkSigningBlockUtils.smali not found"
  fi

  # Patch verifyV1Signature
  echo "Patching verifyV1Signature method only..."
  local file
  file=$(find "$decompile_dir" -type f -name "*ApkSignatureVerifier.smali" | head -n 1)
  if [ -f "$file" ]; then
    local method="verifyV1Signature"

    lines=$(grep -n "$method" "$file" | cut -d: -f1)
    if [ -n "$lines" ]; then
      for lineno in $lines; do
        line_text=$(sed -n "${lineno}p" "$file")
        echo "$line_text" | grep -q "invoke-static" || continue
        next_line=$(sed -n "$((lineno + 1))p" "$file" | grep -E "\.method|\.end method")
        [ -n "$next_line" ] && continue
        above=$((lineno - 1))
        sed -n "${above}p" "$file" | grep -q "const/4 p3, 0x0" || {
          sed -i "${lineno}i\\
    const/4 p3, 0x0" "$file"
          echo "Patched $method"
        }
      done
    else
      echo "No $method found in $file"
    fi
  else
    echo "File not found"
  fi

  # Patch ApkSignatureSchemeV2Verifier isEqual
  echo "Patching ApkSignatureSchemeV2Verifier isEqual check..."
  local file
  file=$(find "$decompile_dir" -type f -path "*/android/util/apk/ApkSignatureSchemeV2Verifier.smali" | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-static {v8, v7}, Ljava/security/MessageDigest;->isEqual([B[B)Z"
    local linenos
    linenos=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$linenos" ]; then
      for invoke_lineno in $linenos; do
        found=0
        for offset in 1 2 3; do
          move_result_lineno=$((invoke_lineno + offset))
          current_line=$(sed -n "${move_result_lineno}p" "$file" | sed 's/^[ \t]*//')
          if [[ "$current_line" == "const/4 v0, 0x1" ]]; then
            echo "Already patched line $move_result_lineno"
            found=1
            break
          fi
          if [[ "$current_line" == "move-result v0" ]]; then
            orig_indent=$(sed -n "${move_result_lineno}p" "$file" | grep -o '^[ \t]*')
            sed -i "${move_result_lineno}s|.*|${orig_indent}const/4 v0, 0x1|" "$file"
            echo "Patched move-result at line $move_result_lineno"
            found=1
            break
          fi
        done
        [ $found -eq 0 ] && echo "move-result v0 not found within 3 lines after invoke-static at line $invoke_lineno"
      done
    else
      echo "Target invoke-static line not found in $file"
    fi
  else
    echo "ApkSignatureSchemeV2Verifier.smali not found"
  fi

  # Patch ApkSignatureSchemeV3Verifier isEqual
  echo "Patching ApkSignatureSchemeV3Verifier isEqual check..."
  local file
  file=$(find "$decompile_dir" -type f -path "*/android/util/apk/ApkSignatureSchemeV3Verifier.smali" | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-static {v12, v6}, Ljava/security/MessageDigest;->isEqual([B[B)Z"
    local linenos
    linenos=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$linenos" ]; then
      for invoke_lineno in $linenos; do
        found=0
        for offset in 1 2 3; do
          move_result_lineno=$((invoke_lineno + offset))
          current_line=$(sed -n "${move_result_lineno}p" "$file" | sed 's/^[ \t]*//')
          if [[ "$current_line" == "const/4 v0, 0x1" ]]; then
            echo "Already patched line $move_result_lineno"
            found=1
            break
          fi
          if [[ "$current_line" == "move-result v0" ]]; then
            orig_indent=$(sed -n "${move_result_lineno}p" "$file" | grep -o '^[ \t]*')
            sed -i "${move_result_lineno}s|.*|${orig_indent}const/4 v0, 0x1|" "$file"
            echo "Patched move-result at line $move_result_lineno"
            found=1
            break
          fi
        done
        [ $found -eq 0 ] && echo "move-result v0 not found within 3 lines after invoke-static at line $invoke_lineno"
      done
    else
      echo "Target invoke-static line not found in $file"
    fi
  else
    echo "ApkSignatureSchemeV3Verifier.smali not found"
  fi

  # Patch PackageParserException error
  echo "Patching PackageParser\$PackageParserException error assignments..."
  local file
  file=$(find "$decompile_dir" -type f -path "*/android/content/pm/PackageParser\$PackageParserException.smali" | head -n 1)
  if [ -f "$file" ]; then
    local pattern="iput p1, p0, Landroid/content/pm/PackageParser\$PackageParserException;->error:I"
    local line_numbers
    line_numbers=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$line_numbers" ]; then
      for lineno in $line_numbers; do
        local insert_line=$((lineno - 1))
        local prev_line
        prev_line=$(sed -n "${insert_line}p" "$file")

        echo "$prev_line" | grep -q "const/4 p1, 0x0" && {
          echo "Already patched above line $lineno"
          continue
        }

        # Insert just above iput line
        sed -i "${lineno}i\\
    const/4 p1, 0x0" "$file"
        echo "Patched const/4 p1, 0x0 above line $lineno"
      done
    else
      echo "Target iput line not found in $file"
    fi
  else
    echo "PackageParser\$PackageParserException.smali not found"
  fi

  # Patch packageParser equals android
  echo "Patching parseBaseApkCommon() in PackageParser..."
  local file
  file=$(find "$decompile_dir" -type f -path "*/android/content/pm/PackageParser.smali" | head -n 1)
  if [ -f "$file" ]; then
    local start_line end_line
    start_line=$(grep -n ".method.*parseBaseApkCommon" "$file" | cut -d: -f1 | head -n 1)

    if [ -n "$start_line" ]; then
      end_line=$(tail -n +"$start_line" "$file" | grep -n ".end method" | head -n 1 | cut -d: -f1)
      end_line=$((start_line + end_line - 1))

      local move_result_line
      move_result_line=$(sed -n "${start_line},${end_line}p" "$file" | grep -n "move-result v5" | head -n 1 | cut -d: -f1)

      if [ -n "$move_result_line" ]; then
        local insert_line=$((start_line + move_result_line))

        # Check if already patched
        local next_line
        next_line=$(sed -n "$((insert_line + 1))p" "$file")
        if echo "$next_line" | grep -q "const/4 v5, 0x1"; then
          echo "Already patched at line $((insert_line + 1))"
        else
          # Insert after move-result v5
          sed -i "$((insert_line + 1))i\\
    const/4 v5, 0x1" "$file"
          echo "Correctly patched const/4 v5, 0x1 after move-result v5 at line $((insert_line + 1))"
        fi
      else
        echo "move-result v5 not found"
      fi
    else
      echo "Method parseBaseApkCommon not found"
    fi
  else
    echo "PackageParser.smali not found"
  fi

  # Patch strictjar findEntry removal
  echo "Patching StrictJarFile..."
  local file
  file=$(find "$decompile_dir" -type f -name "StrictJarFile.smali" | head -n 1)
  if [ -f "$file" ]; then
    local start_line
    start_line=$(grep -n "\->findEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;" "$file" | cut -d: -f1 | head -n 1)

    if [ -n "$start_line" ]; then
      local i=$((start_line + 1))
      local if_line=""
      local cond_label=""
      # local cond_line=""  # Currently unused but kept for future use
      local line=""

      while [ "$i" -le "$((start_line + 20))" ]; do
        line=$(sed -n "${i}p" "$file" | tr -d '\r')

        if [ -z "$if_line" ] && echo "$line" | grep -qE '^[[:space:]]*if-eqz[[:space:]]+v6,[[:space:]]+:cond_'; then
          if_line=$i
        fi

        if [ -z "$cond_label" ] && echo "$line" | grep -qE '^[[:space:]]*:cond_[0-9a-zA-Z_]+'; then
          cond_label=$(echo "$line" | grep -oE ':cond_[0-9a-zA-Z_]+')
          # cond_line=$i  # Currently unused but kept for future use
        fi

        if [ -n "$if_line" ] && [ -n "$cond_label" ]; then
          break
        fi

        i=$((i + 1))
      done

      if [ -n "$if_line" ]; then
        sed -i "${if_line}d" "$file"
        echo "Removed if-eqz jump at line $if_line."
      else
        echo "No matching if-eqz line found."
      fi

      if [ -n "$cond_label" ]; then
        # Replace label with label + nop (instead of deleting)
        sed -i "s/^[[:space:]]*${cond_label}[[:space:]]*$/    ${cond_label}\n    nop/" "$file"
        echo "Neutralized label ${cond_label} with nop."
      else
        echo "No matching :cond_ label found."
      fi

      echo "StrictJarFile patch completed."
    else
      echo "Method findEntry not found."
    fi
  else
    echo "StrictJarFile.smali not found."
  fi

  # Patch static methods with hardcoded paths (faster and no errors)
  echo "Patching verifyMessageDigest..."
  patch_method_in_file "verifyMessageDigest" 1 "$decompile_dir/smali_classes4/android/util/jar/StrictJarVerifier.smali"

  echo "Patching hasAncestorOrSelf..."
  patch_method_in_file "hasAncestorOrSelf" 1 "$decompile_dir/smali/android/content/pm/SigningDetails.smali"

  echo "Patching getMinimumSignatureSchemeVersionForTargetSdk..."
  patch_method_in_file "getMinimumSignatureSchemeVersionForTargetSdk" 0 "$decompile_dir/smali_classes4/android/util/apk/ApkSignatureVerifier.smali"

  # Patch checkCapability variants in SigningDetails
  echo "Patching checkCapability variants..."
  for file in "$decompile_dir/smali/android/content/pm/SigningDetails.smali" \
    "$decompile_dir/smali/android/content/pm/PackageParser\$SigningDetails.smali"; do
    if [ -f "$file" ]; then
      patch_method_in_file "checkCapability(Landroid/content/pm/SigningDetails;I)Z" 1 "$file"
      patch_method_in_file "checkCapability(Landroid/content/pm/PackageParser\$SigningDetails;I)Z" 1 "$file"
      patch_method_in_file "checkCapability(Ljava/lang/String;I)Z" 1 "$file"
      patch_method_in_file "checkCapabilityRecover(Landroid/content/pm/SigningDetails;I)Z" 1 "$file"
      patch_method_in_file "checkCapabilityRecover(Landroid/content/pm/PackageParser\$SigningDetails;I)Z" 1 "$file"
    fi
  done

  # Patch checkCapability String in SigningDetails
  echo "Patching checkCapability(Ljava/lang/String;I)Z in SigningDetails..."
  local method="checkCapability(Ljava/lang/String;I)Z"
  local ret_val="1"
  local class_file="SigningDetails.smali"
  local file
  file=$(find "$decompile_dir" -type f -name "$class_file" 2> /dev/null | head -n 1)

  if [ -f "$file" ]; then
    local starts
    starts=$(grep -n "^[[:space:]]*\.method.* $method" "$file" | cut -d: -f1)

    if [ -n "$starts" ]; then
      for start in $starts; do
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

        if [ "$end" -ne 0 ]; then
          local method_head method_head_escaped
          method_head=$(sed -n "${start}p" "$file")
          method_head_escaped=$(printf "%s\n" "$method_head" | sed 's/\\/\\\\/g')

          sed -i "${start},${end}c\\
$method_head_escaped\\
    .registers 8\\
    const/4 v0, 0x$ret_val\\
    return v0\\
.end method" "$file"

          echo "Patched $method to return $ret_val"
        else
          echo "End method not found for $method"
        fi
      done
    else
      echo "Method $method not found"
    fi
  else
    echo "$class_file not found"
  fi

  echo "Signature verification patches applied to framework.jar"
}

# Apply disable secure flag patches to framework.jar
apply_framework_disable_secure_flag() {
  local decompile_dir="$1"

  echo "Applying disable secure flag patches to framework.jar..."

  # Note: For Android 15, disable secure flag does not require framework.jar patches
  # Only services.jar and miui-services.jar are affected
  echo "Disable secure flag: No framework.jar patches required for Android 15"

  echo "Disable secure flag patches applied to framework.jar"
}

inject_invoke_custom_methods() {
  local decompile_dir="$1"

  echo "Applying invoke-custom methods to framework.jar..."
  cp -rf $INVOKE_DIR/* "$decompile_dir/smali_classes2"
  echo "Invoke-custom methods applied to framework.jar"

}


# Main framework patching function
patch_framework() {
  local framework_path="$work_dir/build/baserom/images/system/system/framework/framework.jar"
  local decompile_dir="$work_dir/framework_decompile"

  echo "Starting framework patch..."

  # Decompile framework.jar
  decompile_jar "$framework_path"

  # Apply invoke-custom patches (common to all features)
  modify_invoke_custom_methods "$decompile_dir"

  # Apply feature-specific patches based on flags
  apply_framework_signature_patches "$decompile_dir"



  # Recompile framework.jar
  recompile_jar "$framework_path"

  # Clean up
  rm -rf "$WORK_DIR/framework" "$decompile_dir"

  if [ ! -f "framework_patched.jar" ]; then
    err "Critical Error: framework_patched.jar was not created."
    return 1
  fi

  echo "Framework patching completed."
}

# ============================================
# Feature-specific patch functions for services.jar
# ============================================

# Apply signature verification bypass patches to services.jar
apply_services_signature_patches() {
  local decompile_dir="$1"

  echo "Applying signature verification patches to services.jar..."

  # Patch methods with hardcoded paths (faster and no errors)
  echo "Patching checkDowngrade..."
  patch_return_void_in_file "checkDowngrade" "$decompile_dir/smali_classes2/com/android/server/pm/PackageManagerServiceUtils.smali"

  # Patch service InstallPackageHelper equals
  echo "Patching equals() result in InstallPackageHelper..."
  local file
  file=$(find "$decompile_dir" -type f -path "*/com/android/server/pm/InstallPackageHelper.smali" | head -n 1)
  if [ -f "$file" ]; then
    local pattern="invoke-virtual {v5, v9}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z"
    local linenos
    linenos=$(grep -nF "$pattern" "$file" | cut -d: -f1)

    if [ -n "$linenos" ]; then
      for invoke_lineno in $linenos; do
        found=0
        for offset in 1 2 3; do
          move_result_lineno=$((invoke_lineno + offset))
          current_line=$(sed -n "${move_result_lineno}p" "$file" | sed 's/^[ \t]*//')
          if [[ "$current_line" == "const/4 v12, 0x1" ]]; then
            echo "Already patched at line $move_result_lineno"
            found=1
            break
          fi
          if [[ "$current_line" == "move-result v12" ]]; then
            # Check if next line already is const/4 v12, 0x1
            next_content=$(sed -n "$((move_result_lineno + 1))p" "$file" | sed 's/^[ \t]*//')
            if [[ "$next_content" == "const/4 v12, 0x1" ]]; then
              echo "Already patched just after move-result at line $((move_result_lineno + 1))"
              found=1
              break
            fi
            indent=$(sed -n "${move_result_lineno}p" "$file" | grep -o '^[ \t]*')
            sed -i "$((move_result_lineno + 1))i\\
${indent}const/4 v12, 0x1" "$file"
            echo "Patched const/4 v12, 0x1 after move-result v12 at line $((move_result_lineno + 1))"
            found=1
            break
          fi
        done
        [ $found -eq 0 ] && echo "move-result v12 not found within 3 lines after invoke-virtual at line $invoke_lineno"
      done
    else
      echo "Target invoke-virtual line not found in $file"
    fi
  else
    echo "InstallPackageHelper.smali not found in services jar"
  fi

  # Patch service ReconcilePackageUtils clinit
  echo "Patching <clinit>() in ReconcilePackageUtils..."
  local file
  file=$(find "$decompile_dir" -type f -path "*/com/android/server/pm/ReconcilePackageUtils.smali" | head -n 1)
  if [ -f "$file" ]; then
    local start_line end_line
    # Find the line number of the static constructor start
    start_line=$(grep -nF ".method static constructor <clinit>()V" "$file" | cut -d: -f1 | head -n 1)
    # Find the line number of the end of the method starting from start_line
    end_line=$(awk "NR>$start_line && /\\.end method/ {print NR; exit}" "$file")

    if [ -n "$start_line" ] && [ -n "$end_line" ]; then
      # Search for const/4 v0, 0x0 inside the method and patch if found
      local const_line
      const_line=$(awk "NR>$start_line && NR<$end_line && /const\\/4 v0, 0x0/ {print NR; exit}" "$file")
      if [ -n "$const_line" ]; then
        local content
        content=$(sed -n "${const_line}p" "$file")
        if [[ "$content" == *"0x1"* ]]; then
          echo "Already patched at line $const_line"
        else
          sed -i "${const_line}s/const\\/4 v0, 0x0/const\\/4 v0, 0x1/" "$file"
          echo "Patched const/4 v0, 0x1 at line $const_line"
        fi
      else
        echo "const/4 v0, 0x0 not found inside <clinit> in $file"
      fi
    else
      echo "<clinit> method not found properly in $file"
    fi
  else
    echo "ReconcilePackageUtils.smali not found in services jar"
  fi

  # Patch static methods with hardcoded paths
  echo "Patching shouldCheckUpgradeKeySetLocked..."
  patch_method_in_file "shouldCheckUpgradeKeySetLocked" 0 "$decompile_dir/smali_classes2/com/android/server/pm/KeySetManagerService.smali"

  echo "Patching verifySignatures..."
  patch_method_in_file "verifySignatures" 0 "$decompile_dir/smali_classes2/com/android/server/pm/PackageManagerServiceUtils.smali"

  echo "Patching matchSignaturesCompat..."
  patch_method_in_file "matchSignaturesCompat" 1 "$decompile_dir/smali_classes2/com/android/server/pm/PackageManagerServiceUtils.smali"

  # echo "Patching compareSignatures..."
  # patch_method_in_file "compareSignatures" 0 "$decompile_dir/smali_classes2/com/android/server/pm/PackageManagerServiceUtils.smali"

  echo "Signature verification patches applied to services.jar"
}

# Apply disable secure flag patches to services.jar
apply_services_disable_secure_flag() {
  local decompile_dir="$1"

  echo "Applying disable secure flag patches to services.jar..."

  # Android 15: Patch WindowState.isSecureLocked()
  echo "Patching WindowState.isSecureLocked()..."
  local method_body="    .registers 6\n\n    const/4 v0, 0x0\n\n    return v0"
  replace_entire_method "isSecureLocked()Z" "$decompile_dir" "$method_body" "com/android/server/wm/WindowState"

  echo "Disable secure flag patches applied to services.jar"
}


# Main services patching function
patch_services() {
  local services_path="$work_dir/build/baserom/images/system/system/framework/services.jar"
  local decompile_dir="$WORK_DIR/services_decompile"

  echo "Starting services.jar patch..."

  # Decompile services.jar
  decompile_jar "$services_path"

  # Apply feature-specific patches based on flags
  apply_services_signature_patches "$decompile_dir"

  # Modify invoke-custom methods (common to all features)
  modify_invoke_custom_methods "$decompile_dir"

  # Recompile services.jar
  recompile_jar "$services_path"

  # Clean up
  rm -rf "$WORK_DIR/services" "$decompile_dir"

  if [ ! -f "services_patched.jar" ]; then
    err "Critical Error: services_patched.jar was not created."
    return 1
  fi

  echo "Services.jar patching completed."
}

# ============================================
# Feature-specific patch functions for miui-services.jar
# ============================================

# Apply signature verification bypass patches to miui-services.jar
apply_miui_services_signature_patches() {
  local decompile_dir="$1"

  echo "Applying signature verification patches to miui-services.jar..."

  # Patch methods with hardcoded paths (faster and no errors)
  echo "Patching canBeUpdate..."
  patch_return_void_in_file "canBeUpdate" "$decompile_dir/smali/com/android/server/pm/PackageManagerServiceImpl.smali"

  echo "Patching verifyIsolationViolation..."
  patch_return_void_in_file "verifyIsolationViolation" "$decompile_dir/smali/com/android/server/pm/PackageManagerServiceImpl.smali"

  echo "Signature verification patches applied to miui-services.jar"
}

# Apply Gboard patches
apply_miui_services_gboard() {
  local decompile_dir="$1"

  # Add Gboard
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/server/devicepolicy/DevicePolicyManagerServiceStubImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/server/input/InputManagerServiceStubImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/server/inputmethod/InputMethodManagerServiceImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/server/wm/ActivityTaskSupervisorImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/server/wm/MiuiSplitInputMethodImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/miui/server/security/AppBehaviorService.smali"

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

# Apply disable secure flag patches to miui-services.jar
apply_miui_services_disable_secure_flag() {
  local decompile_dir="$1"

  echo "Applying disable secure flag patches to miui-services.jar..."

  # Android 15: Patch WindowManagerServiceImpl.notAllowCaptureDisplay()
  echo "Patching WindowManagerServiceImpl.notAllowCaptureDisplay()..."
  local method_body="    .registers 9\n\n    const/4 v0, 0x0\n\n    return v0"
  replace_entire_method "notAllowCaptureDisplay(Lcom/android/server/wm/RootWindowContainer;I)Z" "$decompile_dir" "$method_body" "com/android/server/wm/WindowManagerServiceImpl"

  echo "Disable secure flag patches applied to miui-services.jar"
}

# Main miui-services patching function
patch_miui_services() {
  local miui_services_path="$work_dir/build/baserom/images/system_ext/framework/miui-services.jar"
  local decompile_dir="$WORK_DIR/miui-services_decompile"

  echo "Starting miui-services.jar patch..."

  # Decompile miui-services.jar
  decompile_jar "$miui_services_path"

  # Apply feature-specific patches based on flags
  apply_miui_services_signature_patches "$decompile_dir"
  apply_miui_services_gboard "$decompile_dir"
  apply_miui_services_floating "$decompile_dir"
  apply_miui_services_contentextension "$decompile_dir"

  # Modify invoke-custom methods (common to all features)
  modify_invoke_custom_methods "$decompile_dir"

  # Recompile miui-services.jar
  recompile_jar "$miui_services_path"

  # Clean up
  rm -rf "$WORK_DIR/miui-services" "$decompile_dir"

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
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/android/view/inputmethod/InputMethodManagerStubImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/com/android/internal/os/AnrEnhanceImpl.smali"
  sed -i 's/com.baidu.input_mi/com.google.android.inputmethod.latin/g' "$decompile_dir/smali/miui/util/HapticFeedbackUtil.smali"

  echo "Gboard patches applied to miui-framework.jar"
}

# Main miui-framework patching function
patch_miui_framework() {
  local miui_framework_path="$work_dir/build/baserom/images/system_ext/framework/miui-framework.jar"
  local decompile_dir="$WORK_DIR/miui-framework_decompile"

  echo "Starting miui-framework.jar patch..."

  # Decompile miui-framework.jar
  decompile_jar "$miui_framework_path"

  # Add Gboard
  apply_miui_framework_gboard "$decompile_dir"

  # Modify invoke-custom methods (common to all features)
  modify_invoke_custom_methods "$decompile_dir"

  # Recompile miui-framework.jar
  recompile_jar "$miui_framework_path"

  # Clean up
  rm -rf "$WORK_DIR/miui-framework" "$decompile_dir"

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
