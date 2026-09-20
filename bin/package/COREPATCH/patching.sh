#!/usr/bin/env bash
# scripts/core/patching.sh
# Smali patching functions

remove_storage_restricted() {
  local decompile_dir="$1"
  find "$decompile_dir" -type f -name "ExternalStorageProvider.smali" \
    | while IFS= read -r file; do
      patch_method_in_file "isRestrictedPath(Ljava/lang/String;Ljava/lang/String;)Z" 0 "$file"
    done
}

add_static_return_patch() {
  local method="$1"
  local ret_val="$2" # expect hex nibble w/o 0x OR decimal (we assume hex nibble for const/4 usage)
  local decompile_dir="$3"
  local file

  [ -z "$method" ] || true
  [ -z "$decompile_dir" ] && {
    err "add_static_return_patch: missing decompile_dir"
    return 1m
  }

  file=$(find_smali_method_file "$decompile_dir" "$method")
  [ -z "$file" ] && {
    warn "Method $method not found in $decompile_dir"
    return 0
  }

  local start
  start=$(grep -n "^[[:space:]]*\.method.* ${method}" "$file" | cut -d: -f1 | head -n1)
  [ -z "$start" ] && {
    warn "Method $method start not found"
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
    warn "End not found for $method in $file"
    return 0
  }

  local method_head
  method_head=$(sed -n "${start}p" "$file")
  method_head_escaped=$(printf "%s\n" "$method_head" | sed 's/\\/\\\\/g')

  # Replace method body with a simple const/return
  sed -i "${start},${end}c\\
$method_head_escaped\\
    .registers 8\\
    const/4 v0, 0x${ret_val}\\
    return v0\\
.end method" "$file"

  log "Patched $method in $file to return 0x${ret_val}"
}

patch_return_void_method() {
  local method="$1"
  local decompile_dir="$2"
  local file

  [ -z "$decompile_dir" ] && {
    err "patch_return_void_method: missing decompile_dir"
    return 1
  }

  file=$(find_smali_method_file "$decompile_dir" "$method")
  [ -z "$file" ] && {
    warn "Method $method not found in $decompile_dir"
    return 0
  }

  local start
  start=$(grep -n "^[[:space:]]*\.method.* ${method}" "$file" | cut -d: -f1 | head -n1)
  [ -z "$start" ] && {
    warn "Method $method start not found"
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
    warn "Method $method end not found"
    return 0
  }

  local method_head
  method_head=$(sed -n "${start}p" "$file")
  method_head_escaped=$(printf "%s\n" "$method_head" | sed 's/\\/\\\\/g')

  sed -i "${start},${end}c\\
$method_head_escaped\\
    .registers 8\\
    return-void\\
.end method" "$file"

  log "Patched $method in $file to return-void"
}

modify_invoke_custom_methods() {
  local decompile_dir="$1"
  echo "Checking for invoke-custom in $decompile_dir..."

  # Use find with + instead of \; to batch files and suppress all grep errors
  local smali_files
  # Redirect both stdout and stderr, and use || true to prevent failures
  smali_files=$(find "$decompile_dir" -type f -name "*.smali" 2> /dev/null | while read -r f; do
    if [ -f "$f" ] && grep -s -q "invoke-custom" "$f" 2> /dev/null; then
      echo "$f"
    fi
  done)

  [ -z "$smali_files" ] && {
    log "No invoke-custom found"
    return 0
  }

  local count=0
  while IFS= read -r smali_file; do
    # Skip if file doesn't exist (extra safety check)
    [ ! -f "$smali_file" ] && continue

    count=$((count + 1))

    # equals
    sed -i "/.method.*equals(/,/^.end method$/ {
            /^    .registers/c\\    .registers 2
            /^    invoke-custom/d
            /^    move-result/d
            /^    return/c\\    const/4 v0, 0x0\\n\\n    return v0
        }" "$smali_file" 2> /dev/null || true

    # hashCode
    sed -i "/.method.*hashCode(/,/^.end method$/ {
            /^    .registers/c\\    .registers 2
            /^    invoke-custom/d
            /^    move-result/d
            /^    return/c\\    const/4 v0, 0x0\\n\\n    return v0
        }" "$smali_file" 2> /dev/null || true

    # toString
    sed -i "/.method.*toString(/,/^.end method$/ {
            s/^[[:space:]]*\\.registers.*/    .registers 1/
            /^    invoke-custom/d
            /^    move-result.*/d
            /^    return.*/c\\    const/4 v0, 0x0\\n\\n    return-object v0
        }" "$smali_file" 2> /dev/null || true
  done <<< "$smali_files"

  if [ "$count" -gt 0 ]; then
    log "Modified $count files with invoke-custom"
  else
    log "No invoke-custom found"
  fi
}

