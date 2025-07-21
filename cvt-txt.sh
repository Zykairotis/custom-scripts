#!/usr/bin/env bash
set -euo pipefail

########################################
# Defaults
########################################
INPUT_DIR='.'
OUTPUT_DIR='output'
INCLUDE_PATTERNS=()      # shell globs, e.g. *.py *.md
EXCLUDE_PATTERNS=()      # shell globs, e.g. *.log node_modules/*
DRYRUN=false
LOGFILE="conversion.log"

########################################
# Usage
########################################
usage() {
  cat <<EOF
Usage: $0 [options]

Options
  --input DIR         Source directory (default ".")
  --output DIR        Destination directory (default "output")
  --include  PATTERN  Include only matching glob(s)   (repeatable)
  --exclude  PATTERN  Exclude matching glob(s)        (repeatable)
  --dry-run           List what would be converted but do nothing
  --help              This help message
EOF
  exit 1
}

########################################
# Parse CLI
########################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)  INPUT_DIR=$2; shift 2;;
    --output) OUTPUT_DIR=$2; shift 2;;
    --include) INCLUDE_PATTERNS+=("$2"); shift 2;;
    --exclude) EXCLUDE_PATTERNS+=("$2"); shift 2;;
    --dry-run) DRYRUN=true; shift;;
    --help)    usage;;
    *) echo "Unknown option $1"; usage;;
  esac
done

mkdir -p "$OUTPUT_DIR"
: >"$LOGFILE"

########################################
# Helpers
########################################
is_text() {
  # Returns 0 if the file looks textual
  local mime
  mime=$(file --mime-type -b "$1")
  [[ $mime == text/* || $mime == application/json || $mime == application/xml ]]
}

convert_file() {
  local src=$1 rel dest tmp
  rel=${src#"$INPUT_DIR"/}
  dest="$OUTPUT_DIR/$rel.txt"
  tmp="${dest}.tmp"
  mkdir -p "$(dirname "$dest")"

  # pick specialised converter if possible
  case "${src##*.}" in
    pdf)   pdftotext -layout "$src" "$tmp"        ;;  # poppler-utils[6]
    docx|odt|html|htm|rtf)
           pandoc -q "$src" -t plain -o "$tmp"    ;;  # pandoc
    *)     # plain text: fix encoding & newlines
           iconv -f UTF-8 -t UTF-8 "$src" 2>/dev/null \
            | dos2unix -q >"$tmp" || cp "$src" "$tmp" ;;
  esac

  mv "$tmp" "$dest"
  printf '✔ %s -> %s\n' "$src" "$dest" >>"$LOGFILE"
}

########################################
# Build find command with filters
########################################
mapfile -t FILES < <(
  find "$INPUT_DIR" -type f -print0 \
  | xargs -0 -I{} bash -c '
        f="$1"
        # Apply include / exclude globs
        match_inc=1
        [[ ${#INCLUDE_PATTERNS[@]} -eq 0 ]] || {
          match_inc=0
          for g in "${INCLUDE_PATTERNS[@]}"; do [[ $f == $g ]] && match_inc=1; done
        }
        for g in "${EXCLUDE_PATTERNS[@]}"; do [[ $f == $g ]] && exit 0; done
        (( match_inc )) && printf "%s\0" "$f"
  ' _ "{}"
)

TOTAL=${#FILES[@]}
[[ $TOTAL -eq 0 ]] && { echo "Nothing to do."; exit; }

########################################
# Process in parallel
########################################
export -f convert_file is_text
echo "Scanning $TOTAL files…"
printf -v PROGRESS_FMT "[%${#TOTAL}d/%d] %%s\n" "$TOTAL"

i=0
printf '%s\0' "${FILES[@]}" |
xargs -0 -n 1 -P "$(nproc)" bash -c '
  src="$1"; shift
  (( ++i ))
  printf "'"$PROGRESS_FMT"'" "$i" "$src" >&2
  if is_text "$src"; then
      '"${DRYRUN:+printf \"DRY %s\\n\"}"'
      '"${DRYRUN:+printf \"%s\\n\"}"' || convert_file "$src"
  else
      printf "⤫ %s (binary)\n" "$src" >>"'"$LOGFILE"'"
  fi
' _

echo "Done. Detailed report in $LOGFILE."

