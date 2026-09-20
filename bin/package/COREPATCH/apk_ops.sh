#!/usr/bin/env bash
work_dir=$(pwd)
# APK/JAR manipulation functions
TOOLS_DIR="$work_dir/bin/apktool"
WORK_DIR="$work_dir"
BACKUP_DIR="$WORK_DIR/backup"
SCRIPT_DIR="$work_dir/bin/package/COREPATCH"

decompile_apk() {
  local apk_file="$1"
  local base_name
  base_name="$(basename "$apk_file" .apk)"
  local output_dir="$WORK_DIR/${base_name}_decompile"

  echo "Decompiling $apk_file with apkeditor..."

  # Validate apk file before processing
  if [ ! -f "$apk_file" ]; then
    echo "Error: apk file $apk_file not found!"
    exit 1
  fi

  rm -rf "$output_dir"

  # Run apkeditor
  if ! java -jar "$TOOLS_DIR/apkeditor.jar" d -i "$apk_file" -o "$output_dir"; then
    echo "Error: Failed to decompile $apk_file with apkeditor"
    exit 1
  fi
}

recompile_apk() {
  local apk_file="$1"
  local base_name
  base_name="$(basename "$apk_file" .apk)"
  local output_dir="$WORK_DIR/${base_name}_decompile"
  local patched_apk="${base_name}_patched.apk"

  echo "Recompiling $apk_file with apkeditor..."

  # Check if decompiled directory exists
  if [ ! -d "$output_dir" ]; then
    echo "Error: Decompiled directory $output_dir not found!"
    echo "This means the decompilation step failed."
    exit 1
  fi

  java -jar "$TOOLS_DIR/redivision.jar" "$output_dir" apk

  # Run apkeditor
  if ! java -jar "$TOOLS_DIR/apkeditor.jar" b -i "$output_dir" -o "$patched_apk"; then
    echo "Error: Failed to recompile $output_dir with apkeditor"
    exit 1
  fi
}

backup_original_jar() {
  local jar_file="$1"
  local base_name
  base_name=$(basename "$jar_file" .jar)
  mkdir -p "$BACKUP_DIR/$base_name"
  # Save META-INF and res if present (silently ignore missing)
  unzip -o "$jar_file" "META-INF/*" "res/*" -d "$BACKUP_DIR/$base_name" > /dev/null 2>&1 || true
  # Also copy whole jar for safety
  cp -a "$jar_file" "$BACKUP_DIR/${base_name}.orig.jar"
  log "Backed up $jar_file -> $BACKUP_DIR/$base_name"
}

