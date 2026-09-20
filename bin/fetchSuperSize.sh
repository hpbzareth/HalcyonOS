WORK_DIR=$(pwd)
# Declare an associative array of codenames and their corresponding values
declare -A CODENAME_VALUES=(
    ["MARBLE"]="10021466112"
    ["SPESGlobal"]="9126805504"
)

# Check if a codename was provided as an argument
if [ $# -eq 0 ]; then
    echo "Error: Please provide a codename"
    exit 1
fi

# Get the codename from the first argument
CODENAME=$1

# Check if the codename exists in the array
if [[ -n "${CODENAME_VALUES[$CODENAME]}" ]]; then
    # Print the value
    echo "${CODENAME_VALUES[$CODENAME]}" > $WORK_DIR/bin/ddevice/superSize.txt
else
    # Default value if codename not found
    echo "10021466112" > $WORK_DIR/bin/ddevice/superSize.txt
fi