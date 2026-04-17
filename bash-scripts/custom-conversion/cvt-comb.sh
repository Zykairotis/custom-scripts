#!/bin/bash

#
# Combines all .txt files within a directory structure into folder-wise summary files.
#

# --- Default Configuration ---
DEFAULT_INPUT_DIR="."
DEFAULT_OUTPUT_DIR="combined_output"
DEFAULT_FILE_PATTERN="*.txt"

# --- Help Message ---
usage() {
    echo "Usage: $0 [OPTIONS] [INPUT_DIRECTORY]"
    echo
    echo "Combines .txt files from a directory structure into folder-wise summary files."
    echo
    echo "Arguments:"
    echo "  INPUT_DIRECTORY      The directory to process. Defaults to the current directory."
    echo
    echo "Options:"
    echo "  -o, --output DIR     Set the output directory. Defaults to '${DEFAULT_OUTPUT_DIR}'."
    echo "  -p, --pattern PATT   Set the file search pattern. Defaults to '${DEFAULT_FILE_PATTERN}'."
    echo "  -h, --help           Display this help message and exit."
    echo "  -s, --silent         Suppress all informational output."
    echo
    echo "Examples:"
    echo "  # Process the current directory"
    echo "  $0"
    echo
    echo "  # Process a specific directory"
    echo "  $0 /path/to/your/files"
    echo
    echo "  # Set a custom output directory"
    echo "  $0 -o ./my-combined-files"
    exit 0
}

# --- Argument Parsing ---
INPUT_DIR=""
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
FILE_PATTERN="$DEFAULT_FILE_PATTERN"
SILENT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -p|--pattern)
            FILE_PATTERN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -s|--silent)
            SILENT=true
            shift
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            usage
            exit 1
            ;;
        *)
            if [ -n "$INPUT_DIR" ]; then
                echo "Error: Multiple input directories specified." >&2
                usage
                exit 1
            fi
            INPUT_DIR="$1"
            shift
            ;;
    esac
done

# If no input directory was provided as a positional argument, use the default.
if [ -z "$INPUT_DIR" ]; then
    INPUT_DIR="$DEFAULT_INPUT_DIR"
fi

# --- Logging Function ---
log() {
    if [ "$SILENT" = false ]; then
        echo "$1"
    fi
}

# --- Validation ---
if [ ! -d "$INPUT_DIR" ]; then
    log "Error: Input directory '${INPUT_DIR}' not found."
    exit 1
fi

# Resolve absolute paths to prevent issues with relative paths
OUTPUT_DIR_ABS=$(realpath "$OUTPUT_DIR")
INPUT_DIR_ABS=$(realpath "$INPUT_DIR")

if [ "$INPUT_DIR_ABS" = "$OUTPUT_DIR_ABS" ] || [[ "$OUTPUT_DIR_ABS" == "$INPUT_DIR_ABS"/* ]]; then
    log "Error: The output directory cannot be the same as or inside the input directory."
    exit 1
fi

# --- Main Logic ---
mkdir -p "$OUTPUT_DIR"
log "Output will be saved in '${OUTPUT_DIR}'"

# --- Process Subdirectories ---
find "$INPUT_DIR" -mindepth 1 -maxdepth 1 -type d -not -path "$OUTPUT_DIR/*" | while read -r SUBDIR; do
    DIR_NAME=$(basename "$SUBDIR")
    OUTPUT_FILE="${OUTPUT_DIR}/${DIR_NAME}.txt"
    
    # Check if any matching files exist before creating the output file
    if [ -n "$(find "$SUBDIR" -type f -name "$FILE_PATTERN")" ]; then
        log "Processing '${DIR_NAME}' directory..."
        # Ensure the output file is empty before writing
        > "$OUTPUT_FILE"
        
        find "$SUBDIR" -type f -name "$FILE_PATTERN" | sort | while read -r FILE; do
            RELATIVE_PATH=$(realpath --relative-to="$INPUT_DIR" "$FILE")
            
            echo "--- ${RELATIVE_PATH} ---" >> "$OUTPUT_FILE"
            cat "$FILE" >> "$OUTPUT_FILE"
            echo -e "\n" >> "$OUTPUT_FILE"
        done
    fi
done

# --- Process Root Files ---
ROOT_OUTPUT_FILE="${OUTPUT_DIR}/root.txt"
# Use a temporary file to avoid issues if the script is run on its own output
ROOT_TEMP_FILE=$(mktemp)

# Find all matching files in the root of the input directory
find "$INPUT_DIR" -maxdepth 1 -type f -name "$FILE_PATTERN" | sort | while read -r FILE; do
    FILENAME=$(basename "$FILE")
    
    echo "--- ${FILENAME} ---" >> "$ROOT_TEMP_FILE"
    cat "$FILE" >> "$ROOT_TEMP_FILE"
    echo -e "\n" >> "$ROOT_TEMP_FILE"
done

# If the temporary file has content, move it to the final output file
if [ -s "$ROOT_TEMP_FILE" ]; then
    log "Processing root files..."
    mv "$ROOT_TEMP_FILE" "$ROOT_OUTPUT_FILE"
else
    rm "$ROOT_TEMP_FILE"
fi

log "Combination complete."