# Decompile JAR using baksmali v2
# Uses API_LEVEL if set (e.g. API_LEVEL=33 for Android 13)
decompile_jar() {
  local jar_file="$1"
  local base_name
  base_name=$(basename "$jar_file" .jar)
  local output_dir="${WORK_DIR}/${base_name}_decompile"
  local api_flag=""
  [ -n "${API_LEVEL:-}" ] && api_flag="--api $API_LEVEL"

  log "Decompiling $jar_file -> $output_dir (baksmali v2)"

  # Validate JAR file
  if [ ! -f "$jar_file" ]; then
    err "JAR file $jar_file not found!"
    return 1
  fi

  # Check if JAR file is valid ZIP
  if ! unzip -t "$jar_file" > /dev/null 2>&1; then
    err "$jar_file is corrupted or not a valid ZIP file!"
    return 1
  fi

  rm -rf "$output_dir" > /dev/null 2>&1 || true
  mkdir -p "$output_dir"

  backup_original_jar "$jar_file"

  # Extract all JAR contents
  unzip -o "$jar_file" -d "$output_dir" > /dev/null 2>&1

  # Disassemble each DEX file with baksmali v2
  for dex in "$output_dir"/*.dex; do
    [ -f "$dex" ] || continue
    local dex_name
    dex_name=$(basename "$dex" .dex)
    local smali_dir
    if [ "$dex_name" = "classes" ]; then
      smali_dir="$output_dir/smali"
    else
      # classes2 -> smali_classes2, classes3 -> smali_classes3, etc.
      smali_dir="$output_dir/smali_${dex_name}"
    fi

    java -jar "$TOOLS_DIR/baksmaliv2.jar" d $api_flag "$dex" -o "$smali_dir" || {
      err "baksmali failed to disassemble $(basename "$dex")"
      return 1
    }
    # Remove original DEX after successful disassembly
    [ -d "$smali_dir" ] && rm -f "$dex"
  done

  log "Decompile finished: $output_dir"

  # Provide compatibility symlinks (classes -> smali, classesN -> smali_classesN)
  if [ -d "$output_dir/smali" ] && [ ! -e "$output_dir/classes" ]; then
    ln -s "smali" "$output_dir/classes" 2>/dev/null || true
  fi
  for n in 2 3 4 5 6 7 8 9; do
    if [ -d "$output_dir/smali_classes${n}" ] && [ ! -e "$output_dir/classes${n}" ]; then
      ln -s "smali_classes${n}" "$output_dir/classes${n}" 2>/dev/null || true
    fi
  done

  echo "$output_dir"
}

# Recompile JAR using smali v2
# Uses API_LEVEL if set (e.g. API_LEVEL=33 for Android 13)
recompile_jar() {
  local jar_file="$1" # original jar file path (used only for name)
  local base_name
  base_name=$(basename "$jar_file" .jar)
  local output_dir="${WORK_DIR}/${base_name}_decompile"
  local patched_jar="${base_name}_patched.jar"
  local api_flag=""
  [ -n "${API_LEVEL:-}" ] && api_flag="--api $API_LEVEL"

  log "Recompiling $output_dir -> $patched_jar (smali v2)"
  if [ ! -d "$output_dir" ]; then
    err "Recompile failed: decompile dir not found: $output_dir"
    return 1
  fi

  java -jar "$TOOLS_DIR/redivision.jar" "$output_dir" jar 2>/dev/null || true

  # Remove compatibility symlinks before assembly
  for link in "$output_dir/classes" "$output_dir"/classes[0-9]*; do
    [ -L "$link" ] && rm -f "$link"
  done

  # Reassemble each smali directory -> DEX
  for smali_dir in "$output_dir"/smali "$output_dir"/smali_classes*; do
    [ -d "$smali_dir" ] || continue
    local dir_name
    dir_name=$(basename "$smali_dir")
    local dex_name
    if [ "$dir_name" = "smali" ]; then
      dex_name="classes.dex"
    else
      # smali_classes2 -> classes2.dex
      dex_name="${dir_name#smali_}.dex"
    fi

    java -jar "$TOOLS_DIR/smaliv2.jar" a $api_flag "$smali_dir" -o "$output_dir/$dex_name" || {
      err "smali failed to assemble $dir_name"
      return 1
    }
    # Remove smali dir after successful assembly
    [ -f "$output_dir/$dex_name" ] && rm -rf "$smali_dir"
  done

  # Remove apktool artifacts if leftover from previous runs
  rm -f "$output_dir/apktool.yml" 2>/dev/null || true

  # Create JAR (uncompressed ZIP) - try 7z first, fall back to zip
  rm -f "$WORK_DIR/$patched_jar" 2>/dev/null || true
  if command -v 7z > /dev/null 2>&1; then
    (cd "$output_dir" && 7z a -tzip -mx=0 "$WORK_DIR/$patched_jar" . > /dev/null 2>&1) || {
      err "7z failed to create JAR archive"
      return 1
    }
  else
    (cd "$output_dir" && zip -r -0 "$WORK_DIR/$patched_jar" . > /dev/null 2>&1) || {
      err "zip failed to create JAR archive"
      return 1
    }
  fi

  java -jar "$TOOLS_DIR/timestamp.jar" "$patched_jar" 1199145600

  log "Created patched JAR: $patched_jar"
  echo "$patched_jar"
}
