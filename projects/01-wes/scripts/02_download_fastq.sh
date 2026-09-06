#!/usr/bin/env bash
#
# 02_download_fastq.sh - download FASTQ files listed in a URL file
#
# Resumable and re-runnable: files already present are skipped, partial
# transfers are continued. Safe to interrupt and restart.
#
# Usage:
#   ./02_download_fastq.sh <urls.txt> [DEST_DIR]
#
# Example:
#   nohup ./02_download_fastq.sh urls.txt ~/bme282.2026/$USER/fastq > download.log 2>&1 &
#   tail -f download.log
#
# Before running this, check whether the data is already on the server:
#   ls /work/class/bme282.2026/pub/PRJNA896722/
#
# Requires: wget
#
set -uo pipefail

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

URLS="${1:-}"
DEST="${2:-.}"

[ -s "${URLS:-/nonexistent}" ] || { usage; exit 1; }
URLS=$(readlink -f "$URLS")          # resolve before cd, so a relative path works

mkdir -p "$DEST"
cd "$DEST"

echo "[INFO] urls      : $(grep -c . "$URLS")"
echo "[INFO] dest      : $PWD"
echo "[INFO] start     : $(date '+%F %T')"

ok=0; skip=0; fail=0
while read -r url; do
    [ -n "$url" ] || continue
    f=${url##*/}
    if [ -s "$f" ]; then
        printf 'SKIP %s\n' "$f"
        skip=$((skip+1))
        continue
    fi
    printf 'GET  %s\n' "$f"
    if wget -c "$url"; then
        ok=$((ok+1))
    else
        printf 'FAIL %s\n' "$f" >&2
        fail=$((fail+1))
    fi
done < "$URLS"

echo "[INFO] done      : $(date '+%F %T')"
echo "[INFO] ok=$ok skip=$skip fail=$fail"

# A zero-length file is a failed transfer, not an empty run.
find . -maxdepth 1 -name '*.fastq.gz' -size 0 -printf '[WARN] empty: %p\n'

[ "$fail" -eq 0 ] || exit 1