patch_return_void_methods_all() {
  local method_name="$1"
  local decompile_dir="$2"

  [ -z "$decompile_dir" ] && {
    err "patch_return_void_methods_all: missing decompile_dir"
    return 1
  }

  # Find all files containing the method
  local files
  files=$(find "$decompile_dir" -type f -name "*.smali" -exec grep -s -l "^[[:space:]]*\\.method.*${method_name}" {} + 2> /dev/null || true)

  [ -z "$files" ] && {
    warn "No occurrences of ${method_name} found in $decompile_dir"
    return 0
  }

  local file
  for file in $files; do
    # Patch each occurrence within the file
    # We iterate from bottom to top to keep line numbers stable
    local starts
    starts=$(grep -n "^[[:space:]]*\\.method.*${method_name}" "$file" | cut -d: -f1 | sort -nr)
    [ -z "$starts" ] && continue

    local start end total_lines i line method_head method_head_escaped
    total_lines=$(wc -l < "$file")

    for start in $starts; do
      end=0
      i="$start"
      while [ "$i" -le "$total_lines" ]; do
        line=$(sed -n "${i}p" "$file")
        [[ "$line" == *".end method"* ]] && {
          end="$i"
          break
        }
        i=$((i + 1))
      done
      [ "$end" -eq 0 ] && {
        warn "End not found for ${method_name} in $file (start $start)"
        continue
      }

      method_head=$(sed -n "${start}p" "$file")
      method_head_escaped=$(printf "%s\n" "$method_head" | sed 's/\\/\\\\/g')

      sed -i "${start},${end}c\\
${method_head_escaped}\\
    .registers 8\\
    return-void\\
.end method" "$file"
    done

    log "Patched all ${method_name} overloads in $(basename "$file") to return-void"
  done

  return 0
}

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

patch_smali_method_in_file() {
  local method="$1"
  local inject_code="$2"
  local file="$3"

  [ ! -f "$file" ] && {
    echo "⚠️ File not found: $(basename "$file")"
    return
  }

  # find method
  local start
  start=$(grep -n "^[[:space:]]*\.method.* $method" "$file" | cut -d: -f1 | head -n1)
  [ -z "$start" ] && {
    echo "⚠️ Method $method not found in $(basename "$file")"
    return
  }

  # find end
  local total end=0 i="$start"
  total=$(wc -l < "$file")
  while [ "$i" -le "$total" ]; do
    [[ "$(sed -n "${i}p" "$file")" == *".end method"* ]] && {
      end="$i"
      break
    }
    i=$((i + 1))
  done
  [ "$end" -eq 0 ] && {
    echo "⚠️ .end method not found"
    return
  }

  # find registers/locals
  local rel
  rel=$(sed -n "${start},${end}p" "$file" \
    | grep -nE "^[[:space:]]*\.(registers|locals)" \
    | head -n1 | cut -d: -f1)

  [ -z "$rel" ] && {
    echo "⚠️ No .registers/.locals"
    return
  }

  local inject_line=$((start + rel - 1))

  # inject từng dòng
  while IFS= read -r line; do
    sed -i "${inject_line}a\\
$line" "$file"
    inject_line=$((inject_line + 1))
  done <<< "$inject_code"

  echo "✓ Injected code into $method in $(basename "$file")"
}

