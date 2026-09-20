#!/usr/bin/env bash
work_dir=$(pwd)
# Main functions
SCRIPT_DIR="$work_dir/bin/package/COREPATCH"
source "${SCRIPT_DIR}/patching.sh"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/tools.sh"
source "${SCRIPT_DIR}/apk_ops.sh"