replace_line_contains_in_smali_method() {
  local keyword="$1"
  local method="$2"
  local replace_line="$3"
  local file="$4"

  [ ! -f "$file" ] && {
    echo "⚠️ File not found: $(basename "$file")"
    return 1
  }

  # find method start
  local start
  start=$(grep -n "^[[:space:]]*\.method.* $method" "$file" | cut -d: -f1 | head -n1)
  [ -z "$start" ] && {
    echo "⚠️ Method $method not found in $(basename "$file")"
    return 1
  }

  # find method end
  local total end=0 i="$start"
  total=$(wc -l < "$file")
  while [ "$i" -le "$total" ]; do
    [[ "$(sed -n "${i}p" "$file")" == *".end method"* ]] && {
      end="$i"
      break
    }
    i=$((i + 1))
  done

  [ "$end" -eq 0 ] && {
    echo "⚠️ .end method not found for $method"
    return 1
  }

  # find line CONTAINING keyword inside method
  local rel
  rel=$(sed -n "${start},${end}p" "$file" \
    | grep -n "$keyword" | head -n1 | cut -d: -f1)

  [ -z "$rel" ] && {
    echo "⚠️ No line containing '$keyword' in method $method"
    return 1
  }

  local real_line=$((start + rel - 1))

  # replace whole line
  sed -i "${real_line}c\\
$replace_line" "$file"

  echo "✓ Replaced line containing '$keyword' in $method ($(basename "$file"))"
}

patch_smali_after_keyword() {
  local method="$1"
  local keyword="$2"
  local inject_code="$3"
  local file="$4"

  [ ! -f "$file" ] && {
    echo "⚠️ File not found: $(basename "$file")"
    return
  }

  # 1️⃣ Tìm dòng bắt đầu method
  local start
  start=$(grep -n "^[[:space:]]*\.method.* $method" "$file" | cut -d: -f1 | head -n1)

  [ -z "$start" ] && {
    echo "⚠️ Method $method not found in $(basename "$file")"
    return
  }

  # 2️⃣ Tìm .end method
  local total end=0 i="$start"
  total=$(wc -l < "$file")

  while [ "$i" -le "$total" ]; do
    if [[ "$(sed -n "${i}p" "$file")" == *".end method"* ]]; then
      end="$i"
      break
    fi
    i=$((i + 1))
  done

  [ "$end" -eq 0 ] && {
    echo "⚠️ .end method not found"
    return
  }

  # 3️⃣ Tìm dòng chứa keyword trong phạm vi method
  local rel
  rel=$(sed -n "${start},${end}p" "$file" \
    | grep -n "$keyword" \
    | head -n1 | cut -d: -f1)

  [ -z "$rel" ] && {
    echo "⚠️ Keyword '$keyword' not found in $method"
    return
  }

  local inject_line=$((start + rel - 1))

  # 4️⃣ Inject từng dòng sau keyword
  while IFS= read -r line; do
    sed -i "${inject_line}a\\
$line" "$file"
    inject_line=$((inject_line + 1))
  done <<< "$inject_code"

  echo "✓ Injected after '$keyword' in $method ($(basename "$file"))"
}

delete_lines_in_smali_method() {
  local method="$1"
  local from_line="$2"
  local to_line="$3"
  local file="$4"

  [ ! -f "$file" ] && {
    echo "⚠️ File not found: $(basename "$file")"
    return 1
  }

  # Tìm dòng bắt đầu method
  local start
  start=$(grep -n "^[[:space:]]*\.method.* $method" "$file" | cut -d: -f1 | head -n1)

  [ -z "$start" ] && {
    echo "⚠️ Method $method not found in $(basename "$file")"
    return 1
  }

  # Tìm dòng kết thúc method
  local total end=0 i="$start"
  total=$(wc -l < "$file")

  while [ "$i" -le "$total" ]; do
    if [[ "$(sed -n "${i}p" "$file")" == *".end method"* ]]; then
      end="$i"
      break
    fi
    i=$((i + 1))
  done

  [ "$end" -eq 0 ] && {
    echo "⚠️ .end method not found"
    return 1
  }

  # Kiểm tra hợp lệ
  if [ "$from_line" -lt 1 ] || [ "$to_line" -lt "$from_line" ]; then
    echo "⚠️ Invalid line range"
    return 1
  fi

  # Tính vị trí thực tế trong file
  local real_start=$((start + from_line))
  local real_end=$((start + to_line))

  # Không cho xóa vượt .end method
  if [ "$real_end" -ge "$end" ]; then
    real_end=$((end - 1))
  fi

  # Thực hiện xóa
  sed -i "${real_start},${real_end}d" "$file"

  echo "✓ Deleted lines $from_line → $to_line inside $method in $(basename "$file")"
}
